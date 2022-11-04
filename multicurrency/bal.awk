#!/usr/bin/env awk -f
# Calculates final balances of accounts matching account pattern
# TODO: multicurrency
BEGIN {
    FS="[ \t]+"
    accountPattern = account "";
}

# transaction lines: Account Amount CUR
/^[ \t]+[A-Za-z]/ {
    amount = +$3;
    if (!amount) {
        # Auto fill amount from previous lines
        for (curr in balance) accounts[$2][curr] = balance[curr];
    } else {
        accounts[$2][$4] += amount;
    }
    balance[$4] -= amount;
	next;
}

# transaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    # reset running balance for filling missing amount
    delete balance;
    next;
}

END {
    # Enable sorted for in array
    PROCINFO["sorted_in"] = "@ind_str_asc";
    for (account in accounts) {
        if (account ~ accountPattern) {
            for (curr in accounts[account]) {
                printf "%12.2f %s %s\n", accounts[account][curr], curr, account;
                total[curr] += accounts[account][curr];
            }
        }
    }
    for (curr in total) {
        printf "\n%12.2f %s Total\n", total[curr], curr;
    }
}
