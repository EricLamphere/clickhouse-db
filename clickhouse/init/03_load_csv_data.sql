-- Load data from CSV files
-- These files are mounted in the user_files directory

INSERT INTO staging.customers
SELECT *
FROM file('customers.csv', 'CSVWithNames');

INSERT INTO staging.products
SELECT *
FROM file('products.csv', 'CSVWithNames');

INSERT INTO staging.orders
SELECT *
FROM file('orders.csv', 'CSVWithNames');

INSERT INTO staging.order_items
SELECT *
FROM file('order_items.csv', 'CSVWithNames');
