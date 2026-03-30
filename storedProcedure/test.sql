-- test stored procedure instead of modifying insert data

use SCSCg1;
go

-- rollback changes
begin transaction;

-- chcek inventory
print '#### before ####'
select PID, WID, CID, SerialNo, rQty, timestamp
from INVENTORY
where PID = 1 and WID = 1 and CID = 1 and SerialNo = 101;

-- add 25 units to warehouse
print '#### executing ####'
exec usp_ReceiveInventory
    @PID = 1,
    @WID = 1,
    @CID = 1,
    @SerialNo = 101,
    @ReceivedQty = 25,
    @Reason = 'test';

-- check inventory shud be == 75
print '#### after ####';
select PID, WID, CID, SerialNo, rQty, timestamp
from INVENTORY
where PID = 1 and WID = 1 and CID = 1 and SerialNo = 101;

-- check movement log shud be == 'test'
select top 3 timestamp, Movement, Reasons
from INVENTORY_MOVEMENT
order by timestamp desc;

-- delete changes
print 'undoing changes';
rollback transaction;

-- verify rollback
print 'verifying rollback';
select PID, WID, CID, SerialNo, rQty, TIMESTAMP
from INVENTORY
where PID = 1 and WID = 1 and CID = 1 and SerialNo = 101;
go