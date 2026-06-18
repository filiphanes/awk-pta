#!/bin/sh
# Test suite for pta commands.
# Usage: ./tests/test.sh

DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PTA_DIR="$DIR"
unset PTA_ACCOUNT_REGEX

DEMO="$DIR/tests/demo.txt"
pass=0
fail=0

# Run pta with demo.txt as piped input
run() { cat "$DEMO" | "$DIR/pta" "$@"; }

# Check that output contains a string
expect_contains() {
    name="$1"; needle="$2"; shift 2
    actual=$("$@" 2>&1)
    if echo "$actual" | grep -qF -e "$needle"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $name"
        echo "  expected to contain: $needle"
        echo "  got: $(echo "$actual" | head -3)..."
    fi
}

# Check that output does NOT contain a string
expect_not_contains() {
    name="$1"; needle="$2"; shift 2
    actual=$("$@" 2>&1)
    if echo "$actual" | grep -qF -e "$needle"; then
        fail=$((fail + 1))
        echo "FAIL: $name (should NOT contain: $needle)"
    else
        pass=$((pass + 1))
    fi
}

echo "=== check ==="
expect_contains "check-valid" "OK: 13 transaction(s) checked" run check

printf '2024-01-01 Broken\n 10 expenses:food\n -5 assets:cash\n' | "$DIR/pta" check 2>/dev/null
[ $? -eq 1 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: check-invalid-exit"; }

printf '2024-01-01 Broken\n 10 expenses:food\n -5 assets:cash\n' | "$DIR/pta" check 2>&1 | grep -q "off by 5.00" \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: check-invalid-message"; }

echo ""
echo "=== balance ==="
expect_contains "balance-total"       "0.00 total"        run balance
expect_contains "balance-expenses"    "12174.00 expenses" run balance expenses
expect_contains "balance-depth-1"     "12174.00 expenses" run balance --depth 1
expect_not_contains "balance-depth-1-no-children" "expenses:" run balance --depth 1
expect_contains "balance-depth-2"     "334.00 expenses:food" run balance --depth 2
expect_not_contains "balance-depth-2-no-groceries" "food:groceries" run balance --depth 2
expect_contains "balance-multi"       "-9324.00 assets"   run balance assets liabilities

echo ""
echo "=== date filtering ==="
expect_contains "balance-period"      "37.50 total"       run balance --period 2011-01
expect_contains "balance-year"        "11374.00 expenses" run balance expenses --year 2011
expect_contains "balance-from-to"     "0.00 total"        run balance --from 2011-04-25 --to 2011-04-27

echo ""
echo "=== register ==="
expect_contains "reg-account"         "expenses:food:groceries" run reg --period 2011-01 expenses:food
expect_contains "reg-running"         "146.50"             run reg --period 2011-01 expenses:food

echo ""
echo "=== accounts ==="
acct_count=$(run accounts | wc -l | tr -d ' ')
[ "$acct_count" = "12" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: accounts count (got $acct_count)"; }
expect_contains "accounts-checking"   "assets:checking"   run accounts

echo ""
echo "=== by-month ==="
expect_contains "by-month-dec2010"    "2010-12 -225"      run by-month

echo ""
echo "=== stats ==="
expect_contains "stats-first"         "First date: 2010-12-01" run stats
expect_contains "stats-last"          "Last date: 2011-12-01"  run stats
expect_contains "stats-balance"       "Balance: 0"        run stats

echo ""
echo "=== pipe input ==="
expect_contains "pipe-balance"        "0.00 total"        sh -c 'cat "$0" | "$1" balance' "$DEMO" "$DIR/pta"

echo ""
echo "=== existing test.txt ==="
txt_result=$(cat "$DIR/tests/test.txt" | "$DIR/pta" balance 2>&1)
echo "$txt_result" | grep -q "19.48 total" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: test-txt-balance"; }

echo ""
echo "=== periodic transactions ==="
PERIODIC='~ monthly from 2024-01-01 to 2024-04-01
 100 expenses:rent
-100 assets:checking
'

periodic_count=$(printf '%s\n' "$PERIODIC" | "$DIR/postings" | wc -l | tr -d ' ')
[ "$periodic_count" = "6" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-monthly-count (got $periodic_count)"; }

printf '%s\n' "$PERIODIC" | "$DIR/postings" | grep -q "planned" \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-planned-tag"; }

biweekly_count=$(printf '~ every 2 weeks from 2024-01-01 to 2024-02-01\n 1 expenses:test\n' | "$DIR/postings" | wc -l | tr -d ' ')
[ "$biweekly_count" = "3" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-every-2w-count (got $biweekly_count, want 3)"; }

quarterly_count=$(printf '~ quarterly from 2024-01-01 to 2025-01-01\n 1 expenses:test\n' | "$DIR/postings" | wc -l | tr -d ' ')
[ "$quarterly_count" = "4" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-quarterly-count (got $quarterly_count, want 4)"; }

yearly_count=$(printf '~ yearly from 2024-01-01 to 2026-01-01\n 1 expenses:test\n' | "$DIR/postings" | wc -l | tr -d ' ')
[ "$yearly_count" = "2" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-yearly-count (got $yearly_count, want 2)"; }

daily_count=$(printf '~ daily from 2024-01-01 to 2024-01-05\n 1 expenses:test\n' | "$DIR/postings" | wc -l | tr -d ' ')
[ "$daily_count" = "4" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-daily-count (got $daily_count, want 4)"; }

printf '%s\n' "$PERIODIC" | "$DIR/postings" | grep -v planned | wc -l | tr -d ' ' | grep -q '^0$' \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-grep-v-planned"; }

printf '%s\n' "$PERIODIC" | "$DIR/pta" balance | grep -q "300.00 expenses" \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-balance"; }

printf '%s\n' "$PERIODIC" | "$DIR/pta" balance --planned | grep -q "300.00 expenses" \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-planned-flag"; }

printf '%s\n' "$PERIODIC" | "$DIR/pta" balance --actual | grep -q "0.00 total" \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: periodic-actual-flag"; }

echo ""
echo "=== invoice ==="
INV="$DIR/tests/invoice.txt"
IC="$DIR/tests/invoice-customers"
IM="$DIR/tests/invoice-company"

# paid invoice 2024-001 (3 line items summing to 1000, paid 1000)
inv_html=$(cat "$INV" | PTA_CUSTOMERS="$IC" PTA_COMPANY="$IM" "$DIR/pta" invoice 2024-001 2>&1)
echo "$inv_html" | grep -q "<title>Faktúra 2024-001</title>" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-title"; }
echo "$inv_html" | grep -q "ACME Solutions s.r.o."          && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-client-name"; }
echo "$inv_html" | grep -q "Konzultač"                       && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-item-label"; }
echo "$inv_html" | grep -q "Test s.r.o."                     && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-seller-name"; }
echo "$inv_html" | grep -q "1,000.00\|>1000.00<"             && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-amount"; }
echo "$inv_html" | grep -qi ">Paid<"                         && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-paid-status"; }
# exactly 3 item rows (the # index cells are the only bare <td>DIGIT</td>)
item_rows=$(echo "$inv_html" | grep -cE '<td>[0-9]+</td>')
[ "$item_rows" = "3" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-item-count (got $item_rows)"; }

# unpaid invoice 2024-002 (800, no payment)
inv2=$(cat "$INV" | PTA_CUSTOMERS="$IC" PTA_COMPANY="$IM" "$DIR/pta" invoice 2024-002 2>&1)
echo "$inv2" | grep -q "Globex a.s."         && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice2-client"; }
echo "$inv2" | grep -qi ">Unpaid<"           && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice2-status"; }
echo "$inv2" | grep -q "800.00"              && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice2-amount"; }

# missing invoice -> non-zero exit
cat "$INV" | PTA_CUSTOMERS="$IC" PTA_COMPANY="$IM" "$DIR/pta" invoice 9999 2>/dev/null
[ $? -ne 0 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-missing-exit"; }

# no invoice number -> usage error (exit 2)
echo "" | "$DIR/invoice" >/dev/null 2>&1
[ $? -eq 2 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-no-arg-exit"; }

# fallback template works without the HTML file
inv3=$(cat "$INV" | PTA_CUSTOMERS="$IC" PTA_COMPANY="$IM" PTA_INVOICE_TEMPLATE=/nope "$DIR/pta" invoice 2024-001 2>&1)
echo "$inv3" | grep -qi "<html"              && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: invoice-fallback-template"; }

echo ""
echo "=== pta-tools shebang routing ==="

CSV_TEST=$(mktemp /tmp/pta-test-XXXX.csv)
cat > "$CSV_TEST" <<'CSVEOF'
#!pta-tool: convert-csv --date 1 --amount 2 --payee 3 --account assets:checking --skip-header
date,amount,description
2024-01-01,100,Test Income
2024-01-02,-30,Test Expense
CSVEOF

csv_out=$(cat "$CSV_TEST" | "$DIR/pta-tools/convert-csv" --date 1 --amount 2 --payee 3 --account assets:checking --skip-header 2>&1)
echo "$csv_out" | grep -q "100 assets:checking" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: convert-csv-output-amount"; }
echo "$csv_out" | grep -q "Test Income" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: convert-csv-output-payee"; }

file_out=$("$DIR/pta" "$CSV_TEST" 2>&1)
echo "$file_out" | grep -q "100 assets:checking" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: shebang-routing-pta-file"; }

bal_out=$("$DIR/pta" balance -f "$CSV_TEST" 2>&1)
echo "$bal_out" | grep -q "70.00 total" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: shebang-balance (got: $(echo "$bal_out" | tail -1))"; }

echo "#!pta-tool: nonexistent" > /tmp/pta-bad-tool.csv
"$DIR/pta" /tmp/pta-bad-tool.csv >/dev/null 2>&1
[ $? -ne 0 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: unknown-tool-exit"; }

"$DIR/pta" tools 2>&1 | grep -q "convert-csv" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: tools-listing"; }

printf '#!pta-tool: convert-csv --date 1 --amount 2 --account expenses:t --skip-header --negate\ndate,amount\n2024-01-01,50\n' > /tmp/pta-negate.csv
neg_out=$("$DIR/pta" /tmp/pta-negate.csv 2>&1)
echo "$neg_out" | grep -q "\-50 expenses:t" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: convert-csv-negate"; }

rm -f "$CSV_TEST" /tmp/pta-bad-tool.csv /tmp/pta-negate.csv

echo ""
echo "================================"
echo "Results: $pass passed, $fail failed"
[ $fail -eq 0 ] && echo "All tests passed" || exit 1
