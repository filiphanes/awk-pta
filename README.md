# Plain text accounting with AWK
Plaintext accounting with plaintext scripts without installing additional software.

## Features

- balance report
- register report
- print report
- filtering transactions
- group by month report
- filtering postings
- accounts list
- awk's `-M` option calculates with arbitrary precision arithmetic 
- 2-3x faster that ledger with single currency (4x faster using mawk).
- commodities as account prefix (EUR:assets:cash)
- TODO:
  - validating input file
  - equity report
  - commodity pricing

# Ideas

- Simple dependencies: gawk, sort, sh.
- Simple development or customization: no compilation.
- Small readable scripts.
- Filtering language using awk syntax
- Can be kept and customized directly in your accounting repo.
- Awk knowledge is reusable in other tasks, unlike ledger specific syntax.

Quotes from one of the authors of AWK: https://a-z.readthedocs.io/en/latest/awk.html
> As with a number of languages, it was born from the necessity to meet a need. As a researcher at Bell Labs in the early 1970s, I found myself keeping track of budgets, ...

> Some Wall Street financial houses used AWK when it first came out to balance their books because it was so easy to write data-processing programs in AWK.

# Syntax

- Account names without space
- All posting lines needs to have amount
- ISO date format YYYY-MM-DD but regex can be changed
- line starting with date without following numeric amount means following postings will inherit same date
- empty line ends transaction
- postings can optionally have spaces for indentation
- higher level syntax for transactions, budgeting, auto-transaction needs to be converted to postings lines
- Reasons because amount number is before account and other tags:
   1. amount is more important than account
   2. pretty indenting doesn't need so much spaces
   3. to allow grouping postings by account without duplicating account on each line and still have valid syntax
- default ACCOUNT_REGEX is `^([A-Z]+:)?(expenses|assets|liabilities|income|equity)(:[^ ])?`
- account aliases can be used after amount or date. In 1st field can be alias only if it matches ACCOUNT_REGEX
- account on line has priority over account from transaction
- string COM@price will create 2 auto-postings

```
alias food expenses:food

2024-12-01 tesco
   5 food bread
   5 expenses:food milk
 -10 assets:cash

 2024-12-02 bitcoin
       1 BTC:assets EUR@62000
  -62000 EUR:assets:cash
```

will generate these postings lines:

```
2024-12-31 5 expenses:food bread tesco
2024-12-31 5 expenses:food milk tesco
2024-12-31 10 assets:cash tesco
2024-12-02 1 BTC:assets bitcoin EUR@62000
2024-12-02 -1 BTC:equity bitcoin autotxn
2024-12-02 62000 EUR:assets:BTC bitcoin autotxn
2024-12-02 -62000 EUR:assets:cash bitcoin
```

In this way date of each posting in transaction can be customized.

## File per account
Our syntax allows to group postings by account, not only by transaction. This makes any register listing valid input.
Basically this is what double-entry means - you need to enter each transaction in two places=accounts.
Practically this may not be the most convenient way of entering transactions.
One reason is that transactions are hard to match. Although they can be matched by adding transaction id as tag to both postings.
Second is that user need to open, append and save two files for each transaction.

```
Assets:Checking
2024-01-01 10 employer
2024-01-02 -1 water
2024-01-03 -2 food
```

```
Income:Employer
2024-01-01 -10 employer
```

```
Expenses:Groceries
2024-01-02 1 water
2024-01-03 2 food
```

## Postings syntax
- can be processed using other tools grep, sort, filter
- 1 line = 1 posting
- human readable but not intended for human use
- format: YYYY-MM-DD amount CUR account other tags notes arguments
- example: 2024-12-31 5 EUR expenses:food bread tesco

## Usage

    ./pta 
