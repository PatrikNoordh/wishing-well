-- =============================================================================
-- Wishing Well — initial schema
--
-- People and their contacts, wishes, lists (the main list "All" and categories),
-- sharing, reservations and the private photo bucket. Every table has RLS and
-- explicit grants.
--
-- Sharing works like Google Drive:
--   * Everything is private until the owner shares it.
--   * A list (the main list or a category) is shared with all contacts, with
--     chosen contacts, with anyone who has its link, or (prepared for a later
--     release) publicly. Everyone it is shared with sees the list and every wish in it.
--   * A wish follows its lists, or overrides them: only chosen people, or only me.
--     The override always wins, even inside a list shared with everyone.
--   * Nobody sees the name of a list that is not shared with them.
--   * A block hides two people from each other completely, whichever way they met.
-- And the promise the app rests on: the owner of a wish never sees whether it is
-- reserved.
--
-- Prepared for searchable profiles (not used by the app in v1): profiles.handle,
-- profiles.discoverable (off by default), share 'public' and search_profiles().
--
-- Errors raised here are codes, never user-facing text (docs/error-codes.md).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tables
-- -----------------------------------------------------------------------------

-- One row per user. No email here: contacts see a name, never an address.
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  display_name  text not null default '' check (char_length(display_name) <= 60),
  birthday      date,
  -- Prepared for searchable profiles: a unique @handle, and an opt-in to be found.
  handle        text unique check (handle ~ '^[a-z0-9._]{3,30}$'),
  discoverable  boolean not null default false,
  created_at    timestamptz not null default now()
);

-- Two people who are contacts, stored once per pair (user_a < user_b).
create table public.connections (
  id          uuid primary key default gen_random_uuid(),
  user_a      uuid not null references public.profiles (id) on delete cascade,
  user_b      uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  constraint connections_ordered_pair check (user_a < user_b),
  constraint connections_one_per_pair unique (user_a, user_b)
);
create index connections_user_b_idx on public.connections (user_b);

-- A block hides two people from each other completely, in both directions:
-- contacts, links, public lists, search and invites.
create table public.blocks (
  blocker_id  uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  blocked_id  uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

-- An invite link. Accepted only through accept_invite(), which creates the connection.
create table public.invites (
  id           uuid primary key default gen_random_uuid(),
  code         text not null unique default replace(gen_random_uuid()::text, '-', ''),
  inviter_id   uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default now() + interval '7 days',
  accepted_by  uuid references public.profiles (id) on delete set null,
  accepted_at  timestamptz
);
create index invites_inviter_idx on public.invites (inviter_id);

-- A list: every person has one main list (is_main, no title: the app shows "All"),
-- which holds every wish, and any number of categories ("Christmas", "Home decor").
-- share: 'private' (only me, the default), 'contacts' (all my contacts),
-- 'people' (the contacts in list_shares), 'link' (anyone signed in who opened the
-- list's link, see list_links and list_link_access), 'public' (anyone signed in;
-- prepared for searchable profiles, not offered by the app in v1).
create table public.lists (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  is_main     boolean not null default false,
  title       text,
  share       text not null default 'private' check (share in ('private', 'contacts', 'people', 'link', 'public')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint lists_title check (
    (is_main and title is null)
    or (not is_main and char_length(btrim(title)) between 1 and 60)
  )
);
create index lists_owner_idx on public.lists (owner_id);
create unique index lists_one_main_per_owner on public.lists (owner_id) where is_main;

-- The chosen people for a list with share 'people'. Only the owner sees these rows.
create table public.list_shares (
  list_id    uuid not null references public.lists (id) on delete cascade,
  person_id  uuid not null references public.profiles (id) on delete cascade,
  primary key (list_id, person_id)
);
create index list_shares_person_idx on public.list_shares (person_id);

-- The secret link code of a list shared with 'link'. Only the owner sees it.
-- Made when the list is shared by link, replaced by regenerate_list_link(), and
-- gone when the list stops being shared by link.
create table public.list_links (
  list_id     uuid primary key references public.lists (id) on delete cascade,
  code        text not null unique default replace(gen_random_uuid()::text, '-', ''),
  created_at  timestamptz not null default now()
);

-- Who has opened a list's link (through open_list_link()). Cleared when the code
-- changes or the list stops being shared by link, so an old link stops working.
create table public.list_link_access (
  list_id     uuid not null references public.lists (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (list_id, user_id)
);
create index list_link_access_user_idx on public.list_link_access (user_id);

-- A wish. It is always in its owner's main list, and in any categories through list_items.
-- audience: 'lists' (whoever sees a list it is in, the default), 'people' (only the
-- people in wish_audience, whatever the lists say), 'only_me' (nobody else).
create table public.wishes (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title       text not null check (char_length(btrim(title)) between 1 and 120),
  note        text check (char_length(note) <= 1000),
  url         text check (url ~ '^https?://' and char_length(url) <= 2048),
  price       numeric(12, 2) check (price >= 0),
  currency    text check (currency ~ '^[A-Z]{3}$'),
  store_name  text check (char_length(store_name) <= 120),
  image_path  text check (char_length(image_path) <= 300),
  audience    text not null default 'lists' check (audience in ('lists', 'people', 'only_me')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index wishes_owner_idx on public.wishes (owner_id);
create index wishes_image_path_idx on public.wishes (image_path) where image_path is not null;

-- Which categories a wish is in. Never the main list (every wish is in it already).
create table public.list_items (
  list_id     uuid not null references public.lists (id) on delete cascade,
  wish_id     uuid not null references public.wishes (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (list_id, wish_id)
);
create index list_items_wish_idx on public.list_items (wish_id);

-- The chosen people for a wish with audience 'people'. Only the owner sees these rows.
create table public.wish_audience (
  wish_id    uuid not null references public.wishes (id) on delete cascade,
  person_id  uuid not null references public.profiles (id) on delete cascade,
  primary key (wish_id, person_id)
);
create index wish_audience_person_idx on public.wish_audience (person_id);

-- At most one reservation per wish. Never visible to the wish's owner.
create table public.reservations (
  wish_id      uuid primary key references public.wishes (id) on delete cascade,
  reserved_by  uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at   timestamptz not null default now()
);
create index reservations_reserved_by_idx on public.reservations (reserved_by);

-- -----------------------------------------------------------------------------
-- 2. Helper functions used by the policies
--    Security definer so a policy can look past RLS on another table without
--    recursion. Each one only answers a yes/no question about the caller.
-- -----------------------------------------------------------------------------

create function public.is_connected(other uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.connections c
    where c.user_a = least(auth.uid(), other) and c.user_b = greatest(auth.uid(), other)
  );
$$;

-- Has either of the two blocked the other?
create function public.is_blocked(other uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.blocks b
    where (b.blocker_id = auth.uid() and b.blocked_id = other)
       or (b.blocker_id = other and b.blocked_id = auth.uid())
  );
$$;

create function public.owns_list(p_list_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.lists l where l.id = p_list_id and l.owner_id = auth.uid());
$$;

create function public.owns_wish(p_wish_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.wishes w where w.id = p_wish_id and w.owner_id = auth.uid());
$$;

-- Is this list shared with the caller (or theirs)? Never across a block.
--   contacts / people   need a current connection (and, for people, being chosen)
--   link                needs to have opened the current link
--   public              any signed-in person (prepared, not offered in v1)
create function public.can_view_list(p_list_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.lists l
    where l.id = p_list_id
      and (
        l.owner_id = auth.uid()
        or (
          auth.uid() is not null
          and not public.is_blocked(l.owner_id)
          and case l.share
            when 'contacts' then public.is_connected(l.owner_id)
            when 'people' then public.is_connected(l.owner_id) and exists (
              select 1 from public.list_shares s where s.list_id = l.id and s.person_id = auth.uid())
            when 'link' then exists (
              select 1 from public.list_link_access a where a.list_id = l.id and a.user_id = auth.uid())
            when 'public' then true
            else false
          end
        )
      )
  );
$$;

-- The one place that decides who sees a wish. Wishes, list items, reservations and
-- photos all go through it.
--   owner                 always
--   audience 'only_me'    nobody else
--   audience 'people'     exactly the chosen contacts (the lists do not matter)
--   audience 'lists'      whoever can see the owner's main list, or a category the wish is in
-- Never across a block.
create function public.can_view_wish(p_wish_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.wishes w
    where w.id = p_wish_id
      and (
        w.owner_id = auth.uid()
        or (
          auth.uid() is not null
          and not public.is_blocked(w.owner_id)
          and case w.audience
            when 'people' then public.is_connected(w.owner_id) and exists (
              select 1 from public.wish_audience a where a.wish_id = w.id and a.person_id = auth.uid())
            when 'lists' then (
              exists (
                select 1 from public.lists m
                where m.owner_id = w.owner_id and m.is_main and public.can_view_list(m.id))
              or exists (
                select 1 from public.list_items i
                where i.wish_id = w.id and public.can_view_list(i.list_id))
            )
            else false
          end
        )
      )
  );
$$;

-- Can the caller see this person's profile (name, birthday, handle)? Themselves,
-- their contacts, or the owner of a list they can see. Never across a block.
-- Being discoverable does not open the profile: search_profiles() returns only
-- the name and the handle.
create function public.can_see_profile(p_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select p_id = auth.uid()
    or (
      auth.uid() is not null
      and not public.is_blocked(p_id)
      and (
        public.is_connected(p_id)
        or exists (select 1 from public.lists l where l.owner_id = p_id and public.can_view_list(l.id))
      )
    );
$$;

-- Can the caller read this photo? Only if a wish they can see uses it.
create function public.can_view_image(p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.wishes w
    where w.image_path = p_path and public.can_view_wish(w.id)
  );
$$;

-- -----------------------------------------------------------------------------
-- 3. Triggers
-- -----------------------------------------------------------------------------

-- A profile and a private main list for every new Auth user.
create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, left(coalesce(new.raw_user_meta_data ->> 'display_name', ''), 60));
  insert into public.lists (owner_id, is_main) values (new.id, true);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger lists_touch before update on public.lists
  for each row execute function public.touch_updated_at();
create trigger wishes_touch before update on public.wishes
  for each row execute function public.touch_updated_at();

-- Owners never change. The main list is created by handle_new_user and stays
-- until the account goes.
create function public.lists_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.is_main and exists (select 1 from public.lists where owner_id = new.owner_id and is_main) then
      raise exception 'main_list_exists';
    end if;
    return new;
  elsif tg_op = 'UPDATE' then
    if new.owner_id is distinct from old.owner_id or new.is_main is distinct from old.is_main then
      raise exception 'owner_change_not_allowed';
    end if;
    return new;
  else
    -- Deleting the main list only happens when the whole account goes.
    if old.is_main and exists (select 1 from public.profiles where id = old.owner_id) then
      raise exception 'main_list_protected';
    end if;
    return old;
  end if;
end;
$$;

create trigger lists_guard before insert or update or delete on public.lists
  for each row execute function public.lists_guard();

-- A wish's owner never changes, and its photo must be in the owner's own folder.
create function public.wishes_guard()
returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.owner_id is distinct from old.owner_id then
    raise exception 'owner_change_not_allowed';
  end if;
  if new.image_path is not null and split_part(new.image_path, '/', 1) <> new.owner_id::text then
    raise exception 'image_path_not_owned';
  end if;
  return new;
end;
$$;

create trigger wishes_guard before insert or update on public.wishes
  for each row execute function public.wishes_guard();

-- A category holds only its owner's wishes, and the main list holds no items.
create function public.list_items_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.lists where id = new.list_id and is_main) then
    raise exception 'main_list_has_no_items';
  end if;
  if (select owner_id from public.lists where id = new.list_id)
     is distinct from (select owner_id from public.wishes where id = new.wish_id) then
    raise exception 'owner_mismatch';
  end if;
  return new;
end;
$$;

create trigger list_items_guard before insert on public.list_items
  for each row execute function public.list_items_guard();

-- When two people stop being contacts, everything between them goes: the
-- reservations each made on the other's wishes, and their places among the other's
-- chosen people for wishes and lists. Otherwise others would keep seeing "reserved"
-- for a gift nobody can see any more, and a new connection later would silently
-- bring back old choices.
create function public.connections_cleanup()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.reservations r
  using public.wishes w
  where r.wish_id = w.id
    and ((r.reserved_by = old.user_a and w.owner_id = old.user_b)
      or (r.reserved_by = old.user_b and w.owner_id = old.user_a));
  delete from public.wish_audience a
  using public.wishes w
  where a.wish_id = w.id
    and ((a.person_id = old.user_a and w.owner_id = old.user_b)
      or (a.person_id = old.user_b and w.owner_id = old.user_a));
  delete from public.list_shares s
  using public.lists l
  where s.list_id = l.id
    and ((s.person_id = old.user_a and l.owner_id = old.user_b)
      or (s.person_id = old.user_b and l.owner_id = old.user_a));
  return old;
end;
$$;

create trigger connections_cleanup after delete on public.connections
  for each row execute function public.connections_cleanup();

-- A list shared by link gets a code; a list that stops being shared by link loses
-- its code and everyone who had opened it.
create function public.lists_link_lifecycle()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.share = 'link' and (tg_op = 'INSERT' or old.share is distinct from 'link') then
    insert into public.list_links (list_id) values (new.id) on conflict (list_id) do nothing;
  elsif tg_op = 'UPDATE' and old.share = 'link' and new.share <> 'link' then
    delete from public.list_links where list_id = new.id;
    delete from public.list_link_access where list_id = new.id;
  end if;
  return new;
end;
$$;

create trigger lists_link_lifecycle after insert or update of share on public.lists
  for each row execute function public.lists_link_lifecycle();

-- Blocking someone ends the contact (and with it everything between the two, see
-- connections_cleanup), their access through links, and reservations either way.
create function public.blocks_cleanup()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.connections
  where user_a = least(new.blocker_id, new.blocked_id) and user_b = greatest(new.blocker_id, new.blocked_id);
  delete from public.list_link_access a
  using public.lists l
  where a.list_id = l.id
    and ((a.user_id = new.blocked_id and l.owner_id = new.blocker_id)
      or (a.user_id = new.blocker_id and l.owner_id = new.blocked_id));
  delete from public.reservations r
  using public.wishes w
  where r.wish_id = w.id
    and ((r.reserved_by = new.blocked_id and w.owner_id = new.blocker_id)
      or (r.reserved_by = new.blocker_id and w.owner_id = new.blocked_id));
  return new;
end;
$$;

create trigger blocks_cleanup after insert on public.blocks
  for each row execute function public.blocks_cleanup();

-- -----------------------------------------------------------------------------
-- 4. Invites, links and search
-- -----------------------------------------------------------------------------

-- What the person opening an invite link sees before accepting: who invites them.
-- Returns no row for an unknown, used or expired code.
create function public.preview_invite(p_code text)
returns table (inviter_name text, expires_at timestamptz)
language sql stable security definer set search_path = public as $$
  select p.display_name, i.expires_at
  from public.invites i
  join public.profiles p on p.id = i.inviter_id
  where i.code = p_code and i.accepted_at is null and i.expires_at > now()
    and auth.uid() is not null and not public.is_blocked(i.inviter_id);
$$;

-- Accept an invite: the two become contacts. Returns the connection id.
create function public.accept_invite(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  caller  uuid := auth.uid();
  inv     public.invites%rowtype;
  conn_id uuid;
begin
  if caller is null then
    raise exception 'not_signed_in';
  end if;

  select * into inv from public.invites where code = p_code for update;
  if not found then
    raise exception 'invite_not_found';
  end if;
  if inv.accepted_at is not null then
    raise exception 'invite_used';
  end if;
  if inv.expires_at <= now() then
    raise exception 'invite_expired';
  end if;
  if inv.inviter_id = caller then
    raise exception 'invite_own';
  end if;
  -- Across a block, the invite looks like it does not exist.
  if public.is_blocked(inv.inviter_id) then
    raise exception 'invite_not_found';
  end if;

  insert into public.connections (user_a, user_b)
  values (least(inv.inviter_id, caller), greatest(inv.inviter_id, caller))
  on conflict (user_a, user_b) do nothing
  returning id into conn_id;
  if conn_id is null then
    raise exception 'already_connected';
  end if;

  update public.invites set accepted_by = caller, accepted_at = now() where id = inv.id;
  return conn_id;
end;
$$;

-- Open a list's link: from now on the caller sees the list (until the code changes
-- or the list stops being shared by link). Returns the list and its owner.
-- An unknown code, a list no longer shared by link and a block all look the same.
create function public.open_list_link(p_code text)
returns table (list_id uuid, owner_id uuid)
language plpgsql security definer set search_path = public as $$
declare
  caller  uuid := auth.uid();
  l       public.lists%rowtype;
begin
  if caller is null then
    raise exception 'not_signed_in';
  end if;
  select li.* into l
  from public.list_links k join public.lists li on li.id = k.list_id
  where k.code = p_code and li.share = 'link';
  if not found or public.is_blocked(l.owner_id) then
    raise exception 'link_not_found';
  end if;
  if l.owner_id <> caller then
    insert into public.list_link_access (list_id, user_id) values (l.id, caller)
    on conflict do nothing;
  end if;
  return query select l.id, l.owner_id;
end;
$$;

-- Make a new link for a list shared by link. The old link stops working for
-- everyone, also for those who had opened it. Returns the new code.
create function public.regenerate_list_link(p_list_id uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  new_code text := replace(gen_random_uuid()::text, '-', '');
begin
  if not public.owns_list(p_list_id) then
    raise exception 'not_allowed';
  end if;
  update public.list_links set code = new_code, created_at = now() where list_id = p_list_id;
  if not found then
    raise exception 'list_not_shared_by_link';
  end if;
  delete from public.list_link_access where list_id = p_list_id;
  return new_code;
end;
$$;

-- Prepared for searchable profiles (no screen in v1): find people who chose to be
-- found, by the start of their @handle. At least 3 characters, at most 20 hits,
-- never yourself, never across a block.
create function public.search_profiles(p_query text)
returns table (id uuid, display_name text, handle text)
language sql stable security definer set search_path = public as $$
  select p.id, p.display_name, p.handle
  from public.profiles p
  where auth.uid() is not null
    and char_length(p_query) >= 3
    and p.discoverable
    and p.handle is not null
    and p.handle like replace(replace(replace(lower(p_query), '\', '\\'), '%', '\%'), '_', '\_') || '%'
    and p.id <> auth.uid()
    and not public.is_blocked(p.id)
  order by p.handle
  limit 20;
$$;

-- -----------------------------------------------------------------------------
-- 5. Row Level Security
-- -----------------------------------------------------------------------------

alter table public.profiles      enable row level security;
alter table public.connections   enable row level security;
alter table public.invites       enable row level security;
alter table public.lists         enable row level security;
alter table public.list_shares   enable row level security;
alter table public.list_links    enable row level security;
alter table public.list_link_access enable row level security;
alter table public.blocks        enable row level security;
alter table public.wishes        enable row level security;
alter table public.list_items    enable row level security;
alter table public.wish_audience enable row level security;
alter table public.reservations  enable row level security;

-- profiles: yourself and your contacts.
create policy profiles_select on public.profiles for select to authenticated
  using (public.can_see_profile(id));
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- connections: both people see it, either may end it. Created only by accept_invite().
create policy connections_select on public.connections for select to authenticated
  using ((select auth.uid()) in (user_a, user_b));
create policy connections_delete on public.connections for delete to authenticated
  using ((select auth.uid()) in (user_a, user_b));

-- blocks: only the one who blocked sees and lifts the block. Lifting a block does
-- not bring anything back.
create policy blocks_select on public.blocks for select to authenticated
  using (blocker_id = (select auth.uid()));
create policy blocks_insert on public.blocks for insert to authenticated
  with check (blocker_id = (select auth.uid()));
create policy blocks_delete on public.blocks for delete to authenticated
  using (blocker_id = (select auth.uid()));

-- invites: only the inviter sees and revokes their own.
create policy invites_select on public.invites for select to authenticated
  using (inviter_id = (select auth.uid()));
create policy invites_insert on public.invites for insert to authenticated
  with check (inviter_id = (select auth.uid()));
create policy invites_delete on public.invites for delete to authenticated
  using (inviter_id = (select auth.uid()));

-- lists: the owner does everything; others see a list only when it is shared with them.
create policy lists_select on public.lists for select to authenticated
  using (owner_id = (select auth.uid()) or public.can_view_list(id));
create policy lists_insert on public.lists for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy lists_update on public.lists for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy lists_delete on public.lists for delete to authenticated
  using (owner_id = (select auth.uid()));

-- list_shares and wish_audience: who is chosen is the owner's business alone, and
-- only contacts can be chosen.
create policy list_shares_select on public.list_shares for select to authenticated
  using (public.owns_list(list_id));
create policy list_shares_insert on public.list_shares for insert to authenticated
  with check (public.owns_list(list_id) and public.is_connected(person_id));
create policy list_shares_delete on public.list_shares for delete to authenticated
  using (public.owns_list(list_id));

-- list_links: the code is the owner's alone. Written only by triggers and
-- regenerate_list_link().
create policy list_links_select on public.list_links for select to authenticated
  using (public.owns_list(list_id));

-- list_link_access: the owner sees who has opened the link and can remove them;
-- a person sees and can drop their own access. Written only by open_list_link().
create policy list_link_access_select on public.list_link_access for select to authenticated
  using (user_id = (select auth.uid()) or public.owns_list(list_id));
create policy list_link_access_delete on public.list_link_access for delete to authenticated
  using (user_id = (select auth.uid()) or public.owns_list(list_id));

create policy wish_audience_select on public.wish_audience for select to authenticated
  using (public.owns_wish(wish_id));
create policy wish_audience_insert on public.wish_audience for insert to authenticated
  with check (public.owns_wish(wish_id) and public.is_connected(person_id));
create policy wish_audience_delete on public.wish_audience for delete to authenticated
  using (public.owns_wish(wish_id));

-- wishes: the owner does everything; others read when can_view_wish says so.
create policy wishes_select on public.wishes for select to authenticated
  using (owner_id = (select auth.uid()) or public.can_view_wish(id));
create policy wishes_insert on public.wishes for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy wishes_update on public.wishes for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy wishes_delete on public.wishes for delete to authenticated
  using (owner_id = (select auth.uid()));

-- list_items: the owner sees and changes them; others see that a wish is in a list
-- only when they can see both.
create policy list_items_select on public.list_items for select to authenticated
  using (public.owns_list(list_id) or (public.can_view_list(list_id) and public.can_view_wish(wish_id)));
create policy list_items_insert on public.list_items for insert to authenticated
  with check (public.owns_list(list_id) and public.owns_wish(wish_id));
create policy list_items_delete on public.list_items for delete to authenticated
  using (public.owns_list(list_id));

-- reservations: the one who reserved, and everyone else who can see the wish.
-- Never the wish's owner.
create policy reservations_select on public.reservations for select to authenticated
  using (
    reserved_by = (select auth.uid())
    or public.can_view_wish(wish_id)
  );
create policy reservations_insert on public.reservations for insert to authenticated
  with check (
    reserved_by = (select auth.uid())
    and public.can_view_wish(wish_id)
    and not public.owns_wish(wish_id)
  );
create policy reservations_delete on public.reservations for delete to authenticated
  using (reserved_by = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- 6. Privileges. Nothing by default; authenticated gets only what the app uses.
-- -----------------------------------------------------------------------------

revoke all on public.profiles, public.connections, public.blocks, public.invites, public.lists,
              public.list_shares, public.list_links, public.list_link_access, public.wishes,
              public.list_items, public.wish_audience, public.reservations from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (display_name, birthday, handle, discoverable) on public.profiles to authenticated;

grant select, delete on public.blocks to authenticated;
grant insert (blocked_id) on public.blocks to authenticated;

grant select, delete on public.connections to authenticated;

-- invites: every column comes from a default, so the app inserts an empty row.
grant select, delete on public.invites to authenticated;
grant insert (expires_at) on public.invites to authenticated;

grant select, delete on public.lists to authenticated;
grant insert (title, share), update (title, share) on public.lists to authenticated;

grant select, delete on public.list_shares to authenticated;
grant insert (list_id, person_id) on public.list_shares to authenticated;

grant select on public.list_links to authenticated;
grant select, delete on public.list_link_access to authenticated;

grant select, delete on public.wishes to authenticated;
grant insert (title, note, url, price, currency, store_name, image_path, audience),
      update (title, note, url, price, currency, store_name, image_path, audience)
  on public.wishes to authenticated;

grant select, delete on public.list_items to authenticated;
grant insert (list_id, wish_id) on public.list_items to authenticated;

grant select, delete on public.wish_audience to authenticated;
grant insert (wish_id, person_id) on public.wish_audience to authenticated;

grant select, delete on public.reservations to authenticated;
grant insert (wish_id) on public.reservations to authenticated;

-- An invite may only be shortened, never lengthened past 7 days.
alter table public.invites add constraint invites_max_7_days
  check (expires_at <= created_at + interval '7 days');

-- Functions: nobody by default, the signed-in user only where the app needs it.
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function
  public.is_connected(uuid), public.is_blocked(uuid), public.owns_list(uuid), public.owns_wish(uuid),
  public.can_view_list(uuid), public.can_view_wish(uuid), public.can_see_profile(uuid),
  public.can_view_image(text), public.preview_invite(text), public.accept_invite(text),
  public.open_list_link(text), public.regenerate_list_link(uuid), public.search_profiles(text)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Storage: private bucket for wish photos, one folder per owner.
--    Path: <owner_id>/<file>. Photos are resized and re-encoded on the phone
--    before upload, which drops the EXIF data, location included.
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('wish-images', 'wish-images', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']);

create policy wish_images_select on storage.objects for select to authenticated
  using (
    bucket_id = 'wish-images'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or public.can_view_image(name))
  );
create policy wish_images_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'wish-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy wish_images_update on storage.objects for update to authenticated
  using (bucket_id = 'wish-images' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'wish-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy wish_images_delete on storage.objects for delete to authenticated
  using (bucket_id = 'wish-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
