#!/bin/bash 

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

LMON=$(hostname -s)

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

echo "what's the cluster's name: "
read CLUSTER_NAME

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"
MONMAP="${CPWD}/monmap"

CMUNITF="ceph-mon@.service"
CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"
MYUNITDIR="/etc/systemd/system/"

# get fsid
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}

echo "cluster=${CLUSTER_NAME}" > /etc/sysconfig/ceph

### fill config

echo "[mon.${LMON}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
echo "mon path = /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}


# Create a default data directory (or directories) on the monitor host
mkdir -p /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}

# ?? ceph-authtool --create-keyring cephorium.mon.keyring --gen-key -n mon.$(hostname -s) --cap mon 'allow *'

# create mon keys
#ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring /var/lib/ceph/mon/${CLUSTER_NAME}-${INMON}/keyring
ceph-mon -f --cluster ${CLUSTER_NAME} --id ${LMON} --mkfs --keyring ${MON_KEYRING} --monmap monmap


# Mark that the monitor is created and ready to be started
> /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/done
cp ${MON_KEYRING} /var/lib/ceph/mon/${CLUSTER_NAME}-${LMON}/keyring


# change owner-ship
chown -R ceph. /var/lib/ceph

# restart key-gen
#systemctl restart ceph-create-keys@${LMON}.service

# copy unit-files and replace clustername
cp ${UNITDIR}${CMUNITF} ${MYUNITDIR}
cp ${UNITDIR}${CKUNITF} ${MYUNITDIR}
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${MYUNITDIR}${CMUNITF} 
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${MYUNITDIR}${CKUNITF} 

systemctl daemon-reload

systemctl restart ceph-create-keys@${LMON}.service
systemctl start ceph-mon@${LMON}.service
systemctl enable ceph-mon@${LMON}.service

exit 0
