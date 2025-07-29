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