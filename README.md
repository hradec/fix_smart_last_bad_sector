# fix_smart_last_bad_sector.sh script

It's a bash script to fix bad sectors on hard disks, using only smartctl for testing and hdparm to re-write the bad blocks.

All modern HDD comes with extra blocks to be used by the disk when bad-blocks shows up, automatically. 

Essentially, the HDD "cpu" remaps the disk physical block (which is bad) of a logical block to a diferent physical block from this extra pool, essentially making the logical block work again! <br>
Unfotunatelly, "automatically" doesn't mean "without intervention". Automatically in this case means that once a new WRITE to the bad logical block happens, the HDD "cpu" will remap it to a good physical block. 

Unfortunally this will only happen if the computer "asks" the HDD to do it! It won't do by itself, since the data in that bad block will be lost once you re-write it. <br>
In Linux, fsck will detect such bad blocks, and will attempt to re-write those blocks, triggering the HDD to fix the bad block.<br>
But from my experience, fsck sometimes misses a bunch of those bad blocks!

That's when I decided to write this script. <br>
Basically, it uses the HDD own SMART system to check for bad sectors, and once it finds it, uses hdparm to write over then. <br>
I was able to bring some HDD back to life using this approach, when fsck wouldn't. 

just use it as: 
```
   # /dev/sda is and example of a disk to be fixed! replace it by your faulty disk!
   sudo fix_smart_last_bad_sector.sh /dev/sda    
```
   
and it will ask smartctl to do an long test on /dev/sda. if this tests stops with bad LBA, it will use hdparm to fix the LBA and start the long test again until the long test finishes susscessfully!

It usually takes a long time to complete, depending on the number of bad sectors and the size of the disk. I had 3TB disks taking a week to finish! (I still use those disks today, after fixing then 2 years ago. They work perfectly since then, without any new bad blocks!)

After fixing a drive susscessfully, I usually format then as ZFS (a single disk ZFS volume), since ZFS has a lot of CRC checking per block and copy-on-write. ZFS has prevented me from loosing data on a single disk when new bad blocks eventually shows up, since it will detect the bad-block when writing (by CRC checking) and write the data in another block before clearing it from memory. 



Basycally, don't throw away a HDD just because its starting showing some Bad Blocks... There's already a lot of tech-trash over our earth, so lets be a bit more methodical before contributing to the polution!!<br>
Fix it, and see how it behaves after!<br>
Off course, don't put any crucial data in it until you're 100% sure it's not going to present new bad blocks! 



Last, this script works pretty well if the SMART system in the disk is working properly. Sometimes when a disk starts to fault, the SMART system is also affected. When this happens, it becomes SLOW, to the point of not responding. <br>
If your HDD has a slow or unresponsive SMART, this script probably won't work on it. 

to verify if your HDD has a healty SMART, run: 

``` 
   time sudo smartctl -a /dev/sda    # replace /dev/sda by your HDD device 
```
    
The `time` command should return something like this if you have a healthy SMART:
```
real	0m0.192s
user	0m0.048s
sys	0m0.012s
```

If the "real" value is above 1-2 secs, your SMART is probably not 100% healty. But it MAY still be able to be used by this script. But if the "real" value goes crazy, like 30secs or minutes, then it probably won't work. 



