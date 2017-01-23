#!/bin/bash

curlbin=$(which curl)
sedbin=$(which sed)

u2dloc=/etc/sysconfig/rhn/up2date
rhnploc=/etc/yum/pluginconf.d/rhnplugin.conf
yumcloc=/etc/yum.conf
certloc=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT
sysidloc=/etc/sysconfig/rhn/systemid

serverurl=<satellite server url>
user=<satellite user>
pass=<satellite pasword>
actkey=<satellite access key>

# Check if running as root
if [ $(id -u) -ne 0 ]; then echo 'This needs to be run as a root'; exit 2; fi

# Check if host entry present in hosts file
if [ "$(grep ${serverurl} /etc/hosts)" == "" ]; then echo "156.24.65.227 ${serverurl}" >> /etc/hosts; fi

# Check if system already registered
if [ -f ${sysidloc} ]; then 
  if [ "$1" == "-f" ]; then rm -f ${sysidloc}; fi
fi

# Do the registration and configuration
if [ -f ${certloc} ]; then rm -f ${certloc}; fi
${curlbin} -k -o ${certloc} http://${serverurl}/pub/RHN-ORG-TRUSTED-SSL-CERT
${sedbin} -i "/serverURL=/c \serverURL=http://${serverurl}/XMLRPC\\" ${u2dloc}
${sedbin} -i "/noSSLServerURL=/c \noSSLServerURL=http://${serverurl}/XMLRPC\\" ${u2dloc}
${sedbin} -i "/sslCACert=/c \sslCACert=${certloc}\\" ${u2dloc}
/usr/sbin/rhnreg_ks --serverUrl=http://${serverurl}/XMLRPC --username ${user} --password ${pass} --activationkey=${actkey} --force
${sedbin} -i '/enabled =/c \enabled=1\' ${rhnploc}
${sedbin} -i '/gpgcheck =/c \gpgcheck=0\' ${rhnploc}
${sedbin} -i '/gpgcheck=1/c \gpgcheck=0\' ${yumcloc}

