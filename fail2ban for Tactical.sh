#!/bin/bash


#####Fail2ban setup
sudo apt install -y fail2ban

strip="User="
USER=$(grep ${strip} /etc/systemd/system/rmm.service | sed -e "s/^${strip}//")
sudo chown ${USER}:${USER} -R /etc/fail2ban/filter.d/tacticalrmm.conf
sudo chown ${USER}:${USER} -R /etc/fail2ban/jail.d/tacticalrmm.local


#Set Tactical fail2ban filter conf File
tacticalfail2banfilter="$(cat << EOF
[Definition]
failregex = ^<HOST>.*400.17.*$
ignoreregex = ^<HOST>.*200.*$
EOF
)"
echo "${tacticalfail2banfilter}" > /etc/fail2ban/filter.d/tacticalrmm.conf

#Set Tactical fail2ban jail conf File
tacticalfail2banjail="$(cat << EOF
[tacticalrmm]
enabled = true
port = 80,443
filter = tacticalrmm
action = iptables-allports[name=tactical]
logpath = /rmm/api/tacticalrmm/tacticalrmm/private/log/access.log
maxretry = 3
bantime = 14400
findtime = 14400
EOF
)"
echo "${tacticalfail2banjail}" > /etc/fail2ban/jail.d/tacticalrmm.local

sudo systemctl restart fail2ban


## to unban ips use the command below
## sudo fail2ban-client set tacticalrmm unbanip IPADDRESS
