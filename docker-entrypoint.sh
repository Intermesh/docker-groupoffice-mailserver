#!/bin/sh
set -e

cp /etc/dovecot/dovecot-sql.conf.ext.tpl /etc/dovecot/dovecot-sql.conf.ext
sed -i 's/{dbHost}/'$MYSQL_HOST'/' /etc/dovecot/dovecot-sql.conf.ext && \
sed -i 's/{dbName}/'$MYSQL_DATABASE'/' /etc/dovecot/dovecot-sql.conf.ext && \
sed -i 's/{dbUser}/'$MYSQL_USER'/' /etc/dovecot/dovecot-sql.conf.ext && \
sed -i 's/{dbPass}/'$MYSQL_PASSWORD'/' /etc/dovecot/dovecot-sql.conf.ext

cp /etc/dovecot/conf.d/99-groupoffice.conf.tpl /etc/dovecot/conf.d/99-groupoffice.conf
sed -i 's/{postmaster}/'$POSTMASTER_EMAIL'/' /etc/dovecot/conf.d/99-groupoffice.conf

echo "user = ${MYSQL_USER}\n\
password = ${MYSQL_PASSWORD}\n\
hosts = ${MYSQL_HOST}\n\
dbname = ${MYSQL_DATABASE}\n\
table = pa_aliases\n\
select_field = goto\n\
where_field = address\n\
additional_conditions = and active = '1'" > /etc/postfix/mysql_virtual_alias_maps.cf && \

echo "user = ${MYSQL_USER}\n\
password = ${MYSQL_PASSWORD}\n\
hosts = ${MYSQL_HOST}\n\
dbname = ${MYSQL_DATABASE}\n\
table = pa_domains\n\
select_field = domain\n\
where_field = domain\n\
additional_conditions = and backupmx = '0' and active = '1'" > /etc/postfix/mysql_virtual_mailbox_domains.cf && \

echo "user = ${MYSQL_USER}\n\
password = ${MYSQL_PASSWORD}\n\
hosts = ${MYSQL_HOST}\n\
dbname = ${MYSQL_DATABASE}\n\
table = pa_mailboxes\n\
select_field = maildir\n\
where_field = username\n\
additional_conditions = and active = '1'" > /etc/postfix/mysql_virtual_mailbox_maps.cf

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
