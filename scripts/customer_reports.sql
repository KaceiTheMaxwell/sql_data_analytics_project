/*

=============================================================================================================
Customer Report
=============================================================================================================

Purpose:
 - This report consolidates key customer metrics and behaviors.

Highlights
	1. Gathers essential fields such as names, ages, and transaction details
	2. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	3. Segments customers into categories and age groups
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend

*/

/*----------------------------------------------------------------------------------------------------------------
1. Base Query: Build the database using JOIN to create a base query for which we can retrieve the core columns for our tables
			   Transform a few select columns to focus on only the needed data
			   Place in a CTE
-----------------------------------------------------------------------------------------------------------------*/

-- Create VIEW for storage and visulatizations

CREATE VIEW [gold.report_customers] AS
WITH base_query AS (
SELECT
f.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name, -- combine the first and last name for easier reading
c.gender,
-- c.birthdate, -- only the ages needed to create the age groups, not the exact birth date
DATEDIFF(year, c.birthdate, GETDATE()) AS age,
f.product_key,
f.order_number,
f.order_date,
f.sales_amount,
f.quantity
FROM [gold.fact_sales] f
JOIN [gold.dim_customers] c
ON f.customer_key = c.customer_key
WHERE order_date is not NULL  -- FILTER to remove null values
)

--SELECT
--*
--FROM base_query
-------------------------------------------------------------------------

/*----------------------------------------------------------------------------------------------------------------
Use data in the CTE

	2. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
-----------------------------------------------------------------------------------------------------------------*/
/* Note: Data copied below to make the next CTE 

SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders, -- number of order by customers
COUNT(DISTINCT product_key) AS total_products, -- number of unique products purchased
SUM(sales_amount) AS total_sales, -- revenue
SUM(quantity) AS total_quanity, -- raw amount products purchased or ordered
MAX(order_date) AS last_order,
-- to determine the lifespan of the order, we need the total time for their order time
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

FROM base_query
GROUP BY customer_key, customer_name, customer_number, age

*/

/*----------------------------------------------------------------------------------------------------------------
Use data in the CTE

	3. Segments customers into categories and age groups for the final table
-----------------------------------------------------------------------------------------------------------------*/

-- Note: I named the CTE from above "customer_aggregation"

--, customer_aggregation AS (

--SELECT
--customer_key,
--customer_number,
--customer_name,
--age,
--COUNT(DISTINCT order_number) AS total_orders, -- number of order by customers
--COUNT(DISTINCT product_key) AS total_products, -- number of unique products purchased
--SUM(sales_amount) AS total_sales, -- revenue
--SUM(quantity) AS total_quanity, -- raw amount products purchased or ordered
--MAX(order_date) AS last_order,
---- to determine the lifespan of the order, we need the total time for their order time
--DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

--FROM base_query
--GROUP BY customer_key, customer_name, customer_number, age
--)

--SELECT
--customer_key, 
--customer_name, 
--customer_number, 
--age,
---- note: let's create the age groups similar to how we create the customer_type
--CASE WHEN age < 20 THEN 'Under 20'
--	 WHEN age BETWEEN 20 AND 29 THEN '20 - 29'
--	 WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
--	 WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
--	 WHEN age BETWEEN 50 AND 59 THEN '50 - 59'
--	 WHEN age BETWEEN 60 AND 69 THEN '60 - 69'
--	 ELSE '70 and Above'
--END as age_group,
---- note the column called "customer_type" built from a CASE WHEN statement
--CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
--	 WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
--	 ELSE 'New'
--END AS customer_type,

--total_orders, -- number of order by customers
--total_products, -- number of unique products purchased
--total_sales, -- revenue
--total_quanity, -- raw amount products purchased or ordered
--last_order,
--lifespan
--FROM customer_aggregation

/*----------------------------------------------------------------------------------------------------------------
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend
-----------------------------------------------------------------------------------------------------------------*/

, customer_aggregation AS (

SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders, -- number of order by customers
COUNT(DISTINCT product_key) AS total_products, -- number of unique products purchased
SUM(sales_amount) AS total_sales, -- revenue
SUM(quantity) AS total_quanity, -- raw amount products purchased or ordered
MAX(order_date) AS last_order_date,
-- to determine the lifespan of the order, we need the total time for their order time
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

FROM base_query
GROUP BY customer_key, customer_name, customer_number, age
)

SELECT
customer_key, 
customer_name, 
customer_number, 
age,
-- note: let's create the age groups similar to how we create the customer_type
CASE WHEN age < 20 THEN 'Under 20'
	 WHEN age BETWEEN 20 AND 29 THEN '20 - 29'
	 WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
	 WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
	 WHEN age BETWEEN 50 AND 59 THEN '50 - 59'
	 WHEN age BETWEEN 60 AND 69 THEN '60 - 69'
	 ELSE '70 and Above'
END as age_group,
-- note the column called "customer_type" built from a CASE WHEN statement
CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	 ELSE 'New'
END AS customer_type,

total_orders, -- number of order by customers
total_products, -- number of unique products purchased
total_sales, -- revenue
total_quanity, -- raw amount products purchased or ordered
lifespan,
last_order_date,

-- calculating KPI: recency
DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency_in_months,

-- calculating KPI: average order value (total sales / total number of orders)
-- error analysis: prevent dividing by zero, 0
CASE WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders 
END AS average_order_value,

-- calculating KPI: average month spend (total sales / number of months
-- how much total sales did the customer generate on average (their total spend) over their life time with the business?
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END AS average_monthly_spend
FROM customer_aggregation
