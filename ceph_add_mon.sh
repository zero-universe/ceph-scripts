#!/bin/bash 

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

LMON=$(hostname -s)

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_NAME="cephorium"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="/etc/ceph/${CLUSTER_NAME}.mon.keyring"
MONMAP="${CPWD}/monmap"

CMUNITF="ceph-mon@.service"
CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"
MYUNITDIR="/etc/systemd/system/"

CLUSTER_NAME="cephorium"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="/etc/ceph/${CLUSTER_NAME}.mon.keyring"


# get fsid
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}

echo own ip:
MIP=$(ip a | grep 192 | cut -d' ' -f6 | cut -d'/' -f1)
echo ${MIP}

# Create a default data directory (or directories) on the monitor host
mkdir -p /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}

# ?? ceph-authtool --create-keyring cephorium.mon.keyring --gen-key -n mon.$(hostname -s) --cap mon 'allow *'

# create mon keys
#ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring /var/lib/ceph/mon/${CLUSTER_NAME}-${INMON}/keyring
ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring ${MON_KEYRING}

# Generate a monitor map using the hostname(s), host IP address(es) and the FSID. Save it as monmap
#monmaptool --add ${LMON} ${MIP}:6789 monmap
#monmaptool --add arch-serv02 192.168.122.4:6789 monmap


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

systemctl start ceph-create-keys@${LMON}.service
systemctl start ceph-mon@${LMON}.service
systemctl enable ceph-mon@${LMON}.service

exit 0
