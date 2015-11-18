import sqlite3
import sys
import re

def make_sqlite_cursor(filename, row_factory=False):
    connection = sqlite3.connect(filename)
    if row_factory: connection.row_factory = sqlite3.Row
    return connection.cursor(), connection

def read_baskets_from_sqlite(filename, budget=True, filter_fun=lambda (feature, value): True):
    cursor,conn = make_sqlite_cursor(filename)

    previousCarId = None
    basket = []
    for car_id,feature_id,value_id in cursor.execute("select car_id, feature_id, value_id from feature where value_id != 0 order by car_id asc"):
        if not budget and feature_id == "budget_F":
            continue
        if not filter_fun(feature_id, value_id):
            continue
        if (previousCarId != car_id): # next car
            if (previousCarId != None):    
                yield previousCarId,basket
            basket = [] # clear it
        basket.append(feature_id + "=" + str(value_id)) # add current feature to the basket
        previousCarId = car_id
    # last basket
    yield previousCarId, basket


feature_name_dict = None
value_name_dict = None

def get_name(sqlite_filename, feature_id, value_id=None):
    global feature_name_dict, value_name_dict

    if feature_name_dict == None:
        cursor,conn = make_sqlite_cursor(sqlite_filename)
        feature_name_dict = {}
        value_name_dict = {}
        for id, name in cursor.execute("select * from feature_name"):
            name = re.sub(" ?{Graphic: .*}", "", name)
            feature_name_dict[id] = name
        for feat_id, val_id, name in cursor.execute("select * from value_name"):
            if feat_id not in value_name_dict:
                value_name_dict[feat_id] = {}
            value_name_dict[feat_id][val_id] = name
    
    if value_id is not None:
        if feature_id in value_name_dict and value_id in value_name_dict[feature_id]:
            return value_name_dict[feature_id][value_id]
        else: return str(value_id)
    else:
        return feature_name_dict[feature_id]
    
def ele_to_str(db, ele):
    feat, val = ele.split("=")
    return get_name(db, feat)+": "+get_name(db, feat, int(val))

if __name__ == '__main__':
    seperator = ","
    if len(sys.argv) != 2:
        print("give sqlite db as first arg")
        sys.exit(1)
    for basket in read_sqlite_db(sys.argv[1]):
        print(seperator.join(basket))
