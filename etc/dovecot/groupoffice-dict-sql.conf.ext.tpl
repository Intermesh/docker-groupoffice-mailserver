connect = "host={dbHost} dbname={dbName} user={dbUser} password={dbPass}"

map {
    pattern = priv/quota/storage
    table = community_maildomains_mailbox
    username_field = username
    value_field = bytes
}

map {
    pattern = priv/quota/messages
    table = community_maildomains_mailbox
    username_field = username
    value_field = messages
}