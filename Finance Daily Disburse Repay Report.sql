SET @startDay = date_format(now() - INTERVAL 1 DAY, '%Y-%m-01');
SET @endDay = date(now()) - INTERVAL 1 DAY;

#SET @startDay = '2020-01-01';
#SET @endDay = '2020-01-31';


#1¡¢DISBURSE Normal
select 
orderId,
if(ordLendDay <= '2019-04-07','Non Portofolio','Portofolio') as DisburseType,
FUNDER as LenderName,
ifnull(realName,ACCOUNT_HOLDER_NAME),
UPDATE_TIME,
ordLendDay,
ordApplyAmount,
ordLendAmount,
case
when datediff(ordRefundDay, ord.lendingTime) < 29 then serviceFee + interest
else serviceFee end as profits,
serviceFee - interest as serviceFee,
interest,
borrowingTerm,
ordRefundDay,
ordDueAmount,
DISBURSEMENT_ID,
DISBURSE_CHANNEL,
DISBURSE_STATUS
from 
(
select
uuid as orderId,
useruuid,
date(lendingTime) as ordLendDay,
borrowingTerm,
amountApply as ordApplyAmount,
serviceFee,
0.001 * amountApply * borrowingTerm as interest,
date(refundTime) as ordRefundDay,
lendingTime,
case
when datediff(refundTime, lendingTime) < 29 then amountApply + interest
else amountApply
end as ordDueAmount,
case when status in (10,11) then date(actualRefundTime) end as udahLunasBelum
from ordOrder
where disabled = 0
and date(lendingTime) between @startDay and @endDay
and orderType in (0,2)
and status in (7,8,10,11)
) ord 
left join 
(
select
EXTERNAL_ID,
ACCOUNT_HOLDER_NAME,
DISBURSE_STATUS,
DISBURSE_CHANNEL,
date(UPDATE_TIME) as UPDATE_TIME,
DISBURSEMENT_ID,
AMOUNT as ordLendAmount
from T_DISBURSEMENT
where DISBURSE_STATUS = 'COMPLETED'
and TRANSACTION_STATUS = 'ACTIVE'
and DISBURSE_TYPE not in ('PRE_SERVICE_FEE')
) td on td.EXTERNAL_ID = ord.orderId
left join 
(select uuid, realName from usrUser) as usr
on ord.useruuid = usr.uuid
left join
(
select
EXTERNAL_ID,
MAX(FUNDER) as FUNDER
from T_ORDER_EXT_INFO
where DISABLED = 0 group by EXTERNAL_ID
) TFA on TFA.EXTERNAL_ID = ord.OrderId
order by ordLendDay;




#2¡¢DISBURSE Installment
select 
orderId,
if(ordLendDay <= '2019-04-07','Non Portofolio','Portofolio') as DisburseType,
FUNDER as LenderName,
'Installment' as orderType,
ifnull(realName,ACCOUNT_HOLDER_NAME),
UPDATE_TIME,
ordLendDay,
ordApplyAmount,
ordLendAmount,
serviceFee - (
0.001 * (thirdDueAmout + secondDueAmout + firstDueAmout) * (datediff(firstDueDay, ordLendDay) + 1) +
0.001 * (thirdDueAmout + secondDueAmout) * (datediff(firstDueDay, ordLendDay) + 1) +
0.001 * (thirdDueAmout) * (datediff(firstDueDay, ordLendDay) + 1)
) as serviceFee,
0.001 * (thirdDueAmout + secondDueAmout + firstDueAmout) * (datediff(firstDueDay, ordLendDay) + 1) +
0.001 * (thirdDueAmout + secondDueAmout) * (datediff(firstDueDay, ordLendDay) + 1) +
0.001 * (thirdDueAmout) * (datediff(firstDueDay, ordLendDay) + 1)
as interest,
firstDueDay,
firstDueAmout,
secondDueDay,
secondDueAmout,
thirdDueDay,
thirdDueAmout,
DISBURSEMENT_ID,
DISBURSE_CHANNEL,
DISBURSE_STATUS
from 
(
select
uuid as orderId,
useruuid,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
interest,
totalTerm,
serviceFee,
date(refundTime) as ordRefundDay,
amountApply + interest as ordDueAmount
from ordOrder
where disabled = 0
and date(lendingTime) between @startDay and @endDay
and orderType in (3)
and status in (7,8,10,11)
) ord 
left join 
(
select 
orderNo,
sum(case when billTerm = 1 then billAmout end) as firstDueAmout,
sum(case when billTerm = 2 then billAmout end) as secondDueAmout,
sum(case when billTerm = 3 then billAmout end) as thirdDueAmout,
max(case when billTerm = 1 then date(a.refundTime) end) as firstDueDay,
max(case when billTerm = 2 then date(a.refundTime) end) as secondDueDay,
max(case when billTerm = 3 then date(a.refundTime) end) as thirdDueDay,
count(case when a.status in (1,2) and coalesce(a.actualRefundTime, b.actualRefundTime) is null then orderNo end) as sisaTermin
from ordBill as a
inner join ordOrder as b on a.orderNo = b.uuid
and a.disabled = 0 and b.disabled = 0
group by orderNo
) bill on bill.orderNo = ord.orderId
left join 
(
select
EXTERNAL_ID,
ACCOUNT_HOLDER_NAME,
DISBURSE_STATUS,
DISBURSE_CHANNEL,
date(UPDATE_TIME) as UPDATE_TIME,
DISBURSEMENT_ID,
AMOUNT as ordLendAmount
from T_DISBURSEMENT
where DISBURSE_STATUS = 'COMPLETED'
and TRANSACTION_STATUS = 'ACTIVE'
and DISBURSE_TYPE not in ('PRE_SERVICE_FEE')
) td on td.EXTERNAL_ID = ord.orderId
left join 
(select uuid, realName from usrUser) as usr
on ord.useruuid = usr.uuid
left join
(
select
EXTERNAL_ID,
FUNDER
from T_ORDER_EXT_INFO
where DISABLED = 0
) TFA on TFA.EXTERNAL_ID = td.EXTERNAL_ID
order by ordLendDay;



#3¡¢Repay Before Ext
Select
ifnull(va.CUSTOMER_NAME,ifnull(realName,dis.CUSTOMER_NAME)) as CUSTOMER_NAME,
orderId,
delayOrderNo,
if(ordLendDay <= '2019-04-07','Non Portofolio','Portofolio') as DisburseType,
FUNDER,
orderType,
ordLendDay,
ordApplyAmount,
ordLendAmount,
ordRefundDay,
DEPOSIT_AMOUNT + ifnull(coupon,0) as ordDueAmount,
ordRepayDay,
DEPOSIT_AMOUNT as ordRepayAmout,
DEPOSIT_AMOUNT + ifnull(coupon,0) - ifnull(repayNum,ifnull(ordApplyAmount,0)) - ifnull(delayFee,0) as OverdueFee,
delayFee as ExtensionFee,
Interest,
ifnull(repayNum,ordApplyAmount) as Principal,
-coupon,
PAYMENT_CODE,
DEPOSIT_CHANNEL,
DEPOSIT_METHOD,
DEPOSIT_STATUS,
date(updateTime)
from
(
select
uuid as orderId,
useruuid,
if(orderType = 0,'Normal','Extension') as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
date(refundTime) as ordRefundDay,
lendingTime,
interest,
#0.001 * amountApply * borrowingTerm as interest,
date(actualRefundTime) as ordRepayDay,
updateTime
from ordOrder
where disabled = 0
and status in (10,11)
and ordertype in (0,2)
and actualRefundTime is not null
and date(updateTime) between @startDay and @endDay
) ord
left join 
(
select orderNo,delayOrderNo,repayNum,delayFee
from ordDelayRecord
where disabled = 0 and type = 2 and delayOrderNo is not null
) odr on odr.orderNo = ord.orderId
left join 
(select EXTERNAL_ID, DEPOSIT_STATUS, case when DEPOSIT_CHANNEL = 'CIMB' then concat('1149',PAYMENT_CODE) else PAYMENT_CODE end as PAYMENT_CODE, DEPOSIT_CHANNEL, DEPOSIT_METHOD, DEPOSIT_AMOUNT
from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED'
union all
select EXTERNAL_ID, OVO_DEPOSIT_STATUS as DEPOSIT_STATUS, MERCHANT_INVOICE as PAYMENT_CODE, PHONE as DEPOSIT_CHANNEL,
'OVO' as DEPOSIT_METHOD, AMOUNT as DEPOSIT_AMOUNT
from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED'
union all
select orderNo as EXTERNAL_ID, 'COMPLETED' as DEPOSIT_STATUS, 'MANUAL' as PAYMENT_CODE, 'MANUAL' as DEPOSIT_CHANNEL,
'MANUAL' as DEPOSIT_METHOD, actualRepayAmout as DEPOSIT_AMOUNT
from ordUnderLinePayRecord where disabled = 0
) payment on payment.EXTERNAL_ID = ord.orderId
left join 
(select max(AMOUNT) as ordLendAmount, max(ACCOUNT_HOLDER_NAME) as CUSTOMER_NAME, EXTERNAL_ID from T_DISBURSEMENT
where DISBURSE_STATUS = 'COMPLETED' and DISBURSE_TYPE not in ('PRE_SERVICE_FEE') and TRANSACTION_STATUS = 'ACTIVE'
group by EXTERNAL_ID) dis
on ord.orderId = dis.EXTERNAL_ID
left join
(select max(CUSTOMER_NAME) as CUSTOMER_NAME, EXTERNAL_ID from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED'
group by EXTERNAL_ID) as va
on va.EXTERNAL_ID = ord.orderId
left join
(select uuid as userId, realName from usrUser
) usr on usr.userId = ord.useruuid
left join
(select money as coupon, orderNo from couponRecord where disabled = 0 and status = 1
) as c on ord.orderId = c.orderNo
left join
(select EXTERNAL_ID, MAX(FUNDER) as FUNDER from T_ORDER_EXT_INFO where DISABLED = 0 group by EXTERNAL_ID) as funder
on funder.EXTERNAL_ID = ord.orderId
order by ordRepayDay;



#4¡¢Repay After Ext
Select
ifnull(va.CUSTOMER_NAME,ifnull(realName,dis.CUSTOMER_NAME)) as CUSTOMER_NAME,
orderId,
preOrderNo,
if(preLendDay <= '2019-04-07','Non Portofolio','Portofolio') as DisburseType,
FUNDER,
orderType,
ordLendDay,
ordApplyAmount,
0 as ordLendAmount,
ordRefundDay,
DEPOSIT_AMOUNT + ifnull(coupon,0) as ordDueAmount,
ordRepayDay,
DEPOSIT_AMOUNT as ordRepayAmout,
DEPOSIT_AMOUNT + ifnull(coupon,0) - ordApplyAmount as OverdueFee,
ordApplyAmount as Principal,
-coupon,
PAYMENT_CODE,
DEPOSIT_CHANNEL,
DEPOSIT_METHOD,
DEPOSIT_STATUS,
date(updateTime)
from
(select
uuid as orderId,
useruuid,
'Extension' as orderType,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
0 as ordLendAmount,
date(refundTime) as ordRefundDay,
date(actualRefundTime) as ordRepayDay,
updateTime
from ordOrder
where disabled = 0
and status in (10,11)
and ordertype in (1)
and actualRefundTime is not null
and date(updateTime) between @startDay and @endDay
) ord
left join 
(select orderNo as preOrderNo,delayOrderNo,repayNum,delayFee
from ordDelayRecord
where disabled = 0 and type = 2 and delayOrderNo is not null
) odr on odr.delayOrderNo = ord.orderId
inner join 
(select
uuid as preOrderId,
date(lendingTime) as preLendDay
from ordOrder
where disabled = 0 and orderType = 2
) pre on pre.preOrderId = odr.preOrderNo
left join 
(select EXTERNAL_ID, DEPOSIT_STATUS, case when DEPOSIT_CHANNEL = 'CIMB' then concat('1149',PAYMENT_CODE) else PAYMENT_CODE end as PAYMENT_CODE, DEPOSIT_CHANNEL, DEPOSIT_METHOD, DEPOSIT_AMOUNT
from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED'
union all
select EXTERNAL_ID, OVO_DEPOSIT_STATUS as DEPOSIT_STATUS, MERCHANT_INVOICE as PAYMENT_CODE, PHONE as DEPOSIT_CHANNEL,
'OVO' as DEPOSIT_METHOD, AMOUNT as DEPOSIT_AMOUNT 
from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED'
union all
select orderNo as EXTERNAL_ID, 'COMPLETED' as DEPOSIT_STATUS, 'MANUAL' as PAYMENT_CODE, 'MANUAL' as DEPOSIT_CHANNEL,
'MANUAL' as DEPOSIT_METHOD, actualRepayAmout as DEPOSIT_AMOUNT
from ordUnderLinePayRecord where disabled = 0
) payment on payment.EXTERNAL_ID = ord.orderId
left join
(select EXTERNAL_ID, max(ACCOUNT_HOLDER_NAME) as CUSTOMER_NAME from T_DISBURSEMENT where DISBURSE_STATUS = 'COMPLETED'
and DISBURSE_TYPE not in ('PRE_SERVICE_FEE') and TRANSACTION_STATUS = 'ACTIVE' group by EXTERNAL_ID
) as dis on dis.EXTERNAL_ID = pre.preOrderId
left join
(select max(CUSTOMER_NAME) as CUSTOMER_NAME, EXTERNAL_ID from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED'
group by EXTERNAL_ID) as va
on va.EXTERNAL_ID = ord.orderId
left join 
(select uuid as userId, realName from usrUser
) usr on usr.userId = ord.useruuid
left join (select money as coupon, orderNo from couponRecord where disabled = 0 and status = 1
) as c on ord.orderId = c.orderNo
left join (select EXTERNAL_ID, max(FUNDER) as FUNDER from T_ORDER_EXT_INFO where DISABLED = 0 group by EXTERNAL_ID) as funder
on funder.EXTERNAL_ID = pre.preOrderId
order by ordRepayDay;



#5¡¢Repay Installment
select
ifnull(va.CUSTOMER_NAME,ifnull(realName,dis.CUSTOMER_NAME)) as CUSTOMER_NAME,
orderId,
billId,
billTerm,
'Portofolio' as DisburseType,
FUNDER,
orderType,
ordLendDay,
ordApplyAmount,
ordLendAmount,
billRefundDay,
billDueAmount + ifnull(coupon,0) as billDueAmount,
billRepayDay,
case when DEPOSIT_AMOUNT < billDueAmount then billDueAmount else DEPOSIT_AMOUNT end as billRepayAmout,
billDueAmount as Principal,
case when DEPOSIT_AMOUNT < billDueAmount then 0
else DEPOSIT_AMOUNT + ifnull(coupon,0) - billDueAmount end as OverdueFee,
case when DEPOSIT_AMOUNT < billDueAmount then -(billDueAmount - DEPOSIT_AMOUNT) else -coupon end as coupon,
PAYMENT_CODE,
DEPOSIT_CHANNEL,
DEPOSIT_METHOD,
DEPOSIT_STATUS,
date(updateTime)
from
(select 
uuid as orderId,
'Installment' as orderType,
useruuid,
date(lendingtime) as ordLendDay,
amountApply as ordApplyAmount
from ordOrder
where disabled = 0
and ordertype = 3 
and status in (7,8,10,11)
) ord
inner join 
(select a.uuid as billId, a.uuid as payId, a.orderNo, a.billTerm as billTerm, date(a.refundTime) as billRefundDay,
date(a.actualRefundTime) as billRepayDay, a.billAmout as billDueAmount, date(a.updateTime) as updateTime
from ordBill as a
	where a.status in (3,4) and a.actualRefundTime is not null
    and date(a.updateTime) between @startDay and @endDay
union
select a.uuid as billId, a.orderNo as payId, a.orderNo, a.billTerm as billTerm, date(a.refundTime) as billRefundDay,
date(c.actualRefundTime) as billRepayDay, a.billAmout as billDueAmount, date(c.updateTime) as updateTime
from ordBill as a
		inner join ordOrder as c
        on a.orderNo = c.uuid and c.actualRefundTime is not null
        and a.disabled = 0 and c.disabled = 0 and c.status in (10,11)
        and a.status in (1,2) and billTerm = 3
        and date(c.updateTime) between @startDay and @endDay
) bill on bill.orderNo = ord.orderId
left join 
(select EXTERNAL_ID, DEPOSIT_STATUS, case when DEPOSIT_CHANNEL = 'CIMB' then concat('1149',PAYMENT_CODE) else PAYMENT_CODE end as PAYMENT_CODE, DEPOSIT_CHANNEL, DEPOSIT_METHOD, DEPOSIT_AMOUNT
from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED'
union all
select EXTERNAL_ID, OVO_DEPOSIT_STATUS as DEPOSIT_STATUS, MERCHANT_INVOICE as PAYMENT_CODE, PHONE as DEPOSIT_CHANNEL,
'OVO' as DEPOSIT_METHOD, AMOUNT as DEPOSIT_AMOUNT 
from T_OVO_LPAY_DEPOSIT where OVO_DEPOSIT_STATUS = 'COMPLETED'
union all
select orderNo as EXTERNAL_ID, 'COMPLETED' as DEPOSIT_STATUS, 'MANUAL' as PAYMENT_CODE, 'MANUAL' as DEPOSIT_CHANNEL,
'MANUAL' as DEPOSIT_METHOD, actualRepayAmout as DEPOSIT_AMOUNT
from ordUnderLinePayRecord where disabled = 0
union all
select a.orderNo as EXTERNAL_ID, 'COMPLETED' as DEPOSIT_STATUS, 'MANUAL' as PAYMENT_CODE, 'MANUAL' as DEPOSIT_CHANNEL,
'MANUAL' as DEPOSIT_METHOD, a.actualRepayAmout as DEPOSIT_AMOUNT
from ordRepayAmoutRecord as a
	inner join ordBill as b
    on a.orderNo = b.uuid
    and a.disabled = 0 and b.disabled = 0
    and repayMethod = 'MANUAL' and b.billTerm in (1,2)
) payment on payment.EXTERNAL_ID = bill.payId
left join (select AMOUNT/3 as ordLendAmount, EXTERNAL_ID, ACCOUNT_HOLDER_NAME as CUSTOMER_NAME from T_DISBURSEMENT
where DISBURSE_STATUS = 'COMPLETED' and DISBURSE_TYPE not in ('PRE_SERVICE_FEE') and TRANSACTION_STATUS = 'ACTIVE'
) dis on ord.orderId = dis.EXTERNAL_ID
left join
(select max(CUSTOMER_NAME) as CUSTOMER_NAME, EXTERNAL_ID from T_LPAY_DEPOSIT where DEPOSIT_STATUS = 'COMPLETED'
group by EXTERNAL_ID) as va
on va.EXTERNAL_ID = bill.billId
left join 
(select uuid as userId, realName from usrUser
) usr on usr.userId = ord.useruuid
left join (select money as coupon, orderNo from couponRecord where disabled = 0 and status = 1
) as c on bill.billId = c.orderNo
left join
(select EXTERNAL_ID, max(FUNDER) as FUNDER from T_ORDER_EXT_INFO where DISABLED = 0 group by EXTERNAL_ID) as funder
on funder.EXTERNAL_ID = ord.orderId
order by billRepayDay;
;