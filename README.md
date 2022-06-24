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
2010-12                               Expenses:Escrow                       3353100.00  3353100.000000
                                      Expenses:Food:Groceries               2509236.51  5862336.510000
                                      Expenses:Interest:Mortgage            5588500.00  11450836.510000
2011-01                               Expenses:Auto                         61473500.00  72924336.510000
                                      Expenses:Books                         223540.02  73147876.530000
                                      Expenses:Food:Groceries               1218293.07  74366169.600000
0.33s user 0.01s system 98% cpu 0.344 total
```
