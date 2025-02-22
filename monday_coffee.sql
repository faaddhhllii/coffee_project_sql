CREATE TABLE city
(
	city_id INT PRIMARY KEY,
	city_name VARCHAR(15),
	population BIGINT,
	estimated_rent FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,
	customer_name VARCHAR(25),
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- Monday coffee -- Data Analysis
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

SET sql_mode = '';

-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee. given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC


-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
	ci.city_name,
	SUM(total) AS total_revenue
FROM sales AS s JOIN customers AS c ON s.customer_id = c.customer_id 
JOIN city AS ci ON ci.city_id = c.city_id 
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31'
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales count for each product
-- How many units of each coffee product have been sold?
SELECT 
	s.product_id, 
	p.product_name,
	COUNT(*) total_product_sold 
FROM sales AS s JOIN products AS p ON s.product_id  = p.product_id 
GROUP BY 1
ORDER BY 3 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each_city
SELECT 
	c2.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT c.customer_id) AS total_customers,
	ROUND(SUM(s.total) / COUNT(c.customer_id), 2) AS Average_sales
FROM sales s JOIN customers c ON s.customer_id = c.customer_id 
JOIN city c2 ON c.city_id = c2.city_id
GROUP BY 1
ORDER BY 4 DESC;

-- Q.5
-- City Population and Coffee consumers (25%)
-- provide a list of cities along with their populations and estimated coffee consumers
-- return city_name, total_current cx, estimated coffee consumers (25%)
SELECT 
	c.city_name,
	c.population,
	COUNT(DISTINCT c2.customer_id) AS total_customers,
	ROUND(COUNT(DISTINCT c2.customer_id) * 0.25, 0) AS estimated_coffee_consumers 
FROM city c JOIN customers c2 ON c.city_id = c2.city_id
GROUP BY 1;

-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
WITH product_ranking AS 
(
SELECT 
	c2.city_name,
	p.product_name,
	COUNT(s.product_id) AS total_orders,
	RANK() OVER(PARTITION BY c2.city_name ORDER BY COUNT(s.product_id) DESC) AS ranking
FROM products p JOIN sales s ON p.product_id = s.product_id
JOIN customers c ON s.customer_id = c.customer_id 
JOIN city c2 ON c.city_id = c2.city_id
GROUP BY 1, 2
)
SELECT 
	city_name,
	product_name,
	total_orders,
	ranking
FROM product_ranking
WHERE ranking <= 3
ORDER BY city_name , ranking;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT 
	c2.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_cx
FROM products p JOIN sales s ON p.product_id = s.product_id
JOIN customers c ON s.customer_id = c.customer_id 
JOIN city c2 ON c.city_id = c2.city_id
WHERE p.product_id <= 14
GROUP BY 1;

-- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / ct.total_cx, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY 5 DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
WITH monthly_sales AS (
    SELECT
        c2.city_name,
        MONTH(s.sale_date) AS month_number,
        YEAR(s.sale_date) AS year_number,
        SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city c2 ON c.city_id = c2.city_id
    JOIN products p ON s.product_id = p.product_id  
    GROUP BY c2.city_name, MONTH(s.sale_date), YEAR(s.sale_date) 
),
sales_with_growth AS (
    SELECT
        ms.city_name,
        ms.year_number,
        ms.month_number,
        ms.total_sales,
        LAG(ms.total_sales, 1, 0) OVER (PARTITION BY ms.city_name ORDER BY ms.year_number, ms.month_number) AS prev_month_sales,
        ROUND(
            (ms.total_sales - LAG(ms.total_sales, 1, 0) OVER (PARTITION BY ms.city_name ORDER BY ms.year_number, ms.month_number)) / 
            LAG(ms.total_sales, 1, 0) OVER (PARTITION BY ms.city_name ORDER BY ms.year_number, ms.month_number) * 100, 2
        ) AS sales_growth_percent
    FROM monthly_sales ms
)
SELECT
    city_name,
    year_number,
    month_number,
    total_sales,
    prev_month_sales,
    COALESCE(sales_growth_percent, 0) AS sales_growth_percent
FROM sales_with_growth
WHERE prev_month_sales != 0
ORDER BY city_name, year_number, month_number;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total_sale, total_rent, total customers, estimated coffe consumer 
WITH city_table AS 
(
SELECT
	c2.city_name,
	SUM(s.total) AS total_revenue,
	c2.estimated_rent,
	COUNT( DISTINCT c.customer_id) AS total_cx,
	ROUND(SUM(s.total)/COUNT(DISTINCT c.customer_id), 2) AS avg_sale_per_cx 
FROM sales s JOIN products p ON s.product_id = p.product_id 
JOIN customers c ON s.customer_id = c.customer_id 
JOIN city c2 ON c.city_id = c2.city_id
GROUP BY c2.city_name
),
city_rent AS
(
SELECT 
	city_name,
	estimated_rent,
	ROUND(population * 0.25 / 1000000, 3) AS estimated_coffee_consumer_in_millions
FROM city 
)
SELECT
	cr.city_name,
	ct.total_revenue,
	cr.estimated_rent AS total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_per_cx,
	ROUND(cr.estimated_rent/ct.total_cx, 2) AS avg_rent_per_cx 
FROM city_rent cr
JOIN city_table ct ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
  Top 3 Cities for Opening a Coffee Shop

  Based on the provided data, the following cities are the best locations 
  for opening a coffee shop. The selection is based on key factors such as 
  total revenue, number of customers, estimated coffee consumers, and 
  average sales per customer.
*/

/* 1. Pune - Best city for opening a coffee shop */
-- Total Revenue: 1,258,290
-- Total Customers: 52
-- Estimated Coffee Consumers: 1.875 million
-- Avg. Sale per Customer: 24,197.88
-- Reason: Pune has the highest total revenue and customer count. 
-- Even though the estimated coffee consumer base is lower than some cities, 
-- its strong financial performance makes it the top choice.

/* 2. Chennai - Balanced market size and revenue */
-- Total Revenue: 944,120
-- Total Customers: 42
-- Estimated Coffee Consumers: 2.775 million
-- Avg. Sale per Customer: 22,479.05
-- Reason: Chennai ranks second in total revenue and has a large 
-- estimated coffee consumer base. The balance between customer volume 
-- and sales per customer makes it a strong contender.

/* 3. Bangalore - Highest estimated coffee consumer base */
-- Total Revenue: 860,110
-- Total Customers: 39
-- Estimated Coffee Consumers: 3.075 million
-- Avg. Sale per Customer: 22,054.1
-- Reason: Bangalore has the highest estimated coffee consumer base, 
-- making it a promising city for long-term coffee business growth. 
-- Despite ranking third in revenue, its strong potential market is a key advantage.

/*
  Conclusion:
  Pune leads the ranking with the highest revenue and customer count, 
  followed by Chennai with a balanced market size and revenue, 
  and Bangalore with the highest estimated coffee consumer base.
  These cities provide strong business opportunities for opening a coffee shop. 
  Choosing the right location and a solid marketing strategy will further 
  enhance business success.
*/
