SET @endDay = date(now())-interval 1 day;

#Outstanding Normal
SELECT 
    NOW() - INTERVAL 1 HOUR AS 'Report Generated Time',
    #date(@endDay) as 'Outstanding as of',
    a.uuid AS 'Order ID Before Ext.',
    d.Funder AS 'Lender Name',
    '' AS 'Order ID After Ext.',
    'NORMAL' AS 'Order Type',
    IFNULL(c.NAME, b.realname) AS 'NAME',
    DATE(a.lendingTime) AS 'Disbursed Date',
    a.amountApply AS 'Apply Amount',
    coalesce(c.AMOUNT, a.amountApply - a.serviceFee) AS 'Actual Disbursed Amount',
    DATE(a.refundTime) AS 'Due Date',
    CASE
        WHEN DATEDIFF(a.refundTime, a.lendingTime) < 29 THEN a.amountApply + a.interest
        ELSE a.amountApply
    END AS 'Amount at Due Date'
FROM
    (select uuid, userUuid, amountApply, lendingTime, refundTime, orderType, interest, serviceFee from ordOrder
    where disabled = 0 and orderType in (0) and status in (7,8) and date(lendingTime) <= @endDay #between '2018-06-01' and @endDay
    union
    select uuid, userUuid, amountApply, lendingTime, refundTime, orderType, interest, serviceFee from ordOrder
    where disabled = 0 and orderType in (0) and status in (10,11) and date(actualRefundTime) > @endDay
    and date(lendingTime) <= @endDay #between '2018-06-01' and @endDay
    union
    select uuid, userUuid, amountApply, lendingTime, refundTime, orderType, interest, serviceFee from ordOrder
    where disabled = 0 and orderType in (2) and date(actualRefundTime) > @endDay
    and date(lendingTime) <= @endDay #between '2018-06-01' and @endDay
    ) AS a
        LEFT JOIN
    (select uuid, max(realName) as realName from usrUser group by uuid) AS b ON a.userUuid = b.uuid
        LEFT JOIN
		(select EXTERNAL_ID, max(ACCOUNT_HOLDER_NAME) as NAME, max(AMOUNT) as AMOUNT
        from T_DISBURSEMENT where DISBURSE_STATUS = 'COMPLETED' group by EXTERNAL_ID) as c
		on a.uuid = c.EXTERNAL_ID
        LEFT JOIN
	(select EXTERNAL_ID, MAX(UPDATE_TIME), MAX(FUNDER) as Funder from T_ORDER_EXT_INFO 
	where DISABLED = 0 group by EXTERNAL_ID) AS d ON a.uuid = d.EXTERNAL_ID
ORDER BY 'Disbursed Date' ASC;

#Outstanding Installment
Select
NOW() - INTERVAL 1 HOUR AS 'Report Generated Time',
#date(@endDay) as 'Outstanding as of',
e.uuid as 'Billing ID',
FUNDER as 'Lender Name',
a.uuid as 'Order ID',
'INSTALLMENT' as 'Order Type',
ifnull(c.NAME, b.realname) as 'NAME',
date(a.lendingTime) as 'Disbursed Date',
e.billAmout as 'Apply Amount',
c.AMOUNT/a.borrowingTerm as 'Actual Disbursed Amount',
date(e.refundTime) as 'Due Date',
e.billAmout as 'Amount at Due Date'
from
(select uuid, lendingTime, borrowingTerm, userUuid from ordOrder where disabled = 0
and orderType = 3 and status in (7,8,10,11) and date(lendingTime) <= @endDay) as a
	left join (select max(realName) as realName, uuid from usrUser) as b
	on a.userUuid = b.uuid
		inner join
        (select orderNo, a.uuid, a.refundTime, a.billAmout from ordBill as a
        inner join ordOrder as b
        on a.orderNo = b.uuid and b.disabled = 0 and a.disabled = 0 and a.status in (1,2)
        and coalesce(a.actualRefundTime, b.actualRefundTime) is null
        union
        select orderNo, a.uuid, a.refundTime, a.billAmout from ordBill as a
        inner join ordOrder as b
        on a.orderNo = b.uuid and b.disabled = 0 and a.disabled = 0
        and coalesce(a.actualRefundTime, b.actualRefundTime) is not null
        and date(coalesce(a.actualRefundTime, b.actualRefundTime)) > @endDay) as e
        on a.uuid = e.orderNo
            LEFT JOIN
			(select EXTERNAL_ID, max(ACCOUNT_HOLDER_NAME) as NAME, max(AMOUNT) as AMOUNT
			from T_DISBURSEMENT where DISBURSE_STATUS = 'COMPLETED' group by EXTERNAL_ID) as c
			on a.uuid = c.EXTERNAL_ID
                left join (select EXTERNAL_ID, max(UPDATE_TIME) as UPDATE_TIME, MAX(FUNDER) as FUNDER
                from T_ORDER_EXT_INFO where disabled = 0 group by EXTERNAL_ID) as f 
                on f.EXTERNAL_ID = a.uuid
order by 'Disbursed Date';

#Outstanding Extension
Select 
NOW() - INTERVAL 1 HOUR AS 'Report Generated Time',
#date(@endDay) as 'Outstanding as of',
f.uuid as 'Order ID After Ext.',
FUNDER as 'Lender Name',
a.uuid as 'Order ID Before Ext.',
'EXTENSION' as 'Order Type',
ifnull(c.NAME, b.realname) as 'NAME',
date(a.lendingTime) as 'Disbursed Date',
a.amountApply as 'Apply Amount',
c.AMOUNT as 'Actual Disbursed Amount',
date(f.refundTime) as 'Due Date',
f.amountApply as 'Amount at Due Date',
date(f.lendingTime) as 'Last Repayment Date',
coalesce(actualRepayAmout, DEPOSIT_AMOUNT) as 'Total Repayment Amount',
a.amountApply - f.amountApply as 'Total Principal Repaid',
coalesce(actualRepayAmout, DEPOSIT_AMOUNT) - (a.amountApply - f.amountApply) as 'Other Repaid Details',
#e.interest as interest,
#e.delayFee as delayFee,
#e.overDueFee as overdueFee,
#e.penaltyFee as penaltyFee,
#e.interest + e.delayFee + e.overDueFee + e.penaltyFee as 'Total penalty/interest/overduee Repaid',
f.amountApply as 'NPL write off',
f.amountApply as 'Delay Amount'
from (select uuid, userUuid, lendingTime, amountApply from ordOrder where orderType = 2) as a
	left join (select max(realName) as realName, uuid from usrUser group by uuid) as b
	on a.userUuid = b.uuid
		inner join (select orderNo, delayOrderNo from ordDelayRecord where delayOrderNo is not null) as e
        on e.orderNo = a.uuid
			inner join
            (select uuid, amountApply, refundTime, lendingTime from ordOrder
            where disabled = 0 and orderType = 1 and date(lendingTime) <= @endDay
            and status in (7,8) and actualRefundTime is null
            union
            select uuid, amountApply, refundTime, lendingTime from ordOrder
            where disabled = 0 and orderType = 1 and date(lendingTime) <= @endDay
            and status in (10,11) and date(actualRefundTime) > @endDay) as f
            on e.delayOrderNo = f.uuid
				left join
                (select MAX(DEPOSIT_AMOUNT) AS DEPOSIT_AMOUNT, EXTERNAL_ID from T_LPAY_DEPOSIT
                where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID) as g
                on a.uuid = g.EXTERNAL_ID
                left join
                (select max(actualRepayAmout) as actualRepayAmout, orderNo from ordUnderLinePayRecord
                where disabled = 0 group by orderNo) as i
                on a.uuid = i.orderNo
					LEFT JOIN
					(select EXTERNAL_ID, max(ACCOUNT_HOLDER_NAME) as NAME, max(AMOUNT) as AMOUNT
					from T_DISBURSEMENT where DISBURSE_STATUS = 'COMPLETED' group by EXTERNAL_ID) as c
					on a.uuid = c.EXTERNAL_ID
				left join (select EXTERNAL_ID, max(UPDATE_TIME) as UPDATE_TIME, MAX(FUNDER) as FUNDER
                from T_ORDER_EXT_INFO where disabled = 0 group by EXTERNAL_ID) as h
                on a.uuid = h.EXTERNAL_ID
order by 'Disbursed Date';