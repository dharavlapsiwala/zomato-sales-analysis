-- Create and use a database
CREATE DATABASE IF NOT EXISTS my_database;
USE my_database;

-- Dropping and recreating tables

DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup (
    userid INTEGER,
    gold_signup_date DATE
);

INSERT INTO goldusers_signup (userid, gold_signup_date) 
VALUES 
(1, '2017-09-22'),
(3, '2017-04-21');

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    userid INTEGER,
    signup_date DATE
);

INSERT INTO users (userid, signup_date) 
VALUES 
(1, '2014-09-02'),
(2, '2015-01-15'),
(3, '2014-04-11');

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    userid INTEGER,
    created_date DATE,
    product_id INTEGER
);

INSERT INTO sales (userid, created_date, product_id) 
VALUES 
(1, '2017-04-19', 2),
(3, '2019-12-18', 1),
(2, '2020-07-20', 3),
(1, '2019-10-23', 2),
(1, '2018-03-19', 3),
(3, '2016-12-20', 2),
(1, '2016-11-09', 1),
(1, '2016-05-20', 3),
(2, '2017-09-24', 1),
(1, '2017-03-11', 2),
(1, '2016-03-11', 1),
(3, '2016-11-10', 1),
(3, '2017-12-07', 2),
(3, '2016-12-15', 2),
(2, '2017-11-08', 2),
(2, '2018-09-10', 3);

DROP TABLE IF EXISTS product;
CREATE TABLE product (
    product_id INTEGER,
    product_name VARCHAR(255),
    price INTEGER
);

INSERT INTO product (product_id, product_name, price) 
VALUES
(1, 'p1', 980),
(2, 'p2', 870),
(3, 'p3', 330);

-- Queries to check the data

SELECT * FROM sales;
SELECT * FROM product;
SELECT * FROM goldusers_signup;
SELECT * FROM users;

-- 1. what is the total spent by each customer ?
SELECT s.userid, SUM(p.price) AS total_spent
FROM sales s
JOIN product p ON s.product_id = p.product_id
GROUP BY s.userid;

-- 2.how many days each customer has visited ?
SELECT userid, COUNT(DISTINCT created_date) AS days_visited
FROM sales
GROUP BY userid;

-- 3.what was the first product purchased by each customer ?
SELECT s.userid, p.product_name, s.created_date AS first_purchase_date
FROM sales s
JOIN product p ON s.product_id = p.product_id
WHERE s.created_date = (
    SELECT MIN(s2.created_date)
    FROM sales s2
    WHERE s2.userid = s.userid  
);

-- 5.what is the most purchased product on the menu and how many times it wwas purchased by each customer 
WITH ProductPurchaseCount AS (
    SELECT s.product_id, COUNT(*) AS purchase_count
    FROM sales s
    GROUP BY s.product_id
)
SELECT p.product_name, p.price, pp.purchase_count
FROM ProductPurchaseCount pp
JOIN product p ON pp.product_id = p.product_id
ORDER BY pp.purchase_count DESC
LIMIT 1;

-- 6. what is most popular item for each customer ?
-- Count the number of times each product was purchased by each customer
WITH CustomerProductCount AS (
    SELECT s.userid, s.product_id, COUNT(*) AS purchase_count
    FROM sales s
    GROUP BY s.userid, s.product_id
),

-- Find the maximum purchase count for each customer
MaxPurchaseCount AS (
    SELECT userid, MAX(purchase_count) AS max_count
    FROM CustomerProductCount
    GROUP BY userid
)

-- Join the results to get the most popular product for each customer
SELECT c.userid, p.product_name, p.price, c.purchase_count
FROM CustomerProductCount c
JOIN MaxPurchaseCount m ON c.userid = m.userid AND c.purchase_count = m.max_count
JOIN product p ON c.product_id = p.product_id;

-- 7.Find items purchased by users after they became gold members
SELECT s.userid, s.product_id, p.product_name, s.created_date
FROM sales s
JOIN product p ON s.product_id = p.product_id
JOIN goldusers_signup g ON s.userid = g.userid
WHERE s.created_date > g.gold_signup_date;

-- 8.Find items purchased by users just before they became gold members
SELECT s.userid, s.product_id, p.product_name, s.created_date
FROM sales s
JOIN product p ON s.product_id = p.product_id
JOIN goldusers_signup g ON s.userid = g.userid
WHERE s.created_date = (
    SELECT MAX(s2.created_date)
    FROM sales s2
    WHERE s2.userid = s.userid AND s2.created_date < g.gold_signup_date
);

-- 9.Calculate the total amount spent by each customer before becoming a gold member
WITH PurchaseBeforeMembership AS (
    SELECT s.userid, s.product_id, p.price, s.created_date
    FROM sales s
    JOIN product p ON s.product_id = p.product_id
    JOIN goldusers_signup g ON s.userid = g.userid
    WHERE s.created_date < g.gold_signup_date
)
SELECT pb.userid, SUM(pb.price) AS total_spent_before_membership
FROM PurchaseBeforeMembership pb
GROUP BY pb.userid;

-- 10. Calculate the total points for each gold member based on spending
WITH GoldMemberSpend AS (
    SELECT s.userid, SUM(p.price) AS total_spent
    FROM sales s
    JOIN product p ON s.product_id = p.product_id
    JOIN goldusers_signup g ON s.userid = g.userid
    WHERE s.created_date > g.gold_signup_date
    GROUP BY s.userid
)
SELECT gm.userid, 
       (total_spent / 10) * 5 AS total_points
FROM GoldMemberSpend gm;
