CONFIG_SH       = ../config.sh
BUILD_PKG       = apt install curl git unbound dnscrypt-proxy
BUILDDIR        = build
DNS_CHINA_REPO  = dnsmasq-china-list

all: prepare unbound dnscrypt dns_china
	find ${BUILDDIR} -type d -print0 | xargs -0 chmod 755
	find ${BUILDDIR} -type f -print0 | xargs -0 chmod 644
	@echo "Make is Done..."

unbound: ${BUILDDIR}
	mkdir -p ${BUILDDIR}/unbound/unbound.conf.d/
	curl ftp://FTP.INTERNIC.NET/domain/named.cache -o ${BUILDDIR}/unbound/root.hints
	unbound/unbound_set.sh ${CONFIG_SH} \
		${BUILDDIR}/unbound/unbound.conf \
		${BUILDDIR}/unbound/unbound.conf.d/local_data.conf

dnscrypt: ${BUILDDIR}
	mkdir -p ${BUILDDIR}/dnscrypt/
	sed -f dnscrypt-sed/dnscrypt-etc-conf.sed /etc/dnscrypt-proxy/dnscrypt-proxy.conf > ${BUILDDIR}/dnscrypt/dnscrypt-proxy.conf
	sed -f dnscrypt-sed/dnscrypt-systemd.sed /lib/systemd/system/dnscrypt-proxy.socket > ${BUILDDIR}/dnscrypt/dnscrypt-proxy.socket

dns_china: unbound
	if [ -d ${DNS_CHINA_REPO}/.git ]; then \
	    cd ${DNS_CHINA_REPO} && git pull --depth 1; \
	else \
	    git clone --depth 1 "git://github.com/felixonmars/${DNS_CHINA_REPO}" ${DNS_CHINA_REPO}; \
	fi
	cd ${DNS_CHINA_REPO} && make SERVER=${DNS_SERVER} unbound
	cp ${DNS_CHINA_REPO}/*.unbound.* ${BUILDDIR}/unbound/unbound.conf.d

prepare:
	sudo ${BUILD_PKG}

install:
	cp -iR ${BUILDDIR}/unbound/* /etc/unbound
	chmod 644 /etc/unbound/unbound.conf /etc/unbound/root.hints /etc/unbound/unbound.conf.d/*
	cp -i ${BUILDDIR}/dnscrypt/dnscrypt-proxy.conf /etc/dnscrypt-proxy/dnscrypt-proxy.conf
	chmod 644 /etc/dnscrypt-proxy/dnscrypt-proxy.conf
	cp -i ${BUILDDIR}/dnscrypt/dnscrypt-proxy.socket /lib/systemd/system/dnscrypt-proxy.socket
	chmod 644 /lib/systemd/system/dnscrypt-proxy.socket
	systemctl enable unbound
	systemctl enable dnscrypt-proxy

restart:
	systemctl daemon-reload
	systemctl restart unbound dnscrypt-proxy

${BUILDDIR}:
	mkdir -p $@

clean:
	-rm -rf ${BUILDDIR}
	-rm -rf ${DNS_CHINA_REPO}
