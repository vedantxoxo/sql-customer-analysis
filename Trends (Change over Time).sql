-- CHANGE OF SALE OVER THE TIME

select order_date,
sales_amount
from fact_sales
where order_date is not null
order by order_date

-- Aggrigating the data by sales amount

select order_date,
sum(sales_amount) as Total_Sales
from fact_sales
where order_date is not null
group by order_date
order by order_date

-- We want data by year:

select
year(order_date) as order_date,
sum(sales_amount) as Total_Sales
from fact_sales
where order_date is not null
group by year(order_date)
order by year(order_date)

-- Total Customers: This will tell total customers we had each year

select
year(order_date) as order_year,
sum(sales_amount) as Total_Sales,
count (distinct customer_key) as Total_Customers,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by year(order_date)
order by year(order_date)

-- For Months:

select
month(order_date) as order_month,
sum(sales_amount) as Total_Sales,
count (distinct customer_key) as Total_Customers,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by month(order_date)
order by month(order_date)

-- For both 

select
year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as Total_Sales,
count (distinct customer_key) as Total_Customers,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date),  month(order_date)

-- More optimized


select
DATETRUNC(month, order_date) as order_month,
sum(sales_amount) as Total_Sales,
count (distinct customer_key) as Total_Customers,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)
order by DATETRUNC(month, order_date)

select
DATETRUNC(year, order_date) as order_month,
sum(sales_amount) as Total_Sales,
count (distinct customer_key) as Total_Customers,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by DATETRUNC(year, order_date)
order by DATETRUNC(year, order_date)