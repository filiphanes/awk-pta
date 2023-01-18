# Plain text accounting in AWK
Plain text accounting with plain text scripts without installing additional software.


## Features

- Balance report
- Register report
- Equity report
- Print report (filtering transactions)
- Group by year/month/day report
- Filtering accounts
- Script for validating input file
- awk's `-M` option calculates with arbitrary precision arithmetic 

## Advantages

- simple dependency: only awk
- simple development or customization: no compilation
- small readable scripts
- can be kept and customized directly in your accounting repo
- 2-3x faster that ledger with single currency
- awk knowledge is reusable in other tasks, unlike ledger specific syntax

## Ledger file syntax
- very similar to original ledger
- account names without space
- account line without value must be last
- single currency scripts ignore currencies
- ISO date format (2022-06-01) but easy to customize regex

## TODO

- multi commodities
- more validation and better error messages
- more reports
- more aggregations
- more filters

## Examples
Using ledger.txt file with 122947 transactions or about 18 MB.

```
$ time gawk -f balance.awk -v account="Ex|In" ledger.txt
 61473500.00  Expenses:Auto
   223540.02  Expenses:Books
  3353100.00  Expenses:Escrow
  3727529.58  Expenses:Food:Groceries
  5588500.00  Expenses:Interest:Mortgage
-22354000.09  Income:Salary
  -335310.00  Income:Sales
------------
 51676859.51
122947  transactions
0.29s user 0.01s system 96% cpu 0.314 total
```

```
$ gtime gawk -f groupby.awk -v group=month ledger.txt
2010-12       Assets:Checking                        -2508236.51      -2508236.51
              Equity:OpeningBalances                -11178000.00     -13686236.51
              Expenses:Escrow                         3353100.00     -10333136.51
              Expenses:Food:Groceries                 2509236.51      -7823900.00
              Expenses:Interest:Mortgage              5588500.00      -2235400.00
              Liabilities:Mortgage:Principal          2235400.00             0.00
2011-01       Assets:Checking                        17782607.02      17782607.02
              Assets:Savings                        -58120400.00     -40337792.98
              Expenses:Auto                          61473500.00      21135707.02
              Expenses:Books                           223540.02      21359247.04
              Expenses:Food:Groceries                 1218293.07      22577540.11
              Income:Salary                         -22354000.09        223540.02
              Liabilities:MasterCard                  -223540.02            -0.00
2011-12       Assets:Checking:Business                 335310.00        335310.00
              Income:Sales                            -335310.00            -0.00
0.56user 0.01system 0:00.58elapsed 98%CPU (0avgtext+0avgdata 4848maxresident)k
0inputs+0outputs (0major+409minor)pagefaults 0swaps
```

```
$ gtime gawk -f equity.awk ledger.txt
2011-12-01 Opening Balances
    Assets:Checking                      15274370.51
    Assets:Checking:Business               335310.00
    Assets:Savings                      -58120400.00
    Equity:OpeningBalances              -11178000.00
    Expenses:Auto                        61473500.00
    Expenses:Books                         223540.02
    Expenses:Escrow                       3353100.00
    Expenses:Food:Groceries               3727529.58
    Expenses:Interest:Mortgage            5588500.00
    Income:Salary                       -22354000.09
    Income:Sales                          -335310.00
    Liabilities:MasterCard                -223540.02
    Liabilities:Mortgage:Principal        2235400.00
0.35user 0.01system 0:00.37elapsed 97%CPU (0avgtext+0avgdata 4832maxresident)k
0inputs+0outputs (0major+408minor)pagefaults 0swaps
```
