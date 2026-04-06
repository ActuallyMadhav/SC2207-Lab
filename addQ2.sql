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
    WHERE oc.OrderDate >= DATEADD(MONTH, -6, GETDATE())
      AND oc.OrderStatus != 'Cancelled' 
    GROUP BY oc.CID, oc.CompanyName, op.PID, op.ProductName
),
CurrentStock AS (
    SELECT
        CID,
        PID,
        SUM(sQty) AS AvailableForSale
    FROM INVENTORY
    GROUP BY CID, PID
)
SELECT
    ms.CID,
    ms.CompanyName,
    ms.PID,
    ms.ProductName
FROM MonthlySales ms
LEFT JOIN CurrentStock cs ON cs.CID = ms.CID AND cs.PID = ms.PID
WHERE ISNULL(cs.AvailableForSale, 0) < ms.AvgMonthlySales * 0.10
ORDER BY ms.CID, ms.PID;
GO