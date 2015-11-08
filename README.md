

The database can be recreated like this (including primary keys!) (takes ~2 minutes):

```bash
(
cat db_empty_schema.sql
echo 'begin transaction;'
xzcat insert_commands.sql.xz
echo 'commit;'
) | sqlite3 output.sqlite
```
