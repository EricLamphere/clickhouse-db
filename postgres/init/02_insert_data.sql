-- Insert sample data into Postgres tables

-- User activities
INSERT INTO source.user_activities (user_id, activity_type, activity_timestamp, session_id, page_url, duration_seconds)
VALUES
    (1001, 'page_view', '2024-01-15 10:30:00', 'sess_001', '/home', 45),
    (1001, 'page_view', '2024-01-15 10:31:00', 'sess_001', '/products', 120),
    (1002, 'page_view', '2024-01-15 10:35:00', 'sess_002', '/home', 30),
    (1002, 'click', '2024-01-15 10:36:00', 'sess_002', '/products/123', 5),
    (1003, 'page_view', '2024-01-15 11:00:00', 'sess_003', '/home', 60),
    (1003, 'search', '2024-01-15 11:02:00', 'sess_003', '/search?q=laptop', 15),
    (1001, 'add_to_cart', '2024-01-15 11:15:00', 'sess_001', '/products/456', 10),
    (1004, 'page_view', '2024-01-15 11:30:00', 'sess_004', '/home', 25),
    (1002, 'checkout', '2024-01-15 11:45:00', 'sess_002', '/checkout', 180),
    (1005, 'page_view', '2024-01-15 12:00:00', 'sess_005', '/home', 35);

-- Inventory data
INSERT INTO source.inventory (product_id, warehouse_location, quantity_available, quantity_reserved, last_restocked_at)
VALUES
    (101, 'US-EAST-01', 500, 50, '2024-01-10 08:00:00'),
    (102, 'US-EAST-01', 250, 25, '2024-01-12 08:00:00'),
    (103, 'US-WEST-01', 750, 100, '2024-01-13 08:00:00'),
    (101, 'US-WEST-01', 300, 30, '2024-01-10 08:00:00'),
    (104, 'EU-CENTRAL-01', 1000, 150, '2024-01-11 08:00:00'),
    (105, 'EU-CENTRAL-01', 600, 75, '2024-01-14 08:00:00'),
    (102, 'EU-WEST-01', 400, 40, '2024-01-12 08:00:00'),
    (106, 'ASIA-EAST-01', 800, 120, '2024-01-09 08:00:00'),
    (103, 'ASIA-EAST-01', 450, 60, '2024-01-13 08:00:00'),
    (107, 'US-EAST-01', 200, 20, '2024-01-15 08:00:00');

-- Payment transactions
INSERT INTO source.payment_transactions (order_id, payment_method, transaction_amount, transaction_status, transaction_timestamp, processor_response)
VALUES
    (1, 'credit_card', 299.99, 'completed', '2024-01-15 09:00:00', '{"status": "approved", "code": "00"}'),
    (2, 'paypal', 149.50, 'completed', '2024-01-15 09:15:00', '{"status": "approved", "transaction_id": "PAY123"}'),
    (3, 'credit_card', 599.99, 'completed', '2024-01-15 09:30:00', '{"status": "approved", "code": "00"}'),
    (4, 'debit_card', 89.99, 'failed', '2024-01-15 09:45:00', '{"status": "declined", "code": "05"}'),
    (5, 'credit_card', 1299.99, 'completed', '2024-01-15 10:00:00', '{"status": "approved", "code": "00"}'),
    (6, 'paypal', 199.99, 'completed', '2024-01-15 10:30:00', '{"status": "approved", "transaction_id": "PAY456"}'),
    (7, 'credit_card', 449.99, 'pending', '2024-01-15 11:00:00', '{"status": "processing"}'),
    (8, 'debit_card', 79.99, 'completed', '2024-01-15 11:15:00', '{"status": "approved", "code": "00"}'),
    (9, 'credit_card', 999.99, 'completed', '2024-01-15 11:30:00', '{"status": "approved", "code": "00"}'),
    (10, 'paypal', 324.50, 'completed', '2024-01-15 12:00:00', '{"status": "approved", "transaction_id": "PAY789"}');
