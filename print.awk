BEGIN {
    FS="[ \t]"
	accountPattern = account "";
    b_len = length(b);
    e_len = length(e);
    b = b ""
    e = e "Z"
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}[ \t]/ {
    if (b < $1 && $1 < e) {
        print;
        want = 1;
    }
	next;
}

# transaction lines: Account Value
/^[ \t]+[A-Za-z]/ && want {
    print;
}

# Empty line
/^[ \t]*$/ && want {
    print;
    want = 0;
}
