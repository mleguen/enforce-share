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

>   :warning: `enforce-share` needs to be executed by a user allowed to do this!

## Installation

1.  Create a file named `enforce-sharerc.sh` in the `./etc/enforce-share` directory
    containing the list of shares you want to enforce automatically:

    ```bash
    #!/usr/bin/env bash

    # A space separated list of the shares you want to enforce
    export ENFORCED_SHARES="/my/first/share /my/second/share"
    ```

1.  ```bash
    sudo make install
    ```

    will install:

    -   `enforce-share` in `$BIN_DIR` (`/usr/local/bin` by default)
    -   the `enforce-sharerc.sh` you created in `$CONF_DIR` (`/etc/enforce-share` by default)
    -   a cron script in `$CRON_CONF_DIR` (`/etc/cron.hourly` by default)
        to run `enforce-share` automatically on the shares you defined in `enforce-sharerc.sh`
        and log in `$LOG_DIR` (`/var/local/log` by default)
    -   a logrotate configuration file in `$LOGROTATE_CONF_DIR` (`/etc/logrotate.d` by default)
        to rotate the log file

Optionally, you can change the crontab setup to run enforce-share every minute, instead of every hour:

1.  Move enforce-share cron script to a new `/etc/cron.minutely` folder:

    ```bash
    sudo mkdir /etc/cron.minutely
    sudo mv /etc/cron.hourly/enforce-share /etc/cron.minutely/
    ```

1.  Add the following line to `/etc/crontab` to have scripts in `/etc/cron.minutely` run every minute :

    ```crontab
    *  *    * * *   root    cd / && run-parts --report /etc/cron.minutely
    ```
