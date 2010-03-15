#!/bin/bash
#
# buildenv-setup.sh -> creates a self-contained & chrooted KDEmod build environment
# GPL - jan.mette@berlin.de

echo ":: starting up, this could take some secs..."

#
# globals
#
VER="0.4.3.90"
SVNBASE="svn://konnektion.ath.cx:1235/packages"

#
# setup
#
BASENAME="buildroot"
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
REPO=`echo $1`
ARCH=`echo $2`
USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
USERID=`getent passwd $USER | cut -d: -f3`
PROGRESSBAR="/tmp/chakra-buildsystem.progress"

BASEPATH=`echo $CURDIR/$BASENAME`
REPO_CHECK=`svn ls $SVNBASE | grep -v "_" | sed 's/\///g'`
SVN_BUILDSYS="$SVNBASE/_buildsystem"
SVN_REPO="$SVNBASE/${REPO}"

mkdir -p $BASEPATH
rm -rf $BASEPATH/pacman.conf

#
# detect host
#
if [ -e "/etc/arch-release" ] ; then
	echo ":: running on arch linux"
elif [ -e "/etc/debian_version" ] ; then
	DEB_VER=`cat /etc/debian_version`
	echo ":: running on debian $DEB_VER"
	unset DEB_VER
else
	echo ":: running on a unsupported linux distro"
	echo ":: (everything could happen from here...)"
fi

#
# setup & check pacman
#
if [ -e "/usr/bin/pacman.static" ] ; then
	PACMAN_BIN="pacman.static"
	echo ":: using pacman.static"
elif [ -e "/usr/bin/pacman" ] ; then
	PACMAN_BIN="pacman"
	echo ":: using pacman"
else
	echo ":: you need pacman on your host system."
	echo " "
	exit 0
fi

#
# helper functions
#
title() {
	local mesg=$1; shift
	printf ">> ${mesg}"
}

msg() {
	local mesg=$1; shift
	echo -e ":: ${mesg}"
}

question() {
	local mesg=$1; shift
	echo -e -n "?? ${mesg}"
}

notice() {
	local mesg=$1; shift
	echo -e -n ":: ${mesg}\n"
}

warning() {
	local mesg=$1; shift
	printf "!! ${mesg}\n"
}

error() {
	local mesg=$1; shift
	printf "00 ${mesg}\n"
}

newline() {
	echo " "
}

status_start() {
	local mesg=$1; shift
	echo -e -n ":: ${mesg}"
}

status_ok() {
	echo -e " OK "
}

status_done() {
	echo -e " DONE "
}

mount_special() {
	sudo mount -v /dev/ $BASEPATH/${REPO}-${ARCH}/dev/ --bind &>/dev/null
	sudo mount -v /sys/ $BASEPATH/${REPO}-${ARCH}/sys/ --bind &>/dev/null
	sudo mount -v /proc/ $BASEPATH/${REPO}-${ARCH}/proc/ --bind &>/dev/null
	sudo mount -v /var/cache/pacman/pkg $BASEPATH/${REPO}-${ARCH}/var/cache/pacman/pkg --bind &>/dev/null
}

umount_special() {
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/dev/ &>/dev/null
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/sys/ &>/dev/null
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/proc/ &>/dev/null
	sudo umount -v $BASEPATH/${REPO}-${ARCH}/var/cache/pacman/pkg &>/dev/null
}

create_pacmanconf() {
	echo " " >> $BASEPATH/pacman.conf
	echo "[options]" >> $BASEPATH/pacman.conf
	echo "HoldPkg=pacman glibc" >> $BASEPATH/pacman.conf
	echo "SyncFirst=pacman" >> $BASEPATH/pacman.conf
	echo " " >> $BASEPATH/pacman.conf

	if [ "$REPO" = "core-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "platform-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/platform-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "desktop-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/platform-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[desktop-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/desktop-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf

	elif [ "$REPO" = "apps-testing" ] ; then
		echo "[core-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/core-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[platform-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/platform-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[desktop-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/desktop-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
		echo "[apps-testing]" >> $BASEPATH/pacman.conf
		echo "Server=http://konnektion.ath.cx/repo/apps-testing/${ARCH}" >> $BASEPATH/pacman.conf
		echo " " >> $BASEPATH/pacman.conf
	fi
}

echo ":: creating pacman.conf"
create_pacmanconf

echo ":: loading package information"
COREPKGS=`sudo LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Syl core-testing | cut -d " " -f 2 | grep -e "Synchronizing" -e "core-testing" -v`


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
						sudo umount -v ${REPO}-${ARCH}/dev/ &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/sys/ &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/proc/ &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/home/$USER/$BASENAME/_buildsystem &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/_sources &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/var/cache/pacman/pkg &>/dev/null
						rm -rf -v $BASEPATH/_buildsystem/${REPO}-${ARCH}-*.conf &>/dev/null
						rm -rf -v $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-*.conf &>/dev/null
						rm -rf -v $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg*.conf.* &>/dev/null
						rm -rf -v $BASEPATH/${REPO}-${ARCH}-pkgbuilds &>/dev/null
						rm -rf -v $BASEPATH/${REPO}-${ARCH}-packages &>/dev/null
					status_done
				;;
			
				u* ) 
					newline
					status_start "uninstalling ${REPO}-${ARCH}  "
						cd $BASEPATH
						sudo umount -v ${REPO}-${ARCH}/dev/ &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/sys/ &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/proc/ &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/home/$USER/$BASENAME/_buildsystem &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/_sources &>/dev/null
						sudo umount -v ${REPO}-${ARCH}/var/cache/pacman/pkg &>/dev/null
						rm -rf -v $BASEPATH/_buildsystem/${REPO}-${ARCH}-*.conf &>/dev/null
						rm -rf -v $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-*.conf &>/dev/null
						rm -rf -v $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg*.conf.* &>/dev/null
						rm -rf -v $BASEPATH/${REPO}-${ARCH}-pkgbuilds &>/dev/null
						rm -rf -v $BASEPATH/${REPO}-${ARCH}-packages &>/dev/null
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
	
# 	newline
# 	msg "Do you want to install KDEmod into the chroot?"
# 	msg '(in this case the script will run "pacman -S kdemod automoc4")'
# 	msg "Answer with no here if you are building a KDEmod [core|testing|unstable] repo from scratch."
# 	newline
# 	question "(y/n) "
# 
# 	read yn
# 	case $yn in
# 		y* | Y* ) 
# 			INST_KDEMOD="1"
# 			if [ -z `grep "kdemod-${REPO}" $BASEPATH/pacman.conf` ] ; then
# 				newline
# 				error "Sorry, you need to enable kdemod-${REPO} in $BASEPATH/pacman.conf before running this script."
# 				error "Exiting..."
# 				newline
# 				exit 1
# 			fi
# 		;;
# 		
# 		[nN]* )   
# 			INST_KDEMOD="0"
# 		;;
# 		
# 		* ) 
# 		echo "Enter yes or no" 
# 		;;
# 	esac

	newline
	status_start "creating special dirs"
		mkdir -p $BASEPATH/${REPO}-${ARCH}/dev &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/sys &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/proc &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/var/cache/pacman/pkg &>/dev/null
	status_done
	
	status_start "mounting special dirs"
		mount_special
	status_done

	status_start "creating pacman dirs"
		mkdir -p $BASEPATH/${REPO}-${ARCH}/var/lib/pacman &>/dev/null
	status_done

	msg "installing core packages"
	warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		
		newline
		echo "!!!!!!!!!!!!!!! DEBUG !!!!!!!!!!!!!!!!!!!!!!"
		echo "core packages:"
		echo $COREPKGS

		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy 
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -S $COREPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v

		newline

	if [ "$REPO" = "platform-testing" ] ; then

		msg "installing platform packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Sl platform-testing | cut -d " " -f 2`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "desktop-testing" ] ; then

		msg "installing platform packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Sl platform-testing | cut -d " " -f 2`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing desktop packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Sl desktop-testing | cut -d " " -f 2`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

	elif [ "$REPO" = "apps-testing" ] ; then

		msg "installing platform packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Sl platform-testing | cut -d " " -f 2`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing desktop packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Sl desktop-testing | cut -d " " -f 2`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		msg "installing apps packages"
		warning "follow pacman instructions from here"

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline

		PLATFORMPKGS=`LC_ALL=C $PACMAN_BIN --config $BASEPATH/pacman.conf -Sl apps-testing | cut -d " " -f 2`
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -Sy $PLATFORMPKGS 

		# update sudo timestamp to prevent further password questions
		sudo -v
		newline
	fi

	status_start "configuring system"
		mkdir $BASEPATH/${REPO}-${ARCH}/etc/ &>/dev/null
		sudo cp /etc/resolv.conf $BASEPATH/${REPO}-${ARCH}/etc/ &>/dev/null
		sudo cp $BASEPATH/pacman.conf $BASEPATH/${REPO}-${ARCH}/etc/ &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/etc/pacman.d &>/dev/null
		sudo cp /etc/pacman.d/mirrorlist $BASEPATH/${REPO}-${ARCH}/etc/pacman.d/ &>/dev/null
	status_done

	status_start "adding user: $USER"
		sudo chroot $BASEPATH/${REPO}-${ARCH} useradd -g users -u $USERID -G audio,video,optical,storage,log -m $USER &>/dev/null
	status_done

	status_start "setting up /etc/sudoers"
		sudo chmod 777 $BASEPATH/${REPO}-${ARCH}/etc/sudoers
		sudo echo >>$BASEPATH/${REPO}-${ARCH}/etc/sudoers
		sudo echo "$USER     ALL=NOPASSWD: /usr/bin/pacman" >>$BASEPATH/${REPO}-${ARCH}/etc/sudoers
		sudo chmod 0440 $BASEPATH/${REPO}-${ARCH}/etc/sudoers
	status_done

	status_start "unmounting special dirs"
		umount_special
	status_done
}

########################################################################################################
# create the buildsystem
########################################################################################################
create_buildsystem()
{
	newline
	title "Creating buildsystem"

	status_start "creating needed directories"
		for repo in ${REPOS}
		do
			sudo chroot $BASEPATH/${REPO}-${ARCH} su $USER -c "mkdir -p /home/$USER/$BASENAME/${REPO}" &>/dev/null
			
			sudo chown -R $USER:users $BASEPATH/${REPO}-${ARCH}/home/$USER
		done
	status_done
	
	if [ -d "$BASEPATH/_buildsystem" ] ; then
		notice "buildsystem already installed"
	else
		status_start "fetching buildsystem from SVN"
		svn co $SVN_BUILDSYS $BASEPATH/_buildsystem &>/dev/null
		status_done
	fi
	
	if [ -d "$BASEPATH/_sources" ] ; then
		notice "sources dir exists already"
	else
		status_start "creating sources dir"
		mkdir -p $BASEPATH/_sources &>/dev/null
		status_done
	fi

	# update sudo timestamp to prevent further password questions
	sudo -v
	
	status_start "compiling additional package(s): repo-clean  "
		cd $BASEPATH/_buildsystem/tools/repo-clean &>/dev/null
		makepkg &>/dev/null
	status_done
	
	status_start "installing additional package(s): repo-clean"
		cd $BASEPATH/_buildsystem/tools/repo-clean &>/dev/null
		sudo $PACMAN_BIN --config $BASEPATH/pacman.conf -r $BASEPATH/${REPO}-${ARCH} -U repo-clean*.pkg.tar.gz &>/dev/null
	status_done

	# update sudo timestamp to prevent further password questions
	sudo -v

	status_start "fetching PKGBUILDs from SVN"
		cd $BASEPATH/${REPO}-${ARCH}/home/$USER/kdemod &>/dev/null
		svn co $SVN_REPO $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO} &>/dev/null
		sudo chroot $BASEPATH/${REPO}-${ARCH} su -c "chown -R $USER:users /home/$USER" &>/dev/null
	status_done
}

########################################################################################################
# preconfigure the buildsystem
########################################################################################################
preconfigure_buildsystem()
{
	newline
	title "Preconfiguring buildsystem"
	
	status_start "creating directories"
		mkdir -p $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/{_sources,_repo/{repo,build}} &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/_buildsystem &>/dev/null
		mkdir -p $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/_sources &>/dev/null
	status_done
	
	status_start "installing makepkg"
		cp $BASEPATH/_buildsystem/makepkg $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/makepkg &>/dev/null
	status_done

	status_start "installing chroot configs"
		cp -f $BASEPATH/_buildsystem/skel/bashrc $BASEPATH/${REPO}-${ARCH}/home/$USER/.bashrc
	status_done

	status_start "installing chroot scripts"
		cp $BASEPATH/_buildsystem/scripts/enter-chroot.sh $BASEPATH &>/dev/null
		cp $BASEPATH/_buildsystem/scripts/update-buildsystem.sh $BASEPATH &>/dev/null
		cp $BASEPATH/_buildsystem/scripts/update-chroot.sh $BASEPATH &>/dev/null
		chmod +x $BASEPATH/*.sh &>/dev/null
	status_done
}

########################################################################################################
# configure the buildsystem
########################################################################################################
configure_buildsystem()
{
	newline
	title "Configuring buildsystem for: ${REPO}-${ARCH}"
	
	status_start "creating config files"
		cp -v $BASEPATH/_buildsystem/skel/${REPO}-cfg.conf $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-cfg.conf &>/dev/null
		cp -v $BASEPATH/_buildsystem/skel/${REPO}-pkgs.conf $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-pkgs.conf &>/dev/null
		cp -v $BASEPATH/_buildsystem/skel/${REPO}-makepkg.conf $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg.conf &>/dev/null
		
		if [ -e "$BASEPATH/_buildsystem/conf/user.conf" ] ; then
			/bin/true
		else
			cp -v $BASEPATH/_buildsystem/skel/user.conf $BASEPATH/_buildsystem/conf/ &>/dev/null
		fi
	status_done
	
	status_start "creating user symlinks"
		pushd $BASEPATH/_buildsystem &>/dev/null
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
		sed -i -e "s,#MAKEFLAGS.*,MAKEFLAGS=\"-j$SETUP_MAKEFLAGS\",g" $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg.conf
		sed -i -e s,#PKGDEST.*,PKGDEST=\"/home/$USER/$BASENAME/${REPO}/_repo/build\",g $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg.conf 
		sed -i -e s,#SRCDEST.*,SRCDEST=\"/home/$USER/$BASENAME/${REPO}/_sources\",g $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg.conf
		sed -i -e "s/___ARCH___/$ARCH/g" $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-makepkg.conf
	status_done

	status_start "setting up repo config"
		sed -i -e s#_build_work.*#_build_work=\"/home/$USER/$BASENAME/${REPO}/\"#g $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-cfg.conf
	status_done

	status_start "setting up buildsystem config"
		sed -i -e s#_build_autoinstall.*#_build_autoinstall=1#g $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-cfg.conf
		sed -i -e s#_build_autodepends.*#_build_autodepends=1#g $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-cfg.conf
		sed -i -e s,_build_configured.*,_build_configured=1,g $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-cfg.conf
		sed -i -e "s/___ARCH___/$ARCH/g" $BASEPATH/_buildsystem/conf/${REPO}-${ARCH}-cfg.conf
	status_done
	
	status_start "finishing..."
		# add pkgbuild link
		ln -s $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO} $BASEPATH/${REPO}-${ARCH}-pkgbuilds &>/dev/null	
		# add packages link
		ln -s $BASEPATH/${REPO}-${ARCH}/home/$USER/$BASENAME/${REPO}/_repo $BASEPATH/${REPO}-${ARCH}-packages &>/dev/null
		# enter build dir automatically upon entering the chroot
		echo "export _arch=$ARCH" >> $BASEPATH/${REPO}-${ARCH}/home/$USER/.bashrc
		echo "cd ~/$BASENAME/$REPO/" >> $BASEPATH/${REPO}-${ARCH}/home/$USER/.bashrc
		echo "ls" >> $BASEPATH/${REPO}-${ARCH}/home/$USER/.bashrc
		echo 'echo " "' >> $BASEPATH/${REPO}-${ARCH}/home/$USER/.bashrc
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
	msg "Now open$_W _buildsystem/${REPO}-${ARCH}_makepkg.conf and edit the"
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
title "KDEmod Build Enviroment - Setup-o-Matic v$VER"

msg "This script will create a dir called $BASENAME in the current directory"
msg "and install a chrooted build environment for the repo: ${REPO}"
msg "Please do not move this installer script after creating the first chroot."
msg "You can use it later to install/reinstall/uninstall chroots/repos."
newline
warning "Installation dir: $BASEPATH"
notice "                  (^^the base dir containing everything related to KDEmod^^)"
newline
warning "Repository dir: $BASEPATH/${REPO}-${ARCH}"
notice "                  (^^the installation directory of this repository^^)"
newline
question "Do you want to continue (y/n) "

while true; do
	read yn
	case $yn in
		y* | Y* ) 
			check_chroot ;
			create_chroot ;
			create_buildsystem ;
			preconfigure_buildsystem ;
			configure_buildsystem ;
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
