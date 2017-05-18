#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 2 ]; then
	echo "Usage: $0 <cluster_name> <osd_id>"
	echo "Example: $0 ceph-test 1"
	exit 1
fi


# read http://docs.ceph.com/docs/jewel/rados/operations/add-or-rm-osds/ for better understanding

LMON=$(hostname -s)

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_NAME=$1

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"

#echo "which osd should be removed ?"
#read OSD_ID
OSD_ID=$2

ceph -c ${CLUSTER_CONF} osd out ${OSD_ID}

systemctl stop ceph-osd@${OSD_ID}.service
systemctl disable ceph-osd@${OSD_ID}.service

umount /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

#btrfs subvolume delete /var/lib/ceph/osd/cephorium-0/*

ceph -c ${CLUSTER_CONF} osd crush remove osd.${OSD_ID}

ceph -c ${CLUSTER_CONF} auth del osd.${OSD_ID}

ceph -c ${CLUSTER_CONF} osd rm ${OSD_ID}

rm -rf /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# sed -i "/${CLUSTER_NAME}-${OSD_ID}/d" /etc/fstab

echo "remove entries from /etc/fstab and ${CPWD}/${CLUSTER_NAME}.conf"

exit 0



