-- SQL Retail Sales Data Analysis

--Create Database & Table using PgAdmin4 - PostgreSQL
DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales (
	transactions_id INT PRIMARY KEY,
	sale_date DATE,
	sale_time TIME, 
	customer_id INT,
	gender VARCHAR(15),
	age	INT,
	category VARCHAR(25),
	quantiy INT,
	price_per_unit FLOAT,
	cogs FLOAT,
	total_sale FLOAT
);

SELECT * FROM retail_sales;

-- Data exploration and cleaning 

SELECT COUNT(*) FROM retail_sales; -- 2000

SELECT COUNT(DISTINCT customer_id) FROM retail_sales; --155

SELECT DISTINCT category FROM retail_sales; --3

--Delete any records having missing data if there is any

SELECT * FROM retail_Sales
WHERE
	sale_date IS NULL OR
	sale_time IS NULL OR
	customer_id IS NULL OR
	gender IS NULL OR
	age IS NULL OR
	category IS NULL OR
	quantiy IS NULL OR
	price_per_unit IS NULL OR
	cogs IS NULL OR
	total_sale IS NULL; -- 13 records with missing values

DELETE FROM retail_sales
WHERE 
	sale_date IS NULL OR
	sale_time IS NULL OR
	customer_id IS NULL OR
	gender IS NULL OR
	age IS NULL OR
	category IS NULL OR
	quantiy IS NULL OR
	price_per_unit IS NULL OR
	cogs IS NULL OR
	total_sale IS NULL; -- deleted 13 rows with missing values

-- Data Analysis and insights

--SQL query to retrieve all columns for sales made on 2022-11-05

SELECT * FROM retail_sales
WHERE 
	sale_date = '2022-11-05'; -- 11 records

--SQL query to retrieve all transactions where the category is clothing and the quantity sold is more than 4 in the
--month of november-2022

SELECT * FROM retail_sales AS rs
WHERE rs.category ='Clothing' AND rs.quantiy >=4 AND TO_CHAR(rs.sale_date, 'YYYY-MM') = '2022-11'; -- 17 records\

--SQL query to calculate the total sale and orders per category

SELECT 
	rs.category,
	SUM (rs.total_sale) AS total_sale_per_category,
	COUNT(*) AS total_orders
FROM retail_sales as rs
GROUP BY category;

--SQL query to find the average age of customers who purchased items from the beauty category

SELECT 
	ROUND(AVG(rs.age),2) AS average_age_beauty_category_customer
FROM retail_sales as rs
WHERE
	rs.category = 'Beauty'; --42 years

--SQL query to find all transactions where the total sale is greater than 1000

SELECT * FROM retail_sales WHERE total_sale > 1000; --306 records

--SQL query to find the total number of transactions(transaction id) made by each gender in each category

SELECT 
	rs.category,
	rs.gender,
	COUNT(rs.transactions_id) AS total_transactions
FROM retail_sales AS rs
GROUP BY 1,2
ORDER BY 1;

--SQL query to calculate the average sale for each month . Also finding out the best selling month in each year
-- 2 years data (2022 - 2023)

WITH ranked_sales AS (
    SELECT 
        EXTRACT(YEAR FROM sale_date) AS year,
        EXTRACT(MONTH FROM sale_date) AS month,
        ROUND(AVG(total_sale)::Numeric,2) AS avg_sale,
        RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) AS rank
    FROM retail_sales
    GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(MONTH FROM sale_date)
)
SELECT 
    year,
    month,
    avg_sale
FROM ranked_sales
WHERE rank = 1;

--SQL query to find the top 5 customers based on the highest total sales per customer

SELECT
	rs.customer_id,
	SUM(rs.total_sale) AS total_sale_per_customer
FROM retail_Sales rs
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

--SQL query to find the number of unique customers in each category

SELECT
	rs.category,
	COUNT(DISTINCT rs.customer_id) AS unique_customers
FROM retail_sales rs
GROUP BY 1;

--SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)

WITH shift_orders AS (
SELECT
	rs.sale_time,
	rs.transactions_id,
	CASE
		WHEN EXTRACT(HOUR FROM rs.sale_time) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM rs.sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END AS shift
FROM retail_sales as rs
)
SELECT 
	shift,
	COUNT(shift) AS number_of_orders
FROM shift_orders
GROUP BY shift;
