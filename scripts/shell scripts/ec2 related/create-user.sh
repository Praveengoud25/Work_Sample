#!/bin/bash

[ 0 -ne $(id -u) ] && echo "ERROR: You must run this script as root" >&2 && exit 1

UN="$1"
COMMENT="$2"
PUBKEY="$3"

[ -z "$UN" ] && echo "ERROR: You must specify user name as 1st param" >&2 && exit 1
[ -z "$COMMENT" ] && echo "ERROR: You must specify COMMENT as 2nd param" >&2 && exit 1
[ -z "$PUBKEY" ] && echo "ERROR: You must specify the OpenSSH public key as 3rd param" >&2 && exit 1

# create the geadmins group and the sudoers file (if not there already)
if [ "yes" = "$GRANTSUDO" ]; then
        GRPNAME="geadmins"
        grep -q "^$GRPNAME:" /etc/group
        if [ $? -ne 0 ]; then
          groupadd "${GRPNAME}"
          echo "%${GRPNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        fi

        useradd -m -c "$COMMENT" -G "$GRPNAME" $UN
else
        useradd -m -c "$COMMENT" $UN
fi

mkdir /home/$UN/.ssh && chmod 700 /home/$UN/.ssh && touch /home/$UN/.ssh/authorized_keys \
 && chmod 600 /home/$UN/.ssh/authorized_keys && chown $UN:$UN /home/$UN/.ssh /home/$UN/.ssh/authorized_keys

[ 0 -eq $? ] && echo "$PUBKEY" >> /home/$UN/.ssh/authorized_keys

echo "You should be able to login as
   $UN@$(ifconfig eth0 | grep 'inet 10' | awk '{ print $2 }')

If you are using PuTTY on Windows, you might need to upgrade to the latest version. Version 0.62 does not work. You get 'Server unexpectedly closed network connection'."


exit 0
######


