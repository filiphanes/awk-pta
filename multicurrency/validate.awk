BEGIN {
    FS=" +"
}

function end_transaction() {
    if (accountNoValue) {
        # fill remaining balance account line without value
        for (com in t_balance) {
            groups[group][accountNoValue][com] -= t_balance[com];
            delete t_balance[com];
        }
    }
    else for (com in t_balance)
        if (t_balance[com]) {
            print "Transaction at line", line, "doesn't balance" > "/dev/stderr";
            exit 1;
        }
    delete t_balance;
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
/^[ \t]+[A-Za-z0-9:]+([ \t]+[-+]?[0-9]+\.?[0-9]*)?( *[A-Za-z]+)[ \t]*/ {
    acc = $2;
    val = $3;
    com = $4;
    print acc, val, com;
    if (val) {
        t_balance[com] += val;
        if (acc ~ accountPattern) {
            groups[group][acc][com] += val;
        }
    } else {
        if (accountNoValue) {
            print "Found second account line without value at " NR > "/dev/stderr"
            exit 1;
        }
        accountNoValue = $2;
    }
}

# Empty and Comment lines
/^[ \t]*(;.*)?$/ { next; }

{
    print "Unknown line " NR ": " $0;
    exit;
}

END {
    end_transaction()
    print "OK";
}
