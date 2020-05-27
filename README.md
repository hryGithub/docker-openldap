# quick start
    docker run -d --name openldap --restart on-failure:5 -p 389:389 -e LAPD_ORGANIZATION=example -e LDAP_DOMAIN=example.org -e LDAP_PASSWORD=admin hyr326/openldap:latest


