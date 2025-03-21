/*
Cumulative Analysis: Calculate the total sales per month, and the running total of sales over time for trends

sales performance (sales amount) over time (order date)
*/

--  the total sales per month (individual monthly sales), and the running total sales over time (progress with time)
SELECT
order_date,
total_sales,
SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales -- our window function, partition
FROM -- subquery
(
SELECT 
-- this helps to view each year's performance
DATETRUNC(MONTH, order_date) AS order_date, -- truncate the month and year into the first day of each month throughout the year
SUM(sales_amount) AS total_sales
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY DATETRUNC(MONTH, order_date)
) AS sources


--  the total sales per month for only one year, and its running total of sales in that time 
SELECT
order_date,
total_sales,
SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date) AS running_total_sales -- our window function, partition
FROM -- subquery
(
SELECT 
-- YEAR(order_date) AS order_year, 
DATETRUNC(MONTH, order_date) AS order_date, -- truncate the month and year into the first day of each month throughout the year
SUM(sales_amount) AS total_sales
-- COUNT(DISTINCT customer_key) AS total_customers,
-- SUM(quantity) AS total_quantity
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY DATETRUNC(MONTH, order_date)
) AS sources

-- What's was the moving average of the price?

SELECT
order_date,
total_sales,
SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales, 
AVG(avg_price) OVER(ORDER BY order_date) AS moving_average_price -- This is very useful for seeing how the business is growing with time (progression)
FROM -- subquery
(
SELECT 
DATETRUNC(YEAR, order_date) AS order_date, -- truncate the month and year into the first day of each month throughout the year
SUM(sales_amount) AS total_sales, 
AVG(price) AS avg_price
FROM [gold.fact_sales]
WHERE order_date is not NULL
GROUP BY DATETRUNC(YEAR, order_date)
) H
