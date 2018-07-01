# fix_smart_last_bad_sector.sh script

It's a bash script to fix bad sectors on hard disks, using only smartctl for testing and hdparm to re-write the bad blocks.

All modern HDD comes with extra blocks to be used by the disk when bad-blocks shows up, automatically. 

Essentially, the HDD "cpu" remaps the disk physical block (which is bad) of a logical block to a diferent physical block from this extra pool, essentially making the logical block work again! 

Unfotunatelly, "automatically" doesn't mean "without intervention". Automatically in this case means that once a new WRITE to the bad logical block happens, the HDD "cpu" will remap it to a good physical block. 

Essentially, this will only happen if the computer "asks" the HDD to do it! It won't do by itself, since the data in that bad block will be lost once you re-write it. 

In Linux, fsck will detect such bad blocks, and will attempt to re-write those blocks, triggering the HDD to fix the bad block.

But from my experience, fsck sometimes miss a bunch of those bad blocks!

That's when I wrote this script. 

Basically, this scripts uses the HDD own SMART system to check for bad sectors, and once it finds it, uses hdparm to write over then. 

I was able to bring some HDD back to life using this approach, when fsck wouldn't. 

just use it as: 

   fix_smart_last_bad_sector.sh /dev/sda    # /dev/sda is and example of a disk to be fixed! replace it by your faulty disk!
   
and it will ask smartctl to do an long test on /dev/sda. if this tests stops with bad LBA, it will use hdparm to fix the LBA and start the long test again until the long test finishes susscessfully!

It can take a long time to complete, depending from the number of bad sectors and the size of the disk. I had 3TB disks taking a week to finish! (I still use those disks today, after fixing then 2 years ago. They work perfectly since then, without any new bad blocks!)

Basycally, don't throw away a HDD just because its starting shwoing some Bad Blocks. Fix it, and see how it behaves after! Off course, don't put any crucial data in it until you're 100% sure it's not going to present new bad blocks! 

After fixing a drive susscessfully, I usually format then as ZFS (a single disk ZFS volume), since ZFS has a lot of CRC checking per block and copy-on-write. ZFS has prevented me from loosing data on a single disk when new bad blocks eventually shows up, since it will detect the bad-block when writing (by CRC checking) and write the data in another block before clearing it from memory. 

