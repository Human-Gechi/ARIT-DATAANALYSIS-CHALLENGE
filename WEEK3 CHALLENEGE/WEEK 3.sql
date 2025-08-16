--- Calculate total spend for each customer
SELECT SUM(Totalprice),
	   customerid
FROM retaildata
WHERE customerid != 0
GROUP BY customerid 
ORDER BY SUM(totalprice);
--- Identify the most recent purchase date for each customer.
SELECT customerid, maxdate
FROM(
	SELECT customerid, 
		max(date(invoicedate))as maxdate
	FROM retaildata
	GROUP BY customerid) AS maxpurchases
WHERE customerid != 0
--- Count the total number of invoices per customer.
SELECT customerid, 
       COUNT(DISTINCT InvoiceNo) AS total_invoices
FROM retaildata
WHERE customerid != 0
GROUP BY customerid
ORDER BY total_invoices DESC;
---Determine average order value per customer.
SELECT   customerid, 
		ROUND(SUM(totalprice)/ COUNT(invoiceno),0) as averageorder
FROM retaildata
WHERE customerid !=0 
GROUP BY customerid
ORDER BY averageorder.
-- Calculate total spend per customer and assign tiers
SELECT 
    customerid,
    SUM(totalprice) AS total_spend,
    CASE
        WHEN SUM(totalprice) BETWEEN 200000 AND 340000 THEN 'VIP'
        WHEN SUM(totalprice) BETWEEN 100000 AND 199999 THEN 'High'
        WHEN SUM(totalprice) BETWEEN 50000 AND 99999 THEN 'Mid'     
        ELSE 'Low'
    END AS value_tier
FROM retaildata
WHERE customerid != 0
GROUP BY customerid
ORDER BY total_spend DESC;
----- Purchase Behavior Analysis
------ Calculate total quantity of items purchased per customer.
-- Step 1: Identify high-value customers and their purchases
WITH high_value_customers AS (
    SELECT 
        customerid
    FROM retaildata
    WHERE customerid != 0
    GROUP BY customerid
    HAVING SUM(totalprice) >= 100000   

-- Step 2: Aggregate purchases by product for these customers
SELECT 
    stockcode,
    SUM(quantity) AS total_quantity,
    SUM(totalprice) AS total_spend
FROM retaildata
WHERE customerid IN (SELECT customerid FROM high_value_customers)
GROUP BY stockcode
ORDER BY total_quantity DESC   -- or ORDER BY total_spend DESC
LIMIT 10;
----- Determine customers who consistently buy high-priced items (UnitPrice above a threshold).
--- List customers who make bulk purchases (high Quantity) but low overall spend.
SELECT 
    customerid,
    SUM(quantity) AS total_quantity,
    SUM(totalprice) AS total_spend
FROM retaildata
WHERE customerid != 0 AND totalprice != 0.0
GROUP BY customerid
HAVING SUM(quantity) >= 1000
   AND SUM(totalprice) < 500  
ORDER BY total_spend, total_quantity ;
---- customer month over month change in purchse behavoiur
WITH monthly_spend AS (
    SELECT
        customerid,
        DATE_TRUNC('month', invoicedate) AS month,
        SUM(totalprice) AS monthly_total
    FROM retaildata
    WHERE customerid != 0
    GROUP BY customerid, DATE_TRUNC('month', invoicedate)
),
spend_with_lag AS (
    SELECT
        customerid,
        month,
        monthly_total,
        LAG(monthly_total) OVER (PARTITION BY customerid ORDER BY month) AS prev_month_spend
    FROM monthly_spend
)
SELECT *
FROM spend_with_lag
WHERE prev_month_spend IS NOT NULL
  AND monthly_total > prev_month_spend
ORDER BY customerid, month;
------ Identify high-value customer and their countries who haven’t purchased in the last 60 days.
SELECT 
	country,
    customerid,
    MAX(invoicedate) AS last_purchase,
    SUM(totalprice) AS total_spent,
    MAX(invoicedate) - INTERVAL '60 days' AS threshold_date
FROM retaildata
WHERE customerid != 0
GROUP BY customerid,country
HAVING SUM(totalprice) >= 100000  -- high-value threshold
ORDER BY last_purchase;
---- High value customers by country for high targeted campaigns
select country, 
	customerid,
	sum(totalprice) as totalspend
FROM retaildata
WHERE customerid != 0
GROUP BY customerid,country
HAVING SUM(totalprice) >= 100000
ORDER BY totalspend
--- Find customers with high total spend but declining purchase frequency.
SELECT 
    customerid,
	SUM(totalprice) as totalspend,
    COUNT(DISTINCT invoiceno) AS purchase_count
FROM retaildata
WHERE customerid != 0
GROUP BY customerid
HAVING  COUNT(DISTINCT invoiceno)<=50 AND SUM(totalprice) >=100000
ORDER BY purchase_count DESC,totalspend asc
