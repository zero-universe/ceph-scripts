#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob

if [ $# -ne 2 ]; then
	echo "Usage: $0 <cluster_name> <name_of_crushmap>" 
	echo "Example: $0 ceph-test crush_map_file"
	exit 1
fi


# go to ceph config dir
CPWD="/etc/ceph"

CLUSTER_NAME=$1
CRUSHMAP=$2

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"

CRT=$(which crushtool)
CEPH=$(which ceph)
SUDO=$(which sudo)

echo "getting crushmap and decompiling it ..."

#${SUDO} ${CEPH} --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd getcrushmap -o ${CRUSHMAP}
#${SUDO} ${CRT} -d ${CRUSHMAP} -o ${CRUSHMAP}_decompiled
${CEPH} --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd getcrushmap -o ${CRUSHMAP}
${CRT} -d ${CRUSHMAP} -o ${CRUSHMAP}_decompiled


echo "decompiled crushmap is in ${CRUSHMAP}_decompiled"

exit 0
