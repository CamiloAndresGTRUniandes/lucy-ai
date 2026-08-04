# v1.9.1 — Runtime + Orchestration Hardening Patch

> **Release date:** 2026-08-03

Package the safe runtime/orchestration improvements from the live workspace into a narrow Lucy-ai patch release.

---

## What's New

- 🪶 **Lighter bootstrap defaults** — `config/agent-fragment.json5` now ships `bootstrapMaxChars: 16000` and `bootstrapTotalMaxChars: 48000`
- 📋 **Aligned SDD pre-spawn notification** — the shipped orchestrator docs preserve the approved notification format with phase, primary model, timeout, and fallback model
- 🔁 **Consistent release surfaces** — installer, updater, verifier, README, changelog, and release notes now all reflect `v1.9.1`
- 🚫 **Honest scope boundary** — host-local mitigations stay out of the product release

## What This Release Does Not Ship

- Personal `plugins.allow` or `tools.allow` policy
- Watchdog services or timers added only to one host
- Direct edits to regenerated runtime files under `~/.openclaw/agents/`
- Claims that upstream OpenClaw runtime bugs are fixed by this Lucy-ai patch

## What's Changed

- **config/agent-fragment.json5** — bootstrap defaults reduced from `24000/80000` to `16000/48000`
- **sdd/orchestrator-flow.md** and **workspace/sdd/orchestrator-flow.md** — approved pre-spawn notification wording preserved in both shipped copies
- **install.sh / update.sh / verify.sh** — version-sensitive surfaces updated to `v1.9.1`
- **README.md / CHANGELOG.md / RELEASE_NOTES.md** — patch release framing updated for `v1.9.1`

## Upgrade Notes

1. **Patch release, no workflow break expected.** Existing install and update flows stay the same.
2. **For existing installations:** run `cd ~/.openclaw/lucy-agent && ./update.sh` to get the lighter bootstrap defaults and synchronized release metadata.
3. **For fresh installs:** `install.sh` now seeds the lower bootstrap limits by default through `config/agent-fragment.json5`.
4. **Scope boundary:** if you applied extra host-local runtime mitigations on one machine, keep managing those separately; they are not part of `v1.9.1`.
