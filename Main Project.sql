use DataWarehouseAnalytics2;

select * from dim_customers;

select * from dim_products;

select * from fact_sales;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- CHANGE OF SALE OVER THE TIME

select order_date,
sales_amount
from fact_sales
where order_date is not null
order by order_date;

-- Aggrigating the data by sales amount

select order_date,
sum(sales_amount) as Total_Sales
from fact_sales
where order_date is not null
group by order_date
order by order_date;

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

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------

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

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------

-- PERFORMANCE ANALYSIS

-- (Current Measure - Target Measure)

-- We are going to analyze yearly performance of products by comparing each product's sales
-- to both its average sales performance and the previous year's sales.

select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from fact_sales f
left join dim_products as p
on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name;

-- Going to get Average now...

with yearly_product_sales as(
select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from fact_sales f
left join dim_products as p
on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name
)
select order_year, 
product_name, 
current_sales,
AVG(current_sales) over (partition by product_name) as Average_Sales
from yearly_product_sales;

-- Substracting Current Sales by Average

with yearly_product_sales as(
select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from fact_sales f
left join dim_products as p
on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name
)
select order_year, 
product_name, 
current_sales,
AVG(current_sales) over (partition by product_name) as Average_Sales,
current_sales - AVG(current_sales) over (partition by product_name) as Difference_Average
from yearly_product_sales;

-- Adding cases to tell whether it is below or above Average.

with yearly_product_sales as(
select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from fact_sales f
left join dim_products as p
on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name
)
select order_year, 
product_name, 
current_sales,
AVG(current_sales) over (partition by product_name) as Average_Sales,
current_sales - AVG(current_sales) over (partition by product_name) as Difference_Average,
case when current_sales - AVG(current_sales) over (partition by product_name) > 0 then 'Above Average'
when current_sales - AVG(current_sales) over (partition by product_name) < 0 then 'Below Average'
else 'Average'
end Average_Change
from yearly_product_sales
order by product_name, order_year

-- Now we wanna comapre with previous year sales.

with yearly_product_sales as(
select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from fact_sales f
left join dim_products as p
on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name
)
select order_year, 
product_name, 
current_sales,
AVG(current_sales) over (partition by product_name) as Average_Sales,
current_sales - AVG(current_sales) over (partition by product_name) as Difference_Average,
case when current_sales - AVG(current_sales) over (partition by product_name) > 0 then 'Above Average'
     when current_sales - AVG(current_sales) over (partition by product_name) < 0 then 'Below Average'
     else 'Average'
end Average_Change,
lag(current_sales) over (partition by product_name order by order_year) as Previous_year_sales,
current_sales - lag(current_sales) over (partition by product_name order by order_year) as Difference_Previous_year_sales,
case when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0 then 'Increased'
     when current_sales - lag(current_sales) over (partition by product_name order by order_year) < 0 then 'Decreased'
     else 'No Change'
end Previous_Year_Change
from yearly_product_sales
order by product_name, order_year

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------

-- PROPOTIONAL ANALYSIS

-- Lets see which categories contributes the most to overall sales


select category,
sum(sales_amount) as Total_Sales
from fact_sales as f
left join dim_products as p 
on p.product_key = f.product_key
group by category;

-- Lets make in percentage.

with category_sales as
(
select category,
sum(sales_amount) as total_sales
from fact_sales as f
left join dim_products as p 
on p.product_key = f.product_key
group by category 
)
select category, 
total_sales,
sum(total_sales) over () overall_sales,
concat(round((cast (total_sales as float) / sum(total_sales) over () ) *100, 2), '%') as Percentage_of_Total
from category_sales
order by Total_Sales desc;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

-- DATA SEGEMENTATION

-- Segmenting products into cost ranges and count
-- how many products fall into each segment


with product_segments as 
(
select product_key,
product_name, cost,
case when cost < 100 then 'Below 100'
     when cost between 100 and 500 then '100-500'
     when cost between 500 and 1000 then '500-1000'
     else 'Above 1000'
end cost_range
from dim_products
)
select cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc


-- Grouping customers into three segments depending upon thier spending.

/*
VIP: Customers with atleast 12 months of history and spending more tahn 5000.
Regular: Customers with least 12 months of history and spends 5000 or less.
New: Customers with lifespan less than 12 months.

Finding the total number of customers by each group
*/

with customer_spending as
(
select c.customer_key,
sum(f.sales_amount) as total_spending,
min(order_date) as first_order,
max(order_date) as last_order,
DATEDIFF(month, min(order_date), max(order_date)) as LifeSpan
from fact_sales f
left join dim_customers c
on f.customer_key = c.customer_key
group by c.customer_key
)
select customer_key,
total_spending,
LifeSpan,
case when LifeSpan >= 12 AND total_spending >= 5000 then 'VIP'
     when LifeSpan >= 12 AND total_spending <= 5000 then 'Regular'
     else 'New'
end customer_segment
from customer_spending;

-- Grouping and fetching total

with customer_spending as
(
select c.customer_key,
sum(f.sales_amount) as total_spending,
min(order_date) as first_order,
max(order_date) as last_order,
DATEDIFF(month, min(order_date), max(order_date)) as LifeSpan
from fact_sales f
left join dim_customers c
on f.customer_key = c.customer_key
group by c.customer_key
)
select customer_segment,
count(customer_key) as total_customers
from
(
select customer_key,
case when LifeSpan >= 12 AND total_spending >= 5000 then 'VIP'
     when LifeSpan >= 12 AND total_spending <= 5000 then 'Regular'
     else 'New'
end customer_segment
from customer_spending
)t
group by customer_segment
order by total_customers desc


-- -------------------------------------------------------------------------------------------------------------------------------

-- CUSTOMER REPORT:

/*
================================================================================================================================================================
Customer Report
==================================================================================================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
==================================================================================================================================================================
*/

with base_query as
(
select f.order_number,
f.product_key, f.order_date, 
f.sales_amount, f.quantity,
c.customer_key, c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) as Customer_name,
datediff(year, c.birthdate, getdate()) Age
from fact_sales f
left join dim_customers c
on c.customer_key = f.customer_key
where order_date is not null
)

,customer_aggragation as
(
select customer_key, customer_number,Customer_name,
Age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_qauntity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
datediff(month, min(order_date), max(order_date)) as lifespan
from base_query
group by 
customer_key, customer_number,Customer_name,
Age)
select customer_key, customer_number,Customer_name,
Age,
case when Age < 20 then 'Under 20'
     when Age between 20 and 29 then '20-29'
     when Age between 30 and 39 then '30-39'
     else '50 or Above'
end as age_group,
case 
     when LifeSpan >= 12 AND total_sales >= 5000 then 'VIP'
     when LifeSpan >= 12 AND total_sales <= 5000 then 'Regular'
     else 'New'
end customer_segment,
total_orders,
total_sales,
total_qauntity,
total_products,
last_order_date,
datediff(month, last_order_date, GETDATE()) as Recency,
lifespan,
case when total_sales = 0 then 0
else
total_sales / total_orders 
end as avg_order_value,
case when lifespan = 0 then total_sales
else total_sales / lifespan
end as avg_monthly_spend
from customer_aggragation;
