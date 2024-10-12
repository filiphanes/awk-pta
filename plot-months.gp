#!/usr/bin/env gnuplot

set xdata time
set timefmt '%Y-%m'
set autoscale
set format x '%Y-%m'
set datafile sep space
set term dumb
#set term qt persist
#set boxwidth 1
#set style fill solid 1.0
plot '< bin/postings 2023.txt | bin/by-month | sort' using 1:2 with lines
