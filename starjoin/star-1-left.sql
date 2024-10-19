\set id random(1,1000000)

select * from t
  left join d1 on (t.id1 = d1.id)
  left join d2 on (t.id1 = d2.id)
  left join d3 on (t.id1 = d3.id)
  left join d4 on (t.id1 = d4.id)
  left join d5 on (t.id1 = d5.id)
  left join d6 on (t.id1 = d6.id)
  left join d7 on (t.id1 = d7.id)
  left join d8 on (t.id1 = d8.id)
  left join d9 on (t.id1 = d9.id)
  left join d10 on (t.id1 = d10.id)
where t.id = :id
