# EPICS IOC Runner

`epics-ioc-runner` deploys and runs EPICS IOCs under procServ with the
service manager the host already has. In system mode, systemd runs each IOC
from one template unit as the `ioc-srv` service account, and operators in the
`ioc` group manage the IOCs without a root password. In local mode, an
engineer runs IOCs under their own account with the user instance of systemd.
In container mode, s6 supervises the IOCs inside a container image without
systemd. One command, `ioc-runner`, generates, installs, starts, observes, and
removes IOCs in all three modes.

This book is for the administrator who sets up a host and the operator who
deploys and runs IOCs on it.

## Guides

- [INSTALL.md](INSTALL.md): set up a host for system mode or a container
  image for container mode, including the accounts, directories, sudoers
  policy, unit template, and log rotation.
- [UNINSTALL.md](UNINSTALL.md): remove the system-mode installation from a
  host.
- [USER_GUIDE.md](USER_GUIDE.md): deploy, run, observe, and remove IOCs in
  system mode, and use the console, listing, and version commands that all
  modes share.
- [USER_GUIDE_LOCAL.md](USER_GUIDE_LOCAL.md): run and test IOCs under your
  own account in local mode.
- [FAQ.md](FAQ.md): answers to operational questions, from restarting an IOC
  without a root password to reading logs and history files.

## Concepts

- [ARCHITECTURE.md](ARCHITECTURE.md): the components, the template unit, the
  sudoers delegation, and the s6 service layout of container mode.
- [PERMISSION_MODEL.md](PERMISSION_MODEL.md): the owner, mode, and ACL of
  every path the runner installs, references, or creates, and which principal
  can do what.
- [EXIT_SIGNAL_HANDLING.md](EXIT_SIGNAL_HANDLING.md): how systemd and
  procServ exit codes map to a clean stop.

## Reference

- [CLI_REFERENCE.md](CLI_REFERENCE.md): every command and option, with its
  checks, output, and exit status.
- [NETWORK_ENV.md](NETWORK_ENV.md): the Channel Access and PV Access network
  variables an IOC reads, and which belong in the shared `site.env`.
- [LOG_LAYOUT.md](LOG_LAYOUT.md): log paths and rotation in system and local
  mode.
- [GLOSSARY.md](GLOSSARY.md): the terms this book uses.
