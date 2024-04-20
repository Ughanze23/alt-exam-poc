/*  Part 2a.1 

Q : what is the most ordered item based on the number of times it appears in an order cart that checked out successfully

How i arrived at answer to the question :
There 4 event types in the events table and they follow an order : visit > add to cart >> remove from cart >> checkout
or visit > add to cart >> checkout, lastly visit > add to cart > remove from cart > add to cart > checkout

how i got to the answer of items that got checked out successfully ?
i filtered the events table by checkout eventtype and status = success
the event data json contains order_id and when joined with the line_items table u can see all the items in attached to that order_id
*/

-- all orders that were checked out and status is success
with checkout_success as (select  * ,event_data ->> 'order_id' as order_id ,event_data ->> 'event_type' as event_type 
from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'checkout' and 
event_data ->> 'status' = 'success')

--items in successful order 
select p.id as product_id,name as product_name,count(cs.order_id) as num_times_in_successful_orders from checkout_success cs
left  join alt_school_db.alt_school.line_items li 
on li.order_id = cs.order_id :: uuid
left join alt_school.products p 
on p.id  = li.item_id 
group  by 1,2

--------------------------------------------------------------------------->

/*Part 2a.2 
Q : without considering currency, and without using the line_item table, find the top 5 spenders
  you are exxpected to return the customer_id, location, total_spend where:

How i arrived at answer to the question :

created temp table with only items added to cart in the events table
created temp table with only items removed from cart in the events table
Joined both tables on customerId and itemID
if itemID of remove_from_cart temp table is null, then item was not successfully checkedout

the checkout eventype was not considered as it only has order_id and not itemID and we are asked not to use the line_items table


*/
with add_to_cart as (
select  customer_id,event_timestamp , event_data ->> 'item_id' as item_id,event_data ->> 'quantity' as quantity,
event_data ->> 'event_type' as event_type from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'add_to_cart' 
)
,

remove_from_cart as (
select  customer_id,event_timestamp, event_data ->> 'item_id' as item_id,event_data ->> 'quantity' as quantity,
event_data ->> 'event_type' as event_type from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'remove_from_cart' 
)
,
-- successfull orders are orders where a remove from cart event did not happen
success_order as (
select customer_id, item_id,quantity
from (
select ac.customer_id,ac.item_id,ac.quantity,rc.item_id as remove_from_cart_itemID,
ac.event_timestamp, rc.event_timestamp , EXTRACT(HOUR FROM AGE(rc.event_timestamp, ac.event_timestamp)) as hour_diff
from add_to_cart ac
left join remove_from_cart rc
on rc.customer_id = ac.customer_id and rc.item_id = ac.item_id and EXTRACT(HOUR FROM AGE(rc.event_timestamp, ac.event_timestamp)) <= 24
-- assumption events related to the same order happened btw 0 -24 hours apart
-- this assumption is done based on the fact there is no order_id in the json object when event_type is add_to_cart or remove_to_cart
-- and we are not meant to use the line items table
 ) as success

where remove_from_cart_itemID is null )
,

-- get the amount spent per order : multiply product price by quantity
amt_spent_per_order as (
select sc.customer_id, item_id, quantity :: int as quantity, c.location,p.price  ,p.price*quantity :: int as  amt_spent 
from success_order sc
left join alt_school.customers c 
on c.customer_id  = sc.customer_id
left join alt_school.products p 
on p.id :: text = sc.item_id)


-- get top 5 spenders by location and amount
select customer_id ,location , sum(amt_spent) as total_spend
from amt_spent_per_order
group by 1,2
order by 3 desc
limit 5


--------------------------------------------------------------------------------------->

/*Part 2b.1 
Q : using the events table, Determine **the most common location** (country) 
where successful checkouts occurred. return `location` and `checkout_count` where:

How i arrived at answer to the question :

successful checkout is when event_type = checkout and status = success
join customer table to get location and order by the location with the most orders checkedout
*/

--successful checkout
with checkout_success as (
select  * ,event_data ->> 'order_id' as order_id ,event_data ->> 'event_type' as event_type 
from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'checkout' and 
event_data ->> 'status' = 'success')

select location,count(*) as checkout_count
from alt_school.customers c 
join checkout_success sc
on sc.customer_id = c.customer_id 
group by 1
order by 2 desc
limit 1 -- the most common location (country) where successful checkouts occurred

------------------------------------------------------------------------------------------->
/*Part 2b.2
Q:  using the events table, identify the customers who abandoned their carts and count the number of events (excluding visits) 
that occurred before the abandonment. return the `customer_id` and `num_events`
 */

--all add to cart events
with add_to_cart as (
select  customer_id,event_timestamp , event_data ->> 'item_id' as item_id,event_data ->> 'quantity' as quantity,
event_data ->> 'event_type' as event_type,1 as add_to_cart from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'add_to_cart' 
)
,
-- all remove_from_cart events
remove_from_cart as (
select  customer_id,event_timestamp, event_data ->> 'item_id' as item_id,event_data ->> 'quantity' as quantity,
event_data ->> 'event_type' as event_type, 1 AS remove_from_cart   from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'remove_from_cart' 
)
--all checkout actions
, checkout as  (select  * ,event_data ->> 'order_id' as order_id ,event_data ->> 'event_type' as event_type 
from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'checkout')

,

--orders with no checkout event
abandoned_cart as (
select  customer_id,item_id, add_to_cart,remove_from_cart
from (
-- tranpose table of remove_from_cart , add_to_cart events and checkout event
-- get orders that had no checkout event, this is where order_id is null
select ac.customer_id,ac.item_id,ac.quantity,rc.item_id as remove_from_cart_itemID,
ac.event_timestamp as add_cart_timestamp, rc.event_timestamp as remove_card_timestamp,co.event_timestamp as checkout_event_timestamp , EXTRACT(HOUR FROM AGE(rc.event_timestamp, ac.event_timestamp)) as hour_diff
,COALESCE(add_to_cart, 0) as add_to_cart,COALESCE(remove_from_cart, 0) as remove_from_cart,co.order_id from add_to_cart ac
left join remove_from_cart rc
on rc.customer_id = ac.customer_id and rc.item_id = ac.item_id
left join checkout co
on co.customer_id = ac.customer_id and EXTRACT(HOUR FROM AGE(co.event_timestamp, ac.event_timestamp)) <= 24
-- assumption : events related to the same order happened btw 0 -24 hours apart
-- this assumption is done based on the fact there is no order_id in event_type add_to_cart or remove_to_cart
)
where order_id is null
)

--identify the customers who abandoned their carts and count the number of events (excluding visits)
-- that occurred before the abandonment
select ac.customer_id , 
--item_id can be included to show unique orders.ac.item_id, 
  sum(CASE WHEN add_to_cart = 1 THEN 1 ELSE 0 END) + 
  sum(CASE WHEN remove_from_cart = 1 THEN 1 ELSE 0 END) as num_events
from abandoned_cart ac
group by 1
--,2

------------------------------------------------------------------------------------------->


/*Part 2b.3
Q : Find the average number of visits per customer, 
considering only customers who completed a checkout! return average_visits to 2 decimal place

How i arrived at answer to the question :
created a temp table summing up all visits per customer 
create a temp table of all orders checked-out successfully
counted the number of orders and grouped by customer_id

performed an innerjoin on both temp tables on customer id to get only the total visits of customer with successful total_orders  

avg  visit per order = totalvists/total_successful_orders
 */
 
-- total visits per customer
with visits as (
select customer_id, sum(visit) as total_visits
from (
select  customer_id,event_data,event_timestamp , event_data ->> 'item_id' as item_id,event_data ->> 'quantity' as quantity,
event_data ->> 'event_type' as event_type , 1 as visit
from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'visit' )
group  by 1
order by 2 desc
)

-- all customers who checked-out successfully
,checkout_success as (select customer_id, count(*) no_of_orders
from ( select customer_id
from alt_school_db.alt_school.events e 
where event_data ->> 'event_type' = 'checkout' and event_data ->> 'status' = 'success')
group by 1
order by 2 desc)

-- calculate avg visit per successfull order
select round( sum(v.total_visits)/sum(no_of_orders),2) as average_visits

from visits v
inner join  checkout_success cs
on v.customer_id = cs.customer_id
-- inner join used to select total visits of only customers with successful orders