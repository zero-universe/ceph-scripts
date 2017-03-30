#!/bin/bash -x

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

LMON=$(hostname -s)
echo "what is the cluster's subnet: "
read SUBNET

echo "list all hostnames of the initial mons, seperator is a coma:"
read AMON

echo "list all ip of the initial mons, seperator is a coma:"
read AMIP

echo "what's the cluster's name: "
read CLUSTER_NAME

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="/etc/ceph/${CLUSTER_NAME}.mon.keyring"


### create config file and fill it
> ${CLUSTER_CONF}

echo "[global]" >> ${CLUSTER_CONF}

# create fsid
FSID=$(uuidgen)
echo "fsid = ${FSID}" >> ${CLUSTER_CONF}

# initial mons
echo "mon initial members = ${AMON}" >> ${CLUSTER_CONF}
echo "mon host = ${AMIP}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "public network = ${SUBNET}" >> ${CLUSTER_CONF}
#echo "cluster network = ${SUBNET}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "auth cluster required = cephx" >> ${CLUSTER_CONF}
echo "auth service required = cephx" >> ${CLUSTER_CONF}
echo "auth client required = cephx" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "#osd journal size = 1024" >> ${CLUSTER_CONF}
echo "osd pool default size = 2" >> ${CLUSTER_CONF}
echo "osd pool default min size = 1" >> ${CLUSTER_CONF}
echo "osd pool default pg num = 1024" >> ${CLUSTER_CONF}
echo "osd pool default pgp num = 1024" >> ${CLUSTER_CONF}
echo "osd crush chooseleaf type = 1" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

echo "cluster=${CLUSTER_NAME}" > /etc/sysconfig/ceph

# Create a keyring for your cluster and generate a monitor secret key
ceph-authtool --create-keyring ${CLUSTER_NAME}.mon.keyring --gen-key -n mon. --cap mon 'allow *'
#ceph-authtool --create-keyring ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.$(echo $AMON | awk 'BEGIN {FS=","} {print $1}') --cap mon 'allow *'
#ceph-authtool -C ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.$(echo $AMON | awk 'BEGIN {FS=","} {print $1}') --cap mon 'allow *'


# Generate an administrator keyring, generate a client.admin user and add the user to the keyring.
ceph-authtool --create-keyring ${CLUSTER_NAME}.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'


# Add the client.admin key to the ceph.mon.keyring
ceph-authtool ${CLUSTER_NAME}.mon.keyring --import-keyring ${CLUSTER_NAME}.client.admin.keyring


# Create a default data directory (or directories) on the monitor host
mkdir -p /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}


# create mon keys
#ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring /var/lib/ceph/mon/${CLUSTER_NAME}-${INMON}/keyring
ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring ${MON_KEYRING}


# Generate a monitor map using the hostname(s), host IP address(es) and the FSID. Save it as monmap
#monmaptool --create --add ${LMON} ${MIP}:6789 --fsid ${FSID} monmap
#monmaptool  --create  --add  mon.a 192.168.0.10:6789 --add mon.b 192.168.0.11:6789 --add mon.c 192.168.0.12:6789 --clobber monmap
#monmaptool --create --add $(echo $AMON | awk 'BEGIN {FS=","} {print $2}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $2}'):6789 monmap
monmaptool --create --add $(echo $AMON | awk 'BEGIN {FS=","} {print $1}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $1	}'):6789 \
--add $(echo $AMON | awk 'BEGIN {FS=","} {print $2}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $2}'):6789 \
--add $(echo $AMON | awk 'BEGIN {FS=","} {print $3}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $3}'):6789 monmap
#monmaptool --add $(echo $AMON | awk 'BEGIN {FS=","} {print $2}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $2}'):6789 monmap
#monmaptool --add $(echo $AMON | awk 'BEGIN {FS=","} {print $3}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $3}'):6789 monmap

# schlitzer-edition:
#monmaptool --create $MON_MAP_HOSTS --fsid $FSID /tmp/monmap

# Mark that the monitor is created and ready to be started
> /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/done
cp ${MON_KEYRING} /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/keyring

# change owner-ship
chown -R ceph. /var/lib/ceph

# distribute the keys
echo "rsyncing keys"
for i in $(echo ${AMON} | tr ',' ' '); do
	rsync -a ${CPWD} ${i}:/etc/
done	


exit 0