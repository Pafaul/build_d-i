#!/bin/bash

ROOT_ERROR=3
DEBOOTSTRAB_ERROR=4
MOUNT_ERROR=5
CHROOT_ERROR=6

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET_C="\e[0m"

CHR_DIR=chr/
DEB_NAME=debian-installer.deb

if [[ $UID -eq 0 ]] 
then 
	echo -e "$YELLOW running as root. proceed. $RESET_C"
else
	echo -e "$RED must be root to run this script. exiting. $RESET_C" && exit $ROOT_ERROR
fi

rm -r $CHR_DIR &>/dev/null
mkdir -p $CHR_DIR && echo -e "$GREEN dir for chroot made $RESET_C"
echo -e "$YELLOW checking debootstrap installation $RESET_C"
apt list debootstrap | grep debootstrap 
if [[ $? -ne 0 ]]
then
	apt install -y --allow-unauthenticated debootstrap 
fi
echo -e "$GREEN debootstrap is installed on your system. proceed $RESET_C"

echo -e "$YELLOW debootstrap installlation started. $RESET_C"
debootstrap stretch $CHR_DIR && echo -e "$GREEN debootstrap successful $RESET_C" 
if [[ $? -ne 0 ]]
then
	echo -e "$RED debootstrap failed. exiting. $RESET_C" && exit $DEBOOTSTRAP_ERROR
fi

chmod 0755 chr_script.sh
mkdir $CHR_DIR/build && cp chr_script.sh $CHR_DIR/chr_script.sh

mount --bind /proc $CHR_DIR/proc 
if [[ $? -eq 0 ]]
then
	echo -e "$GREEN mount successful $RESET_C" 
else
	echo -e "$RED /proc mount error. exitting. $RESET_COLOR" && exit $MOUNT_ERROR
fi

chroot $CHR_DIR /chr_script.sh 
if [[ $? -ne 0 ]]
then
	echo -e "$RED chroot error. exiting. $RESET_C" && umount $CHR_DIR/proc &>/dev/null && exit $CHROOT_ERROR
fi

umount $CHR_DIR/proc &>/dev/null
cp $CHR_DIR/build/*.deb $DEB_NAME
echo -e "$GREEN script finished working. Path to .deb file is: $(pwd)/$DEB_NAME $RESET_C	"
