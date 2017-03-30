#!/bin/bash -x

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

LMON=$(hostname -s)
CUSER=ceph
CGROUP=ceph

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}
JPART=1
DPART=2

COUNITF="ceph-osd@.service"
#CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"
MYUNITDIR="/etc/systemd/system/"

CLUSTER_NAME="cephorium"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

# IDs
OSD_UID=$(uuidgen)
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}
OSD_ID=$(ceph -c ${CLUSTER_CONF} --cluster ${CLUSTER_NAME} osd create)

echo ${OSD_ID}

#ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush add-bucket $(hostname -s) host
#ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush move $(hostname -s) root=default

# Create the default directories
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}
# mkdir /var/lib/ceph/osd/ceph-0

# prepare hdd
echo "which (h|v)dd should be prepared ?"
read CDISK
#ceph-disk zap /dev/${CDISK}
parted /dev/${CDISK} --script -- mklabel gpt
#parted /dev/${CDISK} --script -- mkpart primary xfs 1MB 2GB
#parted /dev/${CDISK} --script -- name 1 journal-for-${CLUSTER_NAME}-${OSD_ID}
#parted /dev/${CDISK} --script -- mkpart primary xfs 2GB -1
#parted /dev/${CDISK} --script -- name 2 data-for-${CLUSTER_NAME}-${OSD_ID}

#parted /dev/${CDISK} --script -- mkpart primary xfs 1MB -1
#parted /dev/${CDISK} --script -- name 1 data-for-${CLUSTER_NAME}-${OSD_ID}

#ceph-disk prepare --cluster ${CLUSTER_NAME} --cluster-uuid ${CLUSTER_FSID} --fs-type xfs /dev/${CDISK}${DPART} /dev/${CDISK}${JPART}

# format and mount hdd
#mkfs.xfs -f -L "${CLUSTER_NAME}-${OSD_ID}" /dev/${CDISK}${DPART}
mkfs.xfs -f -L "${CLUSTER_NAME}-${OSD_ID}" /dev/${CDISK}
#mount /dev/${CDISK}${DPART} /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}
mount /dev/${CDISK} /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}
chown -R ceph. /var/lib/ceph/osd/

# put it into fstab
echo "/dev/${CDISK}       /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab

# create keyring
#ceph-osd -c ${CLUSTER_CONF} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey --osd-uuid ${OSD_UID}
ceph-osd -c ${CLUSTER_CONF} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey

#ceph-osd -c ${CLUSTER_CONF} -i ${OSD_ID} --mkfs --mkkey
#ceph-osd -i 0 --mkfs --mkkey --osd-uuid 1ee9e4c0-c962-4453-abd5-b2329896bb42

# add osd to cluster
ceph -c ${CLUSTER_CONF} auth add osd.${OSD_ID} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/keyring
#ceph auth add osd.0 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-0/keyring

ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush add osd.${OSD_ID} 1.0 host=$(hostname -s)
#ceph --cluster ceph osd crush add osd.0 1.0 host=$(hostname -s)

# activate journal
##ceph-osd -c ${CLUSTER_CONF} -i ${OSD_ID} --mkjournal --osd-journal /dev/${CDISK}${JPART}
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/journal
ceph-osd -c ${CLUSTER_CONF} -i ${OSD_ID} --mkjournal --osd-journal /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/journal
#ceph-osd -i 0 --mkjournal --osd-journal /dev/vdb1

# copy unit-files and replace clustername
cp ${UNITDIR}${COUNITF} ${MYUNITDIR}

sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${MYUNITDIR}${COUNITF} 

systemctl daemon-reload
systemctl enable ceph-osd@${OSD_ID}.service
systemctl start ceph-osd@${OSD_ID}.service

exit 0