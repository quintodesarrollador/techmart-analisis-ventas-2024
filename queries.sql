-- Consultas de negocio sobre la tabla `ventas` (ventas_limpias.csv).
-- Probadas en SQLite, usan SQL estandar (CTE y funciones de ventana),
-- asi que funcionan igual en PostgreSQL, SQL Server y MySQL 8.
-- importe neto de una linea = cantidad * precio * (1 - descuento_pct / 100.0)
-- Las cantidades negativas se tratan como devoluciones (restan).

-- 1) Ingresos netos totales 2024
SELECT ROUND(SUM(cantidad * precio * (1 - descuento_pct / 100.0)), 2) AS ingresos_netos
FROM ventas;

-- 2) Ingresos por categoria y peso sobre el total
SELECT categoria,
       ROUND(SUM(cantidad * precio * (1 - descuento_pct / 100.0)), 2) AS ingresos_netos,
       ROUND(100.0 * SUM(cantidad * precio * (1 - descuento_pct / 100.0))
             / SUM(SUM(cantidad * precio * (1 - descuento_pct / 100.0))) OVER (), 1) AS pct_total
FROM ventas
GROUP BY categoria
ORDER BY ingresos_netos DESC;

-- 3) Ingresos por mes y peso del ultimo trimestre
SELECT mes,
       ROUND(SUM(cantidad * precio * (1 - descuento_pct / 100.0)), 0) AS ingresos_netos
FROM ventas
GROUP BY mes
ORDER BY mes;

SELECT ROUND(100.0 * SUM(CASE WHEN mes >= 10 THEN cantidad * precio * (1 - descuento_pct / 100.0) END)
             / SUM(cantidad * precio * (1 - descuento_pct / 100.0)), 1) AS pct_ultimo_trimestre
FROM ventas;

-- 4) Descuentos: unidades por linea de venta segun nivel de descuento
SELECT descuento_pct,
       COUNT(*) AS lineas,
       ROUND(1.0 * SUM(cantidad) / COUNT(*), 2) AS unidades_por_linea
FROM ventas
WHERE cantidad > 0
GROUP BY descuento_pct
ORDER BY descuento_pct;

-- 5) Descuento total concedido sobre el precio de lista (solo ventas)
SELECT ROUND(SUM(cantidad * precio * descuento_pct / 100.0), 0) AS descuento_concedido
FROM ventas
WHERE cantidad > 0;

-- 6) Recompra: clientes que compran en mas de una fecha y su peso en el ingreso de ventas
WITH por_cliente AS (
    SELECT cliente_id,
           COUNT(DISTINCT fecha) AS fechas_compra,
           SUM(cantidad * precio * (1 - descuento_pct / 100.0)) AS ingreso
    FROM ventas
    WHERE cantidad > 0
    GROUP BY cliente_id
)
SELECT COUNT(*) AS clientes,
       ROUND(100.0 * SUM(CASE WHEN fechas_compra > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_recurrentes,
       ROUND(100.0 * SUM(CASE WHEN fechas_compra > 1 THEN ingreso ELSE 0 END) / SUM(ingreso), 1) AS pct_ingreso_recurrentes
FROM por_cliente;

-- 7) Venta cruzada: compras (cliente + fecha) de producto principal que incluyen un accesorio
WITH compras AS (
    SELECT cliente_id, fecha,
           MAX(CASE WHEN categoria IN ('Televisores','Portátiles','Tablets','Smartphones','Gaming') THEN 1 ELSE 0 END) AS tiene_principal,
           MAX(CASE WHEN categoria = 'Accesorios' THEN 1 ELSE 0 END) AS tiene_accesorio
    FROM ventas
    WHERE cantidad > 0
    GROUP BY cliente_id, fecha
)
SELECT SUM(tiene_principal) AS compras_con_principal,
       ROUND(100.0 * SUM(CASE WHEN tiene_principal = 1 AND tiene_accesorio = 1 THEN 1 ELSE 0 END)
             / SUM(tiene_principal), 2) AS pct_con_accesorio
FROM compras;
