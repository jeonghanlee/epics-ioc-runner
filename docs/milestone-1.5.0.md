# Work Register

Release line: 1.5.0
Milestone index: 1.5.0
Canonical path: `docs/milestone-1.5.0.md`
Canonical branch or ref: `master` until the release branch is cut (D2)
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.5.0` (20)
Gate baseline ref: `1.4.2` (D1)

Next session entry point: Select the Debian 13 and Rocky 8 test hosts for the M4 check-identity run.

## Milestone

### Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | Generate and install from an unenterable starting directory | Milestone | Complete | No | | Error-handling S43 and issue #168 acceptance at `95e872f`. [Detail](#m1---generate-and-install-from-an-unenterable-starting-directory) |
| M2 | Start an IOC through the EPICS-env loader | Milestone | Complete | No | | Loader start and refusal checks and issue #169 acceptance. [Detail](#m2---start-an-ioc-through-the-epics-env-loader) |
| M3 | Report an unenterable target directory | Milestone | Complete | No | | Error-handling S45 and issue #170 acceptance at `b3442f4`. [Detail](#m3---report-an-unenterable-target-directory) |
| G1 | Startup generator available for the Gate | External gate | Complete | No | | The control host verified the pinned revision from the 1.4.2 Gate bundle. [Detail](#g1---startup-generator-available-for-the-gate) |
| M4 | Release 1.5.0 | Milestone | Not started | Yes | M1, M2, M3, G1, D1, D2 | The complete Gate passes on the final candidate and the published release is verified. [Detail](#m4---release-150) |

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Bake the Gate baseline from the `1.4.2` tag, which resolves to `8b1aa9e8fc769ae19a02086ac9c8f258c90d21f3`. Deploy the 1.5.0 candidate on fresh consumers from those images. | 2026-11-24 |
| D2 | Develop on `master` and cut the release branch at release time. | 2026-11-24 |

### Milestone Details

#### M1 - Generate and install from an unenterable starting directory

Origin: 1.5.0 / M1
Identity History: none
GitHub Issue: [#168](https://github.com/jeonghanlee/epics-ioc-runner/issues/168)
Status: Complete

##### Summary

`generate` and `install` continue to use the resolved IOC directory when the calling user cannot reenter the starting directory.

##### Scope

Starting-directory handling in `generate` and `install`.

Out of scope: Other directory changes and the target-directory entry error covered by M3.

##### Completion Criteria

- Both commands operate on an enterable IOC directory from a starting directory they cannot reenter.
- Ordinary starting-directory cases continue to pass.

##### Dependencies And Decisions

- The release-wide suite matrix is tracked under M4.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

Retrospective record. The completed change at `95e872f` uses the resolved absolute path throughout the operation and removes the return to the starting directory.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | CLI | Run error-handling S43 with its starting-directory permission control. | Non-root source run | Both commands complete against an enterable target from the inaccessible starting path. |
| T2 | Regression | Inspect the ordinary path cases in the error-handling suite. | Non-root source run | Ordinary starting-directory cases pass. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Recorded by 2026-11-23 | Non-root source run | Pass | Issue #168 records S43 at `95e872f` and four failures before the fix. |
| T2 | Recorded by 2026-11-23 | Non-root source run | Pass | Issue #168 records 551/551 error-handling checks. |

##### Closure Evidence

- `95e872f` implements the fix. Issue #168 records acceptance and closure.

#### M2 - Start an IOC through the EPICS-env loader

Origin: 1.5.0 / M2
Identity History: none
GitHub Issue: [#169](https://github.com/jeonghanlee/epics-ioc-runner/issues/169)
Status: Complete

##### Summary

`IOC_ARGS` supplies whitespace-separated arguments to `IOC_CMD` in all three modes. System and local startup errors include the loader lines from that start.

##### Scope

Argument validation and rendering, loader startup and refusal output, documentation, and regression coverage.

Out of scope: Loader internals, writing `IOC_ARGS` during generation, and changes to restart supervision.

##### Completion Criteria

- The loader starts an IOC and serves a record in system, local, and container mode.
- Install validates quotes and rejects `IOC_ARGS` in `site.env`. The three launch renderings agree.
- System and local start report the loader's refusal with the exit code and log hint. The output caps loader lines at ten and counts further lines.
- The applicable existing configuration and restart supervision checks pass.

##### Dependencies And Decisions

- The complete lifecycle rerun in M4 requires the generator in G1.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

Retrospective record. `3018b51` adds `IOC_ARGS`, `98db671` reports loader lines, and `6708cec` documents the interface. `f7dff1a` and `9881c41` cover container startup and render agreement.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | CLI | Run error-handling S44. | Non-root source run | Optional arguments render and invalid quotes or site placement are rejected. |
| T2 | Lifecycle | Start a loader IOC and read its record. Run local S42 and system S37 with the real refusal and the shipped external child fixture. | Debian 13 and Rocky 8.10 | The IOC initializes, the loader refusal is printed, and the ten-line cap and additional count pass. |
| T3 | Container | Run container lifecycle S16 through `tests/run-container-tests.bash`. | Debian 13, Ubuntu 24, Rocky 8, and Rocky 10 EPICS images | The plain and loader IOC start, serve their records, and clean up. |
| T4 | Source contract | Run the source-regression S16 command-tail comparison. | Rocky 8.10 | The two unit templates and the s6 rendering agree. |
| T5 | Regression | Inspect ordinary startup and restart checks from both lifecycle suites. | Debian 13 and Rocky 8.10 | Applicable checks for configurations without `IOC_ARGS` and restart supervision pass. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Recorded by 2026-11-23 | Source error-handling suite | Pass | Issue #169 records S44 and `3018b51`. |
| T2 | Recorded by 2026-11-23 | Debian 13 and Rocky 8.10 | Pass | Issue #169 records Channel Access readback, local S42, system S37, EPICS-env 1.5.0 loader exit 1, and loader `ac94cca` exit 78. |
| T3 | Recorded by 2026-11-23 | Four EPICS 1.5.0 images | Pass | Issue #169 records container S16 and `f7dff1a`. |
| T4 | Recorded 2026-11-24 | Rocky 8.10 | Pass | The 1.5.0 handoff records 190/190, including the check added in `9881c41`. |
| T5 | Recorded by 2026-11-23 | Debian 13 and Rocky 8.10 | Pass | Issue #169 records startup and restart results. Generated-startup groups local S41 and system S27/S36 reported SKIP for the missing generator revision. |

##### Closure Evidence

- Issue #169 records acceptance and closure. M4 retains the obligation to run the full matrix, including the skipped generated-startup checks.

#### M3 - Report an unenterable target directory

Origin: 1.5.0 / M3
Identity History: none
GitHub Issue: [#170](https://github.com/jeonghanlee/epics-ioc-runner/issues/170)
Status: Complete

##### Summary

`generate` and `install` report the target path when they can identify the target directory but cannot enter it.

##### Scope

The target-directory entry failure in both commands.

Out of scope: Other directory changes, missing targets, and starting-directory handling covered by M1.

##### Completion Criteria

- Both commands exit 1 and name the unenterable target.
- Ordinary target cases continue to pass.

##### Dependencies And Decisions

- The release-wide suite matrix is tracked under M4.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

Retrospective record. `b3442f4` adds a diagnostic to both target-entry error paths.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | CLI | Run error-handling S45 with its mode `0600` directory control. | Non-root source run | Both commands exit 1 and name the unenterable target. |
| T2 | Regression | Run the existing checks in the error-handling suite. | Non-root source run | The other 551 checks pass. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Recorded by 2026-11-25 UTC | Isolated home and runtime directory | Pass | Issue #170 records S45 at `b3442f4` and the two target-name checks failing before the fix. |
| T2 | Recorded by 2026-11-25 UTC | Isolated home and runtime directory | Pass | Issue #170 records 557/557 including S45. |

##### Closure Evidence

- `b3442f4` implements the diagnostic. Issue #170 records acceptance and closure.

#### G1 - Startup generator available for the Gate

Origin: 1.5.0 / G1
GitHub Issue: none
Status: Complete

##### Summary

The startup generator maintainer supplies the original generator revision used by the full Gate matrix.

##### Completion Criteria

- The control host can resolve `ee214deedc5594bb93cd0a77d42615b99783bbd0` as a commit in the repository supplied to `IOC_RUNNER_STARTUP_GENERATOR`. See [Original generated-startup fixture](../tests/README.md#original-generated-startup-fixture).

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-11-25T07:30Z | Pass | The retained bundle from Gate run `20261110T203514Z-2880911` matched the SHA-256 in its `generator.meta`. Git verified the complete bundle history. In `work/startup-generator-1.5.0` on the control host, Git resolved the exact commit and found `generate_ioc_structure.bash` at that revision. |

##### Closure Evidence

- On the control host, set `IOC_RUNNER_STARTUP_GENERATOR` to the absolute path of `work/startup-generator-1.5.0` in this working checkout. The retained evidence is under `work/gate-suites-20261110T203514Z-2880911/`. Its `generator.meta` records the source identity and digest of `startup-generator.bundle`. If the clone is absent on a replacement control host, restore it from that verified bundle using the fixture procedure linked above.

#### M4 - Release 1.5.0

Origin: 1.5.0 / M4
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Verify the integrated 1.5.0 candidate, publish it, and verify the released objects and installation.

##### Scope

Check-identity pin, changelog and version, release Gate, publication, and release verification.

Out of scope: Startup generator changes and assigning work to a subsequent cycle.

##### Completion Criteria

- The final candidate passes all steps of the [Gate runbook](../gate/RUNBOOK.md) and the container suite on four images.
- The 1.5.0 tag and published release resolve to the authorized candidate and milestone 20 is closed.
- The documented install path works from the released tree on a fresh consumer.

##### Dependencies And Decisions

- M1, M2, and M3 provide the change-specific checks. G1 completed when the control host verified the pinned generator.
- D1 sets the image bake baseline. D2 sets the release branch timing.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-24
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Confirm the issues and version in Release Verification 1. Complete G1 before running Release Verification 2.
2. Run Release Verification 2 at Check grade to obtain the identity SHA-256. Select one clean development commit. On each selected non-NFS test VM, deploy that commit and run full setup as in Gate precondition 3. Resolve each EPICS environment as in precondition 4. Check both source HEADs and installed runner stamps against the selected commit before running the six-suite matrix. Read the underlying suite records and cross-host diff as well as both verdicts. The driver stops at identity mismatch before its final matrix validation. Require six complete runs per host, no FAIL, SKIP, or SCRIPT_ERROR, and only explained OS applicability differences before repinning. Record pre-change evidence and commit the repin under separate authorization.
3. Confirm the changelog title and the #170 and S45 entries, then commit the changelog on master. Cut the release branch at the reviewed tip and record the planned version change in a version-only commit. Apply separate authorization for the changelog commit, branch creation, and version commit. Verify the version-only commit in Release Verification 3.
4. Run Release Verification 4 to 7 against the clean versioned candidate. Run the container checks as the separate change-specific work in Gate step 1. The checks mapped to the matrix run once in Gate step 2. Record the results and confirm that the readiness evidence commit meets the register-only exception before publication.
5. Execute Release Execution 1 to 7 in order. For each action, preview the exact command and object, complete the applicable preflight, and obtain its stated authorization. Read back the result and record the immutable object or remote state in this register. Run the repository checks and record a separately authorized checkpoint commit before starting the next dependent action. Use the recorded explicit target for later actions, including the tag target. Stop on any failed action, readback, check, or checkpoint. Complete Release Verification 8 to 10 against the released objects.
6. Record release verification and tracker evidence in the canonical document before closing the cycle. After Release Verification 8 to 10, record closure in a separately authorized commit and compare the committed register with the checked document. Resolve next-cycle scope separately with the owner.

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T1 | Target-directory fix and version change | `generate` and `install` | Release Verification 6 | Error-handling S43 passes. | Pending |
| M1 / T2 | Final candidate | Ordinary generate and install | Release Verification 6 | Both error-handling suites pass. | Pending |
| M2 / T1 | Final candidate | Argument validation and local rendering | Release Verification 6 | Error-handling S44 passes. | Pending |
| M2 / T2 | Final candidate | Local and system launch and startup reporting | Release Verification 6 | Local S42 and system S37 pass. | Pending |
| M2 / T3 | Final candidate | Container launch rendering and operation | Release Verification 5 | Container S16 passes in all four images. | Pending |
| M2 / T4 | Final candidate | Command tail in all three launch renderings | Release Verification 6 | Source-regression S16 passes. | Pending |
| M2 / T5 | Final candidate | Local and system startup and supervision | Release Verification 6 | Both lifecycle suites pass, including generated-startup coverage. | Pending |
| M3 / T1 | Final candidate | Target-entry error handling | Release Verification 6 | Error-handling S45 passes. | Pending |
| M3 / T2 | Final candidate | Ordinary target cases | Release Verification 6 | Both error-handling suites pass. | Pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 4 | post-change | Fresh Debian 13 and Rocky 8 consumers | 1.5.0 candidate | x86_64 | Candidate push and full setup | Gate preconditions 1 to 4 | Clean tagged 1.4.2 provenance, accepted consumers, fixtures ready, and correct installed stamp. | Pending |
| Release Verification 5 | post-change | Four pinned EPICS container images listed below | 1.5.0 candidate | x86_64 | Container suite launcher | Gate step 1 across the four EPICS 1.5.0 images | All four suites pass, including S16. | Pending |
| Release Verification 6 | post-change | Same consumers | 1.5.0 candidate | x86_64 | Source and installed runner | Gate step 2 | Both six-suite matrices pass with matching identity pin. | Pending |
| Release Verification 7 | post-change | Same consumers with simulated NFS root_squash | 1.5.0 candidate | x86_64 | Installed runner and NFS source tree | Gate steps 3 to 5 | Deployment, multi-user scenarios, and installed system suites pass. | Pending |
| Release Verification 10 | post-release | Fresh baseline consumer | Published 1.5.0 | x86_64 | Clean release checkout and documented system install | Released-object storage preflight below, then the [Installation guide](INSTALL.md) and IOC generate, install, and start | Both storage checks pass, the installed stamp matches the release, and the IOC initializes. | Pending |

For Release Verification 5, run the container suite from the clean candidate
checkout, once for each image:

```bash
bash tests/run-container-tests.bash --image jeonghanlee/debian13-epics:1.5.0
bash tests/run-container-tests.bash --image jeonghanlee/ubuntu24-epics:1.5.0
bash tests/run-container-tests.bash --image jeonghanlee/rocky8-epics:1.5.0
bash tests/run-container-tests.bash --image jeonghanlee/rocky10-epics:1.5.0
```

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `RUNNER_VERSION` | `bin/ioc-runner` | 1.4.2 | 1.5.0 | Read the declaration and run the source version command. | Release Verification 1 | Read the changed declaration and run the candidate version command. | Release Verification 3 |

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | After Release Verification 7 reads Pass, integrate the reviewed release tree into `master` after confirming Release Verification 5 also reads Pass. | Separate release authorization after exact preview | The release tree matches the Gate-tested contents, subject to the register-only exception. | Pending |
| 2 | Publish the authorized `master` release ref. | Separate push authorization | The remote ref resolves to the authorized release commit. | Pending |
| 3 | Publish the authorized release branch ref if required by the accepted release plan. | Separate push authorization | The remote release branch matches the authorized ref. | Pending |
| 4 | Create annotated tag `1.5.0` at the authorized published release object. | Separate tag-create authorization | The local tag resolves to the authorized release commit. | Pending |
| 5 | Publish the exact tag ref `refs/tags/1.5.0`. | Separate tag-push authorization | The remote tag and local tag are identical. | Pending |
| 6 | Publish the GitHub release for `1.5.0` with curated notes. | Separate release authorization | The GitHub release is published for the verified tag. | Pending |
| 7 | Close GitHub milestone 20 after release publication. | Separate release authorization after exact preview | The milestone is closed with zero open issues. | Pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Source and tracker | pre-change | Read the version declaration, run `bin/ioc-runner -V`, and read milestone 20. | Clean development commit | Version is 1.4.2 and #168, #169, and #170 are closed. | Source version output and tracker readback |
| Release Verification 2 | Check identity | pre-change | Prepare both VMs and deploy the same clean commit per implementation step 2. Set the generator from G1 and run the Gate step 2 matrix at Check grade. | Debian 13 and Rocky 8 | Both hosts run the selected source and installed runner. All six suites complete per host with no failed or skipped checks or script errors. Applicability differences are explained and the reported identity digests agree. | Source and installed identities, individual suite records, both verdicts, and cross-host diff |
| Release Verification 3 | Version | post-change | Read the version-only diff and run `bin/ioc-runner -V` after the version-only commit. | Clean version commit | The version is 1.5.0 and the change matches the plan. | Version diff and output |
| Release Verification 4 | Provisioning | post-change | Execute all Gate preconditions with baseline D1. | Fresh Gate pair | Provenance and Golden acceptance pass, fixtures are ready, and setup installs the candidate. | Image manifests, acceptance and setup logs |
| Release Verification 5 | Container | post-change | For Gate step 1, run the four pinned-image commands under Production Environment Tests. | Four EPICS 1.5.0 images | Each complete container lifecycle suite passes. | Four container suite logs |
| Release Verification 6 | Integrated suites | post-change | Execute Gate step 2. The matrix covers M1 / T1 and T2, M2 / T1, T2, T4 and T5, and M3 / T1 and T2. | Fresh Gate pair | Both hosts report `SUITES OK` and the driver reports `GATE SUITES PASS`. | Suite records, identity digest, and cross-host diff |
| Release Verification 7 | NFS and multi-user | post-change | Execute Gate steps 3 to 5 and check the complete evidence record. | Same Gate pair in NFS mode | Root-squash deployment, all nineteen scenarios, and the installed system suites pass on both hosts. Startup inputs are removed. | NFS, deployment, multi-user, system-suite, and cleanup records |
| Release Verification 8 | Published objects | post-release | Read the remote tag and GitHub release after Release Execution 6. | Git and GitHub | The annotated tag resolves to the authorized commit with version 1.5.0 and the release is published for that tag. | Remote tag and release readback |
| Release Verification 9 | Tracker | post-release | Read milestone 20 and its issues after Release Execution 7. | GitHub | The milestone and all three issues are closed. | Tracker readback |
| Release Verification 10 | Installation | post-release | After Release Execution 6, complete the storage preflight below. Check out the verified release commit and follow the installation guide. Generate, install, and start an IOC. | Fresh baseline consumer | Both storage checks pass, the installed runner reports the release commit, and the IOC initializes. | Storage measurements, release object identities, and installation and IOC startup logs |

For Release Verification 10, follow Phase 11, "Released-Object Storage
Preflight", in the `release-cycle` skill's `references/close.md`. On the fresh
consumer, record the target filesystem, unused destination, clone mode,
canonical remote, and refspecs. Compare the advertised release and tag refs
with the recorded release identities. Use filesystem-allocated bytes for
the size estimates and reserve 1 GiB at each check.

1. Before cloning, require free space for the estimated Git object database
   plus 1 GiB. Fetch the recorded refs without checking out a tree. Verify the
   tag and release commit and record the actual allocation.
2. Before checkout, measure free space again. Require space for the working
   tree and the verification workspace and evidence plus 1 GiB. Proceed to
   checkout and installation only after this check passes.

If either check fails or an estimate lacks evidence, stop at that check and
follow the recovery procedure in the same reference.

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | Clean development commit | Pending | None |
| Release Verification 2 | Not run | Debian 13 and Rocky 8 | Pending | None |
| Release Verification 3 | Not run | Clean version commit | Pending | None |
| Release Verification 4 | Not run | Fresh Gate pair | Pending | None |
| Release Verification 5 | Not run | Four EPICS images | Pending | None |
| Release Verification 6 | Not run | Fresh Gate pair | Pending | None |
| Release Verification 7 | Not run | Gate pair in NFS mode | Pending | None |
| Release Verification 8 | Not run | Git and GitHub | Pending | None |
| Release Verification 9 | Not run | GitHub | Pending | None |
| Release Verification 10 | Not run | Fresh baseline consumer | Pending | None |

##### Closure Evidence

- Pending final candidate, Gate evidence, publication, and released-object verification.

## Backlog

### Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |

### Backlog Details

No backlog assignments are recorded for this release line.
