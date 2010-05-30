#!/bin/bash

REPO=`echo $1`
USER_CHECK=`whoami`
USER=`echo $USER_CHECK`
CURDIR_CHECK=`pwd`
CURDIR=`echo $CURDIR_CHECK`
BASENAME="Chakra"
BASEPATH=`echo $CURDIR`
REPOS=`ls -1 $BASEPATH | grep -e sh -e _ -e pkgbuild -e packages  -v | sed 's/\///g'`

newline() {
	echo " "
}

msg() {
	local mesg=$1; shift
	echo -e "\033[1;32m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

error() {
	local mesg=$1; shift
	printf "\033[1;31m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

status_start() {
	local mesg=$1; shift
	echo -e -n "\033[1;32m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

status_done() {
	echo -e "\033[1;32m DONE \033[1;0m"
}

msg "updating _buildscripts"
	pushd $CURDIR/_buildscripts &>/dev/null
	svn up
	popd &>/dev/null
	
	rm -rf $CURDIR/*.sh
	cp -v $CURDIR/_buildscripts/scripts/*.sh $CURDIR/
	rm -rf $CURDIR/create-builden*.sh
	rm -rf $CURDIR/setu*.sh
	chmod +x *.sh
	
msg "updating makepkg"
	for repo in $REPOS
	do
		if [ "$repo" = "desktop-i686" ] || [ "$repo" = "desktop-testing-i686" ] || [ "$repo" = "desktop-x86_64" ] || [ "$repo" = "desktop-testing-x86_64" ]; then
		cp -fv $CURDIR/_buildscripts/makepkg-chakra $CURDIR/$repo/chroot/home/$USER/buildroot/`echo $repo | sed 's/-i686//g'`/makepkg
	else
		cp -fv $CURDIR/_buildscripts/makepkg $CURDIR/$repo/chroot/home/$USER/buildroot/`echo $repo | sed 's/-i686//g' | sed 's/-x86_64//g'`/makepkg
	fi
	done

msg "all done"
newline
newline
