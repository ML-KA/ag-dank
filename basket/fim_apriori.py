#!/usr/bin/env python2
import fim
import numpy
import util

db="../output.sqlite"
from_sql = False

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

print('finding rules')

rules = fim.arules(sets)
rules = sorted(rules, key = lambda x: x[3])
for consequence, condition, support_count, confidence_percent in rules:
    condition = map(ele_to_str, condition)
    consequence = ele_to_str(consequence)
    print(u"{:6.2f}% of {} eles: If {} then {}".format(confidence_percent, support_count, " & ".join(condition), consequence))

