FROM alpine:3.11

RUN sed -i "s@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g" /etc/apk/repositories
RUN apk update && apk add --no-cache bash openssl openssl-dev openldap openldap-clients openldap-back-mdb openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint
RUN mv -vf /etc/openldap/slapd.conf /etc/openldap/slapd.conf.example

ENV LDAP_ORGANIZATION=example \
    LDAP_DOMAIN=example.org \
    LDAP_PASSWORD=admin \
    LDAP_RFC2307BIS_SCHEMA=false \
    LDAP_LOGLEVE=1  \
    LDAPS_ENABLE=false

EXPOSE 389


COPY rfc2307bis.* /etc/openldap/schema/
COPY docker-entrypoint.sh /docker-entrypoint.sh


VOLUME ["/etc/openldap/slapd.d", "/var/lib/openldap/openldap-data"]

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
