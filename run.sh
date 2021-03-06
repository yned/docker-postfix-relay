#!/bin/sh

chown root: /var/spool/postfix /var/spool/postfix/pid

# Disable SMTPUTF8, because libraries (ICU) are missing in alpine
postconf -e smtputf8_enable=no

# Update aliases database. It's not used, but postfix complains if the .db file is missing
postalias /etc/postfix/aliases

# Disable local mail delivery
postconf -e mydestination=
# Don't relay for any domains
postconf -e relay_domains=

# Reject invalid HELOs
postconf -e smtpd_delay_reject=yes
postconf -e smtpd_helo_required=yes
postconf -e "smtpd_helo_restrictions=permit_mynetworks,reject_invalid_helo_hostname,permit"

# Set up host name
if [ ! -z "$HOSTNAME" ]; then
	postconf -e myhostname="$HOSTNAME"
else
	postconf -# myhostname
fi

postconf -e "mynetworks=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Split with space
if [ ! -z "$ALLOWED_SENDER_DOMAINS" ]; then
	echo "Setting up allowed SENDER domains:"
	allowed_senders=/etc/postfix/allowed_senders
	rm -f $allowed_senders $allowed_senders.db
	touch $allowed_senders
	for i in $ALLOWED_SENDER_DOMAINS; do
		echo -e "\t$i"
		echo -e "$i\tOK" >> $allowed_senders
	done
	postmap $allowed_senders

	postconf -e "smtpd_restriction_classes=allowed_domains_only"
	postconf -e "allowed_domains_only=permit_mynetworks, reject_non_fqdn_sender reject"
	postconf -e "smtpd_recipient_restrictions=reject_non_fqdn_recipient, reject_unknown_recipient_domain, reject_unverified_recipient, check_sender_access hash:$allowed_senders, reject"
else
	postconf -# "smtpd_restriction_classes"
	postconf -e "smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,reject_unverified_recipient"
fi

# Set up a relay host, if needed
if [ ! -z "$SMTP_SERVER" ]; then
    postconf -e "relayhost = [$SMTP_SERVER]:587"
else
	postconf -# relayhost
fi

postconf -e "message_size_limit=0"

postconf -e "smtp_use_tls=yes"
if [ -n "$SMTP_USERNAME" ] && [ -n "$SMTP_PASSWORD" ]; then
    postconf -e "smtp_sasl_auth_enable = yes"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_sasl_security_options = noanonymous"
    echo "[$SMTP_SERVER]:587 $SMTP_USERNAME:$SMTP_PASSWORD" >> /etc/postfix/sasl_passwd
    postmap hash:/etc/postfix/sasl_passwd
    #postconf -e "smtp_generic_maps = hash:/etc/postfix/generic"
    #echo "/.*/    $SMTP_USERNAME" >> /etc/postfix/generic
    #postmap hash:/etc/postfix/generic
fi


# Use 587 (submission)
sed -i -r -e 's/^#submission/submission/' /etc/postfix/master.cf

exec supervisord -c /etc/supervisord.conf
