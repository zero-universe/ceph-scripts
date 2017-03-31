#!/bin/bash -x

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

LMON=$(hostname -s)
CUSER=ceph
CGROUP=ceph

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

#echo "what's the data partition: "
#read DATAPART

echo "where will the journal be saved: "
read JOURNALPOINT

echo "what's the cluster's name: "
read CLUSTER_NAME

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

# IDs
OSD_UID=$(uuidgen)
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}
OSD_ID=$(ceph -c ${CLUSTER_CONF} --cluster ${CLUSTER_NAME} osd create) && echo ${OSD_ID}

# Create the default directories
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}
#mkdir -p ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal

# prepare hdd
echo "which (h|v)dd should be prepared ?"
read CDISK
sgdisk -z /dev/${CDISK}
parted /dev/${CDISK} --script -- mklabel gpt
parted /dev/${CDISK} --script -- mkpart primary xfs 0 -1
#parted /dev/${CDISK} --script -- name 1 journal-for-${CLUSTER_NAME}-${OSD_ID}

# format and mount hdd
#mkfs.xfs -f -L "${CLUSTER_NAME}-${OSD_ID}" /dev/${DATAPART}
mkfs.xfs -f -L "osd${OSD_ID}" /dev/${CDISK}1

# put it into fstab
#echo "/dev/${CDISK}1	/var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f4) /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab

# append to config
echo "[osd.${OSD_ID}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
echo "osd data = /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}" >> ${CLUSTER_CONF}
echo "osd journal = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

mount -a
chown -R ceph. /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

#systemctl restart ceph-create-keys@${LMON}.service

# create keyring
#ceph-osd -c ${CLUSTER_CONF} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey --osd-uuid ${OSD_UID}
ceph-osd --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey

#ceph-osd -c ${CLUSTER_CONF} -i ${OSD_ID} --mkfs --mkkey
#ceph-osd -i 0 --mkfs --mkkey --osd-uuid 1ee9e4c0-c962-4453-abd5-b2329896bb42

# add osd to cluster
ceph -c ${CLUSTER_CONF} auth add osd.${OSD_ID} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/keyring
#ceph auth add osd.0 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-0/keyring

ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush add osd.${OSD_ID} 1.0 host=$(hostname -s)
#ceph --cluster ceph osd crush add osd.0 1.0 host=$(hostname -s)

systemctl enable ceph-osd@${OSD_ID}.service
systemctl start ceph-osd@${OSD_ID}.service

exit 0