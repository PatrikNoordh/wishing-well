#!/usr/bin/env bash
# English is the working language (CLAUDE.md § Language). Fails if a tracked file
# outside the allowlist contains a Swedish letter: a with ring, a or o with
# diaeresis, in either case. The letters are matched as UTF-8 bytes, so this
# script holds none of them itself.
#
# Allowlist:
#   src/locales/sv.json                    the Swedish translation of the UI
#   src/locales/native/sv.json             the Swedish system texts (permissions), for app.json locales
#   docs/ui-spec.md                        the glossary table "UI terms (en → sv)"
#   docs/journal.md                        quotes the app's old name as history
#   docs/decisions/0011-name-and-slogan.md quotes the app's old name as history
#
# Usage: bash scripts/check-english.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

export ALLOW='^(src/locales/sv\.json|src/locales/native/sv\.json|docs/ui-spec\.md|docs/journal\.md|docs/decisions/0011-name-and-slogan\.md)$'
git ls-files -z | perl -0 -ne '
  BEGIN { $| = 1 }
  chomp;
  next if $_ =~ $ENV{ALLOW} || !-f $_;
  my $file = $_;
  open(my $fh, "<:raw", $file) or die "cannot read $file\n";
  my $text = do { local $/; <$fh> } // "";
  close $fh;
  next if substr($text, 0, 8000) =~ /\0/;  # binary, as git decides it
  my $n = 0;
  for my $line (split /\n/, $text) {
    $n++;
    if ($line =~ /\xC3[\xA5\xA4\xB6\x85\x84\x96]/) { print "$file:$n: $line\n"; $found++ }
  }
  END {
    if ($found) { print STDERR "\nSwedish outside src/locales/sv.json (CLAUDE.md § Language): $found line(s).\n"; exit 1 }
    print "English only: no Swedish outside the allowlist.\n";
  }
'
