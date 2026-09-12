# Contributing

Thanks for helping improve this project.

## Before you start

- Open an issue for larger changes before starting work.
- Keep changes focused and easy to review.
- Do not commit secrets, credentials, private URLs, or local machine files.

## Pull requests

Use the pull request template and include:

- What changed
- Why it changed
- How it was tested

## Local checks

Before opening a pull request:

- Run `bash -n scripts/*.sh`.
- Run `git diff --check`.
- Search the change for secrets, real network details, serial numbers, and private hostnames.
- Update README or docs when behavior changes.
- Test installation changes on the affected Bobcat variant when possible.

## Commit style

Use short, direct commit messages:

```text
Add setup instructions
Fix build command
Update wiring diagram
```
