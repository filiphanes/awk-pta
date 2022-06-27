#!/bin/sh

cmd=$1
shift

awk -f $cmd.awk $@ < ledger.txt

