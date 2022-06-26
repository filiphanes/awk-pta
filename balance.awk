BEGIN {
    FS="[ \t]+"
    OFMT = "%.2f"
    accountPattern = account "";
}

function end_transaction() {
    if (accountNoValue) {
        accounts[accountNoValue] -= balance;
    }
    balance = 0;
    accountNoValue = "";
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2} / {
    end_transaction();
    t_count++;
    next;
}

# transaction lines: Account Value
/^ +[A-Za-z]/ {
    if (+$3) {
        accounts[$2] += $3;
        balance += $3;
    } else {
        accountNoValue = $2;
    }
	next;
}

END {
    end_transaction()

    PROCINFO["sorted_in"] = "@ind_str_asc";
    for (account in accounts) {
        if (account ~ accountPattern) {
            printf "%12.2f  %s\n", accounts[account], account;
            total += accounts[account];
        }
    }
    print "------------"
    printf "%12.2f  Total\n", total
    print t_count, "transactions"
}
