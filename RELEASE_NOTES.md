# v1.9.0 — Full-Clone Export/Import for Server Migration

> **Release date:** 2026-07-31

Migrate your entire Lucy/OpenClaw setup between servers in two commands.

---

## What's New

- 📦 **Full-clone export** — New `scripts/export-full-clone.sh` bundles your complete OpenClaw installation (`openclaw.json`, `lucy-agent/`, `workspace/`) into a portable `lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz`
- 📥 **Full-clone restore** — `install.sh --full-clone <path-or-url>` restores the bundle on a new server, with automatic backup, config validation, and model verification
- 🔒 **Safe by default** — auth tokens, credentials, device identity, and `.env` files are excluded unless you explicitly opt in
- 🔑 **`--include-identity`** — opt-in flag to include `identity/`, `credentials/`, `.env`, and auth profiles for a private full clone (prints a security warning)
- 🧠 **`--exclude-memories`** — export your config without session memory history (`MEMORY.md`, `memory/`)
- 🛡️ **Automatic backup** — existing `~/.openclaw` is moved to `~/.openclaw.backup.<timestamp>/` before any restore

## How It Works

**On the source server (export):**

```bash
bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh
# → lucy-full-clone-20260731-150000.tar.gz (no auth/identity/.env)

# Include auth + identity (private clone):
bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --include-identity

# Config without conversation history:
bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --exclude-memories
```

**On the target server (restore):**

```bash
curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --full-clone ./lucy-full-clone-20260731-150000.tar.gz
```

The installer backs up the existing `~/.openclaw`, restores the bundle, runs `openclaw config validate` + `openclaw models list`, and reminds you to re-authenticate providers/channels (unless the bundle included identity).

## What's Changed

- **install.sh** — new `--full-clone` flag, `step_restore_full_clone()`, full-clone mode in TUI/main flow, mutual exclusion with `--clone`/`--template`/`--skip-workspace`
- **update.sh / verify.sh** — version bumped to v1.9.0, new full-clone checks
- **README.md** — What's New section, install examples, version badge
- **CHANGELOG.md** — v1.9.0 entry

## Upgrade Notes

1. **New feature, no breaking changes.** All existing install modes and flags continue to work.
2. **For existing installations:** run `cd ~/.openclaw/lucy-agent && ./update.sh` to get the exporter script.
3. **Security:** the default bundle contains no authentication material. If you use `--include-identity`, keep the bundle private and delete it when no longer needed.
4. **Re-auth reminder:** after a `--full-clone` restore without identity, re-authenticate with `openclaw configure --section model`.
