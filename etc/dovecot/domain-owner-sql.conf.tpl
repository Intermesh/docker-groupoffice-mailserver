driver = mysql
connect = "host={dbHost} dbname={dbName} user={dbUser} password={dbPass}"
default_pass_scheme = CRYPT

password_query = SELECT \
    username AS user, \
    password \
    FROM community_maildomains_mailbox \
    WHERE username = '%u' AND active = '1' AND domainOwner = true AND '%d'='%{login_domain}'
