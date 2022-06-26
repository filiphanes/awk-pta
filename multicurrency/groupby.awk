BEGIN {
	FS="[ \t]+"
	accountPattern = account "";
	if      (group == "month") groupByDate = 7;
	else if (group == "year")  groupByDate = 4;
	else                       groupByDate = 10; # day
}

function end_transaction() {
	if (accountNoValue) {
		# fill remaining balance account line without value
		for (com in t_balance) {
			groups[group, accountNoValue, com] -= t_balance[com];
			delete t_balance[com];
		}
	} else {
		for (com in t_balance)
			delete t_balance;
	}
	accountNoValue = "";
}

# Transaction header
/^[0-9]{4}-[0-9]{2}-[0-9]{2} / {
	end_transaction();
	group = substr($1, 0, groupByDate);
	next;
}

# Account lines
/^[ \t]+[A-Za-z0-9:]/ {
	match($3 $4, /([+-]?[0-9]+\.?[0-9]*)([A-Z]*)/, v);
	if (v[1]) {
		t_balance[v[2]] += v[1];
		if ($2 ~ accountPattern) {
			groups[group, $2, v[2]] += val;
		}
	} else {
		accountNoValue = $2;
	}
	next;
}

END {
	end_transaction()

	PROCINFO["sorted_in"] = "@ind_str_asc";
	for (key in groups) {
		val = groups[key];
		split(key, s, SUBSEP);
		group   = p[1] != s[1] ? s[1] : "";
		account = p[2] != s[2] ? s[2] : "";
		com     = p[3] != s[3] ? s[3] : "";
		balance[s[3]] += val;
		printf "%-12s  %-36.36s  %12.2f %s %16.2f %s\n",
			group, account, val, com, balance[com], com;
		for (k in s) p[k] = s[k];
	}
}
