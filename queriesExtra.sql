use SCSCg1;
go

-- find drivers licenses expiring in the next 2 month - works corectly
select
    s.Name as driverName,
    d.LicenseNumber,
    l.LicenseExpiration,
    datediff(day, getdate(), l.LicenseExpiration) as daysValid
from DRIVER d
join STAFF s on d.StaffID = s.StaffID
join LICENSE_INFO l on d.LicenseNumber = l.LicenseNumber
where l.LicenseExpiration between getdate() and dateadd(day, 60, getdate())
order by l.LicenseExpiration asc;
go

-- number of orders still pending - works correctly
select
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderTotal
from PURCHASE_ORDER
where Status = 'Pending'
order by OrderDate asc;
go

-- number of orders still processing - works correctly
select 
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderVal
from PURCHASE_ORDER
where status = 'Processing'
order by OrderDate asc;
go

-- orders that are shipped - works correctly
select 
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderVal
from PURCHASE_ORDER
where status = 'Shipped'
order by OrderDate asc;
go

-- orders that are delivered - wokrs correctly
select 
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderVal
from PURCHASE_ORDER
where status = 'Delivered'
order by OrderDate asc;
go

-- number and total value orders still pending or processing - works correctly
select 
    Status,
    count(OID) as numOrders,
    sum(value) as tiedUpRev
from PURCHASE_ORDER
where Status in ('Pending', 'Processing')
group by Status
order by tiedUpRev desc;
go

-- top 2 most expensive products per category - works correctly
with Ranked as(
    select 
        Category,
        Name as ProductName,
        Brand,
        Price,
        dense_rank() over (partition by category order by price desc) as priceRank
    from PRODUCT
)
select 
    Category,
    ProductName,
    Brand,
    Price,    
    priceRank
from Ranked
where priceRank <= 2
order by Category, priceRank;
go 

-- client tier comparison - works correctly
go
select 
    c.ServiceTier,
    avg(po.Value) as avgOrderVal,
    count(po.OID) as totalOrders
from CLIENT c
join CLIENT_PURCHASE_ORDER cpo on c.CID = cpo.CID
join PURCHASE_ORDER po on cpo.OID = po.OID
where c.ServiceTier in ('Gold', 'Silver') -- change str acc to what u want to compare
group by c.ServiceTier
order by avgOrderVal desc;
go