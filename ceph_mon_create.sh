#!/bin/bash -x

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

LMON=$(hostname -s)
SUBNET="192.168.122.0/24"

echo "list all hostnames of the initial mons, seperator is a coma:"
read AMON

echo "list all ip of the initial mons, seperator is a coma:"
read AMIP

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}



CMUNITF="ceph-mon@.service"
CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"
MYUNITDIR="/etc/systemd/system/"

CLUSTER_NAME="cephorium"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="/etc/ceph/${CLUSTER_NAME}.mon.keyring"


# create config file
> ${CLUSTER_CONF}


echo "[global]" >> ${CLUSTER_CONF}


# create fsid
FSID=$(uuidgen)
echo "fsid = ${FSID}" >> ${CLUSTER_CONF}


# initial mon name
#echo "initial mon is needed ... what's its name? "
#read INMON
#echo "mon initial members = ${INMON}" >> ${CLUSTER_CONF}
#echo "mon initial members = ${LMON}" >> ${CLUSTER_CONF}
echo "mon initial members = ${AMON}" >> ${CLUSTER_CONF}


# mon's ip
#echo "what's the mon's ip ?"
#read MIP
echo own ip:
MIP=$(ip a | grep 192 | cut -d' ' -f6 | cut -d'/' -f1)
echo ${MIP}
#echo "mon host = ${MIP}" >> ${CLUSTER_CONF}
echo "mon host = ${AMIP}" >> ${CLUSTER_CONF}
echo "public network = ${SUBNET}" >> ${CLUSTER_CONF}
echo "cluster network = ${SUBNET}" >> ${CLUSTER_CONF}
echo "auth cluster required = cephx" >> ${CLUSTER_CONF}
echo "auth service required = cephx" >> ${CLUSTER_CONF}
echo "auth client required = cephx" >> ${CLUSTER_CONF}
echo "#osd journal size = 1024" >> ${CLUSTER_CONF}
echo "osd pool default size = 2" >> ${CLUSTER_CONF}
echo "osd pool default min size = 1" >> ${CLUSTER_CONF}
echo "osd pool default pg num = 333" >> ${CLUSTER_CONF}
echo "osd pool default pgp num = 333" >> ${CLUSTER_CONF}
echo "osd crush chooseleaf type = 1" >> ${CLUSTER_CONF}

# Create a keyring for your cluster and generate a monitor secret key
#ceph-authtool --create-keyring ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.${LMON} --cap mon 'allow *'
ceph-authtool --create-keyring ${CLUSTER_NAME}.mon.keyring --gen-key -n mon. --cap mon 'allow *'
#ceph-authtool --create-keyring ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.$(echo $AMON | awk 'BEGIN {FS=","} {print $1}') --cap mon 'allow *'
#ceph-authtool -C ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.$(echo $AMON | awk 'BEGIN {FS=","} {print $1}') --cap mon 'allow *'
#ceph-authtool ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.$(echo $AMON | awk 'BEGIN {FS=","} {print $2}') --cap mon 'allow *'
#ceph-authtool ${CLUSTER_NAME}.mon.keyring --gen-key -n mon.$(echo $AMON | awk 'BEGIN {FS=","} {print $3}') --cap mon 'allow *'


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
--add $(echo $AMON | awk 'BEGIN {FS=","} {print $2}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $2}'):6789 monmap \
--add $(echo $AMON | awk 'BEGIN {FS=","} {print $3}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $3}'):6789
#monmaptool --add $(echo $AMON | awk 'BEGIN {FS=","} {print $2}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $2}'):6789 monmap
#monmaptool --add $(echo $AMON | awk 'BEGIN {FS=","} {print $3}') $(echo $AMIP | awk 'BEGIN {FS=","} {print $3}'):6789 monmap

# Mark that the monitor is created and ready to be started
> /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/done
cp ${MON_KEYRING} /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/keyring


# change owner-ship
chown -R ceph. /var/lib/ceph


# restart key-gen
systemctl restart ceph-create-keys@${LMON}.service


# copy unit-files and replace clustername
cp ${UNITDIR}${CMUNITF} ${MYUNITDIR}
cp ${UNITDIR}${CKUNITF} ${MYUNITDIR}

sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${MYUNITDIR}${CMUNITF} 
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${MYUNITDIR}${CKUNITF} 

systemctl daemon-reload
#systemctl start ceph-create-keys@${LMON}.service
systemctl enable ceph-mon@${LMON}.service
systemctl start ceph-mon@${LMON}.service

exit 0