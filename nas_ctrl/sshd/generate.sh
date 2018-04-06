#!/bin/bash

if [[ -z $1 ]]; then
    echo "$0 <config.sh>"
    exit 1
fi
realbase=$(realpath $(dirname $0))
realconfig=$(realpath $1)
source ${realconfig}

sed_cmd=( \
    "s,__SSHD_PORT1__,${SSHD_PORT},g;" \
    "s,__SSHD_PORT2__,${SSHD_PORT},g;" \
    "s,__DATA_PATH__,${DATA_PATH},g;" \
    "s,__GRP_NAME__,${GRP_NAME},g;" \
    "s,//,/,g;"
)

sed -e "${sed_cmd[*]}" ${realbase}/sshd_config
