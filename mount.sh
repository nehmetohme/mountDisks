
#!/usr/bin/bash

# List number of disks existing on host.

disks_count=$(lsblk -id | grep sd | wc -l)
if [ $disks_count -eq 14 ]
then
  echo "Found 14 disks"
else
  echo "Found $disks_count disks. Expecting 14. Exiting.."
exit 1
fi
[[ "-x" == "${1}" ]] && set -x && set -v && shift 1
count=1

for X in /sys/class/scsi_host/host?/scan
do
  echo '- - -' > ${X}
done

for X in /dev/sd?
do
  echo "========"
  echo $X
  echo "========"
  # Avoid formating bootable partition
  bootable=$(/sbin/parted -s ${X} print quit|/bin/grep -c boot)
if [[ -b ${X} && $bootable -ne 0 ]];
then
  echo "$X bootable - skipping."
continue
else
  echo $X
  # Format and mount based on blkid
  Y=${X##*/}1
  echo "Formatting and Mounting Drive => ${X}"
  /sbin/mkfs.xfs -f ${X}
  (( $? )) && continue
  #Identify UUID
  UUID=$(blkid ${X} | cut -d " " -f2 | cut -d "=" -f2 | sed 's/"//g')
  /bin/mkdir -p /data/disk${count}
  (( $? )) && continue
  echo "UUID of ${X} = ${UUID}, mounting ${X} using UUID on
  /data/disk${count}"
  echo "UUID=${UUID} /data/disk${count} xfs inode64,noatime,nobarrier 0 0" >> /etc/fstab
  /bin/mount -t xfs -o inode64,noatime,nobarrier -U ${UUID} /data/disk${count}
  (( $? )) && continue
  # echo "UUID=${UUID} /data/disk${count} xfs inode64,noatime,nobarrier 0 0" >> /etc/fstab
  ((count++))
fi
done
