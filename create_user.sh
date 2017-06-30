#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob

if [ $# -ne 2 ]; then
        echo "Usage: $0 <cluster_name> <username>" 
        echo "Example: $0 ceph-test test001"
        exit 1
fi


CEPH=$(which ceph)

# go to ceph config dir
CPWD="/etc/ceph"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"

CLUSTER_NAME=$1
USERNAME=$2

# create client.keyring
${CEPH} --cluser ${CLUSTER_NAME} auth get-or-create client. mds 'allow' osd 'allow *' mon 'allow *' -o /etc/ceph/${CLUSTER_NAME}.client.${USERNAME}.keyring


exit 0