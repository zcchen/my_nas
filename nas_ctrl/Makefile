CONFIG_SH  = ../config.sh
BUILDDIR   = build

all: scripts

scripts: my_nas_ctrl.sh snapper_set.sh smb.conf sshd_config

my_nas_ctrl.sh: make_dir
	@echo "Generating file <$(@)>..."
	echo "#!/bin/bash\n" > ${BUILDDIR}/usr/bin/$(@)
	cat ${CONFIG_SH} >> ${BUILDDIR}/usr/bin/$(@)
	cat scripts/my_nas_ctrl.sh >> ${BUILDDIR}/usr/bin/$(@)
	chmod 755 ${BUILDDIR}/usr/bin/$(@)
	cp scripts/nas_fix.* ${BUILDDIR}/lib/systemd/system/
	@echo

snapper_set.sh: make_dir
	@echo "Generating file <$(@)>..."
	bash ./make_snapper-set.sh ${CONFIG_SH} > ${BUILDDIR}/usr/bin/$(@)
	chmod 755 ${BUILDDIR}/usr/bin/$(@)
	@echo

smb.conf: make_dir
	@echo "Generating file <$(@)>..."
	bash ./samba/generate.sh ${CONFIG_SH} > ${BUILDDIR}/etc/samba/${@}
	chmod 644 ${BUILDDIR}/etc/samba/${@}
	@echo

sshd_config: make_dir
	@echo "Generating file <$(@)>..."
	bash ./sshd/generate.sh ${CONFIG_SH} > ${BUILDDIR}/etc/ssh/${@}
	chmod 644 ${BUILDDIR}/etc/ssh/${@}
	@echo

install: backup
	cp -rf ${BUILDDIR}/* /
	systemctl daemon-reload
	systemctl restart nas_fix.timer
	systemctl enable nas_fix.timer
	@echo "The NAS setting is installed..."

backup:
	mkdir -p /etc/my_nas/backup/bin
	mkdir -p /etc/my_nas/backup/conf
	-cp /usr/bin/my_nas_ctrl.sh /etc/my_nas/backup/bin
	-cp /usr/bin/snapper_set.sh /etc/my_nas/backup/bin
	-cp /etc/samba/smb.conf /etc/ssh/sshd_config /etc/my_nas/backup/conf

clean:
	-rm -rf ${BUILDDIR}

make_dir: ${BUILDDIR}/usr/bin ${BUILDDIR}/etc/samba ${BUILDDIR}/etc/ssh ${BUILDDIR}/lib/systemd/system

${BUILDDIR}/%:
	mkdir -p $@

