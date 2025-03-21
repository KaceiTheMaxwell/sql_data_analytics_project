/*

Data Segmentation

Task: Segment the products into cost ranges and count how many
	  products fall into each cost range segment

Solution: Most products cost less than $100, or not so far off, between $100 - $500 which could be the accessories

*/

-- Review the data
--SELECT 
--*
--FROM [gold.dim_products]

-- Data needed: cost, product_name or number or key

-- create the cost range
SELECT 
cost,
product_key,
product_name,
product_number,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100 - 500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
	 ELSE 'Above 1000'
END cost_range

FROM [gold.dim_products]

-- create aggregation to compare all the products in our defined cost range
WITH product_segments AS (
SELECT 
cost,
product_key,
product_name,
product_number,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100 - 500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
	 ELSE 'Above 1000'
END cost_range
FROM [gold.dim_products]
)

SELECT
cost_range, 
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

/*

Greater sales insights:

Task 1: 
Group customers into three (3) segments based on their spending behaviour:
 - VIP: Customers with at least 12 months of history and spending more than $5,000
 - Regular: Customers with at least 12 months of history and spending $5,000 or less
 - New: Customers with a lifespan less than 12 months of history

Task 2:
Find the total number of customers in each group

*/

-- Data needed: total number of months, total spending/sales, total number of customers, order date (time)

-- Collect the data needed

SELECT 
c.customer_key,

-- to determine how much each customer spends
SUM(f.sales_amount) AS total_spending, -- sum the sales amount to find out the total spending for each customer

-- to determine the lifespan of the order, first we need the customers' first and last order dates for spending over the 12 time
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,

-- to determine the lifespan of the order, we need the total time for their order time
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM [gold.fact_sales] f
JOIN [gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
ORDER BY c.customer_key


-- Task 1: customer types
WITH customer_spending AS (
SELECT 
c.customer_key,

-- to determine how much each customer spends
SUM(f.sales_amount) AS total_spending, -- sum the sales amount to find out the total spending for each customer

-- to determine the lifespan of the order, first we need the customers' first and last order dates for spending over the 12 time
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,

-- to determine the lifespan of the order, we need the total time for their order time
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

FROM [gold.fact_sales] f
JOIN [gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
customer_key,
total_spending,
lifespan,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
	 ELSE 'New'
END customer_type
FROM customer_spending
ORDER BY customer_key,
customer_type DESC
--------------------------------------------------------------------------------------------


-- Task 2: total number of customers for each customer type
-- segment customers based on their spending behaviors - over 14,000 new customers

WITH customer_spending AS (
SELECT 
c.customer_key,

-- to determine how much each customer spends
SUM(f.sales_amount) AS total_spending, -- sum the sales amount to find out the total spending for each customer

-- to determine the lifespan of the order, first we need the customers' first and last order dates for spending over the 12 time
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,

-- to determine the lifespan of the order, we need the total time for their order time
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

FROM [gold.fact_sales] f
JOIN [gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
customer_type,
COUNT(customer_key) AS total_customers
FROM (
	SELECT
	customer_key,
	CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END customer_type
	FROM customer_spending) t
GROUP BY customer_type
ORDER BY total_customers DESC
