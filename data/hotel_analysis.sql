select current_database();

DROP TABLE IF EXISTS hotel_raw;

CREATE TABLE hotel_raw (
    hotel TEXT,
    is_canceled TEXT,
    lead_time TEXT,
    arrival_date_year TEXT,
    arrival_date_month TEXT,
    arrival_date_week_number TEXT,
    arrival_date_day_of_month TEXT,
    stays_in_weekend_nights TEXT,
    stays_in_week_nights TEXT,
    adults TEXT,
    children TEXT,
    babies TEXT,
    meal TEXT,
    country TEXT,
    market_segment TEXT,
    distribution_channel TEXT,
    is_repeated_guest TEXT,
    previous_cancellations TEXT,
    previous_bookings_not_canceled TEXT,
    reserved_room_type TEXT,
    assigned_room_type TEXT,
    booking_changes TEXT,
    deposit_type TEXT,
    agent TEXT,
    company TEXT,
    days_in_waiting_list TEXT,
    customer_type TEXT,
    adr TEXT,
    required_car_parking_spaces TEXT,
    total_of_special_requests TEXT,
    reservation_status TEXT,
    reservation_status_date TEXT
);

select count(*) from hotel_raw;
select * from hotel_raw;

--no.of colms-
select count(*) as column_count
from information_schema.columns where table_name ='hotel_raw';

--Create clean table
DROP TABLE IF EXISTS hotel_clean;
CREATE TABLE hotel_clean AS
SELECT *
FROM hotel_raw;

--CHECK DATA BEFORE TOUCHING
SELECT * FROM hotel_clean LIMIT 10;

--CLEAN EMPTY VALUES
UPDATE hotel_clean
SET children = '0'
WHERE children IS NULL OR children = '';

UPDATE hotel_clean
SET adults = '0'
WHERE adults IS NULL OR adults = '';

UPDATE hotel_clean
SET babies = '0'
WHERE babies IS NULL OR babies = '';

UPDATE hotel_clean
SET lead_time = '0'
WHERE lead_time IS NULL OR lead_time = '';

UPDATE hotel_clean
SET adr = '0'
WHERE adr IS NULL OR adr = '';

--CONVERT DATA TYPES
ALTER TABLE hotel_clean
ALTER COLUMN is_canceled TYPE INT USING is_canceled::INT,
ALTER COLUMN lead_time TYPE INT USING lead_time::INT,
ALTER COLUMN arrival_date_year TYPE INT USING arrival_date_year::INT,
ALTER COLUMN stays_in_weekend_nights TYPE INT USING stays_in_weekend_nights::INT,
ALTER COLUMN stays_in_week_nights TYPE INT USING stays_in_week_nights::INT,
ALTER COLUMN adults TYPE INT USING adults::INT,
ALTER COLUMN children TYPE INT USING children::INT,
ALTER COLUMN babies TYPE INT USING babies::INT,
ALTER COLUMN adr TYPE NUMERIC USING adr::NUMERIC;

--VERIFY CLEANING
SELECT *
FROM hotel_clean
WHERE children IS NULL
   OR adults IS NULL
   OR babies IS NULL;
----  -----   ----
--CREATE USEFUL COLUMN (FEATURE ENGINEERING)
ALTER TABLE hotel_clean
ADD COLUMN total_nights INT;

update hotel_clean
 set total_nights = stays_in_weekend_nights + stays_in_week_nights;

 -------------------------
 --KPI's---
 
 SELECT 
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS cancellations,
    ROUND(SUM(is_canceled)*100.0 / COUNT(*), 2) AS cancellation_rate
FROM hotel_clean;

-----CANCELLATION ANALYSIS --
--How bad is the cancellation problem?

SELECT 
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS total_cancellations,
    ROUND(SUM(is_canceled)*100.0 / COUNT(*), 2) AS cancellation_rate
FROM hotel_clean;

--WHICH HOTEL TYPE CANCELS MORE?
select hotel,
count(*) as total,
sum(is_canceled) as cancellations,
round(sum(is_canceled)*100.0/count(*), 2) as cancel_rate
from hotel_clean
group by hotel
order by cancel_rate desc;

--MONTH-WISE BOOKING TREND
select arrival_date_month,
count(*) as bookings
from hotel_clean
group by arrival_date_month
order by bookings desc;

        --OR--
 select  
 arrival_date_year,
 arrival_date_month,
 count(*) as bookings
 from hotel_clean
 group by arrival_date_year, arrival_date_month
 order by arrival_date_year, bookings desc;

 --LEAD TIME IMPACT ON CANCELLATION
 select 
  case 
     when lead_time < 50 then 'short'
	 when lead_time between 50 and 150 then 'medium'
	 else 'long'
	 end as lead_category,
	 count(*) as  total,
	 sum(is_canceled) as cancellations,
	 round(sum(is_canceled)*100.0/count(*),2) as cancel_rate
from hotel_clean
group by lead_category
order by cancel_rate desc;
 
--CUSTOMER TYPE ANALYSIS
SELECT 
    customer_type,
    COUNT(*) AS total,
    ROUND(AVG(adr),2) AS avg_price,
    ROUND(SUM(is_canceled)*100.0 / COUNT(*), 2) AS cancel_rate
FROM hotel_clean
GROUP BY customer_type
ORDER BY avg_price DESC;

--MARKET SEGMENT PERFORMANCE
select market_segment,
count(*) as total,
round(avg(adr),2) as avg_revenue,
round(sum(is_canceled)*100.0/count(*),2) as cancel_rate
from hotel_clean
group by market_segment
order by avg_revenue desc;

--ROOM TYPE MISMATCH
select count(*) as total,
 sum( case 
     when reserved_room_type != assigned_room_type then 1
	 else 0
	 end) as mismatches
	 from hotel_clean;

--PARKING DEMAND ANALYSIS
select  required_car_parking_spaces,
  count(*) as bookings
from hotel_clean
group by required_car_parking_spaces
order by bookings desc;

--SPECIAL REQUEST IMPACT
 select total_of_special_requests,
  count(*) as total,
  round(sum(is_canceled)*100.0/count(*),2) as cancel_rate
  from hotel_clean
group by total_of_special_requests
order by total_of_special_requests;

select * from hotel_clean
-------------------------------------------------------------------	 