#!/bin/bash -x

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
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

#journal uuid
JUUID=$(uuidgen)

# block uuid
BUUID=$(uuidgen)

# blockdb uuid
BDBUUID=$(uuidgen)

#block.wal uuid
BWUUID=$(uuidgen)

# IDs
OSD_UID=$(uuidgen)
CLUSTER_FSID=$(grep fsid ${CLUSTER_CONF} | cut -d " " -f3)
echo ${CLUSTER_FSID}
#OSD_ID=$(ceph --cluster ${CLUSTER_NAME} osd create) && echo ${OSD_ID}
OSD_ID=$(ceph --cluster ${CLUSTER_NAME} osd create ${OSD_UID}) && echo ${OSD_ID} ${OSD_UID}

# Create the default directories
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

dd if=/dev/urandom of=${CDISK} bs=20M count=10

# prepare hdd
sgdisk -Z /dev/${CDISK}
sgdisk -o /dev/${CDISK}
sleep 2
${PARTPROBE} /dev/${CDISK}
sleep 1

sgdisk -n 1:0:110M /dev/${CDISK}
sgdisk -n 2 /dev/${CDISK}
${PARTPROBE} /dev/${CDISK}
sleep 2
sgdisk -c 1:bluefs-${OSD_ID}
sgdisk -c 2:blueblock-${OSD_ID}
${PARTPROBE} /dev/${CDISK}
sleep 2

#parted /dev/${CDISK} -s -a optimal -- mklabel gpt
#sleep 1
#parted  /dev/${CDISK} -s -a optimal -- mkpart primary xfs 0% 105MB
#sleep 1
#parted /dev/${CDISK} -s -a optimal -- mkpart primary xfs 105MB -1
#sleep 1
#parted /dev/${CDISK} -s -a optimal -- name 1 bluefs-${OSD_ID}
#sleep 1
#parted /dev/${CDISK} -s -a optimal -- name 2 blueblock-${OSD_ID}
#sleep 1

# format and mount hdd
mkfs.xfs -f -i size=2048 -L "blueFS_osd${OSD_ID}" /dev/${CDISK}1

#${CEPHDISK} prepare --cluster ${CLUSTER_NAME} --bluestore --block.db ${JOURNALPOINT}/blockdb-for-osd${OSD_ID}.db --block.wal ${JOURNALPOINT}/blockwal-for-osd${OSD_ID}.wal /dev/${CDISK}
${PARTPROBE} /dev/${CDISK}
sleep 5

# put it into fstab
#echo "/dev/${CDISK}1	/var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo "# /dev/${CDISK}1" >> /etc/fstab
echo "UUID=$(blkid /dev/${CDISK}1 | grep UUID | cut -d '"' -f4) /var/lib/ceph/osd/${CLUSTER_NAME}-osd${OSD_ID}        xfs     rw,noexec,nodev,noatime   0 0" >> /etc/fstab
echo -n -e "\n" >> /etc/fstab

mount -a
chown -R ceph. /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# append to config
echo "[osd.${OSD_ID}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
#echo "osd data = /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}" >> ${CLUSTER_CONF}
#echo "bluestore block path = /dev/disk/by-partuuid/$(blkid /dev/${CDISK}2 | grep PARTUUID | cut -d '"' -f10)" >> ${CLUSTER_CONF}
echo "bluestore block path = /dev/disk/by-partuuid/$(blkid /dev/${CDISK}2 | grep PARTUUID | cut -d '"' -f2)" >> ${CLUSTER_CONF}
#echo "bluestore block path = /dev/disk/by-partuuid/$(blkid /dev/${CDISK}2 | grep PARTUUID | cut -d '"' -f4)" >> ${CLUSTER_CONF}
echo "bluestore block db path = ${JOURNALPOINT}/blockdb-for-osd${OSD_ID}.db" >> ${CLUSTER_CONF}
echo "bluestore block wal path = ${JOURNALPOINT}/blockwal-for-osd${OSD_ID}.wal" >> ${CLUSTER_CONF}
echo "osd journal = ${JOURNALPOINT}/journal-for-osd${OSD_ID}.journal" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

# create keyring
#ceph-osd --cluster ${CLUSTER_NAME} --setuser ceph --setgroup ceph -i ${OSD_ID} --osd-uuid ${OSD_UID} --osd-journal ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal --mkfs --mkkey
#ceph-osd --cluster ${CLUSTER_NAME} --setuser ceph --setgroup ceph -i ${OSD_ID} --osd-uuid ${OSD_UID} --osd-journal ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.journal --mkfs --mkkey
ceph-osd -c ${CLUSTER_CONF} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkjournal --osd-journal ${JOURNALPOINT}/journal-for-osd${OSD_ID}.journal --mkfs --mkkey
#ceph-osd --cluster ${CLUSTER_NAME} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey
#ceph-osd --cluster ${CLUSTER_NAME} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkjournal


# if type is there remove it and set it new
if [[ -f /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type ]]; then
	rm -f /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type
	echo "bluestore" > /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type
else
	echo "bluestore" > /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/type
fi

#ln -sf /dev/${CDISK}2 /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block
ln -sf ${JOURNALPOINT}/blockdb-for-osd${OSD_ID}.db /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block.db
ln -sf ${JOURNALPOINT}/blockwal-for-osd${OSD_ID}.wal /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block.wal
ln -sf ${JOURNALPOINT}/journal-for-osd${OSD_ID}.journal /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/journal

# add osd to cluster
ceph --cluster ${CLUSTER_NAME} auth add osd.${OSD_ID} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/keyring

# osd's fsid
ceph-osd -c ${CLUSTER_CONF} --get-osd-fsid -i ${OSD_ID} > /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/fsid

chown -R ceph. /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# set weight to 1.0
#ceph --cluster ${CLUSTER_NAME} osd crush add osd.${OSD_ID} 1.0 host=${LMON}

#systemctl enable ceph-osd@${OSD_ID}.service
systemctl start ceph-osd@${OSD_ID}.service

exit 0