#!/bin/bash

CRT=$(which crushtool)
CEPH=$(which ceph)
SUDO=$(which sudo)


if [ ! -n "$1" ]
then
  echo "Usage: $0 name_of_decompiled_crushmap" 
  exit 
fi

echo "compiling crushmap and setting it ..."

${SUDO} ${CRT} -c $1 -o $1_compiled

${SUDO} ${CEPH} osd setcrushmap -i $1_compiled


echo "set compiled crushmap"


exit 0