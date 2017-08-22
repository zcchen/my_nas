CONFIG_SH  = config.sh
BUILDDIR   = build

all: make_dir scripts


scripts: my_nas_ctrl.sh snapper_set.sh smb.conf

my_nas_ctrl.sh:
	@echo "Generating file <$(@)>..."
	echo -e "#!/bin/bash\n" > ${BUILDDIR}/$(@)
	cat ${CONFIG_SH} >> ${BUILDDIR}/$(@)
	cat scripts/my_nas_ctrl.sh >> ${BUILDDIR}/$(@)
	chmod 755 ${BUILDDIR}/$(@)
	@echo

snapper_set.sh:
	@echo "Generating file <$(@)>..."
	cp scripts/snapper_set.sh ${BUILDDIR}/$(@)
	chmod 755 ${BUILDDIR}/$(@)
	@echo

smb.conf:
	@echo "Generating file <$(@)>..."
	samba/generate.sh ${CONFIG_SH} > ${BUILDDIR}/${@}
	chmod 644 ${BUILDDIR}/$(@)
	@echo

install: backup

backup:
	mkdir -p /etc/my_nas/backup

clean:
	-rm -rf ${BUILDDIR}

make_dir:
	mkdir -p ${BUILDDIR}/
	@echo

