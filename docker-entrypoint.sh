#!/bin/sh -e
export LDAP_CONF_DIR="/etc/openldap/slapd.d"
export LDAP_CONF=/etc/openldap/slapd.conf
export LDAP_SUFFIX="dc=${LDAP_DOMAIN//./,dc=}"
export LDAP_ROOTDN="cn=admin,${LDAP_SUFFIX}"
export LDAP_PASSWORD_ENCRYPTED="$(slappasswd -u -h '{SSHA}' -s ${LDAP_PASSWORD})"

mkdir -p /var/run/openldap /var/lib/openldap/run 


if [[ ! -d ${LDAP_CONF_DIR}/cn=config ]]; then
    mkdir -p ${LDAP_CONF_DIR}

    # builtin schema
	cat <<-EOF > "$LDAP_CONF"
include /etc/openldap/schema/core.schema
include /etc/openldap/schema/cosine.schema
include /etc/openldap/schema/nis.schema
include /etc/openldap/schema/inetorgperson.schema
include /etc/openldap/schema/ppolicy.schema
pidfile		/run/openldap/slapd.pid
argsfile	/run/openldap/slapd.args
access to attrs=userPassword,shadowLastChange
        by dn="${LDAP_ROOTDN}" write
        by anonymous auth
        by self write
        by * none
access to *
        by dn="${LDAP_ROOTDN}" write
        by * read

modulepath  /usr/lib/openldap
moduleload  back_mdb.so
database mdb
maxsize 1073741824
suffix "${LDAP_SUFFIX}"
rootdn "${LDAP_ROOTDN}"
rootpw ${LDAP_PASSWORD_ENCRYPTED}
directory  /var/lib/openldap/openldap-data
	EOF

    cat <<-EOF > "${LDAP_CONF_DIR}/base.ldif"
dn: ${LDAP_SUFFIX}
dc: ${LDAP_ORGANIZATION}
objectClass: top
objectClass: dcObject
objectClass: organization
o: ${LDAP_ORGANIZATION}

dn: cn=admin,${LDAP_SUFFIX}
objectClass: organizationalRole
cn: admin
	EOF

    # RFC2307bis schema
    if [ "${LDAP_RFC2307BIS_SCHEMA}" == "true" ]; then
        sed -i "s@nis.schema@rfc2307bis.schema@g" $LDAP_CONF
    fi

    echo "Generating configuration"
    slaptest -f ${LDAP_CONF} -F ${LDAP_CONF_DIR} -d ${LDAP_LOGLEVE}
    slapadd  -c -F ${LDAP_CONF_DIR}  -l "${LDAP_CONF_DIR}/base.ldif" 
    
    chown -R ldap:ldap ${LDAP_CONF_DIR} /var/run/openldap /var/lib/openldap

fi

slapd -h "ldap:/// ldapi:///"  -F ${LDAP_CONF_DIR} -u ldap -g ldap -d "${LDAP_LOGLEVE}"

exec "$@"
