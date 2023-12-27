if ! (sudo ps -efa | grep -v grep | grep -v bash | grep -i qualys)
then

echo "Qualys cloud agent install starting..." >&2
#Qualys Activation ID's from Cyber Team (FOR US-WEST POP)
QUALYS_ACTIVATION_ID=f5fddd4b-8f0f-44c5-be3b-fa7417872688
QUALYS_CUSTOMER_ID=47f67c2b-f945-e0d3-83e0-41701840c236
QUALYS_SERVER_URI=https://qagpublic.qg3.apps.qualys.com/CloudAgent

#Which Linux distribution is this?
DISTRO=`cat /etc/os-release | grep -i 'ID_LIKE'`
if ( echo ${DISTRO} | grep -iqE "fedora|rhel|centos" )
then
    EXT='rpm'
elif ( echo ${DISTRO} | grep -iqE "ubuntu|debian" )
then
    EXT='deb'
else
    echo "Could not identify Linux Distro for Qualys cloud agent install: ${DISTRO}. Exiting." >&2
    exit 86
fi

#Is this architecture X86 or ARM?
if ( uname -m | grep -iq 'x86' )    #architecture is either x86_64 or aarch64.
then
    ARCH=''
elif ( uname -m | grep -iq 'aarch' || uname -m | grep -iq 'ARM')
then
    ARCH='ARM'
else
    echo "Could not identify architecture type for Qualys cloud agent install: ${ARCH}. Exiting." >&2
    exit 87
fi

#Determine correct service command for this platform
if ( which service >/dev/null ) ; then
    SVC_STATUS_CMD='service qualys-cloud-agent status'
    SVC_STOP_CMD='service qualys-cloud-agent stop'
elif (which systemctl >/dev/null) ; then
    SVC_STATUS_CMD='systemctl status qualys-cloud-agent'
    SVC_STOP_CMD='systemctl stop qualys-cloud-agent'
else
    echo "service command not found. Exiting." >&2
    exit -1
fi

#Determine proper install package and download.
QUALYS_PKG_FILE="QualysCloudAgent${ARCH}.${EXT}"
QUALYS_PKG_PATH="https://ged-qualys-agent.s3.amazonaws.com/${QUALYS_PKG_FILE}"
sudo rm -f /tmp/${QUALYS_PKG_FILE}
echo "Downloading file: ${QUALYS_PKG_PATH}" >&2
if ! ( sudo wget --quiet ${QUALYS_PKG_PATH} -P /tmp/ ) ; then
    echo "Failed to Download Qualys cloud agent install package. Exiting." >&2
    exit -1
fi

#If Qualys is already installed, remove it first.
SVC_OUT=`sudo ${SVC_STATUS_CMD}`
QUALYS_INSTALLED=$?
if [[ ${QUALYS_INSTALLED} == 0 ]] ; then
    echo "Qualys is already installed. Stopping service." >&2
    #In at least one case where Qualys install failed, i witnessed the "service stop" command hang indefinitely.
    #So using SIGKILL here on the PID.
    QUALYS_PID=`pidof qualys-cloud-agent`
    if [[ ${QUALYS_PID} != "" ]] ; then
        sudo kill -9 ${QUALYS_PID}
        sleep 30 #I've also seen issues if new Qualys gets installed too quickly after removal, so waiting 30s.
    fi
    sudo ${SVC_STOP_CMD}
fi

#Install if RPM package.
RC=
if [[ "${EXT}" == 'rpm' ]]
then
    # Redhat/RPM:
    sudo yum -y remove qualys-cloud-agent #in case old version is there
    sudo yum -y localinstall /tmp/${QUALYS_PKG_FILE}
    sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=${QUALYS_ACTIVATION_ID} CustomerId=${QUALYS_CUSTOMER_ID} ServerUri=${QUALYS_SERVER_URI}
    if [[ $? != 0 ]] ; then
         echo "Qualys Activation Failed." >&2
         exit 88
    fi
fi

#Install if DEB package.
if [[ "${EXT}" == 'deb' ]]
then
    # Ubuntu/DEB:
    sudo dpkg --remove qualys-cloud-agent #in case old version is there
    sudo dpkg --install /tmp/${QUALYS_PKG_FILE}
    sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=${QUALYS_ACTIVATION_ID} CustomerId=${QUALYS_CUSTOMER_ID} ServerUri=${QUALYS_SERVER_URI}
    if [[ $? != 0 ]] ; then
         echo "Qualys Activation Failed." >&2
         exit 89
    fi
fi

#Check if qualys service got installed correctly and running.
sudo ${SVC_STATUS_CMD} >&2
OUTP=`sudo ${SVC_STATUS_CMD}`
QUALYS_INSTALLED=$?
echo ${OUTP} | grep -iq 'running'
QUALYS_RUNNING=$?

#Fail script if Qualys not running.
if [[ ${QUALYS_INSTALLED} == 0 ]] ; then
    if [[ ${QUALYS_RUNNING} == 0 ]] ; then
        echo "Qualys service installed and running successfully." >&2
    else
        echo "Qualys service is Not Started." >&2
        exit 90
    fi
else
    echo "Qualys service installation Failed" >&2
    exit 91
fi

echo "Qualys cloud agent install completed successfully." >&2

#######################################################################################################################
# END QUALYS CLOUD AGENT INSTALLATION SCRIPT
#######################################################################################################################

else
    echo -e "\n\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "NOT REINSTALLING QUALYS!!"
    echo "QUALYS IS ALREADY RUNNING ON THIS INSTANCE:"
    sudo ps -efa | grep -v grep | grep -v bash | grep -i qualys
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

