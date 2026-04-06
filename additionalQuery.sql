USE SCSCg1;
GO

-- Additional Query: For each client, identify products that are currently
-- available for sale in quantities less than 10% of their average monthly
-- sales over the last six months.

-- Uses views: vw_OrderClient and vw_OrderProduct

WITH MonthlySales AS (
    SELECT
        oc.CID,
        oc.CompanyName,
        op.PID,
        op.ProductName,
        SUM(op.OrderedQty) * 1.0 / 6 AS AvgMonthlySales
    FROM vw_OrderClient oc
    JOIN vw_OrderProduct op ON oc.OID = op.OID
    WHERE oc.OrderDate >= DATEADD(MONTH, -6, (SELECT MAX(OrderDate) FROM PURCHASE_ORDER))
      AND oc.OrderStatus != 'Cancelled'
    GROUP BY oc.CID, oc.CompanyName, op.PID, op.ProductName
),
CurrentStock AS (
    SELECT
        PID,
        SUM(sQty) AS AvailableForSale
    FROM INVENTORY
    GROUP BY PID
)
SELECT
    ms.CID,
    ms.CompanyName,
    ms.PID,
    ms.ProductName,
    ISNULL(cs.AvailableForSale, 0) AS AvailableForSale,
    ROUND(ms.AvgMonthlySales, 2) AS AvgMonthlySales,
    ROUND(ms.AvgMonthlySales * 0.10, 2) AS Threshold
FROM MonthlySales ms
LEFT JOIN CurrentStock cs ON cs.PID = ms.PID
WHERE ISNULL(cs.AvailableForSale, 0) < ms.AvgMonthlySales * 0.10
ORDER BY ms.CID, ms.PID;
GO
