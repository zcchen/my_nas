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
    "s,//,/,g;"
)

cat << EOF > /tmp/smb.conf.example
[global]

    ## Browsing/Identification ###
    workgroup = WORKGROUP
    dns proxy = no
    netbios name = MY_NAS

    #### Networking ####
    interfaces = __NETWORK_CARD__ 127.0.0.0/8 __LOCAL_NETWORK__
    bind interfaces only = yes
    hosts allow = __LOCAL_NETWORK__ 127.0.0.1

    #### Debugging/Accounting ####
    log file = /var/log/samba/log.%m
    max log size = 1000
    ;syslog = 0
    panic action = /usr/share/samba/panic-action %d

    ####### Authentication #######
    server role = standalone server
    passdb backend = tdbsam
    obey pam restrictions = yes
    unix password sync = yes
    passwd program = /usr/bin/passwd %u
    passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
    pam password change = yes
    # This option controls how unsuccessful authentication attempts are mapped
    # to anonymous connections
    map to guest = bad user
    security = user
    guest account = nobody
    # For winXP work around
    server min protocol = NT1
    #lanman auth = yes
    ntlm auth = yes


    ############ Misc ############
    # Allow users who've been granted usershare privileges to create
    # public shares, not just authenticated ones
    ;usershare allow guests = yes
    allow insecure wide links = yes

#======================= Share Definitions =======================

[%U]
    comment = Home Directories
    path = %H
    browseable = yes
    writable = yes
    write list = @U
    create mask = 0700
    directory mask = 0700
    valid users = %U
    follow symlinks = yes
    wide links = yes

[public]
    comment = Public Directories
    path = /__DATA_PATH__/__GRP_NAME__/public
    browseable = yes
    writable = yes
    write list = @__GRP_NAME__
    create mask = 0755
    directory mask = 0755
    guest ok = yes
    guest account = nobody

[family]
    comment = Family Directories
    path = /__DATA_PATH__/__GRP_NAME__/family
    browseable = yes
    writable = yes
    create mask = 0770
    directory mask = 0770
    ;valid users = @__GRP_NAME__

# Uncomment to allow remote administration of Windows print drivers.
# You may need to replace 'lpadmin' with the name of the group your
# admin users are members of.
# Please note that you also need to set appropriate Unix permissions
# to the drivers directory for these users to have write rights in it
;   write list = root, @lpadmin
EOF

sed -e "${sed_cmd[*]}" /tmp/smb.conf.example
