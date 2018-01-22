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
if ! [[ $N_SERVERS =~ $re ]] ; then
   N_ZK_SERVERS=3
fi

# Print number of servers that are going to be deployed.
echo -e "Se levantaran $N_ZK_SERVERS maquinas en el entorno zookeeper."
echo -e ""
###################################################################################


#################################################################################################
################################### Funciones auxiliares ########################################
#################################################################################################

# Print command help.




#################################################################################################
############################################ Main ###############################################
#################################################################################################

# Move admin-openrc.sh and demo-openrc.sh to current directory.
if [ ! -f admin-openrc.sh ]; then
    mv Downloads/admin-openrc.sh .
fi
if [ ! -f admin-openrc.sh ]; then
    mv Downloads/demo-openrc.sh .
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


#####################
# SCENARIO CREATION #
#####################

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


################################################################################
################################################################################

# WAIT UNTIL ROUTER AND NETWORKS STACKS ARE COMPLETED.
COMMAND BLA BLA 

################################################################################
################################################################################


################################################################################
################################################################################

# Salida del comando: openstack stack output show --all network1_stack
NET1_ID=6688bd51-abfd-45a1-9d1b-d24792f2764f
SUBNET1_ID=a9b2b93d-abd2-4c88-8726-2bedc3d1d8f6

# Salida del comando: openstack stack output show --all network2_stack
NET2_ID=ac907fa5-e00a-45a9-9b1c-c50be169ac43
SUBNET2_ID=eac44787-5029-4e82-98bc-8423cfd6e5ac

# Salida del comando: openstack stack output show --all router_stack
ROUTER_ID=6fbeb4db-467d-44e2-bf6b-3d6b3590920b

# Salida del comando: openstack stack output show --all security_group_stack
SECURITY_GROUP_ID=08d7271f-7d94-4ce8-9204-0ab69f827cf6

################################################################################
################################################################################

# Router Associations
openstack stack create --parameter "router_id=${ROUTER_ID}" --parameter "subnet_id=${SUBNET1_ID}" -t ./templates/router-interface.yml router_interface1_stack
openstack stack create --parameter "router_id=${ROUTER_ID}" --parameter "subnet_id=${SUBNET2_ID}" -t ./templates/router-interface.yml router_interface2_stack

# Create Load Balancer
openstack stack create --parameter "subnet=${SUBNET1_ID}" -t ./templates/load-balancer.yml lbaas_stack

# FireWall
openstack stack create --parameter "subnet1=${SUBNET1_CIDR}" --parameter "subnet2=${SUBNET2_CIDR}" --parameter "router=${ROUTER_ID}" -t ./templates/firewall.yml firewall_stack

# Create Servers
openstack stack create --parameter "server_name=server1" --parameter "key_name=key2" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET1_ID}" --parameter "subnet=${SUBNET1_ID}" -t ./templates/server.yml server1_stack
openstack stack create --parameter "server_name=server2" --parameter "key_name=key3" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET1_ID}" --parameter "subnet=${SUBNET1_ID}" -t ./templates/server.yml server2_stack
openstack stack create --parameter "server_name=server3" --parameter "key_name=key4" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET1_ID}" --parameter "subnet=${SUBNET1_ID}" -t ./templates/server.yml server3_stack


################################################################################
################################################################################

# Recover private IP Address from servers: openstack stack output show --all server1_stack
SERVER1_IP=10.1.1.17

# Recover private IP Address from servers: openstack stack output show --all server2_stack
SERVER2_IP=10.1.1.13

# Recover private IP Address from servers: openstack stack output show --all server3_stack
SERVER3_IP=10.1.1.21

# Recover pool from loadbalancer: openstack stack output show --all lbaas_stack
POOL_ID=4eeff086-458a-4a03-88f2-67ef47150453

################################################################################
################################################################################


# Create Pool Members for load balancer
openstack stack create --parameter "subnet=${SUBNET1_ID}" --parameter "pool=${POOL_ID}" --parameter "server_ip=${SERVER1_IP}" -t ./templates/pool-member.yml pool_member1_stack
openstack stack create --parameter "subnet=${SUBNET1_ID}" --parameter "pool=${POOL_ID}" --parameter "server_ip=${SERVER2_IP}" -t ./templates/pool-member.yml pool_member2_stack
openstack stack create --parameter "subnet=${SUBNET1_ID}" --parameter "pool=${POOL_ID}" --parameter "server_ip=${SERVER3_IP}" -t ./templates/pool-member.yml pool_member3_stack

# Admin Server
openstack stack create --parameter "server_name=Admin_Server" --parameter "key_name=key1" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET1_ID}" --parameter "subnet=${SUBNET1_ID}" -t ./templates/admin-server.yml admin-server_stack

# Create Zookeeper ensemble
openstack stack create --parameter "server_name=zk1" --parameter "key_name=key5" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET2_ID}" --parameter "subnet=${SUBNET2_ID}" --parameter "fixed_ip_address=10.1.2.15" -t ./templates/zk-server.yml zk1_stack
openstack stack create --parameter "server_name=zk2" --parameter "key_name=key6" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET2_ID}" --parameter "subnet=${SUBNET2_ID}" --parameter "fixed_ip_address=10.1.2.16" -t ./templates/zk-server.yml zk2_stack
openstack stack create --parameter "server_name=zk3" --parameter "key_name=key7" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET2_ID}" --parameter "subnet=${SUBNET2_ID}" --parameter "fixed_ip_address=10.1.2.17" -t ./templates/zk-server.yml zk3_stack

# Create Database server
openstack stack create --parameter "server_name=DataBase" --parameter "key_name=key8" --parameter "securityGroup=${SECURITY_GROUP_ID}" --parameter "net=${NET2_ID}" --parameter "subnet=${SUBNET2_ID}" --parameter "fixed_ip_address=10.1.2.50" -t ./templates/database-server.yml database_stack


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