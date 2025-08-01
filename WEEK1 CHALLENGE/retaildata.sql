CREATE TABLE retaildata (
    InvoiceNo     INT,
    StockCode     INT,
    Description   TEXT,
    Quantity      INT,
    InvoiceDate   TIMESTAMP,
    UnitPrice     DECIMAL(10, 2),
    CustomerID    INT,
    Country       VARCHAR(100),
    TotalPrice    DECIMAL(10, 2)
);
SELECT * FROM retaildata
--1.What is the total sales value for each day?
SELECT
    TO_CHAR(invoicedate, 'Day') AS day_of_the_week,
    COUNT(*) AS transaction_count,
	SUM(totalprice) as total_sales
FROM retaildata
GROUP BY TO_CHAR(invoicedate, 'Day')
ORDER BY transaction_count, total_sales;
---2. How does total revenue vary month over month?
SELECT 
	TO_CHAR(Invoicedate, 'month') as Mon_th,
	SUM(totalprice) as total_price
FROM retaildata
GROUP BY Mon_th 
ORDER BY total_price DESC;
---3. What are the average daily sales over time?
WITH daily_sales AS (
  SELECT
    invoicedate AS sale_day,
    EXTRACT(YEAR FROM invoicedate) AS year,
    SUM(totalprice) AS total_sales
  FROM retaildata
  GROUP BY invoicedate, EXTRACT(YEAR FROM invoicedate)
)
SELECT
  year,
  ROUND(AVG(total_sales), 2) AS avg_daily_sales
FROM daily_sales
GROUP BY year
ORDER BY year;
---4.What is the total quantity of items sold per week?
SELECT
  DATE_TRUNC('week', InvoiceDate) AS week_start,
  SUM(TotalPrice) AS total_weekly_sales
FROM retaildata
GROUP BY week_start
ORDER BY week_start;
---5.What is the month-over-month percentage change in revenue?
WITH month_summary AS (
  SELECT 
    DATE_TRUNC('month', InvoiceDate) AS month_start,
    TO_CHAR(InvoiceDate, 'Month') AS month_name,
    SUM(TotalPrice) AS total_price
  FROM retaildata
  GROUP BY month_start, month_name
)
SELECT
  month_start,
  month_name,
  total_price,
  ROUND(
    (total_price - LAG(total_price) OVER (ORDER BY month_start)) 
    / NULLIF(LAG(total_price) OVER (ORDER BY month_start),0) * 100, 
    2
  ) AS percent_change
FROM month_summary
ORDER BY month_start;
----6. How does customer activity vary quarter by quarter?
SELECT 
    CASE 
        WHEN invoicedate BETWEEN '2011-01-01' AND '2011-03-31' THEN '1ST QUARTER 2011'
        WHEN invoicedate BETWEEN '2011-04-01' AND '2011-06-30' THEN '2ND QUARTER 2011'
        WHEN invoicedate BETWEEN '2011-07-01' AND '2011-09-30' THEN '3RD QUARTER 2011'
        WHEN invoicedate BETWEEN '2011-10-01' AND '2011-12-31' THEN '4TH QUARTER 2011'
        ELSE 'DECEMBER 2010'
    END AS quarter,
    SUM(totalprice) AS totalsales
FROM retaildata
WHERE invoicedate BETWEEN '2010-12-01' AND '2011-12-31'
GROUP BY quarter
ORDER BY totalsales DESC;
---7. What is the trend in average unit price over time?
SELECT
	EXTRACT("YEAR" FROM INVOICEDATE) AS YEAR,
	ROUND(avg(totalprice),0) as total
from retaildata
group by year
order by total
----8. Who are the top 10 customers each month based on purchase value?
SELECT 
	customerid,
	SUM(totalprice) AS total,
	RANK() OVER(order by(SUM(totalprice))) as ranking
FROM retaildata
WHERE customerid !=0
GROUP BY customerid;
---9. What is the 7-day moving average of total sales?
WITH daily_sales AS (
  SELECT 
    DATE_TRUNC('day', invoicedate) AS sale_day,
    SUM(totalprice) AS daily_total
  FROM retaildata
  GROUP BY sale_day
)
SELECT 
  sale_day,
  daily_total,
  ROUND(AVG(daily_total) OVER (
    ORDER BY sale_day
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2) AS rolling_7_day_avg
FROM daily_sales;
---10. How many unique customers are acquired each month?
WITH first_purchase AS (
  SELECT 
    customerid,
    MIN(DATE_TRUNC('month', invoicedate)) AS first_purchase_month
  FROM retaildata
  WHERE customerid !=0
  GROUP BY customerid
)

SELECT 
  TO_CHAR(first_purchase_month, 'YYYY-MM') AS month,
  COUNT(*) AS new_customers
FROM first_purchase
GROUP BY first_purchase_month
ORDER BY first_purchase_month;