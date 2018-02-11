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
CEPHDEPLOY=$(which ceph-deploy)

# define your monitors
echo "what are the monitors? "
read MONS
ceph-deploy new ${MONS}

# define your subnet
echo "what is you subnet?"
read SUBNET
echo "public network = ${SUBNET}" >> ${CLUSTER_CONF}

# set some standards for a very small cluster
echo -n -e "\n" >> ${CLUSTER_CONF}
echo "osd journal size = 2048" >> ${CLUSTER_CONF}
echo "osd pool default size = 1" >> ${CLUSTER_CONF}
echo "osd pool default min size = 1" >> ${CLUSTER_CONF}
echo "osd pool default pg num = 128" >> ${CLUSTER_CONF}
echo "osd pool default pgp num = 128" >> ${CLUSTER_CONF}
echo "osd crush chooseleaf type = 1" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}

# Deploy the initial monitor(s) and gather the keys:
${CEPHDEPLOY} mon create-initial

# copy the configuration file and admin key to your admin node and your Ceph Nodes
echo "what are your ceph nodes?"
read CNODES
${CEPHDEPLOY} gatherkeys ${CNODES}
${CEPHDEPLOY} admin ${CNODES}
for i in ${CNODES}; do scp ceph.bootstrap-osd.keyring ${i}:/var/lib/ceph/bootstrap-osd/ceph.keyring;done

# deploy mgr
echo "where should the mgr be running?"
read MGRNODE
${CEPHDEPLOY} mgr create ${MGRNODE}


exit 0