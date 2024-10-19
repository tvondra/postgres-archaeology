\set id random(1,10000000)

select * from t
  join d1 on (t.id1 = d1.id)
  join d2 on (t.id1 = d2.id)
  join d3 on (t.id1 = d3.id)
  join d4 on (t.id1 = d4.id)
  join d5 on (t.id1 = d5.id)
  join d6 on (t.id1 = d6.id)
  join d7 on (t.id1 = d7.id)
  join d8 on (t.id1 = d8.id)
  join d9 on (t.id1 = d9.id)
  join d10 on (t.id1 = d10.id)
where t.id = :id
