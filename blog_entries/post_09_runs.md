

```sql
SELECT min(id), val, count(*) as runlength
from (select t.*,
             (row_number() over (order by id) -
              row_number() over (partition by val order by id)
             ) as grp
      from data t
     ) t
group by grp, val;
```

| id | val |
|  1 |  33 |
|  2 |  33 |
|  3 |  44 |
|  4 |  28 |
|  5 |  44 |
|  6 |  44 |