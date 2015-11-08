# Code http://blog.derekfarren.com/2015/02/how-to-implement-large-scale-market.html

def data_pass(basket_list, minSupport, pass_nbr, candidate_dct):
	for basket in basket_list:
		candidate_dct = update_candidates(basket, candidate_dct, pass_nbr)

	candidate_dct = clear_items(candidate_dct, minSupport, pass_nbr)
	
	return candidate_dct


from itertools import combinations

def update_candidates(item_lst, candidate_dct, pass_nbr):
	if pass_nbr==1:
		for item in item_lst:
			candidate_dct[(item,)]+=1
	else:
		frequent_items_set = set()
		for item_tuple in combinations(sorted(item_lst), pass_nbr-1):	
			if item_tuple in candidate_dct:
				frequent_items_set.update(item_tuple)
					
		for item_set in combinations(sorted(frequent_items_set), pass_nbr):
			candidate_dct[item_set]+=1
		
	return candidate_dct


def clear_items(candidate_dct, minSupport, pass_nbr):
	for item_tuple, cnt in candidate_dct.items():
		if cnt<minSupport or len(item_tuple)<pass_nbr:
			del candidate_dct[item_tuple]
	return candidate_dct


import time
from collections import defaultdict

def main(basket_list, support, itemset_size):
	candidate_dct = defaultdict(lambda: 0)
	for i in range(itemset_size):
		now = time.time()
		candidate_dct = data_pass(basket_list, support, pass_nbr=i+1, candidate_dct=candidate_dct)
		print "pass number %i took %f and found %i candidates" % (i+1, time.time()-now, len(candidate_dct))
	return candidate_dct


def dumpclean(obj):
    if type(obj) == dict:
        for k, v in obj.items():
            if hasattr(v, '__iter__'):
                print k
                dumpclean(v)
            else:
                print '%s : %s' % (k, v)
    elif type(obj) == list:
        for v in obj:
            if hasattr(v, '__iter__'):
                dumpclean(v)
            else:
                print v
    else:
        print obj

# generate lists from sql
import sqlite3
connection = sqlite3.connect("company.db")
connection.row_factory = sqlite3.Row
cursor = connection.cursor()
cursor.execute("select car_id, feature_name.name as f_name, value_name.name as v_name from feature, feature_name, value_name where feature.feature_id = feature_name.feature_id and feature.value_id = value_name.value_id and value_name.feature_id = value_name and feature.feature_id = value_name.feature_id  order by")
result = cursor.featchall();

basket_list = []
previousCarId = "";
basket = []
for r in result 
	if (previousCarId != r['car_id']) # next car
		if (previousCarId != "")	
			basket_list.append(basket); # add basket to the basket list
		basket = [] # clear it
	basket.extend(r['f_name'] + r['v_name']) # add current feature to the basket



#itemsets_dct = main([["Milch", "Mehl", "Muesli"], ["Milch", "Mehl", "Eier"], ["Milch", "Mehl", "Muesli", "Eier", "Keckse"], ["Milch", "Mehl", "Keckse", "Eier"], ["Milch", "Mehl", "Brot", "Wurst"], ["A", "B"], ["A", "B"]], 2, 2)
itemsets_dct = main(basket_list, 200, len(basket_list))

for itemset, frequency in itemsets_dct.iteritems():
	print itemset, frequency



