#!/bin/bash

# http://docs.ceph.com/docs/master/start/quick-ceph-deploy/
# http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


CLUSTER_NAME="ceph"
CPWD="/etc/ceph"
#CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
CLUSTER_CONF="${CLUSTER_NAME}.conf"
#CEPHDEPLOY=$(which ceph-deploy)
PARTPROBE=$(which partprobe)
PARTED=$(which parted)
PVCREATE=$(which pvcreate)
VGCREATE=$(which vgcreate)

# prepare needed directory structure
mkdir -p /var/lib/ceph/{osd,mon,mgr,mds}
chown -R ceph. /var/lib/ceph/

# clear gpt structures
echo "which /dev/DISK should be prepared? (sda or vda)"
read CDISK
sgdisk -Z /dev/${CDISK}

# make lvm device
${PVCREATE} /dev/${CDISK}
# create vg
# echo "VG's name?"
# read VGNAME
VGNAME="journals"
${VGCREATE} ${VGNAME}_on_${CDISK} /dev/${CDISK}


exit 0