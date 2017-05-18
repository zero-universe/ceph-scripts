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

# go to ceph config dir
CPWD="/etc/ceph"

CLUSTER_NAME=$1

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"


# prepare ceph-config
echo "[client.restapi]" >> ${CLUSTER_CONF}
echo "log_file = /dev/null" >> ${CLUSTER_CONF}
echo "keyring = /etc/ceph/${CLUSTER_NAME}.client.restapi.keyring" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

# create client.restapi
${CEPH} --cluser ${CLUSTER_NAME} auth get-or-create client.restapi mds 'allow' osd 'allow *' mon 'allow *' >> /etc/ceph/${CLUSTER_NAME}.client.restapi.keyring


exit 0