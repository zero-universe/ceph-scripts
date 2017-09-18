#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob

if [ $# -ne 1 ]; then
        echo "Usage: $0 <cluster_name>"
        echo "Example: $0 ceph-test"
        exit 1
fi


CEPH=$(which ceph)

CLUSTER_NAME=$1

# go to ceph config dir
CPWD="/etc/ceph"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"


# create mgr.keyring and copy it to the right place
${CEPH} --cluster ${CLUSTER_NAME} auth get-or-create mgr.$(hostname -s) mon 'allow profile mgr' osd 'allow *' mds 'allow *' -o /etc/ceph/${CLUSTER_NAME}.mgr.$(hostname -s).keyring
mkdir -p /var/lib/ceph/mgr/${CLUSTER_NAME}-$(hostname -s)
cp /etc/ceph/${CLUSTER_NAME}.mgr.$(hostname -s).keyring /var/lib/ceph/mgr/${CLUSTER_NAME}-$(hostname -s)/keyring
chown -R ceph. /var/lib/ceph/mgr/

systemctl enable ceph-mgr@$(hostname -s).service

exit 0