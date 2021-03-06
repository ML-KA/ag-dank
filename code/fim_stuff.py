#!/usr/bin/env python2
from __future__ import print_function
import fim
import sys
import util
import random
import time
db="../output.sqlite"
from_sql = False
if len(sys.argv) != 2:
    print("usage "+sys.argv[0]+" algorithm")
    sys.exit(1)
algo = sys.argv[1]

transactions = []
calculate_interestingness = False

def filter_fun(feature_id, value_id):
    return True#feature_id.startswith("s7_")

def filter_fun_str(item):
    feat, val = item.split("=")
    val_id = int(val)
    return filter_fun(feat, val_id)

if from_sql:
    print("reading from sql", file=sys.stderr)
    transactions = [x for (car, x) in util.read_baskets_from_sqlite(db, false, filter_fun)]
else:
    print("reading from file", file=sys.stderr)
    for line in  open('baskets.basket'):
        transactions.append([x for x in line.rstrip('\n').split(',') if filter_fun_str(x) ])

trcount = len(transactions)
print(trcount)
transactions = filter(lambda x: len(x) >= 1, transactions)
print(len(transactions))

def ele_to_str(ele):
    global db
    return util.ele_to_str(db, ele)

sets = map(set, transactions)
print('running algorithm', file=sys.stderr)
before = time.time()
if algo == "apriori":
    s = fim.apriori(transactions, supp=2)
    s = sorted(s, key=lambda x:x[1])
    for items,supp in s:
        items = map(ele_to_str, items)
        print(u"{} items: {}".format(supp/float(trcount), "|".join(items)).encode('utf-8'))
if algo == "eclat":
    s = fim.eclat(transactions, supp=2)
    s = sorted(s, key=lambda x:x[1])
    for items,supp in s:
        items = map(ele_to_str, items)
        print(u"{} items: {}".format(supp, "|".join(items)).encode('utf-8'))
elif algo == "eclat-rules":
    rules = fim.eclat(transactions, target='r', report='aC')
    rules = sorted(rules, key = lambda x: x[3])
    for consequence, condition, support_count, confidence_percent in rules:
        condition = map(ele_to_str, condition)
        consequence = ele_to_str(consequence)
        print(u"{:6.2f}% of {} eles: If {} then {}".format(confidence_percent, support_count, " & ".join(condition), consequence))
elif algo == "arules":
    rules = fim.arules(transactions, supp=2, conf=75, report='aCl', eval='l', thresh=30)
    #random.shuffle(rules) # lambda x: x[3])
    #rules = sorted(rules, key = lambda x: x[3]) # sort by confidence %
    rules = sorted(rules, key = lambda x: x[4]) # sort by lift
    rules = sorted(rules, key = lambda x: -len(x[1])) # sort by condition length
    for consequence, condition, support_count, confidence_percent, lift in rules:
        conditionSet = set(condition)
        #den = [c for c in sets if not conditionSet.issubset(c)]
        #num = [c for c in den if consequence in c]
        interestingness = 0
        if calculate_interestingness:
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
            interestingness = confidence_percent/100 - confidence_of_not_condition

        condition = map(ele_to_str, condition)
        consequence = ele_to_str(consequence)
        print(u"lift={} | {} {:6.2f}% of {} eles: If ({}) then ({})".format(lift, interestingness, confidence_percent, support_count, " & ".join(condition), consequence).encode('utf-8'))
else:
    print("unknown algo")

after = time.time()
print("running {} took {} seconds for {} entries".format(algo, after-before, len(transactions)), file=sys.stderr)
