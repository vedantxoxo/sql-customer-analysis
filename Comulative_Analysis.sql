-- COMULATIVE ANALYSIS

-- Calculate the total sales per month
-- and the running total sales over time.

-- I want total sales for each month:

select 
DATETRUNC(month, order_date) as order_date,
sum(sales_amount) as Total_Sales
from fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)
order by DATETRUNC(month, order_date)

-- Runiing total using windows function and sub-query

select order_date,
Total_Sales,
sum(Total_Sales) over (partition by order_date order by order_date) as Running_Total
from
(
select 
DATETRUNC(month, order_date) as order_date,
sum(sales_amount) as Total_Sales
from fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)
) t

-- For years

select order_date,
Total_Sales,
sum(Total_Sales) over (order by order_date) as Running_Total
from
(
select 
DATETRUNC(year, order_date) as order_date,
sum(sales_amount) as Total_Sales
from fact_sales
where order_date is not null
group by DATETRUNC(year, order_date)
) t

-- Now, lets calculate moving Average by Price.

select order_date,
Total_Sales,
sum(Total_Sales) over (order by order_date) as Running_Total_Sales,
sum(avg_price) over (order by order_date) as Running_Average_Price
from
(
select 
DATETRUNC(year, order_date) as order_date,
sum(sales_amount) as Total_Sales,
avg(price) as avg_price
from fact_sales
where order_date is not null
group by DATETRUNC(year, order_date)
) t 
