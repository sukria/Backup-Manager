# AGENTS.md

Guidance for coding agents and human contributors working on Backup Manager.
It is short on purpose. If a rule here is not followed, the change gets sent
back.

## Project

Backup Manager is a command line backup tool for GNU/Linux, written in Bash and
Perl, licensed GPL-2.0. It runs unattended on other people's servers, and the
data it handles is the only copy some of them have. Caution beats cleverness.

AI assistance on this project is governed by [AI_POLICY.md](AI_POLICY.md). No
change reaches `master` without a human maintainer reading it.

## English only

**Everything written in this repository and around it is in English**: code,
identifiers, comments, commit messages, documentation, issues, pull requests,
code reviews and review replies, including replies to a comment written in
another language. The only exception is `po/`, which holds the translations.

The project has contributors and users worldwide. A thread they cannot read is
a thread they cannot help with.

## Branches

Pull requests start from `devel` and target `devel`. `master` only receives
merges from `devel` at release time.

## Running the tests

```bash
cd t && ./run-tests.sh
```

Each `tNN-*.sh` file is a standalone scenario and can be run on its own with
`bash t14-purging-system.sh`. Shared helpers live in `t/testlib.sh`, fixture
configurations in `t/confs/`.

A change to backup, purge or upload behaviour comes with a test. A bug fix
comes with the test that fails without it.

## Conventions

- Shell code follows the surrounding style: `lower_case` function names,
  `BM_`-prefixed configuration variables, `__`-prefixed internal helpers.
- Configuration variables are public API. Renaming or removing one, or changing
  what it accepts, breaks existing `backup-manager.conf` files in the field.
- Archive file names and the `$TODAY` date format are public API too: hooks,
  cron jobs and user scripts depend on them. Keep old formats readable.
- A new configuration variable is documented in `backup-manager.conf.tpl`, in
  `doc/user-guide.sgml` and in the relevant `man/*.8` page.
- User-facing strings go through `gettext`, never hardcoded.
- Keep commits focused: one concern per commit, one subject line that says what
  changed.

## Security

This tool runs as root from cron on machines nobody watches, and it is packaged
by Debian and Ubuntu. A vulnerability here reaches far more installations than
this repository's own releases, and it reaches them slowly, through
distribution updates that take weeks.

**Never describe an unfixed vulnerability anywhere public.** Not in an issue,
not in a pull request title or body, not in a commit message, not in a code
comment, not in the ChangeLog. The moment a defect is described publicly, every
installation running the affected version is both identified and exploitable
until the distributions catch up.

That holds whoever found it: an outside reporter, a maintainer, or the monthly
automated audit. [SECURITY.md](SECURITY.md) is the reporting channel,
[AI_POLICY.md](AI_POLICY.md) covers the audit.

### Working on a security fix

1. **It starts as a private advisory**, not an issue. The fix is developed in
   the temporary private fork attached to it.
2. **The commit message and the pull request say what the code does, not what
   it protects against.** "Quote the repository path in the purge loop" is
   enough. Do not write "fixes an injection that lets a crafted archive name
   run arbitrary commands" before the advisory is published.
3. **No proof-of-concept anywhere.** Not in the advisory body, not in a test,
   not in a fixture file. A regression test asserts the correct behaviour; it
   does not ship a working exploit.
4. **Publication comes after the release.** The advisory is published with a
   CVE once the fix ships, which is what alerts the distributions and the
   vulnerability databases. Only then does the ChangeLog describe the defect.

**A hardening change with no concrete exploit path is ordinary work**, and goes
through the normal public flow. Quoting a variable, tightening a file mode,
checking an exit code: do those in the open. The private path is for a defect
somebody could act on.

## Backward compatibility

**This is the rule that matters most here, and it outranks every other
consideration in this file.**

This tool has been running in production since 2005. It is packaged by Debian
and Ubuntu, it runs as root from cron on machines nobody is watching, and its
job is to hold the only remaining copy of someone's data. A configuration file
written fifteen years ago is still a supported input. Somebody out there is
running a version two releases old and will upgrade to yours without reading
anything.

So: **an established behaviour is a contract, whatever its age and whether or
not it was ever documented.** An upgrade must never orphan existing archives,
silently stop purging them, turn an incremental backup into a full one, or make
an existing `backup-manager.conf` stop working. When a format changes, the new
code still reads what the old code wrote.

The burden of proof is on the change, never on the existing behaviour. "Nobody
could reasonably depend on this" is not an argument that carries here.

### Nothing breaks without an incubation period

When a change really is necessary, it goes through deprecation. It does not go
straight in.

1. **The old form keeps working**, and keeps producing the same result.
2. **A warning tells the user what to do instead**, naming both the old and the
   new form. The mechanism already exists: `confkey_handle_deprecated` in
   `lib/sanitize.sh` honours the old key, warns, and feeds the new one.
   Use it rather than inventing something.
3. **The deprecation ships in a release and lives there**, long enough for the
   distribution packages to carry it and for users to meet the warning.
4. **Removal is a separate, later, deliberate decision**, announced in the
   ChangeLog. It is never a side effect of the change that introduced the
   replacement.

A warning the user can act on is always preferable to a failure, and a failure
is always preferable to silence. Degrading quietly is the worst of the three:
this tool is read by nobody on the day it runs, so a behaviour change that
produces no message produces no backup either, and nobody finds out until they
need the data.

### What counts as a public contract

Not just the documented surface. All of it:

- Every `BM_*` configuration variable, its name, and what it accepts.
- Archive file names and the `$TODAY` date format. Hooks, cron jobs and user
  scripts parse them.
- Every variable exported to `BM_PRE_BACKUP_COMMAND` and
  `BM_POST_BACKUP_COMMAND`.
- Command line flags of `backup-manager`, `backup-manager-purge` and
  `backup-manager-upload`.
- Exit codes, and the md5 database format.

Touching any of these is a deprecation cycle, not an edit.
