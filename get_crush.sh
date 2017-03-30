#!/bin/bash

CRT=$(which crushtool)
CEPH=$(which ceph)
SUDO=$(which sudo)


if [ ! -n "$1" ]
then
  echo "Usage: $0 name_of_crushmap" 
  exit 
fi

echo "getting crushmap and decompiling it ..."

${SUDO} ${CEPH} osd getcrushmap -o $1
${SUDO} ${CRT} -d $1 -o $1_decompiled


echo "decompiled crushmap is in $1_decompiled"

exit 0
