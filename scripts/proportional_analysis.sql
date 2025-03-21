/*

Proportional Analysis

Task: Which categories contributed the most to the overall sales?
Solution: There is an over-reliance on bike sales.

*/

-- Data needed: total sales / sales amount, category

WITH category_sales AS (
SELECT 
products.category AS product_categories,
SUM(sales.sales_amount) AS total_sales
FROM [gold.fact_sales] AS sales
JOIN [gold.dim_products] AS products
ON sales.product_key = products.product_key
WHERE category is not NULL
GROUP BY category
)

SELECT
product_categories,
total_sales,
-- total sales of the whole dataset
SUM(total_sales) OVER() AS overall_sales,
-- find the percentage of total sales, add a concatenate for % sign
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC

--------------------------------------------------------------

-- Which products account for this sales?
-- Solution: The group of products with product number BK-M68

WITH product_sales AS (
SELECT 
products.product_number AS product_p_number,
SUM(sales.sales_amount) AS total_sales
FROM [gold.fact_sales] AS sales
JOIN [gold.dim_products] AS products
ON sales.product_key = products.product_key
WHERE product_number is not NULL
GROUP BY product_number
)

SELECT
product_p_number,
total_sales,
-- total sales of the whole dataset
SUM(total_sales) OVER() AS overall_sales,
-- find the percentage of total sales, add a concatenate for % sign
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100, 2), '%') AS percentage_of_total
FROM product_sales
ORDER BY total_sales DESC
