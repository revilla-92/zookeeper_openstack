# Move to temp directory
cd /mnt/tmp

# Download and extract project, if not present
if [ ! -d openstack_lab-ocata_4n_classic_ovs-v02 ]; then
    /mnt/vnx/repo/cnvr/bin/get-openstack-tutorial-v02.sh
fi

# Move to download directory
cd openstack_lab-ocata_4n_classic_ovs-v02

# Create environment
sudo vnx -f openstack_lab.xml -t

# Start server
sudo vnx -f openstack_lab.xml -x start-all

# Download images
sudo vnx -f openstack_lab.xml -x load-img

# Console text colors
COLOR='\033[0;36m'

# No Color
NC='\033[0m'

# End echoes
echo -e "==================================================="
echo -e "URL of admin panel: http://10.0.10.11/horizon"
echo -e "   domain:    ${COLOR}default${NC}"
echo -e "   user: 	${COLOR}admin${NC}"
echo -e "   password: ${COLOR}xxxx${NC}"
echo -e "==================================================="
echo -e ""
echo -e ""
echo -e "==================================================="
echo -e "Execute next steps"
echo -e "   - Download admin-openrc.sh and demo-openrc.sh from horizon."
echo -e "   - move Downloads/admin-openrc.sh ."
echo -e "   - move Downloads/demo-openrc.sh ."
echo -e "   - source admin-openrc.sh"
echo -e "   - openstack network create --share --external --provider-physical-network provider --provider-network-type flat ExtNet"
echo -e "   - openstack subnet create --network ExtNet --gateway 10.0.10.1 --dns-nameserver 10.0.10.1 --subnet-range 10.0.10.0/24 --allocation-pool start=10.0.10.100,end=10.0.10.200 ExtSubNet"
echo -e "   - Sino se ha establecido correctamente el NAT ==> sudo vnx_config_nat ExtNet enp2s0"
echo -e "   - source demo-openrc.sh"
echo -e "   - openstack orchestration template validate -t pfinal.yml"
echo -e "   - openstack stack create -t pfinal.yml stack1"
echo -e "==================================================="