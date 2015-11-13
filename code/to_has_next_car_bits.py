#!/usr/bin/env python2
import util
import os, io

def output_to_bits(filename):
    os.mkdir("bits")
    with open('bits/input', 'w') as inp, open('bits/output', 'w') as oup:
        cursor,conn = util.make_sqlite_cursor(filename)
        fields = []
        for feature_id, name in cursor.execute("select * from feature_name"):
            if feature_id in "respid,budget_F,step1_budget".split(","):
                continue
            if feature_id == "step1":
                for i in range(1,10):
                    fields.append("step1="+str(i))
            if feature_id.startswith("s7_"):
                fields.append(feature_id+"=1")
            for val, in conn.cursor().execute("select value_id from value_name where feature_id='{}'".format(feature_id)):
                fields.append(feature_id+"="+str(val))
        fieldToInx=dict([(e,i) for (i,e) in enumerate(fields)])
        with io.open('bits/header', 'w', encoding='utf-8') as head:
            head.write(u"bit positions:\nby id:\n{}\nby names:\n{}".format(
                u"\n".join(fields), u"\n".join(map(lambda id: util.ele_to_str(filename, id), fields))))
        fieldCount = len(fields)
        conn.close()
        lastNum=None
        for car_id,transaction in util.read_baskets_from_sqlite(filename, budget=False):
            if car_id%1000==0: print(car_id)
            respondent = int((car_id-1)/4)
            car_num = ((car_id-1)%4) +1
            info = [0]*fieldCount
            for item in transaction:
                info[fieldToInx[item]] = 1
            if info[9:13] == [0,0,0,0]:
                # not configured, ignore
                continue
            if lastNum == None:
                pass
            elif car_id == lastNum + 1:
                oup.write("1\n")
            elif car_num == 1:
                oup.write("0\n")
            else:
                raise "wat"
            #if car_num != 4: inp.write('car {} of person {}: {}\n'.format(car_num, respondent,''.join(map(str,info))))
            if car_num != 4:
                inp.write(''.join(map(str,info)))
                inp.write('\n')
                lastNum = car_id
            else:
                lastNum = None
        oup.write("0\n") # last car does not have successor

output_to_bits("../output.sqlite")
