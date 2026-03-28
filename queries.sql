USE SCSCg1
GO

-- ============================================================
-- Q1. For each warehouse, find its top three clients
--
-- Business value per client per warehouse is measured by the total PURCHASE_ORDER.
-- Value of orders that were:
--     - linked to the client via CLIENT_PURCHASE_ORDER
--     - shipped to that warehouse via SHIPMENT → SHIPMENT_TO_WAREHOUSE
--   DENSE_RANK is used so tied clients both appear if they share rank 1/2/3.
-- ============================================================

WITH ClientWarehouseBusiness AS (
    SELECT stw.WID, cpo.CID, SUM(po.Value) AS TotalBusiness
    FROM PURCHASE_ORDER po
    JOIN CLIENT_PURCHASE_ORDER cpo ON cpo.OID = po.OID
    JOIN SHIPMENT s  ON s.OID = po.OID
    JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID = s.ShipmentID
    GROUP BY stw.WID, cpo.CID
), 
RankedClients AS (
    SELECT cwb.WID, w.Address AS WarehouseAddress, cwb.CID, c.CompanyName, cwb.TotalBusiness, 
    DENSE_RANK() OVER (PARTITION BY cwb.WID ORDER BY cwb.TotalBusiness DESC) AS Rank
    FROM ClientWarehouseBusiness cwb
    JOIN WAREHOUSE w ON w.WID = cwb.WID
    JOIN CLIENT c ON c.CID = cwb.CID
)
SELECT
    WID, WarehouseAddress, CID, CompanyName, TotalBusiness, Rank AS ClientRank
FROM RankedClients
WHERE Rank <= 3
ORDER BY WID, Rank;
GO

-- ============================================================
-- Q2. Do warehouses in Singapore have more business than warehouses in Los Angeles?
--
--   Total business per region is summed from PURCHASE_ORDER.
-- ============================================================

WITH WarehouseBusiness AS (
    SELECT w.WID, w.Address, po.Value,
        CASE
            WHEN w.Address LIKE '%Singapore%'     THEN 'Singapore'
            WHEN w.Address LIKE '%Los Angeles%'   THEN 'Los Angeles'
            ELSE 'Other'
        END AS Region
    FROM PURCHASE_ORDER po
    JOIN SHIPMENT s  ON s.OID = po.OID
    JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID = s.ShipmentID
    JOIN WAREHOUSE w  ON w.WID = stw.WID
)
SELECT
    Region,
    SUM(Value) AS TotalBusinessValue
FROM WarehouseBusiness
WHERE Region IN ('Singapore', 'Los Angeles')
GROUP BY Region
ORDER BY TotalBusinessValue DESC;
GO

-- ============================================================
-- Q3. Top three months (by name) in a year for the last two
--     years that have the most purchase orders created.
-- ============================================================

WITH OrdersByMonth AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        DATENAME(MONTH, OrderDate) AS MonthName,
        COUNT(*) AS OrderCount
    FROM PURCHASE_ORDER
    WHERE YEAR(OrderDate) IN (YEAR(GETDATE()) - 1, YEAR(GETDATE()) - 2)
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate),
        DATENAME(MONTH, OrderDate)
)
SELECT TOP 3
    OrderYear, MonthName, OrderCount
FROM OrdersByMonth
ORDER BY OrderCount DESC, OrderYear DESC, OrderMonth;
GO




-- ============================================================
-- Q4. Average length of time (in months) from order creation until products are delivered to warehouses.
-- ============================================================

SELECT
    p.PID, p.Name AS ProductName,
    ROUND(AVG(CAST(DATEDIFF(DAY, po.OrderDate, sh.AcArrDate) AS FLOAT) / 30.44), 2) AS AvgMonthsToDeliver
FROM PRODUCT p
JOIN ITEM i ON i.PID = p.PID
JOIN ORDER_ITEM oi ON oi.ItemSerialNo = i.ItemSerialNo
JOIN PURCHASE_ORDER po ON po.OID = oi.OID
JOIN SHIPMENT sh ON sh.OID = po.OID
JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID = sh.ShipmentID
WHERE sh.AcArrDate IS NOT NULL
GROUP BY p.PID, p.Name
ORDER BY p.PID;
GO

-- ============================================================
-- Q5. Suppliers that ONLY supply products to warehouses located in Singapore.
--
--   Supply chain: SUPPLIER_PURCHASE_ORDER → PURCHASE_ORDER
--   → SHIPMENT → SHIPMENT_TO_WAREHOUSE → WAREHOUSE
-- ============================================================

SELECT s.SupplierID, s.Name, s.Country
FROM SUPPLIER s
WHERE
    -- Has supplied to at least one Singapore warehouse
    EXISTS (
        SELECT 1
        FROM SUPPLIER_PURCHASE_ORDER spo
        JOIN PURCHASE_ORDER po  ON po.OID = spo.OID
        JOIN SHIPMENT sh ON sh.OID = po.OID
        JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID  = sh.ShipmentID
        JOIN WAREHOUSE w  ON w.WID = stw.WID
        WHERE spo.SupplierID = s.SupplierID
          AND w.Address LIKE '%Singapore%'
    )
    AND
    -- Has NOT supplied to any non-Singapore warehouse
    NOT EXISTS (
        SELECT 1
        FROM SUPPLIER_PURCHASE_ORDER spo
        JOIN PURCHASE_ORDER po  ON po.OID = spo.OID
        JOIN SHIPMENT sh ON sh.OID = po.OID
        JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID = sh.ShipmentID
        JOIN WAREHOUSE w  ON w.WID = stw.WID
        WHERE spo.SupplierID = s.SupplierID
          AND w.Address NOT LIKE '%Singapore%'
    );
GO


-- ============================================================
-- Q6. Suppliers who do NOT supply any product to warehouses in Thailand 
-- BUT have supplied ALL products currently held in warehouses in Singapore.
--
--   1. Find DISTINCT products stocked in singapore
--   2. Find products supplied by each supplier
-- ============================================================

-- distinct products stocked in Singapore warehouses
WITH SingaporeProducts AS (
    SELECT DISTINCT i.PID
    FROM INVENTORY  i
    JOIN WAREHOUSE w ON w.WID = i.WID
    WHERE w.Address LIKE '%Singapore%'
),
-- Products each supplier has delivered to any warehouse
SupplierProducts AS (
    SELECT DISTINCT spo.SupplierID, it.PID
    FROM SUPPLIER_PURCHASE_ORDER spo
    JOIN PURCHASE_ORDER po  ON po.OID = spo.OID
    JOIN ORDER_ITEM oi  ON oi.OID = po.OID
    JOIN ITEM it  ON it.ItemSerialNo = oi.ItemSerialNo
)
SELECT s.SupplierID, s.Name AS SupplierName FROM SUPPLIER s
WHERE
    -- Condition A: no supply to Thailand warehouses
    NOT EXISTS (
        SELECT 1
        FROM SUPPLIER_PURCHASE_ORDER spo
        JOIN PURCHASE_ORDER po  ON po.OID = spo.OID
        JOIN SHIPMENT sh ON sh.OID = po.OID
        JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID = sh.ShipmentID
        JOIN WAREHOUSE w  ON w.WID = stw.WID
        WHERE spo.SupplierID = s.SupplierID AND w.Address LIKE '%Thailand%'
    )
    AND (
    -- Condition B: covers every product in Singapore warehouse inventory
        SELECT COUNT(DISTINCT sp.PID) FROM SingaporeProducts sp
        WHERE EXISTS (
            SELECT 1
            FROM SupplierProducts sup
            WHERE sup.SupplierID = s.SupplierID AND sup.PID = sp.PID
        )
    ) = (SELECT COUNT(*) FROM SingaporeProducts);
GO


-- ============================================================
-- Q7. Departure locations that have experienced the most delays
--     (actual arrival date > 6 months after expected arrival date).
-- ============================================================

SELECT
    sh.OriginalLocation, COUNT(*)  AS DelayCount
FROM SHIPMENT sh
WHERE sh.AcArrDate IS NOT NULL
  AND sh.ExArrDate IS NOT NULL
  AND DATEDIFF(MONTH, sh.ExArrDate, sh.AcArrDate) > 6
GROUP BY sh.OriginalLocation
ORDER BY DelayCount DESC;
GO

