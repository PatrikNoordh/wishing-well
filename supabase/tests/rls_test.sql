-- =============================================================================
-- Wishing Well — RLS tests
--
-- Runs in one transaction and rolls back, so it leaves no data behind.
-- Works in the Supabase SQL Editor, and against a plain Postgres after
-- supabase/tests/local_stub.sql and the migrations (that is how CI runs it).
-- Each check raises an exception on failure. "OK <n>" notices mean the check passed.
--
-- People:
--   A  Anna   the owner of the wishes
--   B  Bo     A's contact (gets one wish only he may see)
--   C  Cleo   A's contact (chosen for the category "Home decor")
--   E  Eva    A's contact
--   D  Dan    a stranger to A (a contact of E)
--
-- A's wishes and lists (built in section "wishes and lists"):
--   main list "All"    every wish; private at first, later shared with all contacts
--   "Christmas"        shared with all contacts: Lamp, Book, Intimate, Secret
--   "Home decor"       shared with C only:       Lamp
--   "Present for Bo"   private:                  Present
--   Sofa               in no category
--   Intimate           audience 'people': only B
--   Secret             audience 'only_me'
-- Ids and invite codes are kept in test.* settings, so a check signed in as one
-- person can name another person's rows.
-- =============================================================================
begin;

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.local', '{"display_name":"Anna"}'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.local', '{"display_name":"Bo"}'),
  ('00000000-0000-0000-0000-00000000000c', 'c@test.local', '{"display_name":"Cleo"}'),
  ('00000000-0000-0000-0000-00000000000d', 'd@test.local', '{"display_name":"Dan"}'),
  ('00000000-0000-0000-0000-00000000000e', 'e@test.local', '{}');

select set_config('test.a', '00000000-0000-0000-0000-00000000000a', true),
       set_config('test.b', '00000000-0000-0000-0000-00000000000b', true),
       set_config('test.c', '00000000-0000-0000-0000-00000000000c', true),
       set_config('test.d', '00000000-0000-0000-0000-00000000000d', true),
       set_config('test.e', '00000000-0000-0000-0000-00000000000e', true);

-- 1. A profile and a private main list per user, no email column
do $$ begin
  assert (select count(*) from public.profiles) = 5, 'five profiles';
  assert (select display_name from public.profiles where id = current_setting('test.a')::uuid) = 'Anna', 'name copied';
  assert (select display_name from public.profiles where id = current_setting('test.e')::uuid) = '', 'empty name allowed';
  assert (select count(*) from public.lists where is_main and share = 'private' and title is null) = 5,
    'every user has one private main list';
  assert not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'email'
  ), 'profiles has no email';
  raise notice 'OK 1: every new user gets a profile without email and a private main list';
end $$;

-- 2. anon has nothing
do $$ begin
  assert not exists (
    select 1 from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'anon'
  ), 'anon has a table privilege';
  assert not has_function_privilege('anon', 'public.accept_invite(text)', 'execute'), 'anon can accept invites';
  assert not has_function_privilege('anon', 'public.preview_invite(text)', 'execute'), 'anon can preview invites';
  assert not has_function_privilege('authenticated', 'public.handle_new_user()', 'execute'), 'trigger function executable';
  raise notice 'OK 2: anon has no table or function privileges';
end $$;

-- ---------------------------------------------------------------- invites
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.invites default values;
insert into public.invites default values;
insert into public.invites default values;
insert into public.invites default values;
insert into public.invites default values;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
insert into public.invites default values;
insert into public.invites default values;
reset role;

select set_config('test.code_b', (select code from public.invites where inviter_id = current_setting('test.a')::uuid order by id offset 0 limit 1), true),
       set_config('test.code_c', (select code from public.invites where inviter_id = current_setting('test.a')::uuid order by id offset 1 limit 1), true),
       set_config('test.code_e', (select code from public.invites where inviter_id = current_setting('test.a')::uuid order by id offset 2 limit 1), true),
       set_config('test.code_expired', (select code from public.invites where inviter_id = current_setting('test.a')::uuid order by id offset 3 limit 1), true),
       set_config('test.code_d', (select code from public.invites where inviter_id = current_setting('test.e')::uuid order by id offset 0 limit 1), true),
       set_config('test.code_d2', (select code from public.invites where inviter_id = current_setting('test.e')::uuid order by id offset 1 limit 1), true);
update public.invites set expires_at = created_at - interval '1 minute' where code = current_setting('test.code_expired');

do $$ begin
  assert length(current_setting('test.code_b')) = 32, 'code is 32 characters';
  assert current_setting('test.code_b') <> current_setting('test.code_c'), 'codes differ';
  raise notice 'OK 3: invites get an inviter from the session and a random code';
end $$;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ declare msg text; bad boolean := false; begin
  assert (select count(*) from public.invites) = 5, 'A sees own five invites';
  begin
    perform public.accept_invite(current_setting('test.code_b'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'invite_own', 'A accepted own invite: ' || coalesce(msg, 'no error');
  begin
    insert into public.invites (expires_at) values (now() + interval '30 days');
  exception when check_violation then bad := true;
  end;
  assert bad, 'an invite lasting 30 days';
  raise notice 'OK 4: the inviter sees their invites, cannot accept their own or make one last longer than 7 days';
end $$;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ declare blocked boolean := false; msg text; begin
  assert (select count(*) from public.invites) = 0, 'B sees A''s invites';
  begin
    insert into public.invites (inviter_id) values (current_setting('test.a')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'B created an invite in A''s name';
  assert (select inviter_name from public.preview_invite(current_setting('test.code_b'))) = 'Anna', 'preview name';
  assert not exists (select 1 from public.preview_invite('nope')), 'preview of unknown code';
  assert not exists (select 1 from public.preview_invite(current_setting('test.code_expired'))), 'preview of expired code';
  begin
    perform public.accept_invite('nope');
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'invite_not_found', 'unknown code: ' || coalesce(msg, 'no error');
  raise notice 'OK 5: others cannot read or forge invites; preview shows the name only for a valid code';
end $$;

-- B, C and E accept A's invites; D accepts E's.
select public.accept_invite(current_setting('test.code_b'));
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
select public.accept_invite(current_setting('test.code_c'));
do $$ declare msg text; begin
  begin
    perform public.accept_invite(current_setting('test.code_b'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'invite_used', 'used code: ' || coalesce(msg, 'no error');
  msg := null;
  begin
    perform public.accept_invite(current_setting('test.code_expired'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'invite_expired', 'expired code: ' || coalesce(msg, 'no error');
  raise notice 'OK 6: a used or expired invite cannot be accepted';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
select public.accept_invite(current_setting('test.code_e'));
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
select public.accept_invite(current_setting('test.code_d'));

do $$ declare msg text; begin
  begin
    perform public.accept_invite(current_setting('test.code_d2'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'already_connected', 'second invite: ' || coalesce(msg, 'no error');
  reset role;
  assert (select count(*) from public.connections) = 4, 'four connections';
  assert (select accepted_by from public.invites where code = current_setting('test.code_b'))
         = current_setting('test.b')::uuid, 'accepted_by set';
  assert (select accepted_at from public.invites where code = current_setting('test.code_d2')) is null,
    'refused invite marked used';
  raise notice 'OK 7: accepting makes two people contacts once, and marks the invite used';
end $$;

-- ---------------------------------------------------------------- contacts and profiles
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ declare blocked boolean := false; begin
  assert (select count(*) from public.profiles) = 2, 'D sees D and E';
  assert not exists (select 1 from public.profiles where id = current_setting('test.a')::uuid), 'D sees A';
  begin
    insert into public.connections (user_a, user_b)
    values (current_setting('test.a')::uuid, current_setting('test.d')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'D connected itself to A';
  raise notice 'OK 8: a stranger sees no profile of A and cannot create a connection directly';
end $$;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.connections) = 1, 'B sees one connection';
  assert (select count(*) from public.profiles) = 2, 'B sees A and B, not C';
  update public.profiles set display_name = 'hacked' where id = current_setting('test.a')::uuid;
  update public.profiles set display_name = 'Bosse' where id = current_setting('test.b')::uuid;
  reset role;
  assert (select display_name from public.profiles where id = current_setting('test.a')::uuid) = 'Anna', 'B renamed A';
  assert (select display_name from public.profiles where id = current_setting('test.b')::uuid) = 'Bosse', 'B renamed self';
  raise notice 'OK 9: people see their own and their contacts'' profiles, and change only their own';
end $$;

-- ---------------------------------------------------------------- wishes and lists
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.lists (title) values ('Christmas'), ('Home decor'), ('Present for Bo');
insert into public.wishes (title, image_path) values
  ('Lamp', '00000000-0000-0000-0000-00000000000a/lamp.jpg');
insert into public.wishes (title) values ('Book'), ('Sofa'), ('Present');
insert into public.wishes (title, audience, image_path) values
  ('Intimate', 'people', '00000000-0000-0000-0000-00000000000a/intimate.jpg'),
  ('Secret', 'only_me', null);
insert into storage.objects (bucket_id, name) values
  ('wish-images', '00000000-0000-0000-0000-00000000000a/lamp.jpg'),
  ('wish-images', '00000000-0000-0000-0000-00000000000a/intimate.jpg'),
  ('wish-images', '00000000-0000-0000-0000-00000000000a/unused.jpg');
reset role;
select set_config('test.l_main',      (select id::text from public.lists where owner_id = current_setting('test.a')::uuid and is_main), true),
       set_config('test.l_christmas', (select id::text from public.lists where title = 'Christmas'), true),
       set_config('test.l_home',      (select id::text from public.lists where title = 'Home decor'), true),
       set_config('test.l_present',   (select id::text from public.lists where title = 'Present for Bo'), true),
       set_config('test.w_lamp',      (select id::text from public.wishes where title = 'Lamp'), true),
       set_config('test.w_book',      (select id::text from public.wishes where title = 'Book'), true),
       set_config('test.w_sofa',      (select id::text from public.wishes where title = 'Sofa'), true),
       set_config('test.w_present',   (select id::text from public.wishes where title = 'Present'), true),
       set_config('test.w_intimate',  (select id::text from public.wishes where title = 'Intimate'), true),
       set_config('test.w_secret',    (select id::text from public.wishes where title = 'Secret'), true);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.list_items (list_id, wish_id) values
  (current_setting('test.l_christmas')::uuid, current_setting('test.w_lamp')::uuid),
  (current_setting('test.l_christmas')::uuid, current_setting('test.w_book')::uuid),
  (current_setting('test.l_christmas')::uuid, current_setting('test.w_intimate')::uuid),
  (current_setting('test.l_christmas')::uuid, current_setting('test.w_secret')::uuid),
  (current_setting('test.l_home')::uuid,      current_setting('test.w_lamp')::uuid),
  (current_setting('test.l_present')::uuid,   current_setting('test.w_present')::uuid);
insert into public.wish_audience (wish_id, person_id) values
  (current_setting('test.w_intimate')::uuid, current_setting('test.b')::uuid);

-- 10. Private by default: nothing is shared yet.
do $$ begin
  assert (select count(*) from public.wishes) = 6, 'owner sees all six wishes';
  assert (select count(*) from public.lists) = 4, 'owner sees main list and three categories';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'C sees an unshared wish';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'C sees an unshared list';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert (select array_agg(title) from public.wishes where owner_id = current_setting('test.a')::uuid) = array['Intimate'],
    'B sees more than the one wish chosen for him';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'B sees an unshared list';
  raise notice 'OK 10: everything is private until it is shared; a wish chosen for one person is seen by that person alone';
end $$;

-- A shares "Christmas" with all contacts and "Home decor" with C.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
update public.lists set share = 'contacts' where id = current_setting('test.l_christmas')::uuid;
update public.lists set share = 'people' where id = current_setting('test.l_home')::uuid;
insert into public.list_shares (list_id, person_id) values
  (current_setting('test.l_home')::uuid,      current_setting('test.c')::uuid);

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.wishes where owner_id = current_setting('test.a')::uuid) = 3, 'B: Lamp, Book, Intimate';
  assert exists (select 1 from public.wishes where title = 'Intimate'), 'B misses the wish chosen for him';
  assert (select array_agg(title order by title) from public.lists where owner_id = current_setting('test.a')::uuid)
         = array['Christmas'], 'B sees other list names than Christmas';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert (select array_agg(title order by title) from public.wishes where owner_id = current_setting('test.a')::uuid)
         = array['Book', 'Lamp'], 'C sees other wishes than Book and Lamp';
  assert (select array_agg(title order by title) from public.lists where owner_id = current_setting('test.a')::uuid)
         = array['Christmas', 'Home decor'], 'C sees other lists than Christmas and Home decor';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'stranger sees a wish';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'stranger sees a list';
  raise notice 'OK 11: a shared category shows its wishes and its name to those it is shared with, and nothing else';
end $$;

-- A shares the main list "All" with all contacts.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
update public.lists set share = 'contacts' where id = current_setting('test.l_main')::uuid;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert (select array_agg(title order by title) from public.wishes where owner_id = current_setting('test.a')::uuid)
         = array['Book', 'Lamp', 'Present', 'Sofa'], 'C with All shared';
  assert not exists (select 1 from public.lists where title = 'Present for Bo'), 'C sees the name of a private category';
  raise notice 'OK 12: sharing "All" shows every wish that follows its lists, but no private category name';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert (select array_agg(title order by title) from public.wishes where owner_id = current_setting('test.a')::uuid)
         = array['Book', 'Intimate', 'Lamp', 'Present', 'Sofa'], 'B with All shared';
  assert not exists (select 1 from public.lists where title = 'Present for Bo'), 'B sees the category about his present';
  assert not exists (select 1 from public.list_items where list_id = current_setting('test.l_present')::uuid),
    'B sees that his present is in a private category';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.wishes where title in ('Intimate', 'Secret')), 'E sees Intimate or Secret';
  raise notice 'OK 13: a wish for chosen people and a wish for only me stay hidden from everyone else, even in shared lists';
end $$;

-- What is in a shared list is visible only wish by wish.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.list_items where list_id = current_setting('test.l_christmas')::uuid) = 2,
    'C sees Christmas items she cannot see the wish of';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.list_items where list_id = current_setting('test.l_christmas')::uuid) = 3,
    'B sees other Christmas items than Lamp, Book and Intimate';
  raise notice 'OK 14: a list''s items are visible only for wishes the person may see';
end $$;

-- Who is chosen is the owner's business alone, and only contacts can be chosen.
do $$ declare blocked boolean := false; n int; begin
  -- as B
  assert (select count(*) from public.list_shares) = 0, 'B sees list shares';
  assert (select count(*) from public.wish_audience) = 0, 'B sees wish audiences';
  begin
    insert into public.list_shares (list_id, person_id)
    values (current_setting('test.l_present')::uuid, current_setting('test.b')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'B shared A''s list with himself';
  delete from public.wish_audience;
  get diagnostics n = row_count;
  assert n = 0, 'B changed an audience';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ declare blocked boolean := false; begin
  begin
    insert into public.list_shares (list_id, person_id)
    values (current_setting('test.l_home')::uuid, current_setting('test.d')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'A shared a list with a stranger';
  blocked := false;
  begin
    insert into public.wish_audience (wish_id, person_id)
    values (current_setting('test.w_intimate')::uuid, current_setting('test.d')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'A chose a stranger for a wish';
  raise notice 'OK 15: only the owner sees and changes who is chosen, and only among their contacts';
end $$;

-- ---------------------------------------------------------------- writes
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
insert into public.lists (title) values ('Bo''s list');
insert into public.wishes (title) values ('Bo''s wish');
reset role;
select set_config('test.l_bo', (select id::text from public.lists where title = 'Bo''s list'), true),
       set_config('test.w_bo', (select id::text from public.wishes where title = 'Bo''s wish'), true);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);

do $$ declare blocked boolean; n int; begin
  update public.lists set title = 'hacked' where id = current_setting('test.l_christmas')::uuid;
  update public.wishes set title = 'hacked' where id = current_setting('test.w_lamp')::uuid;
  delete from public.wishes where id = current_setting('test.w_book')::uuid;
  delete from public.lists where id = current_setting('test.l_christmas')::uuid;
  delete from public.list_items where list_id = current_setting('test.l_christmas')::uuid;
  get diagnostics n = row_count;
  assert n = 0, 'B removed items from A''s list';
  blocked := false;
  begin
    insert into public.list_items (list_id, wish_id) values (current_setting('test.l_christmas')::uuid, current_setting('test.w_bo')::uuid);
  exception
    when insufficient_privilege then blocked := true;
    when raise_exception then blocked := sqlerrm = 'owner_mismatch';
  end;
  assert blocked, 'B put his wish in A''s list';
  blocked := false;
  begin
    insert into public.list_items (list_id, wish_id) values (current_setting('test.l_bo')::uuid, current_setting('test.w_lamp')::uuid);
  exception
    when insufficient_privilege then blocked := true;
    when raise_exception then blocked := sqlerrm = 'owner_mismatch';
  end;
  assert blocked, 'B put A''s wish in his list';
  blocked := false;
  begin
    insert into public.wishes (owner_id, title) values (current_setting('test.a')::uuid, 'planted');
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'B chose a wish''s owner';
  reset role;
  assert not exists (select 1 from public.lists where title = 'hacked'), 'B renamed A''s list';
  assert not exists (select 1 from public.wishes where title in ('hacked', 'planted')), 'B changed A''s wishes';
  assert (select count(*) from public.wishes where owner_id = current_setting('test.a')::uuid) = 6, 'B deleted A''s wish';
  assert (select count(*) from public.lists where owner_id = current_setting('test.a')::uuid) = 4, 'B deleted A''s list';
  raise notice 'OK 16: others cannot change, delete or fill A''s lists and wishes, or choose a wish''s owner';
end $$;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ declare msg text; blocked boolean := false; begin
  begin
    insert into public.list_items (list_id, wish_id) values (current_setting('test.l_main')::uuid, current_setting('test.w_sofa')::uuid);
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'main_list_has_no_items', 'item in main list: ' || coalesce(msg, 'no error');
  msg := null;
  begin
    delete from public.lists where id = current_setting('test.l_main')::uuid;
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'main_list_protected', 'main list deleted: ' || coalesce(msg, 'no error');
  begin
    update public.lists set title = 'All mine' where id = current_setting('test.l_main')::uuid;
  exception when check_violation then blocked := true;
  end;
  assert blocked, 'main list got a title';
  blocked := false;
  begin
    update public.lists set is_main = false where id = current_setting('test.l_main')::uuid;
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'main list stopped being main';
  msg := null;
  begin
    update public.wishes set image_path = '00000000-0000-0000-0000-00000000000b/x.jpg' where id = current_setting('test.w_sofa')::uuid;
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'image_path_not_owned', 'photo outside own folder: ' || coalesce(msg, 'no error');
  raise notice 'OK 17: the main list stays, holds no items and has no title; a photo must be in the owner''s folder';
end $$;

-- ---------------------------------------------------------------- reservations
-- C reserves Lamp. B reserves Book and Intimate.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
insert into public.reservations (wish_id) values (current_setting('test.w_lamp')::uuid);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
insert into public.reservations (wish_id) values (current_setting('test.w_book')::uuid),
                                                 (current_setting('test.w_intimate')::uuid);
do $$ begin
  assert (select count(*) from public.reservations) = 3, 'B sees all three reservations';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.reservations) = 2, 'C sees Lamp and Book, not the hidden Intimate';
  raise notice 'OK 18: others see a reservation exactly when they can see the wish';
end $$;

-- The heart of the app: the owner never sees a reservation on their own wishes.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.reservations) = 0, 'owner sees reservations';
  raise notice 'OK 19: the owner sees no reservation on their own wishes';
end $$;

do $$ declare blocked boolean; n int; begin
  -- Not even by trying to reserve: the same refusal whether the wish is reserved or not.
  blocked := false;
  begin
    insert into public.reservations (wish_id) values (current_setting('test.w_lamp')::uuid) on conflict do nothing;
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'owner probed a reserved wish';
  blocked := false;
  begin
    insert into public.reservations (wish_id) values (current_setting('test.w_sofa')::uuid) on conflict do nothing;
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'owner reserved an unreserved own wish';
  delete from public.reservations where wish_id = current_setting('test.w_lamp')::uuid;
  get diagnostics n = row_count;
  assert n = 0, 'owner deleted a reservation';
  raise notice 'OK 20: the owner cannot reserve, probe or remove reservations on their own wishes';
end $$;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ declare blocked boolean := false; dup boolean := false; n int; begin
  begin
    insert into public.reservations (wish_id) values (current_setting('test.w_secret')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'C reserved a wish only the owner may see';
  blocked := false;
  begin
    insert into public.reservations (wish_id) values (current_setting('test.w_intimate')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'C reserved a wish hidden from her (and could tell it was taken)';
  begin
    insert into public.reservations (wish_id) values (current_setting('test.w_book')::uuid);
  exception when unique_violation then dup := true;
  end;
  assert dup, 'two reservations on one wish';
  delete from public.reservations where wish_id = current_setting('test.w_book')::uuid;
  get diagnostics n = row_count;
  assert n = 0, 'C removed B''s reservation';
  raise notice 'OK 21: only wishes you can see can be reserved, once each, and only the reserver can remove it';
end $$;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ declare blocked boolean := false; begin
  assert (select count(*) from public.reservations) = 0, 'stranger sees reservations';
  begin
    insert into public.reservations (wish_id) values (current_setting('test.w_sofa')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'stranger reserved';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
do $$ declare blocked boolean := false; begin
  begin
    insert into public.reservations (wish_id, reserved_by)
    values (current_setting('test.w_sofa')::uuid, current_setting('test.c')::uuid);
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'E reserved in C''s name';
  raise notice 'OK 22: a stranger neither sees nor makes reservations, and nobody reserves in someone else''s name';
end $$;

-- ---------------------------------------------------------------- photos
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ declare blocked boolean := false; n int; begin
  assert exists (select 1 from storage.objects where name = '00000000-0000-0000-0000-00000000000a/intimate.jpg'), 'B cannot open Intimate''s photo';
  assert not exists (select 1 from storage.objects where name = '00000000-0000-0000-0000-00000000000a/unused.jpg'), 'B opens an unused photo';
  begin
    insert into storage.objects (bucket_id, name) values ('wish-images', '00000000-0000-0000-0000-00000000000a/planted.jpg');
  exception when insufficient_privilege then blocked := true;
  end;
  assert blocked, 'B uploaded into A''s folder';
  delete from storage.objects where name = '00000000-0000-0000-0000-00000000000a/lamp.jpg';
  get diagnostics n = row_count;
  assert n = 0, 'B deleted A''s photo';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert exists (select 1 from storage.objects where name = '00000000-0000-0000-0000-00000000000a/lamp.jpg'), 'C cannot open Lamp''s photo';
  assert not exists (select 1 from storage.objects where name = '00000000-0000-0000-0000-00000000000a/intimate.jpg'), 'C opens Intimate''s photo';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from storage.objects where name like '00000000-0000-0000-0000-00000000000a/%'), 'stranger sees photos';
  raise notice 'OK 23: a photo is readable by exactly those who can see its wish, and writable only in your own folder';
end $$;

-- ---------------------------------------------------------------- ending a connection
-- C ends being A's contact: All and Christmas are still shared with "all contacts", but C is not one any more.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
delete from public.connections where current_setting('test.a')::uuid in (user_a, user_b);
do $$ begin
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'C still sees A''s wishes';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'C still sees A''s lists';
  assert not exists (select 1 from storage.objects where name like '00000000-0000-0000-0000-00000000000a/%'), 'C still sees A''s photos';
  reset role;
  assert not exists (select 1 from public.reservations where wish_id = current_setting('test.w_lamp')::uuid), 'C''s reservation kept';
  assert not exists (select 1 from public.list_shares where person_id = current_setting('test.c')::uuid), 'C still chosen for Home decor';
  assert (select count(*) from public.reservations where reserved_by = current_setting('test.b')::uuid) = 2, 'B''s reservations lost';
  raise notice 'OK 24: ending a connection hides everything and removes reservations and choices between the two, nothing else';
end $$;

-- Even if a choice were left behind (planted here past RLS), a former contact sees nothing:
-- every way to see a wish or a list also needs the connection.
insert into public.wish_audience (wish_id, person_id) values (current_setting('test.w_intimate')::uuid, current_setting('test.c')::uuid);
insert into public.list_shares (list_id, person_id) values (current_setting('test.l_home')::uuid, current_setting('test.c')::uuid);
update public.wishes set audience = 'people' where id = current_setting('test.w_lamp')::uuid;
insert into public.wish_audience (wish_id, person_id) values (current_setting('test.w_lamp')::uuid, current_setting('test.c')::uuid);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'a leftover choice shows a wish';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'a leftover share shows a list';
  raise notice 'OK 25: a leftover choice never shows anything to someone who is no longer a contact';
end $$;
reset role;

-- ---------------------------------------------------------------- shared by link
-- A makes a category "For everyone" with Sofa, Secret and Intimate, and shares it by link.
-- D is a stranger to A.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.lists (title) values ('For everyone');
reset role;
select set_config('test.l_link', (select id::text from public.lists where title = 'For everyone'), true);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.list_items (list_id, wish_id) values
  (current_setting('test.l_link')::uuid, current_setting('test.w_sofa')::uuid),
  (current_setting('test.l_link')::uuid, current_setting('test.w_secret')::uuid),
  (current_setting('test.l_link')::uuid, current_setting('test.w_intimate')::uuid);
update public.lists set share = 'link' where id = current_setting('test.l_link')::uuid;
do $$ begin
  assert (select count(*) from public.list_links where list_id = current_setting('test.l_link')::uuid) = 1, 'no code made';
end $$;
reset role;
select set_config('test.code_link', (select code from public.list_links where list_id = current_setting('test.l_link')::uuid), true);
set local role authenticated;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.list_links) = 0, 'a contact reads the link code';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ declare msg text; begin
  assert (select count(*) from public.list_links) = 0, 'a stranger reads the link code';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'stranger sees the list before opening the link';
  begin
    perform public.open_list_link('nope');
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'link_not_found', 'unknown link: ' || coalesce(msg, 'no error');
  raise notice 'OK 26: sharing by link makes a secret code that only the owner can read';
end $$;

select public.open_list_link(current_setting('test.code_link'));
do $$ begin
  assert (select array_agg(title) from public.lists where owner_id = current_setting('test.a')::uuid) = array['For everyone'],
    'link opener sees other lists';
  assert (select array_agg(title) from public.wishes where owner_id = current_setting('test.a')::uuid) = array['Sofa'],
    'link opener sees other wishes than Sofa';
  assert (select display_name from public.profiles where id = current_setting('test.a')::uuid) = 'Anna', 'link opener cannot see the owner''s name';
  assert (select count(*) from public.list_items) = 1, 'link opener sees other list items';
  raise notice 'OK 27: whoever opens the link sees that list, its owner''s name, and only the wishes that follow their lists';
end $$;

insert into public.reservations (wish_id) values (current_setting('test.w_sofa')::uuid);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from public.reservations) = 0, 'owner sees a reservation made through a link';
  assert (select count(*) from public.list_link_access where list_id = current_setting('test.l_link')::uuid) = 1,
    'owner cannot see who opened the link';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert exists (select 1 from public.reservations where wish_id = current_setting('test.w_sofa')::uuid), 'B misses the reservation';
  raise notice 'OK 28: someone who came by link can reserve; others see it, the owner does not';
end $$;

-- A makes a new link: the old one dies, also for D.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ declare msg text; begin
  begin
    perform public.regenerate_list_link(current_setting('test.l_link')::uuid);
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'not_allowed', 'B made a new link for A''s list: ' || coalesce(msg, 'no error');
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
select set_config('test.code_link2', public.regenerate_list_link(current_setting('test.l_link')::uuid), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ declare msg text; begin
  assert current_setting('test.code_link2') <> current_setting('test.code_link'), 'same code';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'old link still works for D';
  begin
    perform public.open_list_link(current_setting('test.code_link'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'link_not_found', 'old code: ' || coalesce(msg, 'no error');
  perform public.open_list_link(current_setting('test.code_link2'));
  assert exists (select 1 from public.lists where title = 'For everyone'), 'new code does not work';
  raise notice 'OK 29: a new link shuts out everyone who came through the old one';
end $$;

-- A stops sharing by link: code and access go.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
update public.lists set share = 'private' where id = current_setting('test.l_link')::uuid;
do $$ begin
  assert (select count(*) from public.list_links where list_id = current_setting('test.l_link')::uuid) = 0, 'code kept';
  assert (select count(*) from public.list_link_access where list_id = current_setting('test.l_link')::uuid) = 0, 'access kept';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ declare msg text; begin
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'D still sees the list';
  begin
    perform public.open_list_link(current_setting('test.code_link2'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'link_not_found', 'link of an unshared list: ' || coalesce(msg, 'no error');
  raise notice 'OK 30: a list that stops being shared by link loses its code and everyone who opened it';
end $$;

-- ---------------------------------------------------------------- prepared: public lists and search
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.lists (title, share) values ('Public', 'public');
insert into public.list_items (list_id, wish_id)
  select id, current_setting('test.w_book')::uuid from public.lists where title = 'Public';
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  assert (select array_agg(title) from public.lists where owner_id = current_setting('test.a')::uuid) = array['Public'],
    'a former contact sees other lists than the public one';
  assert (select array_agg(title) from public.wishes where owner_id = current_setting('test.a')::uuid) = array['Book'],
    'a former contact sees other wishes than Book';
  raise notice 'OK 31: (prepared) a public list is seen by anyone signed in, and only its wishes';
end $$;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ declare bad boolean := false; begin
  begin
    update public.profiles set handle = 'Anna!' where id = current_setting('test.a')::uuid;
  exception when check_violation then bad := true;
  end;
  assert bad, 'a handle with capitals and !';
end $$;
update public.profiles set handle = 'anna.s' where id = current_setting('test.a')::uuid;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
update public.profiles set handle = 'b_o_b', discoverable = true where id = current_setting('test.b')::uuid;
do $$ declare dup boolean := false; begin
  begin
    update public.profiles set handle = 'anna.s' where id = current_setting('test.b')::uuid;
  exception when unique_violation then dup := true;
  end;
  assert dup, 'two people with one handle';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.search_profiles('anna')), 'found someone who has not chosen to be found';
  assert (select handle from public.search_profiles('b_o')) = 'b_o_b', 'cannot find a discoverable profile';
  assert not exists (select 1 from public.search_profiles('b_')), 'search on two characters';
  assert not exists (select 1 from public.search_profiles('___')), 'wildcards in a search';
  assert not exists (select 1 from public.search_profiles('%%%')), 'wildcards in a search';
  assert not exists (select 1 from public.profiles where id = current_setting('test.b')::uuid), 'being findable opens the profile';
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.search_profiles('b_o_b')), 'search finds yourself';
  raise notice 'OK 32: (prepared) search finds only people who chose to be found, by the start of a valid, unique handle, and opens nothing else';
end $$;

-- ---------------------------------------------------------------- blocks
-- A shares by link again and becomes findable; D opens the link and sends A an invite. Then A blocks D and E.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
update public.lists set share = 'link' where id = current_setting('test.l_link')::uuid;
reset role;
select set_config('test.code_link3', (select code from public.list_links where list_id = current_setting('test.l_link')::uuid), true);
update public.profiles set discoverable = true where id = current_setting('test.a')::uuid;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
select public.open_list_link(current_setting('test.code_link3'));
insert into public.invites default values;
reset role;
select set_config('test.code_from_d', (select code from public.invites where inviter_id = current_setting('test.d')::uuid and accepted_at is null limit 1), true);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.blocks (blocked_id) values (current_setting('test.d')::uuid), (current_setting('test.e')::uuid);
do $$ declare msg text; begin
  assert not exists (select 1 from public.preview_invite(current_setting('test.code_from_d'))), 'preview across a block';
  begin
    perform public.accept_invite(current_setting('test.code_from_d'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'invite_not_found', 'invite across a block: ' || coalesce(msg, 'no error');
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
do $$ declare msg text; begin
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'a blocked person sees a list';
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'a blocked person sees a wish';
  assert not exists (select 1 from public.profiles where id = current_setting('test.a')::uuid), 'a blocked person sees the profile';
  assert not exists (select 1 from public.search_profiles('anna')), 'a blocked person finds the profile';
  assert not exists (select 1 from public.blocks), 'the blocked person sees the block';
  begin
    perform public.open_list_link(current_setting('test.code_link3'));
  exception when raise_exception then msg := sqlerrm;
  end;
  assert msg = 'link_not_found', 'link across a block: ' || coalesce(msg, 'no error');
end $$;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
do $$ begin
  assert not exists (select 1 from public.connections where current_setting('test.a')::uuid in (user_a, user_b)), 'block kept the contact';
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'a blocked former contact sees a wish';
end $$;
reset role;
do $$ begin
  assert not exists (select 1 from public.reservations where reserved_by = current_setting('test.d')::uuid), 'a blocked person''s reservation kept';
  assert not exists (select 1 from public.list_link_access where user_id = current_setting('test.d')::uuid), 'a blocked person''s link access kept';
end $$;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
delete from public.blocks where blocked_id = current_setting('test.e')::uuid;
reset role;
do $$ begin
  assert not exists (select 1 from public.connections where current_setting('test.a')::uuid in (user_a, user_b)
                       and current_setting('test.e')::uuid in (user_a, user_b)), 'lifting a block brought the contact back';
  raise notice 'OK 33: a block hides two people from each other in every way, ends what was between them, and lifting it brings nothing back';
end $$;

-- ---------------------------------------------------------------- deleting an account
-- Deleting A's Auth user (what the delete-account Edge Function does) removes all of A's data.
reset role;
delete from auth.users where id = current_setting('test.a')::uuid;
do $$ begin
  assert not exists (select 1 from public.profiles where id = current_setting('test.a')::uuid), 'profile kept';
  assert not exists (select 1 from public.lists where owner_id = current_setting('test.a')::uuid), 'lists kept (main list included)';
  assert not exists (select 1 from public.wishes where owner_id = current_setting('test.a')::uuid), 'wishes kept';
  assert not exists (select 1 from public.connections where current_setting('test.a')::uuid in (user_a, user_b)), 'connections kept';
  assert not exists (select 1 from public.invites where inviter_id = current_setting('test.a')::uuid), 'invites kept';
  assert not exists (select 1 from public.reservations where wish_id = current_setting('test.w_book')::uuid), 'reservation kept';
  assert exists (select 1 from public.wishes where title = 'Bo''s wish'), 'B''s wish removed';
  assert exists (select 1 from public.lists where owner_id = current_setting('test.b')::uuid and is_main), 'B''s main list removed';
  raise notice 'OK 34: deleting an account removes all of the person''s data, the main list included, and nobody else''s';
end $$;

rollback;
