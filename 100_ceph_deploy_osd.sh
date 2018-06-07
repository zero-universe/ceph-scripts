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
PVCREATE=$(which pvcreate)
VGCREATE=$(which vgcreate)
LVCREATE=$(which lvcreate)
VGS=$(which vgs)
LVS=$(which lvs)
CEPHVOLUME=$(which ceph-volume)


# clear gpt structures
echo "which /dev/DISK should be prepared? (sda or vda)"
read CDISK
sgdisk -Z /dev/${CDISK}

# make lvm device
${PVCREATE} /dev/${CDISK}
# create vg
# echo "VG's name?"
# read VGNAME
VGNAME="data"
${VGCREATE} ${VGNAME}_${CDISK} /dev/${CDISK}
# create lv
${LVCREATE} -l 100%FREE ${VGNAME}_${CDISK} -n data_for_${CDISK}
echo

# crate block.wal
${VGS}
echo
echo "where should the block.wal be created?"
read BLOCKWALVG
echo
echo
echo "what's the size of block.wal gonna be? (eg. 3G)"
read BLOCKWAL_SIZE
${LVCREATE} -L ${BLOCKWAL_SIZE} ${BLOCKWALVG} -n blockwal_for_${CDISK}
echo

# crate block.db
# ${VGS}
# uncomment for different vgs!
# echo "where should the block.db be created?"
# read BLOCKDBVG
echo
echo "what's the size of the block.db gonna be? (eg. 10G)"
read BLOCKDB_SIZE
# ${LVCREATE} -L ${BLOCKDB_SIZE} ${BLOCKDBVG} -n blockdb_for_${CDISK}
${LVCREATE} -L ${BLOCKDB_SIZE} ${BLOCKWALVG} -n blockdb_for_${CDISK}
echo

## crate journal
## ${VGS}
## uncomment for different vgs!
## echo "where should the journal be created?"
## read JOURNALVG
#echo
#echo "what's the size of the journal gonna be? (eg. 3G)"
#read JOURNAL_SIZE
## ${LVCREATE} -L ${JOURNAL_SIZE} ${JOURNALVG} -n journal_for_${CDISK}
#${LVCREATE} -L ${JOURNAL_SIZE} ${BLOCKWALVG} -n journal_for_${CDISK}
#echo
#echo
## list all lvs
#${LVS}
#echo

# create osd
# ceph-volume lvm prepare --bluestore --data {vg/lv} --block.wal {device} --block-db {vg/lv}
#${CEPHVOLUME} lvm create --bluestore --data ${VGNAME}_${CDISK}/data_for_${CDISK} --block.wal ${BLOCKWALVG}/blockwal_for_${CDISK} --block.db ${BLOCKWALVG}/blockdb_for_${CDISK} --journal ${BLOCKWALVG}/journal_for_${CDISK}
${CEPHVOLUME} lvm create --bluestore --data ${VGNAME}_${CDISK}/data_for_${CDISK} --block.wal ${BLOCKWALVG}/blockwal_for_${CDISK} --block.db ${BLOCKWALVG}/blockdb_for_${CDISK}
#${CEPHVOLUME} lvm prepare --bluestore --data ${VGNAME}_${CDISK}/data_for_${CDISK} --block.wal ${BLOCKWALVG}/blockwal_for_${CDISK} --block.db ${BLOCKWALVG}/blockdb_for_${CDISK} --journal ${BLOCKWALVG}/journal_for_${CDISK}

exit 0
