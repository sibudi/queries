use doit_reporting;

SET @startDay = date_format(now(), '%Y-%m-01');
SET @endDay = date(now());
SET @monday = date(curdate() - interval weekday(curdate()) day);
SET @sunday = @monday + interval 6 day;
#SET @startDay = '2019-10-01';
#SET @endDay = '2019-12-31';

#Sheet D30+
#1. D30+ by team
select
tim,
coalesce(userName, 'Unassigned'),
coalesce(sum(D90),0) + coalesce(sum(NPL),0) as total,
coalesce(sum(D90),0),
coalesce(sum(NPL),0),
coalesce(sum(selisih),0),
coalesce(sum(money),0),
#coalesce(sum(coupon1),0),
#coalesce(sum(coupon2),0),
coalesce(sum(today1),0),
coalesce(sum(today2),0),
coalesce(sum(thisweek1),0),
coalesce(sum(thisweek2),0)
from
(select bb.userName, tim, D90, NPL, if(D90 + NPL - pokok < 0, 0, D90 + NPL - pokok) as selisih, today1, today2, money, coupon1, coupon2, thisweek1, thisweek2
from
(select id, userName from manUser where #disabled = 0 and status = 0 and
id in (393,468,159,428,673,201,67, #Ahmad Firdaus
52,599,272, #Dendi
368,122,355,195,781,343,69, #Robby Adi
347,981,464 #Tuta
)
) as bb
left join
(select userName, pokok, money,
case when outsourceId in (393,468,159,428,673,201,67) then 'Ahmad Firdaus'
when outsourceId in (52,599,272) then 'Dendi'
when outsourceId in (368,122,355,195,781,343,69) then 'Robby Adi'
when outsourceId in (347,981,464) then 'Tuta'
else 'Nasabah Baik' end as tim,
case when datediff(actualRefundTime,refundTime) between 31 and 90 then money else 0 end as coupon1,
case when datediff(actualRefundTime,refundTime) > 90 then money else 0 end as coupon2,
case when date(actualRefundTime) = date(now()) and datediff(actualRefundTime,refundTime) between 31 and 90 then repay else 0 end as today1,
case when date(actualRefundTime) = date(now()) and datediff(actualRefundTime,refundTime) > 90 then repay else 0 end as today2,
case when datediff(actualRefundTime,refundTime) between 31 and 90 then repay else 0 end as D90,
case when datediff(actualRefundTime,refundTime) > 90 then repay else 0 end as NPL,
case when date(actualRefundTime) between @monday and @sunday and datediff(actualRefundTime,refundTime) between 31 and 90 then repay else 0 end as thisweek1,
case when date(actualRefundTime) between @monday and @sunday and datediff(actualRefundTime,refundTime) > 90 then repay else 0 end as thisweek2
from
(select uuid, uuid as billId, uuid as payId, amountApply as pokok, orderType, 0 as billTerm, actualRefundTime, refundTime
from ordOrder where disabled = 0 
and orderType in (0,2,1)
and date(actualRefundTime) between @startDay and @endDay
and datediff(actualRefundTime, refundTime) > 30
union
select orderNo as uuid, uuid as billId, uuid as payId, billAmout as pokok, 3 as orderType, billTerm, actualRefundTime, refundTime
from ordBill
where disabled = 0 and date(actualRefundTime) between @startDay and @endDay
and datediff(actualRefundTime, refundTime) > 30
union
select a.orderNo as uuid, a.uuid as billId, a.orderNo as payId, a.billAmout as pokok, 3 as orderType, a.billTerm, c.actualRefundTime, a.refundTime
from ordBill as a inner join ordOrder as c
on a.orderNo = c.uuid and a.disabled = 0 and c.disabled = 0
and a.status in (1,2) and a.billTerm = 3 and a.actualRefundTime is null
and date(c.actualRefundTime) between @startDay and @endDay
and datediff(c.actualRefundTime, a.refundTime) > 30
) as a
	inner join (select a.orderUUID, a.assignedTime, a.outsourceId from collectionOrderDetail as a
			inner join (select max(assignedTime) as assignedTime, orderUUID from collectionOrderDetail where disabled = 0
			group by orderUUID) as b
			on a.orderUUID = b.orderUUID
			and a.assignedTime = b.assignedTime
            and a.disabled = 0
            and a.outsourceId in 
            (393,468,159,428,673,201,67, #Ahmad Firdaus
			52,599,272, #Dendi
			368,122,355,195,781,343,69, #Robby Adi
			347,981,464) #Tuta)
			) as bb
		on a.uuid = bb.orderUUID
			left join (select distinct id, userName from manUser where disabled = 0 and status = 0) as c
		on bb.outsourceId = c.id
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
		on repay.EXTERNAL_ID = a.payId
			left join (select orderNo, max(money) as money from couponRecord where disabled = 0 and status = 1 group by orderNo) as m
            on m.orderNo = a.payId
) full
on bb.userName = full.userName
) fuller
group by userName order by tim desc;


#2. D30+ Unassigned/Nasabah Baik
select
'Nasabah Baik',
coalesce(userName, 'Unassigned') as kolektor,
coalesce(sum(D90),0) + coalesce(sum(NPL),0),
coalesce(sum(D90),0),
coalesce(sum(NPL),0),
coalesce(sum(selisih),0),
coalesce(sum(money),0),
#coalesce(sum(coupon1),0),
#coalesce(sum(coupon2),0),
coalesce(sum(today1),0),
coalesce(sum(today2),0),
coalesce(sum(thisweek1),0),
coalesce(sum(thisweek2),0)
from
(select userName, D90, NPL, if(D90 + NPL - pokok < 0, 0, D90 + NPL - pokok) as selisih, today1, today2, money, coupon1, coupon2, thisweek1, thisweek2
from
(select userName, pokok, money,
case when datediff(actualRefundTime,refundTime) between 31 and 90 then money else 0 end as coupon1,
case when datediff(actualRefundTime,refundTime) > 90 then money else 0 end as coupon2,
case when date(actualRefundTime) = date(now()) and datediff(actualRefundTime,refundTime) between 31 and 90 then repay else 0 end as today1,
case when date(actualRefundTime) = date(now()) and datediff(actualRefundTime,refundTime) > 90 then repay else 0 end as today2,
case when datediff(actualRefundTime,refundTime) between 31 and 90 then repay else 0 end as D90,
case when datediff(actualRefundTime,refundTime) > 90 then repay else 0 end as NPL,
case when date(actualRefundTime) between @monday and @sunday and datediff(actualRefundTime,refundTime) between 31 and 90 then repay else 0 end as thisweek1,
case when date(actualRefundTime) between @monday and @sunday and datediff(actualRefundTime,refundTime) > 90 then repay else 0 end as thisweek2
from
(select uuid, uuid as billId, uuid as payId, amountApply as pokok, orderType, 0 as billTerm, actualRefundTime, refundTime
from ordOrder where disabled = 0 
and orderType in (0,2,1)
and date(actualRefundTime) between @startDay and @endDay
and datediff(actualRefundTime, refundTime) > 30
union
select orderNo as uuid, uuid as billId, uuid as payId, billAmout as pokok, 3 as orderType, billTerm, actualRefundTime, refundTime
from ordBill
where disabled = 0 and date(actualRefundTime) between @startDay and @endDay
and datediff(actualRefundTime, refundTime) > 30
union
select a.orderNo as uuid, a.uuid as billId, a.orderNo as payId, a.billAmout as pokok, 3 as orderType, a.billTerm, c.actualRefundTime, a.refundTime
from ordBill as a inner join ordOrder as c
on a.orderNo = c.uuid and a.disabled = 0 and c.disabled = 0
and a.status in (1,2) and a.billTerm = 3 and a.actualRefundTime is null
and date(c.actualRefundTime) between @startDay and @endDay
and datediff(c.actualRefundTime, a.refundTime) > 30
) as a
	left join (select a.orderUUID, a.assignedTime, a.outsourceId from collectionOrderDetail as a
			inner join (select max(assignedTime) as assignedTime, orderUUID from collectionOrderDetail where disabled = 0
			group by orderUUID) as b
			on a.orderUUID = b.orderUUID
			and a.assignedTime = b.assignedTime
            and a.disabled = 0
            and a.outsourceId != 0 and a.outsourceId is not null) as bb
		on a.uuid = bb.orderUUID
			left join (select distinct id, userName from manUser where disabled = 0 and status = 0) as c
		on bb.outsourceId = c.id
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
		on repay.EXTERNAL_ID = a.payId
			left join (select orderNo, max(money) as money from couponRecord where disabled = 0 and status = 1 group by orderNo) as m
            on m.orderNo = a.payId
) full
) fuller
where userName is null
group by userName;



#Sheet Repaid Orders List
SET @startDay = date_format(now(), '%Y-%m-01');
SET @endDay = date(now());
#SET @startDay = '2019-10-01';
#SET @endDay = '2019-12-31';

select coalesce(userName,'Unassigned'), uuid, terbayarkan, if(terbayarkan - pokok < 0, 0, terbayarkan - pokok) as selisih, date(actualRefundTime), tipe
from
(select userName, uuid, pokok, actualRefundTime,
repay as terbayarkan,
case
when datediff(actualRefundTime, refundTime) < 0 then 'D-'
when datediff(actualRefundTime, refundTime) = 0 then 'D0'
when datediff(actualRefundTime, refundTime) between 1 and 7 then 'D1-7'
when datediff(actualRefundTime, refundTime) between 8 and 30 then 'D8-30'
when datediff(actualRefundTime, refundTime) between 31 and 90 then 'D31-90'
else 'D90+' end as tipe
from 
(select uuid, uuid as billId, uuid as payId, amountApply as pokok, actualRefundTime, refundTime, orderType, 0 as billTerm
from ordOrder where disabled = 0 
and orderType in (0,2,1) and date(actualRefundTime) between @startDay and @endDay
union
select orderNo as uuid, uuid as billId, uuid as payId, billAmout as pokok, actualRefundTime, refundTime, 3 as orderType, billTerm
from ordBill where disabled = 0
and date(actualRefundTime) between @startDay and @endDay
union
select a.orderNo as uuid, a.uuid as billId, a.orderNo as payId, a.billAmout,
coalesce(a.actualRefundTime, c.actualRefundTime) as actualRefundTime,
a.refundTime as refundTime, 3 as orderType, a.billTerm as billTerm
from ordBill as a
	inner join ordOrder as c
	on a.orderNo = c.uuid and c.disabled = 0 and c.orderType = 3
    and a.disabled = 0 and a.billTerm = 3 and a.status in (1,2)
    and date(c.actualRefundTime) between @startDay and @endDay
) as a
	left join (select a.orderUUID, a.assignedTime, a.outsourceId from collectionOrderDetail as a
			inner join (select max(assignedTime) as assignedTime, orderUUID from collectionOrderDetail where disabled = 0
			group by orderUUID) as b
			on a.orderUUID = b.orderUUID
			and a.assignedTime = b.assignedTime
            and a.outsourceId != 0 and a.outsourceId is not null and a.disabled = 0) as bb
		on a.uuid = bb.orderUUID
			left join (select distinct Id, userName from manUser) as c
		on bb.outsourceId = c.id
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
		on repay.EXTERNAL_ID = a.payId
) full
order by userName;



#Sheet Daily Repayment Overview
select date(actualRefundTime), tipe, sum(terbayarkan)
from
(select actualRefundTime,
repay as terbayarkan,
case
when datediff(actualRefundTime, refundTime) < 0 then 'D-'
when datediff(actualRefundTime, refundTime) = 0 then 'D0'
when datediff(actualRefundTime, refundTime) between 1 and 7 then 'D1-7'
when datediff(actualRefundTime, refundTime) between 8 and 30 then 'D8-30'
when datediff(actualRefundTime, refundTime) between 31 and 90 then 'D31-90'
#when datediff(actualRefundTime, refundTime) between 31 and 60 then 'D31-60'
#when datediff(actualRefundTime, refundTime) between 61 and 90 then 'D61-90'
#when datediff(actualRefundTime, refundTime) between 91 and 180 then 'D91-180'
#when datediff(actualRefundTime, refundTime) between 181 and 270 then 'D181-270'
#when datediff(actualRefundTime, refundTime) between 271 and 360 then 'D271-360'
#when datediff(actualRefundTime, refundTime) > 360 then 'D360+'
else 'D90+' end as tipe
from
(select uuid, uuid as billId, uuid as payId, actualRefundTime, refundTime, orderType, 0 as billTerm from ordOrder where disabled = 0 
and orderType in (0,2,1) and date(actualRefundTime) between @startDay and @endDay
union
select orderNo as uuid, uuid as billId, uuid as payId, actualRefundTime, refundTime, 3 as orderType, billTerm from ordBill
where disabled = 0
and date(actualRefundTime) between @startDay and @endDay
union
select a.orderNo as uuid, a.uuid as billId, a.orderNo as payId, c.actualRefundTime,
a.refundTime as refundTime, 3 as orderType, a.billTerm as billTerm from ordBill as a 
	inner join ordOrder as c
	on a.orderNo = c.uuid and c.disabled = 0 and c.orderType = 3
	and a.disabled = 0 and a.billTerm = 3 and a.status in (1,2)
	and date(c.actualRefundTime) between @startDay and @endDay
) as a
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
		on repay.EXTERNAL_ID = a.payId
) full
group by date(actualRefundTime), tipe
order by date(actualRefundTime);



#Sheet Performance Development
SET @startDay = date_format(now(), '%Y-%m-01');
SET @endDay = date_format(last_day(now()), '%Y-%m-%d');
SET @now = date(now());
#SET @startDay = '2020-01-01';
#SET @endDay = '2020-01-31';
set @i = -1;

#1. Monthly Disbursement Detail
select date, count(uuid), sum(amountApply) from
(select DATE(ADDDATE(@startDay, INTERVAL @i:=@i+1 DAY)) AS date FROM ordOrder
HAVING @i < DATEDIFF(@now, @startDay)) as a
left join
(select date(lendingTime) as lending, uuid, amountApply from ordOrder
where disabled = 0
and date(lendingTime) between @startDay and @endDay
and orderType in (0,2,3)
and status in (7,8,10,11)) as b
on a.date = b.lending
group by date
order by date asc;

#2. Monthly Outstanding/Overdue Rate
select
date(refundTime),
count(uuid),
sum(amount),
count(sebelum),
coalesce(sum(duluan),0),
count(bayar),
coalesce(sum(terbayarkan),0)
from
(select refundTime, uuid, a.amount,
case
when date(actualRefundTime) = date(refundTime) then a.uuid
end as bayar,
case
when date(actualRefundTime) < date(refundTime) then a.uuid
end as sebelum,
case
when date(actualRefundTime) < date(refundTime) then repay
else 0 end as duluan,
case
when date(actualRefundTime) = date(refundTime) then repay
else 0 end as terbayarkan
from
(select uuid, uuid as billId, uuid as payId, amountApply as amount, orderType, 0 as billTerm, refundTime, actualRefundTime from ordOrder where disabled = 0
and orderType in (0,1,2) and status in (7,8,10,11) and date(refundTime) between @startDay and @endDay
	union
select orderNo as uuid, uuid as billId, uuid as payId, billAmout as amount, 3 as orderType, billTerm, refundTime, actualRefundTime
from ordBill
where disabled = 0 and billTerm in (1,2)
and date(refundTime) between @startDay and @endDay
	union
select a.orderNo as uuid, a.uuid as billId, 
case when a.actualRefundTime is null and c.actualRefundTime is not null then a.orderNo else a.uuid end as payId,
a.billAmout as amount, 3 as orderType, a.billTerm, a.refundTime, coalesce(a.actualRefundTime, c.actualRefundTime)
from ordBill as a 
	inner join (select uuid, actualRefundTime from ordOrder where disabled = 0 and orderType = 3
    and status in (7,8,10,11) ) as c on a.orderNo = c.uuid
and date(a.refundTime) between @startDay and @endDay
and a.billTerm = 3 and a.disabled = 0
) as a
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
		on repay.EXTERNAL_ID = a.payId
) as fulll
group by date(a.refundTime)
order by date(a.refundTime) asc;

#3. Monthly Outstanding/Overdue Rate Development
select
date(refundTime),
count(uuid),
count(bayar),
(count(uuid) - count(bayar)) / count(uuid),
sum(amount),
coalesce(sum(terbayarkan),0),
(sum(amount) - coalesce(sum(terbayarkan),0)) / sum(amount)
from
(select refundTime, uuid, a.amount,
case
when actualRefundTime is not null then a.uuid
end as bayar,
case
when actualRefundTime is not null then repay
else 0 end as terbayarkan
from
(select uuid, uuid as billId, uuid as payId, amountApply as amount, orderType, 0 as billTerm, refundTime, actualRefundTime from ordOrder where disabled = 0
and orderType in (0,1,2) and status in (7,8,10,11) and date(refundTime) between @startDay and @endDay
union
select orderNo as uuid, uuid as billId, uuid as payId, billAmout as amount, 3 as orderType, billTerm, refundTime, actualRefundTime
from ordBill
where disabled = 0 and billTerm in (1,2)
and date(refundTime) between @startDay and @endDay
union
select a.orderNo as uuid, a.uuid as billId, 
case when a.actualRefundTime is null and c.actualRefundTime is not null then a.orderNo else a.uuid end as payId,
a.billAmout as amount, 3 as orderType, a.billTerm, a.refundTime, coalesce(a.actualRefundTime, c.actualRefundTime)
from ordBill as a 
	inner join (select uuid, actualRefundTime from ordOrder where disabled = 0 and orderType = 3
    and status in (7,8,10,11) ) as c on a.orderNo = c.uuid
and date(a.refundTime) between @startDay and @endDay
and a.billTerm = 3 and a.disabled = 0
) as a
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
		on repay.EXTERNAL_ID = a.payId
) as fulll
group by date(a.refundTime)
order by date(a.refundTime) asc;



#4. Grouped Overdue Rate Table
SET @startDay = '2020-01-01';
SET @endDay = date(now());
select
date(refundTime),
count(D1)/count(uuid),
count(D7)/count(uuid),
count(D15)/count(uuid),
count(D30)/count(uuid),
count(uuid)
from
(select refundTime, uuid,
case
when ((actualRefundTime is null and datediff(@endDay, refundTime) >=1)
OR datediff(actualRefundTime, refundTime) >= 1) then a.uuid
end as D1,
case
when ((actualRefundTime is null and datediff(@endDay, refundTime) >=7)
OR datediff(actualRefundTime, refundTime) >= 7) then a.uuid
end as D7,
case
when ((actualRefundTime is null and datediff(@endDay, refundTime) >=15)
OR datediff(actualRefundTime, refundTime) >= 15) then a.uuid
end as D15,
case
when ((actualRefundTime is null and datediff(@endDay, refundTime) >=30)
OR datediff(actualRefundTime, refundTime) >= 30) then a.uuid
end as D30
from
(select uuid, uuid as billId, uuid as payId, amountApply as amount, orderType, 0 as billTerm, refundTime, actualRefundTime from ordOrder where disabled = 0
and orderType in (0,1,2) and status in (7,8,10,11) and date(refundTime) between @startDay and @endDay
union
select orderNo as uuid, uuid as billId, uuid as payId, billAmout as amount, 3 as orderType, billTerm, refundTime, actualRefundTime
from ordBill
where disabled = 0 and billTerm in (1,2)
and date(refundTime) between @startDay and @endDay
union
select a.orderNo as uuid, a.uuid as billId, 
case when a.actualRefundTime is null and c.actualRefundTime is not null then a.orderNo else a.uuid end as payId,
a.billAmout as amount, 3 as orderType, a.billTerm, a.refundTime, coalesce(a.actualRefundTime, c.actualRefundTime)
from ordBill as a 
	inner join (select uuid, actualRefundTime from ordOrder where disabled = 0 and orderType = 3
    and status in (7,8,10,11) ) as c on a.orderNo = c.uuid
and date(a.refundTime) between @startDay and @endDay
and a.billTerm = 3 and a.disabled = 0
) as a
) as fulll
group by date(a.refundTime)
order by date(a.refundTime) asc;