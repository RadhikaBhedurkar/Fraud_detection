CREATE DATABASE Credit_card;

USE Credit_card;

-- customers

CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100),
  phone VARCHAR(20),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- cards

CREATE TABLE cards (
  card_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT,
  card_number_hash CHAR(64), 
  card_type VARCHAR(20),
  issued_date DATE,
  expire_date DATE,
  is_active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- merchants

CREATE TABLE merchants (
  merchant_id INT AUTO_INCREMENT PRIMARY KEY,
  merchant_name VARCHAR(100),
  merchant_category VARCHAR(50), -- MCC-like
  city VARCHAR(50),
  country VARCHAR(50)
);

-- transactions (core table)

CREATE TABLE transactions (
  txn_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  card_id INT,
  customer_id INT,
  merchant_id INT,
  txn_amount DECIMAL(10,2),
  currency CHAR(3) DEFAULT 'USD',
  txn_time DATETIME,
  merchant_city VARCHAR(50),
  merchant_country VARCHAR(50),
  pos_entry_mode VARCHAR(20), 
  device_id VARCHAR(100), 
  is_declined TINYINT(1) DEFAULT 0,
  label_is_fraud TINYINT(1) DEFAULT NULL, 
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (card_id) REFERENCES cards(card_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);


-- customers

INSERT INTO customers (first_name, last_name, email, phone) VALUES
('Radhika','Bhedurkar','radhika@example.com','+919000000000'),
('Amit','Shah','amit@example.com','+919000000001'),
('Priya','Verma','priya@example.com','+919000000002'),
('Rahul','Kumar','rahul@example.com','+919000000003'),
('Sneha','Joshi','sneha@example.com','+919000000004');


-- cards

INSERT INTO cards (customer_id, card_number_hash, card_type, issued_date, expire_date) VALUES
(1, SHA2('4111111111111111',256), 'VISA', '2019-01-01','2026-01-01'),
(2, SHA2('5500000000000004',256), 'MASTERCARD', '2021-06-01','2028-06-01'),
(3, SHA2('340000000000009',256), 'AMEX', '2020-03-15','2025-03-15'),
(4, SHA2('30000000000004',256), 'DINERS', '2018-11-01','2023-11-01'),
(5, SHA2('6011000000000004',256), 'DISCOVER', '2022-07-10','2027-07-10');


-- merchants

INSERT INTO merchants (merchant_name, merchant_category, city, country) VALUES
('ElectroStore','Electronics','Mumbai','India'),
('FlightNow','Travel','Delhi','India'),
('OnlineShop','Ecommerce','Remote','India'),
('SuperMart','Grocery','Bangalore','India'),
('FashionHub','Clothing','Pune','India');


-- transactions (core table)

INSERT INTO transactions 
(card_id, customer_id, merchant_id, txn_amount, txn_time, merchant_city, merchant_country, pos_entry_mode, device_id, is_declined, label_is_fraud) VALUES
(1,1,1,12000.00,'2025-10-17 10:12:00','Mumbai','India','chip','device_a',0,0),
(1,1,3,45.00,'2025-10-17 10:15:00','Remote','India','online','device_a',0,0),
(1,1,2,9500.00,'2025-10-17 23:50:00','Delhi','India','online','device_x',0,1),
(2,2,3,12.00,'2025-10-16 09:20:00','Remote','India','online','device_b',0,0),
(2,2,4,800.00,'2025-10-16 15:30:00','Bangalore','India','chip','device_b',0,0),
(3,3,1,5000.00,'2025-10-15 14:00:00','Mumbai','India','swipe','device_c',0,0),
(3,3,5,2000.00,'2025-10-15 18:30:00','Pune','India','online','device_c',0,0),
(4,4,2,15000.00,'2025-10-14 22:10:00','Delhi','India','online','device_d',0,1),
(5,5,5,100.00,'2025-10-13 11:45:00','Pune','India','chip','device_e',0,0),
(5,5,3,7000.00,'2025-10-13 23:00:00','Remote','India','online','device_e',0,1);


-- Q1: List all customers who have made transactions.

SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id;


-- Q2: Count the number of transactions per customer.

SELECT customer_id, COUNT(*) AS total_transactions
FROM transactions
GROUP BY customer_id;


-- Q3: Find the total amount spent by each customer.

SELECT customer_id, SUM(txn_amount) AS total_spent
FROM transactions
GROUP BY customer_id;


-- Q4: Show all merchants in Mumbai.

SELECT * FROM merchants
WHERE city = 'Mumbai';


-- Q5: List all transactions labeled as fraud.

SELECT * FROM transactions
WHERE label_is_fraud = 1;


-- Q6: Find the total number of fraudulent transactions per customer.

SELECT customer_id, COUNT(*) AS fraud_count
FROM transactions
WHERE label_is_fraud = 1
GROUP BY customer_id;


-- Q7: List high-value transactions above 10,000.

SELECT * FROM transactions
WHERE txn_amount > 10000;


-- Q8:  Find the average transaction amount per merchant.

SELECT merchant_id, AVG(txn_amount) AS avg_amount
FROM transactions
GROUP BY merchant_id;


-- Q9: Find transactions above 5,000 for each card (High Amount Rule).

SELECT * FROM transactions
WHERE txn_amount > 5000;


-- Q10: Identify customers with multiple transactions in a short period (Velocity Rule, e.g., 10 min).

SELECT t1.customer_id, t1.txn_time, COUNT(*) AS txn_count
FROM transactions t1
JOIN transactions t2 ON t1.customer_id = t2.customer_id
AND t2.txn_time BETWEEN DATE_SUB(t1.txn_time, INTERVAL 10 MINUTE) AND t1.txn_time
GROUP BY t1.txn_id, t1.customer_id, t1.txn_time
HAVING txn_count > 2;


-- Q11: Identify possible impossible travel (transactions in two countries within 2 hours).

SELECT t1.customer_id, t1.txn_id AS txn1, t2.txn_id AS txn2, t1.merchant_country AS country1, t2.merchant_country AS country2
FROM transactions t1
JOIN transactions t2 ON t1.customer_id = t2.customer_id
AND t1.txn_time < t2.txn_time
AND TIMESTAMPDIFF(HOUR, t1.txn_time, t2.txn_time) <= 2
AND t1.merchant_country <> t2.merchant_country;


-- Q12: Compute total fraud amount per merchant.

SELECT merchant_id, SUM(txn_amount) AS total_fraud_amount
FROM transactions
WHERE label_is_fraud = 1
GROUP BY merchant_id;


-- Q13: Rank customers by total fraud amount.

SELECT customer_id, SUM(txn_amount) AS total_fraud_amount
FROM transactions
WHERE label_is_fraud = 1
GROUP BY customer_id
ORDER BY total_fraud_amount DESC;


-- Q14: Find the average transaction amount in the last 7 days per customer.

SELECT customer_id, AVG(txn_amount) AS avg_7days
FROM transactions
WHERE txn_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY customer_id;


-- Q15: Create a view showing each card’s risk score based on high amount and velocity rules.

CREATE VIEW card_risk_score AS
SELECT t.card_id,
  (CASE WHEN t.txn_amount > 5000 THEN 1 ELSE 0 END
   + CASE WHEN (SELECT COUNT(*) FROM transactions t2 WHERE t2.card_id = t.card_id AND t2.txn_time BETWEEN DATE_SUB(t.txn_time, INTERVAL 10 MINUTE) AND t.txn_time) > 2 THEN 1 ELSE 0 END) AS risk_score
FROM transactions t;


-- Q16: Count the number of declined transactions.

SELECT COUNT(*) AS declined_count
FROM transactions
WHERE is_declined = 1;


-- Q17: Find the merchant with the highest number of frauds.

SELECT merchant_id, COUNT(*) AS fraud_count
FROM transactions
WHERE label_is_fraud = 1
GROUP BY merchant_id
ORDER BY fraud_count DESC
LIMIT 1;


-- Q18: List all transactions for a specific customer along with merchant details.

SELECT t.txn_id, t.txn_amount, t.txn_time, m.merchant_name, m.merchant_category
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
WHERE t.customer_id = 1;


-- Q19: List the top 3 customers with the highest total transaction amount.

SELECT customer_id, SUM(txn_amount) AS total_amount
FROM transactions
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 3;


-- Q20: Find customers who never had a fraudulent transaction.

SELECT customer_id
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM transactions
    WHERE label_is_fraud = 1
);


-- Q21: Identify customers with transactions in multiple cities in a single day.

SELECT customer_id, txn_time, COUNT(DISTINCT merchant_city) AS city_count
FROM transactions
GROUP BY customer_id, DATE(txn_time)
HAVING city_count > 1;


-- Q22: List cards with more than 2 declined transactions.

SELECT card_id, COUNT(*) AS declined_count
FROM transactions
WHERE is_declined = 1
GROUP BY card_id
HAVING declined_count > 2;


-- Q23: Find the card with the highest fraud amount.

SELECT card_id, SUM(txn_amount) AS fraud_total
FROM transactions
WHERE label_is_fraud = 1
GROUP BY card_id
ORDER BY fraud_total DESC
LIMIT 1;


-- Q24: Count the number of active vs inactive cards.

SELECT is_active, COUNT(*) AS total_cards
FROM cards
GROUP BY is_active;


-- Q25: Find merchants with more than 1 fraudulent transaction.

SELECT merchant_id, COUNT(*) AS fraud_count
FROM transactions
WHERE label_is_fraud = 1
GROUP BY merchant_id
HAVING fraud_count > 1;


-- Q26: List top 3 merchants with the highest total sales amount.

SELECT merchant_id, SUM(txn_amount) AS total_sales
FROM transactions
GROUP BY merchant_id
ORDER BY total_sales DESC
LIMIT 3;


-- Q27: Show the average transaction amount per merchant category.

SELECT m.merchant_category, AVG(t.txn_amount) AS avg_amount
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_category;


-- Q28: Identify customers with consecutive fraudulent transactions.

SELECT t1.customer_id, t1.txn_id AS txn1, t2.txn_id AS txn2
FROM transactions t1
JOIN transactions t2 ON t1.customer_id = t2.customer_id
AND t2.txn_time > t1.txn_time
WHERE t1.label_is_fraud = 1 AND t2.label_is_fraud = 1;


-- Q29: Find transactions that are unusually high compared to the customer’s average.

SELECT t.txn_id, t.customer_id, t.txn_amount, AVG(t2.txn_amount) AS avg_amount
FROM transactions t
JOIN transactions t2 ON t.customer_id = t2.customer_id
GROUP BY t.txn_id
HAVING t.txn_amount > 3 * AVG(t2.txn_amount);


-- Q30: Detect customers with transactions in two different countries within 24 hours.

SELECT t1.customer_id, t1.txn_id AS txn1, t2.txn_id AS txn2, t1.merchant_country AS country1, t2.merchant_country AS country2
FROM transactions t1
JOIN transactions t2 ON t1.customer_id = t2.customer_id
AND t2.txn_time BETWEEN t1.txn_time AND DATE_ADD(t1.txn_time, INTERVAL 24 HOUR)
AND t1.merchant_country <> t2.merchant_country;


-- Q31: Count the number of transactions per day.

SELECT DATE(txn_time) AS txn_date, COUNT(*) AS txn_count
FROM transactions
GROUP BY txn_date
ORDER BY txn_date;


-- Q32: Find peak transaction hours.

SELECT HOUR(txn_time) AS txn_hour, COUNT(*) AS txn_count
FROM transactions
GROUP BY txn_hour
ORDER BY txn_count DESC;


-- Q33: Average transaction amount per hour.

SELECT HOUR(txn_time) AS txn_hour, AVG(txn_amount) AS avg_amount
FROM transactions
GROUP BY txn_hour
ORDER BY txn_hour;


-- Q34: Customers whose total fraud amount exceeds 10,000.

SELECT customer_id, SUM(txn_amount) AS total_fraud
FROM transactions
WHERE label_is_fraud = 1
GROUP BY customer_id
HAVING total_fraud > 10000;


-- Q35: Find merchants that have processed both fraudulent and non-fraudulent transactions.

SELECT merchant_id
FROM transactions
GROUP BY merchant_id
HAVING SUM(label_is_fraud = 1) > 0 AND SUM(label_is_fraud = 0) > 0;


-- Q36: List top 5 high-risk cards (based on number of frauds).

SELECT card_id, COUNT(*) AS fraud_count
FROM transactions
WHERE label_is_fraud = 1
GROUP BY card_id
ORDER BY fraud_count DESC
LIMIT 5;

