#!/bin/bash
# GPL3+, (C) Anders Breindahl <skrewz@skrewz.net> 2013.
# The idea here is: Return a number between 0 and 100 which operatively
# reflects how strong one's signal is, so as to be used in a dashboard.

# Small scale experimentation (walking around with an iperf running) has led me
# to rougly -50dBm to be the upper limit that I need to care about,
# throughput-wise, and on the other end, when I hit -80dBm, my connection
# begins breaking up.
min_minus_dbms_cut_off="-80"
max_minus_dbms_cut_off="-40"

# Leaving this one empty, as most computers will only have a single active wlan
# interface. If you want to look at a specific one, set it here.
interface=

current_level="$(LC_ALL=C /sbin/iwconfig $interface |& sed -nre "s/^.*Signal level=(-?[0-9.]+) dBm.*/\1/; tp; b; :p p" | head -1)"
bc << EOF
define abs(x) {if (x<0) {return -x}; return x;}
define min(x,y) {if (x<y)  {return x}; return y;}
define max(x,y) {if (x>=y) {return x}; return y;}
100*abs($min_minus_dbms_cut_off-max(min($current_level,$max_minus_dbms_cut_off),$min_minus_dbms_cut_off)) /\
  ($max_minus_dbms_cut_off-($min_minus_dbms_cut_off))
EOF
