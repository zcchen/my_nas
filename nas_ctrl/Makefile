CONFIG_SH  = config.sh
BUILDDIR   = build

all: make_dir scripts

scripts: my_nas_ctrl.sh snapper_set.sh smb.conf sshd_config

my_nas_ctrl.sh:
	@echo "Generating file <$(@)>..."
	echo "#!/bin/bash\n" > ${BUILDDIR}/usr/bin/$(@)
	cat ${CONFIG_SH} >> ${BUILDDIR}/usr/bin/$(@)
	cat scripts/my_nas_ctrl.sh >> ${BUILDDIR}/usr/bin/$(@)
	chmod 755 ${BUILDDIR}/usr/bin/$(@)
	@echo

snapper_set.sh:
	@echo "Generating file <$(@)>..."
	cp scripts/snapper_set.sh ${BUILDDIR}/usr/bin/$(@)
	chmod 755 ${BUILDDIR}/usr/bin/$(@)
	@echo

smb.conf:
	@echo "Generating file <$(@)>..."
	samba/generate.sh ${CONFIG_SH} > ${BUILDDIR}/etc/samba/${@}
	chmod 644 ${BUILDDIR}/etc/samba/${@}
	@echo

sshd_config:
	@echo "Generating file <$(@)>..."
	sshd/generate.sh ${CONFIG_SH} > ${BUILDDIR}/etc/ssh/${@}
	chmod 644 ${BUILDDIR}/etc/ssh/${@}
	@echo

install: backup
	cp -rf ${BUILDDIR}/* /
	@echo "The NAS setting is installed..."

backup:
	mkdir -p /etc/my_nas/backup/bin
	mkdir -p /etc/my_nas/backup/conf
	-cp /usr/bin/my_nas_ctrl.sh /etc/my_nas/backup/bin
	-cp /usr/bin/snapper_set.sh /etc/my_nas/backup/bin
	-cp /etc/samba/smb.conf /etc/ssh/sshd_config /etc/my_nas/backup/conf

clean:
	-rm -rf ${BUILDDIR}

make_dir:
	mkdir -p ${BUILDDIR}/usr/bin
	mkdir -p ${BUILDDIR}/etc/samba
	mkdir -p ${BUILDDIR}/etc/ssh
	@echo

