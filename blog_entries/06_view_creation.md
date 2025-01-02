# Vhapter 6 - view creation

```sql
CREATE OR REPLACE VIEW main.vw_pts_cum AS
WITH pts_by_date AS(
SELECT
  season,
  'home' venue,
  hcc ccode,
  mdate,
  CASE 
    WHEN hcg > acg THEN 3
    WHEN hcg = acg THEN 1
    ELSE 0
  END result
FROM matches
WHERE mdate IS NOT NULL
UNION 
SELECT 
  season,
  'away' venue,
  acc,
  mdate,
  CASE 
    WHEN acg > hcg THEN 3
    WHEN acg = hcg THEN 1
    ELSE 0
  END result
FROM matches
WHERE mdate IS NOT NULL
)
SELECT
  season,
  venue,
  ccode,
  mdate,
  result,
  SUM(result) OVER(PARTITION BY season, ccode
                   ORDER BY mdate
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) pts_cum
FROM pts_by_date
ORDER BY season, ccode, mdate;
```