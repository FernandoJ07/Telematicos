-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS myflaskapp;
USE myflaskapp;

-- Crear tabla users si no existe
CREATE TABLE IF NOT EXISTS users (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name varchar(255),
    email varchar(255),
    username varchar(255),
    password varchar(255)
);

-- Insertar datos iniciales solo si la tabla está vacía
INSERT IGNORE INTO users (id, name, email, username, password) 
VALUES 
    (1, "juan", "juan@gmail.com", "juan", "123"),
    (2, "maria", "maria@gmail.com", "maria", "456");
