#Enable IMAP
protocols = imap lmtp sieve

default_vsz_limit = 1G

#Enable the line below to enable external access for IMAP
listen = *

#configure the location of our virtual mailboxes
#mail_location = maildir:~/Maildir

# Group to enable temporarily for privileged operations. Currently this is
# used only for creating mbox dotlock files when creation fails for INBOX.
# Typically this is set to "mail" to give access to /var/mail.
#mail_privileged_group =
mail_privileged_group = mail

# Grant access to these supplementary groups for mail processes. Typically
# these are used to set up access to shared mailboxes. Note that it may be
# dangerous to set these if users can create symlinks (e.g. if "mail" group is
# set here, ln -s /var/mail ~/mail/var could allow a user to delete others'
# mailboxes, or ln -s /secret/shared/box ~/mail/mybox would allow reading it).
mail_access_groups = mail

# Valid UID range for users, defaults to 500 and above. This is mostly
# to make sure that users can't log in as daemons or other system users.
# Note that denying root logins is hardcoded to dovecot binary and can't
# be done even if first_valid_uid is set to 0.
first_valid_uid = 150
last_valid_uid = 150
first_valid_gid = 8
last_valid_gid = 8

mail_plugins = quota quota_clone acl fts fts_xapian virtual

postmaster_address = {postmaster}

auth_mechanisms = plain login

#FOR DEVELOPMENT ONLY:
disable_plaintext_auth = no


# For users that can login to all mailboxes of a domain
auth_master_user_separator = *
passdb {
    driver = sql
    args = /etc/dovecot/domain-owner-sql.conf.ext
    master = yes
    result_success = continue
}

passdb {
    driver = sql

    # Path for SQL configuration file, see example-config/dovecot-sql.conf.ext
    args = /etc/dovecot/dovecot-groupoffice-sql.conf.ext
}

# "prefetch" user database means that the passdb already provided the
# needed information and there's no need to do a separate userdb lookup.
# <doc/wiki/UserDatabase.Prefetch.txt>
userdb {
    driver = prefetch
}

# The userdb below is used only by lda.
userdb {
    driver = sql
    args = /etc/dovecot/dovecot-groupoffice-sql.conf.ext
}

# Default to no fsyncing, lmtp and lda use optimized
mail_fsync = never

# Should saving a mail to a nonexistent mailbox automatically create it?
lda_mailbox_autocreate = yes

# Should automatically created mailboxes be also automatically subscribed?
# This is useful when there are sieve rules pointing to non existent folders
# when they have been moved. The folder will reappear instead of staying invisble to the user
lda_mailbox_autosubscribe = yes

protocol lda {
  # Space separated list of plugins to load (default is global mail_plugins).
  mail_plugins = $mail_plugins quota sieve
# Enable fsyncing for LDA
  mail_fsync = optimized
}

protocol imap {
  mail_plugins = $mail_plugins imap_quota imap_acl
}

protocol lmtp {
  mail_plugins = $mail_plugins quota sieve
  # Enable fsyncing for LMTP
  mail_fsync = optimized
}

namespace inbox {
  type = private
  separator = /
  prefix =
  #location defaults to mail_location.
  inbox = yes

  # These mailboxes are widely used and could perhaps be created automatically:
  mailbox Drafts {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }

  mailbox Spam {
    auto = subscribe
    special_use = \Junk

    # Enable autoexpunge below to cleanup the Spam folder automatically
    # autoexpunge = 30d
  }

  mailbox Trash {
    auto = subscribe
    special_use = \Trash
    # Enable autoexpunge below to cleanup the Trash folder automatically
    # autoexpunge = 30d
  }

  # For \Sent mailboxes there are two widely used names. We'll mark both of
  # them as \Sent. User typically deletes one of them if duplicates are created.
  mailbox Sent {
    auto = subscribe
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }

  # If you have a virtual "All messages" mailbox:
  mailbox virtual/All {
    special_use = \All
  }
}

namespace shared {
	type = shared
	separator = /
	prefix = shared/%%u/
	# a) Per-user seen flags. Maildir indexes are shared. (INDEXPVT requires v2.2+)
	location = maildir:%%h/Maildir:INDEXPVT=~/Maildir/shared/%%u
	# b) Per-user seen flags. Maildir indexes are not shared. If users have direct filesystem level access to their mails, this is a safer option:
	#location = maildir:%%h/Maildir:INDEX=~/Maildir/shared/%%u:INDEXPVT=~/Maildir/shared/%%u
	subscriptions = no
	list = children
}


namespace virtual {
	prefix = virtual/
    separator = /
    hidden = yes
    list = no
    subscriptions = no
    location = virtual:/etc/dovecot/virtual:INDEX=/var/mail/vhosts/%d/%n/virtual
}

service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }

  # Number of connections to handle before starting a new process. Typically
  # the only useful values are 0 (unlimited) or 1. 1 is more secure, but 0
  # is faster. <doc/wiki/LoginProcess.txt>
  service_count = 0

  # Number of processes to always keep waiting for more connections.
  process_min_avail = 4

  # If you set service_count=0, you probably need to grow this.
  vsz_limit = 1G
}

service lmtp {
 unix_listener /var/spool/postfix/private/dovecot-lmtp {
   group = postfix
   mode = 0600
   user = postfix
  }
}

service auth {
  # auth_socket_path points to this userdb socket by default. It's typically
  # used by dovecot-lda, doveadm, possibly imap process, etc. Its default
  # permissions make it readable only by root, but you may need to relax these
  # permissions. Users that have access to this socket are able to get a list
  # of all usernames and get results of everyone's userdb lookups.
  unix_listener auth-userdb {
    mode = 0600
    user = vmail
    group = mail
  }

  # Postfix smtp-auth
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
  }
}

dict {
    mysql = mysql:/etc/dovecot/dovecot-dict-sql.conf.ext
}


plugin {
    quota = count:User quota

    # This is required - it uses "virtual sizes" rather than "physical sizes"
    # for quota counting:
    quota_vsizes = yes
    quota_clone_dict = proxy::mysql

    sieve_default = /var/mail/vhosts/default.sieve
    acl = vfile
    acl_shared_dict = file:/var/lib/dovecot/db/shared-mailboxes.db
    # This makes sure master/domain owner users can access all folders.
    # See https://doc.dovecot.org/configuration_manual/authentication/master_users/
    acl_user=%u

    # fts is returned from the userdb and passdb sql database so it can be turned on per user
    #fts = xapian
    fts_xapian = partial=3 full=20 attachments=0 verbose=0

    fts_enforced = no

    # Proactively index mail as it is delivered or appended, not only when
    # searching.
    fts_autoindex = yes
    fts_autoindex_exclude = \Trash
    fts_autoindex_exclude2 = \Spam

    # How many \Recent flagged mails a mailbox is allowed to have, before it
    # is not autoindexed.
    # This setting can be used to exclude mailboxes that are seldom accessed
    # from automatic indexing.
    fts_autoindex_max_recent_msgs=99

}

# Avoid spending excessive time waiting for the quota calculation to finish
# when mails' vsizes aren't already cached. If this many mails are opened,
# finish the quota calculation on background in indexer-worker process. Mail
# deliveries will be assumed to succeed, and explicit quota lookups will
# return internal error. (v2.2.28+)
protocol !indexer-worker {
  mail_vsize_bg_after_count = 100
}

service indexer-worker {
  #Increase vsz_limit to 2GB or above.
  #Or 0 if you have rather large memory usable on your server, which is preferred for performance)
  vsz_limit = 2G
  process_limit = 0
}

# For better performance: https://doc.dovecot.org/configuration_manual/mail_location/Maildir/#core_setting-maildir_very_dirty_syncs
maildir_very_dirty_syncs = yes

# Mailbox list indexes can be used to optimize IMAP STATUS commands. They are
# also required for IMAP NOTIFY extension to be enabled.
# Recommended to use with the "autoexpunge" setting.
mailbox_list_index = yes

# Trust mailbox list index to be up-to-date. This reduces disk I/O at the cost
# of potentially returning out-of-date results after e.g. server crashes.
# The results will be automatically fixed once the folders are opened.
mailbox_list_index_very_dirty_syncs = yes

# Recommended when using the "autoexpunge" setting with sdbox or Maildir, as it avoids using stat() to find out the mail’s
# saved-timestamp. With mdbox and obox formats this isn’t necessary, since the saved-timestamp is always available.
mail_always_cache_fields = date.save

# Also for performance cache auth
auth_cache_size = 10MB
auth_cache_ttl = 1 hour
auth_cache_negative_ttl = 1 hour