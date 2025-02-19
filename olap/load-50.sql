\timing on

BEGIN;

CREATE TABLE PART (

	P_PARTKEY		SERIAL,
	P_NAME			VARCHAR(55),
	P_MFGR			CHAR(25),
	P_BRAND			CHAR(10),
	P_TYPE			VARCHAR(25),
	P_SIZE			INTEGER,
	P_CONTAINER		CHAR(10),
	P_RETAILPRICE	DECIMAL,
	P_COMMENT		VARCHAR(23)
);

CREATE TABLE SUPPLIER (
	S_SUPPKEY		SERIAL,
	S_NAME			CHAR(25),
	S_ADDRESS		VARCHAR(40),
	S_NATIONKEY		INTEGER NOT NULL, -- references N_NATIONKEY
	S_PHONE			CHAR(15),
	S_ACCTBAL		DECIMAL,
	S_COMMENT		VARCHAR(101)
);

CREATE TABLE PARTSUPP (
	PS_PARTKEY		INTEGER NOT NULL, -- references P_PARTKEY
	PS_SUPPKEY		INTEGER NOT NULL, -- references S_SUPPKEY
	PS_AVAILQTY		INTEGER,
	PS_SUPPLYCOST	DECIMAL,
	PS_COMMENT		VARCHAR(199)
);

CREATE TABLE CUSTOMER (
	C_CUSTKEY		SERIAL,
	C_NAME			VARCHAR(25),
	C_ADDRESS		VARCHAR(40),
	C_NATIONKEY		INTEGER NOT NULL, -- references N_NATIONKEY
	C_PHONE			CHAR(15),
	C_ACCTBAL		DECIMAL,
	C_MKTSEGMENT	CHAR(10),
	C_COMMENT		VARCHAR(117)
);

CREATE TABLE ORDERS (
	O_ORDERKEY		SERIAL,
	O_CUSTKEY		INTEGER NOT NULL, -- references C_CUSTKEY
	O_ORDERSTATUS	CHAR(1),
	O_TOTALPRICE	DECIMAL,
	O_ORDERDATE		DATE,
	O_ORDERPRIORITY	CHAR(15),
	O_CLERK			CHAR(15),
	O_SHIPPRIORITY	INTEGER,
	O_COMMENT		VARCHAR(79)
);

CREATE TABLE LINEITEM (
	L_ORDERKEY		INTEGER NOT NULL, -- references O_ORDERKEY
	L_PARTKEY		INTEGER NOT NULL, -- references P_PARTKEY (compound fk to PARTSUPP)
	L_SUPPKEY		INTEGER NOT NULL, -- references S_SUPPKEY (compound fk to PARTSUPP)
	L_LINENUMBER	INTEGER,
	L_QUANTITY		DECIMAL,
	L_EXTENDEDPRICE	DECIMAL,
	L_DISCOUNT		DECIMAL,
	L_TAX			DECIMAL,
	L_RETURNFLAG	CHAR(1),
	L_LINESTATUS	CHAR(1),
	L_SHIPDATE		DATE,
	L_COMMITDATE	DATE,
	L_RECEIPTDATE	DATE,
	L_SHIPINSTRUCT	CHAR(25),
	L_SHIPMODE		CHAR(10),
	L_COMMENT		VARCHAR(44)
);

CREATE TABLE NATION (
	N_NATIONKEY		SERIAL,
	N_NAME			CHAR(25),
	N_REGIONKEY		INTEGER NOT NULL,  -- references R_REGIONKEY
	N_COMMENT		VARCHAR(152)
);

CREATE TABLE REGION (
	R_REGIONKEY	SERIAL,
	R_NAME		CHAR(25),
	R_COMMENT	VARCHAR(152)
);

COPY part FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/part.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY region FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/region.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY nation FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/nation.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY supplier FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/supplier.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY customer FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/customer.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY partsupp FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/partsupp.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY orders FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/orders.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY lineitem FROM PROGRAM 'gunzip -c /mnt/data/tpch/50/lineitem.csv.gz' WITH (FORMAT csv, DELIMITER '|');

ALTER TABLE lineitem ALTER l_orderkey SET (n_distinct = -0.25);

COMMIT;

VACUUM ANALYZE;

-- primary keys
ALTER TABLE PART ADD PRIMARY KEY (P_PARTKEY);
ALTER TABLE SUPPLIER ADD PRIMARY KEY (S_SUPPKEY);
ALTER TABLE PARTSUPP ADD PRIMARY KEY (PS_PARTKEY, PS_SUPPKEY);
ALTER TABLE CUSTOMER ADD PRIMARY KEY (C_CUSTKEY);
ALTER TABLE ORDERS ADD PRIMARY KEY (O_ORDERKEY);
ALTER TABLE LINEITEM ADD PRIMARY KEY (L_ORDERKEY, L_LINENUMBER);
ALTER TABLE NATION ADD PRIMARY KEY (N_NATIONKEY);
ALTER TABLE REGION ADD PRIMARY KEY (R_REGIONKEY);

-- indexes on the foreign keys

CREATE INDEX IDX_SUPPLIER_NATION_KEY ON SUPPLIER (S_NATIONKEY);

CREATE INDEX IDX_PARTSUPP_PARTKEY ON PARTSUPP (PS_PARTKEY);
CREATE INDEX IDX_PARTSUPP_SUPPKEY ON PARTSUPP (PS_SUPPKEY);

CREATE INDEX IDX_CUSTOMER_NATIONKEY ON CUSTOMER (C_NATIONKEY);

CREATE INDEX IDX_ORDERS_CUSTKEY ON ORDERS (O_CUSTKEY);

CREATE INDEX IDX_LINEITEM_ORDERKEY ON LINEITEM (L_ORDERKEY);
CREATE INDEX IDX_LINEITEM_PART_SUPP ON LINEITEM (L_PARTKEY,L_SUPPKEY);

CREATE INDEX IDX_NATION_REGIONKEY ON NATION (N_REGIONKEY);


-- aditional indexes

CREATE INDEX IDX_LINEITEM_SHIPDATE ON LINEITEM (L_SHIPDATE, L_DISCOUNT, L_QUANTITY);

CREATE INDEX IDX_ORDERS_ORDERDATE ON ORDERS (O_ORDERDATE);

VACUUM FREEZE;

VACUUM ANALYZE;
