# Get initial time in order to calculate time elapsed during execution of script.
STARTIME=$(date +%s)

# Get actual working directory
ACTUAL_DIRECTORY=$(pwd)

# Move to temp directory
cd /mnt/tmp

# Download and extract project, if not present
if [ ! -d openstack_lab-ocata_4n_classic_ovs-v03 ]; then
    /mnt/vnx/repo/cnvr/bin/get-openstack-tutorial-v03.sh
fi

# Move to download directory
cd openstack_lab-ocata_4n_classic_ovs-v03

# Delete old openstack_lab.xml.
rm -rf openstack_lab.xml

# Replace it with newer version.
cp ${ACTUAL_DIRECTORY}/openstack_lab.xml .

# Create environment
sudo vnx -f openstack_lab.xml -t

# Start server
sudo vnx -f openstack_lab.xml -x start-all

# Download images
sudo vnx -f openstack_lab.xml -x load-img

# Grant admin mode to scenario.sh file
chmod 777 ${ACTUAL_DIRECTORY}/scenario.sh

# Console text colors
COLOR='\033[0;36m'

# No Color
NC='\033[0m'

# End echoes
echo -e "==========================================================================="
echo -e "Access horizon with both admin and demo user: http://10.0.10.11/horizon"
echo -e "   domain:		${COLOR}default${NC}"
echo -e "   user:		${COLOR}admin/demo${NC}"
echo -e "   password:	${COLOR}xxxx${NC}"
echo -e ""
echo -e "Download file admin-openrc.sh and demo-openrc.sh version 3 to ~/Downloads."
echo -e ""
echo -e "Once downloaded both files execute scenario.sh"
echo -e "==========================================================================="
echo -e ""

# Print elapsed time
ENDTIME=$(date +%s)

echo -e "Elapsed Time: $(($ENDTIME - $STARTIME))"