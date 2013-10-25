#!/bin/bash

debrant_version='0.1.1'
# running time measure
start_seconds=`date +%s`
# network check
ping_result=`ping -c 2 8.8.8.8 2>&1`

# Text color variables
txtred='\e[0;31m'       # red
txtgrn='\e[0;32m'       # green
txtylw='\e[0;33m'       # yellow
txtblu='\e[0;34m'       # blue
txtpur='\e[0;35m'       # purple
txtcyn='\e[0;36m'       # cyan
txtwht='\e[0;37m'       # white
bldred='\e[1;31m'       # red    - Bold
bldgrn='\e[1;32m'       # green
bldylw='\e[1;33m'       # yellow
bldblu='\e[1;34m'       # blue
bldpur='\e[1;35m'       # purple
bldcyn='\e[1;36m'       # cyan
bldwht='\e[1;37m'       # white
txtund=$(tput sgr 0 1)  # Underline
txtbld=$(tput bold)     # Bold
txtrst='\e[0m'          # Text reset
txtdim='\e[2m'
 
echo -e "${bldred}
______     _                     _   
|  _  \   | |                   | |  
| | | |___| |__  _ __ __ _ _ __ | |_ 
| | | / _ \ '_ \| '__/ _\` | '_ \| __|
| |/ /  __/ |_) | | | (_| | | | | |_ 
|___/ \___|_.__/|_|  \__,_|_| |_|\__|
${txtrst}
Debian-based Vagrant - version ${txtgrn}$debrant_version${txtrst}
${txtund}https://github.com/swergroup/debrant${txtreset}
"

echo $debrant_version > /etc/debrant_version

# Feedback indicators
info="\n${bldblu} % ${txtrst}"
list="${bldcyn} - ${txtrst}"
pass="${bldgrn} * ${txtrst}"
warn="${bldylw} ! ${txtrst}"
dead="${bldred}!!!${txtrst}"

function headinfo {
	echo -e "${txtrst}"
	echo -e "${bldblu}###${txtrst} ${bldwht}$1${txtrst}"
	echo -e "${txtrst}"
}

# Debian package checklist
apt_package_check_list=(
	build-essential
	byobu
  checkinstall
	colordiff
	curl
	debian-keyring
	deborphan
	dos2unix
	findutils
	ffmpeg
	gettext
	geoip-bin
	geoip-database
	git
	git-svn
	gnupg2
	gnupg-curl
	gnu-standards
	graphviz
	imagemagick
	kexec-tools
	links
	libaio1
	libdbi-perl
	libnet-daemon-perl
	libmemcache0
	libmemcached10
	libmysqlclient18=5.5.34-rel32.0-591.wheezy
	localepurge
	lynx
  mailutils
	mcrypt
	memcached
	mlocate
	nginx-extras
	ntp
	ntpdate
  nullmailer
	optipng
	percona-playback
	percona-toolkit
	percona-server-client-5.5
	percona-server-common-5.5
	percona-server-server-5.5
	percona-xtrabackup
	php-apc
	php-pear
	php5-cli
	php5-common
	php5-curl
	php5-dev
	php5-ffmpeg
	php5-fpm
	php5-gd
	php5-geoip
	php5-imagick
	php5-imap
	php5-mcrypt
	php5-memcache
	php5-memcached
	php5-mysql
	php5-sqlite
	php5-xdebug
	php5-xmlrpc
	php5-xsl
	pound
	rsync
	screen
	stress
	unar
	unrar
	unzip
	varnish
	vim
	wget
	yui-compressor
	zsh
)

pear_channels=(
	components.ez.no
  pear.phpunit.de
	pear.netpirates.net
	pear.symfony.com
	pear.phpdoc.org
)
 
pear_packages=(
  PHP_CodeSniffer
  phpunit/PHP_CodeCoverage
  phpunit/PHPUnit
  phpunit/PHPUnit_Selenium
  phpunit/PHPUnit_MockObject
  phpunit/phpcov
  phpunit/phpcpd
  phpunit/phpdcd-0.9.3
  phpunit/phploc
  phpdoc/phpDocumentor
	phpdoc/phpDocumentor_Template_responsive
)

npm_packages=(
  grunt-cli
  phantomjs
)


export DEBIAN_FRONTEND=noninteractive

headinfo "APT sources setup"
if [ -f /etc/apt/sources.list.d/grml.list ]; then
	sudo rm /etc/apt/sources.list.d/grml.list
fi

if [ -f /srv/config/sources.list ]; then
  echo -e "${list} GPG keys setup"
	# percona server (mysql)
	apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A	2>&1 > /dev/null
	# varnish
	wget -qO- http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

  echo -e "${list} sources.list"
	unlink /etc/apt/sources.list
	ln -s /srv/config/sources.list /etc/apt/sources.list

elif [ -f /srv/config/custom-sources.list ]; then	
  
  echo -e "${list} custom-sources.list"
	unlink /etc/apt/sources.list.d/custom-sources.list
	ln -s /srv/config/custom-sources.list /etc/apt/sources.list.d/custom-sources.list
fi

# MySQL
#
# Use debconf-set-selections to specify the default password for the root MySQL
# account. This runs on every provision, even if MySQL has been installed. If
# MySQL is already installed, it will not affect anything. 
echo mysql-server mysql-server/root_password password root | debconf-set-selections
echo mysql-server mysql-server/root_password_again password root | debconf-set-selections

headinfo "Debrant system packages check"
for pkg in "${apt_package_check_list[@]}"
do
	if dpkg -s $pkg 2>&1 | grep -q 'Status: install ok installed';
	then 
		echo -e "${pass} $pkg"
	else
		echo -e "${warn} $pkg"
		apt_package_install_list+=($pkg)
	fi
done

headinfo "System packages setup"
if [ ${#apt_package_install_list[@]} = 0 ];
then 
  echo -e "${pass} Nothing to do!"
else
  echo -e "${list} Installing packages.."
	aptitude purge ~c
	apt-get update --assume-yes
	apt-get install --force-yes --assume-yes ${apt_package_install_list[@]}
	apt-get clean
fi

headinfo "Composer setup"
if which composer &>/dev/null;
then
  echo -e "${list} Updating.."
	composer self-update
else
	echo -e "${list} Installing.."
	curl -sS https://getcomposer.org/installer | php
	chmod +x composer.phar
	mv composer.phar /usr/local/bin/composer
fi
echo -e "${pass} Composer check"
composer --version


headinfo "Scrutinizer setup"
if which scrutinizer &>/dev/null;
then
	echo -e "${list} Updating.."
	scrutinizer self-update
else
	echo -e "${list} Installing.."
	wget -q -O /usr/local/bin/scrutinizer https://scrutinizer-ci.com/scrutinizer.phar
	chmod +x /usr/local/bin/scrutinizer
fi
echo -e "${pass} Scrutinizer check"
scrutinizer --version


headinfo "PHP PEAR setup"
pear config-set auto_discover 1
echo -e "${list} PEAR channel-discover"
for chan in "${pear_channels[@]}"
do
  pear -q channel-discover $chan
done
echo -e "${list} PEAR update-channels"
pear -q update-channels
 
for pearpkg in "${pear_packages[@]}"
do
	echo -e "${list} PEAR install $pearpkg $(pear -q install -a $pearpkg 2>&1 > /dev/null)"
done
echo -e "${list} PEAR upgrade-all"
pear -q upgrade-all
echo -e "${pass} PEAR check"
pear -V


headinfo "wp-cli setup"
if [ ! -d /srv/www/wp-cli ]
then
  echo -e "${list} Cloning repository"
	git clone git://github.com/wp-cli/wp-cli.git /srv/www/wp-cli
	cd /srv/www/wp-cli
  echo -e "${list} Installing via Composer"
	composer install
  echo -e "${list} Community packages setup"
	composer config repositories.wp-cli composer http://wp-cli.org/package-index/
	composer require pixline/wp-cli-theme-test-command=dev-master
	composer require danielbachhuber/wp-cli-stat-command=dev-master
	composer require humanmade/wp-remote-cli=dev-master
	composer require oxford-themes/wp-cli-git-command=dev-master
	composer require pods-framework/pods-wp-cli=dev-master
	# Link `wp` to the `/usr/local/bin` directory
else
  echo -e "${list} Updating via Composer"
	cd /srv/www/wp-cli
	composer update
fi
echo -e "${list} Symlink setup"
ln -sf /srv/www/wp-cli/bin/wp /usr/local/bin/wp
echo -e "${pass} wp-cli check"
wp --info


headinfo "Node.js setup"
if npm --version | grep -q '1.3.11'; then
  echo -e "${list} Node.js npm update"
	npm update
else
  echo -e "${list} Installing binaries.."
	wget -q -O /tmp/node-v0.10.21-linux-x86.tar.gz http://nodejs.org/dist/v0.10.21/node-v0.10.21-linux-x86.tar.gz
	tar xzf /tmp/node-v0.10.21-linux-x86.tar.gz --strip-components=1 -C /usr/local
	npm update
  echo -e "${list} Installing npm packages.."
	for npm in "${npm_packages[@]}"
	do
		echo -e "  ${list} $npm"
	  npm install -g $npm &>/dev/null
	done
fi
	
# headinfo "Compiling and installing Redis"
# wget -q -O /tmp/redis-2.6.16.tar.gz http://download.redis.io/releases/redis-2.6.16.tar.gz
# tar xzf /tmp/redis-2.6.16.tar.gz /tmp/redis-2.6.16
# cd /tmp/redis-2.6.16
# make

# services
headinfo "Percona Server (MySQL) Configuration"
if [ ! -f /etc/mysql/my.cnf ]; then
#	mv /etc/mysql/my.cnf /etc/mysql/my.cnf-backup
  echo -e "${list} my.cnf setup"
	ln -s /srv/config/my.cnf /etc/mysql/my.cnf
	echo -e "${list} Restart service"
	service mysql restart
	mysql -u root -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
	mysql -u root -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
	mysql -u root -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
fi
if [ -f /srv/database/init-custom.sql ]
then
  # Create the databases (unique to system) that will be imported with
  # the mysqldump files located in database/backups/
  echo -e "${list} Custom MySQL setup..."
	mysql -u root < /srv/database/init-custom.sql
else
  # Setup MySQL by importing an init file that creates necessary
  # users and databases that our vagrant setup relies on.
  echo -e "${list} Default MySQL setup.."
  mysql -u root < /srv/database/init.sql
fi
# Process each mysqldump SQL file in database/backups to import 
# an initial data set for MySQL.
/srv/database/import-sql.sh

headinfo "Nginx configuration"
if [ ! -f /etc/nginx/nginx-wp-common.conf ]; then
  cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf-default
	echo -e "${list} /etc/nginx/nginx.conf"
  ln -sf /srv/config/nginx/nginx.conf /etc/nginx/nginx.conf
	echo -e "${list} /etc/nginx/nginx-wp-common.conf"
  ln -sf /srv/config/nginx/nginx-wp-common.conf /etc/nginx/nginx-wp-common.conf
	echo -e "${list} /etc/nginx/custom-sites"
  ln -sf /srv/config/nginx/sites /etc/nginx/custom-sites
fi
if [ ! -e /etc/nginx/server.key ]; then
  echo -e "${list} Generate Nginx server private key..."
  vvvgenrsa=`openssl genrsa -out /etc/nginx/server.key 2048 2>&1`
  echo $vvvgenrsa
fi
if [ ! -e /etc/nginx/server.csr ]; then
  echo -e "${list} Generate Certificate Signing Request (CSR)..."
  openssl req -new -batch -key /etc/nginx/server.key -out /etc/nginx/server.csr
fi
if [ ! -e /etc/nginx/server.crt ]; then
  echo -e "${list} Sign the certificate using the above private key and CSR..."
  vvvsigncert=`openssl x509 -req -days 365 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>&1`
  echo $vvvsigncert
fi

headinfo "PHP5 configuration"
echo -e "${list} Disable xdebug"
php5dismod xdebug
echo -e "${list} pool.d/www.conf"
ln -sf /srv/config/php5/www.conf /etc/php5/fpm/pool.d/www.conf
echo -e "${list} conf.d/php-custom.ini"
ln -sf /srv/config/php5/php-custom.ini /etc/php5/fpm/conf.d/php-custom.ini
echo -e "${list} conf.d/xdebug.ini"
ln -sf /srv/config/php5/xdebug.ini /etc/php5/fpm/conf.d/xdebug.ini
echo -e "${list} conf.d/apc.ini"
ln -sf /srv/config/php5/apc.ini /etc/php5/fpm/conf.d/apc.ini

# cleaning
headinfo "Housekeeping and service restart"
echo -e "${list} APT cache cleaning"
apt-get autoclean
apt-get autoremove
rm -f /var/cache/apt/archives/*.deb
echo -e "${list} Restarting services.."
service memcached restart
service mysql restart
service nginx restart
service php5-fpm restart

# WP #1: theme test setup
headinfo "WordPress setup #1: Theme test drive"
if [ ! -d /srv/www/theme-test ]
then
  echo -e "${list} WordPress setup"
	mkdir /srv/www/theme-test
	chown www-data:www-data /srv/www/theme-test
	cd /srv/www/theme-test
	wp core download --locale=it_IT
	wp core config --dbname=wp_themetest --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
define( "WP_DEBUG", true );
PHP
	wp core install --url=themetest.debrant.dev --quiet --title="Theme Test Drive" --admin_user=admin --admin_email="admin@themetest.debrant.dev" --admin_password="password"
  echo -e "${list} Theme test data & plugin setup"
  wp theme-test install --plugin=all
  
  echo -e "${list} Shared plugins & themes folders setup"
  ln -s /srv/shared/plugins /srv/www/theme-test/wp-content/plugins/_shared
  ln -s /srv/shared/themes /srv/www/theme-test/wp-content/themes/_shared

  echo -e "${list} Memcached object cache setup"
  dlurl='http://plugins.svn.wordpress.org/memcached/tags/2.0.2/object-cache.php'
  wget -q -O /srv/www/theme-test/wp-content/object-cache.php $dlurl
else
  echo -e "${list} WordPress update"
	cd /srv/www/theme-test
  wp core update
  wp core update-db
  wp plugin update --all
  wp theme update --all
fi


# WP #2: network setup
headinfo "WordPress setup #2: Network"
if [ ! -d /srv/www/network ]
then
	mkdir /srv/www/network
	chown www-data:www-data /srv/www/network
	cd /srv/www/network
  echo -e "${list} WordPress setup"
	wp core download --locale=it_IT
	wp core config --dbname=wp_network --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
define( "WP_DEBUG", true );
PHP
	wp core multisite-install --url=network.debrant.dev --quiet --title="Debrant Network" --admin_user=admin --admin_email="admin@network.debrant.dev" --admin_password="password"
  
  echo -e "${list} Shared plugins & themes folders setup"
  ln -s /srv/shared/plugins /srv/www/network/wp-content/plugins/_shared
  ln -s /srv/shared/themes /srv/www/network/wp-content/themes/_shared

  echo -e "${list} Memcached object cache setup"
  dlurl='http://plugins.svn.wordpress.org/memcached/tags/2.0.2/object-cache.php'
  wget -q -O /srv/www/network/wp-content/object-cache.php $dlurl
else
  echo -e "${list} WordPress update"
	cd /srv/www/network
  wp core update
  wp core update-db
  wp plugin update --all
  wp theme update --all
fi


cat <<BRANDING > /etc/motd
______     _                     _   
|  _  \   | |                   | |  
| | | |___| |__  _ __ __ _ _ __ | |_ 
| | | / _ \ '_ \| '__/ _\` | '_ \| __|
| |/ /  __/ |_) | | | (_| | | | | |_ 
|___/ \___|_.__/|_|  \__,_|_| |_|\__|

BRANDING

headinfo "Your ${txtred}Debrant${txtreset}${bldwht} is ready, enjoy!"
end_seconds=`date +%s`
echo -e "${txtwht}Documentation and issue tracking:"
echo -e "${txtund}https://github.com/swergroup/debrant${txtreset}"

echo -e "${txtwht}Please add this to your /etc/hosts file:"
echo -e "${txtund}192.168.13.37   debrant.dev${txtreset}"
echo -e "${txtund}192.168.13.37   themetest.debrant.dev${txtreset}"
echo -e "${txtund}192.168.13.37   network.debrant.dev${txtreset}"


echo -e "\n${txtwht}Provisioning complete in `expr $end_seconds - $start_seconds` seconds\n"
