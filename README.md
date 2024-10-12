# Plain text accounting with AWK
Plaintext accounting with plaintext scripts without installing additional software.

## Features

- Balance report
- Register report
- Print report
- Filtering transactions
- Group by month report
- Filtering accounts
- awk's `-M` option calculates with arbitrary precision arithmetic 
- 2-3x faster that ledger with single currency (4x faster using mawk).
- TODO:
  - validating input file
  - equity report

# Ideas

- Simple dependencies: awk, sort, sh.
- Simple development or customization: no compilation.
- Small readable scripts.
- Filtering language using awk syntax
- Can be kept and customized directly in your accounting repo.
- Awk knowledge is reusable in other tasks, unlike ledger specific syntax.

Quotes from one of the authors of AWK: https://a-z.readthedocs.io/en/latest/awk.html
> As with a number of languages, it was born from the necessity to meet a need. As a researcher at Bell Labs in the early 1970s, I found myself keeping track of budgets, ...

> Some Wall Street financial houses used AWK when it first came out to balance their books because it was so easy to write data-processing programs in AWK.

## Transaction syntax

- Account names without space
- All posting lines needs to have amount
- ISO date format YYYY-MM-DD but regex can be changed
- line starting with equal sign = means that following postings will inherit same tags
- empty line ends transaction
- postings can optionally have spaces for indentation

```
=2024-12-31 tesco
   5 EUR expenses:food bread
   5 EUR expenses:food milk
 -10 EUR assets:cash
```

will generate these postings lines:

```
2024-12-31   5 EUR expenses:food bread tesco
2024-12-31   5 EUR expenses:food milk tesco
2024-12-31 -10 EUR assets:cash tesco
```

In this way date of each posting in transaction can be customized.

## Postings syntax
- higher level syntax for transactions, budgeting, auto-transaction needs to be converted to postings lines
- can be processed using other tools grep, sort, filter
- 1 line = 1 posting
- human readable but not intended for human use
- format: YYYY-MM-DD amount CUR account other tags notes arguments
- example: 2024-12-31 5 EUR expenses:food bread tesco

## Usage

    ./pta 
