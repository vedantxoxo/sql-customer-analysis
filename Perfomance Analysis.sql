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