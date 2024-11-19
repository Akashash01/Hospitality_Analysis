-- Data Transformation
use hospitality_analysis ;

update fact_bookings
set booking_date = str_to_date(booking_date, '%Y-%m-%d');

ALTER TABLE fact_bookings
modify column booking_date date;

update fact_bookings
set check_in_date = str_to_date(check_in_date, '%Y-%m-%d');

ALTER TABLE fact_bookings
modify column check_in_date date;

update fact_bookings
set checkout_date = str_to_date(checkout_date, '%Y-%m-%d');

ALTER TABLE fact_bookings
modify column checkout_date date;

update fact_bookings
set ratings_given = 0
where ratings_given = '' ;

alter table fact_bookings
modify column ratings_given int;

update fact_aggregated_bookings
set check_in_date = str_to_date(check_in_date, '%d-%m-%Y');
alter table fact_aggregated_bookings
modify column check_in_date date;
---------------------------------------------------------------------------------------------------------------------
-- Primary Key Metrics for Data analysis
-- Total Revenue Generated
select concat(round(sum(revenue_generated)/1000000, 1), 'M') as Total_revenue
from fact_bookings;

-- Total Actual Revenue Generated
select concat(round(sum(revenue_realized)/1000000, 1), 'M') as Total_Actual_revenue
from fact_bookings;

-- Total Revenue loss due to Cancellation
select concat(round((concat(round(sum(revenue_generated)/1000000, 1), 'M') - concat(round(sum(revenue_realized)/1000000, 1), 'M')),1), 'M') as Revenue_loss
from fact_bookings;

-- Total Booking
select count(booking_id) as Total_booking
from fact_bookings;

-- Total Booking based on category
select count(booking_id) as Total_booking, room_category
from fact_bookings
group by room_category;

-- Total rooms capacity
select sum(capacity) as Total_capacity
from fact_aggregated_bookings;

-- Total rooms capacity based on Properties
select sum(capacity) as Total_capacity, property_id
from fact_aggregated_bookings
group by property_id;

-- Total rooms oocupied based on Properties
select property_id,sum(successful_bookings) as Total_occupied
from fact_aggregated_bookings
group by property_id;

-- Total occupied % 
select property_id,sum(capacity) as Total_capacity,sum(successful_bookings) as Total_occupied,
	concat(round((sum(successful_bookings) / sum(capacity)) * 100 ,1), '%') as occupied
from fact_aggregated_bookings
group by property_id;

select room_category,sum(capacity) as Total_capacity,sum(successful_bookings) as Total_occupied,
	concat(round((sum(successful_bookings) / sum(capacity)) * 100 ,1), '%') as occupied
from fact_aggregated_bookings
group by room_category;

-- Average Ratings
select property_id, avg(ratings_given) as Avg_ratings
from fact_bookings
group by property_id;

select room_category, avg(ratings_given) as Avg_ratings
from fact_bookings
group by room_category;

select avg(ratings_given) as Avg_ratings
from fact_bookings;

-- Cancelled bookings
select count(booking_status) as Total_cancelled
from fact_bookings
where booking_status = 'Cancelled';

select room_category, count(booking_status) as Total_cancelled
from fact_bookings
where booking_status = 'Cancelled'
group by room_category;

select property_id, count(booking_status) as total_cancelled
from fact_bookings
where booking_status = 'Cancelled'
group by property_id;

select room_category,count(booking_id) as total_booking, count(case when booking_status = 'Cancelled' then 1 end) as total_cancellation
from fact_bookings
group by room_category;

-- Total Checkout
select property_id, count(booking_status) as total_checkout
from fact_bookings
where booking_status = 'Checked Out'
group by property_id;

select room_category, count(booking_status) as total_checkout
from fact_bookings
where booking_status = 'Checked Out'
group by room_category;

select room_category,count(booking_id) as total_booking, count(case when booking_status = 'Checked Out' then 1 end) as total_cancellation
from fact_bookings
group by room_category;

-- Total no show
select property_id, count(booking_status) as total_noshow
from fact_bookings
where booking_status = 'No Show'
group by property_id;

select room_category, count(booking_status) as total_noshow
from fact_bookings
where booking_status = 'No Show'
group by room_category;

-- Total no show %
select room_category,count(booking_id) as total_booking, 
count(case when booking_status = 'No Show' then 1 end) as total_noshow,
(count(case when booking_status = 'No Show' then 1 end)/count(booking_id))*100 as total_percent
from fact_bookings
group by room_category;

-- Booking Platform
select booking_platform, count(booking_id) as total_booking
from fact_bookings
group by booking_platform
order by total_booking;

-- Avg Revenue per booking
select room_category, (sum(revenue_generated)/count(booking_id)) as Revenue_rate
from fact_bookings
group by room_category;

-- Daily Booking rate
select booking_date, count(booking_id) as Total_booking
from fact_bookings
group by booking_date
order by booking_date;

-- Daily ocuupied rooms
select check_in_date, sum(successful_bookings) as total_occupied
from fact_aggregated_bookings
group by check_in_date
order by check_in_date asc;

-- Top 10
select check_in_date, sum(successful_bookings) as total_occupied
from fact_aggregated_bookings
group by check_in_date
order by total_occupied desc
limit 10;

-- weekly bookings
select `week no`, sum(successful_bookings) as total_occupied
from fact_aggregated_bookings
join dim_date
on fact_aggregated_bookings.check_in_date = dim_date.`date`
group by `week no`
order by total_occupied desc;

-- running total
select check_in_date, successful_bookings, sum(successful_bookings) over (order by `check_in_date`) as total_occupied
from fact_aggregated_bookings
order by check_in_date ;

-- Wow%
with weekly_booking as (
		select week(check_in_date) as weeks, count(booking_id) as total
        from fact_bookings
        group by week(check_in_date))
   select weeks, total as current_total_bookings, lag(total, 1 , 0) over (order by weeks) as previous_total_booking,
   round(((total - lag(total, 1 , 0) over (order by weeks)) / lag(total, 1 , 0) over (order by weeks)) * 100 ,2) as wow_rate
   from weekly_booking 
   order by weeks;
