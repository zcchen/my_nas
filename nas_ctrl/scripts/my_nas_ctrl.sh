
EMPTY_DIR_GEN=$(mktemp -d)  # change the empty_dir generate way as you like

#################################################
# TODO: seperate the config and the script cmd. #
#################################################

#########       making dirs as below    ############
__make_base_dirs__()
{
    mkdir -p -m 755 ${DATA_PATH}
    mkdir -p -m 755 ${DATA_PATH}/${GRP_NAME}
    chown root:root ${DATA_PATH} ${DATA_PATH}/${GRP_NAME}
}
__make_public_dirs__()
{
    mkdir -p -m 755 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}
    chown root:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}
    for d in ${PUBLIC_DIRs[@]}; do
        mkdir -p -m 775 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}/${d}
        chown root:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}/${d}
        setfacl -d -m group::rwx ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}/${d}
    done
}
__make_group_dirs__()
{
    mkdir -p -m 770 ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}
    chown ${GRP_NAME}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}
    for d in ${GRP_DIRs[@]}; do
        mkdir -p -m 770 ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/${d}
        chown ${GRP_NAME}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/${d}
        setfacl -d -m group::rwx ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/${d}
    done
}
__make_user_skel_dirs__()
{
    __CURRENT_DIR__=$(pwd)
    mkdir -p ${DATA_PATH}/${GRP_NAME}/.skel
    mkdir -p ${DATA_PATH}/${GRP_NAME}/.skel/${USER_SKEL_DIRs}

    cd ${DATA_PATH}/${GRP_NAME}/.skel
    for d in ${USER_SKEL_LNs[@]}; do
        ln -snf ${d##*:} ${d%%:*}
    done
    chown -R root:root ${DATA_PATH}/${GRP_NAME}/.skel
    chmod -R 700 ${DATA_PATH}/${GRP_NAME}/.skel
    cd ${__CURRENT_DIR__}
}

make_dirs()
{
    __make_base_dirs__
    __make_public_dirs__
    __make_group_dirs__
    __make_user_skel_dirs__
}

fix_dirs_mod()
{
    chmod 755 ${DATA_PATH}
    chmod 755 ${DATA_PATH}/${GRP_NAME}
    chmod 755 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}
    chmod -R 775 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}/*
    chmod -R 770 ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}
    local grp_users=$(getent group ${GRP_NAME})
    local users=(`echo ${grp_users##*:} | sed -e 's/,/ /g'`)
    for d in ${users} ; do
        if [[ $d != ${GRP_NAME} ]] && \
            [[ -d ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/$d ]];
            then
            chmod -R 700 ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/$d
        fi
    done
    echo "The dirs under ${DATA_PATH} are all fixed."
}

#########       making users as below     ############
add_groups()
{
    echo "Trying to add the groups <${GRP_NAME}>..."
    groupadd -g 2000 -f ${GRP_NAME}
    echo "Added groups <${GRP_NAME}>."
}

default_users()
{
    empty_dir=${EMPTY_DIR_GEN}     # empty_dir for the users skel dir.
    #useradd ${PUBLIC_NAME} -g nogroup -M -s /bin/false -u 2000
    useradd ${GRP_NAME} -g ${GRP_NAME} -M -s /bin/false -u 2000
    rmdir ${empty_dir}
}

function __get_passwd() {
    # get_passwd <username> <passwd_var>
    read -s -p "Enter NEW Unix and Samba Password for <$1>:" passwd_1
    echo
    read -s -p "Retype NEW Unix and Samba Password for <$1>:" passwd_2
    echo

    if [[ ${passwd_1} = ${passwd_2} ]]; then
        eval "$2=${passwd_2}"
        return 0
    else
        echo "Password not match"
        eval "$2=''"
        return 1
    fi
    echo
}

function __test_user_exist()
{
    local username=$1
    if [[ -z ${username} ]]; then
        echo "No username is given. Exiting..."
        return 2
    else
        id ${username} 2>/dev/null 1>/dev/null
        local ret_code=$?
        if [[ ${ret_code} -eq 0 ]]; then
            echo "User ${username} exists."
        fi
        return ${ret_code}
    fi
}

passwd_user()
{
    local username=$1
    __test_user_exist ${username}
    if [[ $? -eq 0 ]]; then
        __get_passwd ${username} new_passwd
        echo "-----Unix passwd Setting-----"
        (echo ${new_passwd}; echo ${new_passwd}) | passwd ${username}
        echo "-----Samba passwd Setting-----"
        (echo ${new_passwd}; echo ${new_passwd}) | smbpasswd -a ${username}
        echo "The password of <${username}> is updated successfully."
        if [[ $? -ne 0 ]]; then
            echo "Updating the password of user <${username}> with error. Exiting..."
            return 1
        fi
    else
        echo "Updating the password of user <${username}> with error. Exiting..."
        return 1
    fi
}

add_user()
{
    local username=$1
    __test_user_exist ${username}
    if [[ $? -ne 1 ]]; then
        exit 0
    fi
    useradd -b ${DATA_PATH}/${GRP_NAME} -g ${GRP_NAME} -s /bin/false \
            -m -k ${DATA_PATH}/${GRP_NAME}/.skel/ ${username}
    if [[ $? -eq 0 ]]; then
        chown ${username}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${username}
        chmod -R 700 ${DATA_PATH}/${GRP_NAME}/${username}
        echo "User <${username}> is added."
    else
        echo "Adding user <${username}> with error. Exiting..."
        return 1
    fi
    passwd_user ${username}
    if [[ $? -ne 0 ]]; then
        userdel -rf ${username}
        rm -rf ${DATA_PATH}/${GRP_NAME}/${username}
        exit 0
    fi
}

del_user()
{
    local username=$1
    __test_user_exist ${username}
    if [[ $? -eq 0 ]]; then
        echo "User directory of <${username}> is cleaning."
        smbpasswd -x ${username}
        chown -R ${GRP_NAME}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${username}
        chmod 755 ${DATA_PATH}/${GRP_NAME}/${username}
        mv ${DATA_PATH}/${GRP_NAME}/${username} \
            "${DATA_PATH}/${GRP_NAME}/olduser_${username}"
        userdel -rf ${username}
        echo "User <${username}> is clean."
    else
        echo "User <${username}> does not exist, or username is not given."
    fi
}

my_help()
{
    echo "$0 <init|fix|add|del|passwd> [username]"
}

main()
{
    if [[ $# -ne 2 ]] ; then
        if [[ $1 == 'init' ]] && [[ -z $2 ]]; then
            add_groups
            default_users
            make_dirs
        elif [[ $1 == 'fix' ]] && [[ -z $2 ]]; then
            fix_dirs_mod
        else
            my_help
        fi
    else
        if [[ $1 == 'add' ]]; then
            add_user $2
        elif [[ $1 == 'del' ]]; then
            del_user $2
        elif [[ $1 == 'passwd' ]]; then
            passwd_user $2
        else
            my_help
        fi
    fi
}

main $@
