SELECT * FROM retaildata
--- Customer Segmentation analysis
----RECENCY
-- 1.Which customers made purchases most recently between December 2010 and December 2011?
WITH MaxDateCTE AS (
    SELECT MAX(InvoiceDate) AS MaxInvoiceDate
    FROM retaildata
    )
SELECT 
    CustomerID,
	COUNT(*),
    InvoiceDate AS LastPurchaseDate
FROM 
    retaildata, MaxDateCTE
WHERE 
    InvoiceDate = MaxDateCTE.MaxInvoiceDate
    AND CustomerID !=0 
GROUP BY customerid,invoicedate;
-- 2. Are there customers who haven’t purchased since early 2011 and might need re-engagement?
WITH last_purchase AS (
    SELECT 
        customerid,
        MAX(invoicedate) AS last_purchasedate
    FROM retaildata
    WHERE customerid !=0
    GROUP BY customerid
)
SELECT 
    customerid,
    last_purchasedate
FROM last_purchase
WHERE last_purchasedate BETWEEN '2010-12-01' AND '2011-03-31'
ORDER BY last_purchasedate;
-- Frequency:
-- 3. Which customers made the most purchases during the year 2011?
SELECT 
    customerid,
    SUM(totalprice) AS total_purchases
FROM retaildata
WHERE invoicedate >= '2011-01-01'
  AND invoicedate <= '2011-12-31'
  AND customerid != 0
GROUP BY customerid
ORDER BY total_purchases DESC
LIMIT 10;
-- 4. Are there customers who only bought once during this period (one-time buyers)?
SELECT 
    customerid,
    COUNT(*) AS total_orders
FROM retaildata
WHERE customerid != 0
GROUP BY customerid
HAVING COUNT(*) = 1
ORDER BY total_orders DESC;
---Monetary
--5. Who are the highest spending customers between Dec 2010 and Dec 2011?
SELECT 
    customerid,
    SUM(totalprice) AS total_purchases
FROM retaildata
WHERE customerid != 0
GROUP BY customerid
ORDER BY total_purchases DESC
LIMIT 1;
-- 6 Total money spent overall 
SELECT 
    SUM(totalprice) AS total_revenue
FROM retaildata
WHERE customerid != 0 
ORDER BY total_revenue DESC;
-- 7. How does spending vary by customer segment or country in this timeframe?
SELECT
   DISTINCT country,
    SUM(totalprice) AS total_revenue,
    RANK() OVER (ORDER BY SUM(totalprice) DESC) AS country_ranking
FROM retaildata
WHERE customerid != 0
GROUP BY country
ORDER BY country_ranking;
---Country based segmentation
---8 How does customer purchase behavior (RFM) differ by country between Dec 2010 and Dec 2011on AVERAGE?
WITH customer_rfm AS (
    SELECT
        customerid,
        country,
        DATE '2011-12-31' - MAX(invoicedate)::date AS recency_days,
        COUNT(DISTINCT invoiceno) AS frequency,
        SUM(totalprice) AS monetary_value
    FROM retaildata
    WHERE customerid != 0
      AND invoicedate BETWEEN '2010-12-01' AND '2011-12-31'
    GROUP BY customerid, country
)
SELECT
    country,
    ROUND(AVG(recency_days),0) AS total_recency,
    ROUND(AVG(frequency),0) AS total_frequency,
    ROUND(AVG(monetary_value),0) AS total_monetary,
    RANK() OVER (
        ORDER BY AVG(monetary_value) DESC
    ) AS country_ranking
FROM customer_rfm
GROUP BY country
ORDER BY country_ranking;
--- 9. Top customers per country:RANK() OVER (PARTITION BY country ORDER BY monetary_value DESC).
WITH customer_spending AS (
    SELECT 
        customerid,
        country,
        SUM(totalprice) AS monetary_value
    FROM retaildata
    WHERE customerid IS NOT NULL
    GROUP BY customerid, country
),
ranked_customers AS (
    SELECT 
        customerid,
        country,
        monetary_value,
        RANK() OVER (PARTITION BY country ORDER BY monetary_value DESC) AS customer_rank
    FROM customer_spending
)
SELECT 
    customerid,
    country,
    monetary_value
FROM ranked_customers
WHERE customer_rank = 1
ORDER BY country;

SELECT COUNT(DISTINCT customerid) FROM retaildata
WHERE invoicedate BETWEEN '2011-01-01' AND '2011-12-31'

SELECT COUNT(DISTINCT customerid) FROM retaildata
WHERE invoicedate BETWEEN '2010-12-01' AND '2010-12-31'