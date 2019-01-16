#!/bin/bash

ROOT_ERROR=3
DEBOOTSTRAB_ERROR=4
MOUNT_ERROR=5
CHROOT_ERROR=6
APT_ERROR=7
BUILD_ERROR=8

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET_C="\e[0m"

export LANGUAGE=C.UTF-8
export LANG=C.UTF-8
export LC_ALL=C

echo -e "$YELLOW installing pre required packages for building. $RESET_C"
apt install -y --allow-unauthenticated build-essential dpkg-dev dh-make
if [[ $? -ne 0 ]] 
then
	echo -e "$RED Cannot install required packages. exiting $RESET_C" && exit $APT_ERROR
fi
[[ $(expr match "$(cat /etc/apt/sources.list | tail -1)" 'deb-src.*') -ne 0 ]] || cat /etc/apt/sources.list | sed 's/deb/deb-src/' | tee -a /etc/apt/sources.list && apt update

cd /build
apt source debian-installer 
if [[ $? -eq 0 ]]
then
	echo -e "$GREEN sources download successful. proceed $RESET_C"
else
	echo -e "$RED sources download failed. exiting. $RESET_C" && exit $APT_ERROR
fi

tar -xzf debian-installer*.tar.gz && cd installer/ || cd debian-installer-*/



echo -e "$YELLOW dependencies solving started $RESET_C"
a="$(dpkg-checkbuilddeps 2>&1 | tail -1 | sed 's/.*:.*:.*: //; s/(>= [0-9\.:-]\+)//g')"

# echo -e "$YELLOW $a $RESET_C"
if [[ $(expr "$a" : '.*: .*: .*: ') -eq 0 ]] 
then
	apt install -y --allow-unauthenticated $a 
	if [[ $? -ne 0 ]]
	then		
		echo -e "$RED apt fail. exitting. $RESET_C" && exit $APT_ERROR
	fi
fi

echo -e "$GREEN dependencies solved $RESET_C"

echo -e "$YELLOW build start $RESET_C"
dpkg-buildpackage -T binary
if [[ $? -eq 0 ]]
then
	echo -e "$GREEN build finished successfully. $RESET_C"
else 
	echo -e "$RED build failed. exiting. $RESET_C" && exit $BUILD_ERROR
fi

exit

