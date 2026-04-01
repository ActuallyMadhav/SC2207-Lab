use SCSCg1;
go

-- find drivers licenses expiring in the next 2 month
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

-- number of orders still pending
select
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderTotal
from PURCHASE_ORDER
where Status = 'Pending'
order by OrderDate asc;
go

-- number of orders still processing
select 
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderVal
from PURCHASE_ORDER
where status = 'Processing'
order by OrderDate asc;
go

-- orders that are shipped
select 
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderVal
from PURCHASE_ORDER
where status = 'Shipped'
order by OrderDate asc;
go

-- orders that are delivered
select 
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderVal
from PURCHASE_ORDER
where status = 'Delivered'
order by OrderDate asc;
go

-- number and total value orders still pending or processing
select 
    Status,
    count(OID) as numOrders,
    sum(value) as tiedUpRev
from PURCHASE_ORDER
where Status in ('Pending', 'Processing')
group by Status
order by tiedUpRev desc;
go

-- top 2 most expensive products per category
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

