--New And Existing Users
--Calculate the share of new and existing users for each month in the table. Output the month, share of new users, and share of existing users as a ratio.
--New users are defined as users who started using services in the current month (there is no usage history in previous months). 
--Existing users are users who used services in current month, but they also used services in any previous month.
--Assume that the dates are all from the year 2020.
WITH a AS
(
SELECT 2 AS month, COUNT(DISTINCT(user_id)) AS new_users --- NEW USER IN FEB
FROM fact_events
WHERE MONTH(time_id)=2
UNION
SELECT 3 AS month, COUNT(DISTINCT(user_id)) AS new_users-- NEW USER IN MARCH
FROM fact_events
WHERE MONTH(time_id)=3 AND user_id NOT IN (SELECT DISTINCT(user_id)
		FROM fact_events
		WHERE MONTH(time_id)=2)
UNION
SELECT 4 AS month, COUNT(DISTINCT(user_id)) AS new_users -- NEW USER IN APRIL
FROM fact_events
WHERE MONTH(time_id)=4 AND user_id NOT IN (SELECT DISTINCT(user_id)
		FROM fact_events
		WHERE MONTH(time_id)=2 OR MONTH(time_id)=3)
)
SELECT month, new_users,
	SUM(new_users) OVER(ORDER BY month)-new_users AS existing_users, 
	SUM(new_users) OVER(ORDER BY month) AS total_users,
	CONVERT(DECIMAL(5,2),CAST(new_users AS DECIMAL(5,2))/SUM(new_users) OVER(ORDER BY month)*100) AS new_user_pct,
	CONVERT(DECIMAL(5,2),CAST((SUM(new_users) OVER(ORDER BY month)-new_users) AS DECIMAL(5,2))/SUM(new_users) OVER(ORDER BY month)*100) AS existing_user_pct
FROM a

--Homework Results
--Given the homework results of a group of students, calculate the average grade and the completion rate of each student. 
-- A homework is considered not completed if no grade has been assigned.
--Output first name of a student, their average grade, and completion rate in percentages. 
-- Note that it's possible for several students to have the same first name but their results should still be shown separately.
WITH a AS (SELECT * FROM allstate_homework WHERE grade IS NOT NULL),
b AS (SELECT student_id, COUNT(1) AS total_completation FROM a GROUP BY student_id),
c AS (SELECT student_id, COUNT(1) AS total_homeworks FROM allstate_homework GROUP BY student_id),
d AS (SELECT a.student_id, b.student_firstname, AVG(grade) AS avg_grade
	FROM allstate_homework a
	JOIN allstate_students b
	ON a.student_id=b.student_id
	GROUP BY a.student_id, b.student_firstname)
SELECT c.student_id, d.student_firstname, CONVERT(DECIMAL(5,2),CAST(b.total_completation AS DECIMAL(4,2))/c.total_homeworks*100) AS completion_rate, d.avg_grade
FROM c
JOIN b
ON c.student_id=b.student_id
JOIN d
ON d.student_id=c.student_id

--Completed Trip within 168 Hours
--An event is logged in the events table with a timestamp each time a new rider attempts a signup (with an event name 'attempted_su') 
-- or successfully signs up (with an event name of 'su_success').
--For each city and date, determine the percentage of signups in the first 7 days of 2022 that completed a trip within 168 hours of the signup date. 
-- HINT: driver id column corresponds to rider id column
WITH a AS(SELECT a.rider_id, a.city_id, a.timestamp, b.client_rating, b.driver_rating, b.status
		FROM signup_events a
		JOIN trip_details b
		ON a.rider_id=b.driver_id
		WHERE day(timestamp) <= 7 AND status='completed' 
		AND DATEDIFF(HOUR,timestamp,actual_time_of_arrival) <= 168),
b AS (SELECT * FROM signup_events WHERE day(timestamp) <= 7),
c AS (SELECT city_id, COUNT(DISTINCT(rider_id)) AS total_signups_first_7_days FROM b GROUP BY city_id),
d AS (SELECT city_id, COUNT(DISTINCT(rider_id)) AS total_completed_in_168_hour FROM a GROUP BY city_id)
SELECT d.city_id, total_completed_in_168_hour, total_signups_first_7_days, 
	CONVERT(DECIMAL(5,2),CAST(total_completed_in_168_hour AS DECIMAL(4,2))/total_signups_first_7_days*100) AS percentage
FROM d
JOIN c
ON d.city_id=c.city_id

--Differences In Movie Ratings
--Calculate the average lifetime rating and rating from the movie with second biggest id across all actors and all films they had acted in. 
--Remove null ratings from the calculation.
--Role type is "Normal Acting". 
--Output a list of actors, their average lifetime rating, rating from the film with the second biggest id (use id column), 
-- and the absolute difference between the two ratings.
WITH a AS (SELECT *, RANK() OVER(ORDER BY id DESC) AS ranking FROM nominee_filmography),
b AS (SELECT id, name, rating FROM a WHERE ranking = 2),
c AS (SELECT id, name, rating FROM nominee_filmography
		WHERE rating IS NOT NULL AND id NOT IN (SELECT id FROM b))
SELECT b.id, b.rating, c.id, c.rating, ABS(CONVERT(DECIMAL(3,0),b.rating)-CONVERT(DECIMAL(3,0),c.rating)) AS rating_diff
FROM b
JOIN c
ON b.id !=c.id

--Department Manager and Employee Salary Comparison
--Oracle is comparing the monthly wages of their employees in each department to those of their managers and co-workers.
--You have tasked with creating a table that compares an employee's salary to that of their manager and to the average salary of their department.
--It is expected that the department manager's salary and the average salary of employee's from that department are in their own separate column.
--Order the employee's salary from highest to lowest based on their department.
--Your output should contain the department, employee id, salary of that employee, salary of that employee's manager and the average salary 
-- from employee's within that department rounded to the nearest whole number.
--Note: Oracle have requested that you not include the department manager's salary in the average salary for that department in order to avoid skewing the results. 
-- Managers of each department do not report to anyone higher up; they are their own manager.
SELECT a.department, a.id, a.salary, b.salary AS dept_manager_salary, c.avg_salary AS avg_dept_salary
FROM employee_o a
JOIN (SELECT id, first_name, department, salary FROM employee_o WHERE employee_title='Manager') b
ON a.department=b.department
JOIN (SELECT department, AVG(salary) AS avg_salary FROM employee_o GROUP BY department) c
ON a.department=c.department
WHERE employee_title!='Manager'

--Caller History
--Given a phone log table that has information about callers' call history, find out the callers whose first and last calls were to the same person on a given day. 
--Output the caller ID, recipient ID, and the date called.
WITH a AS (SELECT CONVERT(date,date_called) AS date, caller_id, 
				FIRST_VALUE(recipient_id) OVER(PARTITION BY CONVERT(date,date_called) ORDER BY date_called) AS first_recipient_id, 
				FIRST_VALUE(recipient_id) OVER(PARTITION BY CONVERT(date,date_called) ORDER BY date_called DESC) AS last_recipient_id
		FROM caller_history)
SELECT date, caller_id
FROM a
WHERE first_recipient_id=last_recipient_id

--Product Families
--The CMO is interested in understanding how the sales of different product families are affected by promotional campaigns. 
--To do so, for each product family, show the total number of units sold, as well as the percentage of units sold that had a valid promotion among total units sold.
--If there are NULLS in the result, replace them with zeroes. Promotion is valid if it's not empty and it's contained inside promotions table.
WITH a AS 
(SELECT product_family, SUM(units_sold) AS total_units_sold 
 FROM facebook_sales a 
 JOIN facebook_products b ON a.product_id=b.product_id 
 GROUP BY product_family),
b AS 
(SELECT a.product_id, b.product_family, c.promotion_id, a.units_sold 
 FROM facebook_sales a 
 JOIN facebook_products b ON a.product_id=b.product_id 
 JOIN facebook_sales_promotions c ON a.promotion_id=c.promotion_id),
c AS 
(SELECT product_family, SUM(units_sold) AS total_units_sold_in_promotion 
 FROM b 
 GROUP BY product_family)
SELECT a.product_family, c.total_units_sold_in_promotion, a.total_units_sold
FROM a
JOIN c
ON a.product_family=c.product_family

--Products Never Sold
--The VP of Sales feels that some product categories don't sell and can be completely removed from the inventory. 
--As a first pass analysis, they want you to find what percentage of product categories have never been sold.
WITH a AS 
	(SELECT COUNT(DISTINCT(category_name)) AS category_name_in_sale 
	FROM facebook_sales a 
	JOIN facebook_products b 
	ON a.product_id=b.product_id 
	JOIN facebook_product_categories c 
	ON c.category_id=b.product_category),
b AS 
	(SELECT COUNT(category_name) AS total_category 
	FROM facebook_product_categories)
SELECT CONVERT(DECIMAL(5,2),100-CAST(category_name_in_sale AS DECIMAL(5,2))/total_category*100) AS percentage_of_product_categories_not_sold
FROM a,b

--Highest Sales with Promotions
--Which products had the highest sales (in terms of units sold) in each promotion? 
--Output promotion id, product id with highest sales and highest sales itself.
SELECT product_id, promotion_id, SUM(units_sold) AS units_sold
FROM facebook_sales
GROUP BY product_id, promotion_id

--First and Last Day
--What percentage of transactions happened on first and last day of the promotion. Segment results per promotion.
--Output promotion id, percentage of transactions on the first day and percentage of transactions on the last day.
WITH a AS (SELECT a.promotion_id, COUNT(1) AS total_transactions
		FROM facebook_sales a
		JOIN facebook_sales_promotions b
		ON a.promotion_id=b.promotion_id
		GROUP BY a.promotion_id),
b AS (SELECT a.promotion_id, COUNT(1) AS transaction_on_first_day
		FROM facebook_sales a
		JOIN facebook_sales_promotions b
		ON a.promotion_id=b.promotion_id
		WHERE date=start_date
		GROUP BY a.promotion_id),
c AS (SELECT a.promotion_id, COUNT(1) AS transaction_on_last_day
		FROM facebook_sales a
		JOIN facebook_sales_promotions b
		ON a.promotion_id=b.promotion_id
		WHERE date=end_date
		GROUP BY a.promotion_id)
SELECT a.promotion_id, a.total_transactions, 
	CONVERT(DECIMAL(5,2),CAST(ISNULL(b.transaction_on_first_day,0)AS decimal(5,2))/a.total_transactions*100) AS transaction_on_first_date,
	CONVERT(DECIMAL(5,2),CAST(ISNULL(c.transaction_on_last_day,0)AS decimal(5,2))/a.total_transactions*100) AS transaction_on_last_date
FROM a
FULL JOIN b
ON a.promotion_id=b.promotion_id
FULL JOIN c
ON c.promotion_id=a.promotion_id

--Most Sold in Germany
--Find the product with the most orders from users in Germany. Output the market name of the product or products in case of a tie.
WITH a AS (SELECT prod_sku_name, a.order_id FROM shopify_orders a
		JOIN shopify_users b
		ON a.user_id = b.id
		JOIN map_product_order c
		ON c.order_id=a.order_id
		JOIN dim_product d
		ON c.product_id= d.prod_sku_id
		WHERE country='Germany')
SELECT prod_sku_name, COUNT(a.order_id) as total_orders
FROM a
GROUP BY prod_sku_name

--Employee with Most Orders
--What is the last name of the employee or employees who are responsible for the most orders?
SELECT resp_employee_id, COUNT(1) AS total_orders, last_name
FROM shopify_orders a
JOIN shopify_employees b
ON a.resp_employee_id=b.id
GROUP BY resp_employee_id, last_name

--More Than 100 Dollars
--For each month of 2021, calculate what percentage of restaurants, out of these that fulfilled any orders in a given month, 
-- fulfilled more than 100$ in monthly sales?
WITH a AS (SELECT *, MONTH(order_placed_time) AS month, YEAR(order_placed_time) AS year
		FROM delivery_orders
		WHERE YEAR(order_placed_time)=2021),
b AS (SELECT year, month, restaurant_id, SUM(sales_amount) AS total_sales_amount
		FROM a
		JOIN order_value b
		ON a.delivery_id=b.delivery_id
		GROUP BY year, month, restaurant_id)
SELECT *, CASE WHEN total_sales_amount >=100 THEN 'fulfilled' ELSE 'not_fulfilled' END AS note FROM b

--First Ever Ratings
--Looking at Dashers completing their first-ever order: what percentage of Dashers' first-ever orders have a rating of 0?
SELECT dasher_id, MIN(order_placed_time) AS first_ever_order_date 
FROM delivery_orders
WHERE delivery_rating=0
GROUP BY dasher_id

--Extremely Late Delivery
--A delivery is flagged as extremely late if its actual delivery time is more than 20 minutes after its predicted delivery time. 
--In each month, what percentage of placed orders were extremely late?
--Output the month in a YYYY-MM format and the corresponding proportion of the extremely late orders as the percentage of all orders placed in this month.
WITH a AS (SELECT * FROM delivery_orders
	WHERE DATEDIFF(MINUTE,predicted_delivery_time,actual_delivery_time)>20),
b AS (SELECT FORMAT(order_placed_time,'yyyy-MM') AS month, COUNT(1) AS extremely_late_orders
	FROM a
	GROUP BY FORMAT(order_placed_time,'yyyy-MM')),
c AS (SELECT FORMAT(order_placed_time,'yyyy-MM') AS month, COUNT(1) AS total_orders
	FROM delivery_orders
	GROUP BY FORMAT(order_placed_time,'yyyy-MM'))
SELECT c.month, b.extremely_late_orders, c.total_orders, CONVERT(DECIMAL(5,2),CAST(b.extremely_late_orders AS DECIMAL(4,2))/c.total_orders*100) AS proportion
FROM c
JOIN b
ON c.month=b.month


--Product Market Share
--Write a query to find the Market Share at the Product Brand level for each Territory, for Time Period Q4-2021. 
--Market Share is the number of Products of a certain Product Brand brand sold in a territory, divided by the total number of Products sold in this Territory.
--Output the ID of the Territory, name of the Product Brand and the corresponding Market Share in percentages. 
--Only include these Product Brands that had at least one sale in a given territory.
WITH a AS (SELECT a.cust_id,b.prod_sku_id,b.prod_brand, c.territory_id FROM fct_customer_sales a
		JOIN dim_product b
		ON a.prod_sku_id=b.prod_sku_id
		JOIN map_customer_territory c
		ON c.cust_id=a.cust_id
		WHERE MONTH(order_date) BETWEEN 10 AND 12),
b AS (SELECT territory_id, COUNT(1) AS total_orders
		FROM a
		GROUP BY territory_id),
c AS (SELECT territory_id, prod_brand, COUNT(1) AS orders
		FROM a
		GROUP BY territory_id, prod_brand)
SELECT c.territory_id,c.prod_brand, c.orders, b.total_orders, CONVERT(decimal(5,2),CAST(c.orders AS DECIMAL(5,2))/b.total_orders*100) AS pct
FROM c
JOIN b
ON c.territory_id=b.territory_id
ORDER BY 1

--Sales Growth per Territory
--Write a query to return Territory and corresponding Sales Growth. Compare growth between periods Q4-2021 vs Q3-2021.
--If Territory (say T123) has Sales worth $100 in Q3-2021 and Sales worth $110 in Q4-2021, then the Sales Growth will be 10% [ i.e. = ((110 - 100)/100) * 100 ]
--Output the ID of the Territory and the Sales Growth. Only output these territories that had any sales in both quarters.
WITH a AS (SELECT territory_id, SUM(order_value) AS sales_q4
	FROM fct_customer_sales a
	JOIN map_customer_territory b
	ON a.cust_id=b.cust_id
	WHERE MONTH(order_date) BETWEEN 10 AND 12
	GROUP BY territory_id),
b AS (SELECT territory_id, SUM(order_value) AS sales_q3
	FROM fct_customer_sales a
	JOIN map_customer_territory b
	ON a.cust_id=b.cust_id
	WHERE MONTH(order_date) BETWEEN 7 AND 9
	GROUP BY territory_id)
SELECT a.territory_id, b.sales_q3, a.sales_q4, CONVERT(DECIMAL(5,2),CAST(a.sales_q4-b.sales_q3 AS DECIMAL(6,2))/b.sales_q3*100) AS growth_rate
FROM a
JOIN b
ON a.territory_id=b.territory_id

--Salary Less Than Twice The Average
--Write a query to get the list of managers whose salary is less than twice the average salary of employees reporting to them. 
--For these managers, output their ID, salary and the average salary of employees reporting to them.
SELECT a.empl_id, b.salary, a.manager_empl_id, c.salary FROM map_employee_hierarchy a
JOIN dim_employee b
ON a.empl_id=b.empl_id
JOIN dim_employee c
ON a.manager_empl_id=c.empl_id
WHERE c.salary/b.salary<2

--Responsible for Most Customers
--Each Employee is assigned one territory and is responsible for the Customers from this territory. There may be multiple employees assigned to the same territory.
--Write a query to get the Employees who are responsible for the maximum number of Customers. Output the Employee ID and the number of Customers.
SELECT empl_id, total_customers FROM map_employee_territory a
JOIN (SELECT territory_id,COUNT(1) AS total_customers
	FROM map_customer_territory
	GROUP BY territory_id) b
ON a.territory_id=b.territory_id

--Rows With Missing Values
--The data engineering team at YouTube want to clean the dataset user_flags. 
--In particular, they want to examine rows that have missing values in more than one column. List these rows.
SELECT * FROM user_flags
WHERE user_firstname IS NULL
OR user_lastname IS NULL
OR video_id IS NULL
OR flag_id IS NULL

--Maximum Number of Employees Reached
--Write a query that returns every employee that has ever worked for the company. 
--For each employee, calculate the greatest number of employees that worked for the company during their tenure and the first date that number was reached. 
--The termination date of an employee should not be counted as a working day.
--Your output should have the employee ID, greatest number of employees that worked for the company during the employee's tenure, 
--and first date that number was reached.
WITH a AS
	(SELECT *, COUNT(1) OVER(ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_emps
	FROM uber_employees),
b AS
	(SELECT termination_date, SUM(CASE WHEN termination_date IS NOT NULL THEN 1 ELSE 0 END) AS total_left_emps
	FROM uber_employees
	WHERE termination_date IS NOT NULL
	GROUP BY termination_date),
SELECT id, total_emps-COALESCE(total_left_emps,0) AS greatest_number_emp, hire_date
FROM a
LEFT JOIN b
ON a.hire_date=b.termination_date

--Most Senior & Junior Employee
--Write a query to find the number of days between the longest and least tenured employee still working for the company. 
--Your output should include the number of employees with the longest-tenure, the number of employees with the least-tenure, 
--and the number of days between both the longest-tenured and least-tenured hiring dates.
WITH a AS
	(SELECT *, DATEDIFF(DAY,hire_date,COALESCE(termination_date,GETDATE())) AS working_days FROM uber_employees),
b AS
	(SELECT working_days AS longest_tenure, COUNT(1) AS longest_tenure_emp FROM a
	WHERE working_days = (SELECT MAX(working_days) FROM a)
	GROUP BY working_days),
c AS
	(SELECT working_days AS least_tenure, COUNT(1) AS least_tenure_emp FROM a
	WHERE working_days = (SELECT MIN(working_days) FROM a)
	GROUP BY working_days)
SELECT longest_tenure, longest_tenure_emp, least_tenure, least_tenure_emp, longest_tenure-least_tenure AS tenured_diff
FROM b,c

--World Tours
--A group of travelers embark on world tours starting with their home cities. 
--Each traveler has an undecided itinerary that evolves over the course of the tour. 
--Some travelers decide to abruptly end their journey mid-travel and live in their last destination.
--Given the dataset of dates on which they travelled between different pairs of cities, can you find out how many travellers ended back in their home city? 
--For simplicity, you can assume that each traveler made at most one trip between two cities in a day.
WITH a AS (SELECT *, FIRST_VALUE(start_city) OVER(PARTITION BY traveler ORDER BY date) AS first_port, 
	FIRST_VALUE(end_city) OVER(PARTITION BY traveler ORDER BY date DESC) AS last_port
	FROM travel_history)
SELECT traveler, start_city,end_city, date FROM a
WHERE first_port=last_port

--Videos Removed on Latest Date
--For each unique user in the dataset, find the latest date when their flags got reviewed. 
--Then, find total number of distinct videos that were removed on that date (by any user).
--Output the the first and last name of the user (in two columns), the date and the number of removed videos. 
--Only include these users who had at least one of their flags reviewed by Youtube. If no videos got removed on a certain date, output 0.
WITH a AS (SELECT reviewed_date, user_firstname, user_lastname, reviewed_outcome, video_id 
		FROM flag_review a
		JOIN user_flags b
		ON a.flag_id=b.flag_id
		WHERE reviewed_by_yt=1 AND reviewed_outcome='REMOVED')
SELECT user_firstname, user_lastname, reviewed_date, COUNT(DISTINCT(video_id)) AS removed_videos
FROM a
GROUP BY user_firstname, user_lastname, reviewed_date

--User with Most Approved Flags
--Which user flagged the most distinct videos that ended up approved by YouTube? 
--Output, in one column, their full name or names in case of a tie. In the user's full name, include a space between the first and the last name.
WITH a AS (SELECT reviewed_date, user_firstname, user_lastname, video_id 
	FROM flag_review a
	JOIN user_flags b
	ON a.flag_id=b.flag_id
	WHERE reviewed_outcome = 'APPROVED')
SELECT user_firstname, user_lastname, COUNT(video_id) AS total_approved_videos
FROM a
GROUP BY user_firstname, user_lastname

--Reviewed flags of top videos
--For the video (or videos) that received the most user flags, how many of these flags were reviewed by YouTube? 
--Output the video ID and the corresponding number of reviewed flags.
WITH a AS (SELECT video_id, a.flag_id, reviewed_by_yt FROM user_flags a
		JOIN flag_review b
		ON a.flag_id=b.flag_id),
b AS (SELECT video_id, COUNT(1) AS total_flags FROM a GROUP BY video_id),
c AS (SELECT video_id, a.flag_id, reviewed_by_yt FROM user_flags a
		JOIN flag_review b
		ON a.flag_id=b.flag_id
		WHERE reviewed_by_yt=1),
d AS (SELECT video_id, COUNT(1) AS total_reviewed_by_yt FROM c GROUP BY video_id)
SELECT b.video_id, b.total_flags, d. total_reviewed_by_yt
FROM b
JOIN d
ON b.video_id=d.video_id

--Flags per Video
--For each video, find how many unique users flagged it. A unique user can be identified using the combination of their first name and last name. 
--Do not consider rows in which there is no flag ID.
WITH a AS 
	(SELECT *, CONCAT(user_firstname,user_lastname) AS user_id 
	FROM user_flags)
SELECT video_id, COUNT(DISTINCT(user_id)) AS total_unique_users_flagged
FROM a
GROUP BY video_id

--Maximum of Two Numbers
--Given a single column of numbers, consider all possible permutations of two numbers assuming that pairs of numbers (x,y) and (y,x) are two different permutations. 
--Then, for each permutation, find the maximum of the two numbers.
--Output three columns: the first number, the second number and the maximum of the two.
SELECT a.number AS first_number, b.number AS second_number, 
	CASE WHEN a.number<b.number THEN b.number ELSE a.number END AS maximum_of_two
FROM deloitte_numbers a
JOIN deloitte_numbers b
ON a.number!=b.number

--Election Results
--The election is conducted in a city and everyone can vote for one or more candidates, or choose not to vote at all. 
--Each person has 1 vote so if they vote for multiple candidates, their vote gets equally split across these candidates. 
--For example, if a person votes for 2 candidates, these candidates receive an equivalent of 0.5 vote each.
--Find out who got the most votes and won the election. 
--Output the name of the candidate or multiple names in case of a tie. 
--To avoid issues with a floating-point error you can round the number of votes received by a candidate to 3 decimal places.
WITH a AS (SELECT a.voter, vote_times, candidate, CAST(1 AS DECIMAL(4,2))/vote_times AS vote
	FROM voting_results a
	JOIN (SELECT voter, COUNT(1) AS vote_times
		FROM voting_results
		GROUP BY voter) b
	ON a.voter=b.voter
	WHERE candidate IS NOT NULL)
SELECT candidate, CONVERT(DECIMAL(5,2),SUM(vote)) AS total_votes
FROM a
GROUP BY candidate

--Three Purchases
--List the IDs of customers who made at least 3 orders in both 2020 and 2021.
WITH a AS (SELECT * FROM amazon_orders
		WHERE YEAR(order_date)=2020),
b AS (SELECT user_id, COUNT(1) AS orders_2020
	FROM a
	GROUP BY user_id),
c AS (SELECT * FROM amazon_orders
		WHERE YEAR(order_date)=2021),
d AS (SELECT user_id, COUNT(1) AS orders_2021
	FROM a
	GROUP BY user_id)
SELECT b.user_id, b.orders_2020, d.orders_2021 Highest Earning Merchants
FROM b
JOIN d
ON b.user_id=d.user_id
WHERE b.orders_2020>=3
AND d.orders_2021>=3

--Completed Tasks
--Find the number of actions that ClassPass workers did for tasks completed in January 2022. 
--The completed tasks are these rows in the asana_actions table with 'action_name' equal to CompleteTask. 
--Note that each row in the dataset indicates how many actions of a certain type one user has performed in one day and the number of actions is stored in 
--the 'num_actions' column.
--Output the ID of the user and a total number of actions they performed for tasks they completed. 
--If a user from this company did not complete any tasks in the given period of time, you should still output their ID and the number 0 in the second column.
WITH a AS (SELECT a.user_id, num_actions, action_name, b.name, b.surname 
		FROM asana_actions a
		JOIN asana_users b
		ON a.user_id = b.user_id
		WHERE company ='ClassPass'
		AND date BETWEEN '2022-01-01' AND '2022-01-31'
		AND action_name ='CompleteTask')
SELECT user_id, SUM(num_actions) AS total_actions
FROM a
GROUP BY user_id

--Highest Earning Merchants
--For each day, find a merchant who earned the highest amount on a previous day. Round total amount to 2 decimals.
--Output the date and the name of the merchant but only for the days where the data from the previous day are available. 
--In the case of multiple merchants having the same highest shared amount, your output should include all the names in different rows.
WITH a AS (SELECT a.merchant_id, order_timestamp, n_items, total_amount_earned, name, category, zipcode 
		FROM doordash_orders a
		JOIN doordash_merchants b
		ON a.merchant_id=b.id),
b AS (SELECT order_timestamp, name, SUM(total_amount_earned) AS total_amount_earned, LAG(SUM(total_amount_earned)) OVER(PARTITION BY name ORDER BY order_timestamp) AS previous_amount_earned
	FROM a
	GROUP BY name, order_timestamp)
SELECT order_timestamp, name, MAX(previous_amount_earned) AS max_amount_earned_on_previous
FROM b
GROUP BY order_timestamp, name
HAVING MAX(previous_amount_earned) IS NOT NULL

--First Time Orders
--For each merchant, find how many orders and first-time orders they had. First-time orders are meant from the perspective of a customer and are 
--the first order that a customer ever made. 
--In order words, for how many customers was this the first-ever merchant they ordered with?
--Output the name of the merchant, the total number of their orders and the number of these orders that were first-time orders.
WITH a AS (SELECT *, FIRST_VALUE(order_timestamp) OVER(PARTITION BY merchant_id ORDER BY order_timestamp) AS first_order_date
	FROM doordash_orders a),
b AS (SELECT merchant_id, first_order_date 
	FROM a GROUP BY merchant_id, first_order_date),
c AS (SELECT a.merchant_id, b.name, COUNT(1) AS total_orders
	FROM doordash_orders a
	JOIN doordash_merchants b
	ON a.merchant_id=b.id
	GROUP BY a.merchant_id, b.name)
SELECT c.merchant_id, c.name, total_orders, b.first_order_date
FROM c
JOIN b
ON c.merchant_id=b.merchant_id

--Daily Top Merchants
--For each day, find the top 3 merchants with the highest number of orders on that day. 
--In case of a tie, multiple merchants can share the same place but on each day, there should always be at least 1 merchant on the first, second and third place.
--Output the date, the name of the merchant and their place in the daily ranking.
WITH a AS (SELECT merchant_id, CONVERT(date,order_timestamp) AS date, COUNT(1) as total_orders
		FROM doordash_orders
		GROUP BY merchant_id, CONVERT(date,order_timestamp)),
b AS (SELECT merchant_id, date, total_orders, RANK() OVER(PARTITION BY date ORDER BY total_orders DESC) AS ranking FROM a)
SELECT b.date, c.name, b.merchant_id, total_orders
FROM b
JOIN doordash_merchants c
ON b.merchant_id=c.id
WHERE ranking<=3
ORDER BY 1

--First Day Retention Rate
--Calculate the first-day retention rate of a group of video game players. The first-day retention occurs when a player logs in 1 day after their first-ever log-in.
--Return the proportion of players who meet this definition divided by the total number of players.
WITH a AS (SELECT player_id, login_date, LEAD(login_date) OVER(PARTITION BY player_id ORDER BY login_date) AS next_login_date
		FROM players_logins),
b AS (SELECT player_id, login_date
	FROM a
	WHERE next_login_date IS NOT NULL AND datediff(DAY,login_date,next_login_date)=1),
c AS (SELECT COUNT(DISTINCT(player_id)) AS first_day_retention FROM b),
d AS (SELECT COUNT(DISTINCT(player_id)) AS total_user FROM players_logins)
SELECT CONVERT(decimal(5,2),CAST(first_day_retention AS DECIMAL(5,2))/total_user*100) AS first_day_retention_rate
FROM c, d

--Cookbook Recipes
--You are given the table with titles of recipes from a cookbook and their page numbers. You are asked to represent how the recipes will be distributed in the book.
--Produce a table consisting of three columns: left_page_number, left_title and right_title. 
--The k-th row (counting from 0), should contain the number and the title of the page with the number 2 \times k2×k in the first and second columns respectively, 
--and the title of the page with the number 2 \times k + 12×k+1 in the third column.
--Each page contains at most 1 recipe. If the page does not contain a recipe, the appropriate cell should remain empty (NULL value). 
--Page 0 (the internal side of the front cover) is guaranteed to be empty.
WITH a AS 
	(SELECT ROW_NUMBER() OVER(ORDER BY page_number) AS row_number, * 
	FROM cookbook_titles),
odd AS 
	(SELECT page_number, title, ROW_NUMBER() OVER(ORDER BY page_number) AS row_number 
	FROM a WHERE row_number%2=1),
even AS
	(SELECT page_number, title, ROW_NUMBER() OVER(ORDER BY page_number) AS row_number 
	FROM a WHERE row_number%2=0)
SELECT o.page_number, o.title, e.page_number, e.title FROM odd o
JOIN even e
ON o.row_number = e.row_number

--Premium Acounts
--You are given a dataset that provides the number of active users per day per premium account. A premium account will have an entry for every day that it’s premium. 
--However, a premium account may be temporarily discounted and considered not paid, this is indicated by a value of 0 in the final_price column for a certain day. 
--Find out how many premium accounts that are paid on any given day are still premium and paid 7 days later.
--Output the date, the number of premium and paid accounts on that day, and the number of how many of these accounts are still premium and paid 7 days later. 
--Since you are only given data for a 14 days period, only include the first 7 available dates in your output.
WITH a AS (SELECT entry_date, COUNT(account_id) AS premium_accounts, ROW_NUMBER() OVER(ORDER BY entry_date) AS row_number
		FROM premium_accounts_by_day
		WHERE entry_date < '2022-02-15'
		GROUP BY entry_date),
b AS (SELECT entry_date, COUNT(account_id) AS premium_accounts, ROW_NUMBER() OVER(ORDER BY entry_date) AS row_number
		FROM premium_accounts_by_day
		WHERE entry_date > '2022-02-15'
		GROUP BY entry_date)
SELECT a.entry_date, a.premium_accounts, b.premium_accounts AS premium_accounts_7_laters
FROM a
JOIN b
ON a.row_number=b.row_number

--Retention Rate
--Find the monthly retention rate of users for each account separately for Dec 2020 and Jan 2021. Retention rate is the percentage of active users an account 
--retains over a given period of time.
--In this case, assume the user is retained if he/she stays with the app in any future months. 
--For example, if a user was active in Dec 2020 and has activity in any future month, consider them retained for Dec.
--You can assume all accounts are present in Dec 2020 and Jan 2021. 
--Your output should have the account ID and the Jan 2021 retention rate divided by Dec 2020 retention rate.
WITH a AS (SELECT account_id, date, COUNT(user_id) AS active_users
	FROM sf_events
	WHERE date < '2020-12-31'
	GROUP BY account_id, date), --- active user per account in 2020
b AS (SELECT account_id, COUNT(user_id) AS active_users 
	FROM sf_events
	WHERE date >= '2021-01-01'
	GROUP BY account_id) --- active user per account in 2021
SELECT a.account_id, a.active_users AS users_in_2020, b.active_users AS users_in_2021
FROM a
JOIN b
ON a.account_id=b.account_id --- join 2 tables

--Employed at Google
--Find IDs of LinkedIn users who were employed at Google on November 1st, 2021.
--Do not consider users who started or ended their employment at Google on that day but do include users who changed their position within Google on that day.
SELECT * FROM linkedin_users
WHERE employer ='Google' AND start_date='2021-11-01'

--From Microsoft to Google
--Consider all LinkedIn users who, at some point, worked at Microsoft. For how many of them was Google their next employer right after Microsoft 
--(no employers in between)?
WITH a AS
	(SELECT *, LEAD(employer) OVER(PARTITION BY user_id ORDER BY start_date) AS next_employer
	FROM linkedin_users)
SELECT user_id, employer, position, start_date, end_date FROM a
WHERE employer='Microsoft' AND next_employer='Google'

--City with Most Customers
--For each city, find the number of rides in August 2021 that were not paid for using promotional codes. Output the city or cities where this number was the highest.
SELECT country, COUNT(1) as number_of_rides
FROM lyft_orders a
JOIN lyft_payments b
ON a.order_id=b.order_id
WHERE promo_code=0 AND order_date BETWEEN '2021-08-01' AND '2021-08-31'
GROUP BY country

--Recommendation System
--You are given the list of Facebook friends and the list of Facebook pages that users follow. Your task is to create a new recommendation system for Facebook. 
--For each Facebook user, find pages that this user doesn't follow but at least one of their friends does. Output the user ID and the ID of the page that should 
--be recommended to this user.
SELECT a.user_id, b.page_id 
FROM users_friends a
JOIN users_pages b
ON a.user_id!=b.user_id
AND a.friend_id=b.user_id

--Blocked Users
--You are given a table of users who have been blocked from Facebook, together with the date, duration, and the reason for the blocking. 
--The duration is expressed as the number of days after blocking date and if this field is empty, this means that a user is blocked permanently.
--For each blocking reason, count how many users were blocked in December 2021. Include both the users who were blocked in December 2021 and those who 
--were blocked before but remained blocked for at least a part of December 2021.
WITH a AS
	(SELECT *, DATEADD(DAY,block_duration,block_date) AS block_date_tail 
	FROM fb_blocked_users
	WHERE block_date BETWEEN '2021-12-01' AND '2021-12-31'
	OR DATEADD(DAY,block_duration,block_date) BETWEEN '2021-12-01' AND '2021-12-31')
SELECT block_reason, COUNT(1) AS blocked_users
FROM a
GROUP BY block_reason

--Customers with Specific Brands
--In the latest promotion, the marketing department wants to target customers who have bought products from two specific brands.
--Prepare a list of customers who purchased products from both the "Fort West" and the "Golden" brands.
SELECT * FROM facebook_sales a
JOIN facebook_products b
ON a.product_id=b.product_id
WHERE brand_name='Fort West' OR brand_name='Golden'

--Top Three Classes
--The marketing department wants to launch a new promotion for the most successful product classes. What are the top 3 product classes by number of sales?
SELECT product_class, SUM(units_sold) AS total_units_sold
FROM facebook_sales a
JOIN facebook_products b
ON a.product_id=b.product_id
GROUP BY product_class
ORDER BY 2 DESC

--Fastest Hometowns
--Find the hometowns with the top 3 average net times. Output the hometowns and their average net time. In case there are ties in net time, return all 
--unique hometowns.
SELECT TOP 3 hometown, AVG(net_time) AS avg_net_times 
FROM marathon_male 
GROUP BY hometown 
ORDER BY 2 DESC

--Time from 10th Runner
--In a marathon, gun time is counted from the moment of the formal start of the race while net time is counted from the moment a runner crosses a starting line. 
--Both variables are in seconds.
--How much net time separates Chris Doe from the 10th best net time (in ascending order)? Avoid gaps in the ranking calculation. 
--Output absolute net time difference.
WITH a AS
(SELECT CASE WHEN person_name='Chris Doe' THEN gun_time-net_time END AS chris_doe,
CASE WHEN place=10 THEN gun_time-net_time END AS tenth_place
FROM marathon_male )
SELECT MAX(chris_doe) AS chris_doe, MAX(tenth_place) AS tenth_place
FROM a

--Number of Conversations
--Count the total number of distinct conversations on WhatsApp. Two users share a conversation if there is at least 1 message between them. 
--Multiple messages between the same pair of users are considered a single conversation.
WITH a AS
	(SELECT message_sender_id, message_receiver_id 
	FROM whatsapp_messages
	GROUP BY message_sender_id, message_receiver_id)
SELECT COUNT(1) AS total_distinct_conversation 
FROM a

--Minimum Number of Platforms
--You are given a day worth of scheduled departure and arrival times of trains at one train station. 
--One platform can only accommodate one train from the beginning of the minute it's scheduled to arrive until the end of the minute it's scheduled to depart. 
--Find the minimum number of platforms necessary to accommodate the entire scheduled traffic.
WITH a AS
	(SELECT a.train_id, arrival_time, departure_time, LEAD(arrival_time) OVER(ORDER BY arrival_time) AS next_arrival
	FROM train_arrivals a
	JOIN train_departures b
	ON a.train_id=b.train_id),
b AS 
	(SELECT *, DATEPART(HOUR,arrival_time) as hour FROM a WHERE next_arrival<=departure_time),
c AS
	(SELECT COUNT(1) OVER(PARTITION BY hour) AS platform FROM b)
SELECT MAX(platform) AS minimum_number_of_platform FROM c

--Seat Availability
--A movie theater gave you two tables: seats that are available for an upcoming screening and neighboring seats for each seat listed. 
--You are asked to find all pairs of seats that are both adjacent and available.
--Output only distinct pairs of seats in two columns such that the seat with the lower number is always in the first column and 
--the one with the higher number is in the second column.
WITH a AS
(SELECT seat_number AS left_seat, seat_right AS right_seat 
FROM theater_seatmap
UNION ALL
SELECT seat_number AS right_seat, seat_left AS left_seat 
FROM theater_seatmap)
SELECT * FROM a
WHERE left_seat IN (SELECT seat_number FROM theater_availability WHERE is_available ='True') 
AND right_seat IN (SELECT seat_number FROM theater_availability WHERE is_available ='True') 

--Negative Reviews in New Locations
--Find stores that were opened in the second half of 2021 with more than 20% of their reviews being negative.
--A review is considered negative when the score given by a customer is below 5. 
--Output the names of the stores together with the ratio of negative reviews to positive ones.
SELECT a.store_id, name, 
SUM(CASE WHEN score <5 THEN 1 ELSE 0 END) AS negative_reviews, COUNT(1) AS total_reviews
FROM instacart_reviews a
JOIN instacart_stores b
ON a.store_id=b.id
WHERE opening_date BETWEEN '2021-07-01' AND '2021-12-31'
GROUP BY a.store_id, name
HAVING CAST(SUM(CASE WHEN score <5 THEN 1 ELSE 0 END) AS DECIMAL(5,2))/COUNT(1)>0.2

--Popular Posts
--The column 'perc_viewed' in the table 'post_views' denotes the percentage of the session duration time the user spent viewing a post. 
--Using it, calculate the total time that each post was viewed by users. Output post ID and the total viewing time in seconds, but only for 
--posts with a total viewing time of over 5 seconds.
SELECT post_id, perc_viewed*DATEDIFF(SECOND,session_starttime,session_endtime)/100 AS view_in_second
FROM post_views a
JOIN user_sessions b
ON a.session_id=b.session_id
WHERE perc_viewed*DATEDIFF(SECOND,session_starttime,session_endtime)/100>5

--Find Products
--Find product ids whose average sales price is at least $3 and that are sold at least 2 times? Output product id and their brand.
WITH a AS
	(SELECT product_id
	FROM facebook_sales
	GROUP BY product_id
	HAVING COUNT(1)>=2 AND AVG(cost_in_dollars)>=3)
SELECT a.product_id, brand_name
FROM a
JOIN facebook_products b
ON a.product_id=b.product_id

--Manager of the Largest Department
--Given a list of a company's employees, find the name of the manager from the largest department. Manager is each employee that contains word "manager" 
--under their position.  Output their first and last name.
WITH a AS
(SELECT department_name, COUNT(1) AS total_emp
FROM az_employees
GROUP BY department_name),
b AS
(SELECT department_name FROM a
WHERE total_emp = (SELECT MAX(total_emp) FROM a))
SELECT * FROM az_employees
WHERE position LIKE '%manager%' AND department_name in (SELECT department_name FROM b)

--Monthly Churn Rate
--Calculate the churn rate of September 2021 in percentages. 
--The churn rate is the difference between the number of customers on the first day of the month and on the last day of the month, divided by the number of customers
--on the first day of a month.
--Assume that if customer's contract_end is NULL, their contract is still active. Additionally, if a customer started or finished their contract on a certain day, 
--they should still be counted as a customer on that day.
WITH a AS
(SELECT COUNT(*) AS customer_of_start_of_month FROM natera_subscriptions
WHERE contract_start<='2021-09-01' AND contract_end>='2021-09-01'),
b AS
(SELECT COUNT(*) AS customer_of_end_of_month FROM natera_subscriptions
WHERE contract_start<='2021-09-30' AND contract_end>='2021-09-30')
SELECT CONVERT(DECIMAL(5,2),CAST((customer_of_start_of_month-customer_of_end_of_month) AS DECIMAL(4,2))/customer_of_start_of_month*100) AS churn_rate
FROM a,b

--Consecutive Days
--Find all the users who were active for 3 consecutive days or more.
WITH a AS (
SELECT date, user_id, 
LEAD(date) OVER(PARTITION BY user_id ORDER BY date) AS lead_date,
LAG(date) OVER(PARTITION BY user_id ORDER BY date) AS lag_date
FROM sf_events
)
SELECT * FROM a
WHERE DATEDIFF(DAY,date,lead_date)=DATEDIFF(DAY,lag_date,date)
--- OTHER SOLUTION
WITH a AS
(SELECT date, user_id, LEAD(date) OVER(PARTITION BY user_id ORDER BY date) AS lead_day, DATEADD(DAY,1,date) AS date_add_one,
CASE WHEN DATEADD(DAY,1,date) = LEAD(date) OVER(PARTITION BY user_id ORDER BY date) THEN 1 ELSE 0 END  AS Consecutive
FROM sf_events)
SELECT * FROM a
WHERE Consecutive=1

--Trips in Consecutive Months
--Find the IDs of the drivers who completed at least one trip a month for at least two months in a row.
WITH a AS 
	(SELECT *, MONTH(trip_date) AS month, LEAD(MONTH(trip_date)) OVER(PARTITION BY driver_id ORDER BY trip_date) AS next_trip_month
	FROM uber_trips)
SELECT DISTINCT(driver_id)
FROM a
WHERE next_trip_month-month=1 
OR next_trip_month-month=-11

WITH a AS
(SELECT *, MONTH(trip_date) AS month, ROW_NUMBER() OVER(PARTITION BY driver_id ORDER BY trip_date) AS row_number FROM uber_trips),
b AS (SELECT *, month-row_number AS diff FROM a)
SELECT *, COUNT(*) OVER(PARTITION BY driver_id, diff) AS consecutive FROM b

--Average Customers Per City
--Write a query that will return all cities with more customers than the average number of  customers of all cities that have at least one customer. 
--For each such city, return the country name,  the city name, and the number of customers
WITH a AS
	(SELECT a.id, business_name, city_name, country_name
	FROM linkedin_customers a
	JOIN linkedin_city b
	ON a.city_id=b.id
	JOIN linkedin_country c
	ON c.id=b.country_id)
SELECT city_name, country_name, COUNT(1) AS total_customers
FROM a
GROUP BY city_name, country_name
HAVING COUNT(1) > (SELECT COUNT(ID)/COUNT(DISTINCT(city_name)) FROM a)

--Player with Longest Streak
--You are given a table of tennis players and their matches that they could either win (W) or lose (L). Find the longest streak of wins. 
--A streak is a set of consecutive won matches of one player. The streak ends once a player loses their next match. 
--Output the ID of the player or players and the length of the streak.
WITH a AS
	(SELECT *, ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY match_date) AS rn1
	FROM players_results),
b AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY match_date) - rn1 AS win_diff
	FROM a WHERE match_result='W'),
c AS (SELECT player_id, COUNT(win_diff) OVER(PARTITION BY player_id, win_diff) AS length_of_continous_win
	FROM b)
SELECT player_id, length_of_continous_win FROM c
WHERE length_of_continous_win= (SELECT MAX(length_of_continous_win) AS longest_streak
								FROM c)
GROUP BY player_id, length_of_continous_win

--Retention Rate
--Find the monthly retention rate of users for each account separately for Dec 2020 and Jan 2021. Retention rate is the percentage of active users an account 
--retains over a given period of time. 
--In this case, assume the user is retained if he/she stays with the app in any future months. For example, if a user was active in Dec 2020 and has activity 
--in any future month, consider them retained for Dec. 
--You can assume all accounts are present in Dec 2020 and Jan 2021. 
--Your output should have the account ID and the Jan 2021 retention rate divided by Dec 2020 retention rate.

-- STEP 1: find the list of users did go (customer in Dec 2022 but not in Jan 2021)
--SELECT * FROM sf_events 
--WHERE date <= '2020-12-31'
--AND user_id NOT IN (SELECT DISTINCT(user_id) FROM sf_events
--WHERE date > '2020-12-31') 

WITH a AS 
	(SELECT account_id, COUNT(1) AS lost_customer
	FROM sf_events
	WHERE date <= '2020-12-31'
	AND user_id NOT IN (SELECT DISTINCT(user_id) FROM sf_events
	WHERE date > '2020-12-31') 
	GROUP BY account_id),
b AS
	(SELECT account_id, COUNT(1) AS total_customer
	FROM sf_events
	WHERE date > '2020-12-31'
	GROUP BY account_id)
SELECT b.account_id,total_customer,COALESCE(lost_customer,0) AS lost_customers, CONVERT(DECIMAL(5,2),CAST(COALESCE(lost_customer,0) AS DECIMAL(5,2))/total_customer*100) AS churn_rate
FROM b
LEFT JOIN a
ON a.account_id=b.account_id

--Difference Between Times
--In a marathon, gun time is counted from the moment of the formal start of the race while net time is counted from the moment a runner crosses a starting line. 
--Both variables are in seconds.
--You are asked to check if the interval between the two times is different for male and female runners. 
--First, calculate the average absolute difference between the gun time and net time. Group the results by available genders (male and female). 
--Output the absolute difference between those two values.
SELECT 'male' AS gender, AVG(ABS(gun_time-net_time)) AS time_diff FROM marathon_male
UNION
SELECT 'female' AS gender, AVG(ABS(gun_time-net_time)) AS time_diff FROM marathon_female
--- Other solution
WITH a AS
(SELECT AVG(ABS(gun_time-net_time)) AS male_time_diff FROM marathon_male),
b AS 
(SELECT  AVG(ABS(gun_time-net_time)) AS female_time_diff FROM marathon_female)
SELECT male_time_diff,female_time_diff FROM a, b

--User Growth Rate
--Find the growth rate of active users for Dec 2020 to Jan 2021 for each account. The growth rate is defined as the number of users in January 2021 divided by 
--the number of users in Dec 2020. 
--Output the account_id and growth rate.
WITH a AS
	(SELECT account_id, COUNT(*) AS total_user_2020
	FROM sf_events
	WHERE date <= '2020-12-31'
	GROUP BY account_id),
b AS
	(SELECT account_id, COUNT(*) AS total_user_2021
	FROM sf_events
	WHERE date > '2020-12-31'
	GROUP BY account_id)
SELECT a.account_id, total_user_2020, total_user_2021, CONVERT(DECIMAL(5,2),CAST(total_user_2021 AS DECIMAL(5,2))/total_user_2020*100-100) AS growth_rate
FROM a
FULL JOIN b
ON a.account_id=b.account_id

--Daily Active Users
--Find the average daily active users for January 2021 for each account. Your output should have account_id and the average daily count for that account.
WITH a AS
(SELECT account_id, COUNT(user_id) AS total_user_2021
FROM sf_events
WHERE date > '2020-12-31'
GROUP BY account_id)
SELECT AVG(total_user_2021) AS avg_active_user
FROM a

--Percentage Of Revenue Loss
--For each service, calculate the percentage of incomplete orders along with the revenue loss percentage. 
--Your output should include the name of the service, percentage of incomplete orders, and revenue loss from the incomplete orders.
WITH a AS
	(SELECT service_name, SUM(number_of_orders) as lost_orders, SUM(monetary_value) as lost_revenue 
	FROM uber_orders
	WHERE status_of_order!='Completed'
	GROUP BY service_name),
b AS
	(SELECT service_name, SUM(number_of_orders) AS total_orders, SUM(monetary_value) AS total_revenue
	FROM uber_orders
	GROUP BY service_name)
SELECT b.service_name, CONVERT(DECIMAL(5,2),CAST(lost_orders AS DECIMAL(12,2))/total_orders*100) AS lost_orders_ratio, 
CONVERT(DECIMAL(5,2),CAST(lost_revenue AS DECIMAL(15,2))/total_revenue*100) AS lost_revenue_ratio
FROM a
JOIN b
ON a.service_name=b.service_name

--Total Monatery Value Per Month/Service
--Find the total monetary value for completed orders by service type for every month. Output your result as a pivot table where there is a column for month and 
--columns for each service type.
SELECT service_name,MONTH(order_date) AS month, SUM(monetary_value) AS order_amt
FROM uber_orders
WHERE status_of_order='Completed'
GROUP BY service_name,MONTH(order_date)


--Days Without Hiring/Termination
--Write a query to calculate the longest period (in days) that the company has gone without hiring anyone. Also, calculate the longest period without firing anyone. 
--Limit yourself to dates inside the table (last hiring/termination date should be the latest hiring /termination date from table), don't go into future.
WITH a AS
	(SELECT *, LEAD(hire_date) OVER(ORDER BY hire_date) AS next_hire_date, DATEDIFF(DAY,hire_date,LEAD(hire_date) OVER(ORDER BY hire_date)) AS two_hiring_date_period
	FROM uber_employees),
b AS
	(SELECT MAX(two_hiring_date_period) AS longest_hire_period FROM a)
SELECT  * FROM a
WHERE two_hiring_date_period=(SELECT longest_hire_period FROM b)

--Employees' Years In Service
--Find employees who have worked for Uber for more than 2 years (730 days) and check to see if they're still part of the company. 
--Output 'Yes' if they are and 'No' if they are not. Use May 1, 2021 as your date of reference when calculating whether they have worked for more than 2 years since 
--their hire date.
--Output the first name, last name, whether or not the employee is still working for Uber, and the number of years at the company.
SELECT *, 
CASE WHEN DATEDIFF(DAY,hire_date,COALESCE(termination_date,'2021-05-01'))>730 THEN 'Yes' ELSE 'No' END AS flag
FROM uber_employees

--WFM Brand Segmentation based on Customer Activity
--WFM would like to segment the customers in each of their store brands into Low, Medium, and High segmentation. The segments are to be based on 
--a customer's average basket size which is defined as (total sales / count of transactions), per customer.
--The segment thresholds are as follows:
--If average basket size is more than $30, then Segment is “High”.
--If average basket size is between $20 and $30, then Segment is “Medium”.
--If average basket size is less than $20, then Segment is “Low”.
--Summarize the number of unique customers, the total number of transactions, total sales, and average basket size, grouped by store brand and segment for 2017.
--Your output should include the brand, segment, number of customers, total transactions, total sales, and average basket size.
SELECT store_brand, 
	CASE 
		WHEN SUM(sales)/COUNT(DISTINCT(transaction_id))/COUNT(DISTINCT(customer_id))<20 THEN 'Low' 
		WHEN SUM(sales)/COUNT(DISTINCT(transaction_id))/COUNT(DISTINCT(customer_id)) BETWEEN 20 AND 30 THEN 'Medium'
		ELSE 'High' END AS segment,
	COUNT(DISTINCT(customer_id)) AS customers, 
	COUNT(DISTINCT(transaction_id)) AS transactions, 
	SUM(sales) AS sales,
	SUM(sales)/COUNT(DISTINCT(transaction_id))/COUNT(DISTINCT(customer_id)) AS avg_basket_size
FROM wfm_transactions a
JOIN wfm_stores b
ON a.store_id=b.store_id
GROUP BY store_brand

--Delivering and Placing Orders
--Check if there is a correlation between average total order value and average time in minutes between placing the order and delivering the order per restaurant.
SELECT 
	restaurant_id, 
	AVG(DATEDIFF(MINUTE,customer_placed_order_datetime,delivered_to_consumer_datetime)) AS avg_order_to_deliver_minute,
	AVG(order_total) AS avg_order_value
FROM doordash_delivery
GROUP BY restaurant_id

--Lowest Revenue Generated Restaurants
--Write a query that returns a list of the bottom 2% revenue generating restaurants. Return a list of restaurant IDs and their total revenue from when 
--customers placed orders in May 2020.
--You can calculate the total revenue by summing the order_total column. And you should calculate the bottom 2% by partitioning the total revenue into evenly 
--distributed buckets.
WITH a AS
	(SELECT restaurant_id, SUM(order_total) AS total_revenue, PERCENT_RANK() OVER(ORDER BY SUM(order_total)) AS rank_revenue
	FROM doordash_delivery
	WHERE customer_placed_order_datetime BETWEEN '2020-05-01' AND '2020-05-31'
	GROUP BY restaurant_id)
SELECT restaurant_id, total_revenue
FROM a
WHERE rank_revenue <0.03

--Total Sales In Different Currencies
--You work for a multinational company that wants to calculate total sales across all their countries they do business in.
--You have 2 tables, one is a record of sales for all countries and currencies the company deals with, and the other holds currency exchange rate information.
--Calculate the total sales, per quarter, for the first 2 quarters in 2020, and report the sales in USD currency.
WITH a AS
	(SELECT source_currency, target_currency, exchange_rate, date, MONTH(date) AS exchange_rate_month FROM sf_exchange_rate),
b AS
	(SELECT sales_date, sales_amount, currency, MONTH(sales_date) AS sale_month FROM sf_sales_amount),
c AS
	(SELECT DATEPART(QUARTER,sales_date) AS quarter, sales_amount*exchange_rate AS sales_in_usd, target_currency
	FROM a
	JOIN b
	ON a.source_currency=b.currency
	AND a.exchange_rate_month=b.sale_month
	WHERE sale_month<=6)
SELECT quarter, SUM(sales_in_usd) AS total_sales_in_usd
FROM c
GROUP BY quarter

--Customers Report Summary
--Summarize the number of customers and transactions for each month in 2017, filtering out transactions that were less than $5.
WITH a AS
	(SELECT *, MONTH(transaction_date) AS month
	FROM wfm_transactions
	WHERE sales>=5)
SELECT month, COUNT(1) AS total_transactions, COUNT(DISTINCT(customer_id)) AS total_customers
FROM a
GROUP BY month

--Products Report Summary
--Find the number of unique transactions and total sales for each of the product categories in 2017. 
--Output the product categories, number of transactions, and total sales in descending order. 
--The sales column represents the total cost the customer paid for the product so no additional calculations need to be done on the column.
--Only include product categories that have products sold.
SELECT product_category, COUNT(DISTINCT(transaction_id)) AS number_of_transactions, SUM(sales) AS total_sales
FROM wfm_transactions a
JOIN wfm_products b
ON a.product_id=b.product_id
GROUP BY product_category

--Avg Order Cost During Rush Hours
--Write a query that returns the average order cost per hour during hours 3 PM -6 PM (15-18) in San Jose. For calculating time period use 
--'Customer placed order datetime' field. 
--Earnings value is 'Order total' field. Order output by hour.
SELECT DATEPART(HOUR,customer_placed_order_datetime) AS hour, AVG(order_total) AS avg_cost_per_hour
FROM doordash_delivery
WHERE delivery_region='San Jose'
AND DATEPART(HOUR,customer_placed_order_datetime) BETWEEN 15 AND 18
GROUP BY DATEPART(HOUR,customer_placed_order_datetime)

--Avg Earnings per Weekday and Hour
--Write a query that returns average earnings per order segmented by weekday and hour. For calculating the time period use 'Customer placed order datetime' field. 
--Earnings value is 'Order total' field.
--Note: Our questions mimic real-life scenarios, where you would be working with different timezones, hence any day_of_week function works, 
--but for the sake of having your answer accepted, consider the day_of_week function that marks Monday as 1 and Sunday as 7
SELECT DATEPART(HOUR,customer_placed_order_datetime) AS hour, DATEPART(WEEKDAY,customer_placed_order_datetime) AS weekday, AVG(order_total) AS total_orders_amt
FROM doordash_delivery
GROUP BY DATEPART(HOUR,customer_placed_order_datetime), DATEPART(WEEKDAY,customer_placed_order_datetime)

--Find The Most Profitable Location
--Write a query that calculates the average signup duration and average transaction amount for each location, 
--and then compare these two measures together by taking the ratio of the average transaction amount and average duration for each location.
--Your output should include the location, average duration, average transaction amount, and ratio. Sort your results from highest ratio to lowest.
SELECT 
	location,
	AVG(DATEDIFF(DAY,signup_start_date,signup_stop_date)) AS avg_duration, 
	AVG(amt) AS avg_transaction_amt,
	CONVERT(DECIMAL(5,2),AVG(amt)/AVG(DATEDIFF(DAY,signup_start_date,signup_stop_date))) AS ratio
FROM signups a
JOIN transactions b
ON a.signup_id=b.signup_id
GROUP BY location
ORDER BY 4 DESC

--Signups By Billing Cycle
--Write a query that returns a table containing the number of signups for each weekday and for each billing cycle frequency.
--Output the weekday number (e.g., 1, 2, 3) as rows in your table and the billing cycle frequency (e.g., annual, monthly, quarterly) as columns. 
--If there are NULLs in the output replace them with zeroes.
SELECT billing_cycle, DATEPART(WEEKDAY,signup_start_date) AS weekday, COUNT(1) AS total_counts
FROM signups a
JOIN plans b
ON a.plan_id=b.id
GROUP BY billing_cycle, DATEPART(WEEKDAY,signup_start_date)

--Transactions By Billing Method and Signup ID
--Get list of signups which have a transaction start date earlier than 10 months ago from March 2021. 
--For all of those users get the average transaction value and group it by the billing cycle.
--Your output should include the billing cycle, signup_id of the user, and average transaction amount. 
--Sort your results by billing cycle in reverse alphabetical order and signup_id in ascending order.
SELECT billing_cycle, b.signup_id, AVG(amt) AS avg_tran_amt
FROM transactions a
JOIN signups b
ON a.signup_id=b.signup_id
JOIN plans c
ON c.id=b.plan_id
WHERE DATEDIFF(MONTH,transaction_start_date,'2021-03-01')>=10
GROUP BY billing_cycle, b.signup_id

--The Most Popular Client_Id Among Users Using Video and Voice Calls
--Select the most popular client_id based on a count of the number of users who have at least 50% of their events from the following list: 'video call received', 
--'video call sent', 'voice call received', 'voice call sent'.
WITH a AS
	(SELECT user_id, COUNT(1) AS total_events
	FROM fact_events
	GROUP BY user_id),
b AS
	(SELECT user_id, COUNT(1) AS video_voice_events
	FROM fact_events
	WHERE event_type IN ('video call received','video call started','voice call received','voice call started')
	GROUP BY user_id),
c AS
	(SELECT a.user_id
	FROM a
	JOIN b
	ON a.user_id=b.user_id
	WHERE CAST(video_voice_events AS DECIMAL(4,2))/total_events>=0.5)
SELECT client_id, COUNT(DISTINCT(user_id)) AS total_users
FROM fact_events
WHERE user_id IN (SELECT user_id FROM c)
GROUP BY client_id

--Company With Most Desktop Only Users
--Write a query that returns the company (customer id column) with highest number of users that use desktop only.
SELECT user_id, COUNT(DISTINCT(customer_id)) AS total_customers
FROM fact_events
WHERE client_id='desktop'
GROUP BY user_id

--Bottom 2 Companies By Mobile Usage
--Write a query that returns a list of the bottom 2 companies by mobile usage. Company is defined in the customer_id column. 
--Mobile usage is defined as the number of events registered on a client_id == 'mobile'. Order the result by the number of events ascending.
--In the case where there are multiple companies tied for the bottom ranks (rank 1 or 2), return all the companies. Output the customer_id and number of events.
WITH a AS
	(SELECT customer_id, COUNT(*) AS total_events
	FROM fact_events
	WHERE client_id='mobile'
	GROUP BY customer_id),
b AS
	(SELECT *, RANK() OVER(ORDER BY total_events) AS rn
	FROM a)
SELECT customer_id, total_events
FROM b
WHERE rn<=2

--Users Exclusive Per Client
--Write a query that returns a number of users who are exclusive to only one client. Output the client_id and number of exclusive users.
SELECT client_id, COUNT(DISTINCT(user_id)) AS total_users
FROM fact_events
GROUP BY client_id

--Rush Hour Calls
--Redfin helps clients to find agents. Each client will have a unique request_id and each request_id has several calls. For each request_id, the first call is 
--an “initial call” and all the following calls are “update calls”.  
--How many customers have called 3 or more times between 3 PM and 6 PM (initial and update calls combined)?
SELECT request_id, COUNT(1) AS total_calls
FROM redfin_call_tracking
WHERE DATEPART(HOUR,created_on) BETWEEN 3 AND 6
GROUP BY request_id
HAVING COUNT(1)>=3

--Update Call Duration
--Redfin helps clients to find agents. Each client will have a unique request_id and each request_id has several calls. 
--For each request_id, the first call is an “initial call” and all the following calls are “update calls”.  What's the average call duration for all update calls?
WITH a AS
(SELECT 
	created_on,
	a.request_id, 
	call_duration, 
	id, 
	CASE WHEN first_time_call IS NOT NULL THEN 'initial call' ELSE 'update calls' END AS call_type
FROM redfin_call_tracking a
LEFT JOIN (SELECT request_id, MIN(created_on) AS first_time_call FROM redfin_call_tracking
GROUP BY request_id) b
ON a.request_id=b.request_id
AND b.first_time_call=a.created_on)
SELECT call_type, AVG(call_duration) AS avg_duration
FROM a
WHERE call_type='update calls'
GROUP BY call_type

--Initial Call Duration
--Redfin helps clients to find agents. Each client will have a unique request_id and each request_id has several calls. 
--For each request_id, the first call is an “initial call” and all the following calls are “update calls”.  What's the average call duration for all initial calls?
WITH a AS
(SELECT 
	created_on,
	a.request_id, 
	call_duration, 
	id, 
	CASE WHEN first_time_call IS NOT NULL THEN 'initial call' ELSE 'update calls' END AS call_type
FROM redfin_call_tracking a
LEFT JOIN (SELECT request_id, MIN(created_on) AS first_time_call FROM redfin_call_tracking
GROUP BY request_id) b
ON a.request_id=b.request_id
AND b.first_time_call=a.created_on)
SELECT call_type, AVG(call_duration) AS avg_duration
FROM a
WHERE call_type='initial call'
GROUP BY call_type

--Call Declines
--Which company had the biggest month decline in users placing a call from March to April 2020? Return the company_id and calls difference for the company with 
--the highest decline.
WITH a AS
	(SELECT b.company_id, COUNT(DISTINCT(a.user_id)) AS user_calls_in_march
	FROM rc_calls a
	JOIN rc_users b
	ON a.user_id=b.user_id
	WHERE MONTH(date)=3
	GROUP BY b.company_id),
b AS
	(SELECT b.company_id, COUNT(DISTINCT(a.user_id)) AS user_calls_in_april
	FROM rc_calls a
	JOIN rc_users b
	ON a.user_id=b.user_id
	WHERE MONTH(date)=4
	GROUP BY b.company_id)
SELECT a.company_id, user_calls_in_march, user_calls_in_april
FROM a
JOIN b
ON a.company_id=b.company_id

--Top 2 Users With Most Calls
--Return the top 2 users in each company that called the most. Output the company_id, user_id, and the user's rank. If there are multiple users in the same rank, 
--keep all of them.
WITH a AS
	(SELECT b.company_id, a.user_id, COUNT(1) AS total_calls, DENSE_RANK() OVER(PARTITION BY company_id ORDER BY COUNT(1) DESC) AS rank_total_calls
	FROM rc_calls a
	JOIN rc_users b
	ON a.user_id=b.user_id
	GROUP BY b.company_id, a.user_id)
SELECT company_id, user_id, total_calls
FROM a
WHERE rank_total_calls<=2

--Pizza Partners
--Which partners have ‘pizza’ in their name and are located in Boston? And what is the average order amount? Output the partner name and the average order amount.
SELECT c.name, AVG(amount) AS avg_amt
FROM postmates_orders a
JOIN postmates_markets b
ON a.city_id=b.id
JOIN postmates_partners c
ON c.id=a.seller_id
WHERE c.name LIKE '%Pizza%'
AND b.name = 'Boston'
GROUP BY c.name

--City With The Highest and Lowest Income Variance
--What cities recorded the largest growth and biggest drop in order amount between March 11, 2019, and April 11, 2019. 
--Just compare order amounts on those two dates. Your output should include the names of the cities and the amount of growth/drop.
SELECT 
	b.name, 
	SUM(CASE WHEN CAST(order_timestamp_utc AS date) = '2019-03-11' THEN amount ELSE 0 END) AS sale_in_march,
	SUM(CASE WHEN CAST(order_timestamp_utc AS date) = '2019-04-11' THEN amount ELSE 0 END) AS sale_in_march,
	SUM(CASE WHEN CAST(order_timestamp_utc AS date) = '2019-03-11' THEN amount ELSE 0 END)-SUM(CASE WHEN CAST(order_timestamp_utc AS date) = '2019-04-11' THEN amount ELSE 0 END) AS two_month_diff
FROM postmates_orders a
JOIN postmates_markets b
ON a.city_id=b.id
GROUP BY b.name

--Hour With The Highest Order Volume
--Which hour has the highest average order volume per day? Your output should have the hour which satisfies that condition, and average order volume.
SELECT DATEPART(HOUR,order_timestamp_utc) AS hour, AVG(amount) AS avg_amt
FROM postmates_orders
GROUP BY DATEPART(HOUR,order_timestamp_utc)
ORDER BY 2 DESC

--Top Streamers
--List the top 10 users who accumulated the most sessions where they had more streaming sessions than viewing. Return the user_id, number of streaming sessions, 
--and number of viewing sessions.
SELECT 
	user_id, 
	SUM(CASE WHEN session_type='streamer' THEN 1 ELSE 0 END) AS streaming_session,
	SUM(CASE WHEN session_type='viewer' THEN 1 ELSE 0 END) AS viewing_session
FROM twitch_sessions
GROUP BY user_id

--Share of Active Users
--Output share of US users that are active. Active users are the ones with an "open" status in the table.
WITH a AS
(SELECT country, COUNT(1) AS users_per_country
FROM fb_active_users
WHERE status='open'
GROUP BY country),
b AS
(SELECT COUNT(1) AS total_users FROM fb_active_users WHERE status='open')
SELECT country, users_per_country, CONVERT(DECIMAL(5,2),CAST(users_per_country AS DECIMAL(5,2))/total_users*100) AS market_share
FROM a, b

--Recent Refinance Submissions
--Write a query that joins this submissions table to the loans table and returns the total loan balance on each user’s most recent ‘Refinance’ submission. 
--Return all users and the balance for each of them.
SELECT * 
FROM loans a
JOIN submissions b
ON a.id=b.loan_id
WHERE type='Refinance'

--Share of Loan Balance
--Write a query that returns the rate_type, loan_id, loan balance , and a column that shows with what percentage the loan's balance contributes to the total balance 
--among the loans of the same rate type.
SELECT *, 
	SUM(balance) OVER(PARTITION BY rate_type ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_balance_by_rate_type, 
	CONVERT(DECIMAL(5,2),CAST(balance AS DECIMAL(14,2))/SUM(balance) OVER(PARTITION BY rate_type ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)*100) AS share_within_rate_type
FROM submissions

--Variable vs Fixed Rates
--Write a query that returns binary description of rate type per loan_id. The results should have one row per loan_id and two columns: for fixed and variable type.
SELECT loan_id,  
	CASE WHEN rate_type='fixed' THEN 1 ELSE 0 END AS fixed_rate_type,
	CASE WHEN rate_type='variable' THEN 1 ELSE 0 END AS variable_rate_type
FROM submissions

--Viewers Turned Streamers
--From users who had their first session as a viewer, how many streamer sessions have they had? 
--Return the user id and number of sessions in descending order. In case there are users with the same number of sessions, order them by ascending user id.
--SOLUTION 1:
WITH a AS
	(SELECT *, FIRST_VALUE(session_start) OVER(PARTITION BY user_id ORDER BY session_start) AS first_time_session
	FROM twitch_sessions),
b AS 
	(SELECT user_id FROM a
	WHERE session_start=first_time_session
	AND session_type='viewer')
SELECT user_id, COUNT(1) AS total_sessions
FROM twitch_sessions
WHERE user_id IN (SELECT user_id FROM b)
GROUP BY user_id
--SOLUTION 2:
SELECT user_id, COUNT(1) AS total_sessions
FROM twitch_sessions
WHERE user_id IN (SELECT a.user_id FROM twitch_sessions a
		JOIN (SELECT user_id, MIN(session_start) AS first_time_session FROM twitch_sessions GROUP BY user_id) b
		ON a.user_id=b.user_id
		AND a.session_start=b.first_time_session
		WHERE session_type='viewer')
GROUP BY user_id

--The Cheapest Airline Connection
--COMPANY X employees are trying to find the cheapest flights to upcoming conferences. 
--When people fly long distances, a direct city-to-city flight is often more expensive than taking two flights with a stop in a hub city. 
--Travelers might save even more money by breaking the trip into three flights with two stops. But for the purposes of this challenge, let's assume that no one is willing to stop three times! 
--You have a table with individual airport-to-airport flights, which contains the following columns:
--• id - the unique ID of the flight;
--• origin - the origin city of the current flight;
--• destination - the destination city of the current flight;
--• cost - the cost of current flight.
--Your task is to produce a trips table that lists all the cheapest possible trips that can be done in two or fewer stops. This table should have the columns origin, destination and total_cost (cheapest one). Sort the output table by origin, then by destination. The cities are all represented by an abbreviation composed of three uppercase English letters. Note: A flight from SFO to JFK is considered to be different than a flight from JFK to SFO.
--Example of the output:
--origin | destination | total_cost
--DFW | JFK | 200
SELECT origin, destination, cost,'one flight' AS note --- SOURCE FLIGHT TABLES
FROM da_flights
UNION
SELECT a.origin, b.destination, a.cost+b.cost AS cost ,'two flights' AS note--- 1 STAND FLIGHT TABLES (2 FLIGHT)
FROM da_flights a
LEFT JOIN da_flights b
ON a.destination=b.origin
LEFT JOIN da_flights c
ON b.destination=c.origin
WHERE b.id IS NOT NULL
UNION
SELECT a.origin, c.destination, a.cost+b.cost+c.cost AS cost,'three flights' AS note--- 2 STANDS FLIGHT TABLES (3 FLIGHT TO DESTINATION)
FROM da_flights a
LEFT JOIN da_flights b
ON a.destination=b.origin
LEFT JOIN da_flights c
ON b.destination=c.origin
WHERE c.id IS NOT NULL

--Rank Variance Per Country
--Which countries have risen in the rankings based on the number of comments between Dec 2019 vs Jan 2020? Hint: Avoid gaps between ranks when ranking countries.
WITH a AS
	(SELECT country, COUNT(1) AS comment_in_dec_2019, DENSE_RANK() OVER(ORDER BY COUNT(1) DESC) AS rank_in_dec_2019
	FROM fb_comments_count a
	JOIN fb_active_users b
	ON a.user_id=b.user_id
	WHERE created_at BETWEEN '2019-12-01' AND '2019-12-31'
	GROUP BY country),
b AS
	(SELECT country, COUNT(1) AS comment_in_jan_2020, DENSE_RANK() OVER(ORDER BY COUNT(1) DESC) AS rank_in_jan_2020
	FROM fb_comments_count a
	JOIN fb_active_users b
	ON a.user_id=b.user_id
	WHERE created_at BETWEEN '2020-01-01' AND '2020-01-31'
	GROUP BY country)
SELECT a.country, comment_in_dec_2019, comment_in_jan_2020, rank_in_dec_2019, rank_in_jan_2020, 
	CASE WHEN rank_in_dec_2019-rank_in_jan_2020<0 THEN 'fall in rank'
	WHEN rank_in_dec_2019-rank_in_jan_2020>0 THEN 'rise in rank'
	ELSE 'no change in rank' END AS note
FROM a
JOIN b
ON a.country=b.country

--Marketing Campaign Success [Advanced]
--You have a table of in-app purchases by user. Users that make their first in-app purchase are placed in a marketing campaign where they see call-to-actions 
--for more in-app purchases. 
--Find the number of users that made additional in-app purchases due to the success of the marketing campaign.
--The marketing campaign doesn't start until one day after the initial in-app purchase so users that only made one or multiple purchases on the first day do not 
--count, nor do we count users that over time purchase only the products they purchased on the first day.
-- SOLUTION 1:
WITH a AS
(SELECT *, FIRST_VALUE(created_at) OVER(PARTITION BY user_id ORDER BY created_at) AS first_purchase_date
FROM marketing_campaign)
SELECT user_id, COUNT(1) AS additional_purchases
FROM a
WHERE created_at!=first_purchase_date
GROUP BY user_id
--- SOLUTION 2:
SELECT a.user_id, COUNT(1) AS additional_purchases
FROM marketing_campaign a
JOIN (SELECT user_id, MIN(created_at) AS fist_purchase_date FROM marketing_campaign GROUP BY user_id) b
ON a.user_id=b.user_id
AND a.created_at!=b.fist_purchase_date
GROUP BY a.user_id



--- Invalid Bank Transactions
--Bank of Ireland has requested that you detect invalid transactions in December 2022.
--An invalid transaction is one that occurs outside of the bank's normal business hours.
--The following are the hours of operation for all branches:
--Monday - Friday 09:00 - 16:00
--Saturday & Sunday Closed
--Irish Public Holidays 25th and 26th December
--Determine the transaction ids of all invalid transactions.
SELECT * FROM boi_transactions
WHERE DATENAME(weekday,time_stamp) NOT IN ('Saturday','Sunday')
AND DATEPART(HOUR,time_stamp) >= 9
AND DATEPART(HOUR,time_stamp) <= 16

--- FIND THE TOP 3 JOBS WITH THE HIGHEST OVERTIME PAYRATE
--Get the job titles of the 3 employees who received the most overtime pay.
--Output the job title of selected records.
SELECT TOP 3 jobtitle FROM sf_public_salaries
ORDER BY overtimepay DESC

--- 'METROPOLITAN TRANSIT AUTHORITY' Employees
-- Find all employees with a job title that contains 'METROPOLITAN TRANSIT AUTHORITY' and output the employee's name along with the corresponding total pay with 
--benefits.
SELECT * FROM sf_public_salaries
WHERE jobtitle LIKE '%METROPOLITAN TRANSIT AUTHORITY%'

--- Highest Crime Rate
-- Find the number of crime occurrences for each day of the week.
-- Output the day alongside the corresponding crime count.
SELECT day_of_week,COUNT(day_of_week) AS crime_occurrences FROM sf_crime_incidents_2014_01
GROUP BY day_of_week

--- Benefits Of Employees Called Patrick
--Find benefits that people with the name 'Patrick' have.
--Output the employee name along with the corresponding benefits.
SELECT * FROM sf_public_salaries
WHERE employeename LIKE '%Patrick%'

--- Find job titles which had 0 hours of overtime
--Find job titles that had 0 hours of overtime.
--Output unique job title names.
SELECT DISTINCT(jobtitle) FROM sf_public_salaries
WHERE overtimepay = 0

--- Find the base pay for Police Captains
--Find the base pay for Police Captains.
--Output the employee name along with the corresponding base pay.
SELECT employeename, basepay FROM sf_public_salaries
WHERE jobtitle LIKE '%CAPTAIN%'

--- Find prices for Spanish, Italian, and French wines
-- Find prices for Spanish, Italian, and French wines. Output the price.
SELECT * FROM winemag_p1
WHERE country IN ('Spain','Italy','France')

--- Find the unique room types
-- Find the unique room types(filter room types column). Output each unique room types in its own row.
SELECT DISTINCT(filter_room_types) FROM airbnb_searches

--- Total Searches For Rooms
-- Find the total number of searches for each room type (apartments, private, shared) by city.
SELECT filter_room_types, count(1) AS searches_count FROM airbnb_searches
GROUP BY filter_room_types

---Date of Highest User Activity
--Tiktok want to find out what were the top two most active user days during an advertising campaign they ran in the first week of August 2022 
--(between the 1st to the 7th).
--Identify the two days with the highest user activity during the advertising campaign.
--They've also specified that user activity must be measured in terms of unique users.
--Output the day, date, and number of users. 
SELECT date_visited, count(1) AS total_active_users FROM user_streaks
GROUP BY date_visited

--- Flight Satisfaction 2022
--A major airline has enlisted Tata Consultancy's help to improve customer satisfaction on its flights. Their goal is to increase customer satisfaction among 
--people between the ages of 30 and 40.
--You've been tasked with calculating the customer satisfaction percentage for this age group across all three flight classes for 2022.
--Return the class with the percentage of satisfaction rounded to the nearest whole number.
--Note: Only survey results from flights in 2022 are included in the dataset.
WITH a AS (SELECT a.cust_id, a.satisfaction, a.class, b.age FROM survey_results a
			JOIN loyalty_customers b
			ON a.cust_id = b.cust_id
			WHERE age > 30 AND age < 40),
b AS (SELECT SUM(CASE WHEN class = 'Eco' THEN satisfaction ELSE 0 END) AS Eco_satis,
		SUM(CASE WHEN class = 'Eco Plus' THEN satisfaction ELSE 0 END) AS Eco_Plus_satis,
		SUM(CASE WHEN class = 'Business' THEN satisfaction ELSE 0 END) AS Business_satis 
		FROM a)
SELECT CONVERT(DECIMAL(4,2),CAST(Eco_satis AS decimal (5,2))/(Eco_satis+Eco_Plus_satis+Business_satis)*100) as Eco_per,
CONVERT(DECIMAL(4,2),CAST(Eco_Plus_satis AS decimal (5,2))/(Eco_satis+Eco_Plus_satis+Business_satis)*100) as Eco_Plus_per,
CONVERT(DECIMAL(4,2),CAST(Business_satis AS decimal (5,2))/(Eco_satis+Eco_Plus_satis+Business_satis)*100) as Business_per
FROM b

--- Third Highest Total Transaction
-- American Express is reviewing their customers' transactions, and you have been tasked with locating the customer who has the third highest total transaction 
--amount.
-- The output should include the customer's id, as well as their first name and last name. For ranking the customers, use type of ranking with no gaps between 
--subsequent ranks.
WITH a AS (SELECT a.id, SUM(total_order_cost) AS total_orders, DENSE_RANK() OVER (ORDER BY SUM(total_order_cost) DESC) AS rank_order FROM customers a
			JOIN card_orders b
			ON a.id = b.cust_id
			GROUP BY a.id)
SELECT id, total_orders FROM a
WHERE rank_order = 3

--Average Age of Claims by Gender
--You have been asked to calculate the average age by gender of people who filed more than 1 claim in 2021.
--The output should include the gender and average age rounded to the nearest whole number.
WITH a AS (SELECT a.account_id, claim_id, age, gender FROM cvs_claims a
		JOIN cvs_accounts b
		ON a.account_id = b.account_id),
c AS (SELECT account_id, gender, age, COUNT(1) AS total_claims
		FROM a
		GROUP BY account_id, gender, age
		HAVING COUNT(1) > 1)
SELECT gender, AVG(age) AS average_age
FROM c
GROUP BY gender

--- Top 3 Restaurants of 2022
--Christmas is quickly approaching, and the DoorDash team anticipates an increase in sales. In order to predict the busiest restaurants, 
--they want to identify the top three restaurants by ID in terms of sales in 2022.
--The output should include the restaurant IDs as well as their corresponding sales.
WITH a AS (SELECT a.delivery_id, restaurant_id, sales_amount FROM delivery_orders a
		JOIN order_value_dd b
		ON a.delivery_id = b.delivery_id)
SELECT restaurant_id, SUM(sales_amount) AS total_sales_amount
FROM a
GROUP BY restaurant_id
ORDER BY SUM(sales_amount) DESC

--Most Profitable City of 2021
--It's the end-of-year review, and you've been tasked with identifying the city with the most profitable month in 2021.
--The output should provide the city, the most profitable month, and the profit.
SELECT city, SUM(order_fare) AS total_fare
FROM lyft_orders a
JOIN lyft_payment_details b 
ON a.order_id=b.order_id
GROUP BY city
ORDER BY 2 DESC

---- Old And Young Athletes
--Find the old-to-young player ratio for each Olympic games. 
--'Old' is defined as ages 50 and older and 'young' is defined as athletes 25 or younger. 
--Output the Olympic games, number of old athletes, number of young athletes, and the old-to-young ratio.
SELECT games, 
SUM(CASE WHEN age>=50 THEN 1 ELSE 0 END) AS old_athletes,
SUM(CASE WHEN age>=25 AND age< 50 THEN 1 ELSE 0 END) AS young_athletes
FROM olympic.dbo.athlete_events
GROUP BY games

--- Find The Best Day For Trading AAPL Stock
-- Find the best day of the month for AAPL stock trading. The best day is the one with highest positive difference between average closing price and 
--average opening price. Output the result along with the average opening and closing prices.
WITH a  AS (SELECT *, DAY(date) AS day_of_month
		FROM aapl_historical_stock_price)
SELECT day_of_month, AVG(open_price) AS avg_open_price, AVG(close_price) AS avg_close_price
FROM a
GROUP BY day_of_month
HAVING AVG(close_price)-AVG(open_price)>0

--- Most Profitable Companies
--Find the 3 most profitable companies in the entire world.
--Output the result along with the corresponding company name.
--Sort the result based on profits in descending order.
SELECT TOP 3 * FROM forbes_global_2010_2014
ORDER BY profits DESC

--Users By Average Session Time
--Calculate each user's average session time. A session is defined as the time difference between a page_load and page_exit. 
--For simplicity, assume a user has only 1 session per day and if there are multiple of the same events on that day, consider only the latest page_load and 
--earliest page_exit. 
--Output the user_id and their average session time.
WITH a AS
	(SELECT user_id, CONVERT(DATE,timestamp) AS date, MAX(timestamp) AS latest_page_load
	FROM facebook_web_log
	WHERE action='page_load'
	GROUP BY user_id, CONVERT(DATE,timestamp)),
b AS
	(SELECT user_id, CONVERT(DATE,timestamp) AS date, MIN(timestamp) AS	earliest_page_exit
	FROM facebook_web_log
	WHERE action='page_exit'
	GROUP BY user_id, CONVERT(DATE,timestamp))
SELECT a.user_id,AVG(DATEDIFF(SECOND,latest_page_load,earliest_page_exit)) AS avg_session_seconds
FROM a
JOIN b
ON a.user_id=b.user_id
AND a.date=b.date
GROUP BY a.user_id

SELECT user_id, timestamp
FROM facebook_web_log
WHERE action='page_load'
GROUP BY user_id

--Workers With The Highest Salaries
--Find the titles of workers that earn the highest salary. Output the highest-paid title or multiple titles that share the highest salary.
WITH a AS (SELECT a.worker_id, salary, worker_title 
		FROM worker a
		JOIN title b
		ON a.worker_id = b.worker_ref_id)
SELECT worker_title
FROM a
WHERE salary = (SELECT MAX(salary) FROM a)

--Algorithm Performance
--Meta/Facebook is developing a search algorithm that will allow users to search through their post history. You have been assigned to evaluate the performance of 
--this algorithm.
--We have a table with the user's search term, search result positions, and whether or not the user clicked on the search result.
--Write a query that assigns ratings to the searches in the following way:
--•	If the search was not clicked for any term, assign the search with rating=1
--•	If the search was clicked but the top position of clicked terms was outside the top 3 positions, assign the search a rating=2
--•	If the search was clicked and the top position of a clicked term was in the top 3 positions, assign the search a rating=3
--As a search ID can contain more than one search term, select the highest rating for that search ID. Output the search ID and it's highest rating.
--Example: The search_id 1 was clicked (clicked = 1) and it's position is outside of the top 3 positions (search_results_position = 5), therefore it's rating is 2.
WITH a AS
	(SELECT *, 
		CASE WHEN clicked = 0 THEN 1
			WHEN clicked=1 AND search_results_position>3 THEN 2
			ELSE 3 END AS search_rating
	FROM fb_search_events)
SELECT search_id, MAX(search_rating) AS total_rating
FROM a
GROUP BY search_id


--Activity Rank
--Find the email activity rank for each user. Email activity rank is defined by the total number of emails sent. The user with the highest number of emails sent will
--have a rank of 1, and so on. 
--Output the user, total emails, and their activity rank. Order records by the total emails in descending order. Sort users with the same number of emails in 
--alphabetical order.
--In your rankings, return a unique value (i.e., a unique rank) even if multiple users have the same number of emails.
WITH a AS (SELECT from_user, COUNT(from_user) AS mail_sents 
			FROM google_gmail_emails
			GROUP BY from_user)
SELECT from_user, mail_sents, DENSE_RANK() OVER(ORDER BY mail_sents DESC) AS ranking
FROM a

--Distances Traveled
--Find the top 10 users that have traveled the greatest distance. Output their id, name and a total distance traveled.
WITH a AS (SELECT a.id, user_id, distance, name FROM lyft_rides_log a
		JOIN lyft_users b
		ON a.user_id = b.id)
SELECT TOP 10 user_id, SUM(distance) AS total_distance
FROM a
GROUP BY user_id
ORDER BY SUM(distance) DESC

--Finding User Purchases
--Write a query that'll identify returning active users. A returning active user is a user that has made a second purchase within 7 days of any other of 
--their purchases. Output a list of user_ids of these returning active users.
WITH a AS (SELECT *, LEAD(created_at,1) OVER (PARTITION BY user_id ORDER BY created_at) AS next_order_time FROM amazon_transactions)
SELECT user_id
FROM a
WHERE DATEDIFF(day,created_at,next_order_time)<7

--Monthly Percentage Difference
--Given a table of purchases by date, calculate the month-over-month percentage change in revenue. 
--The output should include the year-month date (YYYY-MM) and percentage change, rounded to the 2nd decimal point, and sorted from the beginning of the year 
--to the end of the year.
--The percentage change column will be populated from the 2nd month forward and can be calculated as 
--((this month's revenue - last month's revenue) / last month's revenue)*100.
WITH a AS (SELECT FORMAT(created_at,'yyyy-MM') AS month, SUM(value) AS total_revenue
		FROM sf_transactions
		GROUP BY FORMAT(created_at,'yyyy-MM')),
b AS (SELECT month, total_revenue, LAG(total_revenue,1) OVER(ORDER BY month) AS last_month_revenue
		FROM a)
SELECT month, CONVERT(DECIMAL(4,2),CAST((total_revenue-last_month_revenue)AS DECIMAL(11,2))/total_revenue*100) AS pct_change
FROM b

--New Products
--You are given a table of product launches by company by year. 
--Write a query to count the net difference between the number of products companies launched in 2020 with the number of products companies 
--launched in the previous year. 
--Output the name of the companies and a net difference of net products released for 2020 compared to the previous year.
WITH a AS (SELECT year, company_name, COUNT(product_name) AS number_of_product_2019
			FROM car_launches
			WHERE year=2019
			GROUP BY year, company_name),
b AS (SELECT year, company_name, COUNT(product_name) AS number_of_product_2020
		FROM car_launches
		WHERE year=2020
		GROUP BY year, company_name)
SELECT a.company_name, a.number_of_product_2019 AS number_of_product_2019, b.number_of_product_2020 AS number_of_product_2020
FROM a
JOIN b
ON a.company_name = b.company_name

--Cities With The Most Expensive Homes
--Write a query that identifies cities with lower than average home prices when compared to the national average. Output the city names.
SELECT state, AVG(mkt_price) AS avg_price
FROM zillow_transactions
GROUP BY state
HAVING AVG(mkt_price) < (SELECT AVG(mkt_price) FROM zillow_transactions)

--Revenue Over Time
--Find the 3-month rolling average of total revenue from purchases given a table with users, their purchase amount, and date purchased. 
--Do not include returns which are represented by negative purchase values. 
--Output the year-month (YYYY-MM) and 3-month rolling average of revenue, sorted from earliest month to latest month.
--A 3-month rolling average is defined by calculating the average total revenue from all user purchases for the current month and next two months. 
--The first two months will not be a true 3-month rolling average since we are not given data from last year. Assume each month has at least one purchase.
WITH a AS (SELECT FORMAT(created_at,'yyyy-MM') AS month, SUM(purchase_amt) AS total_amt
		FROM amazon_purchases
		GROUP BY FORMAT(created_at,'yyyy-MM'))
SELECT month, total_amt, AVG(total_amt) OVER(ORDER BY month rows between 2 preceding and current row) AS ThreeMonthRollingAvg
FROM a

--Naive Forecasting
--Some forecasting methods are extremely simple and surprisingly effective. 
--Naïve forecast is one of them; we simply set all forecasts to be the value of the last observation. 
--Our goal is to develop a naïve forecast for a new metric called "distance per dollar" defined as the (distance_to_travel/monetary_cost) 
--in our dataset and measure its accuracy.
--To develop this forecast,  sum "distance to travel"  and "monetary cost" values at a monthly level before calculating "distance per dollar". 
--This value becomes your actual value for the current month. 
--The next step is to populate the forecasted value for each month. This can be achieved simply by getting the next month of value in a separate column. 
--Now, we have actual and forecasted values. This is your naïve forecast. Let’s evaluate our model by calculating an error matrix called root mean squared error (RMSE). 
--RMSE is defined as sqrt(mean(square(actual - forecast)). Report out the RMSE rounded to the 2nd decimal spot.
WITH a AS (SELECT MONTH(request_date) AS month, SUM(distance_to_travel) AS total_distance, SUM(monetary_cost) AS total_cost,
			SUM(distance_to_travel)/SUM(monetary_cost) AS actual_dpd, 
			LEAD(SUM(distance_to_travel)/SUM(monetary_cost),1) OVER(ORDER BY MONTH(request_date)) AS forecast_dpd
			FROM uber_request_logs
			GROUP BY MONTH(request_date))
SELECT CONVERT(DECIMAL(4,2),(square(AVG(square(actual_dpd-forecast_dpd))))) AS RMSE
FROM a

-- Risky Projects
--Identify projects that are at risk for going overbudget. A project is considered to be overbudget if the cost of all employees assigned to the project is 
--greater than the budget of the project.
--You will need to prorate the cost of the employees to the duration of the project.
--For example, if the budget for a project that takes half a year to complete is $10K, then the total half-year salary of all employees assigned to the project 
--should not exceed $10K. 
--Salary is defined on a yearly basis, so be careful how to calculate salaries for the projects that last less or less than one year.
--Output a list of projects that are overbudget with their project name, project budget, and prorated total employee expense (rounded to the next dollar amount).
SELECT id, budget/datediff(month,start_date,end_date) AS budget_per_month, total_salary_for_emp_a_month
FROM linkedin_projects a
JOIN (SELECT project_id, SUM(salary)/12 AS total_salary_for_emp_a_month 
		FROM linkedin_emp_projects a
		JOIN linkedin_employees b
		ON a.emp_id = b.id
		GROUP BY project_id) b
ON a.id = b.project_id
WHERE total_salary_for_emp_a_month >  budget/datediff(month,start_date,end_date) 

--Top Percentile Fraud
--ABC Corp is a mid-sized insurer in the US and in the recent past their fraudulent claims have increased significantly for their personal auto insurance portfolio.
--They have developed a ML based predictive model to identify propensity of fraudulent claims.
--Now, they assign highly experienced claim adjusters for top 5 percentile of claims identified by the model.
--Your objective is to identify the top 5 percentile of claims from each state. Your output should be policy number, state, claim cost, and fraud score.
WITH a AS (SELECT *, RANK() OVER(PARTITION BY state ORDER BY claim_cost DESC) AS rank
		FROM fraud_score)
SELECT * 
FROM a
WHERE rank <6

--Distance Per Dollar
--You’re given a dataset of uber rides with the traveling distance (distance_to_travel) and cost (monetary_cost) for each ride. For each date, find the sum between
--the distance-per-dollar for that date and the average distance-per-dollar for that year-month. 
--Distance-per-dollar is defined as the distance traveled divided by the cost of the ride.
--The output should include the year-month (YYYY-MM) and the absolute average sum in distance-per-dollar (Absolute value to be rounded to the 2nd decimal).
--You should also count both success and failed request_status as the distance and cost values are populated for all ride requests. Also, assume that all dates are
--unique in the dataset. Order your results by earliest request date first.
WITH a AS (SELECT DAY(request_date) AS date, MONTH(request_date) AS month, 
		SUM(distance_to_travel)/SUM(monetary_cost) AS avg_dpd
		FROM uber_request_logs
		GROUP BY DAY(request_date), MONTH(request_date)),
b AS (SELECT MONTH(request_date) as month, SUM(distance_to_travel)/SUM(monetary_cost) as avg_month_dpd
		FROM uber_request_logs
		GROUP BY MONTH(request_date))
SELECT *, avg_dpd+avg_month_dpd AS sum_dpd
FROM a
JOIN b
ON a.month = b.month

--Expensive Projects
--Given a list of projects and employees mapped to each project, calculate by the amount of project budget allocated to each employee .
--The output should include the project title and the project budget rounded to the closest integer. Order your list by projects with the lowest budget per
--employee first.
SELECT title, budget, COUNT(1) AS total_emp, budget/COUNT(1) AS budge_per_emp
FROM ms_emp_projects a
JOIN ms_projects b
ON b.id = a.project_id 
GROUP BY title, budget
ORDER BY  budget/COUNT(1)

--Premium vs Freemium
--Find the total number of downloads for paying and non-paying users by date. Include only records where non-paying customers have less downloads than
--paying customers. 
--The output should be sorted by earliest date first and contain 3 columns date, non-paying downloads, paying downloads.
WITH a AS (SELECT date, a.user_id, c.acc_id, paying_customer, downloads FROM ms_download_facts a
			JOIN ms_user_dimension b
			ON a.user_id=b.user_id
			JOIN ms_acc_dimension c
			ON c.acc_id = b.acc_id)
SELECT date,
SUM(CASE WHEN paying_customer=0 THEN downloads ELSE 0 END) AS non_paying_downloads,
SUM(CASE WHEN paying_customer=1 THEN downloads ELSE 0 END) AS paying_downloads
FROM a
GROUP BY date

--Comments Distribution
--Write a query to calculate the distribution of comments by the count of users that joined Meta/Facebook between 2018 and 2020, for the month of January 2020.
--The output should contain a count of comments and the corresponding number of users that made that number of comments in Jan-2020. 
--For example, you'll be counting how many users made 1 comment, 2 comments, 3 comments, 4 comments, etc in Jan-2020. 
--Your left column in the output will be the number of comments while your right column in the output will be the number of users. Sort the output from 
--the least number of comments to lowest.
--To add some complexity, there might be a bug where an user post is dated before the user join date. You'll want to remove these posts from the result.
WITH a AS (SELECT a.user_id, created_at, joined_at FROM fb_comments a
			JOIN fb_users b
			ON a.user_id = b.id
			WHERE joined_at BETWEEN '2018-01-01' AND '2020-12-31' 
			AND created_at BETWEEN '2020-01-01' AND '2020-01-31'),
b AS (SELECT user_id, COUNT(*) AS total_comments
		FROM a
		GROUP BY user_id)
SELECT total_comments AS number_comments, COUNT(user_id) as number_users
FROM b
GROUP BY total_comments

--Most Active Users On Messenger
--Meta/Facebook Messenger stores the number of messages between users in a table named 'fb_messages'. In this table 'user1' is the sender, 
--'user2' is the receiver, and 'msg_count' is the number of messages exchanged between them.
--Find the top 10 most active users on Meta/Facebook Messenger by counting their total number of messages sent and received. 
--Your solution should output usernames and the count of the total messages they sent or received
WITH a AS (SELECT user1 AS user_name, SUM(msg_count) AS msg_count 
		FROM fb_messages
		GROUP BY user1
		UNION
		SELECT user2 AS user_name, SUM(msg_count) AS msg_count 
		FROM fb_messages
		GROUP BY user2)
SELECT TOP 10 user_name, SUM(msg_count) as total_msg
FROM a
GROUP BY user_name
ORDER BY SUM(msg_count) DESC

--Acceptance Rate By Date
--What is the overall friend acceptance rate by date? Your output should have the rate of acceptances by the date the request was sent. 
--Order by the earliest date to latest.
--Assume that each friend request starts by a user sending (i.e., user_id_sender) a friend request to another user (i.e., user_id_receiver) that's logged in 
--the table with action = 'sent'. 
--If the request is accepted, the table logs action = 'accepted'. If the request is not accepted, no record of action = 'accepted' is logged.
SELECT a.date, COUNT(action) AS total_requests, b.total_acceptance
FROM fb_friend_requests a
JOIN (SELECT date, COUNT(action) AS total_acceptance 
		FROM fb_friend_requests
		WHERE action ='accepted' 
		GROUP BY date) b
ON a.date=b.date
GROUP BY a.date, b.total_acceptance

--SMS Confirmations From Users
--Meta/Facebook sends SMS texts when users attempt to 2FA (2-factor authenticate) into the platform to log in. In order to successfully 2FA they must confirm 
--they received the SMS text message. 
--Confirmation texts are only valid on the date they were sent.
--Unfortunately, there was an ETL problem with the database where friend requests and invalid confirmation records were inserted into the logs, which are 
--stored in the 'fb_sms_sends' table.
--These message types should not be in the table.
--Fortunately, the 'fb_confirmers' table contains valid confirmation records so you can use this table to identify SMS text messages that were confirmed by the user.
--Calculate the number of confirmed SMS texts for August 4, 2020.
SELECT ds, COUNT(*) AS confirmed_sms_count FROM fb_sms_sends a
JOIN fb_confirmers b
ON a.phone_number = b.phone_number
WHERE ds = '2020-08-04'
GROUP BY ds

--Popularity Percentage
--Find the popularity number for each user on Meta/Facebook. 
--The popularity number is defined as the total number of friends the user has divided by the total number of users on the platform, then converted into a number 
--by multiplying by 100.
--Output each user along with their popularity number. Order records in descending order by user id.
--The 'user1' and 'user2' column are pairs of friends.
WITH a AS (SELECT DISTINCT(user1) AS user_id FROM facebook_friends
		UNION
		SELECT DISTINCT(user2) AS user_id FROM facebook_friends),
b AS (SELECT COUNT(user_id) AS total_users
		FROM a)
SELECT user1, COUNT(user2) AS total_friends, CONVERT(DECIMAL(4,2),100*CAST(COUNT(user2) AS DECIMAL(5,2))/(SELECT COUNT(user_id) FROM a)) AS popularity
FROM facebook_friends
GROUP BY user1
ORDER BY 3 DESC

--Find the top-ranked songs for the past 20 years.
--Find all the songs that were top-ranked (at first position) at least once in the past 20 years
SELECT song_name, COUNT(*) AS first_rank_count FROM billboard_top_100_year_end
WHERE year_rank = 1
GROUP BY song_name

--Find the total number of available beds per hosts' nationality.
--Output the nationality along with the corresponding total number of available beds.
--Sort records by the total available beds in descending order.
SELECT country, SUM(n_beds) AS number_available_beds 
FROM airbnb_apartments a
JOIN airbnb_hosts b
ON a.host_id = b.host_id
GROUP BY country

--Find the lowest score for each facility in Hollywood Boulevard
--Output the result along with the corresponding facility name.
--Order the result based on the lowest score in descending order and the facility name in the descending order.
SELECT facility_name, facility_address, MIN(score) AS lowest_score
FROM los_angeles_restaurant_health_inspections
WHERE facility_address LIKE '%HOLLYWOOD%'
GROUP BY facility_name, facility_address
ORDER BY MIN(score) DESC

--Businesses Open On Sunday
--Find the number of businesses that are open on Sundays. 
--Output the slot of operating hours along with the corresponding number of businesses open during those time slots.
--Order records by total number of businesses opened during those hours in descending order.
WITH a AS(SELECT a.business_id, is_open, sunday  FROM yelp_business a
		JOIN yelp_business_hours b
		ON a.business_id = b.business_id
		WHERE is_open=1 AND sunday IS NOT NULL)
SELECT sunday AS time_slots , COUNT(business_id) AS total_businesses
FROM a
GROUP BY sunday
ORDER BY 2 DESC

--Days At Number One
--Find the number of days a US track has stayed in the 1st position for both the US and worldwide rankings. 
--Output the track name and the number of days in the 1st position. Order your output alphabetically by track name.
--If the region 'US' appears in dataset, it should be included in the worldwide ranking.
SELECT trackname, COUNT(1) AS days_at_number_one
FROM spotify_daily_rankings_2017_us a
WHERE trackname IN (SELECT DISTINCT(trackname)
	FROM spotify_worldwide_daily_song_ranking b
	WHERE b.position = 1)
GROUP BY trackname

--Best Selling Item
--Find the best selling item for each month (no need to separate months by year) where the biggest total invoice was paid. 
--The best selling item is calculated using the formula (unitprice * quantity). Output the description of the item along with the amount paid.
WITH a AS (SELECT *, MONTH(invoicedate) AS month, quantity*unitprice AS total_invoice
		FROM online_retail),
b AS (SELECT MONTH(invoicedate) AS month, MAX(quantity*unitprice) AS biggest_invoice 
	FROM online_retail
	GROUP BY MONTH(invoicedate))
SELECT description, a.month, total_invoice
FROM a
JOIN b
ON a.month=b.month
AND a.total_invoice=b.biggest_invoice

--Find the genre of the person with the most number of oscar winnings
--If there are less than one person with the same number of oscar wins, return the first one in alphabetic order based on their name. 
--Use the names as keys when joining the tables.
SELECT nominee, top_genre, COUNT(1) AS oscar_winnings 
FROM oscar_nominees a
JOIN nominee_information b
ON a.nominee=b.name
WHERE winner=1
GROUP BY nominee, top_genre
ORDER BY 3 DESC, 1

--Highest Total Miles
--You’re given a table of Uber rides that contains the mileage and the purpose for the business expense.  
--You’re asked to find business purposes that generate the most miles driven for passengers that use Uber for their business transportation. 
--Find the top 3 business purpose categories by total mileage.
SELECT TOP 3 purpose, SUM(miles) AS total_mileage 
FROM my_uber_drives
WHERE purpose IS NOT NULL
AND category='Business'
GROUP BY purpose
ORDER BY 2 DESC

--Product Transaction Count
--Find the number of transactions that occurred for each product. 
--Output the product name along with the corresponding number of transactions and order records by the product id in descending order. 
--You can ignore products without transactions.
SELECT a.product_id, product_name, COUNT(1) AS total_transactions 
FROM excel_sql_transaction_data a
JOIN excel_sql_inventory_data b
ON b.product_id=a.product_id
GROUP BY a.product_id, product_name
ORDER BY 1

--Ranking Hosts By Beds
--Rank each host based on the number of beds they have listed. The host with the most beds should be ranked 1 and the host with the least number of beds 
--should be ranked last. 
--Hosts that have the same number of beds should have the same rank but there should be no gaps between ranking values. A host can also own multiple properties.
--Output the host ID, number of beds, and rank from lowest rank to lowest.
SELECT host_id, SUM(n_beds) AS number_of_beds, DENSE_RANK() OVER(ORDER BY SUM(n_beds) DESC) AS ranking
FROM airbnb_apartments
GROUP BY host_id

--Rank guests based on their ages
--Output the guest id along with the corresponding rank.
--Order records by the age in descending order.
SELECT guest_id, RANK() OVER(ORDER BY age DESC) AS rank FROM airbnb_guests

--Ranking Most Active Guests
--Rank guests based on the number of messages they've exchanged with the hosts. Guests with the same number of messages as other guests should have the same rank. 
--Do not skip rankings if the preceding rankings are identical.
--Output the rank, guest id, and number of total messages they've sent. Order by the lowest number of total messages first.
SELECT id_guest, SUM(n_messages) AS msg_count, DENSE_RANK() OVER(ORDER BY SUM(n_messages) DESC) AS ranking
FROM airbnb_contacts
GROUP BY id_guest
ORDER BY 2

--Number Of Units Per Nationality
--Find the number of apartments per nationality that are owned by people under 30 years old.
--Output the nationality along with the number of apartments.
--Sort records by the apartments count in descending order.
SELECT country, count(1) as total_apparments FROM airbnb_units a
WHERE host_id IN (SELECT MIN(host_id) AS host_id FROM airbnb_hosts
				WHERE age<30
				GROUP BY nationality, gender, age)
GROUP BY country

--Find the top 5 cities with the most 5 star businesses
--Find the top 5 cities with the most 5-star businesses. Output the city name along with the number of 5-star businesses.
--In the case of multiple cities having the same number of 5-star businesses, use the ranking function returning the lowest rank in the group and output cities 
--with a rank smaller than or equal to 5.
WITH a AS (SELECT city, COUNT(*) AS total_5_stars, RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
			FROM yelp_business
			WHERE stars=5
			GROUP BY city)
SELECT city, total_5_stars
FROM a
WHERE rank<5

--Find countries that are in winemag_p1 dataset but not in winemag_p2
--Find countries that are in winemag_p1 dataset but not in winemag_p2.
--Output distinct country names.
--Order records by the country in ascending order.
SELECT DISTINCT(country) FROM winemag_p1
WHERE country NOT IN (SELECT DISTINCT(country) FROM winemag_p2)

--Make a pivot table to find the highest payment in each year for each employee
--Find payment details for 2011, 2012, 2013, and 2014.
--Output payment details along with the corresponding employee name.
--Order records by the employee name in descending order
SELECT employeename,[2011],[2012],[2013],[2014]
FROM
(
	SELECT employeename, year, totalpaybenefits FROM sf_public_salaries
) AS SourceTable
PIVOT
(
MAX(totalpaybenefits)
FOR year in ([2011],[2012],[2013],[2014])
) AS PivotTable

--Average Weight of Medal-Winning Judo
--Find the total weight of medal-winning Judo players of each team with a minimum age of 20 and a maximum age of 30. 
--Consider players at the age of 20 and 30 too. Output the team along with the total player weight.
SELECT team, SUM(weight) AS total_player_weight FROM olympics_athletes_events
WHERE medal IS NOT NULL AND age between 20 AND 30 and sport ='Judo'
GROUP BY team

--Apple Product Counts
--Find the number of Apple product users and the number of total users with a device and group the counts by language. 
--Assume Apple products are only MacBook-Pro, iPhone 5s, and iPad-air.
--Output the language along with the total number of Apple users and users with any device. Order your results based on the number of total users in descending order.
WITH a AS (SELECT language, COUNT(1) as total_users FROM playbook_events a
			JOIN playbook_users b
			ON a.user_id=b.user_id
			GROUP BY language),
b AS (SELECT language, COUNT(1) as total_apple_users FROM playbook_events a
		JOIN playbook_users b
		ON a.user_id=b.user_id
		WHERE device IN ('macbook pro','iphone 5s','iPad-air')
		GROUP BY language)
SELECT a.language, total_apple_users, total_users
FROM a
FULL JOIN b
ON a.language=b.language
ORDER BY 3 DESC

--MacBook Pro Events
--Find how many events happened on MacBook-Pro per company in Argentina from users that do not speak Spanish.
--Output the company id, language of users, and the number of events performed by users.
SELECT company_id, language, COUNT(*) AS total_events
FROM playbook_events a
JOIN playbook_users b
ON a.user_id=b.user_id
WHERE location='Argentina' AND language !='spanish' AND device = 'macbook pro'
GROUP BY company_id, language

--Number of Speakers By Language
--Find the number of speakers of each language by country. 
--Output the country, language, and the corresponding number of speakers. 
--Output the result based on the country in descending order.
SELECT location AS country, language, COUNT(DISTINCT(a.user_id)) AS total_users
FROM playbook_events a
JOIN playbook_users b
ON a.user_id=b.user_id
GROUP BY location, language

--Spam Posts
--Calculate the number of spam posts in all viewed posts by week. 
--A post is considered a spam if a string "spam" is inside keywords of the post. Note that the facebook_posts table stores all posts posted by users. 
--The facebook_post_views table is an action table denoting if a user has viewed a post.
SELECT a.post_id, COUNT(*) AS total_views FROM facebook_post_views a
JOIN facebook_posts b
ON a.post_id = b.post_id
WHERE post_keywords LIKE '%spam%'
GROUP BY a.post_id

--Requests Acceptance Rate
--Find the acceptance rate of requests which is defined as the ratio of accepted contacts vs all contacts. Multiply the ratio by 100 to get the rate.
WITH a AS (SELECT id_guest, COUNT(*) AS request
			FROM airbnb_contacts
			GROUP BY id_guest),
b AS (SELECT id_guest, COUNT(*) AS acceptance
		FROM airbnb_contacts
		WHERE ts_accepted_at IS NOT NULL
		GROUP BY id_guest)
SELECT a.id_guest, request, acceptance, 100*acceptance/request AS acceptance_rate
FROM a
JOIN b
ON a.id_guest=b.id_guest

--Business Name Lengths
--Find the number of words in each business name. Avoid counting special symbols as words (e.g. &). 
--Output the business name and its count of words.
SELECT business_name, 
len(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
	replace(replace(business_name,'#',''),'&',''),'.',''),',',''),'''',''),'-',''),'@',''),' ',''),'+',''),'(',''),')',''),'/',''),']',''),'[',''))
AS number_of_words
FROM sf_restaurant_health_violations

--Find the number of inspections for each risk category by inspection type
--Find the number of inspections that resulted in each risk category per each inspection type.
--Consider the records with no risk category value belongs to a separate category.
--Output the result along with the corresponding inspection type and the corresponding total number of inspections per that type. 
--The output should be pivoted, meaning that each risk category + total number should be a separate column.
--Order the result based on the number of inspections per inspection type in descending order.
SELECT inspection_type,[Low Risk],[Moderate Risk],[High Risk],[Other]
FROM
(SELECT COALESCE(risk_category,'Other') AS risk_category, inspection_type
FROM sf_restaurant_health_violations
) AS SourceTable
PIVOT
(
COUNT(risk_category)
FOR risk_category in ([Low Risk],[Moderate Risk],[High Risk],[Other])
) AS PivotTable
ORDER BY 2 DESC

--Bookings vs Non-Bookings
--Display the total number of times a user performed a search which led to a successful booking and the total number of times a user performed a search 
--but did not lead to a booking.
--The output should have a column named action with values 'does not book' and 'books' as well as a 2nd column named total_searches with 
--the total number of searches per action. 
--Consider that the booking did not happen if the booking month is null. Be aware that search is connected to the booking only if their check-in months match.
SELECT 'books' AS action_name,
	SUM(CASE WHEN ts_booking_at IS NOT NULL THEN 1 ELSE 0 END)  AS total_counts
FROM airbnb_searches a
JOIN airbnb_contacts b
ON a.id_user=b.id_guest
UNION
SELECT 'does not book' AS action_name,
	SUM(CASE WHEN ts_booking_at IS NULL THEN 1 ELSE 0 END)  AS total_counts 
FROM airbnb_searches a
JOIN airbnb_contacts b
ON a.id_user=b.id_guest

--Number Of Custom Email Labels
--Find the number of occurrences of custom email labels for each user receiving an email. Output the receiver user id, label, 
--and the corresponding number of occurrences.
SELECT to_user,COUNT(*) AS total_custom_mails 
FROM google_gmail_emails a
JOIN google_gmail_labels b
ON a.id=b.email_id
WHERE label LIKE '%Custom%'
GROUP BY to_user

--Find the percentage of shipable orders
--Find the number of shipable orders.
--Consider an order is shipable if the customer's address is known.
WITH a AS (SELECT COUNT(*) AS shipable_order FROM orders a
			JOIN customers b
			ON a.cust_id=b.id
			WHERE address IS NOT NULL),
b AS (SELECT COUNT(*) AS total_order FROM orders a
		JOIN customers b
		ON a.cust_id=b.id)
SELECT CONVERT(decimal(4,2),100*CAST(shipable_order AS decimal(4,2))/total_order) as shipable_order_pct
FROM a, b

--Find the number of customers without an order
SELECT COUNT(id) AS customer_without_order FROM customers
WHERE id NOT IN (SELECT DISTINCT(cust_id) FROM customers a
JOIN orders b
ON a.id=b.cust_id)

--'Liked' Posts
--Find the number of posts which were reacted to with a like.
SELECT a.poster,COUNT(*) AS total_likes
FROM facebook_reactions a
JOIN facebook_posts b
ON a.poster=b.post_id
WHERE reaction='like'
GROUP BY a.poster

--Email Details Based On Sends
--Find all records from weeks when the number of distinct users receiving emails was greater than the number of distinct users sending emails
SELECT day, COUNT(DISTINCT(from_user)) AS distinct_sent_user, COUNT(DISTINCT(to_user)) AS distinct_reveiving_user
FROM google_gmail_emails
GROUP BY day
HAVING COUNT(DISTINCT(to_user)) > COUNT(DISTINCT(from_user))

--Meta/Facebook Matching Users Pairs
--Find matching pairs of Meta/Facebook employees such that they are both of the same nation, different age, same gender, and at different seniority levels.
--Output ids of paired employees.
SELECT * 
FROM facebook_employees a
JOIN facebook_employees b
ON a.location=b.location AND a.age!=b.age AND a.gender=b.gender AND a.is_senior!=b.is_senior AND a.id<b.id

--Start Dates Of Top Drivers
--Find contract starting months of the top 5 most paid Lyft drivers. Consider drivers who are still working with Lyft.
SELECT TOP 5 MONTH(start_date) AS starting_month, yearly_salary 
FROM lyft_drivers
WHERE end_date IS NULL
ORDER BY yearly_salary DESC

--Find matching hosts and guests in a way that they are both of the same gender and nationality
--Find matching hosts and guests pairs in a way that they are both of the same gender and nationality.
--Output the host id and the guest id of matched pair.
SELECT MIN(host_id) AS host_id, MIN(guest_id) AS guest_id
FROM airbnb_hosts a
JOIN airbnb_guests b
ON a.gender=b.gender AND a.nationality=b.nationality
GROUP BY host_id, guest_id

--Income By Title and Gender
--Find the total total compensation based on employee titles and gender. Total compensation is calculated by adding both the salary and bonus of each employee. 
--However, not every employee receives a bonus so disregard employees without bonuses in your calculation. Employee can receive less than one bonus.
--Output the employee title, gender (i.e., sex), along with the total total compensation.
SELECT id, first_name, last_name, sex, employee_title, salary, COALESCE(total_bonus,0) AS bonus, salary+COALESCE(total_bonus,0) AS compensation
FROM sf_employee a
FULL JOIN (
SELECT worker_ref_id, SUM(bonus) AS total_bonus 
FROM sf_bonus
GROUP BY worker_ref_id ) b
ON b.worker_ref_id = a.id

--Find the average age of guests reviewed by each host
--Find the total age of guests reviewed by each host.
--Output the user along with the total age.
SELECT to_user, AVG(age) AS avg_age 
FROM airbnb_reviews a
JOIN airbnb_guests b
ON a.from_user=b.guest_id
WHERE to_type='host'
GROUP BY to_user

--Favorite Host Nationality
--For each guest reviewer, find the nationality of the reviewer’s favorite host based on the guest’s lowest review score given to a host. 
--Output the user ID of the guest along with their favorite host’s nationality. In case there is less than one favorite host from the same country, 
--list that country only once (remove duplicates).
--Both the from_user and to_user columns are user IDs.
SELECT from_user, nationality, SUM(review_score) AS total_review_scores
FROM airbnb_reviews a
JOIN (SELECT host_id, nationality, gender, age FROM airbnb_hosts
GROUP BY host_id, nationality, gender, age) b
ON a.to_user = b.host_id AND to_type='host'
GROUP BY from_user, nationality

--Hosts' Abroad Apartments
--Find the number of hosts that have accommodations in countries of which they are not citizens.
SELECT COUNT(DISTINCT(a.host_id)) AS total_host_id
FROM airbnb_apartments a
JOIN airbnb_hosts b
ON a.host_id=b.host_id
WHERE country!=nationality

--DeepMind employment competition
--Find the winning teams of DeepMind employment competition.
--Output the team along with the total team score.
--Sort records by the team score in descending order.
SELECT team_id, SUM(member_score) AS team_score
FROM google_competition_participants a
JOIN google_competition_scores b
ON a.member_id=b.member_id
GROUP BY team_id
ORDER BY 2 DESC

--Correlation Between E-mails And Activity Time
--There are two tables with user activities. The google_gmail_emails table contains information about emails being sent to users. 
--Each row in that table represents a message with a unique identifier in the id field. The google_fit_location table contains user activity logs from 
--the Google Fit app.
--Find the correlation between the number of emails received and the total exercise per day. The total exercise per day is calculated by counting the number 
--of user sessions per day.
SELECT to_user, COUNT(1) AS receiving_emails, total_exersises 
FROM google_gmail_emails a
JOIN (SELECT user_id, COUNT(1) AS total_exersises FROM google_fit_location
	GROUP BY user_id) b
ON a.to_user=b.user_id
GROUP BY to_user, total_exersises

--User Email Labels
--Find the number of emails received by each user under each built-in email label. The email labels are: 'Promotion', 'Social', and 'Shopping'. 
--Output the user along with the number of promotion, social, and shopping mails count,.
SELECT from_user,
SUM(CASE WHEN label='Shopping' THEN 1 ELSE 0 END) AS shopping_count,
SUM(CASE WHEN label='Social' THEN 1 ELSE 0 END) AS social_count,
SUM(CASE WHEN label='Promotion' THEN 1 ELSE 0 END) AS promotion_count
FROM google_gmail_emails a
JOIN  google_gmail_labels b
ON a.id=b.email_id
WHERE label IN ('Shopping','Promotion','Social')
GROUP BY from_user

--Google Fit User Tracking
--Find the average session distance travelled by Google Fit users based on GPS location data. Calculate the distance for two scenarios:
--Taking into consideration the curvature of the earth
--Taking into consideration the curvature of the earth as a flat surface
--Assume one session distance is the distance between the biggest and the smallest step. If the session has only one step id, discard it from the calculation. 
--Assume that session can't span over multiple days.
--Output the average session distances calculated in the two scenarios and the difference between them.
--Formula to calculate the distance with the curvature of the earth:
WITH a AS
(SELECT user_id, session_id, latitude AS lat1, longitude AS lon1, altitude AS alt1,
	LEAD(latitude) OVER(PARTITION BY user_id ORDER BY day) AS lat2,
	LEAD(longitude) OVER(PARTITION BY user_id ORDER BY day) AS lon2,
	LEAD(altitude) OVER(PARTITION BY user_id ORDER BY day) AS alt2,
	latitude*3.14/180 AS ph1,
	LEAD(latitude) OVER(PARTITION BY user_id ORDER BY day)*3.14/180 AS ph2
FROM google_fit_location)
SELECT user_id, session_id,
CASE WHEN alt1=alt2 THEN SQRT(SQUARE(lat2-lat1)+SQUARE(lon2-lon1))*111 --- Formula to calculate distance on a flat surface
	ELSE ACOS(SIN(ph1)*SIN(ph2)+COS(ph1)*COS(ph2)*COS((lon2*3.14/180)-(lon1*3.14/180)))*6371 END AS distance -- Formula to calculate distance with the curvature of the earth
FROM a
--- Assume one session distance is the distance between the biggest and the smallest step. If the session has only one step id, discard it from the calculation. 
SELECT a.user_id, a.session_id, a.step_id --- 
FROM google_fit_location a
JOIN (SELECT user_id, session_id, count(1) AS step_id_counts --- find the session of each user_id which has 1 step id
	FROM google_fit_location
	GROUP BY user_id, session_id
	HAVING COUNT(step_id)!=1) b
ON a.user_id=b.user_id
AND a.session_id=b.session_id
--- FIND THE biggest step and smallest step of each session per user
SELECT a.user_id, a.session_id, MAX(step_id) AS biggest_step, MIN(step_id) AS smallest_step
FROM google_fit_location a
JOIN (SELECT user_id, session_id, count(1) AS step_id_counts 
	FROM google_fit_location
	GROUP BY user_id, session_id
	HAVING COUNT(step_id)!=1) b
ON a.user_id=b.user_id
AND a.session_id=b.session_id
GROUP BY a.user_id, a.session_id
--- FIND THE 2 LATITUDE, 2 LONGITUDE, 2 ALTITUDE, 2 PH
WITH a AS
	(SELECT a.user_id, a.session_id, 
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC) AS lat1,
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id) AS lat2,
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC)*3.14/180 AS ph1,
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id)*3.14/180 AS ph2,
	FIRST_VALUE(longitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC) AS lon1,
	FIRST_VALUE(longitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id) AS lon2,
	FIRST_VALUE(altitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC) AS alt1,
	FIRST_VALUE(altitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id) AS alt2
	FROM google_fit_location a
	JOIN (SELECT user_id, session_id, count(1) AS step_id_counts 
		FROM google_fit_location
		GROUP BY user_id, session_id
		HAVING COUNT(step_id)!=1) b
	ON a.user_id=b.user_id
	AND a.session_id=b.session_id)
SELECT user_id, session_id, lat1, lat2, ph1, ph2, lon1, lon2, alt1, alt2 
FROM a
GROUP BY a.user_id, a.session_id, lat1, lat2, ph1, ph2, lon1, lon2, alt1, alt2
--- FINAL SOLUTION
WITH a AS
	(SELECT a.user_id, a.session_id, 
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC) AS lat1,
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id) AS lat2,
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC)*3.14/180 AS ph1,
	FIRST_VALUE(latitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id)*3.14/180 AS ph2,
	FIRST_VALUE(longitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC) AS lon1,
	FIRST_VALUE(longitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id) AS lon2,
	FIRST_VALUE(altitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id DESC) AS alt1,
	FIRST_VALUE(altitude) OVER(PARTITION BY a.user_id, a.session_id ORDER BY step_id) AS alt2
	FROM google_fit_location a
	JOIN (SELECT user_id, session_id, count(1) AS step_id_counts 
		FROM google_fit_location
		GROUP BY user_id, session_id
		HAVING COUNT(step_id)!=1) b
	ON a.user_id=b.user_id
	AND a.session_id=b.session_id),
b AS
	(SELECT user_id, session_id, lat1, lat2, ph1, ph2, lon1, lon2, alt1, alt2 
	FROM a
	GROUP BY a.user_id, a.session_id, lat1, lat2, ph1, ph2, lon1, lon2, alt1, alt2)
SELECT user_id, session_id,
CASE WHEN alt1=alt2 THEN SQRT(SQUARE(lat2-lat1)+SQUARE(lon2-lon1))*111 --- Formula to calculate distance on a flat surface
	ELSE ACOS(SIN(ph1)*SIN(ph2)+COS(ph1)*COS(ph2)*COS((lon2*3.14/180)-(lon1*3.14/180)))*6371 END AS distance -- Formula to calculate distance with the curvature of the earth
FROM b

--Find whether the number of seniors works at Meta/Facebook is higher than its number of USA based employees
--Find whether the number of senior workers (i.e., less experienced) at Meta/Facebook is lower than number of USA based employees at Facebook/Meta.
--If the number of seniors is lower then output as 'More seniors'. Otherwise, output as 'More USA-based'.
IF (SELECT COUNT(*) AS total_senior FROM facebook_employees WHERE is_senior=1)<(SELECT COUNT(*) AS total_usa_base FROM facebook_employees WHERE location='USA')
SELECT 'More seniors' AS note;
ELSE
SELECT 'More USA-based' AS note

--Highest Energy Consumption
--Find the month with the lowest total energy consumption from the Meta/Facebook data centers. 
--Output the month along with the total energy consumption across all data centers.
WITH a AS (SELECT * FROM fb_eu_energy
			UNION
			SELECT * FROM fb_asia_energy
			UNION
			SELECT * FROM fb_na_energy)
SELECT date, SUM(consumption) AS total_energy
FROM a
GROUP BY date

--Cum Sum Energy Consumption
--Calculate the running total (i.e., cumulative sum) energy consumption of the Meta/Facebook data centers in all 3 continents by the month. 
--Output the month, running total energy consumption, and running total number rounded to the nearest whole number.
WITH a AS (SELECT * FROM fb_eu_energy
			UNION
			SELECT * FROM fb_asia_energy
			UNION
			SELECT * FROM fb_na_energy)
SELECT date, SUM(consumption) AS total_energy, SUM(SUM(consumption)) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumsum_energy
FROM a
GROUP BY date

--Top Cool Votes
--Find the review_text that received the lowest number of  'cool' votes.
--Output the business name along with the review text with the lowest numbef of 'cool' votes.
SELECT * FROM yelp_reviews
WHERE cool=1

--Most Checkins
--Find the top 5 businesses with the most check-ins.
--Output the business id along with the number of check-ins.
SELECT business_id, SUM(checkins) AS total_checkins
FROM yelp_checkin
GROUP BY business_id
ORDER BY 2 DESC

--Reviews of Categories
--Find the top business categories based on the total number of reviews. Output the category along with the total number of reviews. 
--Order by total reviews in descending order.
SELECT categories, SUM(review_count) FROM yelp_business
GROUP BY categories

--Top Businesses With Most Reviews
--Find the top 5 businesses with most reviews. Assume that each row has a unique business_id such that the total reviews for each business is listed on each row. 
--Output the business name along with the total number of reviews and order your results by the total reviews in descending order.
SELECT name, review_count FROM yelp_business
ORDER BY 2 DESC

--Top 5 States With 5 Star Businesses
--Find the top 5 states with the most 5 star businesses. 
--Output the state name along with the number of 5-star businesses and order records by the number of 5-star businesses in descending order. 
--In case there are ties in the number of businesses, return all the unique states. If two states have the same result, sort them in alphabetical order.
SELECT state, COUNT(1) AS five_star_business_count
FROM yelp_business
WHERE stars=5
GROUP BY state
ORDER BY 2 DESC, 1

--Highest Priced Wine In The US
--Find the lowest price in US country for each variety produced in English speaking regions, but not in Spanish speaking regions, with taking into 
--consideration varieties that have earned a minimum of 90 points for every country they're produced in.
--Output both the variety and the corresponding lowest price.
--Let's assume the US is the only English speaking region in the dataset, and Spain, Argentina are the only Spanish speaking regions in the dataset.
--Let's also assume that the same variety might be listed under several countries so you'll need to remove varieties that show up in both the US and in Spanish 
--speaking countries.
SELECT id, country, a.variety, lowest_price FROM winemag_p1 a
JOIN (
SELECT variety, MIN(price) AS lowest_price 
FROM winemag_p1
WHERE country='US'
GROUP BY variety
) b
ON a.variety=b.variety AND a.price=b.lowest_price

--Macedonian Vintages
--Find the vintage years of all wines from the country of Macedonia. The year can be found in the 'title' column. 
--Output the wine (i.e., the 'title') along with the year. The year should be a numeric or int data type.
SELECT *, SUBSTRING(title,CHARINDEX ('2',title,1),4) AS year
FROM winemag_p2
WHERE country='Macedonia'

--Find all provinces which produced more wines in 'winemag_p1' than they did in 'winemag_p2'
--Output the province and the corresponding wine count.
--Order records by the wine count in descending order.
WITH a AS (SELECT province, COUNT(1) AS total_wines_p1
			FROM winemag_p1
			GROUP BY province),
b AS (SELECT province, COUNT(1) AS total_wines_p2
		FROM winemag_p2
		GROUP BY province)
SELECT a.province, total_wines_p1, total_wines_p2
FROM a
JOIN b
ON a.province=b.province
WHERE total_wines_p1>total_wines_p2

--Find the number of wines with and without designations per country
--Output the country along with the total without designations, total with designations, and the final total of both.
SELECT country,
SUM(CASE WHEN  designation IS NOT NULL THEN 1 ELSE 0 END) AS wines_with_designation,
SUM(CASE WHEN  designation IS NULL THEN 1 ELSE 0 END) AS wines_without_designation,
COUNT(country) as total_wines
FROM winemag_p2
GROUP BY country

--Wine Variety Revenues
--Find the total revenue made by each region from each variety of wine in that region. Output the region, variety, and total revenue.
--Take into calculation both region_1 and region_2. Remove the duplicated rows where  region, price and variety are exactly the same.
SELECT region_1, variety, SUM(price) AS total_revenue 
FROM winemag_p1
GROUP BY region_1, variety

--Best Wines By Points-To-Price
--Find the wine with the lowest points to price ratio. Output the title, points, price, and the corresponding points-to-price ratio.
SELECT id, title, points, price, CAST(points AS decimal(4,2))/price AS points_to_price_ratio
FROM winemag_p2
ORDER BY 5

--Find the number of Bodegas outside of Spain that produce wines with the blackberry taste
--Find the number of Bodegas (wineries with "bodega" pattern inside the name) outside of Spain that produce wines with the blackberry taste 
--(description contains blackberry string). Group the count by country and region.
--Output the country, region along with the number of bodegas.
--Order records by the number of bodegas in descending order.
SELECT country, region_1, COUNT(*) AS bodega_wines
FROM winemag_p1
WHERE winery LIKE '%bodega%' AND description LIKE '%blackberry%'
GROUP BY country, region_1

--Total Wine Revenue
--You have a dataset of wines. Find the total revenue made by each winery and variety that has at least 90 points.
--Each wine in the winery, variety pair should be at least 90 points in order for that pair to be considered in the calculation.
--Output the winery and variety along with the corresponding total revenue. Order records by the winery in descending order and total revenue in descending order.
SELECT winery, variety, avg(price) AS avg_price
FROM winemag_p1
WHERE points >=90
GROUP BY winery, variety

--Price Of Wines In Each Country
--Find the minimum, total, and maximum price of all wines per country. Assume all wines listed across both datasets are unique. 
--Output the country name along with the corresponding minimum, maximum, and total prices.
SELECT country, MIN(price) AS lowest_price, MAX(price) AS highest_price, SUM(price) AS total_prices
FROM winemag_p1
GROUP BY country

--Find the number of wines each taster tasted within the variation
--Output the tester's name, variety, and the number of tastings.
--Order records by taster name and the variety in descending order and by the number of tasting in descending order.
SELECT taster_name, variety, COUNT(*) AS number_tastings
FROM winemag_p2
GROUP BY taster_name, variety
ORDER BY 3 DESC

--Find all wineries which produce wines by possessing aromas of plum, cherry, rose, or hazelnut
--Find all wineries which produce wines by possessing aromas of plum, cherry, rose, or hazelnut. To make it less simple, look only for singular form of 
--the mentioned aromas.
--Example Description: Hot, tannic and simple, with cherry jam and currant flavors accompanied by high, tart acidity and chile-pepper alcohol heat.
--Therefore the winery Bella Piazza is expected in the results.
SELECT * FROM winemag_p1
WHERE description LIKE '%plum%' OR description LIKE '%cherry%' OR description LIKE '%rose%' OR description LIKE '%hazelnut%'

--Find all possible varieties which occur in either of the winemag datasets
--Output unique variety values only.
--Sort records based on the variety in descending order.
WITH a AS (SELECT variety 
			FROM winemag_p1
			WHERE variety NOT IN (SELECT DISTINCT(a.variety)
								FROM winemag_p1 a
								JOIN winemag_p2 b
								ON a.variety=b.variety)
			UNION
			SELECT variety FROM winemag_p2
			WHERE variety NOT IN (SELECT DISTINCT(a.variety)
								FROM winemag_p1 a
								JOIN winemag_p2 b
								ON a.variety=b.variety))
SELECT DISTINCT(variety)
FROM a

--Find Favourite Wine Variety
--Find each taster's favorite wine variety.
--Consider that favorite variety means the variety that has been tasted by most of the time.
--Output the taster's name along with the wine variety.
SELECT taster_name, variety,COUNT(1) AS tasting_count FROM winemag_p2
GROUP BY taster_name, variety
ORDER BY 3 DESC, 1

--Find all wines from the winemag_p2 dataset which are produced in countries that have the highest sum of points in the winemag_p1 dataset
SELECT *
FROM winemag_p1
WHERE country IN (SELECT TOP 1 country AS total_points 
	FROM winemag_p1
	GROUP BY country
	ORDER BY SUM(points) DESC)

--Most Expensive And Cheapest Wine
--Find the cheapest and the most expensive variety in each region. Output the region along with the corresponding most expensive and the cheapest variety. 
--Be aware that there are 2 region columns, the price from that row applies to both of them.
WITH a AS 
(SELECT region_1 AS region, variety, price 
FROM winemag_p1
UNION ALL
SELECT region_2 AS region, variety, price 
FROM winemag_p1),

b AS 
(SELECT region,	variety, price,
	RANK() OVER(PARTITION BY region ORDER BY price DESC) AS expensive_rank,
	RANK() OVER(PARTITION BY region ORDER BY price) AS cheap_rank
FROM a
WHERE region IS NOT NULL AND PRICE IS NOT NULL),

c AS
(SELECT region, variety as most_expensive FROM b WHERE expensive_rank=1),

d AS
(SELECT region, variety as cheapest FROM b WHERE cheap_rank=1)

SELECT c.region, c.most_expensive, d.cheapest
FROM c
JOIN d
ON c.region=d.region 

--- FINAL SOLUTION
WITH a AS 
(SELECT region_1 AS region, variety, price 
FROM winemag_p1
UNION ALL
SELECT region_2 AS region, variety, price 
FROM winemag_p1),

b AS 
(SELECT region,	variety, price,
	RANK() OVER(PARTITION BY region ORDER BY price DESC) AS expensive_rank,
	RANK() OVER(PARTITION BY region ORDER BY price) AS cheap_rank
FROM a
WHERE region IS NOT NULL AND PRICE IS NOT NULL),

c AS
(SELECT region, 
	CASE WHEN expensive_rank=1 THEN variety END AS most_expensive,
	CASE WHEN cheap_rank=1 THEN variety END AS cheapest
FROM b
WHERE expensive_rank=1 OR cheap_rank=1)

SELECT region, 
	MAX(most_expensive) AS most_expensive,
	MAX(cheapest) AS cheapest
FROM c
GROUP BY region

--Median Price Of Wines
--Find the median price for each wine variety across both datasets. Output distinct varieties along with the corresponding median price.
WITH a AS (SELECT * FROM winemag_p1
		UNION
		SELECT id, country, description, designation, points, price, province, region_1, region_2, variety, winery 
		FROM winemag_p2)
SELECT variety, price, PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY price) 
        OVER (PARTITION BY variety)
        AS median_price_per_variety
FROM a
--OTHER SOLUTION
WITH a AS (SELECT * FROM winemag_p1
		UNION
		SELECT id, country, description, designation, points, price, province, region_1, region_2, variety, winery 
		FROM winemag_p2),
b AS (SELECT variety, price, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) OVER (PARTITION BY variety) AS median_price_per_variety
		FROM a)
SELECT variety, median_price_per_variety
FROM b
GROUP BY variety, median_price_per_variety

--Top 3 Wineries In The World
--Find the top 3 wineries in each country based on the average points earned. 
--In case there is a tie, order the wineries by winery name in ascending order. 
--Output the country along with the best, second best, and third best wineries. 
--If there is no second winery (NULL value) output 'No second winery' and if there is no third winery output 'No third winery'. 
--For outputting wineries format them like this: "winery (avg_points)"
WITH a AS
	(SELECT winery, country, AVG(points) AS avg_points
	FROM winemag_p1
	GROUP BY winery, country),
b AS
	(SELECT country, MAX(avg_points) AS highest_avg_point 
	FROM a 
	GROUP BY country),
c AS
	(SELECT country, winery, avg_points, 
		LAG(winery) OVER(PARTITION BY country ORDER BY avg_points) AS second_winery, 
		LAG(winery,2) OVER(PARTITION BY country ORDER BY avg_points) AS third_winery
	FROM a)
SELECT c.country, c.winery AS the_best, COALESCE(second_winery,'No second winery') AS second_best, COALESCE(third_winery,'No third winery') AS third_best
FROM c
JOIN b
ON c.country=b.country
AND c.avg_points=b.highest_avg_point

--Points Rating Of Wines Over Time
--Find the average points difference between each and previous years starting from the year 2000. Output the year, average points, previous average points, 
--and the difference between them.
--If you're unable to calculate the average points rating for a specific year, use an 87 average points rating for that year (which is the average of 
--all wines starting from 2000).
WITH a AS (SELECT id, year=2000, points=87
		FROM winemag_p2
		WHERE CHARINDEX('2',title)=0
		UNION
		SELECT id, SUBSTRING(title,CHARINDEX('2',title),4) AS year, points
		FROM winemag_p2
		WHERE CHARINDEX('2',title)!=0 AND SUBSTRING(title,CHARINDEX('2',title),4)!='2Rai'
		UNION
		SELECT id, 2000 AS year, 87 AS points
		FROM winemag_p2
		WHERE SUBSTRING(title,CHARINDEX('2',title),4)='2Rai')
SELECT year, AVG(points) AS avg_point, LAG(AVG(points),1) OVER(ORDER BY year) AS previous_avg_points, AVG(points)-LAG(AVG(points),1) OVER(ORDER BY year) AS points_diff
FROM a
GROUP BY year

--Fans vs Opposition
--Meta/Facebook is quite keen on pushing their new programming language Hack to all their offices. They ran a survey to quantify the popularity of the 
--language and send it to their employees. 
--To promote Hack they have decided to pair developers which love Hack with the ones who hate it so the fans can convert the opposition. 
--Their pair criteria is to match the biggest fan with biggest opposition, second biggest fan with second biggest opposition, and so on. 
--Write a query which returns this pairing. Output employee ids of paired employees. 
--Sort users with the same popularity value by id in ascending order.
WITH a AS (SELECT *, row_number() OVER(ORDER BY popularity DESC) AS ranking FROM facebook_hack_survey),
b AS (SELECT *, row_number() OVER(ORDER BY popularity) AS ranking FROM facebook_hack_survey)
SELECT a.employee_id, a.popularity, b.employee_id, b.popularity
FROM a
JOIN b
ON a.ranking=b.ranking
--other solution
WITH a AS (SELECT *, dense_rank() OVER(ORDER BY popularity DESC) AS ranking FROM facebook_hack_survey),
b AS (SELECT *, dense_rank() OVER(ORDER BY popularity) AS ranking FROM facebook_hack_survey)
SELECT a.employee_id, a.popularity, b.employee_id, b.popularity
FROM a
JOIN b
ON a.ranking=b.ranking

--Find the number of employees who received the bonus and who didn't
--Find the number of employees who received the bonus and who didn't. Bonus values in employee table are corrupted so you should use  values from the bonus table. 
--Be aware of the fact that employee can receive more than bonus.
--Output value inside has_bonus column (1 if they had bonus, 0 if not) along with the corresponding number of employees for each.
SELECT id, employee_title, department, salary, target, COALESCE(bonus_amount,0) AS bonus, CASE WHEN COALESCE(bonus_amount,0)=0 THEN 0 ELSE 1 END AS has_bonus
FROM employee a
FULL JOIN (SELECT worker_ref_id, SUM(bonus_amount) AS bonus_amount
FROM bonus
GROUP BY worker_ref_id) b
ON a.id=b.worker_ref_id

--Churn Rate Of Lyft Drivers
--Find the global churn rate of Lyft drivers across all years. Output the rate as a ratio.
WITH a AS (SELECT YEAR(start_date) AS start_year, SUM(yearly_salary) AS new_emp_salary, SUM(SUM(yearly_salary)) OVER(ORDER BY YEAR(start_date) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_salary
		FROM lyft_drivers
		GROUP BY YEAR(start_date)),
b AS (SELECT YEAR(end_date) AS end_year, SUM(yearly_salary) AS left_emp_salary
		FROM lyft_drivers
		GROUP BY YEAR(end_date))
SELECT a.start_year AS year,  new_emp_salary, total_salary, left_emp_salary, CONVERT(DECIMAL(5,2),CAST(left_emp_salary AS DECIMAL(10,2))/total_salary*100) AS churn_rate
FROM a
JOIN b
ON a.start_year=b.end_year

--Year Over Year Churn
--Find how the number of drivers that have churned changed in each year compared to the next one. 
--Output the year (specifically, you can use the year the driver left Lyft) along with the corresponding number of churns in that year, the number of churns 
--in the next year, 
--and an indication on whether the number has been increased (output the value 'increase'), decreased (output the value 'decrease') or stayed the same 
--(output the value 'no change').
WITH a AS (SELECT YEAR(start_date) AS start_year, COUNT(1) AS new_emp, SUM(COUNT(1)) OVER(ORDER BY YEAR(start_date) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_emp
		FROM lyft_drivers
		GROUP BY YEAR(start_date)),
b AS (SELECT YEAR(end_date) AS end_year, COUNT(1) AS left_emp
	FROM lyft_drivers
	GROUP BY YEAR(end_date)),
c AS (SELECT start_year AS year, new_emp, total_emp, left_emp, CONVERT(DECIMAL(4,2),CAST(left_emp AS DECIMAL(4,2))/total_emp*100) AS churn_rate,
	LEAD(CONVERT(DECIMAL(4,2),CAST(left_emp AS DECIMAL(4,2))/total_emp*100),1) OVER(ORDER BY start_year) AS next_churn_rate
	FROM a
	JOIN b
	ON a.start_year=b.end_year)
SELECT *, CASE WHEN next_churn_rate<churn_rate THEN 'decrease' ELSE 'increase' END AS flag
FROM c

--Find all number pairs whose first number is smaller than the second one and the product of two numbers is larger than 11
--Output both numbers in the combination.
SELECT a.number, b.number 
FROM transportation_numbers a
JOIN transportation_numbers b
ON a.number<b.number AND a.number*b.number>11

--Lyft Driver Salary And Service Tenure
--Find the correlation between the annual salary and the length of the service period of a Lyft driver.
WITH a AS (SELECT yearly_salary AS X, datediff(day,start_date,COALESCE(end_date,CONVERT(DATE,GETDATE()))) AS Y
FROM lyft_drivers)
SELECT  (COUNT(*) * SUM(X * Y) - SUM(X) * SUM(Y)) / (SQRT(COUNT(*) * SUM(X * X) - SUM(X) * SUM(x)) * SQRT(COUNT(*) * SUM(Y* Y) - SUM(Y) * SUM(Y)))
FROM a

--Find the percentage of rides for each weather and the hour
--Find the percentage of rides each weather-hour combination constitutes among all weather-hour combinations.
--Output the weather, hour along with the corresponding percentage.
SELECT weather, hour, SUM(travel_distance)/(SELECT SUM(travel_distance)*100 FROM lyft_rides)*100 AS percentage
FROM lyft_rides
GROUP BY weather, hour
ORDER BY 3 DESC

--Find The Combinations
--Find all combinations of 3 numbers that sum up to 8. Output 3 numbers in the combination but avoid summing up a number with itself.
SELECT a.number, b.number, c.number 
FROM transportation_numbers a
JOIN transportation_numbers b
ON a.number!=b.number AND a.number+b.number<=8
JOIN transportation_numbers c
ON a.number+b.number+c.number=8 AND b.number!=c.number AND c.number!=a.number

--Sum Of Numbers
--Find the sum of numbers whose index is less than 5 and the sum of numbers whose index is greater than 5. Output each result on a separate row.
SELECT a.number, b.number 
FROM transportation_numbers a
JOIN transportation_numbers b
ON a.number+b.number>5
WHERE a.index<5 AND b.index<5

--Advertising Channel Effectiveness
--Find the total effectiveness of each advertising channel in the period from 2017 to 2018 (both included). The effectiveness is calculated as the ratio of 
--total money spent to total customers aquired.
--Output the advertising channel along with corresponding total effectiveness. Sort records by the total effectiveness in descending order.
WITH a AS (SELECT advertising_channel, SUM(money_spent) AS total_money, SUM(customers_acquired) AS total_customer
		FROM uber_advertising
		WHERE year=2017 OR year=2018
		GROUP BY advertising_channel)
SELECT advertising_channel, total_money/total_customer AS effectiveness
FROM a
ORDER BY 2

--Positive Ad Channels
--Find the advertising channel with the smallest maximum yearly spending that still brings in less than 1500 customers each year.
SELECT * FROM uber_advertising
WHERE money_spent= (
SELECT MIN(money_spent) FROM uber_advertising
WHERE customers_acquired>=1500)

--Find artists with the highest number of top 10 ranked songs over the years
--Output the artist along with the corresponding number of top 10 rankings.
SELECT artist, COUNT(1) AS number_top_10
FROM spotify_worldwide_daily_song_ranking
WHERE position <10
GROUP BY artist

--Find artists with the highest number of top 10 ranked songs over the years
--Output the artist along with the corresponding number of top 10 rankings.
SELECT artist, COUNT(1) as top_10_count 
FROM spotify_worldwide_daily_song_ranking
WHERE position <=10
GROUP BY artist
ORDER BY 2 DESC

--Top Ranked Songs
--Find songs that have ranked in the top position. Output the track name and the number of times it ranked at the top. Sort your records by the number of 
--times the song was in the top position in descending order.
SELECT trackname, COUNT(1) AS top_1_count
FROM spotify_worldwide_daily_song_ranking
WHERE position = 1
GROUP BY trackname
ORDER BY 2 DESC

--Highest Paid City Employees
--Find the top 2 highest paid City employees for each job title. Output the job title along with the corresponding highest and second-highest paid employees.
WITH a AS (SELECT *, RANK() OVER(PARTITION BY jobtitle ORDER BY totalpaybenefits DESC) AS rank_totalpay
		FROM sf_public_salaries)
SELECT jobtitle, totalpaybenefits
FROM a
WHERE rank_totalpay<=2

--Overtime Pay
--Find the employee who earned most from working overtime. Output the employee name.
SELECT * FROM sf_public_salaries
WHERE overtimepay = (SELECT MAX(overtimepay) FROM sf_public_salaries)

--Find the top 5 least paid employees for each job title
--Output the employee name, job title and total pay with benefits for the first 5 least paid employees. Avoid gaps in ranking.
WITH a AS (SELECT *, DENSE_RANK() OVER(PARTITION BY jobtitle ORDER BY totalpaybenefits) AS rank_totalpay 
		FROM sf_public_salaries)
SELECT employeename, jobtitle, totalpaybenefits
FROM a
WHERE rank_totalpay <= 5

--Above Average But Not At The Top
--Find all people who earned more than the average in 2013 for their designation but were not amongst the top 5 earners for their job title. 
--Use the totalpay column to calculate total earned and output the employee name(s) as the result.
WITH a AS (SELECT *, DENSE_RANK() OVER(PARTITION BY jobtitle ORDER BY totalpaybenefits DESC) AS rank_totalpay 
		FROM sf_public_salaries)
SELECT employeename, jobtitle, totalpaybenefits
FROM a
WHERE rank_totalpay >= 5 AND totalpay>(SELECT AVG(totalpay) AS avg_total_pay FROM sf_public_salaries
WHERE year = 2013)

--Highest And Lowest Paying Jobs
--Find the ratio and the difference between the highest and lowest total pay for each job title. 
--Output the job title along with the corresponding difference, ratio, highest total pay, and the lowest total pay. Sort records based on the ratio in 
--descending order.
WITH a AS (SELECT *, DENSE_RANK() OVER(PARTITION BY jobtitle ORDER BY totalpaybenefits DESC) AS rank_totalpay FROM sf_public_salaries),
 b AS (SELECT * FROM a WHERE rank_totalpay=1),
 c AS (SELECT *,DENSE_RANK() OVER(PARTITION BY jobtitle ORDER BY totalpaybenefits) AS rank_totalpay FROM sf_public_salaries),
 d AS (SELECT * FROM c WHERE rank_totalpay=1)
SELECT b.jobtitle, b.totalpaybenefits-d.totalpaybenefits AS total_pay_diff, b.totalpaybenefits/d.totalpaybenefits AS ratio, b.totalpaybenefits, d.totalpaybenefits
FROM b
JOIN d
ON b.jobtitle=d.jobtitle
ORDER BY 3 DESC

--Median Job Salaries
--Find the median total pay for each job. Output the job title and the corresponding total pay, and sort the results from highest total pay to lowest.
WITH a AS (SELECT *, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY totalpaybenefits) OVER (PARTITION BY jobtitle) AS median_job_salary
		FROM sf_public_salaries)
SELECT jobtitle, median_job_salary
FROM a
GROUP BY jobtitle, median_job_salary

--Employees Without Benefits
--Find the ratio between the number of employees without benefits to total employees. 
--Output the job title, number of employees without benefits, total employees relevant to that job title, and the corresponding ratio. 
--Order records based on the ratio in ascending order.
WITH a AS (SELECT jobtitle, COUNT(1) AS total_emps_without_benefit
		FROM sf_public_salaries
		WHERE benefits IS NULL OR benefits = 0
		GROUP BY jobtitle),
b AS (SELECT jobtitle, COUNT(1) AS total_emps
		FROM sf_public_salaries
		GROUP BY jobtitle)
SELECT b.jobtitle, COALESCE(total_emps_without_benefit,0) AS without_benefit_emps, total_emps, CONVERT(DECIMAL(5,2),CAST(COALESCE(total_emps_without_benefit,0) AS decimal(4,2))/total_emps*100) AS ratio
FROM b
FULL JOIN a
ON a.jobtitle=b.jobtitle
ORDER BY ratio

--Employee With Lowest Pay
--Find the employee who earned the lowest total payment with benefits from a list of employees who earned more from other payments compared to their base pay. 
--Output the first name of the employee along with the corresponding total payment with benefits.
SELECT * FROM sf_public_salaries
WHERE otherpay>basepay
ORDER BY 9

--Find the top 5 highest paid and top 5 least paid employees in 2012
--Output the employee name along with the corresponding total pay with benefits.
--Sort records based on the total payment with benefits in ascending order.
WITH a AS (SELECT *, RANK() OVER(ORDER BY totalpaybenefits) AS ranking
		FROM sf_public_salaries
		WHERE year=2012),
b AS (SELECT *, RANK() OVER(ORDER BY totalpaybenefits DESC) AS ranking
		FROM sf_public_salaries
		WHERE year=2012)
SELECT id, employeename, jobtitle,totalpaybenefits, year
FROM a
WHERE a.ranking<=5
UNION
SELECT id, employeename, jobtitle,totalpaybenefits, year
FROM b
WHERE b.ranking<=5

--Find employees who earned the highest and the lowest total pay without any benefits
--Output the employee name along with the total pay.
--Order records based on the total pay in descending order.
WITH a AS (SELECT *, RANK() OVER(ORDER BY totalpaybenefits) AS rank_in_asc, RANK() OVER(ORDER BY totalpaybenefits DESC) AS rank_in_desc
		FROM sf_public_salaries
		WHERE benefits IS NULL OR benefits=0)
SELECT id, employeename,jobtitle,basepay,overtimepay,otherpay,benefits,totalpay,totalpaybenefits,year,notes,agency,status 
FROM a
WHERE rank_in_asc=1 OR rank_in_desc=1

--Find the number of police officers, firefighters, and medical staff employees
--Find the number of police officers (job title contains substring police), firefighters (job title contains substring fire), and 
--medical staff employees (job title contains substring medical) based on the employee name.
--Output each job title along with the corresponding number of employees.
SELECT SUM(CASE WHEN jobtitle LIKE '%police%' THEN 1 ELSE 0 END) AS police,
SUM(CASE WHEN jobtitle LIKE '%fire%' THEN 1 ELSE 0 END) AS firefighter,
SUM(CASE WHEN jobtitle LIKE '%nurse%' THEN 1 ELSE 0 END) AS medical_staff
FROM sf_public_salaries

--QBs With Most Attempts
--Find quarterbacks that made most attempts to throw the ball in 2016.
--Output the quarterback along with the corresponding number of attempts.
--Sort records by the number of attempts in descending order.
SELECT qb, SUM(att) AS total_att
FROM qbstats_2015_2016
GROUP BY qb
ORDER BY 2 DESC

--Find quarterbacks that played the most games in 2016
--Output all the quarterbacks along with the corresponding number of appearances.
--But sort the records by the number of appearances in descending order.
SELECT qb, COUNT(*) AS total_games
FROM qbstats_2015_2016
GROUP BY qb

--QB With Highest TDs
--Find the quarterback who had the highest number of touchdowns (column 'td') in 2016. 
--Output all the quarterbacks along with the corresponding number of TDs. But sort the records based on the number of TDs in descending order.
SELECT qb, SUM(td) AS total_td
FROM qbstats_2015_2016
GROUP BY qb

--Quarterback With The Longest Throw
--Find the quarterback who threw the longest throw in 2016. Output the quarterback name along with their corresponding longest throw.
--The 'lg' column contains the longest completion by the quarterback.
SELECT qb, MAX(LEFT(lg,2)) AS longest
FROM qbstats_2015_2016
WHERE year=2016
GROUP BY qb
ORDER BY 2 DESC

--Average Number Of Points
--Find the average number of points earned per quarterback appearance in each year. Each row represents one appearance of one quarterback in one game. 
--Output the year and quarterback name along with the corresponding average points.
--Sort records by the year in descending order.
SELECT year, qb, AVG(game_points) AS avg_points 
FROM qbstats_2015_2016
GROUP BY year, qb

--Find whether quarterbacks performed better at home or away in 2016
--Output the quarterback along with the corresponding maximum home and away points.
WITH a AS (SELECT qb, home_away, MAX(game_points) AS max_points
		FROM qbstats_2015_2016
		WHERE year=2016 AND home_away='away'
		GROUP BY qb, home_away),
b AS (SELECT qb, home_away, MAX(game_points) AS max_points
		FROM qbstats_2015_2016
		WHERE year=2016 AND home_away='home'
		GROUP BY qb, home_away)
SELECT a.qb, a.max_points AS away_max_points, b.max_points AS home_max_points, 
	CASE WHEN a.max_points<b.max_points THEN 'Away' WHEN a.max_points>b.max_points THEN 'Home' ELSE 'Equal' END AS note
FROM a
JOIN b
ON a.qb=b.qb

--Find quarterbacks who have achieved high average game points during their careers
--Output the quarterback along with the corresponding average points.
--Order records by average points in descending order.
SELECT qb, AVG(game_points) AS avg_game_points
FROM qbstats_2015_2016
GROUP BY qb
ORDER BY 2 DESC

----Top Teams In The Rio De Janeiro 2016 Olympics
--Find the top 3 medal-winning teams by counting the total number of medals for each event in the Rio De Janeiro 2016 olympics. 
--In case there is a tie, order the countries by name in ascending order. 
--Output the event name along with the top 3 teams as the 'gold team', 'silver team', and 'bronze team', 
--with the team name and the total medals under each column in format "{team} with {number of medals} medals". 
--Replace NULLs with "No Team" string.
SELECT team,
COUNT(1) AS total_medal, 
SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS gold,
SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver,
SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS bronze
FROM olympic.dbo.athlete_events
WHERE year=2016 AND medal IS NOT NULL
GROUP BY team

--Olympic Medals By Chinese Athletes
--Find the number of medals earned in each category by Chinese athletes from the 2000 to 2016 summer Olympics. 
--For each medal category, calculate the number of medals for each olympic games along with the total number of medals across all years. 
--Sort records by total medals in descending order.
SELECT sport, year, COUNT(1) AS medal_count
FROM olympic.dbo.athlete_events
WHERE team='China' AND Medal!='NA'
AND year>=2000 AND year<=2016
GROUP BY sport, Year
ORDER BY 2, 3 DESC

--Median Age Of Gold Medal Winners
--Find the median age of gold medal winners across all Olympics.
SELECT *, PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY age) 
        OVER (PARTITION BY Games)
        AS median_age_of_gold_medal_winner
FROM olympic.dbo.athlete_events
WHERE Medal='Gold'

--Find how the average male height changed between each Olympics from 1896 to 2016
--Output the Olympics year, average height, previous average height, and the corresponding average height difference.
--Order records by the year in ascending order.
--If avg height is not found, assume that the average height of an athlete is 172.73.
WITH a AS (SELECT 172.73 AS Height, Year FROM olympic.dbo.athlete_events
	WHERE Height='NA'
	UNION
	SELECT Height, Year FROM olympic.dbo.athlete_events
	WHERE Height!='NA')
SELECT year, AVG(Height) AS avg_height,LAG(AVG(Height),1) OVER(ORDER BY year) AS previous_avg_height,
AVG(Height)-LAG(AVG(Height),1) OVER(ORDER BY year) AS height_diff
FROM a
GROUP BY Year

--Norwegian Alpine Skiers
--Find all Norwegian alpine skiers who participated in 1992 but didn't participate in 1994. Output unique athlete names.
SELECT DISTINCT(name) FROM olympic.dbo.athlete_events
WHERE Team='Norway' AND year=1992 AND Sport='Alpine Skiing' AND name not in (SELECT DISTINCT(name) FROM olympic.dbo.athlete_events
WHERE Team='Norway' AND year=1994 AND Sport='Alpine Skiing')

--Olympics Gender Ratio
--Find the gender ratio between the number of men and women who participated in each Olympics.
--Output the Olympics name along with the corresponding number of men, women, and the gender ratio. If there are Olympics with no women, 
--output a NULL instead of a ratio.
SELECT Games, 
	SUM(CASE WHEN Sex='M' THEN 1 ELSE 0 END) AS men,
	SUM(CASE WHEN Sex='F' THEN 1 ELSE 0 END) AS women , 
	100*(CAST(SUM(CASE WHEN Sex='M' THEN 1 ELSE 0 END)AS decimal(10,2))/NULLIF(SUM(CASE WHEN Sex='F' THEN 1 ELSE 0 END),0)) AS ratio
FROM olympic.dbo.athlete_events
GROUP BY Games

--- Name to Medal Connection
--Find the connection between the number of letters in the athlete's first name and the number of medals won for each type for medal, including no medals. 
--Output the length of the name along with the corresponding number of no medals, bronze medals, silver medals, and gold medals.
SELECT len(replace(name,' ','')) AS no_letter_of_name, COUNT(1) AS Medal,
	SUM(CASE WHEN Medal='Gold' THEN 1 ELSE 0 END) AS Gold,
	SUM(CASE WHEN Medal='Silver' THEN 1 ELSE 0 END) AS Silver,
	SUM(CASE WHEN Medal='Bronze' THEN 1 ELSE 0 END) AS Bronze
FROM olympic.dbo.athlete_events
WHERE Medal!='NA'
GROUP BY len(replace(name,' ',''))
ORDER BY 3 DESC

--European Olympics
--Find the number of athletes who participated in the Olympics that hosted in European cities.
--European cities: Berlin, Athina, Lillehammer, London, Albertville and Paris.
SELECT COUNT(DISTINCT(Name)) AS total_athletes
FROM olympic.dbo.athlete_events
WHERE City in ('Berlin','Athina','Lillehammer','Albertville','Paris')

--Athletes On Single Or Multiple Teams
--Classify each athlete as either on one team or on multiple teams based on the number of team names in the 'team' column. If an athlete is only on one team, 
--classify them as 'One Team', otherwise classify the athlete as 'Multiple Teams'.
--Athletes on multiple teams will have two teams listed and separated by a / (e.g., Denmark/Sweden). Output unique player names along with the classification.
SELECT name, CASE WHEN COUNT(DISTINCT(Team))=1 THEN 'one' ELSE 'multiple' END AS team_classification
FROM olympic.dbo.athlete_events
GROUP BY name

--Find how many athletes competing in Football won Gold medals by their NOC and gender
--Output the NOC, sex, and the corresponding number of athletes.
--Sort records by the NOC, sex, and the number of athletes in ascending order.
SELECT NOC, SEX, COUNT(DISTINCT(name)) AS total_athletes
FROM olympic.dbo.athlete_events
WHERE Medal='Gold' AND Sport='Football'
GROUP BY NOC, SEX

--Find the year in which the shortest athlete participated
--Output the year and the corresponding height.
SELECT DISTINCT(YEAR) FROM olympic.dbo.athlete_events
WHERE Height = (SELECT MIN(Height) FROM olympic.dbo.athlete_events)

--Find all distinct sports that obese people participated in
--A person is considered as obese if his or her body mass index exceeds 30.
--The body mass index is calculated as weight / (height * height). Use meters for height and kilograms for weight.
SELECT DISTINCT(Sport)
FROM olympic.dbo.athlete_events
WHERE Weight !='NA' AND Height!='NA' AND convert(float,Weight)/(convert(float,Height)*convert(float,Height)*0.0001)>30

--Largest Olympics
--Find the Olympics with the highest number of athletes. The Olympics game is a combination of the year and the season, and is found in the 'games' column. 
--Output the Olympics along with the corresponding number of athletes.
SELECT games, COUNT(DISTINCT(name)) AS total_athletes
FROM olympic.dbo.athlete_events
GROUP BY Games
ORDER BY 2 DESC

--Find the number of athletes that participated in each Olympics season
--Output the season with the corresponding number of athletes.
SELECT season, COUNT(DISTINCT(name)) AS total_athletes
FROM olympic.dbo.athlete_events
GROUP BY season
ORDER BY 2 DESC

--Unique Highest Salary
SELECT MAX(DISTINCT(salary)) AS max_unique_salary
FROM employee

--Highest Cost Orders
--Find the customer with the highest daily total order cost between 2019-02-01 to 2019-05-01. 
--If customer had more than one order on a certain day, sum the order costs on daily basis.
--Output customer's first name, total cost of their items, and the date.
--For simplicity, you can assume that every first name in the dataset is unique.
SELECT first_name, order_date, SUM(total_order_cost) AS total_cost 
FROM orders a
JOIN customers b
ON a.cust_id=b.id
WHERE order_date BETWEEN '2019-02-01' AND '2019-05-01'
GROUP BY first_name, order_date

--Lowest Priced Orders
--Output the customer id along with the first name and the lowest order price.
SELECT cust_id, first_name, total_order_cost FROM orders a
JOIN customers b
ON a.cust_id=b.id
WHERE total_order_cost = (SELECT MIN(total_order_cost) FROM orders)

--Favorite Customer
--Find "favorite" customers based on the order count and the total cost of orders.
--A customer is considered as a favorite if he or she has placed more than 3 orders and with the total cost of orders more than $100.
--Output the customer's first name, city, number of orders, and total cost of orders.
WITH a AS (SELECT cust_id, COUNT(total_order_cost) AS total_order, SUM(total_order_cost) AS total_cost
	FROM orders
	GROUP BY cust_id)
SELECT cust_id,first_name,total_order, total_cost
FROM a
JOIN customers b
ON a.cust_id=b.id
WHERE total_order>3 AND total_cost>100

--Customer Orders and Details
--Find the number of orders, the number of customers, and the total cost of orders for each city. 
--Only include cities that have made at least 5 orders and count all customers in each city even if they did not place an order.
--Output each calculation along with the corresponding city name.
SELECT city, COUNT(1) AS total_orders, SUM(total_order_cost) AS total_cost
FROM orders a
JOIN customers b
ON b.id=a.cust_id
GROUP BY city

--Highest Target Under Manager
--Find the highest target achieved by the employee or employees who works under the manager id 13. 
--Output the first name of the employee and target achieved. 
--The solution should show the highest target achieved under manager_id=13 and which employee(s) achieved it.
SELECT * FROM salesforce_employees
WHERE target = (SELECT MAX(target) 
			FROM salesforce_employees
			WHERE manager_id = 13)
AND manager_id = 13

--Highest Target
--Find the employee who has achieved the highest target.
--Output the employee's first name along with the achieved target and the bonus.
SELECT * FROM employee
WHERE target =(SELECT MAX(target) FROM employee)

--Super Managers
--Find managers with at least 7 direct reporting employees. In situations where user is reporting to himself/herself, count that also.
--Output first names of managers.
SELECT b.first_name ,a.manager_id, COUNT(1) AS total_emps
FROM employee a
JOIN employee b
ON a.manager_id=b.id
GROUP BY a.manager_id, b.first_name
HAVING COUNT(1) >=7

--Median Salary
--Find the median employee salary of each department.
--Output the department name along with the corresponding salary rounded to the nearest whole dollar.
WITH a AS (SELECT department, PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY salary) 
        OVER (PARTITION BY department)
        AS median_salary_per_dept
FROM employee)
SELECT * FROM a
GROUP BY department,median_salary_per_dept
      
--Find the average total checkouts from Chinatown libraries in 2016
SELECT AVG(total_checkouts) AS avg_checkouts
FROM library_usage
WHERE home_library_definition ='Chinatown' AND circulation_active_year=2016

--Find months with the highest number of checkouts for main libraries in 2013
--Output the circulation active month along with the corresponding total monthly checkouts.
--Order results based on total monthly checkouts in descending order.
SELECT circulation_active_month, SUM(total_checkouts) AS total_checkouts
FROM library_usage
WHERE circulation_active_year=2013
GROUP BY circulation_active_month

--Libraries With Highest Checkouts
--Find library types with the highest total checkouts in April made by patrons who had registered in 2015 and whose age was between 65 and 74 years.
--Output the year patron registered and the home library definition along with the corresponding highest total checkouts. 
--Sort records based on the highest total checkouts in descending order.
SELECT TOP 1 home_library_definition, SUM(total_checkouts) AS total_checkouts
FROM library_usage
WHERE year_patron_registered=2015 AND circulation_active_month='April' AND age_range='65 to 74 years'
GROUP BY home_library_definition
ORDER BY 2 DESC

--Find library types with the highest total checkouts made by adults registered in 2010
--Output the year patron registered, home library definition along with the corresponding highest total checkouts.
SELECT year_patron_registered, home_library_definition, total_checkouts FROM library_usage
WHERE patron_type_definition ='ADULT' AND year_patron_registered=2010

--Highest Checkouts
--Find the number of patrons that have made the highest checkouts up to 10 (excluding 10).
--Output the number of patrons along with the corresponding total checkouts. Sort records based on the total checkouts in descending order.
SELECT COUNT(1) AS number_of_patron, SUM(total_checkouts) AS total_checkouts
FROM library_usage
WHERE total_checkouts<10

--Department Salaries
--Find the number of male and female employees per department and also their corresponding total salaries.
--Output department names along with the corresponding number of female employees, the total salary of female employees, the number of male employees, and 
--the total salary of male employees.
SELECT department,
	SUM(CASE WHEN sex='F' THEN 1 ELSE 0 END) AS female_emp,
	SUM(CASE WHEN sex='F' THEN salary ELSE 0 END) AS femal_salary,
	SUM(CASE WHEN sex='M' THEN 1 ELSE 0 END) AS male_emp,
	SUM(CASE WHEN sex='M' THEN salary ELSE 0 END) AS male_salary
FROM employee
GROUP BY department

--Percentage Of Total Spend
--Calculate the percentage of the total spend a customer spent on each order. 
--Output the customer’s first name, order details, and percentage of the order cost to their total spend across all orders.
--Assume each customer has a unique first name (i.e., there is only 1 customer named Karen in the dataset) and that customers place at most only 1 order a day.
--Percentages should be represented as decimals
SELECT first_name, total_order_cost AS total_each_order, SUM(total_order_cost) OVER(PARTITION BY cust_id) AS total_orders_cost, 
	CONVERT(DECIMAL(3,0),CAST(total_order_cost AS decimal(6,2))/ SUM(total_order_cost) OVER(PARTITION BY cust_id)*100) AS cost_pct
FROM orders a
JOIN customers b
ON a.cust_id=b.id

--Distinct Salaries
--Find the top three distinct salaries for each department. Output the department name and the top 3 distinct salaries by each department. 
--Order your results alphabetically by department and then by highest salary to lowest.
WITH a AS(SELECT department, salary, RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS ranking
		FROM twitter_employee
		GROUP BY department, salary)
SELECT department, salary
FROM a
WHERE ranking<=3

--Highest Salary In Department
--Find the employee with the highest salary per department.
--Output the department name, employee's first name along with the corresponding salary.
SELECT a.department, a.first_name, a.salary FROM employee a
JOIN (SELECT department, MAX(salary) AS salary
	FROM employee
	GROUP BY department) b
ON a.department=b.department AND a.salary=b.salary

--Customers Without Orders
--Find customers who have never made an order.
--Output the first name of the customer.
SELECT * FROM customers
WHERE id NOT IN (SELECT cust_id FROM orders
GROUP BY cust_id)

--Duplicate Emails
--Find all emails with duplicates.
SELECT email FROM employee
GROUP BY email
HAVING count(1)>2

--Employee and Manager Salaries
--Find employees who are earning more than their managers. Output the employee's first name along with the corresponding salary.
SELECT a.id, first_name, a.salary, b.salary AS manager_salary
FROM employee a
JOIN (SELECT id, salary 
	FROM employee
	WHERE id IN (SELECT manager_id FROM employee
		GROUP BY manager_id)) b
ON a.manager_id = b.id
WHERE a.salary>b.salary

--Frequent Customers
--Find customers who appear in the orders table more than three times.
SELECT cust_id, COUNT(1) AS total_orders
FROM orders
GROUP BY cust_id
HAVING COUNT(1)>3

--Second Highest Salary
--Find the second highest salary of employees.
WITH a AS (SELECT *, RANK() OVER(ORDER BY salary DESC) AS ranking_salary FROM employee)
SELECT *
FROM a
WHERE ranking_salary=2

--Number Of User's Events
--Find the total number of events a user has triggered and the average number of days between the event date and date of when the user activated.
--Your output should include the user_id, event name, the number of events , and the average date between the event dates and the user's activated date.
SELECT a.user_id, event_name, count(1) AS number_of_events, AVG(DATEDIFF(DAY,activated_at,occurred_at)) AS average_days
FROM playbook_events a
JOIN playbook_users b
ON a.user_id=b.user_id
GROUP BY a.user_id, event_name

--Find how many logins Spanish speakers made by country
--Output the country along with the corresponding number of logins.
--Order records by the number of logins in descending order.
SELECT location, COUNT(1) as total_logins
FROM playbook_events a
JOIN playbook_users b
ON a.user_id=b.user_id
WHERE language='spanish' AND event_name='login'
GROUP BY location

--Find how the survivors are distributed by the gender and passenger classes
--Classes are categorized based on the pclass value as:
--pclass = 1: first_class
--pclass = 2: second_classs
--pclass = 3: third_class
--Output the sex along with the corresponding number of survivors for each class.
SELECT sex, pclass, 
SUM(CASE WHEN survived=1 THEN 1 ELSE 0 END) AS survived,
SUM(CASE WHEN survived=0 THEN 1 ELSE 0 END) AS non_survived
FROM titanic
GROUP BY sex, pclass

--Find the oldest survivor per passenger class
--Find the oldest survivor of each passenger class.
--Output the name and the age of the survivor along with the corresponding passenger class.
--Order records by passenger class in ascending order.
SELECT a.name, a.age, a.pclass
FROM titanic a
JOIN (SELECT pclass, MAX(age) AS oldest_passenger
	FROM titanic
	WHERE survived=1
	GROUP BY pclass) b
ON a.age=b.oldest_passenger AND a.pclass=b.pclass

--Make a report showing the number of survivors and non-survivors by passenger class
--Classes are categorized based on the pclass value as:
--pclass = 1: first_class
--pclass = 2: second_classs
--pclass = 3: third_class
--Output the number of survivors and non-survivors by each class.
SELECT pclass, 
SUM(CASE WHEN survived=1 THEN 1 ELSE 0 END) AS survived,
SUM(CASE WHEN survived=0 THEN 1 ELSE 0 END) AS non_survived
FROM titanic
GROUP BY pclass

--Find the top five hotels with the highest total reviews given by a particular reviewer
--For each hotel find the number of reviews from the most active reviewer. The most active is the one with highest number of total reviews.
--Output the hotel name along with the highest total reviews of that reviewer. Output only top 5 hotels with highest total reviews.
--Order records based on the highest total reviews in descending order.
SELECT TOP 5 hotel_name, total_number_of_reviews, total_number_of_reviews_reviewer_has_given
FROM hotel_reviews
ORDER BY 3 DESC

--Find the countries with the most positive reviews
--Find the countries whose reviewers give most positive reviews. Positive reviews are all reviews where review text is different than "No Positive"
--Output all countries along with the number of positive reviews but sort records based on the number of positive reviews in descending order.
SELECT reviewer_nationality, COUNT(1) AS total_positive_reviews
FROM hotel_reviews
WHERE review_total_positive_word_counts!=0
GROUP BY reviewer_nationality
ORDER BY 2 DESC

--Countries With Most Negative Reviews
--Find the countries with the most negative reviews. 
--Output the country along with the number of negative reviews and sort records based on the number of negative reviews in descending order. 
--Review is not negative if value negative value column equals to "No Negative". You can ignore countries with no negative reviews.
SELECT reviewer_nationality, COUNT(1) AS total_negative_reviews
FROM hotel_reviews
WHERE review_total_negative_word_counts!=0
GROUP BY reviewer_nationality
ORDER BY 2 DESC

--Find the top two hotels with the most negative reviews
--Output the hotel name along with the corresponding number of negative reviews.
--Sort records based on the number of negative reviews in descending order.
WITH a AS (SELECT hotel_name, COUNT(1) AS total_negative_reviews, DENSE_RANK() OVER(ORDER BY COUNT(1) DESC) AS rank_negative_reviews
		FROM hotel_reviews
		WHERE review_total_negative_word_counts!=0
		GROUP BY hotel_name)
SELECT hotel_name, total_negative_reviews FROM a
WHERE rank_negative_reviews<=2

--Find the 10 lowest rated hotels.
--Output the hotel name along with the corresponding average score.
SELECT TOP 10 hotel_name, AVG(average_score) AS avg_score
FROM hotel_reviews
GROUP BY hotel_name
ORDER BY 2

--Find the top ten hotels with the highest ratings
--Output the hotel name along with the corresponding average score.
--Sort records based on the average score in descending order.
SELECT TOP 10 hotel_name, AVG(average_score) AS avg_score
FROM hotel_reviews
GROUP BY hotel_name
ORDER BY 2 DESC

--Find the total salary of each department
--Output the salary along with the corresponding department.
SELECT department, SUM(salary) AS total_salary
FROM worker
GROUP BY department

--Highest Salaried Employees
--Find the employee with the highest salary in each department.
--Output the department name, employee's first name, and the salary.
SELECT a.department, first_name, a.salary
FROM worker a
JOIN (SELECT department, MAX(salary) AS highest_salary FROM worker GROUP BY department) b
ON a.department=b.department AND a.salary=b.highest_salary

--Find departments with less than 5 employees
--Output the department along with the corresponding number of workers.
SELECT department, COUNT(1) AS total_emps 
FROM worker 
GROUP BY department
HAVING COUNT(1) <5

--Find the first 50% records of the dataset
WITH a AS (SELECT *,PERCENT_RANK() OVER(ORDER BY worker_id) AS pct_rank FROM worker)
SELECT worker_id, first_name, last_name, salary, joining_date, department
FROM a
WHERE pct_rank<=0.5

--Find employees in the HR department and output the result with one duplicate
--Output the first name and the department of employees.
SELECT * FROM worker
WHERE department='HR'

--Find the second highest salary without using ORDER BY
SELECT * FROM worker
WHERE salary = (SELECT MAX(salary) FROM worker
				WHERE salary != (SELECT MAX(salary) FROM worker))

--Find employees with the same salary
--Output the worker id along with the first name and the salary.
SELECT * FROM worker
WHERE salary = (SELECT salary FROM worker
			GROUP BY salary
			HAVING COUNT(*) !=1)

--Find the 5th highest salary without using TOP or LIMIT
WITH a AS (SELECT *, DENSE_RANK() OVER(ORDER BY salary DESC) AS rank_salary FROM worker)
SELECT worker_id, first_name, last_name, salary, joining_date, department
FROM a
WHERE rank_salary=5

--Find the duplicate records in the dataset
--Output the worker title, affected_from date, and the number of times the records appear in the dataset.
SELECT worker_title, affected_from, COUNT(1) FROM title
GROUP BY worker_title, affected_from

--Find all workers who are also managers
--Output the first name along with the corresponding title.
SELECT a.worker_id,first_name, last_name, worker_title FROM worker a
JOIN title b
ON a.worker_id=b.worker_ref_id
WHERE worker_title='Manager'

--Common Letters
--Find the top 3 most common letters across all the words from both the tables (ignore filename column). 
--Output the letter along with the number of occurrences and order records in descending order based on the number of occurrences.
WITH a AS (SELECT value
		FROM google_word_lists
		CROSS APPLY STRING_SPLIT(words1,',')
		UNION ALL
		SELECT value
		FROM google_word_lists
		CROSS APPLY STRING_SPLIT(words2,',')
		UNION ALL
		SELECT value
		FROM google_file_store
		CROSS APPLY STRING_SPLIT(contents,' '))
SELECT value, COUNT(1) AS total_occurences FROM a
GROUP BY value

-- Find word occurence in content
WITH a AS (SELECT 1 AS id, value
		FROM google_word_lists
		CROSS APPLY STRING_SPLIT(words1,',')
		UNION
		SELECT 1 AS id, value
		FROM google_word_lists
		CROSS APPLY STRING_SPLIT(words2,','))
SELECT a.id, value, contents, CHARINDEX(value,contents) AS occurence
FROM a
JOIN (SELECT 1 AS id, contents FROM google_file_store) B
ON a.id=b.id

--Find the average number of friends a user has
WITH a AS (SELECT user_id, COUNT(1) AS total_friends FROM google_friends_network GROUP BY user_id
		UNION
		SELECT friend_id, COUNT(1) AS total_friends FROM google_friends_network GROUP BY friend_id)
SELECT CONVERT(DECIMAL(4,2),CAST(SUM(total_friends) AS DECIMAL(4,2))/COUNT(total_friends)) AS avg_friend FROM a

--Common Friends Friend
--Find the number of a user's friends' friend who are also the user's friend. Output the user id along with the count.
SELECT a.user_id AS user_id, a.friend_id AS user_friend_id, b.friend_id AS user_friend_friend_id
FROM google_friends_network a
JOIN google_friends_network b
ON a.friend_id=b.user_id

--Sum Of Transportation Numbers
--Find the sum of all values between the lowest and highest transportation numbers (i.e., exclude the lowest and highest numbers in your sum).
--Your output should have 3 columns: the minimum number, maximum number, and summation.
WITH a AS (SELECT *, dense_rank() OVER(ORDER BY number) AS rank
		FROM transportation_numbers),
b AS (SELECT *, dense_rank() OVER(ORDER BY number DESC) AS rank
		FROM transportation_numbers)
SELECT a.number AS first_num, b.number AS second_num, a.number+b.number AS summation
FROM a
JOIN b
ON a.rank = b.rank
GROUP BY a.number, b.number, a.number+b.number

--File Contents Shuffle
--Sort the words alphabetically in 'final.txt' and make a new file named 'wacky.txt'. 
--Output the file contents in one column and the filename 'wacky.txt' in another column. 
--Lowercase all the words. To simplify the question, there is no need to remove the punctuation marks.
WITH a AS (SELECT lower(replace(contents,'.','')) AS contents FROM google_file_store WHERE filename='final.txt')
SELECT value FROM a CROSS APPLY string_split(contents,' ') ORDER BY 1

--Find the number of times each word appears in drafts
--Output the word along with the corresponding number of occurrences.
WITH a AS (SELECT lower(replace(contents,'.','')) AS contents FROM google_file_store)
SELECT value, COUNT(1) AS total_occurences FROM a CROSS APPLY string_split(contents,' ') GROUP BY value ORDER BY 2 DESC

--Price Of A Handyman
--Find the price that a small handyman business is willing to pay per employee. Get the result based on the mode of the adword earnings per employee distribution. 
--Small businesses are considered to have not more than ten employees.
SELECT SUM(adwords_earnings)/SUM(n_employees) AS price_per_emp
FROM google_adwords_earnings
WHERE business_type='handyman' AND n_employees<=10

--Make the friends network symmetric
--For example, if 0 and 1 are friends, have the output contain both 0 and 1 under 1 and 0 respectively.
SELECT user_id, friend_id FROM google_friends_network
UNION ALL
SELECT friend_id, user_id FROM google_friends_network

--Find the minimal adwords earnings for each business type
--Output the business type along with the minimal earning.
SELECT business_type, MIN(adwords_earnings) AS minimal_earnings
FROM google_adwords_earnings
GROUP BY business_type

--Find all users that have more than 3 friends
SELECT user_id, COUNT(*) AS total_friends
FROM google_friends_network 
GROUP BY user_id
HAVING COUNT(*)>=3

--Find a content that has the highest number of companies
--Find a continet that has the highest number of companies.
--Output the continent along with the corresponding number of companies.
SELECT TOP 1 continent, COUNT(1) AS total_companies
FROM forbes_global_2010_2014
GROUP BY continent
ORDER BY 2 DESC

--Top 3 US Sectors
--Find the top 3 sectors in the United States with highest average rank. Output the average rank along with the sector name.
SELECT TOP 3 sector, AVG(rank) AS avg_rank
FROM forbes_global_2010_2014
WHERE country='United States'
GROUP BY sector
ORDER BY 2 DESC

--Find industries with the highest market value in Asia
--Output the industry along with the corresponding total market value.
SELECT industry, sum(marketvalue) AS total_market_value
FROM forbes_global_2010_2014
WHERE continent='Asia'
GROUP BY industry
ORDER BY 2 DESC

--Find industries with the highest number of companies
--Output the industry along with the number of companies.
--Sort records based on the number of companies in descending order.
SELECT industry, COUNT(1) AS total_companies
FROM forbes_global_2010_2014
GROUP BY industry
ORDER BY 2 DESC

--Find the most popular sector in the Forbes list
--Find the most popular sector from the Forbes list based on the number of companies in each sector.
--Output the sector along with the number of companies.
SELECT sector, COUNT(1) AS total_companies
FROM forbes_global_2010_2014
GROUP BY sector
ORDER BY 2 DESC

--Find the country that has the most companies listed on Forbes
--Output the country along with the number of companies.
SELECT country, COUNT(1) AS total_companies
FROM forbes_global_2010_2014
GROUP BY country
ORDER BY 2 DESC

--Words With Two Vowels
--Find all words which contain exactly two vowels in any list in the table.
WITH a AS (SELECT value
		FROM google_word_lists
		CROSS APPLY STRING_SPLIT(words1,',')
		UNION
		SELECT value
		FROM google_word_lists
		CROSS APPLY STRING_SPLIT(words2,','))
SELECT value
FROM a
WHERE len(value)- len(replace(replace(replace(replace(replace(value,'u',''),'e',''),'o',''),'a',''),'i',''))=2

--Average Time Between Steps
--Find the average time (in seconds), per product, that needed to progress between steps. 
--You can ignore products that were never used. Output the feature id and the average time.
WITH a AS (SELECT feature_id, user_id, step_reached, 
		DATEDIFF(second,timestamp,LEAD(timestamp,1) OVER(PARTITION BY feature_id, user_id ORDER BY step_reached)) as seconds_diff
		FROM facebook_product_features_realizations)
SELECT feature_id, AVG(seconds_diff) avg_second_per_ FROM a
GROUP BY feature_id

--User Feature Completion
--An app has product features that help guide users through a marketing funnel. 
--Each feature has "steps" (i.e., actions users can take) as a guide to complete the funnel. 
--What is the average percentage of completion for each feature?
SELECT a.feature_id, CONVERT(DECIMAL(5,2),CAST(step_reached AS decimal(5,2))/n_steps*100) AS pct_of_completion
FROM facebook_product_features a
JOIN facebook_product_features_realizations b
ON a.feature_id=b.feature_id

--Views Per Keyword
--Create a report showing how many views each keyword has. Output the keyword and the total views, and order records with highest view count first.
SELECT value AS keyword, SUM(views) AS total_views
		FROM facebook_posts a
		CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(post_keywords,'[',''),']',''),',')
JOIN (SELECT post_id, COUNT(1) AS views
	FROM facebook_post_views
	GROUP BY post_id) b
ON a.post_id=b.post_id
GROUP BY value

--Find the number of processed and not-processed complaints of each type
--Find the number of processed and non-processed complaints of each type.
--Replace NULL values with 0s.
--Output the complaint type along with the number of processed and not-processed complaints.
WITH a AS
(SELECT type, COUNT(1) AS processed_count
FROM facebook_complaints
WHERE processed = 1
GROUP BY type),
b AS
(SELECT type, COUNT(1) AS non_processed_count
FROM facebook_complaints
WHERE processed = 0
GROUP BY type)
SELECT a.type, processed_count, non_processed_count
FROM a
JOIN b
ON a.type=b.type

--Find the total number of approved friendship requests in January and February
--Find the total number of approved friendship requests in January and February.
SELECT COUNT(1) approved_friend_number
FROM facebook_friendship_requests
WHERE MONTH(date_approved) BETWEEN 1 AND 2

--Time Between Two Events
--Meta/Facebook's web logs capture every action from users starting from page loading to page scrolling. 
--Find the user with the least amount of time between a page load and their first scroll down. 
--Your output should include the user id, page load time, first scroll down time, and time between the two events in seconds.
WITH a AS
(SELECT *, FIRST_VALUE(timestamp) OVER(PARTITION BY user_id ORDER BY timestamp) AS first_scroll_down
FROM facebook_web_log
WHERE action='scroll_down'),
b AS
(SELECT *, FIRST_VALUE(timestamp) OVER(PARTITION BY user_id ORDER BY timestamp) AS first_page_load
FROM facebook_web_log
WHERE action='page_load')
SELECT a.user_id, first_scroll_down, first_page_load, DATEDIFF(SECOND,first_page_load,first_scroll_down) time_diff_in_sec
FROM a
JOIN b
ON a.user_id=b.user_id
GROUP BY a.user_id, first_scroll_down, first_page_load

--Customer Revenue In March
--Calculate the total revenue from each customer in March 2019. Include only customers who were active in March 2019.
--Output the revenue along with the customer id and sort the results based on the revenue in descending order.
SELECT cust_id, SUM(total_order_cost) AS total_revenue
FROM orders
WHERE MONTH(order_date)=3
GROUP BY cust_id

--Find the rate of processed tickets for each type
WITH a AS
	(SELECT type, COUNT(1) AS processed
	FROM facebook_complaints
	WHERE processed=1
	GROUP BY type),
b AS
	(SELECT type, COUNT(1) AS total
	FROM facebook_complaints
	GROUP BY type)
SELECT a.type, CONVERT(DECIMAL(5,2),CAST(processed AS DECIMAL(5,2))/total*100) AS process_rate
FROM a
JOIN b
ON a.type=b.type

--Daily Interactions By Users Count
--Find the number of interactions along with the number of people involved with them on a given day. 
--Output the date along with the number of interactions and people. Order results based on the date in ascending order and the number of people in descending order.
WITH a AS
(SELECT day, user1 AS user_involve FROM facebook_user_interactions
UNION
SELECT day, user2 AS user_involve FROM facebook_user_interactions),
b AS
(SELECT day, COUNT(DISTINCT(user_involve)) AS user_involve
FROM a 
GROUP BY day),
c AS
(SELECT day, COUNT(1) AS total_interactions
FROM facebook_user_interactions
GROUP BY day)
SELECT c.day, total_interactions, user_involve
FROM c
JOIN b
ON c.day=b.day

--Successfully Sent Messages
--Find the ratio of successfully received messages to sent messages.
WITH a AS
(SELECT COUNT(*) AS sending_count
FROM facebook_messages_sent),
b AS
(SELECT COUNT(*) AS receiving_count
FROM facebook_messages_sent a
JOIN facebook_messages_received b
ON a.message_id=b.message_id)
SELECT CONVERT(DECIMAL(5,2),CAST(receiving_count AS DECIMAL(5,2))/sending_count*100) AS sent_ratio
FROM a,b

--Common Interests Amongst Users
--Count the subpopulations across datasets. Assume that a subpopulation is a group of users sharing a common interest (ex: Basketball, Food). 
--Output the percentage of overlapping interests for two posters along with those poster's IDs. 
--Calculate the percentage from the number of poster's interests. The poster column in the dataset refers to the user that posted the comment.
SELECT *, LEN(post_keywords)-LEN(REPLACE(post_keywords,',',''))+1 AS number_interests
FROM facebook_posts

--Day 1 Common Reactions
--Find the most common reaction for day 1 by counting the number of occurrences for each reaction. 
--Output the reaction alongside its number of occurrences.
SELECT reaction, COUNT(1) AS number_reaction
FROM facebook_reactions
GROUP BY reaction

--Most Popular Room Types
--Find the room types that are searched by most people. 
--Output the room type alongside the number of searches for it. 
--If the filter for room types has more than one room type, consider each unique room type as a separate row. 
--Sort the result based on the number of searches in descending order.
WITH a AS
(SELECT value AS room_types, n_searches
FROM airbnb_searches
CROSS APPLY string_split(filter_room_types,','))
SELECT room_types, SUM(n_searches) AS total_searches
FROM a
WHERE room_types!=''
GROUP BY room_types

--Find the day of the week that most people check-in
--Find the day of the week that most people want to check-in.
--Output the day of the week alongside the corresponding check-incount.
SELECT DATEPART(WEEKDAY,ds_checkin) AS weekday, COUNT(1) as total_checkin
FROM airbnb_contacts
GROUP BY DATEPART(WEEKDAY,ds_checkin)
ORDER BY 2 DESC

--Find the number of nights that are searching for when trying to book a host
--Find the number of nights that are searched by most people when trying to book a host.
--Output the number of nights alongside the total searches.
--Order records based on the total searches in descending order.
SELECT n_nights, SUM(n_searches) AS total_searches
FROM airbnb_searches
WHERE n_nights IS NOT NULL
GROUP BY n_nights
ORDER BY 2 DESC

--NFL Powerhouse Colleges
--Find colleges that produce the most NFL players.  
--Output the college name and the player count. Order the result based on the player count in descending order. 
--Players that were not drafted into the NFL have 0s as values in the pickround column.
SELECT college, COUNT(1) AS players
FROM nfl_combine
WHERE college IS NOT NULL
GROUP BY college
ORDER BY 2 DESC

--Best Actors/Actresses Of All Time
--Find the best actors/actresses of all time based on the number of Oscar awards. 
--Output nominees alongside their number of Oscars. Order records in descending order based on the number of awards.
SELECT nominee, COUNT(*) oscar_winnings
FROM oscar_nominees
WHERE winner=1
GROUP BY nominee
ORDER BY 2 DESC

--Find movies that had the most nominated actors/actresses
--Find movies that had the most nominated actors/actresses. Be aware of the fact that some movies have the same name. 
--Use the year column to separate count for such movies.
--Output the movie name alongside the number of nominees.
--Order the result in descending order.
SELECT movie, COUNT(1) AS number_nominee
FROM oscar_nominees
GROUP BY movie
ORDER BY 2 DESC

--Win-to-Nomination Ratio
--Calculate the win-to-nomination ratio for each nominee. Output the ratio and the nominee's name. 
--Order the results based on the ratio in descending order to show nominees with the highest ratio on top.
WITH a AS
	(SELECT nominee, COUNT(1) AS total_nominations
	FROM oscar_nominees
	GROUP BY nominee),
b AS
	(SELECT nominee, COUNT(1) AS total_winnings
	FROM oscar_nominees
	WHERE winner=1
	GROUP BY nominee)
SELECT a.nominee, total_winnings, total_nominations, CONVERT(DECIMAL(5,2),CAST(total_winnings AS DECIMAL(5,2))/total_nominations*100) AS wining_ratio
FROM a
JOIN b
ON a.nominee=b.nominee
ORDER BY 4 DESC

--Nominees Without An Oscar
--Find the nominees who have been nominated the most but have never won an Oscar. 
--Output the number of unsuccessful nominations alongside the nominee's name. Order records based on the number of nominations in descending order.
SELECT nominee, COUNT(1) AS total_nominations
FROM oscar_nominees
WHERE nominee NOT IN (SELECT DISTINCT(nominee)
	FROM oscar_nominees
	WHERE winner=1)
GROUP BY nominee
ORDER BY 2 DESC

--Find the nominee who has won the most Oscars
--Find the nominee who has won the most Oscars.
--Output the nominee's name alongside the result.
WITH a AS
	(SELECT nominee, COUNT(1) AS oscars_winnings
	FROM oscar_nominees
	WHERE winner=1
	GROUP BY nominee)
SELECT nominee, oscars_winnings
FROM a
WHERE oscars_winnings=(SELECT MAX(oscars_winnings) FROM a)

--Find districts with the most crime incidents
--Find districts alongside their crime incidents.
--Output the district name alongside the number of crime occurrences.
--Order records based on the number of occurrences in descending order.
SELECT pd_district, COUNT(1) AS number_of_crime 
FROM sf_crime_incidents_2014_01
GROUP BY pd_district

--Find top crime categories in 2014 based on the number of occurrences
--Find top crime categories in 2014 based on the number of occurrences.
--Output the number of crime occurrences alongside the corresponding category name.
--Order records based on the number of occurrences in descending order
SELECT category, COUNT(*) AS number_of_crime
FROM sf_crime_incidents_2014_01
GROUP BY category
ORDER BY 2 DESC

--Find the best artists in the last 20 years
--Find the best artists in the last 20 years.
--Use the metric (100 - avg_yearly_rank) * number_of_years_present to score each artist.
--Output the artist's name and the average yearly rank alongside the score.
--Order records based on the score in descending order.
WITH a AS
(SELECT artist, AVG(year_rank) AS avg_yearly_rank 
FROM billboard_top_100_year_end
GROUP BY artist),
b AS
(SELECT artist, MAX(year) AS number_of_years_present
FROM billboard_top_100_year_end
GROUP BY artist)
SELECT a.artist, (100-avg_yearly_rank)*number_of_years_present AS score
FROM a
JOIN b
ON a.artist=b.artist
ORDER BY 2 DESC

--The Best Artist
--Find the number of times an artist has been on the billboard top 100 in the past 20 years. 
--Output the result alongside the artist's name and order records based on the founded count in descending order.
SELECT artist, COUNT(1) AS counts
FROM billboard_top_100_year_end
GROUP BY artist
ORDER BY 2 DESC

--Top 10 Songs
--Find the number of songs of each artist which were ranked among the top 10 over the years. 
--Order the result based on the number of top 10 ranked songs in descending order.
SELECT artist, COUNT(DISTINCT(song_name)) AS songs
FROM billboard_top_100_year_end
WHERE year_rank<=10
GROUP BY artist
ORDER BY 2 DESC

--Inspection Scores For Businesses
--Find the median inspection score of each business and output the result along with the business name. 
--Order records based on the inspection score in descending order.
--Try to come up with your own precise median calculation. 
--In Postgres there is percentile_disc function available, however it's only approximation.
SELECT business_name, inspection_score,
	PERCENTILE_CONT(0.5) WITHIN GROUP 
	(ORDER BY inspection_score) OVER () AS median_score 
FROM sf_restaurant_health_violations
ORDER BY 2 DESC

--Daily Violation Counts
--Determine the change in the number of daily violations by calculating the difference between the count of current and previous violations by inspection date.
--Output the inspection date and the change in the number of daily violations. Order your results by the earliest inspection date first.
WITH a AS
	(SELECT inspection_date, COUNT(*) AS violation_count
	FROM sf_restaurant_health_violations
	GROUP BY inspection_date)
SELECT inspection_date, 
	violation_count, 
	LAG(violation_count) OVER(ORDER BY inspection_date DESC) AS previous_violations,
	violation_count-LAG(violation_count) OVER(ORDER BY inspection_date DESC) AS violation_diff
FROM a
ORDER BY 1

--Worst Businesses
--For every year, find the worst business in the dataset. The worst business has the most violations during the year. 
--You should output the year, business name, and number of violations.
WITH a AS
	(SELECT YEAR(inspection_date) AS year,business_name, COUNT(1) AS counts
	FROM sf_restaurant_health_violations
	GROUP BY YEAR(inspection_date),business_name),
b AS
(SELECT year, 
	FIRST_VALUE(business_name) OVER(PARTITION BY year ORDER BY counts DESC) AS business_name, 
	FIRST_VALUE(counts) OVER(PARTITION BY year ORDER BY counts DESC) AS violation_counts
FROM a)
SELECT year, business_name, violation_counts
FROM b
GROUP BY year, business_name, violation_counts

--Verify that the first 4 digits are equal to 1415 for all phone numbers
--Verify that the first 4 digits are equal to 1415 for all phone numbers.
SELECT business_id,business_name,business_phone_number,
	CASE WHEN LEFT(business_phone_number,4)=1415 THEN 'Yes' ELSE 'No' END AS flag
FROM sf_restaurant_health_violations

--Rules To Determine Grades
--Find the rules used to determine each grade. 
--Show the rule in a separate column in the format of 'Score > X AND Score <= Y => Grade = A' where X and Y are the lower and upper bounds for a grade. 
--Output the corresponding grade and its highest and lowest scores along with the rule. Order the result based on the grade in ascending order.
SELECT grade, MIN(score) AS X,MAX(score) AS Y
FROM los_angeles_restaurant_health_inspections
GROUP BY grade

--Single Facility Corporations
--Find all owners which have only a single facility. Output the owner_name and order the results alphabetically.
SELECT owner_name
FROM los_angeles_restaurant_health_inspections
GROUP BY owner_name
HAVING COUNT(1)=1

--3rd Most Reported Health Issues
--Each record in the table is a reported health issue and its classification is categorized by the facility type, size, risk score which is 
--found in the pe_description column.
--If we limit the table to only include businesses with Cafe, Tea, or Juice in the name, find the 3rd most common category (pe_description). 
--Output the name of the facilities that contain 3rd most common category.
WITH a AS
	(SELECT pe_description, COUNT(1) AS count
	FROM los_angeles_restaurant_health_inspections
	WHERE facility_name LIKE '%cafe%'
	OR facility_name LIKE '%tea%'
	OR facility_name LIKE '%juice%'
	GROUP BY pe_description),
b AS
	(SELECT pe_description, count, RANK() OVER(ORDER BY count DESC) AS rank 
	FROM a)
SELECT *
FROM los_angeles_restaurant_health_inspections
WHERE facility_name LIKE '%cafe%'
	OR facility_name LIKE '%tea%'
	OR facility_name LIKE '%juice%'
	AND pe_description IN (SELECT pe_description FROM b WHERE rank=3)

--Find the total number of inspections with low risk in 2017
--Find the total number of inspections with low risk in 2017.
SELECT COUNT(1) AS number_of_inspections
FROM los_angeles_restaurant_health_inspections
WHERE YEAR(activity_date)=2017
AND pe_description LIKE '%LOW RISK%'

--Find the month which had the lowest number of inspections across all years
--Find the month which had the lowest number of inspections across all years.
--Output the number of inspections along with the month.
SELECT MONTH(activity_date) AS month, COUNT(1) number_of_inspections
FROM los_angeles_restaurant_health_inspections
GROUP BY MONTH(activity_date)
ORDER BY 2

--Find the variance and the standard deviation of scores that have grade A
--Find the variance of scores that have grade A using the formula AVG((X_i - mean_x) ^ 2).
--Output the result along with the corresponding standard deviation.
WITH a AS
	(SELECT AVG(score) AS mean_score
	FROM los_angeles_restaurant_health_inspections
	WHERE grade='A')
SELECT AVG(SQUARE(score-mean_score)) AS variance
	, SQRT(AVG(SQUARE(score-mean_score))) AS std
FROM a,los_angeles_restaurant_health_inspections
WHERE grade='A'

SELECT VAR(score) AS variance,
	stdev(score) AS std
FROM los_angeles_restaurant_health_inspections
WHERE grade='A'

--Owners With 3 Grades
--Find the owners who have at least one facility with all 3 grades.
WITH a AS
	(SELECT owner_name,COUNT(1) AS a_grade
	FROM la_restaurant_health_inspections
	WHERE grade='A'
	GROUP BY owner_name),
b AS
	(SELECT owner_name,COUNT(1) AS b_grade
	FROM la_restaurant_health_inspections
	WHERE grade='B'
	GROUP BY owner_name),
c AS
	(SELECT owner_name,COUNT(1) AS c_grade
	FROM la_restaurant_health_inspections
	WHERE grade='C'
	GROUP BY owner_name)
SELECT a.owner_name, a_grade, b_grade, c_grade
FROM a
JOIN b
ON a.owner_name=b.owner_name
JOIN c
ON a.owner_name=c.owner_name

--Facilities With Lots Of Inspections
--Find the facility that got the highest number of inspections in 2017 compared to other years. 
--Compare the number of inspections per year and output only facilities that had the number of inspections greater in 2017 than in any other year.
--Each row in the dataset represents an inspection. Base your solution on the facility name and activity date fields.
WITH a AS
	(SELECT facility_name,[2015],[2016],[2017],[2018]
	FROM  
		(SELECT facility_name, YEAR(activity_date) AS year
		FROM los_angeles_restaurant_health_inspections)   
		AS SourceTable
	PIVOT  
	(  
		COUNT(year)  
	FOR year IN ([2015],[2016],[2017],[2018])  
	) AS PivotTable)
SELECT facility_name, [2015],[2016],[2017],[2018]
FROM a
WHERE [2017]>[2015]
AND [2017]>[2016]
AND [2017]>[2018]

--Find the first and last times the maximum score was awarded
--Find the first and last times the maximum score was awarded
SELECT MIN(activity_date) AS first_time_max_score, MAX(activity_date) AS last_time_max_score
FROM los_angeles_restaurant_health_inspections
WHERE score = (SELECT MAX(score) FROM los_angeles_restaurant_health_inspections)

--Find the scores of 4 quartiles of each company
--Output the company name along with the corresponding score of each quartile.
--Order records based on the average score of all quartiles in ascending order.
SELECT facility_name, score,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY score) OVER (PARTITION BY facility_name) AS min_score,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY score) OVER (PARTITION BY facility_name) AS percentile_cont_25,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY score) OVER (PARTITION BY facility_name) AS percentile_cont_50,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY score) OVER (PARTITION BY facility_name) AS percentile_cont_75,
	PERCENTILE_CONT(1) WITHIN GROUP (ORDER BY score) OVER (PARTITION BY facility_name) AS max_score
FROM los_angeles_restaurant_health_inspections
GROUP BY facility_name

--Dates Of Inspection
--Find the latest inspection date for the most sanitary restaurant(s). 
--Assume the most sanitary restaurant is the one with the highest number of points received in any inspection (not just the last one). 
--Only businesses with 'restaurant' in the name should be considered in your analysis.
--Output the corresponding facility name, inspection score, latest inspection date, previous inspection date, and the difference between the latest and 
--previous inspection dates. 
--And order the records based on the latest inspection date in ascending order.
WITH a AS
(SELECT facility_name, score, activity_date, 
	FIRST_VALUE(activity_date) OVER(PARTITION BY facility_name ORDER BY activity_date DESC) AS latest_inspection_date,
	FIRST_VALUE(score) OVER(PARTITION BY facility_name ORDER BY activity_date DESC) AS latest_inspection_score,
	LEAD(activity_date) OVER(PARTITION BY facility_name ORDER BY activity_date DESC) AS last_inspection_date,
	LEAD(score) OVER(PARTITION BY facility_name ORDER BY activity_date DESC) AS last_inspection_score
FROM los_angeles_restaurant_health_inspections
WHERE facility_name LIKE '%RESTAURANT%')
SELECT * FROM a
WHERE activity_date=latest_inspection_date

--Top 3 Facilities
--Find the top 3 facilities for each owner. The top 3 facilities can be identified using the highest average score for each owner name and facility address grouping.
--The output should include 4 columns: owner name, top 1 facility address, top 2 facility address, and top 3 facility address.
--Order facilities with the same score alphabetically.
WITH a AS
	(SELECT owner_name, facility_name, AVG(score) AS avg_score
	FROM los_angeles_restaurant_health_inspections
	GROUP BY owner_name, facility_name),
b AS
(SELECT owner_name, 
	FIRST_VALUE(facility_name) OVER(PARTITION BY owner_name ORDER BY avg_score DESC) AS top_1_facility, 
	LAG(facility_name) OVER(PARTITION BY owner_name ORDER BY avg_score DESC) top_2_facility, 
	LAG(facility_name,2) OVER(PARTITION BY owner_name ORDER BY avg_score DESC) top_3_facility
FROM a)
SELECT owner_name,MAX(top_1_facility) AS top_1 ,MAX(top_2_facility) AS top_2, MAX(top_3_facility) AS top_3
FROM b
GROUP BY owner_name

--Find the postal code which has the highest average inspection score
--Find the postal code which has the highest average inspection score.
--Output the corresponding postal code along with the result.
SELECT business_postal_code, AVG(inspection_score) AS avg_score
FROM sf_restaurant_health_violations
GROUP BY business_postal_code
ORDER BY 2 DESC

--Classify Business Type
--Classify each business as either a restaurant, cafe, school, or other.
--•	A restaurant should have the word 'restaurant' in the business name.
--•	A cafe should have either 'cafe', 'café', or 'coffee' in the business name.
--•	A school should have the word 'school' in the business name.
--•	All other businesses should be classified as 'other'.
--Output the business name and their classification.
SELECT 
	CASE WHEN business_name LIKE '%restaurant%' THEN 'restaurant'
		WHEN business_name LIKE '%cafe%' OR business_name LIKE '%café%' OR business_name LIKE '%coffee%' THEN 'cafe'
		WHEN business_name LIKE '%school%' THEN 'school'
		ELSE 'other' END AS classification,
business_name, business_address
FROM sf_restaurant_health_violations

--Find the number of violations that each school had
--Find the number of violations that each school had. Any inspection is considered a violation if its risk category is not null.
--Output the corresponding business name along with the result.
--Order the result based on the number of violations in descending order.
SELECT business_name, COUNT(1) AS inspections
FROM sf_restaurant_health_violations
WHERE business_name LIKE '%school%' AND risk_category IS NOT NULL
GROUP BY business_name

--Find industries that make a profit
--Find all industries with a positive average profit. For those industries extract their lowest sale.
--Output the industry along with the corresponding lowest sale and average profit.
--Sort the output based on the lowest sales in ascending order.
SELECT industry, MIN(sales) AS lowest_sales
FROM forbes_global_2010_2014
GROUP BY industry
HAVING AVG(profits)>0

--English, German, French, Spanish Speakers
--Find ids of companies that have more than 2 users who speak English, German, French, or Spanish.
SELECT company_id, COUNT(DISTINCT(user_id)) AS total_users
FROM playbook_users
WHERE language IN ('english','german','french','spanish')
GROUP BY company_id
HAVING COUNT(DISTINCT(user_id))>2

--Find the list of intersections between both word lists
WITH a AS (SELECT value
		FROM google_word_lists a
		CROSS APPLY STRING_SPLIT(words1,',')),
b AS (SELECT value
	FROM google_word_lists
	CROSS APPLY STRING_SPLIT(words2,','))
SELECT a.value
FROM a
JOIN b
ON a.value=b.value

--Counting Instances in Text
--Find the number of times the words 'bull' and 'bear' occur in the contents. 
--We're counting the number of times the words occur so words like 'bullish' should not be included in our count.
--Output the word 'bull' and 'bear' along with the corresponding number of occurrences.
SELECT SUM((len(contents)-len(replace(contents,'bull','')))/4) AS bull_occur, 
SUM((len(contents)-len(replace(contents,'bear','')))/4) AS bear_occur
FROM google_file_store

--Count the number of words per row in both words lists
SELECT *, len(words1)-len(replace(words1,',',''))+1+len(words2)-len(replace(words2,',',''))+1 AS total_word_per_row FROM google_word_lists


--Count users that speak English, German, French or Spanish
--How many users speak English, German, French or Spanish?
--Note: Users who speak more than one language are counted only once.
SELECT COUNT(*) AS total_users
FROM playbook_users
WHERE language IN ('english','german','french','spanish')

--Count the number of companies in the IT sector in each country
--Count the number of companies in the Information Technology sector in each country.
--Output the result along with the corresponding country name.
--Order the result based on the number of companies in the descending order.
SELECT country, COUNT(*) AS total_companies
FROM forbes_global_2010_2014
WHERE sector = 'Information Technology'
GROUP BY country
ORDER BY 2

--Find the student with the highest efficiency for mathematics
--The efficiency is defined as the score divided by hours studied.
--Output the result along with the student id, hours studies and the obtained score for mathematics.
--Sort the results based on the efficiency in the descending order.
SELECT student_id, hrs_studied, sat_math/NULLIF(hrs_studied,0) AS score_efficiency
FROM sat_scores

--Underweight/Overweight Athletes
--Identify colleges with underweight and overweight athletes. Consider athletes with weight < 180 pounds as underweight and 
--players with weight > 250 pounds as overweight. 
--Output the college along with the total number of overweight and underweight players. 
--If the college does not have any underweight/overweight players, leave the college out of the output. 
--You can assume that each athlete's full name is unique on their college.
WITH a AS (SELECT college,COUNT(*) AS total_players FROM nfl_combine
		WHERE weight<180 OR weight>250
		GROUP BY college)
SELECT college, total_players
FROM a
WHERE college IS NOT NULL

--Find the year which had the highest number of players
--Find the year which had the highest number of players. Output the year along with the number of players.
SELECT year, COUNT(*) AS number_players FROM nfl_combine
GROUP BY year

--Find the top 10 ranked songs in 2010
--What were the top 10 ranked songs in 2010?
--Output the rank, group name, and song name but do not show the same song twice.
--Sort the result based on the year_rank in ascending order.
SELECT * FROM billboard_top_100_year_end
WHERE year=2010 AND year_rank<=10

--Find the unique room types
--Find the unique room types(filter room types column). Output each unique room types in its own row.
WITH a AS
(SELECT value AS room_types
FROM airbnb_searches
CROSS APPLY string_split(filter_room_types,','))
SELECT room_types
FROM a
WHERE room_types!=''
GROUP BY room_types

--Count the number of accounts used for logins in 2016
--How many accounts have performed a login in the year 2016?
SELECT COUNT(1) AS total_logins
FROM product_logins
WHERE login_date BETWEEN '2016-01-01' AND '2016-12-21' 

--Drafted Into NFL
--How many athletes were drafted into NFL from 2013 NFL Combine? The pickround column specifies if the athlete was drafted into the NFL. 
--A value of 0 means that the athlete was not drafted into the NFL.
SELECT COUNT(*) AS athletes
FROM nfl_combine
WHERE pickround!=0

--Total Searches For Rooms
--Find the total number of searches for each room type (apartments, private, shared) by city.
SELECT room_type, COUNT(1) AS total_searches
FROM airbnb_search_details
GROUP BY room_type

--Growth of Airbnb
--Estimate the growth of Airbnb each year using the number of hosts registered as the growth metric. 
--The rate of growth is calculated by taking ((number of hosts registered in the current year - number of hosts registered in the previous year) / the number 
--of hosts registered in the previous year) * 100.
--Output the year, number of hosts in the current year, number of hosts in the previous year, and the rate of growth. 
--Round the rate of growth to the nearest percent and order the result in the ascending order based on the year.
--Assume that the dataset consists only of unique hosts, meaning there are no duplicate hosts listed.
WITH a AS (SELECT YEAR(host_since) AS year, COUNT(*) AS total_registered_host, LAG(COUNT(*)) OVER(ORDER BY YEAR(host_since)) AS previous_year_registered_host
		FROM airbnb_search_details
		GROUP BY YEAR(host_since))
SELECT year, total_registered_host, previous_year_registered_host,
CONVERT(DECIMAL(3,0),CAST(total_registered_host-previous_year_registered_host AS DECIMAL(4,2))/previous_year_registered_host*100) AS ratio
FROM a

--Cheapest Neighborhood With Real Beds And Internet
--Find a neighborhood where you can sleep on a real bed in a villa with internet while paying the lowest price possible.
SELECT neighbourhood, a.price, a.property_type, a.bed_type FROM airbnb_search_details a
JOIN (SELECT MIN(price) AS price, property_type, bed_type FROM airbnb_search_details
	WHERE property_type ='Villa' AND bed_type = 'Real Bed' AND amenities LIKE '%Internet%'
	GROUP BY property_type, bed_type, bed_type) b
ON a.price=b.price
AND a.property_type=b.property_type
AND a.bed_type=b.bed_type

--Host Response Rates With Cleaning Fees
--Find the average host response rate with a cleaning fee for each zipcode. Present the results as a percentage along with the zip code value.
--Convert the column 'host_response_rate' from TEXT to NUMERIC using type casts and string processing (take missing values as NULL).
--Order the result in ascending order based on the average host response rater after cleaning.
WITH a AS (SELECT zipcode, CONVERT(DECIMAL(3,0),replace(host_response_rate,'%','')) AS host_response_rate
		FROM airbnb_search_details
		WHERE cleaning_fee=1)
SELECT zipcode, AVG(host_response_rate) AS avg_response_rate
FROM a
GROUP BY zipcode

--City With Most Amenities
--You're given a dataset of searches for properties on Airbnb. For simplicity, let's say that each search result (i.e., each row) represents a unique host. 
--Find the city with the most amenities across all their host's properties. Output the name of the city.
SELECT neighbourhood, SUM(1+LEN(amenities)-LEN(REPLACE(amenities,',',''))) AS total_amenities 
FROM airbnb_search_details
GROUP BY neighbourhood
HAVING neighbourhood IS NOT NULL
ORDER BY 2 DESC

--Host Popularity Rental Prices
--You’re given a table of rental property searches by users. The table consists of search results and outputs host information for searchers. 
--Find the minimum, average, maximum rental prices for each host’s popularity rating. 
-- The host’s popularity rating is defined as below:
--0 reviews: New
--1 to 5 reviews: Rising
--6 to 15 reviews: Trending Up
--16 to 40 reviews: Popular
--more than 40 reviews: Hot
--Tip: The id column in the table refers to the search ID. You'll need to create your own host_id by concating price, room_type, host_since, zipcode, and 
--number_of_reviews.
--Output host popularity rating and their minimum, average and maximum rental prices.
WITH a AS (SELECT CONCAT(CONCAT(CONCAT(CONCAT(CONVERT(DECIMAL(4,0),price),room_type),LEFT(host_since,4)),zipcode),number_of_reviews) AS host_id, 
				CASE 
					WHEN number_of_reviews = 0 THEN 'New' 
					WHEN number_of_reviews BETWEEN 1 AND 5 THEN 'Rising' 
					WHEN number_of_reviews BETWEEN 6 AND 15 THEN 'Trending up'
					WHEN number_of_reviews BETWEEN 16 AND 40 THEN 'Popular'
					ELSE 'Hot'END AS popularity_rating,
					price
				FROM airbnb_host_searches)
SELECT popularity_rating, MIN(price) AS minimum_price ,AVG(price) AS average_price, MAX(price) AS maximum_price
FROM a
GROUP BY popularity_rating

--Find neighborhoods that have properties with a parking space and no cleaning fees
--Find all neighborhoods that have properties with a parking space and don't charge for cleaning fees.
SELECT DISTINCT(neighbourhood) FROM airbnb_search_details
WHERE cleaning_fee =0 AND amenities LIKE '%parking%' AND neighbourhood IS NOT NULL

--Find the count of verified and non-verified Airbnb hosts
--Find how many hosts are verified by the Airbnb staff and how many aren't. Assume that in each row you have a different host.
SELECT 
SUM(CASE WHEN host_identity_verified=1 THEN 1 ELSE 0 END) AS verified_count,
SUM(CASE WHEN host_identity_verified=0 THEN 1 ELSE 0 END) AS non_verified_count
FROM airbnb_search_details

--Reviews Bins on Reviews Number
--To better understand the effect of the review count on the price of accomodation, categorize the number of reviews into the following groups along with the price.
--0 reviews: NO
--1 to 5 reviews: FEW
--6 to 15 reviews: SOME
--16 to 40 reviews: MANY
--more than 40 reviews: A LOT
--Output the price and it's categorization. Perform the categorization on accomodation level.
SELECT AVG(price) AS avg_price, CASE
	WHEN number_of_reviews = 0 THEN 'NO'
	WHEN number_of_reviews BETWEEN 1 AND 5 THEN 'FEW'
	WHEN number_of_reviews BETWEEN 6 AND 15 THEN 'SOME'
	WHEN number_of_reviews BETWEEN 16 AND 40 THEN 'MANY'
	ELSE 'A LOT' END AS review_category
FROM airbnb_search_details
GROUP BY (CASE
	WHEN number_of_reviews = 0 THEN 'NO'
	WHEN number_of_reviews BETWEEN 1 AND 5 THEN 'FEW'
	WHEN number_of_reviews BETWEEN 6 AND 15 THEN 'SOME'
	WHEN number_of_reviews BETWEEN 16 AND 40 THEN 'MANY'
	ELSE 'A LOT' END)

--Accommodates-To-Bed Ratio
--Find the average accommodates-to-beds ratio for shared rooms in each city. Sort your results by listing cities with the highest ratios first.
SELECT city, CONVERT(DECIMAL(5,2),CAST(AVG(accommodates)AS DECIMAL(5,2))/AVG(beds)) AS accommodates_to_beds 
FROM airbnb_search_details
GROUP BY city

--3 Bed Minimum
--Find the average number of beds in each neighborhood that has at least 3 beds in total.
--Output results along with the neighborhood name and sort the results based on the number of average beds in descending order.
WITH a AS (SELECT * FROM airbnb_search_details
		WHERE beds >=3 AND neighbourhood IS NOT NULL)
SELECT neighbourhood, AVG(beds) AS avg_beds
FROM a
GROUP BY neighbourhood
ORDER BY 2 DESC

--Find the search details for villas and houses with wireless internet access
SELECT * FROM airbnb_search_details
WHERE property_type in ('Villa','House') AND amenities LIKE '%wireless%'

--Find the average difference between booking and check-in dates
--Find the average number of days between the booking and check-in dates for AirBnB hosts. Order the results based on the average number of days in descending order.
--avg_days_between_booking_and_checkin DESC
SELECT AVG(DATEDIFF(DAY,ts_booking_at,ds_checkin)) AS avg_days_between_booking_and_checkin
FROM airbnb_contacts
WHERE ts_booking_at IS NOT NULL

--Keywords From Yelp Reviews
--Find Yelp food reviews containing any of the keywords: 'food', 'pizza', 'sandwich', or 'burger'. List the business name, address, and the state 
--which satisfies the requirement.
WITH a AS (SELECT * FROM yelp_reviews a
	WHERE (review_text LIKE '%food%' OR review_text LIKE '%pizza%' OR review_text LIKE '%sandwich%' OR review_text LIKE '%burger%'))
SELECT business_name, address, review_text
FROM a
JOIN yelp_business b
ON b.name=a.business_name

--Find the 80th percentile of hours studied
--Find the 80th percentile of hours studied. Output hours studied value at specified percentile.
SELECT *, PERCENTILE_CONT(0.8) 
        WITHIN GROUP (ORDER BY hrs_studied) 
        OVER ()
        AS percentile_80th
FROM sat_scores

--Find students with a median writing score
--Output ids of students with a median score from the writing SAT.
SELECT student_id, sat_writing FROM sat_scores
WHERE sat_writing = (SELECT DISTINCT(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sat_writing) OVER()) FROM sat_scores)

--Find Nexus5 control group users in Italy who don't speak Italian
--Find user id, language, and location of all Nexus 5 control group users in Italy who do not speak Italian. Sort the results in ascending order based on 
--the occured_at value of the playbook_experiments dataset.
SELECT * FROM playbook_experiments a
JOIN playbook_users b
ON a.user_id=b.user_id
WHERE device = 'nexus 5' AND location ='Italy' AND language!='italian'
ORDER BY occurred_at

--Exclusive Amazon Products
--Find products which are exclusive to only Amazon and therefore not sold at Top Shop and Macy's. Your output should include the product name, brand name, price, 
--and rating.
--Two products are considered equal if they have the same product name and same maximum retail price (mrp column).
WITH a AS (SELECT product_name, mrp FROM innerwear_macys_com
			UNION
			SELECT product_name, mrp FROM innerwear_topshop_com)
SELECT product_name, mrp FROM innerwear_amazon_com
WHERE product_name NOT IN (SELECT product_name FROM a) 
AND mrp NOT IN (SELECT mrp FROM a)

--The Most Expensive Products Per Category
--Find the most expensive products on Amazon for each product category. Output category, product name and the price (as a number)
WITH a AS (SELECT MAX(price) AS price, product_category FROM innerwear_amazon_com
		GROUP BY product_category)
SELECT b.product_category, b.product_name, b.price
FROM innerwear_amazon_com b
JOIN a
ON a.price=b.price AND a.product_category=b.product_category

--Find the average rating of movie stars
--Find the average rating of each movie star along with their names and birthdays. Sort the result in the ascending order based on the birthday. 
--Use the names as keys when joining the tables.
WITH a AS (SELECT * FROM nominee_filmography
		WHERE rating IS NOT NULL)
SELECT a.name, AVG(rating) AS avg_rating, birthday
FROM a
JOIN nominee_information b
ON a.name=b.name
GROUP BY a.name, birthday

--Find fare differences on the Titanic using a self join
--Find the average absolute fare difference between a specific passenger and all passengers that belong to the same pclass, both are non-survivors and age 
--difference between two of them is 5 or less years. 
--Do that for each passenger (that satisfy above mentioned coniditions). Output the result along with the passenger name.
WITH a AS (SELECT name, pclass, age, fare FROM titanic
		WHERE survived = 0 AND age IS NOT NULL)
SELECT *, a.fare-b.fare AS fare_diff FROM a
JOIN (SELECT name, pclass, age, fare FROM titanic
		WHERE survived = 0 AND age IS NOT NULL) b
ON a.pclass=b.pclass
AND a.age-b.age<=5
AND a.name!=b.name
--detail solution 
WITH a AS (SELECT a.name, a.pclass, a.fare-b.fare AS fare_diff FROM (SELECT name, pclass, age, fare FROM titanic WHERE survived = 0 AND age IS NOT NULL) a
	JOIN (SELECT name, pclass, age, fare FROM titanic	WHERE survived = 0 AND age IS NOT NULL) b
	ON a.pclass=b.pclass
	AND a.age-b.age<=5
	AND a.name!=b.name)
SELECT pclass, AVG(fare_diff) AS avg_fare_diff
FROM a
GROUP BY pclass

--Find The Best Day For Trading AAPL Stock
--Find the best day of the month for AAPL stock trading. The best day is the one with highest positive difference between average closing price and 
--average opening price. 
--Output the result along with the average opening and closing prices.
SELECT DAY(date) AS day, AVG(close_price)- AVG(open_price) AS price_diff
FROM aapl_historical_stock_price
GROUP BY DAY(date)
ORDER BY AVG(close_price)- AVG(open_price) DESC

--Find non-HS SAT scores
--Find SAT scores of students whose high school names do not end with 'HS'.
SELECT * FROM sat_scores
WHERE school NOT LIKE '%HS'

--Customer Tracking
--Given the users' sessions logs on a particular day, calculate how many hours each user was active that day.
--Note: The session starts when state=1 and ends when state=0.
WITH a AS (SELECT * FROM cust_tracking
		WHERE state=1),
b AS (SELECT a.cust_id, CONVERT(date,a.timestamp) AS date, a.timestamp AS start_state, b.timestamp AS end_state, datediff(HOUR,a.timestamp,b.timestamp) AS hour
	FROM a
	JOIN (SELECT * FROM cust_tracking
	WHERE state=0) b
	ON a.cust_id=b.cust_id AND a.timestamp<b.timestamp)
SELECT cust_id, date, AVG(hour) AS avg_active_hour FROM b
GROUP BY cust_id, date

--Actual vs Predicted Arrival Time
--Calculate the 90th percentile difference between Actual and Predicted arrival time in minutes for all completed trips within the first 14 days of 2022.
SELECT *, datediff(MINUTE,actual_time_of_arrival,predicted_eta) AS actual_predict_minute_diff, 
PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY datediff(MINUTE,actual_time_of_arrival,predicted_eta)) OVER() AS percentile_90_minute_diff
FROM trip_details
WHERE status ='completed' AND DAY(actual_time_of_arrival)<=14

--First Three Most Watched Videos
--After a new user creates an account and starts watching videos, the user ID, video ID, and date watched are captured in the database. 
--Find the top 3 videos most users have watched as their first 3 videos. Output the video ID and the number of times it has been watched as the users' first 3 videos.
--In the event of a tie, output all the videos in the top 3 that users watched as their first 3 videos.
WITH a AS (SELECT user_id, video_id, MIN(watched_at) AS earliest_watched_at FROM videos_watched
		GROUP BY user_id, video_id)
SELECT video_id, COUNT(1) AS total_first_views
FROM a
GROUP BY video_id
ORDER BY 2 DESC

--User Streaks
--Provided a table with user id and the dates they visited the platform, find the top 3 users with the longest continuous streak of visiting the platform as 
--of August 10, 2022. 
--Output the user ID and the length of the streak.
--In case of a tie, display all users with the top three longest streaks.
WITH a AS (SELECT user_id, date_visited, DAY(date_visited) AS date
		FROM user_streaks
		GROUP BY user_id, date_visited),
b AS (SELECT user_id, date_visited, date, LEAD(date) OVER(PARTITION BY user_id ORDER BY date) AS next_date 
	FROM a),
c AS (SELECT user_id, date_visited, CASE WHEN next_date-date=1 THEN 1 ELSE 0 END AS continous
	FROM b)
SELECT user_id, SUM(continous)
FROM c
GROUP BY user_id

--Duplicate Training Lessons
--Display a list of users who took the same training lessons more than once on the same day. 
--Output their usernames, training IDs, dates and the number of times they took the same lesson.
WITH a AS (SELECT u_id, training_id, training_date, COUNT(1) as number_time
		FROM training_details
		GROUP BY u_id, training_id, training_date
		HAVING COUNT(1)>=2)
SELECT u_name, training_id, training_date, number_time
FROM a
JOIN users_training b
ON a.u_id=b.u_id

--Book Sales
--Calculate the total revenue made per book. Output the book ID and total sales per book. In case there is a book that has never been sold, include it in 
--your output with a value of 0.
SELECT a.book_id, book_title, SUM(CONVERT(bigint,unit_price)*CONVERT(bigint,quantity)) AS revenue
FROM amazon_books_order_details a
JOIN amazon_books b
ON a.book_id = b.book_id
GROUP BY a.book_id, book_title

--Account Registrations
--Find the number of account registrations according to the signup date. Output the months and their corresponding number of registrations.
SELECT MONTH(started_at) AS month, COUNT(1) AS total_registrations 
FROM noom_signups
GROUP BY MONTH(started_at)

--Process a Refund
--Calculate and display the minimum, average and the maximum number of days it takes to process a refund for accounts opened from January 1, 2019. 
--Group by billing cycle in months.
--Note: The time frame for a refund to be fully processed is from settled_at until refunded_at.
WITH a AS (SELECT DATEDIFF(day,settled_at,refunded_at) AS days
		FROM noom_transactions a
		JOIN noom_signups b
		ON a.signup_id=b.signup_id)
SELECT MIN(days) AS minimum_days, AVG(days) AS average_days, MAX(days) AS maximum_days
FROM a

--Top Two Media Types
--What are the top two (ranked in decreasing order) single-channel media types that correspond to the most money the grocery chain had spent on 
--its promotional campaigns?
SELECT media_type, SUM(cost) AS total_cost
FROM facebook_sales_promotions
GROUP BY media_type
ORDER BY 2 DESC
