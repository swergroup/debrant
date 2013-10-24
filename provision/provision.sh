#!/bin/bash

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
 
# Feedback indicators
info="\n${bldblu} % ${txtrst}"
list="${bldcyn} - ${txtrst}"
pass="${bldgrn} * ${txtrst}"
warn="${bldylw} ! ${txtrst}"
dead="${bldred}!!!${txtrst}"

function headinfo {
	echo -e ""
	echo -e "${txtrst}${bldblu}###${txtrst} ${bldwht}$1${txtrst}"
}

echo -e "
${bldred}
______     _                     _   
|  _  \   | |                   | |  
| | | |___| |__  _ __ __ _ _ __ | |_ 
| | | / _ \ '_ \| '__/ _\` | '_ \| __|
| |/ /  __/ |_) | | | (_| | | | | |_ 
|___/ \___|_.__/|_|  \__,_|_| |_|\__|
${txtrst}
Debian-based Vagrant ${txtgrn}0.1.1${txtrst}
${txtund}https://github.com/swergroup/debrant${txtreset}
"

# running time measure
start_seconds=`date +%s`
# network check
ping_result=`ping -c 2 8.8.8.8 2>&1`

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
#	libmysqlclient18=5.5.33-rel31.1-569.wheezy
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
  grunt-asciify
  grunt-cli
  grunt-contrib-uglify
  grunt-contrib-compress
  grunt-contrib-csslint
  grunt-contrib-imagemin
  grunt-css
  grunt-curl
  grunt-jslint
  grunt-rsync
  grunt-phpcs
  grunt-phpdocumentor
  grunt-phplint
  grunt-shell
)


export DEBIAN_FRONTEND=noninteractive

if [ -f /etc/apt/sources.list.d/grml.list ]; then
	sudo rm /etc/apt/sources.list.d/grml.list
fi

if [ -f /srv/config/sources.list ]; then
	headinfo "Add new APT main sources"
	unlink /etc/apt/sources.list
	ln -s /srv/config/sources.list /etc/apt/sources.list

	headinfo "APT repositories GPG keys"
	# percona server (mysql)
	apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A	2>&1 > /dev/null

	# varnish
	wget -qO- http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

elif [ -f /srv/config/custom-sources.list ]; then	
	headinfo "Add new APT custom sources"
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

headinfo "Checking Debrant system requirement"
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

# Debian packages
if [ ${#apt_package_install_list[@]} = 0 ];
then 
	headinfo "Skip APT install"
else
	headinfo "APT install"
	aptitude purge ~c
	apt-get update --assume-yes
	apt-get install --force-yes --assume-yes ${apt_package_install_list[@]}
	apt-get clean
fi

if which composer;
then
	headinfo "Updating Composer"
	composer self-update
else
	headinfo "Installing Composer"
	curl -sS https://getcomposer.org/installer | php
	chmod +x composer.phar
	mv composer.phar /usr/local/bin/composer
	composer --version
fi

if which scrutinizer;
then
	headinfo "Updating Scrutinizer"
	scrutinizer self-update
else
	headinfo "Installing Scrutinizer"
	wget -q -O /usr/local/bin/scrutinizer https://scrutinizer-ci.com/scrutinizer.phar
	chmod +x /usr/local/bin/scrutinizer
	scrutinizer --version
fi

headinfo "Discover PEAR channels"
pear config-set auto_discover 1
for chan in "${pear_channels[@]}"
do
  pear -q channel-discover $chan
done
pear -q update-channels
 
headinfo "Install/upgrade PEAR packages"
for pearpkg in "${pear_packages[@]}"
do
	echo -e "${list} $pearpkg $(pear -q install -a $pearpkg 2>&1 > /dev/null)"
done
pear -q upgrade-all


if [ ! -d /srv/www/wp-cli ]
then
	headinfo "Downloading wp-cli"
	git clone git://github.com/wp-cli/wp-cli.git /srv/www/wp-cli
	cd /srv/www/wp-cli
	composer install
	composer config repositories.wp-cli composer http://wp-cli.org/package-index/
	composer require pixline/wp-cli-theme-test-command=dev-master
	composer require danielbachhuber/wp-cli-stat-command=dev-master
	composer require humanmade/wp-remote-cli=dev-master
	composer require oxford-themes/wp-cli-git-command=dev-master
	composer require pods-framework/pods-wp-cli=dev-master
	# Link `wp` to the `/usr/local/bin` directory
else
	headinfo "Updating wp-cli"
	cd /srv/www/wp-cli
	composer update
fi
ln -sf /srv/www/wp-cli/bin/wp /usr/local/bin/wp


if npm --version | grep -q '1.3.11'; then
	headinfo "Node.js already installed: npm update"
	npm update
else
	headinfo "Installing Node.js"
	wget -q -O /tmp/node-v0.10.21-linux-x86.tar.gz http://nodejs.org/dist/v0.10.21/node-v0.10.21-linux-x86.tar.gz
	tar xzf /tmp/node-v0.10.21-linux-x86.tar.gz --strip-components=1 -C /usr/local
	npm update
	headinfo "Installing Node.js packages"
	for npm in "${npm_packages[@]}"
	do
		echo -e "${list} $npm"
	  npm install -g $npm 2>&1 > /dev/null
	done
fi
	
# Configuration for nginx
if [ ! -e /etc/nginx/server.key ]; then
        headinfo "Generate Nginx server private key..."
        vvvgenrsa=`openssl genrsa -out /etc/nginx/server.key 2048 2>&1`
        echo $vvvgenrsa
fi
if [ ! -e /etc/nginx/server.csr ]; then
        headinfo "Generate Certificate Signing Request (CSR)..."
        openssl req -new -batch -key /etc/nginx/server.key -out /etc/nginx/server.csr
fi
if [ ! -e /etc/nginx/server.crt ]; then
        headinfo "Sign the certificate using the above private key and CSR..."
        vvvsigncert=`openssl x509 -req -days 365 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>&1`
        echo $vvvsigncert
fi


#branding
cat <<BRANDING > /etc/motd
______     _                     _   
|  _  \   | |                   | |  
| | | |___| |__  _ __ __ _ _ __ | |_ 
| | | / _ \ '_ \| '__/ _\` | '_ \| __|
| |/ /  __/ |_) | | | (_| | | | | |_ 
|___/ \___|_.__/|_|  \__,_|_| |_|\__|
                                     
BRANDING

# services
headinfo "Percona Server (MySQL) Configuration"
if [ ! -f /etc/mysql/my.cnf ]; then
#	mv /etc/mysql/my.cnf /etc/mysql/my.cnf-backup
	ln -s /srv/config/my.cnf /etc/mysql/my.cnf
	service mysql restart
	mysql -u root -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
	mysql -u root -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
	mysql -u root -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
fi

# WP #1: theme test setup
if [ ! -d /srv/www/theme-test ]
then
	headinfo "Installing WordPress theme test setup"
  echo "create database if not exists wp_themetest" | mysql -u root
	mkdir /srv/www/theme-test
	chown www-data:www-data /srv/www/theme-test
	cd /srv/www/theme-test
	wp core download --locale=it_IT
	wp core config --dbname=wp_themetest --dbuser=root --dbpass='' --quiet --extra-php <<PHP
define( "WP_DEBUG", true );
PHP
	wp core install --url=debrant.themetest.dev --quiet --title="Theme Test Drive" --admin_name=admin --admin_email="admin@themetest.debrant.dev" --admin_password="password"
  wp theme-test install --plugin=all
  ln -s /srv/shared/plugins /srv/www/theme-test/wp-content/plugins/_shared
  ln -s /srv/shared/themes /srv/www/theme-test/wp-content/themes/_shared
else
	headinfo "Update WordPress theme test setup"
	cd /srv/www/theme-test
  wp core update
  wp core update-db
  wp plugin update --all
  wp theme update --all
fi

# cleaning
headinfo "Final housekeeping"
apt-get autoclean
apt-get autoremove
rm -f /var/cache/apt/archives/*.deb

headinfo "Your ${txtred}Debrant${txtreset}${bldwht} is ready, enjoy!"
end_seconds=`date +%s`
echo -e "\n${txtwht}Documentation and issue tracking:"
echo -e "${txtund}https://github.com/swergroup/debrant${txtreset}"
echo -e "\n${txtwht}Provisioning complete in `expr $end_seconds - $start_seconds` seconds\n"
