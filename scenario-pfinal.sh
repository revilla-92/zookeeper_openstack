#https://moodle.lab.dit.upm.es/pluginfile.php/16194/mod_resource/content/4/cnvr-trabajo-final.pdf

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



#########################################################################################################
#################################### Configurar topologia con HEAT ######################################
#########################################################################################################


#########################################################################################################
#########################################################################################################
#########################################################################################################


# Configure NAT
sudo vnx_config_nat ExtNet enp1s0

# Console text colors
COLOR='\033[0;36m'
NC='\033[0m' # No Color

# End echoes
echo -e "==================================================="
echo -e "URL of admin panel: http://10.0.10.11/horizon"
echo -e "   domain:   ${COLOR}default${NC}"
echo -e "   user:     ${COLOR}admin${NC}"
echo -e "   password: ${COLOR}xxxx${NC}"
echo -e "==================================================="