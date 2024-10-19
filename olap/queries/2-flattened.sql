-- using 1583427054 as a seed to the RNG

create temporary table tmp_supplycost as
		select
			ps_partkey,
			min(ps_supplycost) AS min_ps_supplycost
		from
			partsupp,
			supplier,
			nation,
			region
		where
			s_suppkey = ps_suppkey
			and s_nationkey = n_nationkey
			and n_regionkey = r_regionkey
			and r_name = 'AMERICA'
		group by
			ps_partkey;

create index tmp_supplycost_idx on tmp_supplycost (ps_partkey);

analyze tmp_supplycost;

select
	s_acctbal,
	s_name,
	n_name,
	p_partkey,
	p_mfgr,
	s_address,
	s_phone,
	s_comment
from
	part,
	supplier,
	partsupp,
	nation,
	region
where
	p_partkey = ps_partkey
	and s_suppkey = ps_suppkey
	and p_size = 16
	and p_type like '%NICKEL'
	and s_nationkey = n_nationkey
	and n_regionkey = r_regionkey
	and r_name = 'AMERICA'
	and ps_supplycost = (
		select
			min_ps_supplycost
		from
			tmp_supplycost
		where
			p_partkey = ps_partkey
	)
order by
	s_acctbal desc,
	n_name,
	s_name,
	p_partkey
LIMIT 100;

drop table tmp_supplycost;
