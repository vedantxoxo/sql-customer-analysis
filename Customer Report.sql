/*
========================================================================================
Customer Report
========================================================================================
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
=============================================================================================================================================================================
*/
create view customer_report as
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
from customer_aggragation



-- select * from customer_report