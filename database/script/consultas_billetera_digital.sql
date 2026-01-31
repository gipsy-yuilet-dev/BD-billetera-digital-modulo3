-- ==================================================================
--  Consultas a una o varias tablas - Alke Wallet (MySQL 8.4)
--  Objetivo: SELECT, filtros, JOINs, subconsultas y vistas
-- ==================================================================

USE alkewallet_db;

-- ------------------------------------------------------------------
-- 1. SELECT básicos sobre usuario_tbl
-- ------------------------------------------------------------------

-- Listado completo de usuarios
SELECT user_id, nombre_usuario, correo_electronico, saldo
FROM usuario_tbl
ORDER BY user_id;

-- Mostrar solo nombre y saldo, ordenados por saldo descendente
SELECT nombre_usuario, saldo
FROM usuario_tbl
ORDER BY saldo DESC;

-- ------------------------------------------------------------------
-- 2. Filtros dinámicos con WHERE y operadores lógicos
-- ------------------------------------------------------------------

SET @nombre_like := 'Maria%';
SET @saldo_minimo := 1000.00;
SET @fecha_desde := '2024-01-01';

-- Usuarios cuyo nombre inicia con un valor dinámico y tienen saldo mínimo
SELECT user_id, nombre_usuario, saldo
FROM usuario_tbl
WHERE nombre_usuario LIKE @nombre_like
  AND saldo >= @saldo_minimo;

-- Transacciones después de una fecha específica y monto mayor a 100
SELECT transaccion_id, fecha_transaccion, importe_transaccion
FROM transaccion_tbl
WHERE fecha_transaccion >= @fecha_desde
  AND importe_transaccion > 100
ORDER BY fecha_transaccion DESC;

-- ------------------------------------------------------------------
-- 3. INNER JOIN entre transaccion_tbl y usuario_tbl
-- ------------------------------------------------------------------

-- JOIN para ver detalle de transacciones con nombres de emisor y receptor
SELECT
    t.transaccion_id,
    t.fecha_transaccion,
    emisor.nombre_usuario   AS nombre_usuario_emisor,
    receptor.nombre_usuario AS nombre_usuario_receptor,
    t.importe_transaccion,
    m.nombre_moneda
FROM transaccion_tbl AS t
INNER JOIN usuario_tbl AS emisor
    ON emisor.user_id = t.usuario_emisor_id
INNER JOIN usuario_tbl AS receptor
    ON receptor.user_id = t.usuario_receptor_id
INNER JOIN moneda_tbl AS m
    ON m.moneda_id = t.moneda_utilizada_id
ORDER BY t.fecha_transaccion DESC;

-- ------------------------------------------------------------------
-- 4. Subconsultas y agregaciones
-- ------------------------------------------------------------------

-- Total de transacciones emitidas por cada usuario (subconsulta correlacionada)
SELECT
    u.user_id,
    u.nombre_usuario,
    (
        SELECT COUNT(1)
        FROM transaccion_tbl AS t
        WHERE t.usuario_emisor_id = u.user_id
    ) AS total_transacciones_emisor
FROM usuario_tbl AS u
ORDER BY total_transacciones_emisor DESC;

-- Total de transacciones (emitidas y recibidas) con agregaciones
SELECT
    u.user_id,
    u.nombre_usuario,
    SUM(CASE WHEN t.usuario_emisor_id = u.user_id THEN 1 ELSE 0 END) AS transacciones_enviadas,
    SUM(CASE WHEN t.usuario_receptor_id = u.user_id THEN 1 ELSE 0 END) AS transacciones_recibidas,
    COUNT(t.transaccion_id) AS total_interacciones
FROM usuario_tbl AS u
LEFT JOIN transaccion_tbl AS t
    ON t.usuario_emisor_id = u.user_id OR t.usuario_receptor_id = u.user_id
GROUP BY u.user_id, u.nombre_usuario
ORDER BY total_interacciones DESC;

-- Sumatoria e importe promedio por usuario emisor
SELECT
    u.user_id,
    u.nombre_usuario,
    COUNT(t.transaccion_id) AS total_transacciones,
    SUM(t.importe_transaccion) AS suma_importes,
    AVG(t.importe_transaccion) AS promedio_importes
FROM usuario_tbl AS u
JOIN transaccion_tbl AS t
    ON t.usuario_emisor_id = u.user_id
GROUP BY u.user_id, u.nombre_usuario
ORDER BY suma_importes DESC;

-- ------------------------------------------------------------------
-- 5. Vista: Top 5 usuarios con mayor saldo
-- ------------------------------------------------------------------

DROP VIEW IF EXISTS vw_top5_saldos_usuario;
CREATE VIEW vw_top5_saldos_usuario AS
SELECT
    user_id,
    nombre_usuario,
    saldo,
    ROW_NUMBER() OVER (ORDER BY saldo DESC) AS posicion
FROM usuario_tbl
ORDER BY saldo DESC
LIMIT 5;

-- Consultar la vista
SELECT * FROM vw_top5_saldos_usuario ORDER BY posicion;

-- ------------------------------------------------------------------
-- 6. Recursos demostrativos (COUNT y SUM globales)
-- ------------------------------------------------------------------

/* Total general de usuarios y saldo acumulado */
SELECT
    COUNT(*) AS total_usuarios,
    COALESCE(SUM(saldo), 0) AS saldo_total
FROM usuario_tbl;

/* Total de transacciones registradas y monto total movido */
SELECT
    COUNT(*) AS total_transacciones,
    COALESCE(SUM(importe_transaccion), 0) AS monto_total_movido
FROM transaccion_tbl;
