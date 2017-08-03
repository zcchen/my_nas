#!/bin/bash

GRP_NAME="family"               # the group name
PUBLIC_NAME="public"

DATA_PATH='/tmp/data/'
PUBLIC_DIRs=( \
    "Movies_电影"
    "Music_音乐"
    "Picture_贴图"
    "Games_游戏"
    "Software_软件"
    "eBooks_电子书"
    "Downloads_下载"
)   # ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}/PUBLIC_DIRs
GRP_DIRs=( \
    "Photos_照片"
    "Public_公共文件"
)   # ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/GRP_DIRs
USER_SKEL_DIRs=( \
    "Photos_照片/personal_个人照片"
)   # ${DATA_PATH}/${GRP_NAME}/.skel/
USER_SKEL_LNs=( \
    "Movies_电影:../${PUBLIC_NAME}/Movies_电影"
    "Music_音乐:../${PUBLIC_NAME}/Music_音乐"
    "Picture_贴图:../${PUBLIC_NAME}/Picture_贴图"
    "Games_游戏:../${PUBLIC_NAME}/Games_游戏"
    "Software_软件:../${PUBLIC_NAME}/Software_软件"
    "eBooks_电子书:../${PUBLIC_NAME}/eBooks_电子书"
    "Downloads_下载:../${PUBLIC_NAME}/Downloads_下载"
    "Public_公共文件:../${GRP_NAME}/Public_公共文件"
    "Photos_照片/family_家庭照片:../../${GRP_NAME}/Photos_照片"
)   # ${DATA_PATH}/${GRP_NAME}/.skel/

ANONYMOUS_UPLOAD="upload"       # anonymous upload name
UPLOAD_DIR='upload'

EMPTY_DIR_GEN=$(mktemp -d)  # change the empty_dir generate way as you like

#################################################
# TODO: seperate the config and the script cmd. #
#################################################

#########       making dirs as below    ############
__make_base_dirs__()
{
    mkdir -p -m 755 ${DATA_PATH}
    mkdir -p -m 750 ${DATA_PATH}/${GRP_NAME}
    #chown root:root ${DATA_PATH} ${DATA_PATH}/${GRP_NAME}
}
__make_public_dirs__()
{
    mkdir -p -m 750 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}
    #chown root:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}
    for d in ${PUBLIC_DIRs[@]}; do
        mkdir -p -m 775 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}/${d}
        #chown ${PUBLIC_NAME}:${GRP_NAME} ${d}
    done
}
__make_group_dirs__()
{
    mkdir -p -m 770 ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}
    #chown ${GRP_NAME}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}
    for d in ${GRP_DIRs[@]}; do
        mkdir -p -m 770 ${DATA_PATH}/${GRP_NAME}/${GRP_NAME}/${d}
        #chown ${GRP_NAME}:${GRP_NAME} ${d}
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
    #chown -R root:root ${DATA_PATH}/${GRP_NAME}/.skel
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
    chmod 750 ${DATA_PATH}/${GRP_NAME}
    chmod 750 ${DATA_PATH}/${GRP_NAME}/${PUBLIC_NAME}
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
default_users()
{
    empty_dir=${EMPTY_DIR_GEN}     # empty_dir for the users skel dir.
    useradd ${PUBLIC_NAME} -g nogroup -k ${empty_dir} -M -s /bin/false -u 2000
    useradd ${GRP_NAME} -g ${GRP_NAME} -k ${empty_dir} -M -s /bin/false -u 2001
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
        echo "-----Unix passwd Setting-----"
        (echo ${new_passwd}; echo ${new_passwd}) | passwd ${username}
        echo "-----Samba passwd Setting-----"
        (echo ${new_passwd}; echo ${new_passwd}) | smbpasswd -a -s ${username}
        echo "The password of <${username}> is updated successfully."
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
    __get_passwd ${username} new_passwd
    if [[ $? -ne 0 ]]; then
        exit 0
    fi
    useradd -b ${DATA_PATH}/${GRP_NAME} -g ${GRP_NAME} -s /bin/false \
            -m -k ${DATA_PATH}/${GRP_NAME}/.skel/ ${username}
    if [[ $? -eq 0 ]]; then
        chown ${username}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${username}
        #chmod -R 700 ${DATA_PATH}/${GRP_NAME}/${username}
        echo "User <${username}> is added."
    else
        echo "Adding user <${username}> with error. Exiting..."
        return 1
    fi
}

del_user()
{
    local username=$1
    __test_user_exist ${username}
    if [[ $? -eq 0 ]]; then
        echo "User directory of <${username}> is cleaning."
        smbpasswd -x ${username}
        chown -r ${GRP_NAME}:${GRP_NAME} ${DATA_PATH}/${GRP_NAME}/${username}
        #chmod -R 755 ${DATA_PATH}/${GRP_NAME}/${username}
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
