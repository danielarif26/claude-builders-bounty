# Changelog Generator — Bounty #1 ($50)

A dependency-free `CHANGELOG.md` generator built from git history, plus the
matching Claude Code `SKILL.md`.

## What it does

`bash changelog.sh` reads `git log` since the most recent tag, categorizes each
commit into **Added / Fixed / Changed / Removed**, and writes a structured
`CHANGELOG.md`. No network, no dependencies, no install.

## Files

| File           | Purpose                                                |
| -------------- | ------------------------------------------------------ |
| `changelog.sh` | The generator. bash + git only.                        |
| `SKILL.md`     | Claude Code skill definition (`/generate-changelog`).  |
| `CHANGELOG.md` | Sample output from running the script on this repo.    |

## Try it

```bash
bash changelog.sh                 # writes CHANGELOG.md since the last tag
CHANGELOG_OUT=- bash changelog.sh # stdout only
CHANGELOG_SINCE=v1.0.0 bash changelog.sh
```

## Categories

| Prefix                       | Section  |
| ---------------------------- | -------- |
| `feat:`, `add:`, `new:`      | Added    |
| `fix:`, `bugfix:`, `hotfix:` | Fixed    |
| `remove:`, `delete:`, `rm:`  | Removed  |
| anything else                | Changed  |

## License

MIT