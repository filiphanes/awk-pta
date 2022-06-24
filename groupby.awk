BEGIN {
    FS="[ \t]{2,}"
    OFMT = "%.2f"
	accountPattern = account "";
    switch (group) {
    case "month":
        groupByDate = 7;
        break
    case "year":
        groupByDate = 4;
        break
    default:
        groupByDate = 10;
    }
}

function end_transaction() {
    if (accountNoValue) {
		accounts[accountNoValue] -= t_balance;
    }
	else if (t_balance > 0) {
        print "Transaction at line", line, "does't balance" > "/dev/stderr"
	}
    t_balance = 0;
	accountNoValue = "";
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}[ \t]/ {
    end_transaction();
    line = NR;
    if (groupByDate) {
        group = substr($1, 0, groupByDate);
    }
	next;
}

# transaction lines: Account Value
/^[ \t]+[A-Za-z]/ {
    if ($3) {  # if value
        t_balance += $3;
		if ($2 ~ accountPattern) {
            groups[group][$2] += $3;
        }
    } else {
        if (accountNoValue) {
            print "Found second account line without value at " NR > "/dev/stderr"
            exit;
        }
        accountNoValue = $2;
    }
}

END {
    end_transaction()

    PROCINFO["sorted_in"] = "@ind_str_asc";
    for (group in groups) {
        header = group "";
        for (account in groups[group]) {
            value = groups[group][account]
            balance += value;
            printf "%-36.36s  %-36.36s  %10.2f  %-16f\n", header, account, value, balance;
            header = "";
        }
    }
}
