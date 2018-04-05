NAS_DONAME = nas.zcchen.me
DNS_SERVER = 114.114.114.114
LOCAL_NET  = 192.168.1.0/24
LOCAL_NAS  = 192.168.1.5

PAK_INSTALL= apt install unbound dnscrypt-proxy
BUILDDIR   = build

all: unbound dnscrypt dns_china
	find ${BUILDDIR} -type d -print0 | xargs -0 chmod 755
	find ${BUILDDIR} -type f -print0 | xargs -0 chmod 644
	@echo "Make is Done..."

unbound: make_dir
	mkdir -p ${BUILDDIR}/unbound/unbound.conf.d/
	curl ftp://FTP.INTERNIC.NET/domain/named.cache -o ${BUILDDIR}/unbound/root.hints
	sed -e "s,__LOCAL_NET__,${LOCAL_NET},g" unbound/unbound-example.conf > ${BUILDDIR}/unbound/unbound.conf
	sed -e "s,__LOCAL_NET__,${LOCAL_NET},g; s,__NAS_DONAME__,${NAS_DONAME},g; s,__LOCAL_NAS__,${LOCAL_NAS},g;" unbound/local_data-example.conf > ${BUILDDIR}/unbound/unbound.conf.d/local_data.conf

dnscrypt: make_dir
	mkdir -p ${BUILDDIR}/dnscrypt/
	sed -f dnscrypt-sed/dnscrypt-etc-conf.sed /etc/dnscrypt-proxy/dnscrypt-proxy.conf > ${BUILDDIR}/dnscrypt/dnscrypt-proxy.conf
	sed -f dnscrypt-sed/dnscrypt-systemd.sed /lib/systemd/system/dnscrypt-proxy.socket > ${BUILDDIR}/dnscrypt/dnscrypt-proxy.socket

dns_china: unbound
	if [ -d dnsmasq-china-list/.git ]; then \
	    cd dnsmasq-china-list && git pull; \
	else \
	    git clone --depth 1 "git://github.com/felixonmars/dnsmasq-china-list"; \
	fi
	cd dnsmasq-china-list && make SERVER=${DNS_SERVER} unbound
	cp dnsmasq-china-list/*.unbound.* ${BUILDDIR}/unbound/unbound.conf.d

install:
	${PAK_INSTALL}
	cp -iR ${BUILDDIR}/unbound/* /etc/unbound
	chmod 644 /etc/unbound/unbound.conf /etc/unbound/root.hints /etc/unbound/unbound.conf.d/*
	cp -i ${BUILDDIR}/dnscrypt/dnscrypt-proxy.conf /etc/dnscrypt-proxy/dnscrypt-proxy.conf
	chmod 644 /etc/dnscrypt-proxy/dnscrypt-proxy.conf
	cp -i ${BUILDDIR}/dnscrypt/dnscrypt-proxy.socket /lib/systemd/system/dnscrypt-proxy.socket
	chmod 644 /lib/systemd/system/dnscrypt-proxy.socket

restart:
	systemctl daemon-reload
	systemctl restart unbound dnscrypt-proxy

make_dir:
	mkdir -p ${BUILDDIR}/

clean:
	-rm -rf ${BUILDDIR}
