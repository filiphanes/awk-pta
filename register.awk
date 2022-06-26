BEGIN {
    FS="[ \t]{2,}"
    OFMT = "%.2f"
    accountPattern = account "";
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
    header = $1 $2 $3 $4;
    next;
}

# transaction lines: Account Value
/^[ \t]+[A-Za-z]/ {
    if ($3) {  # if value
        t_balance += $3;
        if ($2 ~ accountPattern) {
            balance += $3;
            printf "%-36.36s  %-36.36s  %10g  %16g\n", header, $2, $3, balance;
            header = "";
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
}
