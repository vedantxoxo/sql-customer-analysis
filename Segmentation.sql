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
