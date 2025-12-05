CREATE TABLE items (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100)
    );
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    buyer_id INT,
    store_id INT,
    purchase_time DATETIME,
    refund_time DATETIME,
    gross_transaction_value DECIMAL(10,2)
);
CREATE TABLE transaction_items (
    id INT PRIMARY KEY,
    transaction_id INT,
    item_id INT,
    quantity INT,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

INSERT INTO items VALUES
(1,'Watch'),
(2,'Shoes'),
(3,'Tshirt'),
(4,'Socks');

INSERT INTO transactions VALUES
(1001, 1, 10, '2020-10-05 10:00:00', NULL, 120.00),
(1002, 2, 10, '2020-10-06 12:00:00', '2020-10-06 14:00:00', 200.00),
(1003, 3, 11, '2020-10-06 10:00:00', NULL, 80.00),
(1004, 3, 12, '2020-10-10 08:00:00', '2020-10-13 15:00:00', 400.00);

INSERT INTO transaction_items VALUES
(1,1001,1,1),
(2,1002,2,1),
(3,1003,3,2),
(4,1004,4,1);
SELECT DATE_FORMAT(purchase_time,'%Y-%m') AS month,
       COUNT(*) AS total_purchases
FROM transactions
WHERE refund_time IS NULL
GROUP BY month;

SELECT store_id
FROM transactions
WHERE YEAR(purchase_time) = 2020 AND MONTH(purchase_time) = 10
GROUP BY store_id
HAVING COUNT(transaction_id) >= 5;

SELECT store_id,
       MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS shortest_refund_minutes
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;

WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time) AS rn
    FROM transactions
)
SELECT store_id, gross_transaction_value
FROM ranked
WHERE rn = 1;

WITH first_tx AS (
    SELECT buyer_id, MIN(purchase_time) AS first_purchase_time
    FROM transactions
    WHERE refund_time IS NULL
    GROUP BY buyer_id
),
first_tx_join AS (
    SELECT t.buyer_id, t.transaction_id
    FROM transactions t
    JOIN first_tx f
        ON t.buyer_id = f.buyer_id
       AND t.purchase_time = f.first_purchase_time
)
SELECT i.item_name,
       COUNT(*) AS times_ordered
FROM first_tx_join ft
JOIN transaction_items ti ON ft.transaction_id = ti.transaction_id
JOIN items i ON ti.item_id = i.item_id
GROUP BY i.item_name
ORDER BY times_ordered DESC
LIMIT 1;

SELECT ti.*,
       CASE 
            WHEN t.refund_time IS NULL THEN 0
            WHEN TIMESTAMPDIFF(HOUR, t.purchase_time, t.refund_time) <= 72 THEN 1
            ELSE 0
       END AS refund_process_flag
FROM transaction_items ti
JOIN transactions t USING (transaction_id);

WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT *
FROM ranked
WHERE rn = 2;

WITH ordered AS (
    SELECT buyer_id,
           purchase_time,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT buyer_id, purchase_time AS second_transaction_time
FROM ordered
WHERE rn = 2;


