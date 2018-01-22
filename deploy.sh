# Move to temp directory
cd /mnt/tmp

# Download and extract project, if not present
if [ ! -d openstack_lab-ocata_4n_classic_ovs-v03 ]; then
    /mnt/vnx/repo/cnvr/bin/get-openstack-tutorial-v03.sh
fi

# Move to download directory
cd openstack_lab-ocata_4n_classic_ovs-v03

# Create environment
sudo vnx -f openstack_lab.xml -t

# Start server
sudo vnx -f openstack_lab.xml -x start-all

# Download images
sudo vnx -f openstack_lab.xml -x load-img

# Grant admin mode to scenario.sh file
chmod 777 scenario.sh

# Console text colors
COLOR='\033[0;36m'

# No Color
NC='\033[0m'

# End echoes
echo -e "======================================================================================="
echo -e "Access horizon with both admin and demo user: http://10.0.10.11/horizon"
echo -e "   domain:		${COLOR}default${NC}"
echo -e "   user:		${COLOR}admin/demo${NC}"
echo -e "   password:	${COLOR}xxxx${NC}"
echo -e ""
echo -e "Download file admin-openrc.sh and demo-openrc.sh version 3."
echo -e ""
echo -e "Once downloaded both files into Download directory, execute scenario.sh"
echo -e "======================================================================================="
