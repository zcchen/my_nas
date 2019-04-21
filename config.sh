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

NETWORK_CARD='bond0'
LOCAL_NETWORK='192.168.1.0/24'
LOCAL_NAS_IP="192.168.1.5"
NAS_DONAME="nas.zcchen.me"
DNS_SERVER="114.114.114.114"
SSHD_PORT_1=22
SSHD_PORT_2=22

SNAP_USER="admin"
SNAP_PATH=( \
    "root:/"
    "nas_data:/data/data"
)
