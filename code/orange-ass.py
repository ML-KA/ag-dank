#!/usr/bin/env python3

# http://orange.biolab.si/docs/latest/reference/rst/Orange.associate.html
import Orange

data = Orange.data.Table("baskets-sm.basket")

rules = Orange.associate.AssociationRuleInducer(data, support=0.7)

print("%4s %4s  %s" % ("Supp", "Conf", "Rule"))
for r in rules:
        print("%4.1f %4.1f  %s" % (r.support, r.confidence, r))

