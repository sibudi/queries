#Collector Daily Calling Performance
select coalesce(date(createTime), 'Hari ini belum') , userName, tim, count(distinct orderNo), count(orderNo),
rata2Distinct, rata2,
count(distinct sepuluh), count(sepuluh),
count(distinct sebelas), count(sebelas),
count(distinct duabelas), count(duabelas),
count(distinct satu), count(satu),
count(distinct dua), count(dua),
count(distinct tiga), count(tiga),
count(distinct empat), count(empat),
count(distinct lima), count(lima),
count(distinct enam), count(enam)
from
(select a.createTime, userName, a.orderNo, rata2, rata2Distinct,
case when (jam = 08 or jam = 09) then a.orderNo end as sepuluh,
case when jam = 10 then a.orderNo end as sebelas,
case when jam = 11 then a.orderNo end as duabelas,
case when jam = 12 then a.orderNo end as satu,
case when jam = 01 then a.orderNo end as dua,
case when jam = 02 then a.orderNo end as tiga,
case when jam = 03 then a.orderNo end as empat,
case when jam = 04 then a.orderNo end as lima,
case when (jam = 05 or jam = 06) then a.orderNo end as enam,
case when id in (52,599,272) then 'Dendi'
when id in (347,981,464) then 'Tuta'
when id in (393,159) then 'Ahmad Firdaus'
when id in (368,122,355,195,781,343,69) then 'Robby Ady'
end as tim
from
(select id, userName from manUser
where id in
(52,599,272, #Dendi 
347,981,464, #Tuta
393,159, #AhmadFirdaus
368,122,355,195,781,343,69)#Robby Ady
) as bb
	left join
(select createTime, time_format(createTime, '%h') as jam, createUser, orderNo, remark from manCollectionRemark
where disabled = 0
and date(createTime) = date(now())
) as a
on bb.id = a.createUser
left join
(select createUser, round(count(orderNo)/count(distinct date(createTime))) as rata2,
round(count(distinct orderNo)/count(distinct date(createTime))) as rata2Distinct
from manCollectionRemark where disabled = 0 and contactMode in (1,2,3)
and date(createTime) between (date(now()) - interval 7 day) and (date(now()) - interval 1 day)
group by createUser) as k
on bb.id = k.createUser
) as full
group by date(createTime), userName, tim
order by count(distinct orderNo) desc;


#Assigned Oustandings Follow Up Update
select a.uuid, 
case
when orderType = 0 then 'Normal'
when orderType = 1 then 'Sudah Extension'
else 'Cicilan'
end as tipeOrder,
case 
when orderType in (0,1) then amountApply
when orderType in (3) and termin = 1 then amountApply/3
when orderType in (3) and termin = 2 then amountApply/3*2
else amountApply
end as AMOUNT,
case when orderType in (0,1) then 1
else termin
end as Termin,
realName,
date(refundTime),
datediff(now(),refundTime) as telat,
case
when datediff(now(),refundTime) < 0 then 'D-'
when datediff(now(),refundTime) = 0 then 'D0'
when datediff(now(),refundTime) between 1 and 30 then 'D1-30'
when datediff(now(),refundTime) between 31 and 60 then 'D31-60'
when datediff(now(),refundTime) between 61 and 90 then 'D61-90'
when datediff(now(),refundTime) > 90 then 'D90+'
end as kategori,
case
when aa.outsourceId in (52,599,272) then 'Dendi'
when aa.outsourceId in (347,981,464) then 'Tuta'
when aa.outsourceId in (393,468,159,428,673,201,67,861) then 'Ahmad Firdaus'
when aa.outsourceId in (368,122,355,195,781,343,69) then 'Robby'
when aa.outsourceId is null then 'Last Collector Resigned'
else 'No Team' end as TEAM,
coalesce(bb.userName,'Unassigned'),
coalesce(date(aa.assignedTime),'Unassigned'),
berapaWA, f.lastt, waCollector,
case
when f.contactResult = 0 then 'Telepon - Collector tidak mengisi'
when f.contactResult = 1 then 'Telepon - Tersambung, janji bayar'
when f.contactResult = 2 then 'Telepon - Tersambung, ingkar janji'
when f.contactResult = 3 then 'Telepon - Nomor Salah'
when f.contactResult = 4 then 'Telepon - Reject'
when f.contactResult = 5 then 'Telepon - Tidak dijawab, sedang dalam panggilan'
when f.contactResult = 6 then 'Telepon - Tidak aktif'
when f.contactResult = 7 then 'Telepon - Dialihkan'
when f.contactResult = 8 then 'Telepon - Lainnya'
when f.contactResult = 9 then 'WA - Tidak ada WA'
when f.contactResult = 10 then 'WA - Sudah terkirim, belum dibaca'
when f.contactResult = 11 then 'WA - Sudah dibaca, tidak dibalas'
when f.contactResult = 12 then 'WA - Sudah dibaca, ingkar janji'
when f.contactResult = 13 then 'WA - Sudah dibaca, janji bayar'
when f.contactResult = 14 then 'WA - Protected'
when f.contactResult = 15 then 'WA - Lainnya'
when f.contactResult = 16 then 'Lainnya - Sudah terkirim, belum dibalas'
when f.contactResult = 17 then 'Lainnya - Sudah terkirim, janji bayar'
when f.contactResult = 18 then 'Lainnya - Sudah terkirim, ingkar janji'
when f.contactResult = 19 then 'Lainnya - Tidak terkirim'
when f.contactResult = 20 then 'Lainnya - Gagal terkirim'
when f.contactResult = 21 then 'EC - Lainnya'
when f.contactResult = 22 then 'EC - Mohon catat secara rinci untuk cara menghubungi nasabah melalui media apa'
when f.contactResult = 23 then 'EC - Tersambung, bersedia dititipi pesan'
when f.contactResult = 24 then 'EC - Tersambung, tidak bersedia dititipi pesan'
when f.contactResult = 25 then 'EC - Tersambung, tidak kenal/sudah resign/tidak ada orang ini'
else 'No Info'
end as remarks,
f.remark,
berapaPHONE, h.lastt, tlpCollector,
case
when h.contactResult = 0 then 'Telepon - Collector tidak mengisi'
when h.contactResult = 1 then 'Telepon - Tersambung, janji bayar'
when h.contactResult = 2 then 'Telepon - Tersambung, ingkar janji'
when h.contactResult = 3 then 'Telepon - Nomor Salah'
when h.contactResult = 4 then 'Telepon - Reject'
when h.contactResult = 5 then 'Telepon - Tidak dijawab, sedang dalam panggilan'
when h.contactResult = 6 then 'Telepon - Tidak aktif'
when h.contactResult = 7 then 'Telepon - Dialihkan'
when h.contactResult = 8 then 'Telepon - Lainnya'
when h.contactResult = 9 then 'WA - Tidak ada WA'
when h.contactResult = 10 then 'WA - Sudah terkirim, belum dibaca'
when h.contactResult = 11 then 'WA - Sudah dibaca, tidak dibalas'
when h.contactResult = 12 then 'WA - Sudah dibaca, ingkar janji'
when h.contactResult = 13 then 'WA - Sudah dibaca, janji bayar'
when h.contactResult = 14 then 'WA - Protected'
when h.contactResult = 15 then 'WA - Lainnya'
when h.contactResult = 16 then 'Lainnya - Sudah terkirim, belum dibalas'
when h.contactResult = 17 then 'Lainnya - Sudah terkirim, janji bayar'
when h.contactResult = 18 then 'Lainnya - Sudah terkirim, ingkar janji'
when h.contactResult = 19 then 'Lainnya - Tidak terkirim'
when h.contactResult = 20 then 'Lainnya - Gagal terkirim'
when h.contactResult = 21 then 'EC - Lainnya'
when h.contactResult = 22 then 'EC - Mohon catat secara rinci untuk cara menghubungi nasabah melalui media apa'
when h.contactResult = 23 then 'EC - Tersambung, bersedia dititipi pesan'
when h.contactResult = 24 then 'EC - Tersambung, tidak bersedia dititipi pesan'
when h.contactResult = 25 then 'EC - Tersambung, tidak kenal/sudah resign/tidak ada orang ini'
else 'No Info'
end as remarkss,
h.remark,
a.userUuid
from
(select uuid, userUuid, orderType, amountApply, refundTime from ordOrder where disabled = 0 and orderType in (0,1,3)
and status in (7,8) and actualRefundTime is null) as a
	#left join
    inner join
    (select a.orderUUID, a.assignedTime, a.outsourceId from collectionOrderDetail as a
    inner join (select orderUUID, max(assignedTime) as assignedTime from collectionOrderDetail where disabled = 0
    and outsourceId is not null group by orderUUID) as b
    on a.orderUUID = b.orderUUID and a.assignedTime = b.assignedTime
    and a.outsourceId != 0) as aa
    on a.uuid = aa.orderUUID
		left join (select distinct id, userName from manUser where disabled = 0 and status = 0) as bb
        on aa.outsourceId = bb.id
				left join (select uuid, realName from usrUser) as e
				on a.userUuid = e.uuid
            left join
            (select a.orderNo, a.remark, a.createTime as lastt,
            a.contactResult, c.userName as waCollector, berapaWA
            from manCollectionRemark as a
            inner join (select orderNo, max(id) as id, count(orderNo) as berapaWA from manCollectionRemark where disabled = 0
            and contactMode in (1) group by orderNo) as b
            on a.orderNo = b.orderNo and a.id = b.id
            left join (select distinct id, userName from manUser where disabled = 0 and status = 0) as c
            on a.createUser = c.id
            ) as f
            on a.uuid = f.orderNo
				left join
            (select a.orderNo, a.remark, a.createTime as lastt,
            a.contactResult, c.userName as tlpCollector, berapaPHONE
            from manCollectionRemark as a
            inner join (select orderNo, max(id) as id, count(orderNo) as berapaPHONE from manCollectionRemark where disabled = 0
            and contactMode in (2) group by orderNo) as b
            on a.orderNo = b.orderNo and a.id = b.id
            left join (select distinct id, userName from manUser where disabled = 0 and status = 0) as c
            on a.createUser = c.id
            ) as h
            on a.uuid = h.orderNo
				left join
                (select orderNo, count(orderNo) as termin from ordBill where disabled = 0 and status in (1,2)
                and actualRefundTime is null group by orderNo) as g
                on a.uuid = g.orderNo
;