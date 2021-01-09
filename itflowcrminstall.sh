#check if running on ubuntu 20.04
UBU20=$(grep 20.04 "/etc/"*"release")
if ! [[ $UBU20 ]]; then
  echo -ne "\033[0;31mThis script will only work on Ubuntu 20.04\e[0m\n"
  exit 1
fi

#Enter domain
while [[ $domain != *[.]*[.]* ]]
do
echo -ne "Enter your Domain${NC}: "
read domain
done

#Generate mysql password
mysqlpwd=$(cat /dev/urandom | tr -dc 'A-Za-z0-9%&+?@^~' | fold -w 20 | head -n 1)

echo ${mysqlpwd}
pause 

#run update
sudo apt-get update && sudo apt-get -y upgrade

#Install apache2 & mysql
sudo apt-get install -y apache2
sudo apt-get install -y mysql-server
sudo mysql_secure_installation
sudo apt-get install -y php libapache2-mod-php php-mysql php-mbstring php-curl 
sudo apt-get install -y rewrite libapache2-mod-md
sudo apt-get install -y certbot python3-certbot-apache
sudo apt-get install -y git
sudo a2enmod md
sudo a2enmod ssl

#Restart apache2
sudo service apache2 restart

#Set firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw enable

#Create and set permissions on webroot
mkdir /var/www/${domain}

chown -R www-data:www-data /var/www/

#Set Apache2 config file
apache2="$(cat << EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName ${domain}
    ServerAlias ${domain}
    DocumentRoot /var/www/${domain}
    ErrorLog /\${APACHE_LOG_DIR}/error.log
    CustomLog /\${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
)"
echo "${apache2}" > /etc/apache2/sites-available/${domain}.conf

sudo a2ensite ${domain}.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2

#run certification
sudo certbot --apache

#Go to webroot
cd /var/www/${domain}

#Clone IT Flow CRM
git clone https://github.com/johnnyq/itflow.git

#Move files and fix permissions
mv /var/www/${domain}/pittpc_crm/* /var/www/${domain}/
rm -rf /var/www/${domain}/pittpc_crm/
chown -R www-data:www-data /var/www/


#Create MySQl DB
    mysql -e "CREATE DATABASE ITFlow /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -e "CREATE USER PITTCRM@localhost IDENTIFIED BY '${mysqlpwd}';"
    mysql -e "GRANT ALL PRIVILEGES ON ITFlow.* TO 'ITFlow'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

printf >&2 "Please go to admin url: https://${domain}"
printf >&2 "\n\n"
printf >&2 "Enter ITFlow as database user and database name. Enter '${mysqlpwd}' as MySQL Password\n\n"

echo "Press any key to finish install"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
echo "waiting for the keypress"
fi
done
