#!/usr/bin/env python2
import fim
import sys
import util
import random
db="../output.sqlite"
from_sql = False
if len(sys.argv) != 2:
    print("usage "+sys.argv[0]+" algorithm")
    sys.exit(1)
algo = sys.argv[1]

transactions = []

if from_sql:
    print("reading from sql")
    transactions = [x for (car, x) in util.read_baskets_from_sqlite(db)]
else:
    print("reading from file")
    for line in  open('baskets.basket'):
        transactions.append(line.rstrip('\n').split(','))


def ele_to_str(ele):
    global db
    return util.ele_to_str(db, ele)

sets = map(set, transactions)
print('running algorithm')
if algo == "eclat":
    s = fim.eclat(transactions)
    s = sorted(s, key=lambda x:x[1])
    for items,supp in s:
        items = map(ele_to_str, items)
        print(u"{} items: {}".format(supp, "|".join(items)))
elif algo == "eclat-rules":
    rules = fim.eclat(transactions, target='r', report='aC')
    rules = sorted(rules, key = lambda x: x[3])
    for consequence, condition, support_count, confidence_percent in rules:
        condition = map(ele_to_str, condition)
        consequence = ele_to_str(consequence)
        print(u"{:6.2f}% of {} eles: If {} then {}".format(confidence_percent, support_count, " & ".join(condition), consequence))
elif algo == "arules":
    rules = fim.arules(transactions, supp=5)
    random.shuffle(rules) # lambda x: x[3])
    for consequence, condition, support_count, confidence_percent in rules:
        conditionSet = set(condition)
        #den = [c for c in sets if not conditionSet.issubset(c)]
        #num = [c for c in den if consequence in c]
        den = 0
        for c in sets: 
            if not conditionSet.issubset(c): 
                den = den+1
        num = 0 
        for c in sets: 
            if (consequence in c) and (not conditionSet.issubset(c)):
                num = num +1
        
        #confidence_of_not_condition = float(len(num))/len(den)
        confidence_of_not_condition = float(num)/den

        condition = map(ele_to_str, condition)
        consequence = ele_to_str(consequence)
        interestingness = confidence_percent/100 - confidence_of_not_condition
        print(u"{} {:6.2f}% of {} eles: If {} then {}".format(interestingness, confidence_percent, support_count, " & ".join(condition), consequence).encode('utf-8'))
else:
    print("unknown algo")
