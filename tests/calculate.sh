#!/bin/bash
cd $1

# We only have txt files for process:

echo ".txt files:"
for t in *txt;do md5sum $t;done | sort -V
