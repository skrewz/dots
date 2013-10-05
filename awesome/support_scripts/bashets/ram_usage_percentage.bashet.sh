#!/bin/bash
free -k | awk '/^Mem/{print "100 *",$3,"/",$2}' | bc
