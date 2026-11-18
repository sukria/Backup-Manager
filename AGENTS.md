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

## Backward compatibility

This is the rule that matters most here. An upgrade must never orphan existing
archives, silently stop purging them, or turn an incremental backup into a full
one. When a format changes, the new code still reads what the old code wrote.
