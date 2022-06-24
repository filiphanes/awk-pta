# Plain text accounting in AWK

## Features

- Balance report
- Register report
- Group by month report
- Filtering accounts
- Checking balance for each transaction

## Advantages

- depends only on standard unix awk
- can be kept and hacked in your accounting scripts dir
- faster (2x) that ledger

## Disadvantages

- fewer features

## Examples

```
$ time gawk -f balance.awk -v account="Ex|In" main.ledger
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
$ time gawk -f groupby.awk -v account=^Ex -v group=month main.ledger
2010-12                               Expenses:Escrow                       3.3531e+06        3.3531e+06
                                      Expenses:Food:Groceries               2.50924e+06       5.86234e+06
                                      Expenses:Interest:Mortgage            5.5885e+06       1.14508e+07
2011-01                               Expenses:Auto                         6.14735e+07       7.29243e+07
                                      Expenses:Books                            223540       7.31479e+07
                                      Expenses:Food:Groceries               1.21829e+06       7.43662e+07
gawk -f groupby.awk -v account=^Ex -v group=month main.ledger  0.33s user 0.01s system 96% cpu 0.351 total
```
