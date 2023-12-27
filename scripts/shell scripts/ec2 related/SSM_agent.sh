#Which Linux distribution is this?
DISTRO=`cat /etc/os-release | grep -i 'ID_LIKE'`
if ( echo ${DISTRO} | grep -iqE "fedora|rhel|centos" )
then
    EXT='yum'
elif ( echo ${DISTRO} | grep -iqE "ubuntu|debian" )
then
    EXT='apt'
else
    echo "Could not identify Linux Distro for Qualys cloud agent install: ${DISTRO}. Exiting." >&2
    exit 86
fi
echo $EXT

#Is this architecture X86 or ARM?
if ( uname -m | grep -iq 'x86_64' )  #architecture is either x86_64 or aarch64.
then
    ARCH='x86_64'

elif ( uname -m | grep -iq 'x86' )
then
    ARCH='x86'

elif ( uname -m | grep -iq 'aarch' || uname -m | grep -iq 'ARM')
then
    ARCH='ARM'
else
    echo "Could not identify architecture type for Qualys cloud agent install: ${ARCH}. Exiting." >&2
    exit 87
fi

echo $ARCH


#sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
echo "sudo $EXT install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_$ARCH/amazon-ssm-agent.rpm"

if [[ "${EXT}" == 'yum' ]]
then
    sudo systemctl status amazon-ssm-agent
elif [[ "${EXT}" == 'apt' ]]
then 
    sudo status amazon-ssm-agent
fi