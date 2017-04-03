# ceph-scripts



Setup manually a ceph cluster:



### 001_ceph_mon_prepare.sh

To be run on the first ceph-mon host


Usage: 001_ceph_mon_prepare.sh <cluster_name> <subnet> <mons_hostname> <mons_ip>
Example: 001_ceph_mon_prepare.sh ceph-test 10.0.0.0/8 server01,server02 10.0.0.1,10.0.0.2

1. cluster-name
2. network subnet of cluster
3. $(hostname -s) of all monitor hosts - only for initial setup!
4. ip-addresses of initial monitor hosts




### 002_ceph_mon_add.sh

To be run on every additional (and new) ceph-mon host


Usage: 002_ceph_mon_add.sh <cluster_name>
Example: 002_ceph_mon_add.sh ceph-test

1. only the cluster-name is needed




### 003_ceph_osd_add_to_bucket.sh

To be run ONCE on every ceph-osd host


Usage: 003_ceph_osd_add_to_bucket.sh <cluster_name>
Example: 003_ceph_osd_add_to_bucket.sh ceph-test

1. only the cluster-name is needed




### 004_ceph_journal_prepare.sh

To be run on every ceph-osd hosts for every journal-hdd


Usage: 004_ceph_journal_prepare.sh <cluster_name> <hdd_for_ceph_journal> <mount_point_of_journal_hdd>
Example: 004_ceph_journal_prepare.sh ceph-test sdc /mnt/sdc

1. cluster-name
2. which hdd is ment for journal
3. mount point of hdd




###  005_ceph_osd_add.sh

To be run on every ceph-osd hosts for every hdd that is supposed to store data


Usage: 005_ceph_osd_add.sh <cluster_name> <hdd_for_ceph_data> <mountpoint_for_ceph_journal>
Example: 005_ceph_osd_add.sh ceph-test sdc /mnt/sdb

1. cluster-name
2. hdd for data storage
3. mount-point journal-hdd (see 004)





OTHER SCRIPTS


### get_crush.sh

Get the crushmap and decompile it

Usage: $0 <cluster_name> <name_of_crushmap>
Example: $0 ceph-test crush_map_file

1. cluster-name
2. name of crushmap_file




### set_crush.sh

Set crushmap after adjustments

Usage: $0 <cluster_name> <name_of_crushmap_file>
Example: $0 ceph-test crush_map_file

1. cluster-name
2. name of crushmap_file to be applied




### ceph_remove_osd.sh

To be run on a ceph-osd hosts containing the osd which should be removed


Usage: ceph_remove_osd.sh <cluster_name> <osd_id>
Example: ceph_remove_osd.sh ceph-test 1

1. cluster-name
2. osd number 


