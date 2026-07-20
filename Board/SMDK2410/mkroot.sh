#!/bin/sh

set -euo pipefail

[ -n "${FAKEROOTKEY:-}" ] || exec fakeroot -- bash "$0" "$@"

HOSTNAME=smdk2410
ISSUE="Welcome to SMDK2410"
DHCP_IFACE=eth0
UBIFS_LEBSIZE=0x3e00
UBIFS_MAXLEBCNT=2048
UBIFS_MINIOSIZE=0x200
UBI_PEBSIZE=0x4000
UBI_SUBSIZE=256

UBOOT_DIR=./u-boot
LINUX_DIR=./linux
BUSYBOX_DIR=./busybox
BUILDROOT_DIR=./buildroot
ROOTFS_DIR=./rootfs
SYSROOT_DIR=./sysroot
TOOLCHAIN=arm-unknown-linux-gnueabi

# ===========================================================================
rm -rf $ROOTFS_DIR
install -d -m 0755 $ROOTFS_DIR/bin
install -d -m 0755 $ROOTFS_DIR/dev/pts
install -d -m 0755 $ROOTFS_DIR/dev/shm
install -d -m 0755 $ROOTFS_DIR/etc/cron/crontabs
install -d -m 0755 $ROOTFS_DIR/etc/init.d
install -d -m 0755 $ROOTFS_DIR/etc/network/if-down.d
install -d -m 0755 $ROOTFS_DIR/etc/network/if-post-down.d
install -d -m 0755 $ROOTFS_DIR/etc/network/if-pre-up.d
install -d -m 0755 $ROOTFS_DIR/etc/network/if-up.d
install -d -m 0755 $ROOTFS_DIR/etc/profile.d
install -d -m 0755 $ROOTFS_DIR/lib
install -d -m 0755 $ROOTFS_DIR/media
install -d -m 0755 $ROOTFS_DIR/mnt
install -d -m 0755 $ROOTFS_DIR/opt
install -d -m 0755 $ROOTFS_DIR/proc
install -d -m 0700 $ROOTFS_DIR/root
install -d -m 0755 $ROOTFS_DIR/run/lock
install -d -m 0755 $ROOTFS_DIR/sbin
install -d -m 0755 $ROOTFS_DIR/sys
install -d -m 1777 $ROOTFS_DIR/tmp
install -d -m 0755 $ROOTFS_DIR/usr/bin
install -d -m 0755 $ROOTFS_DIR/usr/lib
install -d -m 0755 $ROOTFS_DIR/usr/sbin
install -d -m 0755 $ROOTFS_DIR/usr/share
install -d -m 0755 $ROOTFS_DIR/usr/share/udhcpc/default.script.d
install -d -m 0755 $ROOTFS_DIR/var/lib

ln -snf ../proc/self/fd $ROOTFS_DIR/dev/fd
ln -snf ../tmp/log $ROOTFS_DIR/dev/log
ln -snf ../proc/self/fd/2 $ROOTFS_DIR/dev/stderr
ln -snf ../proc/self/fd/0 $ROOTFS_DIR/dev/stdin
ln -snf ../proc/self/fd/1 $ROOTFS_DIR/dev/stdout

ln -snf ../proc/self/mounts $ROOTFS_DIR/etc/mtab
ln -snf ../run/resolv.conf $ROOTFS_DIR/etc/resolv.conf

#ln -snf lib $ROOTFS_DIR/lib64
#ln -snf lib $ROOTFS_DIR/usr/lib64
ln -snf lib $ROOTFS_DIR/lib32
ln -snf lib $ROOTFS_DIR/usr/lib32

ln -snf ../../tmp $ROOTFS_DIR/var/lib/misc
ln -snf ../tmp $ROOTFS_DIR/var/cache
ln -snf ../run/lock $ROOTFS_DIR/var/lock
ln -snf ../tmp $ROOTFS_DIR/var/log
ln -snf ../run $ROOTFS_DIR/var/run
ln -snf ../tmp $ROOTFS_DIR/var/spool
ln -snf ../tmp $ROOTFS_DIR/var/tmp

cat >$ROOTFS_DIR/etc/fstab <<EOF
# <file system>	<mount pt>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext2	rw,noauto	0	1
proc		/proc		proc	defaults	0	0
devpts		/dev/pts	devpts	defaults,gid=5,mode=620,ptmxmode=0666	0	0
tmpfs		/dev/shm	tmpfs	mode=1777	0	0
tmpfs		/tmp		tmpfs	mode=1777	0	0
tmpfs		/run		tmpfs	mode=0755,nosuid,nodev	0	0
sysfs		/sys		sysfs	defaults	0	0
EOF

cat >$ROOTFS_DIR/etc/group <<EOF
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
kmem:x:9:
wheel:x:10:root
cdrom:x:11:
dialout:x:18:
floppy:x:19:
video:x:28:
audio:x:29:
tape:x:32:
www-data:x:33:
operator:x:37:
utmp:x:43:
plugdev:x:46:
staff:x:50:
lock:x:54:
netdev:x:82:
users:x:100:
nobody:x:65534:
EOF

echo "$HOSTNAME" > $ROOTFS_DIR/etc/hostname

cat >$ROOTFS_DIR/etc/hosts <<EOF
127.0.0.1	localhost
127.0.1.1	$HOSTNAME
EOF

cat >$ROOTFS_DIR/etc/inittab <<EOF
# /etc/inittab
#
# Copyright (C) 2001 Erik Andersen <andersen@codepoet.org>
#
# Note: BusyBox init doesn't support runlevels.  The runlevels field is
# completely ignored by BusyBox init. If you want runlevels, use
# sysvinit.
#
# Format for each entry: <id>:<runlevels>:<action>:<process>
#
# id        == tty to run on, or empty for /dev/console
# runlevels == ignored
# action    == one of sysinit, respawn, askfirst, wait, and once
# process   == program to run

# Startup the system
::sysinit:/bin/mount -t proc proc /proc
::sysinit:/bin/mount -o remount,rw /
::sysinit:/bin/mkdir -p /dev/pts /dev/shm
::sysinit:/bin/mount -a
::sysinit:/bin/mkdir -p /run/lock/subsys
::sysinit:/sbin/swapon -a
null::sysinit:/bin/ln -sf /proc/self/fd /dev/fd
null::sysinit:/bin/ln -sf /proc/self/fd/0 /dev/stdin
null::sysinit:/bin/ln -sf /proc/self/fd/1 /dev/stdout
null::sysinit:/bin/ln -sf /proc/self/fd/2 /dev/stderr
::sysinit:/bin/hostname -F /etc/hostname
# now run any rc scripts
::sysinit:/etc/init.d/rcS

# Put a getty on the serial port
console::respawn:/sbin/getty -L  console 0 vt100 # GENERIC_SERIAL

# Stuff to do for the 3-finger salute
#::ctrlaltdel:/sbin/reboot

# Stuff to do before rebooting
::shutdown:/etc/init.d/rcK
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
EOF

echo "$ISSUE" > $ROOTFS_DIR/etc/issue

cat >$ROOTFS_DIR/etc/nsswitch.conf <<EOF
# /etc/nsswitch.conf

passwd:         files
group:          files
shadow:         files

hosts:          files dns
networks:       files dns

protocols:      files
services:       files
ethers:         files
rpc:            files
EOF

cat >$ROOTFS_DIR/usr/lib/os-release <<EOF
NAME=Buildroot
VERSION=2026.08
ID=buildroot
VERSION_ID=2026.08
PRETTY_NAME="Buildroot 2026.08"
EOF
ln -snf ../usr/lib/os-release $ROOTFS_DIR/etc

cat >$ROOTFS_DIR/etc/passwd <<EOF
root:x:0:0:root:/root:/bin/sh
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
sys:x:3:3:sys:/dev:/bin/false
sync:x:4:100:sync:/bin:/bin/sync
mail:x:8:8:mail:/var/spool/mail:/bin/false
www-data:x:33:33:www-data:/var/www:/bin/false
operator:x:37:37:Operator:/var:/bin/false
nobody:x:65534:65534:nobody:/home:/bin/false
EOF

cat >$ROOTFS_DIR/etc/profile <<'EOF'
export PATH="/bin:/sbin:/usr/bin:/usr/sbin"

if [ "$PS1" ]; then
	if [ "`id -u`" -eq 0 ]; then
		export PS1='# '
	else
		export PS1='$ '
	fi
fi

export EDITOR='/bin/vi'

# Source configuration files from /etc/profile.d
for i in /etc/profile.d/*.sh ; do
	if [ -r "$i" ]; then
		. $i
	fi
done
unset i
EOF

cat >$ROOTFS_DIR/etc/protocols <<EOF
# Internet (IP) protocols
#
# Updated from http://www.iana.org/assignments/protocol-numbers and other
# sources.

ip	0	IP		# internet protocol, pseudo protocol number
hopopt	0	HOPOPT		# IPv6 Hop-by-Hop Option [RFC1883]
icmp	1	ICMP		# internet control message protocol
igmp	2	IGMP		# Internet Group Management
ggp	3	GGP		# gateway-gateway protocol
ipencap	4	IP-ENCAP	# IP encapsulated in IP (officially ``IP'')
st	5	ST		# ST datagram mode
tcp	6	TCP		# transmission control protocol
egp	8	EGP		# exterior gateway protocol
igp	9	IGP		# any private interior gateway (Cisco)
pup	12	PUP		# PARC universal packet protocol
udp	17	UDP		# user datagram protocol
hmp	20	HMP		# host monitoring protocol
xns-idp	22	XNS-IDP		# Xerox NS IDP
rdp	27	RDP		# "reliable datagram" protocol
iso-tp4	29	ISO-TP4		# ISO Transport Protocol class 4 [RFC905]
dccp	33	DCCP		# Datagram Congestion Control Prot. [RFC4340]
xtp	36	XTP		# Xpress Transfer Protocol
ddp	37	DDP		# Datagram Delivery Protocol
idpr-cmtp 38	IDPR-CMTP	# IDPR Control Message Transport
ipv6	41	IPv6		# Internet Protocol, version 6
ipv6-route 43	IPv6-Route	# Routing Header for IPv6
ipv6-frag 44	IPv6-Frag	# Fragment Header for IPv6
idrp	45	IDRP		# Inter-Domain Routing Protocol
rsvp	46	RSVP		# Reservation Protocol
gre	47	GRE		# General Routing Encapsulation
esp	50	IPSEC-ESP	# Encap Security Payload [RFC2406]
ah	51	IPSEC-AH	# Authentication Header [RFC2402]
skip	57	SKIP		# SKIP
ipv6-icmp 58	IPv6-ICMP	# ICMP for IPv6
ipv6-nonxt 59	IPv6-NoNxt	# No Next Header for IPv6
ipv6-opts 60	IPv6-Opts	# Destination Options for IPv6
rspf	73	RSPF CPHB	# Radio Shortest Path First (officially CPHB)
vmtp	81	VMTP		# Versatile Message Transport
eigrp	88	EIGRP		# Enhanced Interior Routing Protocol (Cisco)
ospf	89	OSPFIGP		# Open Shortest Path First IGP
ax.25	93	AX.25		# AX.25 frames
ipip	94	IPIP		# IP-within-IP Encapsulation Protocol
etherip	97	ETHERIP		# Ethernet-within-IP Encapsulation [RFC3378]
encap	98	ENCAP		# Yet Another IP encapsulation [RFC1241]
#	99			# any private encryption scheme
pim	103	PIM		# Protocol Independent Multicast
ipcomp	108	IPCOMP		# IP Payload Compression Protocol
vrrp	112	VRRP		# Virtual Router Redundancy Protocol [RFC5798]
l2tp	115	L2TP		# Layer Two Tunneling Protocol [RFC2661]
isis	124	ISIS		# IS-IS over IPv4
sctp	132	SCTP		# Stream Control Transmission Protocol
fc	133	FC		# Fibre Channel
mobility-header 135 Mobility-Header # Mobility Support for IPv6 [RFC3775]
udplite	136	UDPLite		# UDP-Lite [RFC3828]
mpls-in-ip 137	MPLS-in-IP	# MPLS-in-IP [RFC4023]
manet	138			# MANET Protocols [RFC5498]
hip	139	HIP		# Host Identity Protocol
shim6	140	Shim6		# Shim6 Protocol [RFC5533]
wesp	141	WESP		# Wrapped Encapsulating Security Payload
rohc	142	ROHC		# Robust Header Compression
EOF

cat >$ROOTFS_DIR/etc/services <<'EOF'
# /etc/services:
# $Id: services,v 1.1 2004/10/09 02:49:18 andersen Exp $
#
# Network services, Internet style
#
# Note that it is presently the policy of IANA to assign a single well-known
# port number for both TCP and UDP; hence, most entries here have two entries
# even if the protocol doesn't support UDP operations.
# Updated from RFC 1700, ``Assigned Numbers'' (October 1994).  Not all ports
# are included, only the more common ones.

tcpmux		1/tcp				# TCP port service multiplexer
echo		7/tcp
echo		7/udp
discard		9/tcp		sink null
discard		9/udp		sink null
systat		11/tcp		users
daytime		13/tcp
daytime		13/udp
netstat		15/tcp
qotd		17/tcp		quote
msp		18/tcp				# message send protocol
msp		18/udp				# message send protocol
chargen		19/tcp		ttytst source
chargen		19/udp		ttytst source
ftp-data	20/tcp
ftp		21/tcp
fsp		21/udp		fspd
ssh		22/tcp				# SSH Remote Login Protocol
ssh		22/udp				# SSH Remote Login Protocol
telnet		23/tcp
# 24 - private
smtp		25/tcp		mail
# 26 - unassigned
time		37/tcp		timserver
time		37/udp		timserver
rlp		39/udp		resource	# resource location
nameserver	42/tcp		name		# IEN 116
whois		43/tcp		nicname
re-mail-ck	50/tcp				# Remote Mail Checking Protocol
re-mail-ck	50/udp				# Remote Mail Checking Protocol
domain		53/tcp		nameserver	# name-domain server
domain		53/udp		nameserver
mtp		57/tcp				# deprecated
bootps		67/tcp				# BOOTP server
bootps		67/udp
bootpc		68/tcp				# BOOTP client
bootpc		68/udp
tftp		69/udp
gopher		70/tcp				# Internet Gopher
gopher		70/udp
rje		77/tcp		netrjs
finger		79/tcp
www		80/tcp		http		# WorldWideWeb HTTP
www		80/udp				# HyperText Transfer Protocol
link		87/tcp		ttylink
kerberos	88/tcp		kerberos5 krb5	# Kerberos v5
kerberos	88/udp		kerberos5 krb5	# Kerberos v5
supdup		95/tcp
# 100 - reserved
hostnames	101/tcp		hostname	# usually from sri-nic
iso-tsap	102/tcp		tsap		# part of ISODE.
csnet-ns	105/tcp		cso-ns		# also used by CSO name server
csnet-ns	105/udp		cso-ns
# unfortunately the poppassd (Eudora) uses a port which has already
# been assigned to a different service. We list the poppassd as an
# alias here. This should work for programs asking for this service.
# (due to a bug in inetd the 3com-tsmux line is disabled)
#3com-tsmux	106/tcp		poppassd
#3com-tsmux	106/udp		poppassd
rtelnet		107/tcp				# Remote Telnet
rtelnet		107/udp
pop-2		109/tcp		postoffice	# POP version 2
pop-2		109/udp
pop-3		110/tcp				# POP version 3
pop-3		110/udp
sunrpc		111/tcp		portmapper	# RPC 4.0 portmapper TCP
sunrpc		111/udp		portmapper	# RPC 4.0 portmapper UDP
auth		113/tcp		authentication tap ident
sftp		115/tcp
uucp-path	117/tcp
nntp		119/tcp		readnews untp	# USENET News Transfer Protocol
ntp		123/tcp
ntp		123/udp				# Network Time Protocol
netbios-ns	137/tcp				# NETBIOS Name Service
netbios-ns	137/udp
netbios-dgm	138/tcp				# NETBIOS Datagram Service
netbios-dgm	138/udp
netbios-ssn	139/tcp				# NETBIOS session service
netbios-ssn	139/udp
imap2		143/tcp				# Interim Mail Access Proto v2
imap2		143/udp
snmp		161/udp				# Simple Net Mgmt Proto
snmp-trap	162/udp		snmptrap	# Traps for SNMP
cmip-man	163/tcp				# ISO mgmt over IP (CMOT)
cmip-man	163/udp
cmip-agent	164/tcp
cmip-agent	164/udp
xdmcp		177/tcp				# X Display Mgr. Control Proto
xdmcp		177/udp
nextstep	178/tcp		NeXTStep NextStep	# NeXTStep window
nextstep	178/udp		NeXTStep NextStep	# server
bgp		179/tcp				# Border Gateway Proto.
bgp		179/udp
prospero	191/tcp				# Cliff Neuman's Prospero
prospero	191/udp
irc		194/tcp				# Internet Relay Chat
irc		194/udp
smux		199/tcp				# SNMP Unix Multiplexer
smux		199/udp
at-rtmp		201/tcp				# AppleTalk routing
at-rtmp		201/udp
at-nbp		202/tcp				# AppleTalk name binding
at-nbp		202/udp
at-echo		204/tcp				# AppleTalk echo
at-echo		204/udp
at-zis		206/tcp				# AppleTalk zone information
at-zis		206/udp
qmtp		209/tcp				# The Quick Mail Transfer Protocol
qmtp		209/udp				# The Quick Mail Transfer Protocol
z3950		210/tcp		wais		# NISO Z39.50 database
z3950		210/udp		wais
ipx		213/tcp				# IPX
ipx		213/udp
imap3		220/tcp				# Interactive Mail Access
imap3		220/udp				# Protocol v3
ulistserv	372/tcp				# UNIX Listserv
ulistserv	372/udp
https		443/tcp				# MCom
https		443/udp				# MCom
snpp		444/tcp				# Simple Network Paging Protocol
snpp		444/udp				# Simple Network Paging Protocol
saft		487/tcp				# Simple Asynchronous File Transfer
saft		487/udp				# Simple Asynchronous File Transfer
npmp-local	610/tcp		dqs313_qmaster	# npmp-local / DQS
npmp-local	610/udp		dqs313_qmaster	# npmp-local / DQS
npmp-gui	611/tcp		dqs313_execd	# npmp-gui / DQS
npmp-gui	611/udp		dqs313_execd	# npmp-gui / DQS
hmmp-ind	612/tcp		dqs313_intercell# HMMP Indication / DQS
hmmp-ind	612/udp		dqs313_intercell# HMMP Indication / DQS
#
# UNIX specific services
#
exec		512/tcp
biff		512/udp		comsat
login		513/tcp
who		513/udp		whod
shell		514/tcp		cmd		# no passwords used
syslog		514/udp
printer		515/tcp		spooler		# line printer spooler
talk		517/udp
ntalk		518/udp
route		520/udp		router routed	# RIP
timed		525/udp		timeserver
tempo		526/tcp		newdate
courier		530/tcp		rpc
conference	531/tcp		chat
netnews		532/tcp		readnews
netwall		533/udp				# -for emergency broadcasts
uucp		540/tcp		uucpd		# uucp daemon
afpovertcp	548/tcp				# AFP over TCP
afpovertcp	548/udp				# AFP over TCP
remotefs	556/tcp		rfs_server rfs	# Brunhoff remote filesystem
klogin		543/tcp				# Kerberized `rlogin' (v5)
kshell		544/tcp		krcmd		# Kerberized `rsh' (v5)
kerberos-adm	749/tcp				# Kerberos `kadmin' (v5)
#
webster		765/tcp				# Network dictionary
webster		765/udp
#
# From ``Assigned Numbers'':
#
#> The Registered Ports are not controlled by the IANA and on most systems
#> can be used by ordinary user processes or programs executed by ordinary
#> users.
#
#> Ports are used in the TCP [45,106] to name the ends of logical
#> connections which carry long term conversations.  For the purpose of
#> providing services to unknown callers, a service contact port is
#> defined.  This list specifies the port used by the server process as its
#> contact port.  While the IANA can not control uses of these ports it
#> does register or list uses of these ports as a convienence to the
#> community.
#
nfsdstatus	1110/tcp
nfsd-keepalive	1110/udp

ingreslock	1524/tcp
ingreslock	1524/udp
prospero-np	1525/tcp			# Prospero non-privileged
prospero-np	1525/udp
datametrics	1645/tcp	old-radius	# datametrics / old radius entry
datametrics	1645/udp	old-radius	# datametrics / old radius entry
sa-msg-port	1646/tcp	old-radacct	# sa-msg-port / old radacct entry
sa-msg-port	1646/udp	old-radacct	# sa-msg-port / old radacct entry
radius		1812/tcp			# Radius
radius		1812/udp			# Radius
radacct		1813/tcp			# Radius Accounting
radacct		1813/udp			# Radius Accounting
nfsd		2049/tcp	nfs
nfsd		2049/udp	nfs
cvspserver	2401/tcp			# CVS client/server operations
cvspserver	2401/udp			# CVS client/server operations
mysql		3306/tcp			# MySQL
mysql		3306/udp			# MySQL
rfe		5002/tcp			# Radio Free Ethernet
rfe		5002/udp			# Actually uses UDP only
cfengine	5308/tcp			# CFengine
cfengine	5308/udp			# CFengine
bbs		7000/tcp			# BBS service
#
#
# Kerberos (Project Athena/MIT) services
# Note that these are for Kerberos v4, and are unofficial.  Sites running
# v4 should uncomment these and comment out the v5 entries above.
#
kerberos4	750/udp		kerberos-iv kdc	# Kerberos (server) udp
kerberos4	750/tcp		kerberos-iv kdc	# Kerberos (server) tcp
kerberos_master	751/udp				# Kerberos authentication
kerberos_master	751/tcp				# Kerberos authentication
passwd_server	752/udp				# Kerberos passwd server
krb_prop	754/tcp				# Kerberos slave propagation
krbupdate	760/tcp		kreg		# Kerberos registration
kpasswd		761/tcp		kpwd		# Kerberos "passwd"
kpop		1109/tcp			# Pop with Kerberos
knetd		2053/tcp			# Kerberos de-multiplexor
zephyr-srv	2102/udp			# Zephyr server
zephyr-clt	2103/udp			# Zephyr serv-hm connection
zephyr-hm	2104/udp			# Zephyr hostmanager
eklogin		2105/tcp			# Kerberos encrypted rlogin
#
# Unofficial but necessary (for NetBSD) services
#
supfilesrv	871/tcp				# SUP server
supfiledbg	1127/tcp			# SUP debugging
#
# Datagram Delivery Protocol services
#
rtmp		1/ddp				# Routing Table Maintenance Protocol
nbp		2/ddp				# Name Binding Protocol
echo		4/ddp				# AppleTalk Echo Protocol
zip		6/ddp				# Zone Information Protocol
#
# Services added for the Debian GNU/Linux distribution
poppassd	106/tcp				# Eudora
poppassd	106/udp				# Eudora
mailq		174/tcp				# Mailer transport queue for Zmailer
mailq		174/tcp				# Mailer transport queue for Zmailer
omirr		808/tcp		omirrd		# online mirror
omirr		808/udp		omirrd		# online mirror
rmtcfg		1236/tcp			# Gracilis Packeten remote config server
xtel		1313/tcp			# french minitel
coda_opcons	1355/udp			# Coda opcons            (Coda fs)
coda_venus	1363/udp			# Coda venus             (Coda fs)
coda_auth	1357/udp			# Coda auth              (Coda fs)
coda_udpsrv	1359/udp			# Coda udpsrv            (Coda fs)
coda_filesrv	1361/udp			# Coda filesrv           (Coda fs)
codacon		1423/tcp	venus.cmu	# Coda Console           (Coda fs)
coda_aux1	1431/tcp			# coda auxiliary service (Coda fs)
coda_aux1	1431/udp			# coda auxiliary service (Coda fs)
coda_aux2	1433/tcp			# coda auxiliary service (Coda fs)
coda_aux2	1433/udp			# coda auxiliary service (Coda fs)
coda_aux3	1435/tcp			# coda auxiliary service (Coda fs)
coda_aux3	1435/udp			# coda auxiliary service (Coda fs)
cfinger		2003/tcp			# GNU Finger
afbackup	2988/tcp			# Afbackup system
afbackup	2988/udp			# Afbackup system
icp		3130/tcp			# Internet Cache Protocol (Squid)
icp		3130/udp			# Internet Cache Protocol (Squid)
postgres	5432/tcp			# POSTGRES
postgres	5432/udp			# POSTGRES
fax		4557/tcp			# FAX transmission service        (old)
hylafax		4559/tcp			# HylaFAX client-server protocol  (new)
noclog		5354/tcp			# noclogd with TCP (nocol)
noclog		5354/udp			# noclogd with UDP (nocol)
hostmon		5355/tcp			# hostmon uses TCP (nocol)
hostmon		5355/udp			# hostmon uses TCP (nocol)
ircd		6667/tcp			# Internet Relay Chat
ircd		6667/udp			# Internet Relay Chat
webcache	8080/tcp			# WWW caching service
webcache	8080/udp			# WWW caching service
tproxy		8081/tcp			# Transparent Proxy
tproxy		8081/udp			# Transparent Proxy
mandelspawn	9359/udp	mandelbrot	# network mandelbrot
amanda		10080/udp			# amanda backup services
amandaidx	10082/tcp			# amanda backup services
amidxtape	10083/tcp			# amanda backup services
isdnlog		20011/tcp			# isdn logging system
isdnlog		20011/udp			# isdn logging system
vboxd		20012/tcp			# voice box system
vboxd		20012/udp			# voice box system
binkp           24554/tcp			# Binkley
binkp           24554/udp			# Binkley
asp		27374/tcp			# Address Search Protocol
asp		27374/udp			# Address Search Protocol
tfido           60177/tcp			# Ifmail
tfido           60177/udp			# Ifmail
fido            60179/tcp			# Ifmail
fido            60179/udp			# Ifmail

# Local services

EOF

cat >$ROOTFS_DIR/etc/shadow <<EOF
root::::::::
daemon:*:::::::
bin:*:::::::
sys:*:::::::
sync:*:::::::
mail:*:::::::
www-data:*:::::::
operator:*:::::::
nobody:*:::::::
EOF
chmod 0600 $ROOTFS_DIR/etc/shadow

cat >$ROOTFS_DIR/etc/shells <<EOF
/bin/ash
/bin/sh
EOF

cat >$ROOTFS_DIR/etc/init.d/rcS <<'EOF'
#!/bin/sh
#
# Start all init scripts in /etc/init.d
# executing them in numerical order.
#
for i in /etc/init.d/S??*; do

	# Ignore dangling symlinks (if any).
	[ ! -f "$i" ] && continue

	case "$i" in
		*.sh)
			# Source shell script for speed.
			(
				trap - INT QUIT TSTP
				set start
				# shellcheck source=/dev/null
				. "$i"
			)
			;;
		*)
			# No sh extension, so fork subprocess.
			"$i" start
			;;
	esac
done
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/rcS

cat >$ROOTFS_DIR/etc/init.d/rcK <<'EOF'
#!/bin/sh
#
# Stop all init scripts in /etc/init.d
# executing them in reversed numerical order.
#
# we need to reverse the order here, sort -r would be no less fragile
# shellcheck disable=SC2045
for i in $(ls -r /etc/init.d/S??*); do

	# Ignore dangling symlinks (if any).
	[ ! -f "$i" ] && continue

	case "$i" in
		*.sh)
			# Source shell script for speed.
			(
				trap - INT QUIT TSTP
				set stop
				# shellcheck source=/dev/null
				. "$i"
			)
			;;
		*)
			# No sh extension, so fork subprocess.
			"$i" stop
			;;
	esac
done
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/rcK

cat >$ROOTFS_DIR/etc/init.d/S01seedrng <<'EOF'
#! /bin/sh
#
# Preserve the random seed between reboots. See urandom(4).
#
# This script can be called multiple times during operation (e.g. with
# "reload" argument) to refresh the seed.

# The following arguments can be added to SEEDRNG_ARGS in
# /etc/default/seedrng:
#   --seed-dir=/path/to/seed/directory
#     Path to the directory where the seed and the lock files are stored.
#     for optimal operation, this should be a persistent, writeable
#     location. Default is /var/lib/seedrng
#
#  --skip-credit
#     Set this to true only if you do not want seed files to actually
#     credit the RNG, for example if you plan to replicate this file
#     system image and do not have the wherewithal to first delete the
#     contents of /var/lib/seedrng.
#
# Example:
# SEEDRNG_ARGS="--seed-dir=/data/seedrng --skip-credit"
#

DAEMON="seedrng"
SEEDRNG_ARGS=""

# shellcheck source=/dev/null
[ -r "/etc/default/$DAEMON" ] && . "/etc/default/$DAEMON"

case "$1" in
	start|stop|restart|reload)
		# Never fail, as this isn't worth making a fuss
		# over if it doesn't go as planned.
		# shellcheck disable=SC2086 # we need the word splitting
		seedrng $SEEDRNG_ARGS || true;;
	*)
		echo "Usage: $0 {start|stop|restart|reload}"
		exit 1
esac
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S01seedrng

cat >$ROOTFS_DIR/etc/init.d/S01syslogd <<'EOF'
#!/bin/sh

DAEMON="syslogd"
PIDFILE="/var/run/$DAEMON.pid"

SYSLOGD_ARGS=""

# shellcheck source=/dev/null
[ -r "/etc/default/$DAEMON" ] && . "/etc/default/$DAEMON"

# BusyBox' syslogd does not create a pidfile, so pass "-n" in the command line
# and use "--make-pidfile" to instruct start-stop-daemon to create one.
start() {
	printf 'Starting %s: ' "$DAEMON"
	# shellcheck disable=SC2086 # we need the word splitting
	start-stop-daemon --start --background --make-pidfile \
		--pidfile "$PIDFILE" --exec "/sbin/$DAEMON" \
		-- -n $SYSLOGD_ARGS
	status=$?
	if [ "$status" -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
	fi
	return "$status"
}

stop() {
	printf 'Stopping %s: ' "$DAEMON"
	start-stop-daemon --stop --pidfile "$PIDFILE" --exec "/sbin/$DAEMON"
	status=$?
	if [ "$status" -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
		return "$status"
	fi
	while start-stop-daemon --stop --test --quiet --pidfile "$PIDFILE" \
		--exec "/sbin/$DAEMON"; do
		sleep 0.1
	done
	rm -f "$PIDFILE"
	return "$status"
}

restart() {
	stop
	start
}

case "$1" in
	start|stop|restart)
		"$1";;
	reload)
		# Restart, since there is no true "reload" feature.
		restart;;
	*)
		echo "Usage: $0 {start|stop|restart|reload}"
		exit 1
esac
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S01syslogd

cat >$ROOTFS_DIR/etc/init.d/S02klogd <<'EOF'
#!/bin/sh

DAEMON="klogd"
PIDFILE="/var/run/$DAEMON.pid"

KLOGD_ARGS=""

# shellcheck source=/dev/null
[ -r "/etc/default/$DAEMON" ] && . "/etc/default/$DAEMON"

# BusyBox' klogd does not create a pidfile, so pass "-n" in the command line
# and use "-m" to instruct start-stop-daemon to create one.
start() {
	printf 'Starting %s: ' "$DAEMON"
	# shellcheck disable=SC2086 # we need the word splitting
	start-stop-daemon --start --background --make-pidfile \
		--pidfile "$PIDFILE" --exec "/sbin/$DAEMON" \
		-- -n $KLOGD_ARGS
	status=$?
	if [ "$status" -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
	fi
	return "$status"
}

stop() {
	printf 'Stopping %s: ' "$DAEMON"
	start-stop-daemon --stop --pidfile "$PIDFILE" --exec "/sbin/$DAEMON"
	status=$?
	if [ "$status" -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
		return "$status"
	fi
	while start-stop-daemon --stop --test --quiet --pidfile "$PIDFILE" \
		--exec "/sbin/$DAEMON"; do
		sleep 0.1
	done
	rm -f "$PIDFILE"
	return "$status"
}

restart() {
	stop
	start
}

case "$1" in
	start|stop|restart)
		"$1";;
	reload)
		# Restart, since there is no true "reload" feature.
		restart;;
	*)
		echo "Usage: $0 {start|stop|restart|reload}"
		exit 1
esac
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S02klogd

cat >$ROOTFS_DIR/etc/init.d/S02sysctl <<'EOF'
#!/bin/sh
#
# This script is used by busybox and procps-ng.
#
# With procps-ng, the "--system" option of sysctl also enables "--ignore", so
# errors are not reported via syslog. Use the run_logger function to mimic the
# --system behavior, still reporting errors via syslog. Users not interested
# on error reports can add "-e" to SYSCTL_ARGS.
#
# busybox does not have a "--system" option neither reports errors via syslog,
# so the scripting provides a consistent behavior between the implementations.
# Testing the busybox sysctl exit code is fruitless, as at the moment, since
# its exit status is zero even if errors happen. Hopefully this will be fixed
# in a future busybox version.

PROGRAM="sysctl"

SYSCTL_ARGS=""

# shellcheck source=/dev/null
[ -r "/etc/default/$PROGRAM" ] && . "/etc/default/$PROGRAM"

# Files are read from directories in the SYSCTL_SOURCES list, in the given
# order. A file may be used more than once, since there can be multiple
# symlinks to it. No attempt is made to prevent this.
SYSCTL_SOURCES="/etc/sysctl.d/ /usr/local/lib/sysctl.d/ /usr/lib/sysctl.d/ /lib/sysctl.d/ /etc/sysctl.conf"

# If the logger utility is available all messages are sent to syslog, except
# for the final status. The file redirections do the following:
#
# - stdout is redirected to syslog with facility.level "kern.info"
# - stderr is redirected to syslog with facility.level "kern.err"
# - file dscriptor 4 is used to pass the result to the "start" function.
#
run_logger() {
	# shellcheck disable=SC2086 # we need the word splitting
	find $SYSCTL_SOURCES -maxdepth 1 -name '*.conf' -print0 2> /dev/null | \
	xargs -0 -r -n 1 readlink -f | {
		prog_status="OK"
		while :; do
			read -r file || {
				echo "$prog_status" >&4
				break
			}
			echo "* Applying $file ..."
			/sbin/sysctl $SYSCTL_ARGS -p "$file" || prog_status="FAIL"
		done 2>&1 >&3 | /usr/bin/logger -t sysctl -p kern.err
	} 3>&1 | /usr/bin/logger -t sysctl -p kern.info
}

# If logger is not available all messages are sent to stdout/stderr.
run_std() {
	# shellcheck disable=SC2086 # we need the word splitting
	find $SYSCTL_SOURCES -maxdepth 1 -name '*.conf' -print0 2> /dev/null | \
	xargs -0 -r -n 1 readlink -f | {
		prog_status="OK"
		while :; do
			read -r file || {
				echo "$prog_status" >&4
				break
			}
			echo "* Applying $file ..."
			/sbin/sysctl $SYSCTL_ARGS -p "$file" || prog_status="FAIL"
		done
	}
}

if [ -x /usr/bin/logger ]; then
	run_program="run_logger"
else
	run_program="run_std"
fi

start() {
	printf '%s %s: ' "$1" "$PROGRAM"
	status=$("$run_program" 4>&1)
	echo "$status"
	if [ "$status" = "OK" ]; then
		return 0
	fi
	return 1
}

case "$1" in
	start)
		start "Running";;
	restart|reload)
		start "Rerunning";;
	stop)
		:;;
	*)
		echo "Usage: $0 {start|stop|restart|reload}"
		exit 1
esac
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S02sysctl

cat >$ROOTFS_DIR/etc/init.d/S11modules <<'EOF'
#!/bin/sh

MODULES_DIR="/etc/modules-load.d/"

[ -z "$(ls -A ${MODULES_DIR} 2> /dev/null)" ] && exit 0

load_unload() {
	for module_file in "${MODULES_DIR}"/*.conf; do
		while read -r module args; do

			case "$module" in
				""|"#"*) continue ;;
			esac

			if [ "$1" = "load" ]; then
				# shellcheck disable=SC2086  # We need word splitting for args
				modprobe -q "${module}" ${args} >/dev/null && \
					printf '%s ' "$module" || RET='FAIL'
			else
				rmmod "${module}" >/dev/null
			fi

		done < "${module_file}"
	done

	RET='OK'
}

start() {
	printf 'Starting modules: '

	load_unload load

	echo $RET
}

stop() {
	printf 'Stopping modules: '

	load_unload unload

	echo $RET
}

restart() {
	stop
	sleep 1
	start
}

case "$1" in
	start|stop|restart)
		"$1";;
	reload)
		# Restart, since there is no true "reload" feature.
		restart;;
	*)
		echo "Usage: $0 {start|stop|restart|reload}"
		exit 1
esac

# check-package Ignore missing DAEMON Variables
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S11modules

cat >$ROOTFS_DIR/etc/init.d/S40network <<'EOF'
#!/bin/sh
#
# Start the network....
#

# Debian ifupdown needs the /run/network lock directory
mkdir -p /run/network

case "$1" in
  start)
	printf "Starting network: "
	/sbin/ifup -a
	[ $? = 0 ] && echo "OK" || echo "FAIL"
	;;
  stop)
	printf "Stopping network: "
	/sbin/ifdown -a
	[ $? = 0 ] && echo "OK" || echo "FAIL"
	;;
  restart|reload)
	"$0" stop
	"$0" start
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?

EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S40network

cat >$ROOTFS_DIR/etc/init.d/S50crond <<'EOF'
#!/bin/sh

DAEMON="crond"
PIDFILE="/var/run/$DAEMON.pid"

CROND_ARGS=""

# shellcheck source=/dev/null
[ -r "/etc/default/$DAEMON" ] && . "/etc/default/$DAEMON"

# BusyBox' crond does not create a pidfile, so pass "-f" on the crond
# command line and use "--make-pidfile" to instruct start-stop-daemon
# to create one.
start() {
	printf 'Starting %s: ' "$DAEMON"
	# shellcheck disable=SC2086 # we need the word splitting
	start-stop-daemon --start --background --make-pidfile \
		--pidfile "$PIDFILE" --exec "/usr/sbin/$DAEMON" \
		-- -f $CROND_ARGS
	status=$?
	if [ "$status" -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
	fi
	return "$status"
}

stop() {
	printf 'Stopping %s: ' "$DAEMON"
	start-stop-daemon --stop --pidfile "$PIDFILE" --exec "/usr/sbin/$DAEMON"
	status=$?
	if [ "$status" -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
	fi
	while start-stop-daemon --stop --test --quiet --pidfile "$PIDFILE" \
		--exec "/usr/sbin/$DAEMON"; do
		sleep 0.1
	done
	rm -f "$PIDFILE"
	return "$status"
}

restart() {
	stop
	start
}

case "$1" in
	start|stop|restart)
		"$1";;
	reload)
		# Restart, since there is no true "reload" feature.
		restart;;
	*)
		echo "Usage: $0 {start|stop|restart|reload}"
		exit 1
esac
EOF
chmod 0755 $ROOTFS_DIR/etc/init.d/S50crond

cat >$ROOTFS_DIR/etc/network/interfaces <<EOF
# interface file auto-generated by buildroot

auto lo
iface lo inet loopback

auto $DHCP_IFACE
iface $DHCP_IFACE inet dhcp
  hwaddress ether 00:0E:3A:24:10:01
  pre-up /etc/network/nfs_check
  wait-delay 15
  hostname $HOSTNAME
EOF

cat >$ROOTFS_DIR/etc/network/nfs_check <<'EOF'
#!/bin/sh

# This allows NFS booting to work while also being able to configure
# the network interface via DHCP when not NFS booting.  Otherwise, a
# NFS booted system will likely hang during DHCP configuration.

# Attempting to configure the network interface used for NFS will
# initially bring that network down.  Since the root filesystem is
# accessed over this network, the system hangs.

# This script is run by ifup and will attempt to detect if a NFS root
# mount uses the interface to be configured (IFACE), and if so does
# not configure it.  This should allow the same build to be disk/flash
# booted or NFS booted.

nfsip=`sed -n '/^[^ ]*:.* \/ nfs.*[ ,]addr=\([0-9.]\+\).*/s//\1/p' /proc/mounts`
if [ -n "$nfsip" ] && ip route get to "$nfsip" | grep -q "dev $IFACE"; then
	echo Skipping $IFACE, used for NFS from $nfsip
	exit 1
fi
EOF
chmod 0755 $ROOTFS_DIR/etc/network/nfs_check

cat >$ROOTFS_DIR/etc/network/if-pre-up.d/wait_iface <<'EOF'
#!/bin/sh

# In case we have a slow-to-appear interface (e.g. eth-over-USB),
# and we need to configure it, wait until it appears, but not too
# long either. IF_WAIT_DELAY is in seconds.

if [ "${IF_WAIT_DELAY}" -a ! -e "/sys/class/net/${IFACE}" ]; then
    printf "Waiting for interface %s to appear" "${IFACE}"
    while [ ${IF_WAIT_DELAY} -gt 0 ]; do
        if [ -e "/sys/class/net/${IFACE}" ]; then
            printf "\n"
            exit 0
        fi
        sleep 1
        printf "."
        : $((IF_WAIT_DELAY -= 1))
    done
    printf " timeout!\n"
    exit 1
fi
EOF
chmod 0755 $ROOTFS_DIR/etc/network/if-pre-up.d/wait_iface

cat >$ROOTFS_DIR/etc/profile.d/umask.sh <<'EOF'
umask 022
EOF

cat >$ROOTFS_DIR/usr/share/udhcpc/default.script <<'EOF'
#!/bin/sh

# udhcpc script edited by Tim Riker <Tim@Rikers.org>

[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1

ACTION="$1"
RESOLV_CONF="/etc/resolv.conf"
[ -e $RESOLV_CONF ] || touch $RESOLV_CONF
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"
# Handle stateful DHCPv6 like DHCPv4
[ -n "$ipv6" ] && ip="$ipv6/128"

if [ -z "${IF_WAIT_DELAY}" ]; then
	IF_WAIT_DELAY=10
fi

wait_for_ipv6_default_route() {
	printf "Waiting for IPv6 default route to appear"
	while [ $IF_WAIT_DELAY -gt 0 ]; do
		if ip -6 route list | grep -q default; then
			printf "\n"
			return
		fi
		sleep 1
		printf "."
		: $((IF_WAIT_DELAY -= 1))
	done
	printf " timeout!\n"
}

case "$ACTION" in
	deconfig)
		/sbin/ifconfig $interface up
		/sbin/ifconfig $interface 0.0.0.0

		# drop info from this interface
		# resolv.conf may be a symlink to /tmp/, so take care
		TMPFILE=$(mktemp)
		grep -vE "# $interface\$" $RESOLV_CONF > $TMPFILE
		cat $TMPFILE > $RESOLV_CONF
		rm -f $TMPFILE

		if [ -x /usr/sbin/avahi-autoipd ]; then
			/usr/sbin/avahi-autoipd -c $interface && /usr/sbin/avahi-autoipd -k $interface
		fi
		;;

	leasefail|nak)
		if [ -x /usr/sbin/avahi-autoipd ]; then
			/usr/sbin/avahi-autoipd -c $interface || /usr/sbin/avahi-autoipd -wD $interface --no-chroot
		fi
		;;

	renew|bound)
		if [ -x /usr/sbin/avahi-autoipd ]; then
			/usr/sbin/avahi-autoipd -c $interface && /usr/sbin/avahi-autoipd -k $interface
		fi
		/sbin/ifconfig $interface $ip $BROADCAST $NETMASK
		if [ -n "$ipv6" ] ; then
			wait_for_ipv6_default_route
		fi

		# RFC3442: If the DHCP server returns both a Classless
		# Static Routes option and a Router option, the DHCP
		# client MUST ignore the Router option.
		if [ -n "$staticroutes" ]; then
			echo "deleting routers"
			route -n | while read dest gw mask flags metric ref use iface; do
				[ "$iface" != "$interface" -o "$gw" = "0.0.0.0" ] || \
					route del -net "$dest" netmask "$mask" gw "$gw" dev "$interface"
			done

			# format: dest1/mask gw1 ... destn/mask gwn
			set -- $staticroutes
			while [ -n "$1" -a -n "$2" ]; do
				route add -net "$1" gw "$2" dev "$interface"
				shift 2
			done
		elif [ -n "$router" ] ; then
			echo "deleting routers"
			while route del default gw 0.0.0.0 dev $interface 2> /dev/null; do
				:
			done

			for i in $router ; do
				route add default gw $i dev $interface
			done
		fi

		# drop info from this interface
		# resolv.conf may be a symlink to /tmp/, so take care
		TMPFILE=$(mktemp)
		grep -vE "# $interface\$" $RESOLV_CONF > $TMPFILE
		cat $TMPFILE > $RESOLV_CONF
		rm -f $TMPFILE

		# prefer rfc3397 domain search list (option 119) if available
		if [ -n "$search" ]; then
			search_list=$search
		elif [ -n "$domain" ]; then
			search_list=$domain
		fi

		[ -n "$search_list" ] &&
			echo "search $search_list # $interface" >> $RESOLV_CONF

		for i in $dns ; do
			echo adding dns $i
			echo "nameserver $i # $interface" >> $RESOLV_CONF
		done
		;;
esac

HOOK_DIR="$0.d"
for hook in "${HOOK_DIR}/"*; do
    [ -f "${hook}" -a -x "${hook}" ] || continue
    "${hook}" "$ACTION"
done

exit 0
EOF
chmod 0755 $ROOTFS_DIR/usr/share/udhcpc/default.script

ARCH=arm CROSS_COMPILE=$PWD/$TOOLCHAIN/bin/$TOOLCHAIN- make -C ./$LINUX_DIR modules_install INSTALL_MOD_PATH=../rootfs
rm -f $ROOTFS_DIR/lib/modules/*/build
rm -f $ROOTFS_DIR/lib/modules/*/source

LIBS="
ld*.so.*
libgcc_s.so.*
libatomic.so.*
libc.so.*
libdl.so.*
libm.so.*
libnsl.so.*
libresolv.so.*
librt.so.*
libutil.so.*
libpthread.so.*
libnss_files.so.*
libnss_dns.so.*
libmvec.so.*
libanl.so.*
libcrypt.so.1
libstdc++.so.*
"
for pattern in $LIBS; do
    for file in "$SYSROOT_DIR"/lib/$pattern; do
        [ -e "$file" ] || continue
        cp -a "$file" "$ROOTFS_DIR/lib/"
    done
done

ARCH=arm CROSS_COMPILE=$PWD/$TOOLCHAIN/bin/$TOOLCHAIN- make -C ./$BUSYBOX_DIR install CONFIG_PREFIX=../rootfs
chmod 4755 $ROOTFS_DIR/bin/busybox

# 1. Strip shared libraries (.so files)
find $ROOTFS_DIR/lib $ROOTFS_DIR/usr/lib -type f -name '*.so*' 2>/dev/null | while read -r lib; do
    if [ ! -L $lib ]; then
        $PWD/$TOOLCHAIN/bin/$TOOLCHAIN-strip --strip-unneeded $lib 2>/dev/null || true
    fi
done

# 2. Strip executables in bin and sbin directories
find $ROOTFS_DIR/bin $ROOTFS_DIR/sbin $ROOTFS_DIR/usr/bin ${ROOTFS_DIR}/usr/sbin -type f 2>/dev/null | while read -r bin; do
    if [ ! -L $bin ]; then
        $PWD/$TOOLCHAIN/bin/$TOOLCHAIN-strip --strip-all $bin 2>/dev/null || true
    fi
done

mkfs.ubifs -d $ROOTFS_DIR -e $UBIFS_LEBSIZE -c $UBIFS_MAXLEBCNT -m $UBIFS_MINIOSIZE -x lzo -o rootfs.ubifs
ubinize -o rootfs.ubi -m $UBIFS_MINIOSIZE -p $UBI_PEBSIZE -s $UBI_SUBSIZE ./ubinize.cfg

exit

# SYSTEM_RSYNC
rsync -a --ignore-times \
    --exclude .svn --exclude .git --exclude .hg --exclude .bzr --exclude CVS \
	--chmod=u=rwX,go=rX --exclude .empty --exclude '*~' \
	$BUILDROOT_DIR/system/skeleton/ $ROOTFS_DIR/

# GLIBC_INSTALL_TARGET_CMDS
cp -d $SYSROOT_DIR/lib/*.so* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/ld*.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libgcc_s.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libatomic.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libc.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libdl.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libm.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libnsl.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libresolv.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/librt.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libutil.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libpthread.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libnss_files.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libnss_dns.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libanl.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libmvec.so.* $ROOTFS_DIR/lib/
#cp -d $SYSROOT_DIR/lib/libstdc++.so.* $ROOTFS_DIR/lib/

