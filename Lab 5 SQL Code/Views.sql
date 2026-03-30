USE SCSCg1;
GO

-- View 1: Links Purchase Orders to the Warehouses they were shipped to
CREATE VIEW vw_OrderWarehouse AS
SELECT
    po.OID, po.OrderDate, po.Status AS OrderStatus, po.Value,
    s.ShipmentID, s.OriginalLocation, s.TrackingNumber,
    s.ShippedDate, s.ExArrDate, s.AcArrDate,
    w.WID, w.Address AS WarehouseAddress, w.Size AS WarehouseSize,
    w.Temperature, w.Security
FROM PURCHASE_ORDER po
JOIN SHIPMENT s ON s.OID = po.OID
JOIN SHIPMENT_TO_WAREHOUSE stw ON stw.ShipmentID = s.ShipmentID
JOIN WAREHOUSE w ON w.WID = stw.WID;
GO

-- View 2: Links Purchase Orders to the Clients who placed them
CREATE VIEW vw_OrderClient AS
SELECT
    po.OID, po.OrderDate, po.Status AS OrderStatus, po.Value,
    c.CID, c.CompanyName, c.ContactPerson, c.StartDate, c.ServiceTier
FROM PURCHASE_ORDER po
JOIN CLIENT_PURCHASE_ORDER cpo ON cpo.OID = po.OID
JOIN CLIENT c ON c.CID = cpo.CID;
GO

-- View 3: Links Purchase Orders to the Suppliers who fulfilled them
CREATE VIEW vw_OrderSupplier AS
SELECT
    po.OID, po.OrderDate, po.Status AS OrderStatus, po.Value,
    s.SupplierID, s.Name AS SupplierName, s.Country, s.PaymentTerms, s.LeadTime
FROM PURCHASE_ORDER po
JOIN SUPPLIER_PURCHASE_ORDER spo ON spo.OID = po.OID
JOIN SUPPLIER s ON s.SupplierID = spo.SupplierID;
GO

-- View 4: Links Purchase Orders to the Products ordered
CREATE VIEW vw_OrderProduct AS
SELECT
    po.OID, po.OrderDate, po.Status AS OrderStatus, po.Value,
    oi.OrderedQty, oi.UnitPrice, oi.ExDelDate,
    p.PID, p.Name AS ProductName, p.Brand, p.Cost, p.Price,
    p.Category, p.HandlingRequirements
FROM PURCHASE_ORDER po
JOIN ORDER_ITEM oi ON oi.OID = po.OID
JOIN ITEM i ON i.ItemSerialNo = oi.ItemSerialNo
JOIN PRODUCT p ON p.PID = i.PID;
GO

