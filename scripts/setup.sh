#!/bin/bash
#
# setup,sh
# (c) 2010.05 - Phil Miller <philm[at]chakra-project[dot]org
# (c) 2010.01-04 - Jan Mette
# GPL



#
# globals
#
# version
VER="0.4.4.52"

# svn root dir (that contains the packages and _buildscripts dirs)
SVNBASE="svn://konnektion.ath.cx:1235/packages"

# packages root dir (that contains the different repos)
PKGSOURCE="http://konnektion.ath.cx/repo"

# the primary branch, either core or core-testing
PRIMARYCORE="core-testing"

# the root of everything
BASENAME="buildroot"



#
# output functions
#
get_colors() {
    _r="\033[00;31m"
    _y="\033[00;33m"
    _g="\033[00;32m"
    _b="\033[00;34m"
    _B="\033[01;34m"
    _W="\033[01;37m"
    _n="\033[00;0m"
}

title() {
	local mesg=$1; shift
	echo " "
	printf "\033[1;0m>>\033[1;1m ${mesg}\033[1;0m\n"
	echo " "
}

title2() {
	local mesg=$1; shift
	printf "\033[1;33m>>\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
}

msg() {
	local mesg=$1; shift
	echo -e "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

question() {
	local mesg=$1; shift
	echo -e -n "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

notice() {
	local mesg=$1; shift
	echo -e -n ":: ${mesg}\n"
}

warning() {
	local mesg=$1; shift
	printf "\033[1;33m::\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
}

error() {
	local mesg=$1; shift
	printf "\033[1;31m::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

newline() {
	echo " "
}

status_start() {
	local mesg=$1; shift
	echo -e -n "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

status_ok() {
	echo -e "\033[1;32m OK \033[1;0m"
}

status_done() {
	echo -e "\033[1;32m DONE \033[1;0m"
}


msg ":: starting up, this could take some secs..."


#
# setup
#
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
REPO=`echo $1`
ARCH=`echo $2`
if [ "$ARCH" = "x86_64" ] ; then
   BUILDARCH="x86-64"
else
   BUILDARCH="$ARCH"
fi
USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
USERID=`getent passwd $USER | cut -d: -f3`
PROGRESSBAR="/tmp/chakra-buildscripts.progress"

BASEPATH=`echo $CURDIR/$BASENAME`
REPO_CHECK=`svn ls $SVNBASE | grep -v "_" | sed 's/\///g'`
SVN_BUILDSYS="$SVNBASE/_buildscripts"
SVN_REPO="$SVNBASE/${REPO}"

mkdir -p $BASEPATH
rm -rf $BASEPATH/pacman.conf



#
# "detect" distro
#
if [ -e "/etc/arch-release" ] ; then
	echo ":: running on arch linux"
	DISTRO="arch"
elif [ -e "/etc/debian_version" ] ; then
	DEB_VER=`cat /etc/debian_version`
	echo ":: running on debian $DEB_VER"
	unset DEB_VER
	DISTRO="debian" # debian stable
else
	echo ":: running on a unsupported linux distro"
	echo ":: (everything could happen from here...)"
	DISTRO="unsupported"
fi



#
# look for pacman
#
if [ -e "/usr/bin/pacman.static" ] ; then
	PACMAN_BIN="pacman.static"
	echo ":: using pacman.static"
elif [ -e "/usr/bin/pacman" ] ; then
	PACMAN_BIN="pacman"
	echo ":: using pacman"
else
	echo ":: you need either pacman or pacman.static in /usr/bin"
	echo ":: can not proceed, stopping... "
	exit 0
fi



#
# helper functions
#
# messages
title() {
	local mesg=$1; shift
	echo " "
	printf "\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
	echo " "
}

title2() {
	local mesg=$1; shift
	printf "\033[1;33m>>\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
}

msg() {
	local mesg=$1; shift
	echo -e "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

question() {
	local mesg=$1; shift
	echo -e -n "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

notice() {
	local mesg=$1; shift
	echo -e -n ":: ${mesg}\n"
}

warning() {
	local mesg=$1; shift
	printf "\033[1;33m::\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
}

error() {
	local mesg=$1; shift
	printf "\033[1;31m::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

newline() {
	echo " "
}

status_start() {
	local mesg=$1; shift
	echo -e -n "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

status_ok() {
	echo -e "\033[1;32m OK \033[1;0m"
}

status_done() {
	echo -e "\033[1;32m DONE \033[1;0m"
}

# mounting
mount_special() {
	sudo mount -v /dev/ $BASEPATH/${REPO}-${ARCH}/chroot/dev/ --bind &>/dev/null
	sudo mount -v /sys/ $BASEPATH/${REPO}-${ARCH}/chroot/sys/ --bind &>/dev/null
	sudo mount -v /proc/ $BASEPATH/${REPO}-${ARCH}/chroot/proc/ --bind &>/dev/null
	sudo mount -v $BASEPATH/_cache $BASEPATH/${REPO}-${ARCH}/chroot/var/cache/pacman/pkg --bind &>/dev/null
}

umount_special() {
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/dev/ &>/dev/null
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/sys/ &>/dev/null
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/proc/ &>/dev/null
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/var/cache/pacman/pkg &>/dev/null
}

# needs to be simplified
create_pacmanconf() {
	echo " " >> $BASEPATH/pacman.conf
	echo "[options]" >> $BASEPATH/pacman.conf
	echo "HoldPkg=pacman glibc" >> $BASEPATH/pacman.conf
	echo "SyncFirst=pacman" >> $BASEPATH/pacman.conf
	echo " " >> $BASEPATH/pacman.conf

	if [ "$REPO" = "core" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "core-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "platform" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/platform/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "platform-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/platform-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "desktop" ] ; then
		echo "[core]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/platform/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[desktop]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/desktop/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "desktop-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/platform-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[desktop-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/desktop-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "apps" ] ; then
		echo "[core]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/platform/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[desktop]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/desktop/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[apps]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/apps/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "apps-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/platform-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[desktop-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/desktop-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[apps-testing]" >> $BASEPATH/pacman.conf
		echo "Server=$PKGSOURCE/apps-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
	fi
}

# 

echo ":: creating pacman.conf"
create_pacmanconf

echo ":: loading package information"
COREPKGS=`sudo LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Syl $PRIMARYCORE | cut -d " " -f 2 | grep -e "Synchronizing" -e "core-testing" -v | grep -e ".db.tar." -e "platform-testing" -v`


#
# main functions
#
########################################################################################################
# create the chroot
########################################################################################################

check_chroot()
{
	if [ -d "$BASEPATH/${REPO}-${ARCH}" ] ; then
		newline
		error "The ${REPO}-${ARCH} chroot already exists. Do you want to"
		newline
		msg "(d)elete and reinstall ${REPO}-${ARCH}?"
		msg "(u)ninstall ${REPO}-${ARCH}?"	
		question "(q)uit this script? "
		
		read option
			case $option in
				d* ) 
					newline
					status_start "deleting ${REPO}-${ARCH}  "
						cd $BASEPATH
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/dev/ &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/sys/ &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/proc/ &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/_buildscripts &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/_sources &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/var/cache/pacman/pkg &>/dev/null
						sudo rm -rf -v $BASEPATH/_buildscripts/${REPO}-${ARCH}-*.conf &>/dev/null
						sudo rm -rf -v $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-*.conf &>/dev/null
						sudo rm -rf -v $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg*.conf.* &>/dev/null
						sudo -v
						sudo rm -rf -v $BASEPATH/${REPO}-${ARCH}/pkgbuilds &>/dev/null
						sudo rm -rf -v $BASEPATH/${REPO}-${ARCH}/packages &>/dev/null
						sudo rm -rf -v $BASEPATH/${REPO}-${ARCH}/chroot &>/dev/null
						sudo -v
					status_done
				;;
			
				u* ) 
					newline
					status_start "uninstalling ${REPO}-${ARCH}  "
						cd $BASEPATH
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/dev/ &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/sys/ &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/proc/ &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/_buildscripts &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/_sources &>/dev/null
						sudo umount -v $BASEPATH/${REPO}-${ARCH}/chroot/var/cache/pacman/pkg &>/dev/null
						sudo rm -rf -v $BASEPATH/_buildscripts/${REPO}-${ARCH}-*.conf &>/dev/null
						sudo rm -rf -v $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-*.conf &>/dev/null
						sudo rm -rf -v $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg*.conf.* &>/dev/null
						sudo -v
						sudo rm -rf -v $BASEPATH/${REPO}-${ARCH}/pkgbuilds &>/dev/null
						sudo rm -rf -v $BASEPATH/${REPO}-${ARCH}/packages &>/dev/null
						sudo rm -rf -v $BASEPATH/${REPO}-${ARCH}/chroot &>/dev/null
						sudo -v
					status_done
					newline
					exit 1
				;;
				
				q* )   
					newline
					msg "bye!"
					newline
					exit 1
				;;
			esac
	fi
}

create_chroot()
{
	newline
	title "Creating Chroot: ${REPO}-${ARCH}"

	newline
	status_start "creating special dirs"
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/dev 
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/sys 
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/proc 
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/var/cache/pacman/pkg 
	status_done
	
	status_start "mounting special dirs"
		mount_special
	status_done

	status_start "creating pacman dirs"
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/var/lib/pacman &>/dev/null
	status_done

	# this is really dumb
	if [ "$REPO" = "core" ] ; then

		msg "installing core packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "core-testing" ] ; then

		msg "installing core-testing packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "platform" ] ; then

		msg "installing core-testing packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing platform packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl platform | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy $PLATFORMPKGS 
		unset PLATFORMPKGS

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "platform-testing" ] ; then

		msg "installing core-testing packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing platform-testing packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl platform-testing | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "desktop-testing" ] ; then
		# NOTE: tmp fix.
                # sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy base-devel cmake subversion git sudo xorg boost vi vim ccache rsync

		msg "installing core-testing packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing platform packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl platform-testing | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing desktop packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl desktop-testing | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "apps-testing" ] ; then
		# NOTE: tmp fix.
                # sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy base-devel cmake subversion git sudo xorg boost vi vim ccache rsync

		msg "installing core-testing packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing platform packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl platform-testing | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing desktop packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl desktop-testing | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing apps packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf --cachedir $BASEPATH/_cache -Sl apps-testing | cut -d " " -f 2 | grep -v ".db.tar."`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH}/chroot --cachedir $BASEPATH/_cache -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline
	fi

	status_start "configuring system"
		mkdir $BASEPATH/${REPO}-${ARCH}/chroot/etc/ &>/dev/null
		sudo cp /etc/resolv.conf $BASEPATH/${REPO}-${ARCH}/chroot/etc/ &>/dev/null
		sudo cp $BASEPATH/pacman.conf $BASEPATH/${REPO}-${ARCH}/chroot/etc/ &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/etc/pacman.d &>/dev/null
		sudo cp /etc/pacman.d/mirrorlist $BASEPATH/${REPO}-${ARCH}/chroot/etc/pacman.d/ &>/dev/null
	status_done

	newline
	title "User setup"

	status_start "adding user: $USER"
		sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot useradd -g users -u $USERID -G audio,video,optical,storage,log -m $USER &>/dev/null
	status_done

		warning "you will be asked to enter a password for the chroot user"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline
		
		sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot passwd $USER

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	status_start "setting up /etc/sudoers"
		sudo chmod 777 $BASEPATH/${REPO}-${ARCH}/chroot/etc/sudoers
		sudo echo >>$BASEPATH/${REPO}-${ARCH}/chroot/etc/sudoers
		sudo echo "$USER     ALL=(ALL) NOPASSWD: ALL" >>$BASEPATH/${REPO}-${ARCH}/chroot/etc/sudoers
		sudo chmod 0440 $BASEPATH/${REPO}-${ARCH}/chroot/etc/sudoers
	status_done

	status_start "setting up device permissions"
		sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot chmod 777 /dev/console &>/dev/null
		sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot chmod 777 /dev/null &>/dev/null
		sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot chmod 777 /dev/zero &>/dev/null
	status_done

	status_start "unmounting special dirs"
		umount_special
	status_done
}

########################################################################################################
# create the buildscripts
########################################################################################################
create_buildscripts()
{
	newline
	title "Installing buildscripts"

	status_start "creating needed directories"
		for repo in ${REPOS}
		do
			sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot su $USER -c "mkdir -p /home/$USER/$BASENAME/${REPO}" &>/dev/null
			
			sudo chown -R $USER:users $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER
		done
	status_done
	
	if [ -d "$BASEPATH/_buildscripts" ] ; then
		notice "buildscripts already installed"
	else
		status_start "fetching buildscripts from SVN"
		svn co $SVN_BUILDSYS $BASEPATH/_buildscripts &>/dev/null
		status_done
	fi
	
	if [ -d "$BASEPATH/_sources" ] ; then
		notice "sources dir exists already"
	else
		status_start "creating sources dir"
		mkdir -p $BASEPATH/_sources &>/dev/null
		status_done
	fi

	status_start "fetching PKGBUILDs from SVN"
		cd $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/kdemod &>/dev/null
		svn co $SVN_REPO $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/ &>/dev/null
		sudo chroot $BASEPATH/${REPO}-${ARCH}/chroot su -c "chown -R $USER:users /home/$USER" &>/dev/null
	status_done
}

########################################################################################################
# preconfigure the buildscripts
########################################################################################################
preconfigure_buildscripts()
{
	newline
	title "Preconfiguring buildscripts"
	
	status_start "creating directories"
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/{_sources,_temp,_repo/{remote,local}} &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/_buildscripts &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/_sources &>/dev/null
	status_done
	
	status_start "installing makepkg"
	if [ "$REPO" = "desktop" ] || [ "$REPO" = "desktop-testing" ]; then
		cp $BASEPATH/_buildscripts/makepkg-chakra $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/makepkg &>/dev/null
	else
		cp $BASEPATH/_buildscripts/makepkg $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/makepkg &>/dev/null
	fi

	status_done

	status_start "installing chroot configs"
		cp -f $BASEPATH/_buildscripts/skel/bashrc $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/.bashrc
		cp -f $BASEPATH/_buildscripts/skel/screenrc $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/.screenrc
	status_done

	status_start "installing chroot scripts"
		cp $BASEPATH/_buildscripts/scripts/enter-chroot.sh $BASEPATH &>/dev/null
		cp $BASEPATH/_buildscripts/scripts/update-buildsystem.sh $BASEPATH &>/dev/null
		cp $BASEPATH/_buildscripts/scripts/update-chroot.sh $BASEPATH &>/dev/null
		chmod +x $BASEPATH/*.sh &>/dev/null
	status_done
}

########################################################################################################
# configure the buildscripts
########################################################################################################
configure_buildscripts()
{
	newline
	title "Configuring buildscripts for: ${REPO}-${ARCH}"
	
	status_start "creating config files"
		cp -v $BASEPATH/_buildscripts/skel/${REPO}-cfg.conf $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-cfg.conf &>/dev/null
		cp -v $BASEPATH/_buildscripts/skel/${REPO}-pkgs.conf $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-pkgs.conf &>/dev/null
		cp -v $BASEPATH/_buildscripts/skel/${REPO}-makepkg.conf $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg.conf &>/dev/null
		
		if [ -e "$BASEPATH/_buildscripts/conf/user.conf" ] ; then
			/bin/true
		else
			cp -v $BASEPATH/_buildscripts/skel/user.conf $BASEPATH/_buildscripts/conf/ &>/dev/null
		fi
	status_done
	
	status_start "creating user symlinks"
		pushd $BASEPATH/_buildscripts &>/dev/null
		ln -sv conf/${REPO}-${ARCH}-cfg.conf ${REPO}-${ARCH}-cfg.conf &>/dev/null
		ln -sv conf/${REPO}-${ARCH}-pkgs.conf ${REPO}-${ARCH}-pkgs.conf &>/dev/null
		ln -sv conf/${REPO}-${ARCH}-makepkg.conf ${REPO}-${ARCH}-makepkg.conf &>/dev/null
		ln -sv conf/user.conf user.conf &>/dev/null
		popd &>/dev/null
	status_done

	local CPU_NUM=$(grep ^processor /proc/cpuinfo | awk '{a++} END {print a}')
	local SETUP_MAKEFLAGS=$(( $CPU_NUM + 1 ));
	notice "$CPU_NUM cpu('s) detected, setting MAKEFLAGS to -j$SETUP_MAKEFLAGS"

	status_start "setting up makepkg config"
		sed -i -e "s,#MAKEFLAGS.*,MAKEFLAGS=\"-j$SETUP_MAKEFLAGS\",g" $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg.conf
		sed -i -e s,#PKGDEST.*,PKGDEST=\"/home/$USER/$BASENAME/${REPO}/_repo/local\",g $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg.conf 
		sed -i -e s,#SRCDEST.*,SRCDEST=\"/home/$USER/$BASENAME/${REPO}/_sources\",g $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg.conf
		sed -i -e "s/___ARCH___/$BUILDARCH/g" $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-makepkg.conf
	status_done

	status_start "setting up repo config"
		sed -i -e s#_build_work.*#_build_work=\"/home/$USER/$BASENAME/${REPO}/\"#g $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-cfg.conf
	status_done

	status_start "setting up buildscripts config"
		sed -i -e s#_build_autoinstall.*#_build_autoinstall=1#g $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-cfg.conf
		sed -i -e s#_build_autodepends.*#_build_autodepends=1#g $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-cfg.conf
		sed -i -e s,_build_configured.*,_build_configured=1,g $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-cfg.conf
		sed -i -e "s/___ARCH___/$BUILDARCH/g" $BASEPATH/_buildscripts/conf/${REPO}-${ARCH}-cfg.conf
	status_done
	
	status_start "finishing..."
		# add pkgbuild link
		ln -s $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO} $BASEPATH/${REPO}-${ARCH}/pkgbuilds &>/dev/null	
		# add packages link
		ln -s $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/$BASENAME/${REPO}/_repo $BASEPATH/${REPO}-${ARCH}/packages &>/dev/null
		# enter build dir automatically upon entering the chroot
		echo "export _arch=$ARCH" >> $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/.bashrc
		echo "cd ~/$BASENAME/$REPO/" >> $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/.bashrc
		echo "ls" >> $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/.bashrc
		echo 'echo " "' >> $BASEPATH/${REPO}-${ARCH}/chroot/home/$USER/.bashrc
		# clean up generated pacman.conf
		rm -rf $BASEPATH/pacman.conf
	status_done
}

########################################################################################################
# i'll be back
########################################################################################################
all_done()
{
	newline
	title "All done!"
	msg "Now open$_W _buildscripts/${REPO}-${ARCH}-makepkg.conf and edit the"
	msg "DLAGENTS, CFLAGS, CXXFLAGS and PACKAGER settings to your"
	msg "liking and you are ready to build packages :)"
	newline
	msg "(Very) Quick Start:"
	msg "-------------------"
	msg "1 -> cd $BASENAME"
	msg "2 -> ./enter-chroot.sh ${REPO}-${ARCH}"
	msg "3 -> cd package"
	msg "4 -> ../makepkg"
	newline
}

#
# startup
#
########################################################################################################
# lets start
########################################################################################################
# we need to start this a a normal user
if [ $UID -ne 0 ];
then
        notice "running on user: $USER"
else
	newline
	error "Do not run me on your root account, thanks ;)"
	exit 1
fi
# check the repo parameter
if [ -z "${REPO}" ] ; then
	warning "you need to specify a repository:\n$REPO_CHECK"
	newline
	exit 1
fi
# check the parameter
if [ -z "${ARCH}" ] ; then
	warning "you need to specify an architecture:\ni686\nx86_64"
	newline
	exit 1
fi
# initialize sudo, so we dont interrupt the setup in the middle of the run. cheap, but should work (tm)
if [ -e "/usr/bin/sudo" ] ; then
	newline
	warning "Initializing sudo, you will be asked for your password"
	newline
	sudo /bin/true &>/dev/null
else
	newline
	error "Please install and configure sudo"
	newline
	exit 1
fi

clear
title "Chakra buildroot - setup-o-matic v$VER"
warning "Root directory        : $BASEPATH"
notice "                        (^^the root dir, containing everything created by this script^^)"
newline
warning "Installation directory: $BASEPATH/${REPO}-${ARCH}"
notice "                        (^^the root dir of the currently selected repository^^)"
newline
question "Do you want to continue (y/n) "

while true; do
	read yn
	case $yn in
		y* | Y* ) 
			check_chroot ;
			create_chroot ;
			create_buildscripts ;
			preconfigure_buildscripts ;
			configure_buildscripts ;
			all_done ;
		break 
		;;
		
		[nN]* )   
		newline ;
		title "bye!" ; 
		newline ;
		break 
		;;
		
		q* ) 
		exit 
		;;
		
		* ) 
		echo "Enter yes or no" 
		;;
	esac
done
