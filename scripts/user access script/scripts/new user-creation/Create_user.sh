#!/bin/bash

export USERNAME=$1
#ec2-user

export DEFAULT_USER=$2
#pdf_user

#create the user
sudo adduser $USERNAME
sudo mkdir /home/$USERNAME/.ssh
sudo chown $USERNAME:$USERNAME  /home/$USERNAME/.ssh
sudo chmod 700 /home/$USERNAME/.ssh
#Grant permissions to swith to default user
sudo usermod -aG sudo $USERNAME
sudo usermod -aG $DEFAULT_USER $USERNAME
#allow the user to swtich to the default username without passwd
echo "$USERNAME ALL=(ALL:$DEFAULT_USER) NOPASSWD: ALL"| sudo tee /etc/sudoers.d/$USERNAME"_switch"