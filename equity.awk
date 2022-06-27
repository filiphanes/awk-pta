BEGIN {
    FS="[ \t]+"
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
    date = substr($0, 0, 10);
    if (last_date < date)
        last_date = date;
    next;
}

END {
    # Enable sorted for in array
    PROCINFO["sorted_in"] = "@ind_str_asc";

    # Find longest account name length
    for (account in accounts) {
        len = length(account);
        if (max_len < len) max_len = len;
    }

    print last_date, "Opening Balances"
    for (account in accounts) {
        printf "    %-*s  %16.2f\n", max_len, account, accounts[account];
    }
}
