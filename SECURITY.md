# Security Policy

Backup Manager runs as root, unattended, from cron, on machines nobody is
watching, and it holds what is often the only remaining copy of someone's data.
A defect here is not an inconvenience. This page says how to report one and what
happens next.

## Supported versions

| Version | Supported |
|---|---|
| 1.0 and later | Yes |
| 0.7.x and earlier | No |

If you run a distribution package, report the issue here anyway. We will
coordinate with the Debian and Ubuntu maintainers, who carry this tool to far
more machines than our own releases do.

## Reporting a vulnerability

**Use the "Report a vulnerability" button in the [Security tab](https://github.com/sukria/Backup-Manager/security/advisories/new).**
It reaches the maintainers privately. Nothing you write there is visible to
anyone else.

**Please do not open a public issue for a vulnerability**, even a small one, and
even if you already have a patch. Once a defect is described publicly, every
installation running the affected version is identified and exploitable until
the distributions ship an update, which takes weeks.

If you cannot use the button for any reason, open an issue saying only that you
have a security report and nothing else, and a maintainer will come to you.

A report is more useful than a perfect report. If you are unsure whether what
you found is a vulnerability, send it anyway.

## What happens next

1. **Within 7 days**: you get an acknowledgement, and our first read of whether
   we can reproduce it.
2. **We work on a fix in private**, in a temporary private fork attached to the
   advisory. You are credited unless you ask not to be.
3. **We publish** the advisory with a CVE once the fix is released. Publication
   is what alerts the distributions and the vulnerability databases, so it
   matters as much as the patch.
4. **Within 90 days** of your report, the advisory is published whether or not
   a complete fix exists. A defect held indefinitely because it is hard to fix
   is a defect kept secret from the people it affects, and that is not a
   trade we make.

If you intend to publish on your own schedule, tell us in the report. We will
work to yours rather than argue about it.

## How we handle our own findings

This project runs a monthly automated audit, described in
[AI_POLICY.md](AI_POLICY.md). Any finding it rates critical or high goes
through the same private advisory channel as an outside report: fixed first,
published after, with a CVE.

**No unfixed vulnerability is ever filed as a public issue**, including ones we
found ourselves. The public backlog shows security work only once it is done.

Lower-severity findings, such as hardening with no concrete exploit path, are
handled as ordinary issues in the open.
