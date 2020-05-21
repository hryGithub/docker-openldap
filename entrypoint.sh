#!/bin/bash

# escape url
_escurl() { echo $1 | sed 's|/|%2F|g' ;}
# substitute environment variables in file
_envsubst() { envsubst < $1 > ${SUBST_FILE}; echo ${SUBST_FILE} ; }

host=$(hostname)

SLAPD_SUFFIX=""
IFS='.' read -ra LDAP_BASE_DN_TABLE <<< "$SLAPD_DOMAIN"
for i in "${LDAP_BASE_DN_TABLE[@]}"; do
    EXT="dc=$i,"
    SLAPD_SUFFIX=$SLAPD_SUFFIX$EXT
done
SLAPD_SUFFIX=${SLAPD_SUFFIX::-1}

SLAPD_ROOTDN="cn=admin,$SLAPD_SUFFIX"

DB_DUMP_FILE=/ldap/dump/dbdump.ldif


if [[ ! -d ${SLAPD_CONF_DIR} ]]; then
	FIRST_START=1
	if [[ ! -f ${SLAPD_CONF} ]];then
	 touch ${SLAPD_CONF}
	fi
	mkdir -p /run/openldap/

	echo "Configuring OpenLDAP via slapd.d"
	mkdir -p ${SLAPD_CONF_DIR}
	chmod -R 750 ${SLAPD_CONF_DIR}
	mkdir -p ${SLAPD_DATA_DIR}
	chmod -R 750 ${SLAPD_DATA_DIR}

	echo "SLAPD_ROOTDN = $SLAPD_ROOTDN"

	rootpw_hash=`slappasswd -o module-load=pw-pbkdf2.so -h {PBKDF2-SHA512} -s "${SLAPD_ROOTPW}"`

	# builtin schema
	cat <<-EOF > "$SLAPD_CONF"
	include /etc/openldap/schema/core.schema
	include /etc/openldap/schema/cosine.schema
	include /etc/openldap/schema/inetorgperson.schema
	include /etc/openldap/schema/ppolicy.schema
	EOF

	# user-provided schemas
	if [[ -d "/ldap/schema" ]] &&  [[ "$(ls -A '/ldap/schema')" ]]; then
		for f in /ldap/schema/*.schema ; do
			echo "Including custom schema $f"
			echo "include $f" >> "$SLAPD_CONF"
		done
	fi

    # ssl certs and keys
    if [[ -d "/ldap/pki" ]]  &&  [[ "$(ls -A '/ldap/pki')" ]]; then
        CA_CERT=/ldap/pki/ca_cert.pem
        SSL_KEY=/ldap/pki/key.pem
        SSL_CERT=/ldap/pki/cert.pem

        # user-provided tls certs
        if [[ -f ${CA_CERT} ]]; then
            echo "TLSCACertificateFile ${CA_CERT}" >>  "$SLAPD_CONF"
        fi
        echo "TLSCertificateFile ${SSL_CERT}" >>  "$SLAPD_CONF"
        echo "TLSCertificateKeyFile ${SSL_KEY}" >>  "$SLAPD_CONF"
        echo "TLSCipherSuite HIGH:-SSLv2:-SSLv3" >>  "$SLAPD_CONF"
    fi


    cat <<-EOF >> "$SLAPD_CONF"
pidfile		/run/openldap/slapd.pid
argsfile	/run/openldap/slapd.args
modulepath  /usr/lib/openldap
moduleload  back_mdb.so
moduleload  pw-pbkdf2.so
database config
rootdn "gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
access to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by dn.base="$SLAPD_ROOTDN" manage by * break
database mdb
access to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by dn.base="$SLAPD_ROOTDN" manage by * none
maxsize 1073741824
suffix "${SLAPD_SUFFIX}"
rootdn "${SLAPD_ROOTDN}"
rootpw ${rootpw_hash}
password-hash {PBKDF2-SHA512}
directory  ${SLAPD_DATA_DIR}
EOF


    cat <<-EOF > "${SLAPD_CONF_DIR}/domain.ldif"
dn: ${SLAPD_SUFFIX}
dc: ${SLAPD_DOMAIN}
objectClass: top
objectClass: dcObject
objectClass: organization
o: ${SLAPD_ORGANIZATION}
EOF

    echo "Generating configuration"
    slaptest -f ${SLAPD_CONF} -F ${SLAPD_CONF_DIR} -d ${SLAPD_LOG_LEVEL}
    slapadd  -c -F ${SLAPD_CONF_DIR}  -l "${SLAPD_CONF_DIR}/domain.ldif" -n1
    chown -R ldap:ldap ${SLAPD_CONF_DIR}
    chown -R ldap:ldap /run/openldap/
    chown -R ldap:ldap ${SLAPD_DATA_DIR}
fi
# Start the slapd service
if [[  -f "${SSL_KEY}"  ]] ; then
	slapd -h "ldap:/// ldaps:///" -F ${SLAPD_CONF_DIR} -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"
else
	slapd -h "ldap:///" -F ${SLAPD_CONF_DIR} -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"
fi

exec "$@"
