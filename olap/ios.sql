-- Q2
CREATE INDEX q2_idx_1 ON part (p_partkey, p_size, p_type, p_mfgr);
CREATE INDEX q2_idx_2 ON partsupp (ps_partkey, ps_suppkey, ps_supplycost);
CREATE INDEX q2_idx_3 ON supplier (s_suppkey, s_nationkey, s_acctbal, s_address, s_phone, s_comment);

-- Q4
CREATE INDEX q4_idx_1 ON lineitem (l_orderkey) WHERE (l_commitdate < l_receiptdate);

-- Q5
CREATE INDEX q5_idx_1 ON lineitem (l_orderkey, l_suppkey, l_extendedprice, l_discount);

-- Q8
CREATE INDEX q8_idx_1 ON lineitem (l_partkey, l_orderkey, l_suppkey, l_extendedprice, l_discount);

-- Q9
CREATE INDEX q9_idx_1 ON lineitem (l_partkey, l_suppkey, l_orderkey, l_extendedprice, l_discount, l_quantity);

-- Q10
CREATE INDEX q10_idx_1 ON customer (c_custkey, c_nationkey, c_name, c_acctbal, c_phone, c_address, c_comment);
CREATE INDEX q10_idx_2 ON lineitem (l_orderkey, l_returnflag, l_extendedprice, l_discount);

-- Q12
CREATE INDEX q12_idx_1 ON lineitem (l_orderkey, l_shipmode, l_receiptdate) WHERE (l_commitdate < l_receiptdate) AND (l_shipdate < l_commitdate);

-- Q14
CREATE INDEX q14_idx_1 ON lineitem (l_partkey, l_shipdate, l_extendedprice, l_discount);

-- Q17
CREATE INDEX q17_idx_1 ON lineitem (l_partkey, l_quantity);

-- Q18
CREATE INDEX q18_idx_1 ON lineitem (l_orderkey, l_quantity);

-- Q19
CREATE INDEX q19_idx_1 ON lineitem (l_partkey, l_shipmode, l_shipinstruct, l_quantity, l_extendedprice, l_discount);

-- Q20
CREATE INDEX q20_idx_1 ON partsupp (ps_partkey, ps_suppkey, ps_availqty);
CREATE INDEX q20_idx_2 ON part (p_partkey, p_name);

-- Q21
CREATE INDEX q21_idx_1 ON lineitem (l_orderkey, l_receiptdate, l_suppkey, l_commitdate);
CREATE INDEX q21_idx_2 ON lineitem (l_orderkey, l_suppkey) WHERE (l_receiptdate > l_commitdate);
CREATE INDEX q21_idx_3 ON orders (o_orderkey, o_orderstatus);

ANALYZE;

