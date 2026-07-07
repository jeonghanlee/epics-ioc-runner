# EPICS IOC Runner — Milestone Register

Single, unified, repository-local source of truth for milestone and
carry-forward status. Every agent and contributor reads this file instead of
chat history or memory. GitHub milestone state and issue `Closes`/`Refs`
footers are authoritative; this register reconciles them into one readable
view.

**Release convention:** this is one unified register, not a per-version file.
On each release the register is cleared and restarted for the next cycle; the
released milestone's full record is preserved in the matching git tag
(`git show <tag>:docs/milestone.md`). The 1.2.0 record lives in
`git show 1.2.0:docs/milestone.md`.

**1.2.1 release target:** 2026-07-31, per the GitHub milestone `1.2.1`
due date. Stability patch — make what 1.2.0 already does
honest and robust, with no redesign. Sourced from the ten-reviewer full-code
review at 1.2.0 (session rs20260706_180525, convergence conv20260706_203134)
plus the conceptual-integrity sweep; all review decisions adopted per
Facilitator recommendation (User, 2026-07-06): U-1 emit
RuntimeDirectoryPreserve, U-3 single-word IOC_CMD contract, U-4 hard error on
unknown-name verbs, U-5 view nonzero / ss gated on -vv, U-6 conf-mtime drift
warning, U-9 policy set accepted, CI-F charset guard adopted. U-2 (FATAL
boundary form) and U-7 (kill-based E2E) belong to the 1.3.0 items they gate.

**Next session entry point:** start M1 (verify-exit contract) — the
three-lane-converged top cluster. Milestones are ordered so behavior-visible
changes (M2, M5, M6) land before the M10 golden gate; the M10 bake doubles as
the ansible/cloud-provision U8 first-joint-tag event.

## Work Register

| ID | Version | Work unit | Type | Status | Evidence / scope |
| --- | --- | --- | --- | --- | --- |
| M1 | 1.2.1 | (#104) Verify-exit contract: setup exits 1 on VERIFY_FAIL>0; verify helpers abort-proof (missing path counts a FAIL, never kills the run) | Review follow-up | Done (code; M10 gate pending) | R5-F1/R7-F1/R9-F1 (three-lane convergence C1), R7-F12/R9-F3. Golden harness exit-code expectations confirmed (R7 Q3: no suite executes-and-asserts). Executed 2026-07-06 via 5-lane x 2-round session rs20260706_223322 (10 approvals; conv20260706_225422): AC1-AC3/AC5 demonstrated (transcript in session), AC4 error-suite 148/148; system-infra AC4 half deferred to M10. Issue #104 left open for the landing review. |
| M2 | 1.2.1 | (#105) Lifecycle verb honesty: conf-existence gate on stop/enable/disable/remove (U-4 hard error); remove verifies its outcome and surfaces stop/disable stderr; view exits nonzero on missing conf; list gates ss on -vv with a named error; local IOC_PORT rewrite warns (U-5) | Review follow-up | Open | C7 (R1-F1/F2/F4/F5), C8 (R1-F6/F7, R9-F6), R1-F8. |
| M3 | 1.2.1 | (#106) Crash-scan input guards: _EXTRA runtime compile probe with one Warning + install-time canary probe + structural rejection of empty alternations; conf-newer-than-activation mtime warning (U-6) | Review follow-up | Open | C3 (baseline F1, R2-F1, R9-F5, R4-F6, R10 RA-3), R10 OQ3/G1. |
| M4 | 1.2.1 | (#107) Atomic deployment sweep: stage-in-target-dir + mv for runner/unit/completion in setup and for do_generate (0660 in system mode) | Review follow-up | Open | C4 (R7-F7, R9-F2, R4-F3); pattern already owned by deploy_local_logrotate. |
| M5 | 1.2.1 | (#108) Supervision unit completion: emit RuntimeDirectoryPreserve=restart in BOTH templates (U-1, completes ADR 0001 C004/C005); phase-2 dwell rotation fingerprint + final post-dwell banner check | Review follow-up | Open | R10 RA-1/R10-F3, C5 (R2-F4/F6, R6-F6). Template contract guard rows extend accordingly. |
| M6 | 1.2.1 | (#109) Drift-warning completion + conf contract: baked-LOG_DIR comparison at local start (covers XDG drift), CONF_DIR absolute/whitespace guard, local RUN_DIR divergence warning, IOC_CHDIR absolute required in validate_conf, IOC_CMD single-word enforcement (U-3) | Review follow-up | Open | C6 (R6-F1/F7, R3-F7, R4-F4), R4-F2. |
| M7 | 1.2.1 | (#110) Small hardening set: logrotate edges (guarded mkdirs, honest enable-failure recovery text, dead-timer warning in local list); capability probes via captured output (:924/:1546); setup extras (procServ preflight, cmp-guarded backups, repo-identity check before git stamping, getfacl verification, #87 resolved-identity banner + sudo env_reset doc caveat) | Review follow-up | Open | R6-F2/F4/F5, C9 (R9-F4, R3-F5), R7-F5/F6/F8/F9/F11. |
| M8 | 1.2.1 | (#111) Test honesty: exact `Active: active` token in both status tests; monitor-isolation positive control; wait_for_state timeouts count FAILs; tests/README truth pass; NEW charset-parity guard pinning validate_ioc_name == sudoers regex (CI-F) | Review follow-up | Open | R8-F1/F2/F4/F6; CI sweep CI-F (verified unpinned 2026-07-06). |
| M9 | 1.2.1 | (#112) Docs truth pass (one coordinated commit set): CLI_REFERENCE monitor fallbacks; FAQ Q6 C1+H revival + ^T note; FAQ Q7 corroboration wording + _EXTRA -i note; FAQ Q2 pass-through correction + IOC_META_ normative; socket 0770-dir/0660-file correction + PERMISSION_MODEL socket section + 1.2.1 refresh + conf-integrity boundary sentence + M19 objects; USER_GUIDE_LOCAL env tables + rotation section; INSTALL 2.3 regex padding (verify on golden, R7 Q1) + 2.4 unit block; UNINSTALL logrotate reversal + log-retention statement; version examples; ADR 0001 note that U-1 emission landed; U-9 policy sentences (marker-trust ADR note, NFS-hang folded into #102 acceptance, nc.openbsd unsupported, logrotate edits-not-preserved contract, untrusted-HOME statement); record three Keep (examined, no action) verdicts — #81-guarded template pair, #87-guarded identity, #86 socket alias | Review follow-up | Open | C10 (R3-F1..F4, R7-F2/F3/F4, R5-F2/F3, R6-F9, R10-F1/F2/F4/F5/F6/F7, R8-F6 doc half), R4-F5, U-9, CI sweep Keep set. |
| M11 | 1.2.1 | (#119) Field bug: nested sudo (sudo make setup) rewrites SUDO_USER=root and defeats the git-stamp delegation (hash stamps unknown via silent dubious-ownership failure); plain make setup dies with the bare sudo error against the README promise. Fix: repo-owner fallback for the delegation target + WARN on unknown fallback + sudo -n guidance gate in the make recipes | Bug | Done (code; M10 gate pending) | Reported by owner on host charm 2026-07-07 (master @ 1.2.0); reproduced by transcript; ansible path unaffected (role sets SUDO_USER). Fixed 2026-07-07 via 2-lane session rs20260707_063000 (L1 required changes adopted: id -u guard, broader root-invoker engagement incl. direct root shell); AC1 six derivation shapes + AC2/AC3 demonstrated (transcript in session), AC4 error suite PASS. Latent same-pattern noted in tests (test-system-infra:424, run-all-tests:106) — deferred, see M8 scope adjacency. Issue #119 left open for the landing review. |
| M10 | 1.2.1 | Release gate: T2-class golden verification of the patch (all four suites, both modes, both goldens) — this bake is also the ansible/cloud-provision U8 first-joint-tag event | Release gate | Open | Gate criteria per testplan_1.2.0.md pattern; U8 cross-repo tag is User-run at this event. |

## Carry-Forward (1.3.0 — reliability cycle; recorded, not scheduled)

| Work unit | Source | Note |
| --- | --- | --- |
| Detection-layer design: #102 running-IOC hang + conf-skew/disk-full/NFS-outage detectability | SG-D, R10 gap ranking, backlog #102 | The 1.3.0 theme. |
| (#113) Conf parser unification (single parse core, trim + last-wins + tab) + divergence fixtures | C2 (R2-F2/R4-F1), R8-G4 | Behavior-visible; needs its own review. |
| (#114) FATAL-subset boundary hygiene (U-2 portable class) + golden rerun | R2-F5 | Pairs with E2E probe. |
| (#115/#116) E2E restart-supervision probe on goldens (U-7 approved) + #98 tripwire port to three suites + M19 oneshot via systemd | R8-G1/F5/G3 | Test-infrastructure block. |
| (#117) Local-install deploy-after-gates reordering | R1-F3 | do_install flow refactor. |
| Deferred minor pool: fast-path window cap (R2-F7), NUL handling (R2-F3), coverage gaps G5-G8, co-residence workspace guard (U-8 second half), polish lists of all ten artifacts | Review artifacts | Scope decided at 1.3.0 opening. |

## External Gates

| Gate | State |
| --- | --- |
| ansible/cloud-provision U8 first joint tag (1.0) | Fires at the M10 bake; User-run. |
| INSTALL 2.3 padded-regex verification on a sudo>=1.9.10 golden (R7 Q1) | Needed inside M9; one visudo/sudo -l check. |

**Tally:** milestones Open 10 (M2-M9 + M10 gate + M11), Done 1 (M1 code) · carry-forward (1.3.0) 6 recorded · blocked 0.

## Update Protocol

When a milestone is completed, update this register in the same commit as the
substantive change. Any commit that changes a playbook-equivalent contract
(unit template rows, sudoers emission, doc-pinned behavior) updates the
mirroring documents in the same commit. GitHub issue state changes are
reflected in the next documentation commit.
