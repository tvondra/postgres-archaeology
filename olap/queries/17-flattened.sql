-- using 1583427054 as a seed to the RNG

create temporary table tmp_avg_quantity as
		select
			l_partkey as agg_partkey,
			0.2 * avg(l_quantity) as avg_quantity
		from lineitem
		group by l_partkey;

create index idx_tmp_avg_quantity on tmp_avg_quantity(agg_partkey);

analyze tmp_avg_quantity;

select
	sum(l_extendedprice) / 7.0 as avg_yearly
from
	lineitem,
	part,
	tmp_avg_quantity part_agg
where
	p_partkey = l_partkey
	and agg_partkey = l_partkey
	and p_brand = 'Brand#22'
	and p_container = 'LG BOX'
	and l_quantity < avg_quantity
LIMIT 1;

drop table tmp_avg_quantity;
