#!/bin/sh -e
export LDAP_CONF_DIR="/etc/openldap/slapd.d"
export LDAP_CONF=/etc/openldap/slapd.conf
export LDAP_SUFFIX="dc=${LDAP_DOMAIN//./,dc=}"
export LAPD_ROOTDN="cn=admin,${LDAP_SUFFIX}"
export LDAP_PASSWORD_ENCRYPTED="$(slappasswd -u -h '{SSHA}' -s ${LDAP_PASSWORD})"

mkdir -p /var/run/openldap /var/lib/openldap/run 


if [[ ! -d ${LDAP_CONF_DIR}/cn=config ]]; then
    mkdir -p ${LDAP_CONF_DIR}

    # builtin schema
	cat <<-EOF > "$LDAP_CONF"
	include: file:///etc/openldap/schema/core.ldif
    include: file:///etc/openldap/schema/cosine.ldif
    include: file:///etc/openldap/schema/nis.ldif
    include: file:///etc/openldap/schema/inetorgperson.ldif
	EOF

    cat <<-EOF >> "$LDAP_CONF"
pidfile		/run/openldap/slapd.pid
argsfile	/run/openldap/slapd.args
modulepath  /usr/lib/openldap
moduleload  back_mdb.so
database config
rootdn "gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
access to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by dn.base="$LAPD_ROOTDN" manage by * break
database mdb
access to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by dn.base="$LAPD_ROOTDN" manage by * none
maxsize 1073741824
suffix "${LDAP_SUFFIX}"
rootdn "${LAPD_ROOTDN}"
rootpw ${LDAP_PASSWORD_ENCRYPTED}
directory  /var/lib/openldap/openldap-data
	EOF

    cat <<-EOF > "${LDAP_CONF_DIR}/base.ldif"
dn: ${LAPD_SUFFIX}
dc: ${LAPD_ORGANIZATION}
objectClass: top
objectClass: dcObject
objectClass: organization
o: ${LAPD_ORGANIZATION}

dn: cn=admin,${LDAP_SUFFIX}
objectClass: organizationalRole
cn: admin
	EOF


    # RFC2307bis schema
    if [ "${LDAP_RFC2307BIS_SCHEMA}" == "true" ]; then
        sed -i "s@nis.ldif@rfc2307bis.ldif@g" $LDAP_CONF
    fi

    echo "Generating configuration"
	slaptest -f ${LDAP_CONF} -F ${LDAP_CONF_DIR} -d ${LDAP_LOGLEVE}
    slapadd  -c -F ${LDAP_CONF_DIR}  -l "${SLAPD_CONF_DIR}/base.ldif" -n1

    chown -R ldap:ldap ${LDAP_CONF_DIR} /var/run/openldap /var/lib/openldap

fi

slapd -h "ldap:/// ldapi:///"  -F ${LDAP_CONF_DIR} -u ldap -g ldap -d "${LDAP_LOGLEVE}"

exec "$@"
