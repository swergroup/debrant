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
 ___       __        ______  
|_ _|___ __\ \      / /  _ \ 
 | |/ __/ _ \ \ /\ / /| |_) |
 | | (_|  __/\ V  V / |  __/ 
|___\___\___| \_/\_/  |_|    
${txtrst}
WordPress + Icecast (Debrant ${txtgrn}$debrant_version${txtrst})
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
  checkinstall
	curl
	debian-keyring
	deborphan
  faad
  flac
  ffmpeg
	findutils
	gettext
	git
	git-svn
	gnupg2
	gnupg-curl
	gnu-standards
  icecast2
	imagemagick
	kexec-tools
  libdbd-mysql-perl
	libmemcache0
	libmemcached5
  libmemcached-tools
  libmysqlclient18=5.5.33-rel31.1-568.squeeze
  liquidsoap
	links
	localepurge
	lynx
  mailutils
  memcached
	mcrypt
	mlocate
  nginx
	ntp
	ntpdate
  percona-toolkit
  percona-server-client-5.5
  percona-server-common-5.5
  percona-server-server-5.5
  percona-xtrabackup
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
	rsync
	screen
  subversion
	unrar
	unzip
	vim
	wget
	zsh
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
  # debmulti
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1F41B907	2>&1 > /dev/null
  # dotdeb
  apt-key adv --keyserver keys.gnupg.net --recv-keys E9C74FEEA2098A6E	2>&1 > /dev/null
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
	aptitude purge -y ~c
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


# cleaning
headinfo "Housekeeping and service restart"
echo -e "${list} APT cache cleaning"
apt-get -y autoclean
apt-get -y autoremove
rm -f /var/cache/apt/archives/*.deb
aptitude purge -y ~c
echo -e "${list} Restarting services.."
service memcached restart
service mysql restart
service nginx restart
service php5-fpm restart

# WP #1: theme test setup
headinfo "WordPress setup"
if [ ! -d /srv/www/icewp ]
then
  echo -e "${list} Download & install WordPress"
	mkdir /srv/www/icewp
	chown www-data:www-data /srv/www/icewp
	cd /srv/www/icewp
	wp core download --locale=it_IT
	wp core config --dbname=wp_icewp --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
define( 'WP_DEBUG', true );
if ( WP_DEBUG ) {
    define( 'WP_DEBUG_LOG', true );
    define( 'WP_DEBUG_DISPLAY', false );
    @ini_set( 'display_errors', 0 );
}
PHP
	wp core install --url=icewp.debrant.dev --quiet --title="IceWP Test" --admin_user=admin --admin_email="admin@icewp.debrant.dev" --admin_password="password"
  wp option update permalink_structure "/%postname%/"
  
  echo -e "${list} Theme test data & plugin"
  wp theme-test install --plugin=all

  echo -e "${list} Default plugin bundle"
  wp plugin install mp6 --activate
  wp plugin install pods
  wp plugin install uploadplus
  wp plugin install s2member --activate
  
  echo -e "${list} Shared plugins & themes folders"
  ln -s /srv/shared/plugins /srv/www/icewp/wp-content/plugins/_shared
  ln -s /srv/shared/themes /srv/www/icewp/wp-content/themes/_shared

  echo -e "${list} Memcached object cache"
  dlurl='http://plugins.svn.wordpress.org/memcached/tags/2.0.2/object-cache.php'
  wget -q -O /srv/www/icewp/wp-content/object-cache.php $dlurl
  
  # echo -e "${list} Redis object cache"
  # ln -s /opt/wordpress-redis-backend/predis /srv/www/icewp/wp-content/predis
  # ln -s /opt/wordpress-redis-backend/object-cache.php /srv/www/icewp/wp-content/object-cache.php
else
  echo -e "${list} WordPress update"
	cd /srv/www/icewp
  wp core update
  wp core update-db
  wp plugin update --all
  wp theme update --all
fi

cat <<BRANDING > /etc/motd
 ___       __        ______  
|_ _|___ __\ \      / /  _ \ 
 | |/ __/ _ \ \ /\ / /| |_) |
 | | (_|  __/\ V  V / |  __/ 
|___\___\___| \_/\_/  |_|    
                             
BRANDING

headinfo "Your ${txtred}IceWP Debrant${txtreset}${bldwht} is ready!"

echo -e "${txtwht}Please add these to your /etc/hosts file:${txtreset}\n"
echo -e "192.168.99.99   debrant.dev${txtreset}"
echo -e "192.168.99.99   icewp.debrant.dev${txtreset}"

echo -e "\n${txtwht}Code repository and issue tracking:"
echo -e "${txtund}https://github.com/swergroup/debrant${txtreset}\n"

end_seconds=`date +%s`
echo -e "\n${txtwht}Provisioning complete in `expr $end_seconds - $start_seconds` seconds\n"
