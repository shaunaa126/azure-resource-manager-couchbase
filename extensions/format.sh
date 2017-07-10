#!/usr/bin/env bash

# This script formats and mounts the drive on lun0 as /datadisk

DISK="/dev/disk/azure/scsi1/lun0"
PARTITION="/dev/disk/azure/scsi1/lun0-part1"
MOUNTPOINT="/datadisk"

echo "Partitioning the disk."
echo "n
p
1


t
83
w"| fdisk ${DISK}

echo "Waiting for the symbolic link to be created..."
sleep 10

echo "Creating the filesystem."
mkfs -j -t ext4 ${PARTITION}

echo "Updating fstab"
LINE="${PARTITION}\t${MOUNTPOINT}\text4\tnoatime,nodiratime,nodev,noexec,nosuid\t1\t2"
echo -e ${LINE} >> /etc/fstab

echo "Mounting the disk"
mkdir -p $MOUNTPOINT
mount -a

echo "Changing permissions"
chown couchbase $MOUNTPOINT
chgrp couchbase $MOUNTPOINT
