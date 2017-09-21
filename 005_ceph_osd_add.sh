#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 3 ]; then
	echo "Usage: $0 <cluster_name> <hdd_for_ceph_data> <mountpoint_for_ceph_journal>" 
	echo "Example: $0 ceph-test sdc /mnt/sdb"
	exit 1
fi

LMON=$(hostname -s)
CUSER=ceph
CGROUP=ceph

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

CLUSTER_NAME=$1

#DATAPART=$2
CDISK=$2

JOURNALPOINT=$3

# IDs
OSD_UID=$(uuidgen)
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}
OSD_ID=$(ceph -c ${CLUSTER_CONF} --cluster ${CLUSTER_NAME} osd create) && echo ${OSD_ID}

# Create the default directories
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# prepare hdd
sgdisk -z /dev/${CDISK}
sleep 1
parted /dev/${CDISK} -s -a optimal -- mklabel gpt
sleep 1
#parted  /dev/${CDISK} -s -a optimal -- mkpart primary xfs 0 -1
parted /dev/${CDISK} -s -a optimal -- mkpart primary xfs 0% 100%
sleep 1
parted /dev/${CDISK} -s -a optimal -- name 1 data-for-${CLUSTER_NAME}-${OSD_ID}
sleep 1

# format and mount hdd
mkfs.xfs -f -L "osd${OSD_ID}" /dev/${CDISK}1

# put it into fstab
#echo "/dev/${CDISK}1	/var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo "# /dev/${CDISK}" >> /etc/fstab
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f4) /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo -n -e "\n" >> /etc/fstab

# append to config
echo "[osd.${OSD_ID}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
echo "osd data = /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}" >> ${CLUSTER_CONF}
echo "osd journal = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

mount -a
chown -R ceph. /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# create keyring
ceph-osd --cluster ${CLUSTER_NAME} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey

# add osd to cluster
ceph -c ${CLUSTER_CONF} auth add osd.${OSD_ID} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/keyring

# set weight to 1.0
ceph --cluster ${CLUSTER_NAME} osd crush add osd.${OSD_ID} 1.0 host=${LMON}

systemctl enable ceph-osd@${OSD_ID}.service
systemctl start ceph-osd@${OSD_ID}.service

exit 0
