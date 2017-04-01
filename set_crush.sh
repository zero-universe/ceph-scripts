#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: $0 <cluster_name> <name_of_crushmap_file>" 
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


echo "compiling crushmap and setting it ..."

#${SUDO} ${CRT} -c ${CRUSHMAP} -o ${CRUSHMAP}_compiled
#${SUDO} ${CEPH} --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd setcrushmap -i ${CRUSHMAP}_compiled
${CRT} -c ${CRUSHMAP} -o ${CRUSHMAP}_compiled
${CEPH} --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd setcrushmap -i ${CRUSHMAP}_compiled


echo "set compiled crushmap"


exit 0