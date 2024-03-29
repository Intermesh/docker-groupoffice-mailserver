#Enable IMAP
protocols = imap lmtp sieve

#Listen on all IP addresses
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

mail_plugins = quota acl

postmaster_address = {postmaster}

auth_mechanisms = plain login

#FOR DEVELOPMENT ONLY:
disable_plaintext_auth = no
!include auth-sql.conf.ext

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
  postmaster_address = {postmaster}   # required
  mail_plugins = quota sieve  
  # Enable fsyncing for LMTP
  mail_fsync = optimized
}

namespace inbox {
  type = private
  separator = /
  prefix =
  #location defaults to mail_location.
  inbox = yes


  #mailbox name {
    # auto=create will automatically create this mailbox.
    # auto=subscribe will both create and subscribe to the mailbox.
    #auto = no

    # Space separated list of IMAP SPECIAL-USE attributes as specified by
    # RFC 6154: \All \Archive \Drafts \Flagged \Junk \Sent \Trash
    #special_use =
  #}

  # These mailboxes are widely used and could perhaps be created automatically:
  mailbox Drafts {
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }
  mailbox Trash {
    special_use = \Trash
  }

  # For \Sent mailboxes there are two widely used names. We'll mark both of
  # them as \Sent. User typically deletes one of them if duplicates are created.
  mailbox Sent {
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }

  # If you have a virtual "All messages" mailbox:
  #mailbox virtual/All {
  #  special_use = \All
  #}

  # If you have a virtual "Flagged" mailbox:
  #mailbox virtual/Flagged {
  #  special_use = \Flagged
  #}
}  


namespace {
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
  #service_count = 1

  # Number of processes to always keep waiting for more connections.
  #process_min_avail = 0

  # If you set service_count=0, you probably need to grow this.
  #vsz_limit = 64M
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

  # Auth process is run as this user.
  #user = $default_internal_user
}

service auth-worker {
  # Auth worker process is run as root by default, so that it can access
  # /etc/shadow. If this isn't necessary, the user should be changed to
  # $default_internal_user.
  #user = root
}

service dict {
  # If dict proxy is used, mail processes should have access to its socket.
  # For example: mode=0660, group=vmail and global mail_access_groups=vmail
  unix_listener dict {
    #mode = 0600
    #user = 
    #group = 
  }
}



plugin {
  #quota = dirsize:User quota
  quota = maildir:User quota
  #quota = dict:User quota::proxy::quota
  #quota = fs:User quota
	
  acl = vfile
  acl_shared_dict = file:/var/lib/dovecot/db/shared-mailboxes.db

  fts=solr
  fts_solr = url=http://localhost/8983/solr/dovecot/
}