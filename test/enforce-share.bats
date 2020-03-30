#!/usr/bin/env bats

effective_group=$(id -gn)
other_group=$(id -Gn | sed -re "s/( +|^)$effective_group( |\$)/\2/" | grep -o '[^ ]*$')

function setup() {
  tmp_dir=$(mktemp -d -t enforce-share-XXXXXXXXXX)
  make install \
    BIN_DIR=$tmp_dir/bin \
    CRON_CONF_DIR=$tmp_dir/etc/cron.daily \
    LOG_DIR=$tmp_dir/log \
    LOG_DIR_GROUP=$other_group \
    LOGROTATE_CONF_DIR=$tmp_dir/etc/logrotate.d
  pushd $tmp_dir
}

function teardown() {
  popd
  rm -r $tmp_dir
}

@test "user running tests should belong to at least 2 groups" {
  [ "$other_group" != "$effective_group" ]
  [ "$other_group" != "" ]
}

function file_should_belong_to_other_group() {
  echo "$1 should belong to $other_group"
  [ $(stat -c %G $1) == "$other_group" ]
}

@test "log directory should be owned by syslog" {
  file_should_belong_to_other_group $tmp_dir/log
}

@test "cron script should be customized to the right log path" {
  grep -q "> $tmp_dir/log/enforce-share.log" $tmp_dir/etc/cron.daily/enforce-share
}

@test "logrotate conf should be customized to the right log path" {
  grep -q "^$tmp_dir/log/enforce-share.log" $tmp_dir/etc/logrotate.d/enforce-share
}

@test "enforce-share should fail if there are no parameters" {
  run ./bin/enforce-share
  [ "$status" -ne 0 ]
}

@test "enforce-share should fail if the 1st parameter is not a directory" {
  run ./bin/enforce-share root
  [ "$status" -ne 0 ]
}

function fixture() {
  good_dirs=(root root/goodd root/{badd,goodd}/goodsubd)
  bad_dirs=(root/badd root/{badd,goodd}/badsubd)
  mkdir -p ${good_dirs[@]} ${bad_dirs[@]}
  chmod ug=rwxs,o=s ${good_dirs[@]} ${bad_dirs[@]}

  good_files=(root/{badd,goodd}/goodf)
  bad_files=(root/{badd,goodd}/badf)
  touch ${good_files[@]} ${bad_files[@]}
  chmod ug=rw,o= ${good_files[@]} ${bad_files[@]}

  goods=(${good_dirs[@]} ${good_files[@]})
  bads=(${bad_dirs[@]} ${bad_files[@]})

  chgrp -R $other_group ${goods[@]} ${bads[@]}
}

function output_should_contain() {
  echo "output should contain $1"
  IFS=$'\n' grep -q "^$1\$" <<<"$output"  
}

function output_should_not_contain() {
  echo "output should not contain $1"
  ! IFS=$'\n' grep -q "^$1\$" <<<"$output"  
}

@test "group should be enforced" {
  fixture
  chgrp $effective_group ${bads[@]}

  run ./bin/enforce-share root $other_group
  [ "$status" -eq 0 ]
  output_should_not_contain "CHMOD .*"
  
  for f in ${bads[@]}; do
    output_should_contain "CHGRP $f"
    file_should_belong_to_other_group $f
  done
  
  for f in ${goods[@]}; do
    output_should_not_contain "CHGRP $f"
    file_should_belong_to_other_group $f
  done
}

@test "default group should be enforced" {
  fixture
  chgrp $effective_group ${bads[@]}

  run ./bin/enforce-share root
  [ "$status" -eq 0 ]
  output_should_not_contain "CHMOD .*"
  
  for f in ${bads[@]}; do
    output_should_contain "CHGRP $f"
    file_should_belong_to_other_group $f
  done
  
  for f in ${goods[@]}; do
    output_should_not_contain "CHGRP $f"
    file_should_belong_to_other_group $f
  done
}

function file_should_be_group_writable() {
  echo "$1 should be group writable"
  access_rights=$(stat -c %A $1)
  [ ${access_rights:5:1} != "-" ]
}

@test "directory group permissions should be enforced" {
  fixture
  chmod g-w ${bad_dirs[@]}

  run ./bin/enforce-share root $other_group
  [ "$status" -eq 0 ]

  output_should_not_contain "CHGRP .*"
  
  for f in ${bad_dirs[@]}; do
    output_should_contain "CHMOD $f"
    file_should_be_group_writable $f
  done
  
  for f in ${goods[@]} ${bad_files[@]}; do
    output_should_not_contain "CHMOD $f"
    file_should_be_group_writable $f
  done
}

@test "file group permissions should be enforced" {
  fixture
  chmod g-w ${bad_files[@]}

  run ./bin/enforce-share root $other_group
  [ "$status" -eq 0 ]

  output_should_not_contain "CHGRP .*"
  
  for f in ${bad_files[@]}; do
    output_should_contain "CHMOD $f"
    file_should_be_group_writable $f
  done
  
  for f in ${goods[@]} ${bad_dirs[@]}; do
    output_should_not_contain "CHMOD $f"
    file_should_be_group_writable $f
  done
}
