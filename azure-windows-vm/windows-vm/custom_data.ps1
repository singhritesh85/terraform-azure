get-disk

Initialize-Disk -Number 2 -PartitionStyle MBR

New-Partition -DiskNumber 2 -UseMaximumSize -IsActive -DriveLetter F

Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel myDrive

get-volume
