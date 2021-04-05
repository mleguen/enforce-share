BIN_DIR?=/usr/local/bin
CONF_DIR=/etc/enforce-share
CRON_CONF_DIR?=/etc/cron.hourly
LOG_DIR?=/var/local/log
LOG_DIR_GROUP?=syslog
LOGROTATE_CONF_DIR?=/etc/logrotate.d

.PHONY: test

install: $(BIN_DIR)/enforce-share $(CRON_CONF_DIR)/enforce-share $(LOGROTATE_CONF_DIR)/enforce-share $(CONF_DIR)/enforce-sharerc.sh $(LOG_DIR)

$(BIN_DIR)/enforce-share: bin/enforce-share | $(BIN_DIR)
	cp -f $^ $@
	chmod u=rwx,go=rx $@

$(CRON_CONF_DIR)/enforce-share: etc/cron.hourly/enforce-share | $(CRON_CONF_DIR)
	sed -e "s:%LOG_DIR%:$(LOG_DIR):g;s:%CONF_DIR%:$(CONF_DIR):g" $^ > $@
	chmod u=rwx,go=rx $@

$(LOGROTATE_CONF_DIR)/enforce-share: etc/logrotate.d/enforce-share | $(LOGROTATE_CONF_DIR)
	sed -e "s:%LOG_DIR%:$(LOG_DIR):g" $^ > $@
	chmod u=rw,go=r $@

$(CONF_DIR)/enforce-sharerc.sh: etc/enforce-share/enforce-sharerc.sh | $(CONF_DIR)
	cp $^ $@
	chmod u=rw,go=r $@

$(BIN_DIR) $(LOGROTATE_CONF_DIR) $(CRON_CONF_DIR) $(CONF_DIR):
	mkdir -p $@
	chmod ug=rwx,o=rx $@

$(LOG_DIR):
	mkdir -p $@
	chgrp $(LOG_DIR_GROUP) $@
	chmod ug=rwx,o=rx $@

test:
	bats test/enforce-share.bats
