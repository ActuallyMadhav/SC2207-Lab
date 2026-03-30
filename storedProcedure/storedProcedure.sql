-- log inventory mvoement and update qty so data is not corrupted

use SCSCg1
go

create procedure usp_ReceiveInventory
    @PID int,
    @WID int,
    @CID int,
    @SerialNo int,
    @ReceivedQty int,
    @Reason nvarchar(100)
as
begin
    set nocount on;

    begin try
        begin transaction;

        declare @CurrentTime datetime = getdate();

        -- log movement
        insert into INVENTORY_MOVEMENT (timestamp, Movement, Reasons)
        values (@CurrentTime, 'In',@Reason);

        -- update/insert inverntory qty
        if exists (select 1 from INVENTORY where PID = @PID and WID = @WID and CID = @CID and SerialNo = @SerialNo)
        begin
            update INVENTORY
            set rQty = rQty + @ReceivedQty,
                timestamp = @CurrentTime
            where PID = @PID and WID = @WID and CID = @CID and SerialNo = @SerialNo;
        end
        else
        begin
            insert into INVENTORY(PID, WID, CID, SerialNo, rQty, hQty, sQty, oQty, timestamp)
            values (@PID, @WID, @CID, @SerialNo, @ReceivedQty, 0, 0, 0, @CurrentTime);
        end

        commit transaction;
    end try
    begin catch
        if @TRANCOUNT > 0
            rollback transaction;
        throw;
    end catch
end;
go