# ADR 0004 — Crash-Scan Corroboration Matches Framework Severity Markers

- Status: **Accepted** (2026-09-18).
- Scope: which tokens the post-initialization corroboration scan matches
  (`CRASH_LOG_PATTERNS_AMBIGUOUS` / `CRASH_LOG_PATTERNS_SEVERITY`,
  `bin/ioc-runner`), and why English error vocabulary is excluded from the
  built-in set. Complements ADR 0001 (startup-poll classification: what a
  corroborating match *does* — a warning on a live IOC, never a failure).
- Supersedes: the corroborating-token mechanism of 1.4.1 register decision D4
  (the "`ERROR` followed by a colon" rule). D4's other parts stand: the warning
  is worded as a heuristic hint, prints the matched line(s), and the scan
  normalizes ANSI SGR sequences before matching.

## Context

Issue #153: a healthy PDU IOC's own diagnostic report — an
`Error count      : 0` field and an `errors` column header — tripped the
post-initialization warning, because the corroborating token `ERROR` was
matched case-insensitively as a bare substring.

A first correction changed the token to the marker shape `ERROR[[:space:]]*:`
(a colon after the word). The release gate falsified it the same day: the
source-regression S21 positive control — the real iocsh history diagnostic —
stopped matching, because EPICS Base's error marker has **no colon**:

```c
#define ERL_ERROR ANSI_RED("ERROR")            /* errlog.h:298            */
fprintf(..., ERL_ERROR " %s (%d) loading '%s'\n", ...)   /* iocsh.cpp:646 */
```

Across EPICS Base, `ERL_ERROR` is followed by a colon at 25 call sites and by
a space at 67; a colon rule misses two thirds of Base's own error lines. The
false-positive fix had traded a cosmetic warning for missed genuine errors.

## Evidence

Three measurements, each re-runnable from the in-tree sources.

**1. Emission-site survey, all 33 in-tree module sources.** Quoted format
strings at error-emission calls (`errlogPrintf`, `errlogSevPrintf`,
`fprintf(stderr)`, `asynPrint(..ASYN_TRACE_ERROR..)`, `log_err_printf`,
`cantProceed`, ...) show no shared vocabulary: uppercase `ERROR` literals are
rare (Base 4, mca 15, StreamDevice 11, motor 9, most modules 0); prose
`error`/`Error` is common; the single most frequent error word is `failed`
(Base 170, sequencer 45, StreamDevice 21, opcua 18, asyn 14), which contains
no "error" at all. 24 of 33 modules emit errors with no severity tag of any
kind.

**2. Runtime rendering.** What actually reaches the log is decided by each
framework's renderer, not by the message literal:

| Framework | Marker in the log | Source |
| --- | --- | --- |
| Base `ERL_ERROR` | uppercase `ERROR`, ANSI-red, no colon | `errlog.h:298` |
| Base `errlogSevPrintf` | `sevr=info\|minor\|major\|fatal ` prefix | `errlog.c:382` |
| PVXS | level words ` ERR ` / ` CRIT ` / ` WARN ` (not "ERROR") | pvxs `log.cpp:78-82` |
| StreamDevice | color + `file line N:` — no marker word | `StreamError.cc:152-166` |
| asyn | none — free-form `errorMessage` text | `asynManager.c` trace path |

**3. A real healthy IOC log** (the 42 KB #153 PDU log). Framework severity
markers appear **zero** times: uppercase-`ERROR`-word 0, ` ERR `/` CRIT ` 0,
`sevr=` 0. English vocabulary appears constantly and always benignly: `error`
case-insensitively 24 times (the count field, the column header,
`SessionTimeout`, transient `read error` prose), `timeout` 5, `WARNING` 5
(the `cas WARNING:` dynamic-TCP-port notice). On this log the severity
markers separate signal from noise perfectly; the vocabulary separates
nothing.

## Decision

1. The corroborating scan splits into two match classes, both
   corroborating-only (a warning on a live IOC, per ADR 0001):
   - `CRASH_LOG_PATTERNS_SEVERITY`, matched **case-sensitively**:
     the uppercase word `ERROR` (non-identifier boundaries), the
     space-bounded level words `ERR` and `CRIT`, and `sevr=(major|fatal)`.
   - `CRASH_LOG_PATTERNS_AMBIGUOUS`, matched case-insensitively as before,
     now carrying only the message phrases (`Can't open`, `cannot open`,
     `No such file or directory`, `Invalid directory path`), plus the
     per-IOC `CRASH_LOG_PATTERNS_EXTRA` key.
2. ANSI SGR sequences are stripped from the scan window before either class
   is matched (`crash_scan_filter`), so the ANSI-wrapped `ERL_ERROR` marker
   matches; byte-offset scans (the readiness marker) keep the raw window.
3. English error vocabulary — `error`, `Error`, `failed`, `Timeout`,
   `WARNING`/`WARN` — is never part of the built-in set. An operator who
   knows a module's phrasing opts in per IOC through
   `CRASH_LOG_PATTERNS_EXTRA` (issue #25's mechanism).
4. The warning remains an honestly-heuristic hint: it says it is a pattern
   match and not a verdict, prints the matched line(s), and points at the
   log.

## Alternatives

- **Bare case-insensitive `ERROR` (the previous behavior).** Rejected: it is
  a vocabulary matcher; on the real healthy log it fires on 24 benign lines —
  the #153 class, which recurs with the next module's report table.
- **The colon marker `ERROR[[:space:]]*:`.** Rejected by measurement:
  `ERL_ERROR` defines no colon and two thirds of Base's uses follow it with a
  space, so the rule misses genuine Base errors; the gate's S21 positive
  control caught exactly this.
- **Keep the vocabulary matcher and only exclude the #153 shapes**
  (`CRASH_LOG_EXCLUDE_PATTERNS`). Rejected: it removes two known shapes but
  keeps the vocabulary class, so every future benign "Error ..." report line
  is a new exclusion; it also adds nothing for the frameworks the vocabulary
  never matched (PVXS `ERR`, `sevr=` lines).
- **Broaden the built-in set with vocabulary** (`Timeout`, `failed`,
  `WARNING`). Rejected by the same log: its five `timeout` and five `WARNING`
  occurrences are all healthy, and `failed`-class prose is unbounded.

## Consequences

- A module that reports a genuine error as untagged prose (lowercase
  `error: ...`, asyn free-form text) no longer raises the built-in warning;
  the sensitivity lives in the per-IOC `CRASH_LOG_PATTERNS_EXTRA` opt-in.
  This is the accepted trade: on the measured evidence the vocabulary class
  carried no signal on a healthy IOC, and a heuristic that is quiet and
  right beats one that is loud and wrong.
- The scan runs two greps (case-insensitive base + extras, case-sensitive
  severity); the matched-line display unions both.
- The source contracts moved with the mechanism: source-regression S20 pins
  the severity subset's membership and case-sensitivity and the benign
  vocabulary fixtures; S21's positive control is evaluated on the
  ANSI-normalized form, as the scan sees it.
- The pre-marker fatal subset and the death-banner verdicts are unchanged
  (ADR 0001); `sevr=fatal` also matches the fatal subset's `fatal` token
  before the marker, which is the intended severity reading.
- The survey is repeatable: grep the module sources' error-emission format
  literals and the three renderers above; re-run the healthy-log tally
  against any suspect log before adding a token.
