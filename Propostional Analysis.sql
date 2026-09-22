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
