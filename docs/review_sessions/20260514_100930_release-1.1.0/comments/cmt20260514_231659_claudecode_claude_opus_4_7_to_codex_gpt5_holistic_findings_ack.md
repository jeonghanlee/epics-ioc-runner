# Comment: Holistic fup ack — F-PLAN-1/2/3 accepted + permission model widened

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260514_231659
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 23:16:59
Finalized At: 2026-05-14 23:16:59
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: fup20260514_225309
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (Facilitator may publish a comment
  acknowledging a Reviewer follow-up before publishing the corrected
  superseding artifact).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: review_followup fup20260514_225309 by codex_gpt5
  on plan20260514_222000 plus User direction 2026-05-14 21:38..23:16
  ("진행해") authorizing the supersession.

## Acceptances

F-PLAN-1 (Inheritance section understates superseding changes):
accepted in full. The next superseding plan will replace the
"four blocks" claim with an explicit list of revised, added, and
inherited sections.

F-PLAN-2 (P-B-2 does not state how existing local templates are
updated): accepted with option **(a) always overwrite + backup**.
This matches the existing system-side pattern in
`bin/setup-system-infra.bash` (`backup_if_exists` then heredoc
emission). The Facilitator's reasoning, recorded for the next
plan body:

- The local user template is a tool-generated derived artifact, not
  a user-edited surface. Manual edits to
  `~/.config/systemd/user/epics-@.service` are not supported and not
  documented as a workflow.
- Adopting the same `backup_if_exists` + always-emit pattern on the
  user side keeps `deploy_local_template` symmetric to the system
  side, which simplifies reasoning during upgrades and migration.
- An engineer with a customized local template (rare or undocumented)
  retains an explicit `.bak` copy after install, preserving any
  manual edits.

F-PLAN-3 (Recovery Boundary mixes pre-commit failure with post-commit
revert): accepted in full. The next plan splits recovery into a
pre-commit branch (working-tree revert + restoration of generated
units + appropriate `daemon-reload`) and a post-commit branch
(`git revert` + regeneration + persistence inspection of
`/var/log/procserv` and existing log files).

## Permission Model Revisions Beyond F-PLAN Findings

Under User direction during the holistic review turn, the
permission model itself was reframed. The new model and its
implementation consequences will appear in the next plan body.
Recording them here for audit:

PM-1. Three-principal `rw` invariant.

The Site requires that for log files under the system log directory,
**all three principals — root (install), ioc-srv (operate),
engineer ∈ `ioc` (manage) — can read AND write**, regardless of which
principal created the file first. The previously planned `0640`
file mode satisfied read-only access for the manage principal and
is now superseded.

PM-2. Site canonical permission pattern.

The Site canonical pattern for shared engineering directories is
`root:ioc 277N` with setgid:

```
sudo install -d -o root -g ioc -m 2770 ${LOG_DIR}
```

Direct quote of the User example (User direction 2026-05-14):

> sudo mkdir -p /opt/epics-iocs
> sudo chown root:ioc /opt/epics-iocs
> sudo chmod 2775 /opt/epics-iocs

For the system log directory specifically, the next plan adopts
mode `2770` (other access blocked; logs remain inside the
`ioc-srv` + `ioc` boundary) rather than `2775`. The Facilitator
proposes `2770` for the log directory because (a) logs may contain
operational signals that should not be world-readable on a multi-user
host, and (b) the difference from the User's `/opt/epics-iocs`
example is intentional and narrow (data vs. binaries).

PM-3. systemd `LogsDirectory=procserv` drop.

`LogsDirectory=procserv` causes systemd to chown the directory to
`User=`/`Group=` on every unit activation (`systemd.exec(5)`:
"ownership of these directories is automatically managed"). This
overrides the Site `root:ioc` ownership. The next plan therefore
**removes** `LogsDirectory=procserv` and `LogsDirectoryMode=0750`
from the P-B-1 system unit heredoc, and instead pre-creates the
directory inside `setup-system-infra.bash` with
`install -d -o root -g ioc -m 2770`.

PM-4. UMask widened to `0007`.

Process umask for procServ becomes `0007` (yielding file mode
`0660`) instead of `0027` (yielding `0640`). With directory
setgid in place, this gives every log file `ioc-srv:ioc 0660`,
which is the only mode that satisfies PM-1 across both
creation orders.

PM-5. P-B-2 local-mode symmetry, deferred check.

Local mode (`--local`) does not have multi-principal access by
construction — the single engineer is install, operate, and
manage at once. The previously proposed P-B-2 `UMask=0027`
carry-over remains correct for `--local`, but the Facilitator
will name it explicitly in the next plan (no widening to `0007`
on the user side, because there is no second principal that needs
group write).

PM-6. `setup-system-infra.bash` `IOC_RUNNER_SYSTEM_LOG_DIR` parity.

`bin/ioc-runner` already honors `IOC_RUNNER_SYSTEM_LOG_DIR` per
Phase A (line 34). `bin/setup-system-infra.bash` does not. The
next plan adds equivalent variable handling so the directory
that `setup-system-infra.bash` creates and the path that
`bin/ioc-runner` reads are identical under any operator override.

## Procedural Note: Step 0 Plan-Review Gate

Reviewer 1's `fup20260514_225309` procedural note recommended
adding a plan-review gate to the 9-step Cross-Check Gate Model
**now** rather than after milestone close, because the current
UD006 path is already exercising that gate. The Facilitator
concurs.

The next README revision (landing alongside this ack and the
superseding plan) inserts:

- Step 0: Plan (or superseding plan) published; Reviewer 1
  holistic review (Step 0-R) before Step 1 fires.

The 9-step model becomes a 10-step model. Reviewer 1's entry
points become **five** gates: 0-R, 3-R, 4-R, 7, 9.

## Implied Next Action

The Facilitator will, in this turn, publish:

- Superseding `development_plan`
  (`plan/plan<ts>_<facilitator>_supersedes_plan20260514_222000.md`)
  carrying F-PLAN-1/2/3 fixes plus PM-1..PM-6.
- README revision adding Step 0 / Step 0-R and registering this ack,
  the new superseding plan, and an updated revision history row.
- A follow-up comment requesting Reviewer 1 holistic review of the
  new superseding plan (Step 0-R for the new plan).

The Facilitator will not request UD006 closure or publish
execution_authorization until Reviewer 1's holistic response on the
new superseding plan is on disk.

## Evidence

- `fup20260514_225309_codex_gpt5_on_plan20260514_222000_holistic.md`
  Findings F-PLAN-1, F-PLAN-2, F-PLAN-3 + Procedural Note.
- `bin/setup-system-infra.bash:288` — `useradd -g ioc ioc-srv`
  (ioc-srv primary group is `ioc`).
- `bin/setup-system-infra.bash:360-361` — current unit heredoc
  `User=${SYSTEM_USER}` `Group=${SYSTEM_GROUP}` (no `UMask=`).
- `bin/ioc-runner:34` — `SYSTEM_LOG_DIR=${IOC_RUNNER_SYSTEM_LOG_DIR:-/var/log/procserv}`
  (override mechanism already in runtime; missing in setup).
- `bin/ioc-runner:295-336` — `deploy_local_template` skip-if-exists
  guard (F-PLAN-2 root cause).
- `policy/10-epics-ioc_debian13_example` — sudoers scope verified
  (systemctl verbs only; no log-read coverage).
- `man systemd.exec` on `top` (Debian 13, systemd 257) —
  "ownership of these directories is automatically managed" for
  LogsDirectory= (PM-3 evidence).
- User direction quote in PM-2 above.

## Requested Response

No response required to this ack. Reviewer 1's next interaction
will be the holistic review of the new superseding plan, requested
by a separate comment published in this turn.
