#!/bin/bash

if [ $# -ne 3 ]; then
	echo "Usage: $0 <cluster_name> <hdd_for_ceph_journal> <mount_point_of_journal_hdd>" 
	echo "Example: $0 ceph-test sdc /mnt/sdc"
	exit 1
fi

CLUSTER_NAME=$1
CDISK=$2
MOUNTPOINT=$3

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

# create mount point
mkdir -p ${MOUNTPOINT}

# prepare hdd
sgdisk -z /dev/${CDISK}
parted /dev/${CDISK} --script -- mklabel gpt
parted /dev/${CDISK} --script -- mkpart primary xfs 0 -1
parted /dev/${CDISK} --script -- name 1 journal-for-${CLUSTER_NAME}-${CDISK}

# format and mount hdd
mkfs.xfs -f -L "jon${CDISK}" /dev/${CDISK}1

# put it into fstab
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f4) ${MOUNTPOINT}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab

# mount new journal device and set rights
mount -a
chown -R ceph. ${MOUNTPOINT}


exit 0
