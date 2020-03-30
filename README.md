# enforce-share

Enforce group ownership and permissions for shared folder files and directories.

This tool was designed to mitigate file permission issues
when setting up synchronized shared folders with [syncthing](https://syncthing.net/).

## Usage

```
enforce-share <share_root> [share_group]
```

forces `share_root`'s files and directories:
- to belong to `share_group` group (`share_root`'s group by default)
- to be group readable and writable
- not to be world readable nor writable
- plus for directories:
  - to be group executable and setgid (for its future contents to belong to `share_group` too)
  - not to be world executable

> :warning: `enforce-share` needs to be executed by a user allowed to do this!

## Installation

```bash
sudo make install
```

installs:
- `enforce-share` in `$BIN_DIR` (`/usr/local/bin` by default)
- a cron script in `$CRON_CONF_DIR` (`/etc/cron.hourly` by default)
  to run `enforce-share` automatically and log in `$LOG_DIR` (`/var/local/log` by default)
- a logrotate configuration file in `$LOGROTATE_CONF_DIR` (`/etc/logrotate.d` by default)
  to rotate the log file
