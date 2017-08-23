#!/bin/bash

the_user="admin"
name_path=(
    "root:/"
    "nas_data:/data/data"
)
all_configs=(
    "ALLOW_USERS=${the_users}"
    "TIMELINE_MIN_AGE=1000"
    "TIMELINE_LIMIT_WEEKLY=10"
    "TIMELINE_LIMIT_MONTHLY=0"
    "TIMELINE_LIMIT_YEARLY=0"
    "EMPTY_PRE_POST_MIN_AGE=1000"
    "EMPTY_PRE_POST_CLEANUP=yes"
)

for i in ${name_path}; do
    config_name=${i%%:*}
    config_path=${i##*:}
    #echo "config_names: ${config_name}"
    #echo "config_paths: ${config_path}"
    snapper -c ${config_name} create-config ${config_path}
    snapper -c ${config_name} set-config ${all_configs}
done
