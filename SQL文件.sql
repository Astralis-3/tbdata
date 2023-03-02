select * from tbdata;
select 时间戳 from tbdata;
-- 0.索引
-- 0.1 tbdata的索引如下
ALTER TABLE tbdata ADD INDEX userid(用户ID);
ALTER TABLE tbdata ADD INDEX goodsid(商品ID);
ALTER TABLE tbdata add index categ(商品类目);
ALTER TABLE tbdata ADD INDEX act(行为);
-- alter table tbdata
--               add index index_user_goods(用户ID,商品ID);
-- alter table tbdata
-- 				drop index index_user_goods; -- 0.1s删除
alter table tbdata
              add index index_user_goods_cat(用户ID,商品ID,商品类目);
-- 0.2 r_table索引如下 
ALTER TABLE r_table add index rdate(最近购买时间)

/*
总数据量：
select count(unname) from tbdata; -- 用时13.5s未建索引，未走索引
select count(*) from tbdata; -- 用时3.68s走Userid索引

*/
-- 1.行为统计
select 行为,count(行为)
from tbdata
group by 行为;

-- 2.用户行为视图 
create view 用户行为视图 as
select 用户ID,商品ID,
sum(if(行为 = 'pv',1,0)) as '点击',
sum(if(行为 = 'cart',1,0)) as '加入购物车',
sum(if(行为 = 'fav',1,0)) as '收藏',
sum(if(行为 = 'buy',1,0)) as '购买'
from tbdata
group by 用户ID,商品ID; -- 使用到 user_goods与use_goods_cat两个索引
drop view 用户行为视图; -- 删除行为视图


-- 3.点击次数top10
explain 
select 商品类目,count(商品类目)as '点击次数' 
from tbdata where 行为='pv' 
group by 商品类目 
order by '点击次数' desc 
limit 10;

-- 4.购买榜top10
explain 
select 商品ID,count(商品ID) as '购买次数'
from tbdata where 行为='pv'
group by 商品ID
order by '购买次数' desc
limit 10;

-- 5.购买率分析 
-- 5.1用户购买次数（该表用作F值，取消limit 1000限制）
explain
select 用户ID,count(行为) as '购买次数'
from tbdata where 行为='buy'
group by 用户ID
order by '购买次数' desc;

-- 5.2用户最近一次购买(该表用作R值，取消limit 1000限制）
explain 
select 用户ID,max(日期) as '最近购买时间'
from tbdata where 行为='buy'
group by 用户ID;

-- 5.3用户R值(视图)
create view R值 as
-- explain
select 用户ID,最近购买时间,
(case when datediff('2017-12-03',最近购买时间)<=2 then 4
      when datediff('2017-12-03',最近购买时间)<=4 then 3
      when datediff('2017-12-03',最近购买时间)<=6 then 2
      when datediff('2017-12-03',最近购买时间)<=8 then 1
      end) as R值
from r_table;

-- 5.4用户F值（视图）
create view F值 as 
-- explain
select 用户ID,购买次数,
(case when 购买次数 >= 20 then 4
      when 购买次数 between 10 and 15 then 3
      when 购买次数 between 5 and 10 then 2
      when 购买次数 between 1 and 5 then 1
 else 0 end) as F值
from f_table;

-- 5.5 R值与F值平均
select avg(R值) from R值; -- 均值3.25
select avg(F值) from F值; -- 均值1.20

-- 5.6 RF视图 (没M) 见jupyter lab