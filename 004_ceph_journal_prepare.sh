#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 3 ]; then
	echo "Usage: $0 <cluster_name> <hdd_for_ceph_journal> <mount_point_of_journal_hdd>" 
	echo "Example: $0 ceph-test sdc /mnt/sdc"
	exit 1
fi

CLUSTER_NAME=$1
CDISK=$2
MOUNTPOINT=$3

PARTPROBE=$(which partprobe)

# create mount point
mkdir -p ${MOUNTPOINT}

# prepare hdd
sgdisk -Z /dev/${CDISK}
${PARTPROBE} /dev/${CDISK}
sleep 2
parted /dev/${CDISK} -s -a optimal -- mklabel gpt
sleep 1
#parted /dev/${CDISK} -s -a optimal -- mkpart primary xfs 0 -1
parted /dev/${CDISK} -s -a optimal -- mkpart primary xfs 0% 100%
sleep 1
parted /dev/${CDISK} -s -a optimal -- name 1 journal-for-${CLUSTER_NAME}-${CDISK}
sleep 2
${PARTPROBE} /dev/${CDISK}

# format and mount hdd
mkfs.xfs -f -L "jon${CDISK}" /dev/${CDISK}1

# create ${MOUNTPOINT}
mkdir -p ${MOUNTPOINT}

# put it into fstab
echo "# /dev/${CDISK}" >> /etc/fstab
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f4) ${MOUNTPOINT}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo -n -e "\n" >> /etc/fstab

# mount new journal device and set rights
mount -a
chown -R ceph. ${MOUNTPOINT}


exit 0
