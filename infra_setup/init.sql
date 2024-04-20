
-- Create schema
CREATE SCHEMA IF NOT EXISTS ALT_SCHOOL;


-- create and populate tables

-- create products table
create table if not exists ALT_SCHOOL.PRODUCTS
(
    id  serial primary key,
    name varchar not null,
    price numeric(10, 2) not null
);

-- insert data into products table
COPY ALT_SCHOOL.PRODUCTS (id, name, price)
FROM '/data/products.csv' DELIMITER ',' CSV HEADER;

-- setup customers table following the example above

-- TODO: Provide the DDL statment to create this table ALT_SCHOOL.CUSTOMERS
--create customers table
CREATE TABLE if not exists ALT_SCHOOL.CUSTOMERS
  (
     customer_id  uuid primary key,
     device_id  UUID  not null,
     location  varchar not null,
     currency  varchar  not null
  ); 

-- TODO: provide the command to copy the customers data in the /data folder into ALT_SCHOOL.CUSTOMERS
-- insert data into customers table
COPY ALT_SCHOOL.CUSTOMERS (customer_id, device_id, location,currency)
FROM '/data/customers.csv' DELIMITER ',' CSV HEADER;

-- TODO: complete the table DDL statement
create table if not exists ALT_SCHOOL.ORDERS
(
    order_id uuid primary key,
    customer_id uuid not null,
    status varchar not null,
    checked_out_at timestamp
);

-- provide the command to copy orders data into POSTGRES
-- insert data into orders table
COPY ALT_SCHOOL.ORDERS (order_id,customer_id, status, checked_out_at)
FROM '/data/orders.csv' DELIMITER ',' CSV HEADER;

create table if not exists ALT_SCHOOL.LINE_ITEMS
(
    line_item_id serial primary key,
    order_id  uuid not null,
    item_id bigint not null,
    quantity bigint not null
);

-- provide the command to copy ALT_SCHOOL.LINE_ITEMS data into POSTGRES
-- insert data into line_items table
COPY ALT_SCHOOL.LINE_ITEMS (line_item_id,order_id, item_id, quantity)
FROM '/data/line_items.csv' DELIMITER ',' CSV HEADER;

-- setup the events table following the examle provided
create table if not exists ALT_SCHOOL.EVENTS
(
    event_id bigint primary key,
    customer_id uuid not null,
    event_data JSONB not null,
    event_timestamp timestamp not null

);

-- TODO: provide the command to copy ALT_SCHOOL.EVENTS data into POSTGRES
-- insert data into events table
COPY ALT_SCHOOL.EVENTS (event_id,customer_id, event_data, event_timestamp)
FROM '/data/events.csv' DELIMITER ',' CSV HEADER;





