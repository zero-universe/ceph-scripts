#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 4 ]; then
	echo "Usage: $0 <hdd_for_ceph_data> <osd_mount_point> <block.db_ssd_mount_point> <wal_ssd_mount_point>" 
	echo "Example: $0 sdc /var/lib/ceph/osd/ceph-0 /mnt/sdb /mnt/sdc"
	exit 1
fi

CDISK=$1
MOUNTPOINT=$2
BLOCKDBSSD=$3
WALSSD=$4

CEPHDISK=$(which ceph-disk)


${CEPHDISK} zap /dev/${CDISK}
${CEPHDISK} prepare --bluestore --block.db /mnt/${BLOCKDBSSD}/blockdb.for.${CDISK} --block.wal /mnt/${WALSSD}/wal.for.${CDISK} /dev/${CDISK}


# put it into fstab
echo "# /dev/${CDISK}" >> /etc/fstab
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f2) ${MOUNTPOINT}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo -n -e "\n" >> /etc/fstab


exit 0