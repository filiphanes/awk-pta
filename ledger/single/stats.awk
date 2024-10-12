#!/usr/bin/env awk -f
# Prints some stats about ledger like 
# - number of transactions
# - date of first, last transaction
# - number of accounts
BEGIN {
    FS="[ \t]+"
    first_date = "9999";
}

# transaction lines: Account Value
/^[ \t]+[A-Za-z]/ {
    accounts[$a] = 1;
	next;
}

# trasaction header: Date Description
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    date = substr($0, 0, 10);
    if (first_date > date) first_date = date;
    if (last_date < date)  last_date = date;
    transactions++;
    next;
}

END {
    print "Transactions:", transactions;
    print "First Date  :", first_date;
    print "Last Date   :", last_date;
    print "Accounts    :", length(accounts);
}
