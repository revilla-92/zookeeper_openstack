#################################################################################################
######################################### Variables #############################################
#################################################################################################

# Regular expression for detecting if a variable is a number.
re='^[0-9]+$'

#################################### N_SERVERS ####################################
# Variable of number of servers that the user can introduce.
echo -e "Cuantos servidores desea levantar (introduzca un numero). ENTER (Por defecto 3): "
read -sr N_SERVERS

# If input is not a number we assign default N_SERVERS to 3.
if ! [[ $N_SERVERS =~ $re ]] ; then
   N_SERVERS=3
fi

# Print number of servers that are going to be deployed.
echo -e "Se levantaran $N_SERVERS servidores."
echo -e ""
###################################################################################

################################## N_ZK_SERVERS ###################################
# Variable of number of zookeeper server that the user can introduce.
echo -e "Cuantas maquinas desea que tenga el entorno zookeeper (introduzca un numero). ENTER (Por defecto 3): "
read -sr N_ZK_SERVERS

# If input is not a number we assign default N_SERVERS to 3.
if ! [[ $N_ZK_SERVERS =~ $re ]] ; then
   N_ZK_SERVERS=3
fi

# Print number of servers that are going to be deployed.
echo -e "Se levantaran $N_ZK_SERVERS maquinas en el entorno zookeeper."
echo -e ""
###################################################################################

# Move admin-openrc.sh and demo-openrc.sh to current directory.
if [ ! -f admin-openrc.sh ]; then
    mv ~/Downloads/admin-openrc.sh .
fi
if [ ! -f demo-openrc.sh ]; then
    mv ~/Downloads/demo-openrc.sh .
fi

# Change lines in both admin and demo openrc so there is no need to introduce password.
sed -i '/echo "Please enter your OpenStack Password for project $OS_PROJECT_NAME as user $OS_USERNAME: "/d' ./admin-openrc.sh
sed -i '/echo "Please enter your OpenStack Password for project $OS_PROJECT_NAME as user $OS_USERNAME: "/d' ./demo-openrc.sh
sed -i 's/read -sr OS_PASSWORD_INPUT/OS_PASSWORD_INPUT=xxxx/g' ./admin-openrc.sh
sed -i 's/read -sr OS_PASSWORD_INPUT/OS_PASSWORD_INPUT=xxxx/g' ./demo-openrc.sh

# Get admin access in order to create external network and subnetwork
source admin-openrc.sh
openstack network create --share --external --provider-physical-network provider --provider-network-type flat ExtNet
openstack subnet create --network ExtNet --gateway 10.0.10.1 --dns-nameserver 10.0.10.1 --subnet-range 10.0.10.0/24 --allocation-pool start=10.0.10.100,end=10.0.10.200 ExtSubNet

# Stablish NAT configuration with ExtNet to Internet.
sudo vnx_config_nat ExtNet enp1s0

# Get demo access in order to create scenario.
source demo-openrc.sh


#################################################################################################
####################################### SCENARIO CREATION #######################################
#################################################################################################

# Parametros de entrada a la hora de crear las redes.
SUBNET1_CIDR=10.1.1.0/24
SUBNET2_CIDR=10.1.2.0/24

# Networks & SubNetworks:
openstack stack create --parameter "net_name=net1" --parameter "subnet_name=subnet1" --parameter "gateway_ip=10.1.1.1" --parameter "subnet_cidr=${SUBNET1_CIDR}" --parameter "start_allocation_pool=10.1.1.8" --parameter "end_allocation_pool=10.1.1.100" -t ./templates/network.yml network1_stack
openstack stack create --parameter "net_name=net2" --parameter "subnet_name=subnet2" --parameter "gateway_ip=10.1.2.1" --parameter "subnet_cidr=${SUBNET2_CIDR}" --parameter "start_allocation_pool=10.1.2.8" --parameter "end_allocation_pool=10.1.2.100" -t ./templates/network.yml network2_stack

# Security Group
openstack stack create --parameter "security_name=Security_Group" -t ./templates/security_group.yml security_group_stack

# Router 
openstack stack create --parameter "router_name=r1" -t ./templates/router.yml router_stack

# Recover Net and Subnet ID of Network1 from created stack.
openstack stack output show --all -f json network1_stack > net1.json
SUBNET1_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" net1.json | head -1)
NET1_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" net1.json | tail -n1)

# Recover Net and Subnet ID of Network1 from created stack.
openstack stack output show --all -f json network2_stack > net2.json
SUBNET2_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" net2.json | head -1)
NET2_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" net2.json | tail -n1)

# Recover Router ID from created stack.
openstack stack output show --all -f json router_stack > router.json
ROUTER_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" router.json | head -1)

# Recover Security Group ID.
openstack stack output show --all -f json security_group_stack > security.json
SECURITY_GROUP_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" security.json | head -1)

# Delete JSON Files
rm -rf net1.json
rm -rf net2.json
rm -rf router.json
rm -rf security.json

# Router Associations
openstack stack create --parameter "router_id=${ROUTER_ID}" --parameter "subnet_id=${SUBNET1_ID}" -t ./templates/router-interface.yml router_interface1_stack
openstack stack create --parameter "router_id=${ROUTER_ID}" --parameter "subnet_id=${SUBNET2_ID}" -t ./templates/router-interface.yml router_interface2_stack

# Create Load Balancer
openstack stack create --parameter "subnet=${SUBNET1_ID}" -t ./templates/load-balancer.yml lbaas_stack

# FireWall
openstack stack create --parameter "subnet1=${SUBNET1_CIDR}" --parameter "subnet2=${SUBNET2_CIDR}" --parameter "router=${ROUTER_ID}" -t ./templates/firewall.yml firewall_stack

# Recover Pool ID for adding new Pool Members.
openstack stack output show --all -f json lbaas_stack > lbaas.json
POOL_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" lbaas.json | head -1)

# Wait until the lbaas stack is created
while true; do
	openstack stack output show --all -f json lbaas_stack > lbaas.json
	POOL_ID=$(grep -Eo "[a-z0-9]{8,8}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{4,4}-[a-z0-9]{12,12}" lbaas.json | head -1)
	if [[ -z $POOL_ID ]]; then
        break
	fi
	rm -rf lbaas.json
    	sleep 1
done

# Create Servers
for (( COUNTER = 0; COUNTER < ${N_SERVERS}; COUNTER++ )); 
do
	openstack stack create --parameter "server_name=server$((COUNTER+1))" --parameter "key_name=key$((COUNTER+1))" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET1_ID}" --parameter "subnet=${SUBNET1_ID}" --parameter "pool_id=${POOL_ID}" -t ./templates/server.yml server$((COUNTER+1))_stack
done

# Admin Server
openstack stack create --parameter "server_name=Admin_Server" --parameter "key_name=keyAdmin" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET1_ID}" --parameter "subnet=${SUBNET1_ID}" -t ./templates/admin-server.yml admin-server_stack
# Create Zookeeper ensemble
for (( CONTADOR = 0; CONTADOR < ${N_ZK_SERVERS}; CONTADOR++ )); 
do
	openstack stack create --parameter "server_name=zk$((CONTADOR+1))" --parameter "key_name=key$((CONTADOR+N_SERVERS+1))" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET2_ID}" --parameter "subnet=${SUBNET2_ID}" --parameter "fixed_ip_address=10.1.2.$((CONTADOR+15))" -t ./templates/zk-server.yml zk$((CONTADOR+1))_stack
done

# Create Database server
openstack stack create --parameter "server_name=DataBase" --parameter "key_name=keyDB" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET2_ID}" --parameter "subnet=${SUBNET2_ID}" --parameter "fixed_ip_address=10.1.2.50" -t ./templates/database-server.yml database_stack

# End echoes
echo -e "======================================================================================="
echo -e "In order to validate template execute next command:"
echo -e "	openstack orchestration template validate -t XXXXXXX.yml"
echo -e ""
echo -e "In order to re-execute XXXXX.yml template execute next command:"
echo -e "	openstack stack create -t XXXXXXX.yml YYYYYYY"
echo -e "======================================================================================="

#############################################################################################
#############################################################################################
#############################################################################################
