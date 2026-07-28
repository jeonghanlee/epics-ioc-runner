# Closed Doors

> Write down the doors you decided to leave closed. The open ones announce
> themselves; the closed ones only cost you twice.
>
> — *The Door You Left Closed*, <https://github.com/jeonghanlee/essay-site>

Findings that a coherence sweep examined and deliberately left as they were.
Each row is one line and a commit: the reasoning lives in that commit, not
here. The list does not hold the argument — it gives the next sweep something
to read in one pass, so a settled question is recognized before it is derived
again from the start.

This file is not tied to a release cycle. `docs/milestone.md` is cleared when a
cycle opens; this one is not.

**Promotion test** — default is Keep; promotion to an enforced guard runs four
ordered gates, and elimination is tried before guarding: `3e47ee6`.

| ID | Examined | Verdict | Commit |
| --- | --- | --- | --- |
| CI-25 | procServ unit template kept as two copies rather than one emitter (#81) | Keep, guarded by the shared-contract test | `040f32f`, guard `7a3aeb2` |
| CI-26 | System service identity resolved independently in both scripts (#87) | Keep, pinned by the static identity guard | `96fc886` |
| CI-27 | Unify the `resolve_sock_path` callers (#86) | Keep B — the drift would be cosmetic, gate B fails | `ee82e09` |
| CI-28 | Do the `cmp`-identical skip paths leave a hand-loosened mode un-reasserted? Examined during the M3 (#123) review across every deploy site. | Keep, principled — the five setup mv-sites (`setup-system-infra.bash`) `chmod` the staged temp then `mv` unconditionally, so the mode is reasserted every run regardless of the backup skip; `deploy_local_logrotate` (`bin/ioc-runner:479-575`) skips the `mv` on identical content but asserts no mode (mktemp default, local user files under `~/.config`, 0600 is correct). Only `do_generate` skips a real mode assertion — fixed in M3, not a Keep. | review 2026-07-28 |

CI-1 through CI-24 were recorded in the register of the cycle that closed them:
`git show 1.2.0:docs/milestone.md`. The history answers directly too —
`git log --grep=examined-Keep`.
