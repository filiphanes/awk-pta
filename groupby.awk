BEGIN {
	FS="[ \t]+"
	accountPattern = account "";
	if      (group == "month") groupByDate = 7;
	else if (group == "year")  groupByDate = 4;
	else                       groupByDate = 10; # day
}

# Account lines
/^[ \t]+[A-Za-z0-9:]/ {
    val = +$3;
	if (val) {
		balance += val;
		if ($2 ~ accountPattern)
			groups[group, $2] += val;
	} else {
		if ($2 ~ accountPattern)
            groups[group, $2] -= balance;
        balance = 0;
	}
	next;
}

# Transaction header
/^[0-9]{4}-[0-9]{2}-[0-9]{2} / {
    balance = 0;
	group = substr($1, 0, groupByDate);
	next;
}

END {
	PROCINFO["sorted_in"] = "@ind_str_asc";
	for (key in groups) {
		val = groups[key];
		split(key, s, SUBSEP);
		group   = p[1] != s[1] ? s[1] : "";
		account = p[2] != s[2] ? s[2] : "";
		balance += val;
		printf "%-12s  %-36.36s  %12.2f %16.2f\n",
			group, account, val, balance;
		for (k in s) p[k] = s[k];
	}
}
