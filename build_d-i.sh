#!/bin/bash

ROOT_ERROR=3
DEBOOTSTRAB_ERROR=4
MOUNT_ERROR=5
CHROOT_ERROR=6
APT_ERROR=7
BUILD_ERROR=8
ARG_ERROR=9
CHR_SCR_ERROR=10

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET_C="\e[0m"

CHR_DIR=chr/
CHR_DIR_DEL=1
CHR_SCR=chr_script.sh
CHR_STATUS=
DEB_NAME=debian-installer.deb
DEB_LOCATION=$(pwd)

if [ $UID -eq 0 ] 
then 
	echo -e "$YELLOW running as root. proceed. $RESET_C"
else
	echo -e "$RED must be root to run this script. exiting. $RESET_C" && exit $ROOT_ERROR
fi

while [ $# -ne 0 ]
do
    case "$1" in
	"-c" )
	    echo -e "$YELLOW chroot directory will be removed after build $RESET_C"
	    CHR_DIR_DEL=0
	    shift
	;;
	"-d" )
	    shift
	    if [ ! -d "$1" ]
	    then
		 echo -e "$RED -d argument must be existing directory. exiting. $RESET_C" && exit $ARG_ERROR
	    fi
	    CHR_DIR=$( echo $1 | sed 's/\/$//')/chr
	    echo -e "$YELLOW chroot directory will be created here: $CHR_DIR"
	    shift
	;;
	"-s" )
	    shift
	    if [ ! -d "$1" ] 
	    then 
		echo -e "$RED -s argument must be existing directory. exiting. $RESET_C" && exit $ARG_ERROR
	    fi
	    CHR_SRC=$( echo $1 | sed 's/\/$//')/$CHR_SCR
	    if [ ! -f "$CHR_SCR" ] 
	    then
		echo -e "$RED cannot find build_d-i.sh script at $1. exiting. $RESET_C" && exit $ARG_ERROR
	    fi
	    shift
	;;
	"-o" )
	    shift
	    if [ ! -d "$1" ]
	    then 
		echo -e "$RED -o argument must be existing directory. exiting. $RESET_C" && exit $ARG_ERROR
	    fi
	    DEB_LOCATION=$( echo $1 | sed 's/\/$//')
	    echo -e "$YELLOW package will be here: $DEB_LOCATION"
	    shift
	;;
	* ) 
	    echo -e "$RED $1 - unnown key. exiting $RESET_C" && exit $ARG_ERROR
	;;
    esac
done

if [ ! -f $CHR_SCR ] 
then 
    echo -e "$RED cannot find chr_script.sh. exiting. $RESET_C" && exit $CHR_SCR_ERROR
fi

rm -r $CHR_DIR &>/dev/null
mkdir -p $CHR_DIR && echo -e "$GREEN dir for chroot made $RESET_C"
echo -e "$YELLOW checking debootstrap installation $RESET_C"
apt list debootstrap | grep debootstrap
[ $? -ne 0 ] || apt install -y --allow-unauthenticated debootstrap 

echo -e "$GREEN debootstrap is installed on your system. proceed $RESET_C"

echo -e "$YELLOW debootstrap installlation started. $RESET_C"
debootstrap stretch $CHR_DIR && echo -e "$GREEN debootstrap successful $RESET_C" 
if [ $? -ne 0 ]
then
	echo -e "$RED debootstrap failed. exiting. $RESET_C" && exit $DEBOOTSTRAP_ERROR
fi

chmod 0755 $CHR_SCR
mkdir $CHR_DIR/build && cp $CHR_SCR $CHR_DIR/chr_script.sh

mount --bind /proc $CHR_DIR/proc && echo -e "$GREEN mount successful $RESET_C"
if [ $? -eq 0 ]
then
	echo -e "$GREEN mount successful $RESET_C"
else
	echo -e "$RED /proc mount error. exitting. $RESET_COLOR" && exit $MOUNT_ERROR
fi

chroot $CHR_DIR ./chr_script.sh
CHR_STATUS=$?
if [ $CHR_STATUS -ne 0 ]
then
	echo -e "$RED chroot error. exiting. $RESET_C" && umount $CHR_DIR/proc &>/dev/null && exit $CHROOT_STATUS
fi

umount $CHR_DIR/proc &>/dev/null
cp $CHR_DIR/build/*.deb $DEB_LOCATION/$DEB_NAME
echo -e "$GREEN script finished working. Path to .deb file is: $DEB_LOCATION/$DEB_NAME $RESET_C"

[ $CHR_DIR_DEL ] && rm -r "$CHR_DIR"