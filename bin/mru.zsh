#!/bin/zsh

#GET LOCKMRU AGE (IN SECONDS ?!)
lockfilename=~/lockmru
changed=$(perl -MFile::stat -e "print stat(\"${lockfilename}\")->mtime")
now=`date +%s`
elapsed=now-changed

#DELETE LOCKFILE IF OLDER THAN 20 SECONDS (I GUESS IT WAS LEFT THERE DUE TO SOME BUG OR FORCED SHUTDOWN)
[[ $elapsed -gt 20 ]] && rm ~/lockmru

#MRU IS LOCKED, SOMEONE ELSE IS UPDATING IT, LEAVE IT ALONE AND AVOID DELETING ALL IT'S CONTENTS BY MISTAKE
[[ -f ~/lockmru ]] && return

#LOCK MRU FILE (TAKE OWNERSHIP ON IT)
touch ~/lockmru
filename=$1
#see `man parameter expansion`
linenum=${2:=0}
mrufile=${3:-$HOME/.mru}
if [[ ! -f ${filename} ]]; then; 
    return
fi
[[ ! -f $mrufile ]] && touch $mrufile; 
if [[ $linenum -eq 0 ]]; then
    newentry=${$(cat $mrufile | grep ${filename}):=filename}; 
else
    newentry=${filename}:${linenum}
fi
grep -v ${filename} $mrufile > /tmp/tmpmru; 
echo $newentry >> /tmp/tmpmru; 
tail -n1000 /tmp/tmpmru > $mrufile; 

rm ~/lockmru
