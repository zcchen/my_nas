#!/bin/bash

if [[ -z $1 ]]; then
    echo "$0 <config.sh>"
    exit 1
fi
realbase=$(realpath $(dirname $0))
realconfig=$(realpath $1)
source ${realconfig}

sed_cmd=( \
    "s,//,/,g;"
)

cat << EOF | sed -e "${sed_cmd[*]}"
#!/bin/bash

the_user="${SNAP_USER}"
name_path=(${SNAP_PATH[@]})
all_configs=(
    "ALLOW_USERS=\${the_users}"
    "TIMELINE_MIN_AGE=1000"
    "TIMELINE_LIMIT_WEEKLY=10"
    "TIMELINE_LIMIT_MONTHLY=0"
    "TIMELINE_LIMIT_YEARLY=0"
    "EMPTY_PRE_POST_MIN_AGE=1000"
    "EMPTY_PRE_POST_CLEANUP=yes"
)

for i in \${name_path}; do
    config_name=\${i%%:*}
    config_path=\${i##*:}
    #echo "config_names: \${config_name}"
    #echo "config_paths: \${config_path}"
    snapper -c \${config_name} create-config \${config_path}
    snapper -c \${config_name} set-config \${all_configs}
done
EOF

