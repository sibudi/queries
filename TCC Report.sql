#1-Disbursement-Normal
select 
orderId,
orderType,
'' as parentId,
userId,
sex,
age,
province,
positionName,
borrowUse,
applyComDay,
ordApplyAmount,
ordLendAmount,
ordLendDay,
ordDueDay,
ordDueAmount,
if(status in (7,8),null,ordRepayDay) as ordRepayDay,
if(status in (7,8),null,repay) as ordRepayAmout,
money as coupon,
if(funder.EXTERNAL_ID is null,'SL',FUNDER) as FUNDER
from 
(
select
uuid as orderId,
useruuid as userId,
'Normal' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
date(refundTime) as ordDueDay,
amountApply + interest as ordDueAmount,
interest,
date(actualRefundTime) as ordRepayDay,
status
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (0,2)
and date(lendingTime) between '2019-04-08' and '2019-05-31'
) ord
left join 
(
select 
uuid,
realName,
if(sex = 1,'Male','Female') as sex,
age
from usrUser
#where disabled = 0
) usr on usr.uuid = ord.userId
left join 
(
select userUuid,max(province) as province
from usrAddressDetail
where addressType = 0
group by userUuid
) address on address.userUuid = ord.userId
left join 
(
select  
useruuid,
max(borrowUse) as borrowUse,
max(positionName) as positionName
from 
(
select 
useruuid,
max(borrowUse) as borrowUse,
max(positionName) as positionName
from usrWorkDetail
#where disabled = 0
group by useruuid

union
select 
useruuid,
max(borrowUse) as borrowUse,
'student' as positionName
from usrStudentDetail
#where disabled = 0
group by useruuid

union
select 
useruuid,
max(borrowUse) as borrowUse,
'HouseWife' as positionName
from usrHouseWifeDetail
#where disabled = 0
group by useruuid
) role
group by useruuid
) mydata on mydata.useruuid = ord.userId
	left join
(select EXTERNAL_ID, sum(repay) as repay
from
	(select EXTERNAL_ID, max(AMOUNT) as repay from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
	union
	select EXTERNAL_ID, max(DEPOSIT_AMOUNT) as repay from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
	union
	select orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordUnderLinePayRecord where disabled = 0 group by orderNo
	) as compile
group by EXTERNAL_ID
) as repay
on repay.EXTERNAL_ID = ord.orderId
left join   
(
select
date(max(createtime)) as applyComDay,
orderId as orderNo
from ordHistory
where disabled = 0 and status = 5
group by orderNo
) history on history.orderNo = ord.orderId
left join 
(
select
EXTERNAL_ID,
ACCOUNT_HOLDER_NAME,
DISBURSE_STATUS,
DISBURSE_CHANNEL,
date(CREATE_TIME) as CREATE_TIME,
DISBURSEMENT_ID,
AMOUNT as ordLendAmount,
TRANSACTION_STATUS
from T_DISBURSEMENT
where DISBURSE_STATUS = 'COMPLETED'
and TRANSACTION_STATUS = 'ACTIVE'
and DISBURSE_TYPE not in ('PRE_SERVICE_FEE')
) td on td.EXTERNAL_ID = ord.orderId
left join
(select distinct orderNo, money from couponRecord where disabled = 0 and status = 1) as coupon
on coupon.orderNo = ord.orderId
left join
(select distinct EXTERNAL_ID, FUNDER from T_ORDER_EXT_INFO where FUNDER = 'TCC' and DISABLED = 0) as funder
on funder.EXTERNAL_ID = ord.orderId 
order by ordLendDay;




#2-Disbursement-aftExtension
select 
orderId,
orderType,
preOrderNo,
userId,
sex,
age,
province,
positionName,
borrowUse,
'' as applyComDay,
ordApplyAmount,
0 as ordLendAmount,
ordLendDay,
ordDueDay,
ordDueAmount,
if(status in (7,8),null,ordRepayDay) as ordRepayDay,
if(status in (7,8),null,repay) as ordRepayAmout,
money as coupon,
if(funder.EXTERNAL_ID is null,'SL',FUNDER) as FUNDER
from 
(
select
uuid as orderId,
useruuid as userId,
'aftExtension' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
date(refundTime) as ordDueDay,
amountApply + interest as ordDueAmount,
interest,
date(actualRefundTime) as ordRepayDay,
status
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (1)
and date(lendingTime) between '2019-04-08' and '2020-01-05'
) ord
inner join 
(
select orderNo as preOrderNo,delayOrderNo,repayNum,delayFee
from ordDelayRecord
where disabled = 0 and type = 2
) odr on odr.delayOrderNo = ord.orderId
inner join
(select uuid as preOrderId from ordOrder where disabled = 0 and orderType = 2 and date(lendingTime) between '2019-04-08' and '2020-01-05') as o
on o.preOrderId = odr.preOrderNo
left join 
(
select 
uuid,
realName,
if(sex = 1,'Male','Female') as sex,
age
from usrUser
#where disabled = 0
) usr on usr.uuid = ord.userId
left join 
(
select userUuid,max(province) as province
from usrAddressDetail
where addressType = 0
group by userUuid
) address on address.userUuid = ord.userId
left join 
(
select  
useruuid,
max(borrowUse) as borrowUse,
max(positionName) as positionName
from 
(
select 
useruuid,
max(borrowUse) as borrowUse,
max(positionName) as positionName
from usrWorkDetail
#where disabled = 0
group by useruuid

union
select 
useruuid,
max(borrowUse) as borrowUse,
'student' as positionName
from usrStudentDetail
#where disabled = 0
group by useruuid

union
select 
useruuid,
max(borrowUse) as borrowUse,
'HouseWife' as positionName
from usrHouseWifeDetail
#where disabled = 0
group by useruuid
) role
group by useruuid
) mydata on mydata.useruuid = ord.userId
left join 
(
select
EXTERNAL_ID,
ACCOUNT_HOLDER_NAME,
DISBURSE_STATUS,
DISBURSE_CHANNEL,
date(CREATE_TIME) as CREATE_TIME,
DISBURSEMENT_ID,
AMOUNT as ordLendAmount,
TRANSACTION_STATUS
from T_DISBURSEMENT
where DISBURSE_STATUS = 'COMPLETED'
and TRANSACTION_STATUS = 'ACTIVE'
and DISBURSE_TYPE not in ('PRE_SERVICE_FEE')
) td on td.EXTERNAL_ID = odr.preOrderNo
	left join
(select EXTERNAL_ID, sum(repay) as repay
from
	(select EXTERNAL_ID, max(AMOUNT) as repay from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
	union
	select EXTERNAL_ID, max(DEPOSIT_AMOUNT) as repay from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
	union
	select orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordUnderLinePayRecord where disabled = 0 group by orderNo
	) as compile
group by EXTERNAL_ID
) as repay
on repay.EXTERNAL_ID = ord.orderId
	left join
(select distinct orderNo, money from couponRecord where disabled = 0 and status = 1) as coupon
on coupon.orderNo = ord.orderId
	left join
(select distinct EXTERNAL_ID, FUNDER from T_ORDER_EXT_INFO where FUNDER = 'TCC' and DISABLED = 0) as funder
on funder.EXTERNAL_ID = odr.preOrderNo
order by ordLendDay;




#3-Disbursement-Installment
select 
billId,
orderType,
preOrderId,
userId,
sex,
age,
province,
positionName,
borrowUse,
applyComDay,
billDueAmount as billApplyAmount,
AMOUNT/3 as billLendAmount,
ordLendDay,
billDueDay,
billDueAmount,
billRepayDay as ordRepayDay,
repay as ordRepayAmout,
money as coupon,
if(funder.EXTERNAL_ID is null,'SL',FUNDER) as FUNDER
from 
(
select
uuid as orderId,
useruuid as userId,
'Installment' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
serviceFee/amountApply as serviceRate,
date(refundTime) as ordDueDay,
amountApply + interest as ordDueAmount,
interest,
date(actualRefundTime) as ordRepayDay
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (3)
and date(lendingTime) between '2019-04-08' and '2020-01-05'
) ord
inner join
(select orderNo as preOrderId, a.uuid as billId, a.uuid as payId, billTerm,
date(coalesce(a.actualRefundTime,b.actualRefundTime)) as billRepayDay, billAmout as billDueAmount, date(a.refundTime) as billDueDay
from ordBill as a
	inner join ordOrder as b
    on a.orderNo = b.uuid
    and a.disabled = 0 and b.disabled = 0 and a.status in (3,4)
union all
select orderNo as preOrderId, a.uuid as billId, orderNo as payId, billTerm,
date(b.actualRefundTime) as billRepayDay, billAmout as billDueAmount, date(a.refundTime) as billDueDay
from ordBill as a
	inner join ordOrder as b
    on a.orderNo = b.uuid
    and a.disabled = 0 and b.disabled = 0 and a.status in (1,2)
) bill on bill.preOrderId = ord.orderId
left join 
(
select 
uuid,
realName,
if(sex = 1,'Male','Female') as sex,
age
from usrUser
#where disabled = 0
) usr on usr.uuid = ord.userId
left join 
(
select userUuid,max(province) as province
from usrAddressDetail
where addressType = 0
group by userUuid
) address on address.userUuid = ord.userId
left join 
(
select  
useruuid,
max(borrowUse) as borrowUse,
max(positionName) as positionName
from 
(
select 
useruuid,
max(borrowUse) as borrowUse,
max(positionName) as positionName
from usrWorkDetail
#where disabled = 0
group by useruuid

union
select 
useruuid,
max(borrowUse) as borrowUse,
'student' as positionName
from usrStudentDetail
#where disabled = 0
group by useruuid

union
select 
useruuid,
max(borrowUse) as borrowUse,
'HouseWife' as positionName
from usrHouseWifeDetail
#where disabled = 0
group by useruuid
) role
group by useruuid
) mydata on mydata.useruuid = ord.userId
left join   
(
select
date(max(createtime)) as applyComDay,
orderId as orderNo
from ordHistory
where disabled = 0 and status = 5
group by orderNo
) history on history.orderNo = ord.orderId
left join
(select distinct orderNo, money from couponRecord where disabled = 0 and status = 1) as coupon
on coupon.orderNo = bill.billId
left join
(select distinct EXTERNAL_ID, FUNDER from T_ORDER_EXT_INFO where DISABLED = 0 and FUNDER = 'TCC') as funder
on funder.EXTERNAL_ID = ord.orderId
left join
(select distinct EXTERNAL_ID, AMOUNT from T_DISBURSEMENT where DISBURSE_STATUS = 'COMPLETED'
and TRANSACTION_STATUS = 'ACTIVE' and DISBURSE_TYPE not in ('PRE_SERVICE_FEE')) as disburse
on disburse.EXTERNAL_ID = ord.orderId
left join 
(select EXTERNAL_ID, sum(repay) as repay
from
(select EXTERNAL_ID, max(AMOUNT) as repay from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select EXTERNAL_ID, max(DEPOSIT_AMOUNT) as repay from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordUnderLinePayRecord where disabled = 0 group by orderNo
union
select a.orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordRepayAmoutRecord as a
inner join ordBill as b
on a.orderNo = b.uuid and a.disabled = 0 and b.disabled = 0 and b.billTerm in (1,2) and b.status in (3,4)
and a.repayMethod = 'MANUAL' group by a.orderNo
) as compile
group by EXTERNAL_ID
) as repay
on repay.EXTERNAL_ID = bill.payId
order by ordLendDay;







#4-Repay-Normal
SET @startDay = '2019-04-08';
SET @endDay = '2019-12-15';

select 
orderId,
ordRepayDay,
repay
from 
(
select
uuid as orderId,
useruuid as userId,
'Normal' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
date(refundTime) as ordDueDay,
amountApply + interest as ordDueAmount,
interest,
date(actualRefundTime) as ordRepayDay,
status
from ordOrder
where disabled = 0
and status in (10,11)
and ordertype in (0,2)
and date(actualRefundTime) <= @endDay
and date(lendingTime) between @startDay and @endDay
) ord
left join
(select EXTERNAL_ID, sum(repay) as repay
from
(select EXTERNAL_ID, max(AMOUNT) as repay from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select EXTERNAL_ID, max(DEPOSIT_AMOUNT) as repay from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordUnderLinePayRecord where disabled = 0 group by orderNo
) as compile
group by EXTERNAL_ID
) as repay
on repay.EXTERNAL_ID = ord.orderId
order by ordRepayDay;



#5-Repay-aftExtension
select 
orderId,
ordRepayDay,
repay
from 
(
select
uuid as orderId,
useruuid as userId,
'aftExtension' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
date(refundTime) as ordDueDay,
amountApply + interest as ordDueAmount,
interest,
date(actualRefundTime) as ordRepayDay,
status
from ordOrder
where disabled = 0
and status in (10,11)
and ordertype in (1)
and date(actualRefundTime) <= @endDay
and date(lendingTime) between @startDay and @endDay
) ord
inner join 
(select orderNo as preOrderNo, delayOrderNo, repayNum, delayFee
from ordDelayRecord
where disabled = 0 and type = 2 and delayOrderNo is not null
) odr on odr.delayOrderNo = ord.orderId
inner join 
(select uuid as preOrderId
from ordOrder
where disabled = 0
and date(lendingTime) between @startDay and @endDay
) pre on pre.preOrderId = odr.preOrderNo
left join
(select EXTERNAL_ID, sum(repay) as repay
from
(select EXTERNAL_ID, max(AMOUNT) as repay from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select EXTERNAL_ID, max(DEPOSIT_AMOUNT) as repay from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordUnderLinePayRecord where disabled = 0 group by orderNo
) as compile
group by EXTERNAL_ID
) as repay
on repay.EXTERNAL_ID = ord.orderId
order by ordRepayDay;




#6-Repay-CICILAN
select 
billId,
billRepayDay,
repay

from 
(
select
uuid as orderId,
useruuid as userId,
'Installment' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
date(refundTime) as ordDueDay,
amountApply + interest as ordDueAmount,
interest,
date(actualRefundTime) as ordRepayDay
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (3)
and date(lendingTime) between @startDay and @endDay
) ord
inner join 
(
select orderNo as preOrderId, uuid as billId, uuid as payId, billTerm,
date(actualRefundTime) as billRepayDay, billAmout as billDueAmount
from ordBill where disabled = 0 and status in (3,4) and date(actualRefundTime) <= @endDay
union all
select orderNo as preOrderId, a.uuid as billId, orderNo as payId, billTerm,
date(b.actualRefundTime) as billRepayDay, billAmout as billDueAmount
from ordBill as a
	inner join ordOrder as b
    on a.orderNo = b.uuid
    and a.disabled = 0 and b.disabled = 0
    and a.billTerm = 3 and a.status in (1,2)
    and date(b.actualRefundTime) <= @endDay
) bill on bill.preOrderId = ord.orderId
left join 
(select EXTERNAL_ID, sum(repay) as repay
from
(select EXTERNAL_ID, max(AMOUNT) as repay from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select EXTERNAL_ID, max(DEPOSIT_AMOUNT) as repay from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED' group by EXTERNAL_ID
union
select orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordUnderLinePayRecord where disabled = 0 group by orderNo
union
select a.orderNo as EXTERNAL_ID, max(actualRepayAmout) as repay from ordRepayAmoutRecord as a
inner join ordBill as b
on a.orderNo = b.uuid and a.disabled = 0 and b.disabled = 0 and b.billTerm in (1,2) and b.status in (3,4)
and a.repayMethod = 'MANUAL' group by a.orderNo
) as compile
group by EXTERNAL_ID
) as repay
on repay.EXTERNAL_ID = bill.payId
order by billRepayDay;






#7-Lender-TCC mark
select 
EXTERNAL_ID,
#case
#when date(lendingTime) >= '2019-08-01' then 'TCC'
#else FUNDER end as FUNDER
FUNDER
from 
(
select
EXTERNAL_ID,
MAX(FUNDER) as FUNDER
from T_ORDER_EXT_INFO
where DISABLED = 0
and FUNDER = 'TCC'
group by EXTERNAL_ID
) TFA
inner join 
(
select 
uuid as orderId,
lendingTime
from ordOrder
where disabled = 0
and ordertype in (0,2,3)
and status in (7,8,10,11)
and date(lendingTime) between '2019-04-08' and '2019-12-15'
) ord on ord.orderId = TFA.EXTERNAL_ID;

#8 Cash-back
select a.uuid, money from
(select uuid from ordOrder where disabled = 0 and status in (10,11) and actualRefundTime is not null
and date(lendingTime) between @startDay and @endDay and orderType in (0,1,2)
union
select a.uuid from ordBill as a
inner join ordOrder as b
on a.orderNo = b.uuid
and a.disabled = 0 and b.disabled = 0
and date(lendingTime) between @startDay and @endDay
and coalesce(a.actualRefundTime,b.actualRefundTime) is not null) as a
inner join (select orderNo, max(money) as money from couponRecord where disabled = 0 and status = 1 group by orderNo) as b
on a.uuid = b.orderNo;