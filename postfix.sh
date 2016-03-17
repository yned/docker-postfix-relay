#!/bin/bash

if [[ ! -z "$HOSTNAME" ]]; then
	postconf -e myhostname=$HOSTNAME
else
	postconf -# myhostname
fi

if [[ ! -z "$RELAYHOST" ]]; then
	postconf -e relayhost=$RELAYHOST
else
	postconf -# relayhost
fi

/usr/sbin/postfix -c /etc/postfix start
