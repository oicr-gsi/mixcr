#!/bin/bash
cd $1
for t in *txt;do wc -l $t;done | sed 's! .*/.*!!'
