#!/bin/bash

USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
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

#
# main functions
#
for repo in $REPOS
	do
	msg "updating chroot: $repo"
	newline
	echo ":: creating pacman.conf"
	sudo pacman -r $BASEPATH/$repo/chroot --config $BASEPATH/$repo/chroot/etc/pacman.conf --cachedir $BASEPATH/_cache -Suy --noconfirm
	newline
	done
	
msg "all done!"
newline





