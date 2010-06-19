#!/bin/bash

REPO=`echo $1`
REPOREAL=`echo $1 | sed "s/-i686//g" | sed "s/-x86_64//g"`
USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
BASENAME="Chakra"
BASEPATH=`echo $CURDIR`
REPOS=`ls -1 $BASEPATH | grep -e 86 | sed 's/\///g'`

newline() {
	echo " "
}

error() {
	local mesg=$1; shift
	printf "\033[1;31m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

msg() {
	local mesg=$1; shift
	printf "\033[1;32m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

if [ -z "$REPO" ] ; then
	newline
	error "you need to specify a repository:\n\n$REPOS"
	newline
	exit 1
fi

if [ -d $BASEPATH/$REPO ] ; then
	#
	# main functions
	#
	msg "entering chroot: $REPO"
	newline

	sudo mount -v /dev/ $CURDIR/$REPO/chroot/dev/ --bind &>/dev/null
	sudo mount -v /sys/ $CURDIR/$REPO/chroot/sys/ --bind &>/dev/null
	sudo mount -v /proc/ $CURDIR/$REPO/chroot/proc/ --bind &>/dev/null
	sudo mount -v $CURDIR/_buildscripts/ $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_buildscripts --bind &>/dev/null
	sudo mount -v $CURDIR/_sources/ $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_sources --bind &>/dev/null
	sudo mount -v $CURDIR/_cache/ $CURDIR/$REPO/chroot/var/cache/pacman/pkg --bind &>/dev/null
	sudo cp -vf /etc/mtab $CURDIR/$REPO/chroot/etc/mtab &>/dev/null
	sudo cp -vf /etc/resolv.conf $CURDIR/$REPO/chroot/etc/resolv.conf &>/dev/null

	sudo chroot $CURDIR/$REPO/chroot su - $USER

	sudo umount $CURDIR/$REPO/chroot/dev/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/sys/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/proc/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_buildscripts &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_sources &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/var/cache/pacman/pkg &>/dev/null
	
	sudo umount $CURDIR/$REPO/chroot/dev/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/sys/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/proc/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_buildscripts &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_sources &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/var/cache/pacman/pkg &>/dev/null
	
	sudo umount $CURDIR/$REPO/chroot/dev/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/sys/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/proc/ &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_buildscripts &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/home/$USER/buildroot/$REPOREAL/_sources &>/dev/null
	sudo umount $CURDIR/$REPO/chroot/var/cache/pacman/pkg &>/dev/null
else
	newline
        error "the repository $REPO does not exist!"
	error "available repos:\n\n$REPOS"
	newline
	exit 1
fi	

