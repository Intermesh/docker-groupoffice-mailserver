# https://www.mybluelinux.com/configure-opendkim-with-postfix-on-debian/

# apt-get install opendkim libopendbx1-mysql


# for accessing socket local:/run/opendkim/opendkim.sock
# usermod -a -G opendkim postfix

# run dir must exist
# mkdir /var/spool/postfix/opendkim
# chown opendkim:opendkim /var/spool/postfix/opendkim

# /etc/postfix/main.cf (postfix runs in chroot jail /var/spool/postfix/)
# smtpd_milters = unix:opendkim/opendkim.sock


# This is a basic configuration for signing and verifying. It can easily be
# adapted to suit a basic installation. See opendkim.conf(5) and
# /usr/share/doc/opendkim/examples/opendkim.conf.sample for complete
# documentation of available configuration parameters.

Syslog			yes
SyslogSuccess		yes
#LogWhy			no

# Common signing and verification parameters. In Debian, the "From" header is
# oversigned, because it is often the identity key used by reputation systems
# and thus somewhat security sensitive.
Canonicalization	relaxed/simple

# Sign only as rspamd does the verifying
Mode			s

#SubDomains		no
OversignHeaders		From

# Signing domain, selector, and key (required). For example, perform signing
# for domain "example.com" with selector "2020" (2020._domainkey.example.com),
# using the private key stored in /etc/dkimkeys/example.private. More granular
# setup options can be found in /usr/share/doc/opendkim/README.opendkim.
#Domain			example.com
#Selector		2020
#KeyFile		/etc/dkimkeys/example.private

# In Debian, opendkim runs as user "opendkim". A umask of 007 is required when
# using a local socket with MTAs that access the socket as a non-privileged
# user (for example, Postfix). You may need to add user "postfix" to group
# "opendkim" in that case.
UserID			opendkim
UMask			007

# Socket for the MTA connection (required). If the MTA is inside a chroot jail,
# it must be ensured that the socket is accessible. In Debian, Postfix runs in
# a chroot in /var/spool/postfix, therefore a Unix socket would have to be
# configured as shown on the last line below.

# /etc/postfix/main.cf
# smtpd_milters = unix:/var/spool/postfix/opendkim/opendkim.sock

#Socket			local:/run/opendkim/opendkim.sock
#Socket			inet:8891@localhost
#Socket			inet:8891
Socket			local:/var/spool/postfix/opendkim/opendkim.sock

PidFile			/run/opendkim/opendkim.pid

# Hosts for which to sign rather than verify, default is 127.0.0.1. See the
# OPERATION section of opendkim(8) for more information.
#InternalHosts		192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12

# The trust anchor enables DNSSEC. In Debian, the trust anchor file is provided
# by the package dns-root-data.
TrustAnchorFile		/usr/share/dns/root.key
#Nameservers		127.0.0.1

# https://github.com/trusteddomainproject/OpenDKIM/blob/master/opendkim/README.SQL
SigningTable dsn:mysql://{dbUser}:{dbPass}@{dbHost}/{dbName}/table=community_maildomains_dkim?keycol=domain?datacol=id
KeyTable     dsn:mysql://{dbUser}:{dbPass}@{dbHost}/{dbName}/table=community_maildomains_dkim?keycol=id?datacol=domain,selector,privateKey