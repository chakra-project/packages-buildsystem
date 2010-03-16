#!/bin/bash

USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
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




#
# main functions
#
for repo in $REPOS
	do
	msg "updating chroot: $repo"
	newline
		sudo pacman -r $CURDIR/$repo/chroot --cachedir $CURDIR/_cache -Suy --noconfirm
	done
	
	newline
	msg "all done!"
	newline





