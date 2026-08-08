-- Prometheus mysqld_exporter user + sample schema
-- Password must match MYSQL_EXPORTER_PASSWORD in .env (default below)
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY 'ExporterMysql2024' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';

USE demo;

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'created',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (amount, status) VALUES
  (19.99, 'created'),
  (49.50, 'paid'),
  (120.00, 'paid'),
  (7.25, 'cancelled');
