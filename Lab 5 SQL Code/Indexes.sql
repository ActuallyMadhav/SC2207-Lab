USE SCSCg1;
GO

-- Speeds up Q1, Q2, Q5, Q6, Q7 which filter warehouses by location
CREATE INDEX idx_warehouse_address ON WAREHOUSE(Address);
GO

-- Speeds up Q3 (top months by year) and Q4 (date diff calculation)
CREATE INDEX idx_po_orderdate ON PURCHASE_ORDER(OrderDate);
GO

-- Speeds up Q4 (avg delivery time) and Q7 (delay detection)
CREATE INDEX idx_shipment_acarrdate ON SHIPMENT(AcArrDate);
GO

-- Speeds up Q7 (grouping by departure location)
CREATE INDEX idx_shipment_originallocation ON SHIPMENT(OriginalLocation);
GO
