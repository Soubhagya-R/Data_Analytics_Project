--Change Over Time

---Business over the month-year
SELECT 
MONTH(order_date) order_month,YEAR(order_date) order_year,
SUM(sales_amount) total_sales,
COUNT(DISTINCT customer_key) total_customer,
SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date),YEAR(order_date)
ORDER BY YEAR(order_date),MONTH(order_date) ;
---------------------------------------------------------------------
--Cumulative Analysis
--YoY Growth: Running total
SELECT
month_year,
tot_sales,
SUM(tot_sales) OVER(ORDER BY month_year) AS running_total
FROM 

(SELECT
DATETRUNC(year,order_date) month_year,
SUM(sales_amount) tot_sales

FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)

)t;
--Month on Month growth over years
SELECT
month_year,
tot_sales,
SUM(tot_sales) OVER(PARTITION BY year(month_year) ORDER BY month_year) AS running_total
FROM 

(SELECT
DATETRUNC(month,order_date) month_year,
SUM(sales_amount) tot_sales

FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
--ORDER BY DATETRUNC(month,order_date)
)t;

----------------------------------------------------------------------------------
--Performance Analysis

--Analyse yearly performance of products by comparing its sales to average sales and previous year sales

WITH yearly_product_sales AS
(
SELECT 
YEAR(f.order_date) order_year,
p.product_name,
SUM(f.quantity) total_quantity

FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
WHERE order_date IS NOT NULL
GROUP BY p.product_name,
YEAR(f.order_date)

 )


SELECT 
	order_year,
	product_name,
	total_quantity,
	AVG(total_quantity) OVER (PARTITION BY product_name) AS avg_product_sales,
	total_quantity-AVG(total_quantity) OVER (PARTITION BY product_name) diff_avg,
	CASE
		WHEN total_quantity-AVG(total_quantity) OVER (PARTITION BY product_name)<0 THEN 'Below Average'
		WHEN total_quantity-AVG(total_quantity) OVER (PARTITION BY product_name)=0 THEN 'Average'
		ELSE 'Above Average'
	END avg_flag,
	LAG(total_quantity) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS previous_year_sold,
	total_quantity-LAG(total_quantity) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS yearly_diff_sales,
	CASE
		WHEN total_quantity-LAG(total_quantity) OVER (PARTITION BY product_name ORDER BY order_year ASC) IS NULL THEN 'No previous year sale'
		WHEN total_quantity-LAG(total_quantity) OVER (PARTITION BY product_name ORDER BY order_year ASC) >0 THEN 'Sold more'
		WHEN total_quantity-LAG(total_quantity) OVER (PARTITION BY product_name ORDER BY order_year ASC) <0 THEN 'Sold Less'
		ELSE 'Same as last year'
	END AS flag_yoy_sales

FROM yearly_product_sales;

------------------------------------------------------------------------------------------

--Part to whole Analysis
--Percentage contribution of each category

WITH category_sales AS
(
SELECT 
p.category,
SUM(f.sales_amount) total_sales_category
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
GROUP BY p.category
)

SELECT 
category, 
total_sales_category,
SUM(total_sales_category) OVER() AS total_sales,
CONCAT(ROUND((CAST(total_sales_category AS FLOAT)/SUM(total_sales_category) OVER())*100,2),'%') AS percentage_category
FROM category_sales
ORDER BY percentage_category DESC


--------------------------------------------------
--Data segmentation

--Classify products based on cost range and find how many products fall in each segment

WITH segment AS
(
SELECT 
product_name,
cost,
CASE 
	WHEN cost<100 THEN 'Low'
	WHEN cost<500 THEN 'Mid'
	ELSE 'High'
END cost_segment
FROM gold.dim_products)

SELECT cost_segment,count(product_name) nr_of_products
FROM segment
GROUP BY cost_segment

/*
Group customers into 3 segments based on their spent
-VIP: Customers with atleast 12 month history and spending>5000
-Regular: Customers with atleast 12 month history and spending<5000
-New: Customers with lifespan less than 12 months
And find cust count in each group
*/
WITH customer_activity AS
(
SELECT 
c.customer_key,
SUM(f.sales_amount) spent,
DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS lifespan,
CASE 
WHEN DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date))>=12 AND SUM(sales_amount)>5000 THEN 'VIP'
WHEN DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date))>=12 AND SUM(sales_amount)<=5000 THEN 'Regular'
ELSE 'New'
END  AS cust_segment

FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key= c.customer_key
GROUP BY c.customer_key)

SELECT 
cust_segment, COUNT(*)
FROM customer_activity
GROUP BY cust_segment

-------------------------------------------------------------------------------


