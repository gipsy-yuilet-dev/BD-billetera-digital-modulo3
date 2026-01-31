-- ================================================================
--  Alke Wallet (_db, _tbl, _atributos) - MySQL 8.4 compatible
-- ================================================================

CREATE DATABASE IF NOT EXISTS alkewallet_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE alkewallet_db;

-- Limpieza controlada para entornos de desarrollo
DROP TABLE IF EXISTS transaccion_tbl;
DROP TABLE IF EXISTS moneda_tbl;
DROP TABLE IF EXISTS usuario_tbl;

-- 1. Crear tabla usuario_tbl
CREATE TABLE usuario_tbl (
    user_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre_usuario VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(100) NOT NULL,
    saldo DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (saldo >= 0),
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id)
) ENGINE = InnoDB;

-- 2. Crear tabla moneda_tbl
CREATE TABLE moneda_tbl (
    moneda_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre_moneda VARCHAR(50) NOT NULL,
    simbolo_moneda VARCHAR(5) NOT NULL,
    codigo_moneda CHAR(3) NOT NULL UNIQUE,
    PRIMARY KEY (moneda_id)
) ENGINE = InnoDB;

-- 3. Crear tabla transaccion_tbl
CREATE TABLE transaccion_tbl (
    transaccion_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_emisor_id INT UNSIGNED NOT NULL,
    usuario_receptor_id INT UNSIGNED NOT NULL,
    importe_transaccion DECIMAL(15, 2) NOT NULL CHECK (importe_transaccion > 0),
    fecha_transaccion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    moneda_utilizada_id INT UNSIGNED NOT NULL,
    CONSTRAINT chk_emisor_distinto_receptor CHECK (usuario_emisor_id <> usuario_receptor_id),
    CONSTRAINT fk_transaccion_usuario_emisor FOREIGN KEY (usuario_emisor_id) REFERENCES usuario_tbl(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_transaccion_usuario_receptor FOREIGN KEY (usuario_receptor_id) REFERENCES usuario_tbl(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_transaccion_moneda FOREIGN KEY (moneda_utilizada_id) REFERENCES moneda_tbl(moneda_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    PRIMARY KEY (transaccion_id)
) ENGINE = InnoDB;

-- Índices para consultas frecuentes
CREATE INDEX idx_usuario_nombre_correo ON usuario_tbl (nombre_usuario, correo_electronico);
CREATE INDEX idx_transaccion_emisor_fecha ON transaccion_tbl (usuario_emisor_id, fecha_transaccion);
CREATE INDEX idx_transaccion_receptor_fecha ON transaccion_tbl (usuario_receptor_id, fecha_transaccion);

-- Insertar Usuarios
INSERT INTO usuario_tbl (nombre_usuario, correo_electronico, contrasena, saldo) VALUES
('Juan Perez', 'juan@example.com', 'pass123', 5000.00),
('Maria Lopez', 'maria@example.com', 'secure456', 12000.50),
('Carlos Ruiz', 'carlos@example.com', 'clave789', 300.00),
('Pedro Santana', 'pedrosantana@example.com', 'pedro652', 500.00),
('Francisca Ramirez', 'franramirez@example.com', 'fran0923', 13000.00),
('Armando Meza', 'ameza@example.com', 'Armando987', 120000.00),
('Linda Hermosilla', 'lindahermosa@example.com', 'Hermosa623', 300.00),
('Manuel Rivas', 'manuelrivas@example.com', 'manuel689', 1000.00),
('Jacinta Larrain', 'jacintallarain@example.com', 'jacinta932', 1500000.00),
('Nelson Navia', 'nelsonnavia@example.com', 'nelson951', 5000.00),
('Salvador Rivera', 'srivera@example.com', 'Salva789', 150000.00),
('Jackie Micheaux', 'jackiemichi@example.com', 'jacki820', 3000.00);

-- Insertar Monedas
INSERT INTO moneda_tbl (nombre_moneda, simbolo_moneda, codigo_moneda) VALUES
('Dolar estadounidense', '$', 'USD'),
('Euro', '€', 'EUR'),
('Peso Chileno', 'CLP$', 'CLP');

-- Insertar Transacciones base
INSERT INTO transaccion_tbl (usuario_emisor_id, usuario_receptor_id, importe_transaccion, fecha_transaccion, moneda_utilizada_id)
VALUES
(1, 2, 100.00, '2024-03-20', 1),
(2, 3, 5000.00, '2024-03-21', 3);

-- ===================================================================
--  Lección 3: DML y control transaccional (ejecutar bloque por bloque)
-- ===================================================================

-- Ejemplo 1: transferencia controlada con COMMIT (Juan -> María)
SET @monto_transferencia := 250.00;
START TRANSACTION;
INSERT INTO transaccion_tbl (usuario_emisor_id, usuario_receptor_id, importe_transaccion, fecha_transaccion, moneda_utilizada_id)
VALUES (1, 2, @monto_transferencia, NOW(), 1);
SET @ultima_transaccion := LAST_INSERT_ID();
UPDATE usuario_tbl SET saldo = saldo - @monto_transferencia WHERE user_id = 1;
UPDATE usuario_tbl SET saldo = saldo + @monto_transferencia WHERE user_id = 2;
COMMIT;

-- Ejemplo 2: limpieza controlada + ROLLBACK (sin violar FK)
START TRANSACTION;
DELETE FROM transaccion_tbl
WHERE usuario_emisor_id = 1 OR usuario_receptor_id = 1;
DELETE FROM usuario_tbl WHERE user_id = 1;
ROLLBACK;

-- Tarea Plus: 50 transacciones pseudoaleatorias mediante CTE secuencial
-- Ejecutar solo una vez o envolver en TRANSACTION + ROLLBACK para pruebas
START TRANSACTION;
INSERT INTO transaccion_tbl (usuario_emisor_id, usuario_receptor_id, importe_transaccion, fecha_transaccion, moneda_utilizada_id)
SELECT
    movimientos.usuario_emisor_id,
    movimientos.usuario_receptor_id,
    movimientos.importe_transaccion,
    movimientos.fecha_transaccion,
    movimientos.moneda_utilizada_id
FROM (
    WITH RECURSIVE seq AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1 FROM seq WHERE n < 50
    )
    SELECT 
        ((n - 1) MOD 12) + 1 AS usuario_emisor_id,
        ((n + 4) MOD 12) + 1 AS usuario_receptor_id,
        ROUND(50 + RAND(n) * 950, 2) AS importe_transaccion,
        DATE_SUB(NOW(), INTERVAL n DAY) AS fecha_transaccion,
        ((n - 1) MOD 3) + 1 AS moneda_utilizada_id
    FROM seq
    WHERE ((n - 1) MOD 12) + 1 <> ((n + 4) MOD 12) + 1
) AS movimientos;
COMMIT;

/* ================================================================
    Consultas SQL solicitadas (ajustar @usuario_objetivo según sea necesario)
    ================================================================ */

SET @usuario_objetivo := 2;
SET @transaccion_a_eliminar := 2;

-- Consulta 1: Moneda elegida por un usuario específico
SELECT DISTINCT
    u.user_id,
    u.nombre_usuario,
    m.nombre_moneda AS moneda_utilizada
FROM usuario_tbl AS u
JOIN transaccion_tbl AS t
    ON t.usuario_emisor_id = u.user_id OR t.usuario_receptor_id = u.user_id
JOIN moneda_tbl AS m
    ON m.moneda_id = t.moneda_utilizada_id
WHERE u.user_id = @usuario_objetivo;

-- Consulta 2: Todas las transacciones registradas
SELECT
    t.transaccion_id,
    t.fecha_transaccion,
    emisor.nombre_usuario   AS nombre_usuario_emisor,
    receptor.nombre_usuario AS nombre_usuario_receptor,
    t.importe_transaccion,
    m.nombre_moneda         AS moneda_utilizada
FROM transaccion_tbl AS t
JOIN usuario_tbl AS emisor
    ON emisor.user_id = t.usuario_emisor_id
JOIN usuario_tbl AS receptor
    ON receptor.user_id = t.usuario_receptor_id
JOIN moneda_tbl AS m
    ON m.moneda_id = t.moneda_utilizada_id
ORDER BY t.fecha_transaccion DESC, t.transaccion_id DESC;

-- Consulta 3: Transacciones realizadas por un usuario específico
SELECT
    t.transaccion_id,
    t.fecha_transaccion,
    emisor.nombre_usuario   AS nombre_usuario_emisor,
    receptor.nombre_usuario AS nombre_usuario_receptor,
    t.importe_transaccion,
    m.nombre_moneda         AS moneda_utilizada,
    CASE
        WHEN t.usuario_emisor_id = @usuario_objetivo THEN 'EMISOR'
        ELSE 'RECEPTOR'
    END AS rol_usuario
FROM transaccion_tbl AS t
JOIN usuario_tbl AS emisor
    ON emisor.user_id = t.usuario_emisor_id
JOIN usuario_tbl AS receptor
    ON receptor.user_id = t.usuario_receptor_id
JOIN moneda_tbl AS m
    ON m.moneda_id = t.moneda_utilizada_id
WHERE t.usuario_emisor_id = @usuario_objetivo
   OR t.usuario_receptor_id = @usuario_objetivo
ORDER BY t.fecha_transaccion DESC, t.transaccion_id DESC;

-- Sentencia DML para modificar correo electrónico
UPDATE usuario_tbl
SET correo_electronico = 'maria.lopez.actualizado@example.com'
WHERE user_id = @usuario_objetivo;

-- Sentencia para eliminar una transacción específica
DELETE FROM transaccion_tbl
WHERE transaccion_id = @transaccion_a_eliminar;