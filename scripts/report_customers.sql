/*
=============================================================================
CUSTOMER REPORT
=============================================================================
Purpose:
	This report combines key customer metrics and behaviors

Highlights:

	1. Gather essential fields such as names,age,and transaction details.
	2. Segment customers into categories(VIP,Regular,New) and age groups.
	3.aggregates customer level metrics:
		-total orders
		-total sales
		-total quantity purchased
		-total products
		-lifespan (in months)
	4.Calculate valuable KPIs:
		-recency(months since last order)
		-averageordervalue
		-average monthly spend
===================================================================================
*/
-----------BASE QUERY:TRANSFORMATIONS------
CREATE VIEW gold.report_customers AS

WITH base_table AS
(
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
c.firstname+' '+c.lastname customer_name,
DATEDIFF(YEAR, c.birthdate,GETDATE()) customer_age,
c.country,
c.gender
FROM
gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL),

-------------AGGREGATIONS----------
customer_aggregation AS
(
SELECT 
customer_key,
customer_number,
customer_name,
customer_age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_spent,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) product_count,
MAX(order_date) AS last_order_date,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan

FROM base_table
GROUP BY 
customer_key,
customer_number,
customer_name,
customer_age)

SELECT 
customer_key,
customer_number,
customer_name,
customer_age,
CASE
	WHEN customer_age<20 THEN 'Under 20'
	WHEN customer_age BETWEEN 20 AND 40 THEN 'Between 20 & 40'
	WHEN customer_age BETWEEN 40 AND 60 THEN 'Between 40 & 60'
	ELSE 'Above 60'
END AS age_category,
CASE 
	WHEN lifespan>=12 AND total_spent>5000 THEN 'VIP'
	WHEN lifespan>=12 AND total_spent<5000THEN 'Regular'
	ELSE 'New'
END  AS cust_segment,
total_orders,
total_spent,
total_quantity,
product_count,
DATEDIFF(MONTH, last_order_date, GETDATE()) recency,
CASE 
	WHEN total_orders=0 THEN 0
	ELSE total_spent/total_orders 
END avg_order_value,
CASE
	WHEN lifespan=0 THEN total_spent
	ELSE total_spent/lifespan
END avg_monthly_spend

FROM customer_aggregation;
-------------------------------------------------------------------------------

SELECT * FROM gold.report_customers;
