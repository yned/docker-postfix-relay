FROM alpine:edge

# You can set this variables when running the image to override the host name or
# foward the messages to another server
# ENV	HOSTNAME
# Hostname and optional authentication that will be used in the outgoing mail
# ENV	SMTP_SERVER
# ENV	SMTP_USERNAME
# ENV	SMTP_PASSWORD
# The relay host for this server
# ENV	ALLOWED_SENDER_DOMAINS
# Limit the list of sending domains to this list only

RUN	apk add --no-cache --update postfix ca-certificates supervisor && \
	rm -f /tmp/* && rm -rf /var/cache/apk/*

COPY supervisord.conf /etc/supervisord.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME [ "/var/spool/postfix", "/etc/postfix" ]

USER root
WORKDIR	/tmp

EXPOSE 25 587
CMD ["/run.sh"]
