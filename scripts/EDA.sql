/*
==========================================================
Exploratory Data Analysis
==========================================================
As soon as we see a new project, we need to understand the DB. 
For this we run these queries to know the tables and columns.
We can also use the object Explorer

*/

--Data base Exploration: Explore all Objects in the Database

SELECT * FROM INFORMATION_SCHEMA.TABLES;

--Explore all columns in the Database

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='dim_products';

---------------------------------------------------------------------------

--Dimension Exploration
--Explore the DImension country to understand where our customers come from

SELECT DISTINCT country FROM gold.dim_customers;

--Explore all categories, the major divisions of products

SELECT DISTINCT category,subcategory,product_name FROM gold.dim_products;
----------------------------------------------------------------------------

--Date Exploration
--Identify the timespan of our Business

SELECT 
	MIN(order_date) first_order_date,
	MAX(order_date) last_order_date,
	DATEDIFF(year,MIN(order_date),MAX(order_date)) AS order_placement_year_range
FROM gold.fact_sales;


--Identify the youngest & oldest cutomer

SELECT 
MIN(birthdate) AS oldest_birthdate,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year,MIN(birthdate),GETDATE()) AS age_of_oldest_customer,
DATEDIFF(year,MAX(birthdate),GETDATE()) AS age_of_youngest_customer
FROM gold.dim_customers;

-------------------------------------------------------------

--Measure Exploration

--Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;

--Total number of items sold
SELECT SUM(quantity) AS items_sold FROM gold.fact_sales;

--Average selling price
SELECT AVG(price) AS average_selling_price FROM gold.fact_sales;

--Total number of Orders
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales;

--Total number of products
SELECT COUNT(product_key) AS total_products FROM gold.dim_products

--Total number of Customers
SELECT COUNT(DISTINCT customer_number) AS total_customers FROM gold.dim_customers;

--Total number of cutomers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS customers_who_ordered FROM gold.fact_sales;


-----------REPORT WITH KEY METRICS--------------
SELECT 'total_sales' AS Dimension, SUM(sales_amount) AS 'Value' FROM gold.fact_sales
UNION ALL
SELECT 'items_sold',SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'average_selling_price',AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'total_orders',COUNT(DISTINCT order_number)  FROM gold.fact_sales
UNION ALL
SELECT 'total_products',COUNT(product_key) FROM gold.dim_products
UNION ALL
SELECT 'total_customers',COUNT(DISTINCT customer_number) FROM gold.dim_customers
UNION ALL
SELECT 'customers_who_ordered',COUNT(DISTINCT customer_key) FROM gold.fact_sales;

---------------------------------------------------------------------------
--Magnitude Analysis

--Find total customers by country

SELECT 
	country,
	COUNT(customer_key) AS customer_count 
FROM gold.dim_customers
GROUP BY country
ORDER BY customer_count DESC;

--Total customers by gender

SELECT 
gender,
COUNT(customer_key) AS customer_count 
FROM gold.dim_customers
GROUP BY gender
ORDER BY customer_count DESC;

--Total products per category

SELECT 
category,
COUNT(product_key) total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

--Average cost in each category

SELECT 
category,
AVG(cost) avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

--Revenue generated for each category

SELECT p.category, SUM(f.sales_amount) AS total_sales
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f
ON p.product_key=f.product_key
GROUP BY p.category
ORDER BY total_sales DESC;


--Revenue by each customer
SELECT
SUM(f.sales_amount) total_sales,
firstname+' '+lastname AS customer_name
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
GROUP BY firstname,lastname
ORDER BY total_sales DESC;

--Distribution of sold item across country
SELECT
SUM(quantity) total_sales,
country,category
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
GROUP BY country,category
ORDER BY total_sales DESC;

----------------------------------------

--RANKING ANALYSIS

--Highest revenue generating 5 products

SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
GROUP BY  p.product_name
ORDER BY revenue DESC;


--Least revenue generating 5 products

SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
GROUP BY  p.product_name
ORDER BY revenue ASC;

--Highest revenue generating 10 customers

SELECT TOP 10
c.firstname+' '+c.lastname,
SUM(f.sales_amount) AS revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
GROUP BY  firstname,lastname
ORDER BY revenue DESC;


--Least order placed 3 customer

SELECT TOP 3
c.firstname,c.lastname,
COUNT(DISTINCT f.order_number) AS orders_placed
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
GROUP BY  firstname,lastname
ORDER BY orders_placed ASC;
