./fromledger ~/projects/pta/ledger.txt | awk -v 'FS=\t' '{b[$4]+=+$2}END{for(a in b)print b[a], a}'
