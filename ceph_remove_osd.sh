#!/bin/bash -x

# read http://docs.ceph.com/docs/jewel/rados/operations/add-or-rm-osds/ for better understanding

LMON=$(hostname -s)

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_NAME="cephorium"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

echo "which osd should be removed ?"
read OSD_ID

ceph -c ${CLUSTER_CONF} osd out ${OSD_ID}

systemctl stop ceph-osd@${OSD_ID}.service

umount /var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}

btrfs subvolume delete /var/lib/ceph/osd/cephorium-0/*

ceph -c ${CLUSTER_CONF} osd crush remove osd.${OSD_ID}

ceph -c ${CLUSTER_CONF} auth del osd.${OSD_ID}

ceph -c ${CLUSTER_CONF} osd rm ${OSD_ID}

rm -rf /var/lib/ceph/osd/* /etc/systemd/system/ceph-osd*

systemctl daemon-reload

exit 0



