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
sudo apt-get install -y unzip
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

#Download Anuko Time Tracker
wget https://www.anuko.com/download/time_tracker/time_tracker_pdf.zip
unzip time_tracker_pdf.zip 

#Move files and fix permissions
mv /var/www/${domain}/timetracker/* /var/www/${domain}/
rm -rf /var/www/${domain}/timetracker/
chown -R www-data:www-data /var/www/
chmod 777 /var/www/${domain}/WEB-INF/templates_c


#Create MySQl DB
    mysql -e "CREATE DATABASE timetracker /*\!40100 DEFAULT CHARACTER SET utf8mb4 */;"
    mysql -e "CREATE USER timetracker@localhost IDENTIFIED BY '${mysqlpwd}';"
    mysql -e "GRANT ALL PRIVILEGES ON timetracker.* TO 'timetracker'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
	
#TimeTrack config
ttconf="$(cat << EOF
<?php
// +----------------------------------------------------------------------+
// | Anuko Time Tracker
// +----------------------------------------------------------------------+
// | Copyright (c) Anuko International Ltd. (https://www.anuko.com)
// +----------------------------------------------------------------------+
// | LIBERAL FREEWARE LICENSE: This source code document may be used
// | by anyone for any purpose, and freely redistributed alone or in
// | combination with other software, provided that the license is obeyed.
// |
// | There are only two ways to violate the license:
// |
// | 1. To redistribute this code in source form, with the copyright
// |    notice or license removed or altered. (Distributing in compiled
// |    forms without embedded copyright notices is permitted).
// |
// | 2. To redistribute modified versions of this code in *any* form
// |    that bears insufficient indications that the modifications are
// |    not the work of the original author(s).
// |
// | This license applies to this document only, not any other software
// | that it may be combined with.
// |
// +----------------------------------------------------------------------+
// | Contributors:
// | https://www.anuko.com/time_tracker/credits.htm
// +----------------------------------------------------------------------+


// Set include path for PEAR and its modules, which we include in the distribution.
//
set_include_path(realpath(dirname(__FILE__).'/lib/pear') . PATH_SEPARATOR . get_include_path());


// Database connection parameters.
//
// CHANGE 3 PARAMETERS HERE!
// In this example: "root" is username, "no" is password, "dbname" is database name.
//
define('DSN', 'mysqli://timetrack:${mysqlpwd}@localhost/timetrack?charset=utf8mb4');
// Do NOT change charset unless you upgraded from an older Time Tracker where charset was NOT specified
// and now you see some corrupted characters. See http://dev.mysql.com/doc/refman/5.0/en/charset-mysql.html


// MULTIORG_MODE option defines whether users can create their own top groups (organizations).
// When false, a Time Tracker server is managed by admin, who creates top groups (one or many).
//
// Available values are true or false.
//
define('MULTIORG_MODE', false);


// EMAIL_REQUIRED defines whether an email is required for new registrations.
define('EMAIL_REQUIRED', false);


// Directory name.
// If you install time tracker into a sub-directory of your site reflect this in the DIR_NAME parameter.
// For example, for http://localhost/timetracker/ define DIR_NAME as 'timetracker'.
//
// define('DIR_NAME', 'timetracker');
//
define('DIR_NAME', '');


// WEEKEND_START_DAY
//
// This option defines which days are highlighted with weekend color.
// 6 means Saturday. For Saudi Arabia, etc. set it to 4 for Thursday and Friday to be weekend days.
//
define('WEEKEND_START_DAY', 6);


// SESSION_COOKIE_NAME
//
// PHP session cookie name.
// define('SESSION_COOKIE_NAME', 'tt_PHPSESSID');


// PHPSESSID_TTL
//
// Lifetime in seconds for session cookie. Time to live is extended by this value
// with each visit to the site so that users don't have to re-login. 
define('PHPSESSID_TTL', 2592000);
//
// Note: see also PHP_SESSION_PATH below as you may have to use it together with
// PHPSESSID_TTL to avoid premature session expirations.


// PHP_SESSION_PATH
// Local file system path for PHP sessions. Use it to isolate session deletions
// (garbage collection interference) by other PHP scripts potentially running on the system.
define('PHP_SESSION_PATH', '/tmp/timetracker'); // Directory must exist and be writable.


// LOGIN_COOKIE_NAME
//
// Cookie name for user login to remember it between browser sessions.
define('LOGIN_COOKIE_NAME', 'tt_login');


// Forum and help links from the main menu.
//
//define('FORUM_LINK', 'https://www.anuko.com/forum/viewforum.php?f=4');
//define('HELP_LINK', 'https://www.anuko.com/time-tracker/user-guide/index.htm');


// Default sender for mail.
//
define('SENDER', 'Anuko Time Tracker <no-reply@timetracker.anuko.com>');


// MAIL_MODE - mail sending mode. Can be 'mail' or 'smtp'.
// 'mail' - sending through php mail() function.
// 'smtp' - sending directly through SMTP server.
// See https://www.anuko.com/time_tracker/install_guide/mail.htm
//
define('MAIL_MODE', 'smtp');
define('MAIL_SMTP_HOST', 'localhost'); // For gmail use 'ssl://smtp.gmail.com' instead of 'localhost' and port 465.
// define('MAIL_SMTP_PORT', '465');
// define('MAIL_SMTP_USER', 'yourname@yourdomain.com');
// define('MAIL_SMTP_PASSWORD', 'yourpassword');
// define('MAIL_SMTP_AUTH', true);
// define('MAIL_SMTP_DEBUG', true);


// CSS files. They are located in the root of Time Tracker installation.
//
define('DEFAULT_CSS', 'default.css');
define('RTL_CSS', 'rtl.css'); // For right to left languages.


// Default language of the application.
// Possible values: en, fr, nl, etc. Empty string means the language is defined by user browser.
// 
define('LANG_DEFAULT', '');


// Default currency symbol. Use €, £, a more specific dollar like US$, CAD, etc.
// 
define('CURRENCY_DEFAULT', '£');


// EXPORT_DECIMAL_DURATION - defines whether time duration values are decimal in CSV and XML data exports (1.25 or 1,25 vs 1:15).
// 
define('EXPORT_DECIMAL_DURATION', true);


// REPORT_FOOTER - defines whether to use a footer on reports.
// 
define('REPORT_FOOTER', true);


// Authentication module (see WEB-INF/lib/auth/)
// Possible authentication methods:
//   db - internal database, logins and password hashes are stored in time tracker database.
//   ldap - authentication against an LDAP directory such as OpenLDAP or Windows Active Directory.
define('AUTH_MODULE', 'db');

// LDAP authentication examples.
// Go to https://www.anuko.com/time_tracker/install_guide/ldap_auth/index.htm for detailed configuration instructions.

// Configuration example for OpenLDAP server:
// define('AUTH_MODULE', 'ldap');
// $GLOBALS['AUTH_MODULE_PARAMS'] = array(
//  'server' => '127.0.0.1',                    // OpenLDAP server address or name. For secure LDAP use ldaps://hostname:port here.
//  'type' => 'openldap',                       // Type of server. openldap type should also work with Sun Directory Server when member_of is empty.
                                                // It may work with other (non Windows AD) LDAP servers. For Windows AD use the 'ad' type.
//  'base_dn' => 'ou=People,dc=example,dc=com', // Path of user's base distinguished name in LDAP catalog.
//  'user_login_attribute' => 'uid',            // LDAP attribute used for login.
//  'default_domain' => 'example.com',          // Default domain.
//  'member_of' => array());                    // List of groups, membership in which is required for user to be authenticated.


// Configuration example for Windows domains with Active Directory:
// define('AUTH_MODULE', 'ldap');
// $GLOBALS['AUTH_MODULE_PARAMS'] = array(
//  'server' => '127.0.0.1',            // Domain controller IP address or name. For secure LDAP use ldaps://hostname:port here.
//  'type' => 'ad',                     // Type of server.
//  'base_dn' => 'DC=example,DC=com',   // Base distinguished name in LDAP catalog.
//  'default_domain' => 'example.com',  // Default domain.
//  'member_of' => array());            // List of groups, membership in which is required for user to be authenticated.
                                        // Leave it empty if membership is not necessary. Otherwise list CN parts only.
                                        // For example:
                                        // array('Ldap Testers') means that the user must be a member Ldap Testers group.
                                        // array('Ldap Testers', 'Ldap Users') means the user must be a member of both Ldap Testers and Ldap Users groups.

// define('DEBUG', false); // Note: enabling DEBUG breaks redirects as debug output is printed before setting redirect header. Do not enable on production systems.


// Group managers can set monthly work hour quota for years between the following  values.
// define('MONTHLY_QUOTA_YEAR_START', 2010); // If nothing is specified, it falls back to 2015.
// define('MONTHLY_QUOTA_YEAR_END', 2025);   // If nothing is specified, it falls back to 2030.

// Height in pixels for the note input field in time.php. Defaults to 40.
define('NOTE_INPUT_HEIGHT', 100);

// A comma-separated list of default plugins for new group registrations.
// Example below enables charts and attachments.
// define('DEFAULT_PLUGINS', 'ch,at');
EOF
)"
echo "${ttconf}" > /var/www/${domain}/WEB-INF/config.php

chown -R www-data:www-data /var/www/${domain}/WEB-INF/config.php


printf >&2 "Please go to admin url: https://${domain}"
printf >&2 "\n\n"
printf >&2 "Enter timetracker as database user and database name. Enter '${mysqlpwd}' as MySQL Password\n\n"

echo "Press any key to finish install"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
echo "waiting for the keypress"
fi
done
