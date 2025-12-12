-- Create Database
CREATE DATABASE pizzasales;

-- Switch to the database 
use pizzasales;
-- Import pizza and pizza type table using table import wizard.
-- creating orders table then import data from csv
CREATE TABLE orders (
    order_id int not null,
    order_date date not null,
    order_time time not null,
    primary key(order_id)
);

-- creating order details table then import data from csv

CREATE TABLE order_details (
	order_details_id int not null,
    order_id int not null,
    pizza_id text not null,
    quantity int not null,
    primary key(order_details_id)
);
-- showing all the data from tables
select * from pizzas;
select * from pizza_types;
select * from orders;
select * from order_details;

-- Basic:
-- 1. Retrieve the total number of orders placed.
SELECT COUNT(order_id) as Total_Orders from orders;

-- 2. Calculate the total revenue generated from pizza sales.
SELECT 
	ROUND(SUM(od.quantity* p.price),2) as Total_Revenue
from 
	order_details od
join 
	pizzas p on p.pizza_id = od.pizza_id;
-- 3. Identify the highest-priced pizza.
SELECT 
    p.price AS Price,
    pt.name
FROM
    pizzas p
join
	pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
order by Price desc
limit 1;
-- 4. Identify the most common pizza size ordered.
SELECT * from pizzas;
SELECT * from order_details;
Select
    p.size as size,
	count(od.quantity) as qty
from 
	pizzas p
join
order_details od on	p.pizza_id = od.pizza_id
group by size
order by qty desc
limit 1;

-- 5. List the top 5 most ordered pizza types along with their quantities.
Select 
pt.name as Name,
sum(od.quantity) as qty

from
	pizza_types pt
join
	pizzas p on pt.pizza_type_id = p.pizza_type_id
join
	order_details od on od.pizza_id= p.pizza_id
group by Name
order by qty desc
limit 5;

-- Intermediate:
-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.
Select
pt.category,
sum(od.quantity) as total_qty	
from
	pizza_types pt
join
	pizzas p on pt.pizza_type_id = p.pizza_type_id
join
	order_details od on od.pizza_id = p.pizza_id
group by pt.category
order by total_qty desc;

-- 7. Determine the distribution of orders by hour of the day.
Select hour(order_time) as hr_vise, count(order_id) as order_count
from orders
group by hr_vise
order by order_count desc;

-- 8. Join relevant tables to find the category-wise distribution of pizzas.
Select category, count(pizza_type_id) as pizza_count
from pizza_types 
group by category
order by pizza_count desc;

-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.
WITH daily AS (
  SELECT DATE(o.order_date) AS order_date, SUM(od.quantity) AS total_pizzas
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY DATE(order_date)
)
SELECT round(AVG(total_pizzas),0) AS avg_pizzas_per_day FROM daily;

-- 10. Determine the top 3 most ordered pizza types based on revenue.
SELECT
	pt.name,
	ROUND(SUM(od.quantity* p.price),2) as Total_Revenue
from
	pizza_types pt
join
	pizzas p on pt.pizza_type_id = p.pizza_type_id
join
	order_details od on od.pizza_id = p.pizza_id
group by pt.name
order by Total_Revenue desc
limit 3;

-- Advanced:
-- 11. Calculate the percentage contribution of each pizza type to total revenue.
WITH pizza_revenue AS (
    SELECT 
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.name
),
total_revenue AS (
    SELECT SUM(revenue) AS total_rev FROM pizza_revenue
)
SELECT 
    pr.pizza_name,
    pr.revenue,
    ROUND(100 * pr.revenue / tr.total_rev, 2) AS percentage_contribution
FROM pizza_revenue pr
CROSS JOIN total_revenue tr
ORDER BY percentage_contribution DESC;

-- 12. Analyze the cumulative revenue generated over time.
WITH daily_revenue AS (
    SELECT 
        o.order_date AS order_date,
        SUM(od.quantity * p.price) AS daily_rev
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY o.order_date
)
SELECT 
    order_date,
    daily_rev,
    SUM(daily_rev) OVER (ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM daily_revenue
ORDER BY order_date;

-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH category_revenue AS (
    SELECT 
        pt.category,
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY pt.category
            ORDER BY SUM(od.quantity * p.price) DESC
        ) AS rn
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
)
SELECT 
    category,
    pizza_name,
    revenue
FROM category_revenue
WHERE rn <= 3
ORDER BY category, revenue DESC;



