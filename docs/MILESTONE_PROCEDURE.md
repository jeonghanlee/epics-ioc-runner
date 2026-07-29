# Milestone Procedure (working draft)

A per-milestone procedure for a release cycle, to be folded into a skill later.
General on its own; the 1.2.2 M2/M3/M4 runs are worked examples at the end.

A milestone here is one tracker issue with its register row and verification
subs (`M<n>.T<k>`). The order below is the order each milestone is taken through,
from plan to landed commit.

## The steps

1. **Plan review before code (conceptual integrity).** Read the finished code
   the milestone touches and recover *why* each piece took its shape before
   naming its fate (Keep / Replace / Generalize / Discard / the seam between
   two). Spawn independent reviewers who each read the essays
   (<https://jeonghanlee.github.io/essay-site/>) and verify against the code,
   ranking findings by reality
   (already-wrong-in-output > latent-reachable > cosmetic). Hunt two
   failure shapes specifically: a real **seam** where one piece leans on
   another's exact shape, and an **invented knot** — a dependency or problem
   written as real where none holds (a real constraint pushes back when broken;
   an invented one only quietly blocks the road).

2. **Owner gate — classify, present, do not record.** Sort candidates into
   three bins — confirmed finding, hypothesis, owner-decision-needed — each with
   `file:line`. Bring them to the owner. For any candidate with more than one
   defensible fate, the owner chooses; do not pre-decide and bury it. Write to
   the register only after direction.

3. **De-knot and reflect.** Remove the invented knots the owner confirmed;
   narrow the milestone to its real target. Record each *examined, no action*
   verdict as a one-line Keep in `CLOSED_DOORS.md` (a nothing is also a result;
   the next sweep must not re-hunt it). Reflect the corrected scope, the honest
   dependency wording (work-ordering vs a real code dependency), and the sub
   split into the register, the issue body, and the cycle plan.

4. **Implement.** Make the change, matched to the surrounding code's idiom.

5. **Verify on the real path.** A green counts only when the real shipped path
   ran on the real condition — no stubs of internal functions, no hand-built
   reproduction of the answer. Add permanent regression tests that drive the
   real path and would go **red** on the un-fixed code (guard against vacuous
   always-green assertions). Run the affected suites on both goldens.

6. **Reconcile and land.** Move the register subs and the issue checkboxes to
   done with the evidence (counts, host); set the next-session entry point.
   Commit code + tests + docs as one coupled change; the issue body edit and the
   git commit/push are owner-run unless delegated in the same request.

## Principles carried through (from the essays)

- Recover the premise before the fate; the code read alone will not tell you
  which of the five you are standing in.
- Before sequencing steps, look whether the thing is already there — do not tie
  a dependency the world does not ask for.
- Verification counts only when the real path ran; better an honest red than a
  fabricated green.
- Record the verdict, not just the finding; keep even the doors you left closed.
- The owner signs. Bring findings to the owner before recording, and vouch only
  for what you actually ran.

## Worked examples (1.2.2 cycle, 2026-07-28)

### M2 (#128) — root_squash version stamping
- **Review found:** `sudo make setup` is not a viable entry point on
  root_squash (make-as-root cannot read its own Makefile includes) — an
  entry-point correction, not a stamping fix; and a planned
  "delegation-unavailable" repair-WARN branch was **unreachable dead code**
  (no-sudo + unreadable tree means root cannot read the setup script at all).
- **De-knot:** dropped the dead branch; folded the manual-repair guidance onto
  the reachable "metadata unavailable" WARN instead.
- **Verified:** three documented entry points stamp a real hash on both goldens;
  manual repair restores `-V` end-to-end. Permanent test
  `test_setup_stamp_layout_guard` runs the real STEP 7 into a scratch tree.

### M3 (#123) — mode reassert + runner backup filter
- **Review found two invented knots:** item 1 was written as covering
  `do_generate` AND `backup_if_exists`, but only `do_generate` bypasses a mode
  reassertion (the five setup mv-sites `chmod` then `mv` unconditionally); and
  the stated "depends on M2 fixing the stamp values" dependency does not exist
  (the filter excludes the three `RUNNER_*` lines by name, so M2's values are
  irrelevant — M3 is correct with or without M2, work-ordering only).
- **De-knot:** narrowed item 1 to `do_generate`; corrected the dependency to
  work-ordering; recorded the mv-sites and `deploy_local_logrotate` as
  examined-Keep (`CLOSED_DOORS.md` CI-28).
- **Verified:** mode restored on the identical-skip path (with the "Identical"
  marker keeping the assertion honest); 0 runner backups on a no-change
  redeploy, 1 on a real source change. Two permanent tests, green on both
  goldens.

### M4 (#120) — atomic staged-rename for two more sites -> examined-Keep (retired)
- **Review outcome:** the plan review (step 1) found the two sites carry no
  meaningful defect. The `install.user` injector uses `sed -i`, already atomic
  (temp + rename); the local template's direct `cat >` write is genuinely
  non-atomic but its only concurrent reader (`systemd --user`) reads after the
  write, so no torn read is reachable single-user. Both were deliberately
  excluded from the 1.2.0 atomic sweep, and the stamp-injection coherence is
  already guarded by #84/CI-9.
- **The flash of remembering:** during the readback the owner recognized "we
  have been here before" — a door examined and closed once, being re-opened.
- **Disposition:** items 1-2 recorded as examined-Keep (`CLOSED_DOORS.md` CI-29),
  not work; item 3 (SELinux, RHEL-only) stays in Backlog, conditional on a
  production SELinux-enforcing decision. M4 retired from the cycle. The owner
  gate here produced a Keep, not a change — a valid, cheaper outcome than code,
  and the recorded verdict stops the next sweep from re-deriving it.
