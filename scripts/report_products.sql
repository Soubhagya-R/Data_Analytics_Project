/*
=============================================================================
PRODUCTS REPORT
=============================================================================
Purpose:
	This report combines key product metrics and behaviors

Highlights:

	1. Gather essential fields such as product name,category,subcategory and cost.
	2. Segment products by revenue to identify High-Performers, Mid-Range or Low-Performers.
	3. Aggregates product level metrics:
		-total orders
		-total sales
		-total quantity sold
		-total customers(unique)
		-lifespan (in months)
	4.Calculate valuable KPIs:
		-recency(months since last sale)
		-average order revenue
		-average monthly revenue
===================================================================================
*/

CREATE VIEW gold.report_products AS

WITH base_table AS
(
SELECT
p.product_name,
p.category,
p.subcategory,
p.cost,
f.order_number,
f.sales_amount,
f.quantity,
f.customer_key,
f.order_date

FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
)

SELECT 
product_name,
category,
subcategory,
cost,
COUNT(order_number) AS total_orders,
SUM(quantity) AS total_quantity_sold,
SUM(sales_amount) AS total_sales,
CASE
	WHEN SUM(sales_amount)<=50000 THEN 'Low-Performers'
	WHEN SUM(sales_amount)BETWEEN 50000 AND 100000  THEN 'Mid-Range'
	ELSE 'High-Performers'
END product_segemnt,
COUNT(DISTINCT customer_key) AS total_customers,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan,
DATEDIFF(MONTH,MAX(order_date),GETDATE()) AS recency,
SUM(sales_amount)/COUNT(order_number) AS avg_order_revenue,
SUM(sales_amount)/DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS avg_monthly_revenue
FROM base_table
GROUP BY
product_name,
category,
subcategory,
cost;

SELECT * FROM gold.report_products
