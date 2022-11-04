#!/usr/bin/env awk -f
BEGIN {
    FS="[ \t]"
    accountPattern = account "";
    begin = begin "";
    end = end "Z";
}

# Account lines
/^[ \t]+[A-Za-z\(]/ && want {
    print;
    next;
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    date = substr($0, 0, 10);
    want = begin < date && date < end;
    if (want) {
        print "";
        print;
    }
    next;
}

# Comments in transaction
/^[ \t]+;/ && want {
    print;
    next;
}
