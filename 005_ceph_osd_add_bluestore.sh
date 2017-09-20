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
OSD_ID=$(ceph -c ${CLUSTER_CONF} --cluster ${CLUSTER_NAME} osd create) && echo ${OSD_ID}

# Create the default directories
mkdir -p /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# prepare hdd
${CEPHDISK} zap /dev/${CDISK}

# bluestore stuff
${CEPHDISK} prepare --cluster ${CLUSTER_NAME} --bluestore --block.db ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db  --block.wal ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal /dev/${CDISK}

# append to config
echo "[osd.${OSD_ID}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
echo "osd data = /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}" >> ${CLUSTER_CONF}
echo "bluestore block path = /dev/${CDISK}" >> ${CLUSTER_CONF}
echo "bluestore block db path = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db" >> ${CLUSTER_CONF}
echo "bluestore block wal path = ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

chown -R ceph. /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

# create keyring
ceph-osd --cluster ${CLUSTER_NAME} --setuser ceph --setgroup ceph -i ${OSD_ID} --mkfs --mkkey

# add osd to cluster
ceph -c ${CLUSTER_CONF} auth add osd.${OSD_ID} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/keyring

ln -sf /dev/${CDISK} /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block
ln -sf ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.db /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block.db
ln -sf ${JOURNALPOINT}/${CLUSTER_NAME}-${OSD_ID}.wal /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}/block.wal

# set weight to 1.0
ceph --cluster ${CLUSTER_NAME} osd crush add osd.${OSD_ID} 1.0 host=${LMON}

systemctl enable ceph-osd@${OSD_ID}.service
systemctl start ceph-osd@${OSD_ID}.service

exit 0