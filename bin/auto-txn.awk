#!/usr/bin/awk -f
# Run on preprocessed postings

# after every KFC posting, create doubled amount to virtual account
/KFC/ {
    print;
    $2 = $2 * 2;
    $3 = "virtual:account";
    print;
}