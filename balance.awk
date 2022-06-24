BEGIN {
    FS="[ \t]{2,}"
    OFMT = "%.2f"
	accountPattern = account "";
}

function end_transaction() {
    if (accountNoValue) {
		accounts[accountNoValue] -= balance;
    }
	else if (balance > 0) {
        print "Transaction at line", line, "does't balance" > "/dev/stderr"
	}
    balance = 0;
	accountNoValue = "";
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}(=[0-9]{4}-[0-9]{2}-[0-9]{2})?[ \t]/ {
    end_transaction();
    line = NR;
	t_count++;
	next;
}

# transaction lines: Account Value
/^[ \t]+[A-Za-z]/ {
    if ($3) {
		accounts[$2] += $3;
		balance += $3;
    } else {
        if (accountNoValue)
            print NR, "Only 1 line in transaction can omit value" > "/dev/stderr"
        accountNoValue = $2;
    }
}

END {
    end_transaction()
    OFS="\t"
    PROCINFO["sorted_in"] = "@ind_str_asc";
    for (account in accounts) {
		if (account ~ accountPattern) {
			printf "%12.2f  %s\n", accounts[account], account;
			total += accounts[account];
		}
    }
    print "------------"
	printf "%12.2f\n", total
	print t_count, "transactions"
}
