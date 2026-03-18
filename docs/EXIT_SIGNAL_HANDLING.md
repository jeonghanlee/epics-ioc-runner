# Technical Note: Exit Signal Handling for procServ and systemd

## 1. Objective
This document defines the signaling behavior between `systemd` and `procServ` to ensure that intentional service terminations are correctly interpreted as successful operations rather than process failures.

## 2. Theoretical Background
### 2.1. systemd Termination Process
When a stop command is issued via `systemctl`, `systemd` sends `SIGTERM` (Signal 15) to the main process defined in the unit file. By default, `systemd` expects the process to return an exit code of `0` to mark the service as `inactive (dead)`. Any other exit code or termination by a signal results in a `failed` state.

### 2.2. procServ Wrapper Architecture
`procServ` acts as a wrapper that manages a child process (the EPICS IOC) within a Pseudo Terminal (PTY). Because of this intermediate layer, the exit status of the main `procServ` process often reflects the state of its child or the signal it received, rather than a simple success/fail status.

## 3. Signal Propagation and Exit Codes
The interaction between these two systems during a shutdown sequence typically follows this path:

1. **Signal Delivery**: `systemd` sends `SIGTERM` to `procServ`.
2. **Signal Forwarding**: `procServ` receives the signal and propagates it to the child IOC process.
3. **Child Exit**: The IOC process terminates. Under POSIX conventions, a process terminated by a signal returns an exit status of `128 + Signal Number`. For `SIGTERM`, this value is `143`.
4. **Parent Exit**: `procServ` terminates and returns either the child's exit status (`143`) or the status of the signal it received itself (`15`).

## 4. SuccessExitStatus Configuration
To bridge the gap between `systemd`'s strict requirements and `procServ`'s signaling reality, the `SuccessExitStatus` directive is used to whitelist expected non-zero exit codes.

```ini
# Defined in both system-wide and local templates
SuccessExitStatus=0 1 2 15 143 SIGTERM SIGKILL
```

### 4.1. Code Definitions
* **0**: Standard graceful exit.
* **1, 2**: Occasional statuses returned during specific PTY or socket interrupt sequences.
* **15 / SIGTERM**: Confirmation that the process terminated in direct response to the standard stop request.
* **143**: Specific POSIX status (128 + 15) confirming the child IOC was successfully terminated by `SIGTERM`.
* **SIGKILL**: Ensures that if a process does not respond to `SIGTERM` and is subsequently killed by `SIGKILL` (after `TimeoutStopSec`), it is still recorded as a successful administrative stop.

