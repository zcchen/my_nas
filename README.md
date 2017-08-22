家用NAS解决方案
===============

考虑到webdav在上传大文件时候的不稳定性，smb/cifs在公网上的不安全性，sftp传输时的资源开销较大且速度较慢，以及相应的文件目录和权限问题。
经过折腾后，形成一下解决方案。

本方案，主要是基于各个程序的优点而组合的：
+ **nextcloud**能非常方便地对文件进行管理、分享、协同编辑，
+ smb能在局域网内非常方便地交换文件，
+ sftp能相对安全地在公网范围内进行文件交互，尤其是大文件。
+ syncthing能相对方便地把手机上的照片信息上传至服务器。
+ aria2能非常方便地实现离线下载

文件目录
--------

```
/data/                          root: root      755 整个数据硬盘的挂载点
  |- upload/                    root: root      755 为了sftp准备
     +- upload/                 root: family    773 仅用于sftp上传文件。
    (用户：upload: upload)
  |- family/                    root: root      750 组群储存的数据目录，核心目录，sftp、smb的基础目录
     |- public/                 root: family    750 组群储存的共享目录，(固定目录内容)
        |- Movies_电影/         public: family  775 组群电影目录
        |- Music_音乐/          public: family  775 组群音乐目录
        |- Picture_贴图/        public: family  775 组群贴图/公开版权照片目录
        |- Games_游戏/          public: family  775 组群游戏目录
        |- Software_软件/       public: family  775 组群软件目录
        |- eBooks_电子书/       public: family  775 组群电子书目录
        |- Downloads_下载/      public: family  775 组群下载完成目录
        +- Upload_临时上传/     public: family  777 临时上传文件目录
           +- temp_外部上传     public: family      symlinks to ../../upload/upload
      (这些目录，可通过外部匿名访问，方便访客和TV等设备。)
     |- family/                 family: family  770 组群储存的共享目录。
        |- Photos_照片/         family: family  770 群组公共照片
        +- Public_公共文件/     family: family  770 群组公共照片
           +- (others)/         (user): family  770 其他目录，由群组内部用户自行添加创建的。
      (这些目录，仅可通过family用户组内部，通过smb，sftp进行登录修改)
     +- (users / .skel)/        (user): family  700 用户内部目录，也是(users)的home目录
        |- Movies_电影/         symlinks to ../public/Movies_电影
        |- Music_音乐/          symlinks to ../public/Music_音乐
        |- Picture_贴图/        symlinks to ../public/Picture_贴图
        |- Games_游戏/          symlinks to ../public/Games_游戏
        |- Software_软件/       symlinks to ../public/Software_软件
        |- eBooks_电子书/       symlinks to ../public/eBooks_电子书
        |- Downloads_下载/      symlinks to ../public/Downloads_下载
        |- Upload_临时上传/     symlinks to ../public/Upload_临时上传
        |- Public_公共文件/     symlinks to ../family/Public_公共文件
        +- Photos_照片/         root: family    700 照片目录
           |- family_家庭照片   root: family        symlinks to ../family/Photos_照片
           +- personal_个人照片 (user): family  700 个人照片目录
        +- (others)/            (user): family  700 个人目录
  |- nextcloud/                 root: root      755 nextcloud目录
     |- db_backup/              admin: root     750 用于备份nextcloud的数据库。
     +- data/                   www: www        750 nextcloud_data储存目录

/opt/my_nas/                    root: root  755 my_nas的相关储存目录，包括脚本，运行等。
      |- bin/                   root: root  755
      |- lib/systemd/system/    root: root  755 systemd files
      |- usr/doc/               root: root  755 config docs
      |- usr/patches/           root: root  755 patches for the unit I am using.
      |- etc/                   root: root  755 etc configs, like nextcloud docker config.php
```

users
------------
用户主要分为以下这些：
upload: gid-upload， /bin/false, no-home, 仅用于外网sftp上传。
public: gid-nogroup, /bin/false, no-home, 仅用于smb映射。
(user): gid-family,  /bin/false, /data/family/(user), 可用于外网sftp上传下载，也可用于内部smb管理

网络连接
------------
局域网内，router指定NAS为第一DNS；第二DNS为114.114.114.114，或223.5.5.5。
client -> nas.doname -> NAS

无公网IP，nas.doname 指向 VPS，由VPS进行数据转发。SSL证书也通过该VPS上的脚本，定期推送回NAS。

有公网IP，NAS放置在DMZ区，nas.doname走CNAME转发至DDNS对应的域名。SSL证书通过放置在NAS上的脚本进行定期更新。

程序组
--------
### sftp
+ sftp chrootDirectory: /data/family
+ 默认的写入权限是：640。

### smb
+ 最重要的是，针对[%U]目录，打开symlinks支持。
+ 默认的写入权限是：640。
+ 同步Unix和smb密码。

### syncthing
+ syncthing 主要是能把手机上的照片上传到`/data/family/(user)/Photos_照片/personal_个人照片`。
+ 把需要增量储存的文件，都通过 syncthing 上传至相应的服务器目录。
由于主要都是采用 send to only，因此，该服务可替换。

### cron脚本
由于sftp无法根据目录来实现权限一致，因此，采用cron脚本，每隔15min，检查一次`/data/family`里面的目录，权限是否正常。

### nextcloud
1. docker nextcloud搭建创建好，创建(users)，采用单用户单群组。
2. 打开「外部储存」，分用户分文件夹（每个小分类）挂载`localhost`的`smb`服务。
3. 这些外部储存的，基本不进行同步，只采用nextcloud来进行管理。
4. 预留不大的quota，用于进行手机联系人、日程等进行同步。
5. Apache2设定为，只监听本地8080端口；外部访问，依靠nginx调配。

### nginx
1. 反向代理
2. 为aria2提供web-ui

### DNS, unbound + dnscrypt-proxy
1. 采用`unbound`作为内网DNS服务器提供方。
2. 采用`dnscrypt-proxy`作为配合，解决DNS污染问题。
3. unbound上，采用配置文件的方式，解决局域网内的DNS解析指引。

### frp
1. 穿越内网的工具
2. 可采用不稳定的ssh替代。

### SSL的解决
letsencrypt解决问题。

### aria2
1. save-session / input-file 放在ssd硬盘上，反正ssd硬盘做系统盘之余，足够大。
2. download 文件夹也可以放在ssd硬盘上。
3. 下载完成后，可采用nextcloud来进行移动。
4. YAAW，web-ui，还有众多各种前端。
   eg.[Aria2 & YAAW 使用说明][http://aria2c.com/usage.html]

备份方案
--------------

### btrfs镜像
1. 采用snapper的方式，自动形成对应的snapshot，尤其是针对`/data`目录。
2. 需要注意的是，需要把日志文件尽量移除，尤其是类似，nextcloud目录内的日志文件。
3. 如果需要恢复，命令行登录，用snapper恢复。

### nextcloud的数据库备份
输入以下命令即可
`mysqldump -u <user> -p'<passwd>' --one-database <db_name> > /path/you/want`

<!--
vim: ft=markdown
-->
