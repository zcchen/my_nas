#!/bin/bash

if [[ -z $1 ]]; then
    echo "$0 <config.sh>"
    exit 1
fi
realbase=$(realpath $(dirname $0))
realconfig=$(realpath $1)
source ${realconfig}

sed_cmd=( \
    "s,__DATA_PATH__,${DATA_PATH},g;" \
    "s,__GRP_NAME__,${GRP_NAME},g;" \
    "s,__NETWORK_CARD__,${NETWORK_CARD},g;" \
    "s,__LOCAL_NETWORK__,${LOCAL_NETWORK},g;" \
)

sed -e "${sed_cmd[*]}" ${realbase}/smb.conf
