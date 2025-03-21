/*

=============================================================================================================
Product Report
=============================================================================================================

Purpose:
 - This report consolidates key product metrics and behaviors.

Highlights
	1. Gathers essential fields such as product name, categories, subcategories, and cost
	2. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total unique customers
		- lifespan (in months)
	3. Segments products by revenue to identify high-performers, mid-range or low-performers
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue

*/

/*----------------------------------------------------------------------------------------------------------------
1. Base Query: Build the database using JOIN to create a base query for which we can retrieve the core columns for our tables
			   Transform a few select columns to focus on only the needed data
			   Place in a CTE
-----------------------------------------------------------------------------------------------------------------*/

-- Create VIEW for storage and visulatizations

DROP VIEW IF EXISTS [gold.biking_product_report];
GO

CREATE VIEW [gold.biking_product_report] AS
WITH base_query AS (
SELECT
f.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost,
f.customer_key,
f.order_number,
f.order_date,
f.sales_amount,
f.quantity
FROM [gold.fact_sales] f
JOIN [gold.dim_products] p
ON f.product_key = p.product_key
WHERE order_date is not NULL  -- FILTER to remove null values
)

--SELECT
--*
--FROM base_query
-------------------------------------------------------------------------

, product_aggregation AS (

SELECT
product_key,
product_name,
category,
subcategory,
cost,
COUNT(DISTINCT customer_key) as total_customers,
COUNT(DISTINCT order_number) AS total_orders, -- number of order by customers
COUNT(DISTINCT product_key) AS total_products, -- number of unique products sold
SUM(sales_amount) AS total_sales, -- revenue
SUM(quantity) AS total_quanity, -- raw amount products sold
MAX(order_date) AS last_sale_date,
-- to determine the lifespan of the order, we need the total time for their sale time
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS average_selling_price
FROM base_query
GROUP BY product_key,
product_name,
category,
subcategory,
cost
)

SELECT
product_key, 
product_name, 
category,
subcategory, 
cost,

-- note the column called "product_segment" built from a CASE WHEN statement
CASE WHEN total_sales > 50000 THEN 'High Performer'
	 WHEN total_sales <= 5000 THEN 'Mid-Range'
	 ELSE 'Low Performer'
END AS product_segment,

total_orders, -- number of order by customers
total_products, -- number of unique products sold
total_sales, -- revenue
total_quanity, -- raw amount products purchased or ordered
total_customers,
lifespan,
last_sale_date,
average_selling_price,

/*
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
*/

-- KPI: Average Order Revenue (AOR)

-- calculating KPI: average order revenue (total sales / total number of orders)
-- error analysis: prevent dividing by zero, 0
CASE WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders 
END AS average_order_revenue,

-- calculating KPI: recency
DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,


-- calculating KPI: average monthly revenue (total sales / number of months
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END AS average_monthly_revenue
FROM product_aggregation
