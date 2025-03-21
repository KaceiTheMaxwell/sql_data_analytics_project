/*
Performance Analysis

Task: Analyse the yearly performance of products by comparing each product's sales to both its average 
sales performance and the previous year's sales
*/

-- Review the needed data though interchangeable for other data of interest like product quantity
-- Data needed: yearly = order date; product sales = sales amount; of products = product name


--SELECT 
--*
--FROM [gold.fact_sales] AS sales

--SELECT 
--*
--FROM [gold.dim_products] AS products

--SELECT 
--YEAR(sales.order_date) AS order_year,
--SUM(sales.sales_amount) AS current_sales,
--products.product_name
--FROM [gold.fact_sales] AS sales
--JOIN [gold.dim_products] AS products
--ON sales.product_key = products.product_key
--WHERE order_date is not NULL
--GROUP BY YEAR(sales.order_date), products.product_name
----------------------------------------------------------------------------------

-- Task 1
-- Comparison to average sales performance: Build CTE

WITH yearly_product_sales AS
(
SELECT 
YEAR(sales.order_date) AS order_year,
SUM(sales.sales_amount) AS current_sales,
products.product_name
FROM [gold.fact_sales] AS sales
JOIN [gold.dim_products] AS products
ON sales.product_key = products.product_key
WHERE order_date is not NULL
GROUP BY YEAR(sales.order_date), products.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales
FROM yearly_product_sales
ORDER BY product_name, order_year

-- Comparison to average sales performance: Sales performance

WITH yearly_product_sales AS
(
SELECT 
YEAR(sales.order_date) AS order_year,
SUM(sales.sales_amount) AS current_sales,
products.product_name
FROM [gold.fact_sales] AS sales
JOIN [gold.dim_products] AS products
ON sales.product_key = products.product_key
WHERE order_date is not NULL
GROUP BY YEAR(sales.order_date), products.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_from_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
	ELSE 'Average'
	END AS average_change
FROM yearly_product_sales
ORDER BY product_name, order_year

--------------------------------------------------

-- Task 2
-- Comparison to previous year sales performance: LAG()

WITH yearly_product_sales AS
(
SELECT 
YEAR(sales.order_date) AS order_year,
SUM(sales.sales_amount) AS current_sales,
products.product_name
FROM [gold.fact_sales] AS sales
JOIN [gold.dim_products] AS products
ON sales.product_key = products.product_key
WHERE order_date is not NULL
GROUP BY YEAR(sales.order_date), products.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_from_avg,
AVG(current_sales) OVER (PARTITION BY product_name) AS diff_from_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
	ELSE 'Average'
	END AS average_change,
-- Year-over-year performance change
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales, -- prints the previous year sales
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_from_previous_year_sales,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	ELSE 'No Change'
	END AS change_from_previous_year
FROM yearly_product_sales
ORDER BY product_name, order_year
