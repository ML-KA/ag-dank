

The database can be recreated like this (including primary keys!) (takes ~2 minutes):

```bash
(
cat db_empty_schema.sql
echo 'begin transaction;'
xzcat insert_commands.sql.xz
echo 'commit;'
) | sqlite3 output.sqlite
```

# Neural Net evaluation

`$ code/nn/countCorrect.sh`

out of 10k:

- correct when assuming 1:
5259
- correct when assuming 0:
4741
- correct with NN:
7407
