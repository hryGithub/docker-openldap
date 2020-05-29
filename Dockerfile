FROM alpine:3.11

RUN echo -e "http://mirrors.aliyun.com/alpine/v3.11/main\nhttp://mirrors.aliyun.com/alpine/v3.11/community" > /etc/apk/repositories
RUN apk update && apk add --no-cache bash gettext openldap openldap-clients openldap-back-mdb openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint
RUN mv -vf /etc/openldap/slapd.conf /etc/openldap/slapd.conf.original

ENV LAPD_ORGANIZATION=example \
    LDAP_DOMAIN=example.org \
    LDAP_PASSWORD=admin \
    LDAP_RFC2307BIS_SCHEMA=false \
    LDAP_LOGLEVE=1

EXPOSE 389 636

COPY rfc2307bis.* /etc/openldap/schema/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
