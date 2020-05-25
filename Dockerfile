FROM alpine:3.11

RUN echo -e "http://mirrors.aliyun.com/alpine/v3.11/main\nhttp://mirrors.aliyun.com/alpine/v3.11/community" > /etc/apk/repositories
RUN apk update && apk add --no-cache bash gettext openldap openldap-clients openldap-back-mdb openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint

ENV SLAPD_ORGANIZATION="example" \
    SLAPD_DOMAIN="example.org" \
    SLAPD_ROOTPW="admin" \
    SLAPD_LOG_LEVEL=1 

ENV SLAPD_CONF_DIR=/etc/openldap/slapd.d \
    SLAPD_DATA_DIR=/var/lib/openldap/openldap-data \
    SLAPD_CONF=/etc/openldap/slapd.conf


COPY ldap/ /ldap/

EXPOSE 389 636
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
