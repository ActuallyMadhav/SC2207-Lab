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

