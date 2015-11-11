#!/usr/bin/env python2
import fim
import sys
import util

db="../output.sqlite"
from_sql = False
if len(sys.argv) != 2:
    print("usage "+sys.argv[0]+" algorithm")
    sys.exit(1)
algo = sys.argv[1]

sets = []
if from_sql:
    print("reading from sql")
    sets = [x for x in util.read_baskets_from_sqlite(db)]
else:
    print("reading from file")
    for line in  open('baskets.basket'):
        sets.append(line.rstrip('\n').split(','))

def ele_to_str(ele):
    global db
    feat, val = ele.split("=")
    return util.get_name(db, feat)+": "+util.get_name(db, feat, int(val))

print('running algorithm')
if algo == "eclat":
    s = fim.eclat(sets)
    s = sorted(s, key=lambda x:x[1])
    for items,supp in s:
        items = map(ele_to_str, items)
        print(u"{} items: {}".format(supp, "|".join(items)))
elif algo == "eclat-rules":
    rules = fim.eclat(sets, target='r', report='aC')
    rules = sorted(rules, key = lambda x: x[3])
    for consequence, condition, support_count, confidence_percent in rules:
        condition = map(ele_to_str, condition)
        consequence = ele_to_str(consequence)
        print(u"{:6.2f}% of {} eles: If {} then {}".format(confidence_percent, support_count, " & ".join(condition), consequence))
elif algo == "arules":
    rules = fim.arules(sets)
    rules = sorted(rules, key = lambda x: x[3])
    for consequence, condition, support_count, confidence_percent in rules:
        condition = map(ele_to_str, condition)
        consequence = ele_to_str(consequence)
        print(u"{:6.2f}% of {} eles: If {} then {}".format(confidence_percent, support_count, " & ".join(condition), consequence))
else:
    print("unknown algo")
