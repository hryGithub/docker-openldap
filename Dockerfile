FROM alpine:3.11

RUN echo -e "http://mirrors.aliyun.com/alpine/v3.11/main\nhttp://mirrors.aliyun.com/alpine/v3.11/community" > /etc/apk/repositories
RUN apk update && apk add --no-cache bash gettext openldap openldap-clients openldap-back-mdb openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint
RUN mv -vf /etc/openldap/ldap.conf /etc/openldap/ldap.conf.original && mv -vf /etc/openldap/slapd.conf /etc/openldap/slapd.conf.original

EXPOSE 389 636

COPY *.template /srv/openldap/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
