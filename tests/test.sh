#!/bin/sh
# Test suite for pta commands.
# Usage: ./tests/test.sh

DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PTA_DIR="$DIR"
unset PTA_ACCOUNT_REGEX

DEMO="$DIR/tests/demo.pta"
pass=0
fail=0

# Run pta with demo.pta as piped input
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
echo "================================"
echo "Results: $pass passed, $fail failed"
[ $fail -eq 0 ] && echo "All tests passed" || exit 1
