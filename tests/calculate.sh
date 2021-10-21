#!/bin/bash
cd $1
for t in *txt;do echo $t;cat $t | wc -l;done | sed 's! .*/.*!!'
