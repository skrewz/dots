#!/bin/bash

bc <<< "100-$(LC_ALL=C LC_ALL=C top -bn2 -d 0.1 | sed -nre 's/^%Cpu.* ([0-9]+)\.?[0-9]? id,.*$/\1/; tp; b ; :p p' | tail -1)"
exit 0

NUMCPUS=`grep ^proc /proc/cpuinfo | wc -l`
FIRST=`cat /proc/stat | awk '/^cpu / {print $5}'`
sleep 1
SECOND=`cat /proc/stat | awk '/^cpu / {print $5}'`
USED=`echo 2 k 100 $SECOND $FIRST - $NUMCPUS / - p | dc`
echo "${USED}"
