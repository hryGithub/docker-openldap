#!/bin/sh -e
OPENLDAP_CONFIG_DIR="/etc/openldap/slapd.d"
OPENLDAP_ULIMIT="2048"

LDAP_SUFFIX="dc=${LDAP_DOMAIN//./,dc=}"
LDAP_PASSWORD_ENCRYPTED="$(slappasswd -u -h '{SSHA}' -s ${LDAP_PASSWORD})"

ulimit -n ${OPENLDAP_ULIMIT}
mkdir -p /var/run/openldap /var/lib/openldap/run /srv/openldap.d 

if [[ ! -d ${OPENLDAP_CONFIG_DIR}/cn=config ]]; then
    mkdir -p ${OPENLDAP_CONFIG_DIR}

    if [[ ! -s /etc/openldap/slapd-config.ldif ]]; then
        cat /srv/openldap/slapd-config.ldif.template | envsubst > /etc/openldap/slapd-config.ldif
    fi

    slapadd -n0 -F ${OPENLDAP_CONFIG_DIR} -l /etc/openldap/slapd-config.ldif > /etc/openldap/slapd-config.ldif.log

    if [[ ! -s /etc/openldap/ldap.conf ]]; then
        cat /srv/openldap/ldap.conf.template | envsubst > /etc/openldap/ldap.conf
    fi

    chown -R ldap:ldap ${OPENLDAP_CONFIG_DIR} /var/run/openldap /var/lib/openldap

    if [[ -d /srv/openldap.d ]]; then
        if [[ ! -s /srv/openldap.d/000-domain.ldif ]]; then
            cat /srv/openldap/domain.ldif.template | envsubst > /srv/openldap.d/000-domain.ldif
        fi

        slapd_exe=$(which slapd)
        echo >&2 "$0 ($slapd_exe): starting initdb daemon"
        slapd -u ldap -g ldap -h ldapi:///

        for f in $(find /srv/openldap.d -type f | sort); do
            case "$f" in
                *.sh)   echo "$0: sourcing $f"; . "$f" ;;
                *.ldif) echo "$0: applying $f"; ldapadd -Y EXTERNAL -f "$f" 2>&1;;
                *)      echo "$0: ignoring $f" ;;
            esac
        done

        if [[ ! -s /var/run/openldap/slapd.pid ]]; then
            echo >&2 "$0 ($slapd_exe): /var/run/openldap/slapd.pid is missing, did the daemon start?"
            exit 1
        else
            slapd_pid=$(cat /var/run/openldap/slapd.pid)
            echo >&2 "$0 ($slapd_exe): sending SIGINT to initdb daemon with pid=$slapd_pid"
            kill -s INT "$slapd_pid" || true
            while : ; do
                [[ ! -f /var/run/openldap/slapd.pid ]] && break
                sleep 1
                echo >&2 "$0 ($slapd_exe): initdb daemon is still up, sleeping ..."
            done
            echo >&2 "$0 ($slapd_exe): initdb daemon stopped"
        fi
    fi
fi

exec "$@"
