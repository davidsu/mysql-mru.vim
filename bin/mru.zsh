#!/bin/zsh
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



