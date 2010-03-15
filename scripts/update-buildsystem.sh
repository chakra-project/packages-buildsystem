#!/bin/bash

REPO=`echo $1`
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

msg "updating _buildsystem"
	pushd $CURDIR/_buildsystem &>/dev/null
	svn up
	popd &>/dev/null
	
	rm -rf $CURDIR/*.sh
	cp $CURDIR/_buildsystem/scripts/*.sh $CURDIR/
	rm -rf $CURDIR/create-buildenv.sh
	chmod +x *.sh
	
msg "updating makepkg"
	for repo in $REPOS
	do
		cp -f $CURDIR/_buildsystem/makepkg $CURDIR/$repo/home/$USER/buildroot/$repo
	done

msg "all done"
newline
newline
