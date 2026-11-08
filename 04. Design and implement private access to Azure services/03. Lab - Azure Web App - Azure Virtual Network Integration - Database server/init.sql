# 1 - First install the MySQL Server

sudo apt update
sudo apt install -y mysql-server
clear

# 2 - Make MySQL listen on the network

sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Change the bind address
bind-address = 10.0.1.4

sudo systemctl restart mysql

# 3 - Create a new MySQL user

sudo mysql

CREATE USER 'dbadmin'@'%' IDENTIFIED BY '<your-db-password>';
GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

# 4 - Create a database and a table

CREATE DATABASE coursesdb;
USE coursesdb;

CREATE TABLE IF NOT EXISTS courses (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(200) NOT NULL,
  rating DECIMAL(3,1) NOT NULL
);

# 5 - Insert information into the table
INSERT INTO courses (name, rating) VALUES
('Docker and Kubernetes', 4.5),
('AI-102 Azure AI Engineer', 4.6),
('AZ-104 Azure Administrator', 4.7);