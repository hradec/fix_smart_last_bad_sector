#!/bin/bash
#
# a script to test all files in a LizardFS/MooseFS filesystem (actually, any filesystem)
#
# it just creates a list of all the files in a filesystem, and tries to READ then, one by one.
# if a error reading a file happens, it will log the filename with a big fat ERROR!
#
# I've wrote this for LizardFS/MooseFS filesystem in mind, since they dont have a "scrub" like
# command to force a re-checking of its data. They continuosly test the chunks in a slow pace, during
# idle time, which can take months to "scrub" the whole filesystem.
#
# This script will force it to read every single file on the filesystem, forcing it to "check" all
# chunks in use.
#

if [ ! -e lizard_files.txt ] ; then
	echo 'No lizard_files.txt file with a list of files in the LizardFS mount.'
	m=$(mount | grep mfs.mfsmaster | awk '{print $3}')
	echo 'Creating lizard_files.txt...'
	time find $m -type f > lizard_files.txt
fi

if [ ! -e /dev/shm/lizard_files_sorted.txt ] || [ $(stat /dev/shm/lizard_files_checked_sorted.txt | grep Size | awk '{print $2}') -eq 0 ] ; then
	echo 'sorting lizardfs file list...'
	cp lizard_files.txt /dev/shm/lizard_files.txt
	time sort /dev/shm/lizard_files.txt > /dev/shm/lizard_files_sorted.txt
fi

if [ -e lizard_files_checked.txt ] ; then
	echo 'getting the list of checked files and sorting it...'
	head -n $(let x=$(wc -l lizard_files_checked.txt|awk '{print $1}')-5;echo $x)  lizard_files_checked.txt >  /dev/shm/lizard_files_checked.txt
	time cat /dev/shm/lizard_files_checked.txt | awk '{print $2}' | sed 's/\.\.\.OK//g' | sed 's/\.\.\.ERROR//g' | sort > /dev/shm/lizard_files_checked_sorted.txt
fi

echo "now extract the files that need to still be checked, so we don't double test if we stop in the middle!"

time comm -23  /dev/shm/lizard_files_sorted.txt /dev/shm/lizard_files_checked_sorted.txt  > lizard_files_need_to_check.txt

monitor(){
  while true ; do
	echo ========================================
	wc -l /dev/shm/lizard_files.txt
	echo $(wc -l lizard_files_checked.txt)
	echo ==============
	a=$(wc -l /dev/shm/lizard_files.txt | awk '{print $1}')
	b=$(wc -l lizard_files_checked.txt | awk '{print $1}')
	let t=a-b
	p=$(python2 -c "print '%0.2f' % (float($b)/$a*100.0)")
	echo "$t left to do... $p% of 100% done"
	sleep 30
  done
}
monitor &

check(){
  echo "starting checking"
  cat lizard_files_need_to_check.txt | while read f ; do
	# we check a file by reading it! it's enough to force LizardFS access the
	# data in the chunks, and trigger an error
	# if there's missing chunks!
	echo -n "testing $f..." >>  lizard_files_checked.txt
	cat "$f"  > /dev/null
	if [ $? == 0 ] ; then
		echo OK >> lizard_files_checked.txt
	else
		echo "ERROR - CAN'T READ FILE $f"
		echo "ERROR - CAN'T READ FILE $f" >> lizard_files_checked.txt
	fi
  done
}
check
