#!/bin/bash -x

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
#set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 3 ]; then
	echo "Usage: $0 <cluster_name> <hdd_for_ceph_data> <mountpoint_for_ceph_journal_blockdb>" 
	echo "Example: $0 ceph-test sdc /mnt/sdb"
	exit 1
fi

LMON=$(hostname -s)
CUSER=ceph
CGROUP=ceph
PARTPROBE=$(which partprobe)

CEPHDISK=$(which ceph-disk)

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_NAME=$1
CDISK=$2
JOURNALPOINT=$3

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

# IDs
OSD_UID=$(uuidgen)
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}
#OSD_ID=$(ceph --cluster ${CLUSTER_NAME} osd create) && echo ${OSD_ID}
OSD_ID=$(ceph --cluster ${CLUSTER_NAME} osd create ${OSD_UID}) && echo ${OSD_ID} ${OSD_UID}

# Create the default directories
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

## prepare hdd
sgdisk -Z /dev/${CDISK}
${PARTPROBE} /dev/${CDISK}
#
#sgdisk -n 1:0:100M /dev/${CDISK}
#sgdisk -n 2 /dev/${CDISK}
#${PARTPROBE} /dev/${CDISK}
#sleep 2
#sgdisk -c 1:bluefs-${OSD_ID}
#sgdisk -c 2:blueblock-${OSD_ID}
#${PARTPROBE} /dev/${CDISK}
#sleep 2
#
#
## format and mount hdd
#mkfs.xfs -f -i size=2048 -L "blueFS${OSD_ID}" /dev/${CDISK}1

${CEPHDISK} --zap-disk /dev/${CDISK}
sleep 2
${PARTPROBE} /dev/${CDISK}
sleep 2
#${CEPHDISK} prepare --bluestore --block.db-file ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db --block.wal-file ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal --osd-id ${OSD_ID} -osd-uuid ${OSD_UID} --journal-file ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal /dev/${CDISK}
${CEPHDISK} prepare --bluestore --block.db ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db --block.wal ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal --osd-id ${OSD_ID} --osd-uuid ${OSD_UID} --journal-file ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal /dev/${CDISK}
#${CEPHDISK} prepare --bluestore --block.db ${JOURNALPOINT}/blockdb-for-${CDISK}.db --block.wal ${JOURNALPOINT}/wal-for-${CDISK}.wal /dev/${CDISK}
sleep 2
${PARTPROBE} /dev/${CDISK}

# put it into fstab
#echo "/dev/${CDISK}1	/var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo "# /dev/${CDISK}1" >> /etc/fstab
# with LABEL
#echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f4) /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab

# without! LABEL
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f2) /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo -n -e "\n" >> /etc/fstab

mount -a

# append to config
echo "[osd.${OSD_ID}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
#echo "osd data = /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}" >> ${CLUSTER_CONF}
echo "bluestore block path = /dev/disk/by-partuuid/$(blkid /dev/${CDISK}2 | grep PARTUUID | cut -d '"' -f2)" >> ${CLUSTER_CONF}
echo "bluestore block db path = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db" >> ${CLUSTER_CONF}
echo "bluestore block wal path = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal" >> ${CLUSTER_CONF}
echo "osd journal = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}


if [[ -f /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type ]]; then
	rm -f /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type
	echo "bluestore" > /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type
else
	echo "bluestore" > /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type
fi


#ln -sf /dev/disk/by-partuuid/$(blkid /dev/${CDISK}2 | grep PARTUUID | cut -d '"' -f2) /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block
#ln -sf ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block.db
#ln -sf ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block.wal
#ln -sf ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/journal

chown -R ceph. /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

systemctl start ceph-osd@${OSD_ID}.service

exit 0
