create table t (
  id int,
  id1 int,
  id2 int,
  id3 int,
  id4 int,
  id5 int,
  id6 int,
  id7 int,
  id8 int,
  id9 int,
  id10 int,
  val text);

create table d1 (id int, val text);
create table d2 (id int, val text);
create table d3 (id int, val text);
create table d4 (id int, val text);
create table d5 (id int, val text);
create table d6 (id int, val text);
create table d7 (id int, val text);
create table d8 (id int, val text);
create table d9 (id int, val text);
create table d10 (id int, val text);

insert into d1 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d2 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d3 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d4 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d5 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d6 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d7 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d8 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d9 select i, md5(i::text) from generate_series(1,10000) s(i);
insert into d10 select i, md5(i::text) from generate_series(1,10000) s(i);

create index on t (id);

create index on d1 (id);
create index on d2 (id);
create index on d3 (id);
create index on d4 (id);
create index on d5 (id);
create index on d6 (id);
create index on d7 (id);
create index on d8 (id);
create index on d9 (id);
create index on d10 (id);

insert into t
select i,
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  10000 * random(),
  repeat(md5(i::text),8)
from generate_series(1,10000000) s(i);

create index on t (id1);
create index on t (id2);
create index on t (id3);
create index on t (id4);
create index on t (id5);
create index on t (id6);
create index on t (id7);
create index on t (id8);
create index on t (id9);
create index on t (id10);

vacuum freeze;
vacuum analyze;

checkpoint;
