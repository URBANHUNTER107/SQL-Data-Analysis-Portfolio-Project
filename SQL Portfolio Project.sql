--Our Table or Dataset
select * from dbo.credit_card_transcations

--Changing the name of columns from uppercase to lowercase
EXEC sp_rename 'dbo.credit_card_transcations.index',  'rn',  'COLUMN';
EXEC sp_rename 'dbo.credit_card_transcations.City',  'city',  'COLUMN';
EXEC sp_rename 'dbo.credit_card_transcations.Date',  'date',  'COLUMN';
EXEC sp_rename 'dbo.credit_card_transcations.Card_Type',  'card_type',  'COLUMN';
EXEC sp_rename 'dbo.credit_card_transcations.Exp_Type',  'exp_type',  'COLUMN';
EXEC sp_rename 'dbo.credit_card_transcations.Gender',  'gender',  'COLUMN';
EXEC sp_rename 'dbo.credit_card_transcations.Amount',  'amount',  'COLUMN';


--1- write a query to print top 5 cities with highest spends 
--and their percentage contribution of total credit card spends

with cte1 as (
select city,sum(amount) as total_spend
from credit_card_transcations
group by city)

,total_spent as (select sum(cast(amount as bigint)) as total_amount from credit_card_transcations)

select top 5 cte1.*, round(total_spend*1.0/total_amount * 100,2) as percentage_contribution from 
cte1 inner join total_spent on 1=1
order by total_spend desc

--Insight:- Thus the top 5 cities with highest spends are 
--namely:- Greater Mumbai, Bengaluru, Hyderabad, Delhi, Kolkata 



--2- write a query to print highest spend month 
--and amount spent in that month for each card type

with cte as (
select card_type,datepart(year,date) yt
,datepart(month,date) mt,sum(amount) as total_spend
from dbo.credit_card_transcations
group by card_type,datepart(year,date),datepart(month,date)
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

--Insight:- Thus, highest spend month are January for Gold, September for Platinum,
--December for signature and March for Silver



--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

WITH CTE1 AS (
    SELECT *, 
           SUM(amount) OVER (PARTITION BY card_type ORDER BY rn) AS run_sum
    FROM dbo.credit_card_transcations
),
CTE2 AS (
    SELECT card_type, 
           MIN(run_sum) AS rs, 
           MIN(rn) AS rn
    FROM CTE1
    WHERE run_sum > 1000000
    GROUP BY card_type
)
SELECT *
FROM CTE1
WHERE rn IN (SELECT rn FROM CTE2);

--Insight:- Thus, mostly in Greater Mumbai, different card 
--types reached 10 Lakh limit early


--4- write a query to find city which had lowest percentage spend for gold card type

select top 1 card_type,city, (sum(amount)*1.00/(select sum(amount) from dbo.credit_card_transcations 
where card_type='Gold'))*100.00 as perc
from dbo.credit_card_transcations
where card_type='Gold'
group by card_type,city
order by perc 

--Insight:- Thus, Dharmtari had lowest percentage spend for gold card type 


--5- write a query to print 3 columns:  city, highest_expense_type , 
--lowest_expense_type (example format : Delhi , bills, Fuel)

 
with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transcations
group by city,exp_type)

select city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type from
(select city, exp_type
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city



--6- write a query to find percentage contribution of spends by females for each expense type

select A.exp_type, women_amt, total, round(((women_amt*1.00/total)*100.00),2) as percentage_female_contribution 
from
(select gender, exp_type, sum(amount) as women_amt
from dbo.credit_card_transcations
where gender='F'
group by gender,exp_type) A
inner join
(select exp_type,sum(amount) as total
from dbo.credit_card_transcations
group by exp_type) B
on A.exp_type=B.exp_type

--Insight:- Thus, you can see the percentage contribution of spends by females for each expense type


--7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,datepart(year,date) yt
,datepart(month,date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,date),datepart(month,date)
)
select top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;

--Insight:- Thus, Platinum saw highest month over month growth in Jan-2014


--8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city, sum(amount) as amt,count(date) as no_trans, round((sum(amount)*1.00/count(date)),2) as ratio 
from dbo.credit_card_transcations  
where DATEPART(WEEKDAY,date) in (1,7)
group by city
order by ratio DESC

--Insight:- Thus, Sonepur has highest total spend to total no of transcations ratio

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as (
select *
,row_number() over(partition by city order by date,rn) as rn1
from credit_card_transcations)
select top 1 city,datediff(day,min(date),max(date)) as datediff1
from cte
where rn1=1 or rn1=500
group by city
having count(1)=2
order by datediff1 

--Insight:- Bengaluru took least number of days to reach its 500th transaction after the first transaction in that city