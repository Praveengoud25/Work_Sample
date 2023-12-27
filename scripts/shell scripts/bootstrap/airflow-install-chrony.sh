#!/bin/bash
set -ex
apt_package_install()
{
  for (( i=1; i<=20; i++ ))
  do
    apt_pkg_installed=$(dpkg-query -W --showformat='${Status}\n' $1 | grep "install ok installed")
    if [ "" == "$apt_pkg_installed" ]
    then
      sudo apt-get -y install $1
    else
      break
    fi
    sleep 15
  done
}

apt_package_install chrony
#sudo sed -i '/pool 2.debian.pool.ntp.org/ a server 169.254.169.123 prefer iburst\' /etc/chrony/chrony.conf
sudo echo 'server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4' >> /etc/chrony/chrony.conf
sudo /etc/init.d/chrony restart

sudo service         chrony status
sudo chronyc         sources -v
sudo chronyc         tracking
sudo apt     install bc