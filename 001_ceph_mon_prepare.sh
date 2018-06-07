#!/bin/bash 

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 4 ]; then
	echo "Usage: $0 <cluster_name> <subnet> <mons_hostname> <mons_ip>" 
	echo "Example: $0 ceph-test 10.0.0.0/8 server01,server02 10.0.0.1,10.0.0.2"
	exit 1
fi

LMON=$(hostname -s)

# cluster_name
CLUSTER_NAME=$1

# pub subnet
SUBNET=$2

# initial mons
AMON=$3

# ips of the initial mons
AMIP=$4

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="/etc/ceph/${CLUSTER_NAME}.mon.keyring"

CMUNITF="ceph-mon@.service"
#CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"
CEPHAUTH=$(which ceph-authtool)

### create config file and fill it
> ${CLUSTER_CONF}

echo "[global]" >> ${CLUSTER_CONF}

# create fsid
FSID=$(uuidgen)
echo "fsid = ${FSID}" >> ${CLUSTER_CONF}

# initial mons
echo "mon_initial_members = ${AMON}" >> ${CLUSTER_CONF}
echo "mon_host = ${AMIP}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "public_network = ${SUBNET}" >> ${CLUSTER_CONF}
#echo "cluster network = ${PSUBNET}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "auth_cluster_required = cephx" >> ${CLUSTER_CONF}
echo "auth_service_required = cephx" >> ${CLUSTER_CONF}
echo "auth_client_required = cephx" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "osd_journal_size = 4096" >> ${CLUSTER_CONF}
echo "osd_pool_default_size = 2" >> ${CLUSTER_CONF}
echo "osd_pool_default_min_size = 1" >> ${CLUSTER_CONF}
echo "osd_pool_default_pg_num = 1024" >> ${CLUSTER_CONF}
echo "osd_pool_default_pgp_num = 1024" >> ${CLUSTER_CONF}
echo "osd_crush_chooseleaf_type = 1" >> ${CLUSTER_CONF}
#echo "mds_cache size = 900000" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}


#if [ -d /etc/sysconfig ]; then
	#echo "cluster=${CLUSTER_NAME}" > /etc/sysconfig/ceph
#fi


# Create a default data directory (or directories) on the monitor host
mkdir -p /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}
mkdir -p /var/lib/ceph/bootstrap-{osd,mon,mgr,mds}
mkdir -p /var/lib/ceph/{osd,mon,mgr,mds}
chown -R ceph. /var/lib/ceph


# Create a keyring for your cluster and generate a monitor secret key
${CEPHAUTH} --create-keyring ${CLUSTER_NAME}.mon.keyring --gen-key -n mon. --cap mon 'allow *'


# Generate an administrator keyring, generate a client.admin user and add the user to the keyring.
${CEPHAUTH} --create-keyring ${CLUSTER_NAME}.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'


# Generate a bootstrap-osd keyring, generate a client.bootstrap-osd user and add the user to the keyring.
${CEPHAUTH} --create-keyring /var/lib/ceph/bootstrap-osd/${CLUSTER_NAME}.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd'


# Add the client.admin key to the ceph.mon.keyring
${CEPHAUTH} ${CLUSTER_NAME}.mon.keyring --import-keyring ${CLUSTER_NAME}.client.admin.keyring
${CEPHAUTH} ${CLUSTER_NAME}.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/${CLUSTER_NAME}.keyring


# create mon keys
ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring ${MON_KEYRING}


# Generate a monitor map using the hostname(s), host IP address(es) and the FSID. Save it as monmap
#monmaptool  --create  --add  mon.a 192.168.0.10:6789 --add mon.b 192.168.0.11:6789 --add mon.c 192.168.0.12:6789 --clobber monmap
monmaptool --create --add $(echo $AMON | awk 'BEGIN {FS=","} {print $1}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $1	}'):6789 \
--add $(echo $AMON | awk 'BEGIN {FS=","} {print $2}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $2}'):6789 \
--add $(echo $AMON | awk 'BEGIN {FS=","} {print $3}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $3}'):6789 monmap


# Mark that the monitor is created and ready to be started
> /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/done
cp ${MON_KEYRING} /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/keyring


# change owner-ship
chown -R ceph. /var/lib/ceph


# copy unit-files and replace clustername
#sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${CMUNITF} 
#sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${CKUNITF} 

systemctl daemon-reload

#systemctl restart ceph-create-keys@${LMON}.service
systemctl start ceph-mon@${LMON}.service
systemctl enable ceph-mon@${LMON}.service


# distribute the keys
echo "rsyncing keys"
for i in $(echo ${AMON} | tr ',' ' '); do
	rsync -a ${CPWD} ${i}:/etc/
done	


# append host specific part to config must not be rsynced !
echo "[mon.${LMON}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
echo "mon_path = /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}



exit 0