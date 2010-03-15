#!/bin/bash

REPO=`echo $1`
REPOREAL=`echo $1 | sed "s/-i686//g" | sed "s/-x86_64//g"`
USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
BASENAME="Chakra"
BASEPATH=`echo $CURDIR`
REPOS=`ls -1 $BASEPATH | grep -v -e sh -e _ -e pkgbuild -e packages | sed 's/\///g'`

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
	error "you need to specify a repository:\n$REPOS"
	newline
	exit 1
fi


#
# main functions
#
	msg "entering chroot: $REPO"
	newline

	sudo mount -v /dev/ $CURDIR/$REPO/dev/ --bind &>/dev/null
	sudo mount -v /sys/ $CURDIR/$REPO/sys/ --bind &>/dev/null
	sudo mount -v /proc/ $CURDIR/$REPO/proc/ --bind &>/dev/null
	sudo mount -v $CURDIR/_buildsystem/ $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_buildsystem --bind &>/dev/null
	sudo mount -v $CURDIR/_sources/ $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_sources --bind &>/dev/null
	sudo mount -v /var/cache/pacman/pkg $CURDIR/$REPO/var/cache/pacman/pkg --bind &>/dev/null
	sudo cp -vf /etc/mtab $CURDIR/$REPO/etc/mtab &>/dev/null
	sudo cp -vf /etc/resolv.conf $CURDIR/$REPO/etc/resolv.conf &>/dev/null

	sudo chroot $CURDIR/$REPO su - $USER

	sudo umount $CURDIR/$REPO/dev/ &>/dev/null
	sudo umount $CURDIR/$REPO/sys/ &>/dev/null
	sudo umount $CURDIR/$REPO/proc/ &>/dev/null
	sudo umount $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_buildsystem &>/dev/null
	sudo umount $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_sources &>/dev/null
	sudo umount $CURDIR/$REPO/var/cache/pacman/pkg &>/dev/null
	
	sudo umount $CURDIR/$REPO/dev/ &>/dev/null
	sudo umount $CURDIR/$REPO/sys/ &>/dev/null
	sudo umount $CURDIR/$REPO/proc/ &>/dev/null
	sudo umount $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_buildsystem &>/dev/null
	sudo umount $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_sources &>/dev/null
	sudo umount $CURDIR/$REPO/var/cache/pacman/pkg &>/dev/null
	
	sudo umount $CURDIR/$REPO/dev/ &>/dev/null
	sudo umount $CURDIR/$REPO/sys/ &>/dev/null
	sudo umount $CURDIR/$REPO/proc/ &>/dev/null
	sudo umount $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_buildsystem &>/dev/null
	sudo umount $CURDIR/$REPO/home/$USER/buildroot/$REPOREAL/_sources &>/dev/null
	sudo umount $CURDIR/$REPO/var/cache/pacman/pkg &>/dev/null
