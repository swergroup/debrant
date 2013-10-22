#!/bin/bash

# running time measure
start_seconds=`date +%s`
# network check
ping_result=`ping -c 2 8.8.8.8 2>&1`
# architecture
arch=`uname -m`
# Script URLs
GUEST_URL="https://gist.github.com/pixline/6981710/raw/5bcc702616a8253b0ed90889dd31529962a89c37/guest-account.sh"
LIGHTDM_URL="https://gist.github.com/pixline/6981787/raw/d16dadb2e21d3ba8e0168fc455004ea621cd8a33/lightdm.conf"
FLASHLIB_URL="https://cloudup.com/files/ikffRQ0X7G8/download"
DO_FC_CACHE=false

# Debian package checklist
apt_package_check_list=(
	bleachbit
	build-essential
	byobu
	ca-certificates
	chromium-browser
	chromium-browser-l10n
	curl
	debian-multimedia-keyring
	deborphan
	eog
	evince
	faad
	ffmpeg
	findutils
	gettext
	gimp
	gimp-gutenprint
	gimp-help-it
	gimp-plugin-registry
	gpaint
	git
	git-svn
	gnupg2
	gnupg-curl
	grml-rescueboot
	hyphen-it
	iceweasel
	kexec-tools
	lame
	libnss3-tools
	libqt4-dbus
	libqt4-network
	libqt4-xml
	libqtcore4
	libqtwebkit4
	libqtdbus4
	libqtgui4
	libreoffice-l10n-it
	libreoffice-writer2xhtml
	libreoffice-writer
	lightdm
	links
	localepurge
	lynx
	midori
	mlocate
	module-assistant
	mplayer2
	mplayer-gui
	myspell-it
	netselect
	netselect-apt
	ntp
	ntpdate
	orage
	parole
	parted
	pidgin
	pidgin-awayonlock
	pidgin-encryption
	pidgin-otr
	pidgin-sipe
	pidgin-skype
	pidgin-twitter
	pidgin-plugin-pack
	qdbus
	remmina
	remmina-plugin-vnc
	ristretto
	screen
	samba-tools
	smbc
	smbclient
	smbnetfs
	terminator
	thunar-archive-plugin
	thunar-media-tags-plugin
	thunar-volman
	ttf-mscorefonts-installer
	ttf-xfree86-nonfree
	unar
	unoconv
	unrar
	unzip
	vim
	vlc
	vlc-plugin-pulse
	vlc-plugin-sdl
	wget
	x264
	xfconf
	xfce4-datetime-plugin
	xfce4-goodies
	xfce4-mount-plugin
	xfce4-utils
	xfce4-places-plugin
	xfce4-session
	xfce4-settings
	xfce4-volumed
	xchat
	xfdesktop4
	xfe
	xfprint4
	xfwm4
	xfwm4-themes
	xscreensaver-screensaver-bsod
	zsh
)

if [ ! -f /etc/apt/sources.list.d/deb-multimedia.list ]; then
	printf "\n\n\e[36m  * Adding Deb Multimedia repository..\n\n"
	gpg --keyserver pgp.mit.edu --recv-keys 1F41B907
	gpg --armor --export 1F41B907 | apt-key add -

	echo '
deb http://mirror3.mirror.garr.it/mirrors/deb-multimedia stable main
deb-src http://mirror3.mirror.garr.it/mirrors/deb-multimedia stable main
	' > /etc/apt/sources.list.d/deb-multimedia.list
fi

printf "\n\n\e[36m  * Checking required packages..\n\n"
for pkg in "${apt_package_check_list[@]}"
do
	if dpkg -s $pkg 2>&1 | grep -q 'Status: install ok installed';
	then 
		printf "\e[39m $pkg already installed\n"
	else
		printf "\e[31m $pkg not yet installed\n"
		apt_package_install_list+=($pkg)
	fi
done

# Debian packages
if [ ${#apt_package_install_list[@]} = 0 ];
then 
	printf "\n\n\e[32m  * No packages to install.\n\n"
else
	printf "\n\n\e[36m  * Preparing for apt-get....\n\n\e[39m"
	aptitude purge ~c
	apt-get update --assume-yes

	printf "\n\n\e[36m  * Installing apt-get packages...\n\n\e[39m"
	apt-get install --force-yes --assume-yes ${apt_package_install_list[@]}

	apt-get clean
	update-alternatives --set x-www-browser /usr/bin/chromium
fi

# Lightdm setup
if [ ! -f /etc/lightdm/_old-lightdm.conf ]; then
	printf "\e[36m  * Setting Lightdm guest support\n\n\e[39m"
	ln -s /usr/lib/i386-linux-gnu/lightdm/ /usr/lib/lightdm
	wget -O /usr/sbin/guest-account $GUEST_URL
	chmod +x /usr/sbin/guest-account
	git clone git://github.com/pixline/lightdm-guest-session/ /tmp/lightdm-guest
	cd /tmp/lightdm-guest
	/tmp/lightdm-guest/install.sh
	cp /etc/lightdm/lightdm.conf /etc/lightdm/_old-lightdm.conf
	wget -O /etc/lightdm/lightdm.conf $LIGHTDM_URL
	rm -fr /tmp/lightdm-guest
else
	printf "\e[32m  * Lightdm already configured\n\n\e[39m"
fi

# Flash player ovewrite (obsolete CPUs)
CHECK_FLASH=`dpkg -s flashplugin-nonfree 2>&1 | grep -q 'Status: install ok installed'`
CHECK_SSE2=`grep --quiet sse2 /proc/cpuinfo`
if [ ! $CHECK_FLASH ]; then
	printf "\e[32m  * Flash player already installed\n\n"
else
	printf "\e[36m  * Installing Flash player\n\n"
  apt-get install flashplugin-nonfree
	if [ ! $CHECK_SSE2 ]; then
		printf "\e[36m  * Patching Flash player with old CPU support\n\n"
		wget -O /tmp/libflashplayer.so.bz2 $FLASHLIB_URL
		unar -o /tmp/ /tmp/libflashplayer.so.bz2
		cp /tmp/libflashplayer.so /usr/lib/flashplugin-nonfree/libflashplayer.so
		rm -fr /tmp/libflashplayer.so	
	fi
fi

# Fonts!
if [ ! -d /usr/share/fonts/truetype/font_win_mac ]; then
	printf "\e[39m  * Installing Win/Mac fonts \n\n"
	wget -O /tmp/Font_Win_Mac_LffL.tar.gz http://sourceforge.net/projects/linuxfreedomfor/files/font/Font_Win_Mac_LffL.tar.gz
	cd /tmp
	tar xzvf /tmp/Font_Win_Mac_LffL.tar.gz
	mv Font_Win_Mac_LffL/ /usr/share/fonts/truetype/font_win_mac
	rm -fr /tmp/Font_Win_Mac_LffL.tar.gz
	DO_FC_CACHE=true
else
	printf "\e[32m  * Win/Mac fonts already installed \n\n\e[39m"
fi

if [ ! -d /usr/share/fonts/truetype/googlefontdirectory ]; then
	printf "\e[39m  * Installing Google fonts \n\n"
	wget -O /tmp/googlefontdirectory.zip http://sourceforge.net/projects/linuxfreedomfor/files/Font/googlefontdirectory.zip
	cd /tmp
	unar googlefontdirectory.zip
	mv googlefontdirectory/ /usr/share/fonts/truetype/googlefontdirectory
	rm -fr /tmp/googlefontdirectory.zip
	DO_FC_CACHE=true
else
	printf "\e[32m  * Google fonts already installed \n\n\e[39m"
fi

if [ $DO_FC_CACHE == true ]; then
	printf "\e[36m  * Rebuilding font cache \n\n\e[39m"
	fc-cache -fv
else
	printf "\e[32m  * Skipping font cache rebuild \n\n\e[39m"
fi

# Skype
if [ ! -f /usr/bin/skype ]; then
	printf "\e[39m  * Installing Skype \n\n"
	wget -O /tmp/skype-install.deb http://www.skype.com/go/getskype-linux-deb
	dpkg -i /tmp/skype-install.deb
	rm -f /tmp/skype-install.deb
else
	printf "\e[32m  * Skype already installed \n\n\e[39m"
fi


printf "\e[36m  * APT update + missing dependencies install \n\n\e[39m"
apt-get update
apt-get -f install

# GRML rescue boot
if [ ! -f /boot/grml/grml32-small_2013.09.iso ]; then
	printf "\n\n\e[39m  * Installing GRML Rescue Boot \n\n"
	rm /boot/grml/grml*
	wget -O /boot/grml/grml32-small_2013.09.iso http://download.grml.org/grml32-small_2013.09.iso
	update-grub
else
	printf "\n\n\e[32m  * GRML Rescue boot already installed \n\n"
fi

# autistici/inventati CA root certificate
if [ ! -f /usr/local/share/ca-certificates/autistici-ca.crt ]; then
	printf "\e[39m  * Installing Autistici/Inventati Certification Authority \n\n"
	wget -O /tmp/autistici-ca.crt http://autistici.org/static/certs/ca.crt
	cp /tmp/autistici-ca.crt /usr/local/share/ca-certificates/autistici-ca.crt
	update-ca-certificates
	certutil -d sql:/etc/skel/.pki/nssdb -A -t TC -n "autistici/inventati CA" -i /tmp/autistici-ca.crt
	rm -f /tmp/autistici-ca.crt
else
	printf "\e[32m  * Autistici/Inventati Certification Authority already installed \n\n"
fi

# cleaning
printf "\e[36m  * Final APT cleaning \n\n\e[39m"
apt-get autoclean
apt-get autoremove
rm -f /var/cache/apt/archives/*.deb

#printf "\n\e[36m  * Choosing the faster APT mirror.. \n\n\e[39m"
#netselect-apt -n -c IT -o /etc/apt/sources.list

end_seconds=`date +%s`
echo -----------------------------
printf "\n\n\e[32m Provisioning complete in `expr $end_seconds - $start_seconds` seconds\n"
printf "\e[32m Please HALT (do not reboot this time) then enjoy your brand new internet point! \n\n\e[39m"
