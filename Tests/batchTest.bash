#! /bin/bash

logfile="output.log"
date > $logfile
workdir=`pwd`
dirarray=( `find . -maxdepth 1 -type d | grep -v .svn` )
i=0;
for dir in ${dirarray[@]}
do
	cd $workdir
	echo "$i dir: $dir"
	echo "$i dir: $dir" >> $workdir/$logfile
	if [ "$dir" != "." ]; then
		cd $dir
		./$dir 2>&1 | tee -a $workdir/$logfile
		echo "" >> $workdir/$logfile
	fi
	i=$((i+1))
done
echo ""
cd $workdir
echo "Total number of  tests: ${#dirarray[@]}"
echo "Total number of  tests: ${#dirarray[@]}" >> $logfile
