# MySQL Database Creation Script

# Run this script if you want to set up the database manually:
# mysql -u root -p < create_db.sql

-- Create the database
CREATE DATABASE IF NOT EXISTS procreditapp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create the user for the application
CREATE USER IF NOT EXISTS 'procreditapp'@'localhost' IDENTIFIED BY 'procreditapp_password';

-- Grant all privileges
GRANT ALL PRIVILEGES ON procreditapp_db.* TO 'procreditapp'@'localhost';

-- Apply the changes
FLUSH PRIVILEGES;

-- Show confirmation
SHOW DATABASES;
SHOW GRANTS FOR 'procreditapp'@'localhost';
