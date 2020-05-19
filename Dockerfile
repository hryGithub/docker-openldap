FROM alpine:3.11

RUN echo -e "http://mirrors.aliyun.com/alpine/v3.11/main\nhttp://mirrors.aliyun.com/alpine/v3.11/community" > /etc/apk/repositories
RUN apk update && apk add --no-cache gettext openldap openldap-clients openldap-back-mdb openldap-passwd-pbkdf2 openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint

ENV SLAPD_ORGANIZATION="My Company" \
    SLAPD_DOMAIN="My-Company.com" \
    SLAPD_ROOTDN="root" \
    SLAPD_ROOTPASSWORD="admin"

ENV SLAPD_CONF_DIR=/etc/openldap/slapd.d \
    SLAPD_DATA_DIR=/var/lib/openldap/openldap-data \
    SLAPD_CONF=/etc/openldap/slapd.conf



EXPOSE 389 636

COPY ldap/ /ldap/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]