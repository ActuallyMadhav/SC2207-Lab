use SCSCg1;
go

-- Q8. find drivers licenses expiring in the next 2 month - works corectly
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

-- Q9. number of orders still pending - works correctly
select
    OID as OrderID,
    OrderDate,
    Status,
    Value as OrderTotal
from PURCHASE_ORDER
where Status = 'Pending'  -- change status between 'Pending', 'Processing', 'Shipped', 'Delivered'
order by OrderDate asc;
go

-- Q10. number and total value orders still pending or processing - works correctly
select 
    Status,
    count(OID) as numOrders,
    sum(value) as tiedUpRev
from PURCHASE_ORDER
where Status in ('Pending', 'Processing')
group by Status
order by tiedUpRev desc;
go

-- Q11. top 2 most expensive products per category - works correctly
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

-- Q12. client tier comparison - works correctly
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

-- Q13. which clients only order 'x' category
select c.CID, c.CompanyName
from CLIENT c
where 
    -- must have ordered at least one 'x' item
    exists(
        select 1
        from CLIENT_PURCHASE_ORDER cpo
        join ORDER_ITEM oi on cpo.OID = oi.OID
        join ITEM i on oi.ItemSerialNo = i.ItemSerialNo
        join product p on i.PID = p.PID
        where cpo.CID = c.CID and p.Category = 'Electronics' -- change according to which cat u want
    )
    
    -- must not have ordered a non 'x' item
    and not exists(
        select 1
        from CLIENT_PURCHASE_ORDER cpo
        join ORDER_ITEM oi on cpo.OID = oi.OID
        join item i on oi.ItemSerialNo = i.ItemSerialNo
        join product p on i.PID = p.PID
        where cpo.CID = c.CID and p.Category != 'Electronics' -- change according to which cat u want
    );
go

