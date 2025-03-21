/*
Changes over time: Analyse sales performance (sales amount) over time (order date)
*/

-- Review the data

SELECT order_date, sales_amount
FROM [gold.fact_sales]
WHERE order_date is not NULL
ORDER BY order_date

-- total daily sales
SELECT order_date, SUM(sales_amount) AS total_sales
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY order_date
ORDER BY order_date

-- total year sales: But how did the company perform annually?
SELECT 
YEAR(order_date) AS order_year, 
SUM(sales_amount) AS total_sales
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

-- total year sales: How did the company perform annually, and did it acquire or lose customers over time?
SELECT 
YEAR(order_date) AS order_year, 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

-- total year sales: How did the company's sales production vary with these observed changes?
SELECT 
YEAR(order_date) AS order_year, 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

-- total year sales: How did the company's monthly sales production vary, and think about the larger societal happenings? -- Christmas?
SELECT 
YEAR(order_date) AS order_year, 
MONTH(order_date) AS order_month, 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date) 
