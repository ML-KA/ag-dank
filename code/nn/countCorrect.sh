#!/bin/bash
expected=../../data/bits/output

echo 'out of 10k:'
echo '- correct when assuming 1:'
cat "$expected"|tail -n 10000|grep -P '^1$'|wc -l
echo '- correct when assuming 0:'
cat "$expected"|tail -n 10000|grep -P '^0$'|wc -l
echo '- correct with NN:'
th src/nnetwork/agDank/4_evaluate.lua
paste -d= <(cat "$expected"| tail -n 10000) src/nnetwork/agDank/Data/Prod/output2.txt | grep -P '0=0|1=1' | wc -l
