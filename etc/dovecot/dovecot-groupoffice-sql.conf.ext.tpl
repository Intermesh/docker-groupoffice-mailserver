driver = mysql
connect = "host={dbHost} dbname={dbName} user={dbUser} password={dbPass}"
default_pass_scheme = CRYPT

user_query = SELECT \
    CONCAT('/var/mail/vhosts/',homedir) AS home, \
    CONCAT('maildir:/var/mail/vhosts/',maildir) AS mail, \
    150 AS uid, 8 AS gid, \
    CONCAT('*:storage=', quota) AS quota_rule, \
    IF(fts, 'xapian', null) as fts, \
    IF(fts, '+XFTS', '') as imap_capability, \
    'Trash Spam' as 'namespace/inbox/mailbox', \
    autoExpunge as 'namespace/inbox/mailbox/Trash/autoexpunge', \
    autoExpunge as 'namespace/inbox/mailbox/Spam/autoexpunge' \
    FROM community_maildomains_mailbox \
    WHERE username = '%u' AND active = '1'

password_query = SELECT \
    username AS user, \
    password, \
    CONCAT('/var/mail/vhosts/',homedir) AS userdb_home, \
    CONCAT('maildir:/var/mail/vhosts/', maildir) AS userdb_mail, \
    150 AS userdb_uid, 8 AS userdb_gid, \
    IF(fts, "xapian", null) as userdb_fts, \
    IF(fts, "+XFTS", "") as userdb_imap_capability, \
    'Trash Spam' as 'namespace/inbox/mailbox', \
    autoExpunge as 'namespace/inbox/mailbox/Trash/autoexpunge', \
    autoExpunge as 'namespace/inbox/mailbox/Spam/autoexpunge' \
    FROM community_maildomains_mailbox \
    WHERE username = '%u' AND active = '1' AND ('%Ls' != 'smtp' OR smtpAllowed=1)

# For using doveadm -A:
iterate_query = SELECT username AS user FROM community_maildomains_mailbox

# Use queries below instead of the above to put index files in /var/indexes/%u
# This can be useful if you want the indexes on a faster SSD partition
# mkdir /var/indexes
# chown vmail:mail /var/indexes
#
# User dirs are created automatically.
#
# user_query = SELECT \
#    CONCAT('/var/mail/vhosts/',homedir) AS home, \
#    CONCAT('maildir:/var/mail/vhosts/',maildir, ':INDEX=/var/indexes/%u:ITERINDEX') AS mail, \
#    150 AS uid, 8 AS gid, \
#    CONCAT('*:storage=', quota) AS quota_rule, \
#    IF(fts, 'xapian', null) as fts, \
#    IF(fts, '+XFTS', '') as imap_capability, \
#    'Trash Spam' as 'namespace/inbox/mailbox', \
#    autoExpunge as 'namespace/inbox/mailbox/Trash/autoexpunge', \
#    autoExpunge as 'namespace/inbox/mailbox/Spam/autoexpunge' \
#    FROM community_maildomains_mailbox \
#    WHERE username = '%u' AND active = '1'
#
# password_query = SELECT \
#    username AS user, \
#    password, \
#    CONCAT('/var/mail/vhosts/',homedir) AS userdb_home, \
#    CONCAT('maildir:/var/mail/vhosts/', maildir, ':INDEX=/var/indexes/%u:ITERINDEX') AS userdb_mail, \
#    150 AS userdb_uid, 8 AS userdb_gid, \
#    IF(fts, "xapian", null) as userdb_fts, \
#    IF(fts, "+XFTS", "") as userdb_imap_capability, \
#    'Trash Spam' as 'namespace/inbox/mailbox', \
#    autoExpunge as 'namespace/inbox/mailbox/Trash/autoexpunge', \
#    autoExpunge as 'namespace/inbox/mailbox/Spam/autoexpunge' \
#    FROM community_maildomains_mailbox \
#    WHERE username = '%u' AND active = '1' AND ('%Ls' != 'smtp' OR smtpAllowed=1)

