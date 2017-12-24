#https://moodle.lab.dit.upm.es/pluginfile.php/16194/mod_resource/content/4/cnvr-trabajo-final.pdf

# Salir del script si alguna de las ejecuciones falla.
set -e

# ======================================================================================================================================
# Default parameters
# ======================================================================================================================================

WORKING_DIRECTORY=/tmp/CNVR


# ======================================================================================================================================
# Auxiliar functions
# ======================================================================================================================================

# Funcion para imprimir '=' hasta el final de la linea.
line () {
	for i in $(seq 1 $(stty size | cut -d' ' -f2)); do 
		echo -n "="
	done
	echo ""
}

# Imprime ayuda por pantalla.
print_help () {
	echo "Parámetros:"
	echo ""
	echo "   --size=n:  levanta n procesos. Por defecto: 3."
	echo "   --debug:   activa o desactiva el modo debug. Por defecto: desactivado."
	echo ""
	echo "Ejemplos:"
	echo ""
	echo "   ./zookeeper.sh"
	echo "   ./zookeeper.sh --size=4"
	echo "   ./zookeeper.sh --size=4 --debug"
}


# ======================================================================================================================================
# Parameter comprobation
# ======================================================================================================================================




# ======================================================================================================================================
# Main
# ======================================================================================================================================

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


# ======================================================================================================================================
# HOT (Heat) Templates for creating scenario
# ======================================================================================================================================

# Si existe el repo, hacer pull; si no, clonar.
if [ -d "$WORKING_DIRECTORY/zookeeper_openstack" ]; then
	cd $WORKING_DIRECTORY/zookeeper_openstack && git pull
else
	cd $WORKING_DIRECTORY && git clone https://github.com/revilla-92/zookeeper_openstack.git
fi


#######################################################################################################################################
######################################## Comandos para ejecutar plantillas ############################################################
#######################################################################################################################################

#######################################################################################################################################
#######################################################################################################################################
#######################################################################################################################################



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

