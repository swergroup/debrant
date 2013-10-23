#!/bin/bash

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
 
# Feedback indicators
info="\n${bldblu} - ${txtrst}\n"
pass="${bldgrn} * ${txtrst}"
warn="${bldylw} ! ${txtrst}"
dead="${bldred}!!!${txtrst}"

# Debian package checklist
apt_package_check_list=(
	build-essential
	byobu
	curl
	debian-keyring
	deborphan
	findutils
	gettext
	geoip-bin
	geoip-database
	git
	git-svn
	gnupg2
	gnupg-curl
	gnu-standards
	kexec-tools
	links
	libmemcached
	localepurge
	lynx
	mcrypt
	memcached
	mlocate
	nginx-extras
	ntp
	ntpdate
	percona-toolkit
	php-pear
	php5-cli
	php5-common
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
	pound
	screen
	unar
	unrar
	unzip
	varnish
	vim
	wget
	xtrabackup
	zsh
)

pear_channels=(
	components.ez.no
  pear.phpunit.de
	pear.netpirates.net
	pear.symfony.com
)
 
pear_packages=(
  PHPDoc-0.1.0
  phpunit/PHP_CodeCoverage
  phpunit/PHP_CodeSniffer
  phpunit/PHPUnit
  phpunit/PHPUnit_Selenium
  phpunit/PHPUnit_MockObject
  phpunit/phpcov
  phpunit/phpcpd
  phpunit/phpdcd-0.9.3
  phpunit/phploc
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


if [ -f /srv/config/sources.list ]; then
	echo -e "${info} Add new APT main sources"
	unlink /etc/apt/sources.list
	ln -s /srv/config/sources.list /etc/apt/sources.list

	echo -e "${info} Add missing repostitory GPG keys"
	
	# percona server (mysql)
	apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A	
	# varnish
	wget -qO- http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

elif [ -f /srv/config/custom-sources.list ]; then	
	echo -e "${info} Add new APT custom sources"
	unlink /etc/apt/sources.list.d/custom-sources.list
	ln -s /srv/config/custom-sources.list /etc/apt/sources.list.d/custom-sources.list
fi


echo -e "${info} Checking Debrant system requirement"
for pkg in "${apt_package_check_list[@]}"
do
	if dpkg -s $pkg 2>&1 | grep -q 'Status: install ok installed';
	then 
		echo -e "${pass} $pkg already installed"
	else
		echo -e "${warn} $pkg missing"
		apt_package_install_list+=($pkg)
	fi
done

# Debian packages
if [ ${#apt_package_install_list[@]} = 0 ];
then 
	echo -e "${pass} Everything is already installed"
else
	echo -e "${info} APT init"
	aptitude purge ~c
	apt-get update --assume-yes

	echo -e "${info} APT install"
	apt-get install --force-yes --assume-yes ${apt_package_install_list[@]}

	apt-get clean
fi


if composer --version | grep -q 'Composer version';
then
	printf "Updating Composer...\n"
	composer self-update
else
	printf "Installing Composer...\n"
	curl -sS https://getcomposer.org/installer | php
	chmod +x composer.phar
	mv composer.phar /usr/local/bin/composer
fi

if scrutinizer --version | grep -q 'scrutinizer version';
then
	printf "Updating Scrutinizer...\n"
	scrutinizer self-update
else
	printf "Installing Scrutinizer...\n"
	wget .O /usr/local/bin/scrutinizer https://scrutinizer-ci.com/scrutinizer.phar
	chmod +x /usr/local/bin/scrutinizer
fi

echo -e "${info} PEAR upgrade"
pear config-set auto_discover 1
for chan in "${pear_channels[@]}"
do
  pear channel-discover $chan
done
 
echo -e "${info} Installing PEAR packages"
for pearpkg in "${pear_packages[@]}"
do
  pear install -a $pearpkg
done
 
echo -e "${info} Installing Node.js packages"
for npm in "${npm_packages[@]}"
do
  npm install -g $npm
done


if [ ! -d /srv/www/wp-cli ]
then
	echo -e "${info} Downloading wp-cli"
	git clone git://github.com/wp-cli/wp-cli.git /srv/www/wp-cli
	cd /srv/www/wp-cli
	composer install
else
	echo -e "${info} Updating wp-cli"
	cd /srv/www/wp-cli
	git pull --rebase origin master
fi
# Link `wp` to the `/usr/local/bin` directory
ln -sf /srv/www/wp-cli/bin/wp /usr/local/bin/wp



# cleaning
echo -e "${info} Cleaning"
apt-get autoclean
apt-get autoremove
rm -f /var/cache/apt/archives/*.deb

#printf "\n\e[36m  * Choosing the faster APT mirror.. \n\n\e[39m"
#netselect-apt -n -c IT -o /etc/apt/sources.list

end_seconds=`date +%s`
echo -----------------------------
echo -e "${pass} Provisioning complete in `expr $end_seconds - $start_seconds` seconds\n"
