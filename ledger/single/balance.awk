#!/usr/bin/env awk -f
BEGIN {
    FS="[ \t]+"
    accountPattern = account "";
}

# transaction lines: Account Value
/^[ \t]+[A-Za-z]/ {
    val = +$3;
    if (!val) {
        # Auto fill value
        val = -balance;
    }
    accounts[$2] += val;
    balance += val;
	next;
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    balance = 0;
    next;
}

END {
    # Enable sorted for in array
    PROCINFO["sorted_in"] = "@ind_str_asc";
    for (account in accounts) {
        if (account ~ accountPattern) {
            printf "%12.2f  %s\n", accounts[account], account;
            total += accounts[account];
        }
    }
    printf "\n%12.2f  Total\n", total
}
