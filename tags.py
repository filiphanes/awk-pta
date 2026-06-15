#!/usr/bin/env python3
# Find best matching postings
import sys

tags = {}

for filename in sys.argv[1:]:
    with open(filename) as file:
        commontags = []
        for line in file.readlines():
            if line[0] == '=':
                commontags = line[1:].split()
                continue
            elif line[0] == '\n':
                continue
            for tag in commontags:
                try:
                    tags[tag] += 1
                except KeyError:
                    tags[tag] = 1
            for tag in line.split():
                try:
                    tags[tag] += 1
                except KeyError:
                    tags[tag] = 1

for tag, count in sorted(tags.items(), key=lambda x:x[1]):
    print(count, tag)
