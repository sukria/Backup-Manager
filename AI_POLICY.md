# AI Policy

> **TL;DR**. Backup Manager is maintained with the help of an AI agent named Kōan.
> Kōan opens pull requests, triages issues and runs security audits. It never
> merges, never releases, and never has the last word. A human maintainer reviews
> and merges every single change.

---

## Why this document exists

Backup Manager is an old project that runs on a lot of people's servers. You are
entitled to know who, or what, writes the code that touches your backups.

This page says exactly how AI is used here, and where it stops. It is updated
whenever the practice changes.

---

## The agent

The project is assisted by [Kōan](https://github.com/sukria/koan), an open source
autonomous agent written and operated by one of this repository's maintainers.

Kōan is not a service, not a black box, and not a third party: its source,
its prompts and its skills are public, and it runs on that maintainer's own
machine under their own GitHub account.

Work produced by Kōan is marked as such in the pull request body.

---

## What Kōan does on this project

### Pull requests

Kōan opens pull requests: bug fixes, refactors, test coverage, documentation.
They are a first pass, not a finished contribution. They get reworked, cut down
or closed like anybody else's.

### Issue replies

Kōan may answer issues: asking for a reproduction, pointing at the relevant code,
summarising a long thread. An answer from Kōan is labelled as such.

If you would rather talk to a human, say so in the thread. You will get one.

### Triage meta-issues

Kōan may open meta-issues that group and summarise the current state of open
issues and pull requests, so that the backlog stays readable. These are
housekeeping notes, not decisions.

### Security audits

Kōan runs a monthly audit of the codebase: static analysis, the usual classes
of defect, and dependencies with known CVEs.

**A finding it rates critical or high is filed as a public issue**, labelled
`security`. Lower-severity findings stay in the maintainer's notes.

That is a deliberate choice, and it deserves an explanation, because the
conventional advice is the opposite.

This project has no funded security team and no on-call. A vulnerability kept
in a private channel is a vulnerability nobody works on, and the backlog of
this repository is proof enough that quiet reports go stale here. A public
issue, on the other hand, gets read: by whoever wants to send the patch, and by
the Debian and Ubuntu maintainers who package this tool and who would otherwise
learn about the defect last. Disclosure is what gets a fix shipped.

So the trade is made openly: **we describe the defect, where it lives and what
it costs you, and we never publish a working exploit, a ready-to-paste payload,
or a recipe for abusing an installed system.** Enough to find and fix it, not
enough to hand it to somebody looking for targets. An issue of this kind is
triaged before anything else in the backlog.

A human verifies every finding before it is filed. Kōan does not decide what is
real.

**If you have found a vulnerability yourself**, you are welcome to open an issue
the same way. If you would rather not disclose it before a fix exists, that is a
legitimate position: say so in a thread without the details, or contact the
maintainer directly, and we will agree on a private channel.

---

## What Kōan does not do

| Kōan does not | A human maintainer does |
|---|---|
| Merge a pull request | Review and merge every one of them |
| Approve its own work | Decide what ships |
| Close an issue on its own | Judge whether a report is resolved |
| Tag, build or publish a release | Run every release by hand |
| Decide the direction of the project | Own the design and the roadmap |

Auto-merge is disabled on this repository. There is no path by which code
reaches `master` without a human reading it.

---

## Releases

Releases are cut by hand, by the same maintainers as always. Kōan may draft a
changelog entry; the tag, the build and the publication are human actions.

---

## Accountability

Nothing here dilutes responsibility. The maintainer who merges a change owns it,
whoever or whatever wrote the first draft. "The agent did it" is not an
acceptable answer to a regression, and it will never be used as one.

---

## Objections

If you are not comfortable with an AI-assisted contribution, say so in the
thread. It is a legitimate position and it will be heard, not argued down.

Open an issue if you have a question about this policy.

---

*[Alexis Sukrieh](https://alexissukrieh.com), co-maintainer of Backup Manager.*
