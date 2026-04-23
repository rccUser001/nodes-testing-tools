#!/bin/bash

# extract the output of the lscpu extended command to check if the CPUs are hyperthreading enabled
# generate a YAML file to be read in by run-tests.py and
# compared with the expected values in the configuration file

file=$1
# check if hyperthreading is enabled
#ht=`awk 'BEGIN{ht = 0;} {if (NR > 1 && $1 != $4) ht = 1;} END{ printf("%d\n", ht); }' $file`
ht=`awk 'BEGIN{ht = 0;} NR > 1 { key = $3 ":" $4; if (seen[key]++) ht = 1; } END{ printf("%d\n", ht); }' $file`

echo "---"
echo "  output:"
echo "    Hyperthreading:"
echo "      value: $ht"


