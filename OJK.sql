#OJK

#1. Users, Orders, Amount by Province
SET @patokan = 201910;
select	
province,		
count(distinct userId) as activeUser,
count(orders),
sum(amountApply)

from

(select useruuid as userId, amountApply, uuid as orders
from ordOrder where disabled = 0 and status in (7,8,10,11) and orderType in (0,2,3)
and date_format(lendingTime,'%Y%m') = @patokan
union
select userUuid as userId, amountApply, uuid as orders
from produktifOrder where disabled = 0 and date_format(lendingTime,'%Y%m') = @patokan) as a

left join

(select userUuid, max(province) as province
from
(select userUuid, lower(province) as province
from usrAddressDetail where addressType = 0 and disabled = 0
union
select userUuid, lower(province) as province
from produktifOrder where disabled = 0) as b
group by userUuid) as c 
on c.userUuid = a.userId

group by province;


#2. Users, Orders by SEX
SET @patokan = 201910;
select 
Sex,
count(distinct userId) as activeUser,
count(orders)

from

(select useruuid as userId, uuid as orders
from ordOrder
where disabled = 0 and status in (7,8,10,11) and orderType in (0,2,3)
and date_format(lendingTime,'%Y%m') = @patokan
union
select userUuid as userId, uuid as orders
from produktifOrder
where disabled = 0 and date_format(lendingTime,'%Y%m') = @patokan) as a

left join 

(select userUuid, max(sex) as sex
from
(select uuid as userUuid, sex
from usrUser where disabled = 0
union
select userUuid, sex
from produktifOrder where disabled = 0) as b
group by userUuid) as c 

on c.userUuid = a.userId

group by sex;


#3. Users, Orders by AGE
SET sql_mode = 'NO_UNSIGNED_SUBTRACTION';
SET @patokan = 201910;
select
case
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) < 19 then '1.Under 19'
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) between 19 and 34 then '2.19-34'
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) between 35 and 54 then '3.35-54'
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) > 54 then '4.Over 54'
end as type,
count(distinct userId) as activeUser,
count(orders) as orders
from
(select userId, orders, userAge, actualAge
from
(select useruuid as userId, uuid as orders from ordOrder
where disabled = 0 and status in (7,8,10,11) and orderType in (0,2,3)
and date_format(lendingTime,'%Y%m') <= @patokan
union
select userUuid as userId, uuid as orders from produktifOrder
where disabled = 0 and date_format(lendingTime,'%Y%m') <= @patokan) ord
								
left join
(select uuid, max(userAge) as userAge
from
(select uuid, age as userAge from usrUser where disabled = 0
union
select userUuid as uuid, age as userAge from produktifOrder where disabled = 0) as umur
group by uuid) as usr
on usr.uuid = ord.userId

left join 
(select useruuid,
max(ifnull(year(now()) - birthday,0)) as actualAge
from  
(select useruuid,max(year(birthday)) as birthday from usrWorkDetail where disabled = 0 group by useruuid
union
select useruuid,max(year(birthday)) as birthday from usrStudentDetail where disabled = 0 group by useruuid
union
select useruuid,max(year(birthday)) as birthday from usrHouseWifeDetail where disabled = 0 group by useruuid
union
select useruuid,max(year(birthday)) as birthday from produktifOrder where disabled = 0 group by useruuid
) un
group by useruuid
) det on det.useruuid = ord.userId
) full
group by type
order by type;


#4. Approved - Loaned Time (punya Weibin)
#Min, Max, Average Approved - Loaned Time
set @startDay = '2019-10-01';
set @endDay = '2019-10-31';

select 
count(1) as orders,
from_unixtime(max(sec)) as maxtime,
from_unixtime(min(sec)) as mintime,
from_unixtime(avg(sec)) as avgtime
from 
(
select 
orderid,
count(1) as orders,
unix_timestamp(max(timediff(createDay2,createDay1))) as sec
from 
(
select
His1.orderId,
His1.createDay as createDay1,
His2.createDay as createDay2
from
(
select
createtime as createDay,status,orderId
from ordHistory
where disabled = 0 and status = 5 
) His1
inner join   
(
select
createtime as createDay,status,orderId
from ordHistory
where disabled = 0 and status = 7
and date(createTime) between @startDay and @endDay
) His2 on His1.orderId = His2.orderId
) a
group by orderid
order by sec
) result;


#5. Submit - Approved Time (punya Weibin)
#Min, Max, Average Submit - Approved Time
set @startDay = '2019-10-01';
set @endDay = '2019-10-31';

select 
count(1) as orders,
from_unixtime(max(sec)) as maxtime,
from_unixtime(min(sec)) as mintime,
from_unixtime(avg(sec)) as avgtime
from 
(
select 
orderid,
count(1) as orders,
unix_timestamp(max(timediff(createDay2,createDay1))) as sec
from 
(
select
His1.orderId,
His1.createDay as createDay1,
His2.createDay as createDay2
from
(
select
createtime as createDay,status,orderId
from ordHistory
where disabled = 0 and status = 2 
) His1
inner join   
(
select
createtime as createDay,status,orderId
from ordHistory
where disabled = 0 and status = 5
) His2 on His1.orderId = His2.orderId
inner join   
(
select
uuid
from ordOrder
where disabled = 0
and date(lendingTime) between @startDay and @endDay
) ord on His1.orderId = ord.uuid
) mydata
group by orderid
having orders = 1
order by sec
) result;


#6. Average borrowingTerm
SET @startDay = '2019-10-01';
SET @endDay = '2019-10-31';
select count(uuid), borrowingTerm
from
(select uuid, borrowingTerm from ordOrder where disabled = 0 and orderType in (0,2)
and date(lendingTime) between @startDay and @endDay and status in (7,8,10,11)
union
select uuid, 90 as borrowingTerm from ordOrder where disabled = 0 and orderType = 3
and date(lendingTime) between @startDay and @endDay and status in (7,8,10,11)) as a
group by borrowingTerm;


#7. Average amountApply
SET @startDay = '2019-10-01';
SET @endDay = '2019-10-31';
select count(uuid), amountApply from 
(select uuid, amountApply from ordOrder where disabled = 0 and status in (7,8,10,11) and orderType in (0,2,3)
and date(lendingTime) between @startDay and @endDay
union
select uuid, amountApply from produktifOrder where disabled = 0 and date(lendingTime) between @startDay and @endDay) as a
group by amountApply;


#8. Submitted Orders
SET @startDay = '2019-10-01';
SET @endDay = '2019-10-31';
select count(distinct orderId) from 
(select distinct orderId from ordHistory where disabled = 0 and status = 2 and date(createTime) <= @endDay 
#between @startDay and @endDay
union all
select uuid as orderId from produktifOrder where date(lendingTime) <= @endDay) as a; 
#between @startDay and @endDay and disabled = 0) as a;


#9. Rejected Orders
SET @startDay = '2019-10-01';
SET @endDay = '2019-10-31';
select count(distinct a.orderId) from ordHistory as a
inner join
	(select distinct orderId from ordHistory where status in (12,13,14,15)) as b
	on a.orderId = b.orderId
	and a.status = 2
	and a.disabled = 0
	and date(a.createTime) between @startDay and @endDay;



#FORM 2 - OUTSTANDING
#1. By province - normal & extension
SET @endDay = '2020-01-31';

select 
dayType,
province,
sum(amountApply) as outstandingAmount,
count(distinct userId) as outstandingUsers
from 
(
select 
userId, amountApply, province,
case 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) <= 30 then '<=30' 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) between 31 and 90 then '31-90' 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) > 90 then '>90' 
when status in (7,8) and datediff(@endDay,refundTime) <= 30 then '<=30' 
when status in (7,8) and datediff(@endDay,refundTime) between 31 and 90 then '31-90' 
when status in (7,8) and datediff(@endDay,refundTime) > 90 then '>90'
else 'repay' end as dayType
from
(select userId, amountApply, province, actualRefundTime, refundTime, status
from 
(select userUuid as userId, amountApply, actualRefundTime, refundTime, status
from ordOrder
where disabled = 0 
and ordertype in (0,1,2)
and status in (7,8,10,11)
and date(lendingtime) between '2018-06-01' and @endDay
union all
select userUuid as userId, amountApply, actualRefundTime, refundTime, status
from produktifOrder
where date(lendingTime) between '2018-06-01' and @endDay and disabled = 0# and orderType != 3
) ord  

left join 
(select userUuid, max(province) as province
from
(select userUuid,lower(province) as province
from usrAddressDetail where addressType = 0 and disabled = 0
union
select userUuid,lower(province) as province
from produktifOrder where disabled = 0
) address
group by userUuid
) as full on full.userUuid = ord.userId
) as fuller
) as fullerrrr
where dayType != 'repay'
group by province, dayType;


#2. By province - installment
SET @endDay = '2019-11-30';

select 
dayType,
province,
sum(billDueAmount) as outstandingAmount,
count(distinct userId) as outstandingUsers
from 
(
select 
orderId,
province,
userId,
case 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) <= 30 then '<=30' 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) between 31 and 90 then '31-90' 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) > 90 then '>90' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) <= 30 then '<=30' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) between 31 and 90 then '31-90' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) > 90 then '>90' 
else 'repay' end as dayType,
billDueAmount
from
(
select
uuid as orderId,
useruuid as userId,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
amountApply - serviceFee as ordLendAmount
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (3)
and date(lendingTime) between '2019-04-01' and @endDay
) ord  
inner join 
(
select 
orderNo,
a.uuid as billId,
billTerm,
date(a.refundTime) as billDueDay,
date(coalesce(a.actualRefundTime, b.actualRefundTime)) as billRepayDay,
billAmout as billDueAmount,
a.status
from ordBill as a
	inner join ordOrder as b
    	on a.orderNo = b.uuid
	and a.disabled = 0 and b.disabled = 0
) bill on bill.orderNo = ord.orderId
left join
(select userUuid,max(province) as province
from
(select userUuid, lower(province) as province
from usrAddressDetail where addressType = 0 and disabled = 0
union
select userUuid, lower(province) as province
from produktifOrder where disabled = 0) as addr
group by userUuid
) address on address.userUuid = ord.userId
) result
where dayType != 'repay'
group by dayType,province;


#3. By sex - normal & extension
SET @endDay = '2019-11-30';

select 
if(sex is null or sex = 0,2,sex) as newsex,
dayType,
sum(amountApply) as outstandingAmount,
count(distinct userId) as outstandingUsers
from 
(
select 
userId, amountApply, sex,
case 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) <= 30 then '<=30' 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) between 31 and 90 then '31-90' 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) > 90 then '>90' 
when status in (7,8) and datediff(@endDay,refundTime) <= 30 then '<=30' 
when status in (7,8) and datediff(@endDay,refundTime) between 31 and 90 then '31-90'
when status in (7,8) and datediff(@endDay,refundTime) > 90 then '>90'
else 'repay' end as dayType
from
(select userId, amountApply, sex, status, actualRefundTime, refundTime
from

(select userUuid as userId, amountApply, status, actualRefundTime, refundTime
from ordOrder
where disabled = 0 
and ordertype in (0,1,2)
and status in (7,8,10,11)
and date(lendingtime) between '2018-06-01' and @endDay
union all
select userUuid as userId, amountApply, status, actualRefundTime, refundTime
from produktifOrder
where disabled = 0 and date(lendingTime) between '2018-06-01' and @endDay
) ord  

left join 
(select uuid, max(sex) as sex
from
(select uuid, sex from usrUser where disabled = 0
union
select userUuid as uuid, sex from produktifOrder where disabled = 0) a
group by uuid
) as usr on usr.uuid = ord.userId
) as full
) as fuller
where dayType != 'repay'
group by dayType,newsex;

#4. By sex - installment
SET @endDay = '2019-11-30';
select 
if(sex is null or sex = 0,2,sex) as newsex,
dayType,
sum(billDueAmount) as outstandingAmount,
count(distinct userId) as outstandingUsers
from 
(
select 
orderId,
sex,
userId,
case 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) <= 30 then '<=30' 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) between 31 and 90 then '31-90' 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) > 90 then '>90' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) <= 30 then '<=30' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) between 31 and 90 then '31-90' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) > 90 then '>90' 
else 'repay' end as dayType,
billDueAmount
from
(
select
uuid as orderId,
useruuid as userId,
date(lendingTime) as ordLendDay,
amountApply as ordApplyAmount,
amountApply - serviceFee as ordLendAmount
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (3)
and date(lendingTime) between '2019-04-01' and @endDay
) ord  
inner join 
(
select 
orderNo,
a.uuid as billId,
billTerm,
date(a.refundTime) as billDueDay,
date(coalesce(a.actualRefundTime, b.actualRefundTime)) as billRepayDay,
billAmout as billDueAmount,
a.status
from ordBill as a
	inner join ordOrder as b
    	on a.orderNo = b.uuid
	and a.disabled = 0 and b.disabled = 0
) bill on bill.orderNo = ord.orderId
left join 
(
select uuid,sex
from usrUser
where disabled = 0
) usr on usr.uuid = ord.userId
) result
where dayType != 'repay'
group by dayType,newsex;


#5. By age - normal & extension
SET sql_mode = 'NO_UNSIGNED_SUBTRACTION';
set @endDay = '2019-11-30';

select
dayType,
case 
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) < 19 then '1.Under 19'
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) between 19 and 34 then '2.19-34'
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) between 35 and 54 then '3.35-54'
when if(actualAge <= 0 or actualAge >= 101, coalesce(userAge,0), actualAge) > 54 then '4.Over 54'
end as ageType,
sum(amountApply) as outstandingAmount,
count(distinct userId) as outstandingUsers
from 
(
select 
userId, amountApply, userAge, actualAge,
case 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) <= 30 then '<=30' 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) between 31 and 90 then '31-90' 
when status in (10,11) and datediff(actualRefundTime,@endDay) > 0 and datediff(@endDay,refundTime) > 90 then '>90' 
when status in (7,8) and datediff(@endDay,refundTime) <= 30 then '<=30' 
when status in (7,8) and datediff(@endDay,refundTime) between 31 and 90 then '31-90'
when status in (7,8) and datediff(@endDay,refundTime) > 90 then '>90'
else 'repay' end as dayType
from
(select userId, amountApply, userAge, actualAge, status, actualRefundTime, refundTime

from 
(select userUuid as userId, amountApply, status, actualRefundTime, refundTime
from ordOrder
where disabled = 0 
and ordertype in (0,1,2)
and status in (7,8,10,11)
and date(lendingtime) between '2018-06-01' and @endDay
union all
select userUuid as uuid, amountApply, status, actualRefundTime, refundTime
from produktifOrder
where disabled = 0 and date(lendingTime) between '2018-06-01' and @endDay
) ord  

left join 
(select uuid, max(userAge) as userAge
from
(select uuid, age as userAge from usrUser where disabled = 0
union
select userUuid as uuid, age as userAge from produktifOrder where disabled = 0) as age
group by uuid) usr on usr.uuid = ord.userId

left join 
(select useruuid,
max(ifnull(year(now()) - year(birthday),0)) as actualAge
from  
(select useruuid, max(birthday) as birthday from usrWorkDetail where disabled = 0 group by useruuid
union
select useruuid, max(birthday) as birthday from usrStudentDetail where disabled = 0 group by useruuid
union
select useruuid, max(birthday) as birthday from usrHouseWifeDetail where disabled = 0 group by useruuid
union
select useruuid, birthday from produktifOrder where disabled = 0) un
group by useruuid
) det on det.useruuid = ord.userId
) as full
) as fuller
where dayType != 'repay'
group by dayType,ageType
order by ageType;



#6. By age - installment
SET @endDay = '2019-11-30';

select 
dayType,
ageType,
sum(billDueAmount) as outstandingAmount,
count(distinct userId) as outstandingUsers
from 
(
select 
orderId,
case 
when if(actualAge = 0 or actualAge >= 101, coalesce(userAge,0), actualAge) < 19 then '1.Under 19'
when if(actualAge = 0 or actualAge >= 101, coalesce(userAge,0), actualAge) between 19 and 34 then '2.19-34'
when if(actualAge = 0 or actualAge >= 101, coalesce(userAge,0), actualAge) between 35 and 54 then '3.35-54'
when if(actualAge = 0 or actualAge >= 101, coalesce(userAge,0), actualAge) > 54 then '4.Over 54'
end as ageType,
userId,
case 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) <= 30 then '<=30' 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) between 31 and 90 then '31-90' 
when status in (3,4) and datediff(billRepayDay,@endDay) > 0 and datediff(@endDay,billDueDay) > 90 then '>90' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) <= 30 then '<=30' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) between 31 and 90 then '31-90' 
when status in (1,2) and billRepayDay is null and datediff(@endDay,billDueDay) > 90 then '>90' 
else 'repay' end as dayType,
billDueAmount
from
(
select
uuid as orderId,
useruuid as userId
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and ordertype in (3)
and date(lendingTime) between '2019-04-01' and @endDay
) ord  
inner join 
(
select 
orderNo,
a.uuid as billId,
billTerm,
date(a.refundTime) as billDueDay,
date(coalesce(a.actualRefundTime, b.actualRefundTime)) as billRepayDay,
billAmout as billDueAmount,
a.status
from ordBill as a	
	inner join ordOrder as b
    on a.orderNo = b.uuid
    and a.disabled = 0 and b.disabled = 0
) bill on bill.orderNo = ord.orderId
left join 
(
select uuid,age as userAge
from usrUser
where disabled = 0
) usr on usr.uuid = ord.userId
left join 
(
select useruuid,
max(ifnull(year(now()) - right(birthday,4),0)) as actualAge
from  
(
select useruuid,max(birthday) as birthday
from usrWorkDetail
where disabled = 0
group by useruuid
union
select useruuid,max(birthday) as birthday
from usrStudentDetail
where disabled = 0
group by useruuid
union
select useruuid,max(birthday) as birthday
from usrHouseWifeDetail
where disabled = 0
group by useruuid
) un
group by useruuid
) det on det.useruuid = ord.userId
) result
where dayType != 'repay'
group by dayType,ageType
order by ageType;



#FUNDER
#1. Akumulasi orders & amount berdasar funder + unique funder
use doit_reporting;
SET @endDay = '2019-10-31';
select	
FUNDER,
count(orders),
sum(amountApply)

from

(select FUNDER, orders, amountApply

from
(select uuid as orders, amountApply
from ordOrder where disabled = 0 and status in (7,8,10,11) and orderType in (0,2,3)
and date(lendingTime) <= @endDay
union
select uuid as orders, amountApply
from produktifOrder where disabled = 0 and date(lendingTime) <= @endDay) as a
left join 
(select a.FUNDER, a.EXTERNAL_ID from T_ORDER_EXT_INFO as a
inner join (select EXTERNAL_ID, ID, max(UPDATE_TIME) as UPDATE_TIME from T_ORDER_EXT_INFO
where DISABLED = 0 group by EXTERNAL_ID) as b
on a.EXTERNAL_ID = b.EXTERNAL_ID and a.ID = b.ID and a.DISABLED = 0
union
select FUNDER, uuid as EXTERNAL_ID from produktifOrder where DISABLED = 0) as b
on a.orders = b.EXTERNAL_ID
) as full
group by FUNDER;



#3. OUTSTANDING DETAIL, grouped by FUNDER
SET @endDay = '2020-01-31';
#NORMAL
select FUNDER, sum(amountApply) from
(select FUNDER, 
amountApply
from
(select amountApply, uuid from ordOrder 
where orderType in (0,2)
and disabled = 0
and date(lendingTime) between '2018-06-01' and @endDay
and ((status in (7,8) and datediff(@endDay, refundTime) <= 90)
OR (status in (10,11) and date(actualRefundTime) > @endDay and datediff(@endDay,refundTime) <= 90))
union all
select amountApply, uuid from produktifOrder
where disabled = 0 and date(lendingTime) between '2018-06-01' and @endDay
and ((status in (7,8) and datediff(@endDay, refundTime) <= 90)
OR (status in (10,11) and date(actualRefundTime) > @endDay and datediff(@endDay,refundTime) <= 90))) as a
	left join
    (select a.FUNDER, a.EXTERNAL_ID from T_ORDER_EXT_INFO as a
    inner join (select EXTERNAL_ID, ID, max(UPDATE_TIME) as UPDATE_TIME from T_ORDER_EXT_INFO
    where DISABLED = 0 group by EXTERNAL_ID) as b
    on a.EXTERNAL_ID = b.EXTERNAL_ID and a.ID = b.ID and a.DISABLED = 0
    union
    select FUNDER, uuid as EXTERNAL_ID from produktifOrder where disabled = 0) as b
    on a.uuid = b.EXTERNAL_ID
) as full
group by FUNDER;

#EXTENSION
select FUNDER, sum(amountApply) from
(select amountApply, uuid from ordOrder 
where orderType in (1)
and disabled = 0
and date(lendingTime) between '2018-06-01' and @endDay
and ((status in (7,8) and datediff(@endDay, refundTime) <= 90)
OR (status in (10,11) and date(actualRefundTime) > @endDay and datediff(@endDay,refundTime) <= 90))) as a
	left join (select orderNo, delayOrderNo from ordDelayRecord where type = 2 and delayOrderNo is not null
    and disabled = 0) as d
    on a.uuid = d.delayOrderNo
		inner join
        (select uuid from ordOrder where disabled = 0 and orderType = 2 and date(lendingTime) between '2018-06-01' and @endDay) as b
        on d.orderNo = b.uuid
	left join
    (select a.FUNDER, a.EXTERNAL_ID from T_ORDER_EXT_INFO as a
    inner join (select EXTERNAL_ID, ID, max(UPDATE_TIME) as UPDATE_TIME from T_ORDER_EXT_INFO
    where DISABLED = 0 group by EXTERNAL_ID) as b
    on a.EXTERNAL_ID = b.EXTERNAL_ID and a.ID = b.ID and a.DISABLED = 0
	) as e
    on d.orderNo = e.EXTERNAL_ID
group by FUNDER;


#CICILAN
select 
FUNDER,
sum(billDueAmount) as outstandingAmount
from 
(select FUNDER, billDueAmount
from
(select orderNo, a.uuid as billId, billAmout as billDueAmount
from ordBill as a
	inner join ordOrder as b
    on a.orderNo = b.uuid
    and a.disabled = 0 and b.disabled = 0
    and date(lendingTime) between '2019-04-01' and @endDay
and ((a.status in (1,2) and coalesce(a.actualRefundTime,b.actualRefundTime) is null
and datediff(@endDay,a.refundTime) <= 90) 
OR (a.status in (3,4) and datediff(a.actualRefundTime, @endDay) > 0 and datediff(@endDay,a.refundTime) <= 90))
) bill
left join 
(select a.FUNDER, a.EXTERNAL_ID from T_ORDER_EXT_INFO as a
    inner join (select EXTERNAL_ID, ID, max(UPDATE_TIME) as UPDATE_TIME from T_ORDER_EXT_INFO
    where DISABLED = 0 group by EXTERNAL_ID) as b
    on a.EXTERNAL_ID = b.EXTERNAL_ID and a.ID = b.ID and a.DISABLED = 0
) as B
on bill.orderNo = B.EXTERNAL_ID
) as full
group by FUNDER;



###AMOUNTAPPLY by BORROWUSE
select 
borrowUse,
sum(amountapply) as amountapply
from 
(select amountApply, borrowUse

from
(select useruuid as userId, amountapply
from ordOrder
where disabled = 0
and status in (7,8,10,11)
and orderType in (0,2,3)
and date_format(lendingTime,'%Y%m') = 201910
) ord
left join 
(
select 
useruuid,max(borrowUse) as borrowUse
from  
(
select useruuid,max(if(borrowUse='Lainnya',0,borrowUse)) as borrowUse
from usrWorkDetail
where disabled = 0
group by useruuid
union
select useruuid,max(if(borrowUse='Lainnya',0,borrowUse)) as borrowUse
from usrStudentDetail
where disabled = 0
group by useruuid
union
select useruuid,max(if(borrowUse='Lainnya',0,borrowUse)) as borrowUse
from usrHouseWifeDetail
where disabled = 0
group by useruuid
) un
group by useruuid
) det on det.useruuid = ord.userId
) as full
group by borrowUse;


#BORROWUSE produktif
select borrowUse, sum(amountApply) from produktifOrder where date(lendingTime) between '2019-10-01' and '2019-10-31'
and disabled = 0
group by borrowUse;