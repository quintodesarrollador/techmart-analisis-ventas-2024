# Análisis de ventas TechMart 2024

Caso de análisis de datos de principio a fin: un archivo de ventas sin documentar de un e-commerce de electrónica se limpia, se analiza con Python y SQL, y se presenta en un dashboard interactivo con resumen ejecutivo y recomendaciones.

> **Nota:** `ventas_techmart_2024.csv` es un conjunto de datos de práctica, no datos reales de un cliente.

## Resumen

TechMart facturó **7.989.107,51 € netos** en 2024 (España y Portugal, canales Web y Marketplace). El negocio es sólido, pero depende de la recompra y desaprovecha descuentos, temporada alta y venta cruzada. Las cuatro recomendaciones suman un potencial de ≈ 0,63 M€ (≈ 7,8 % del ingreso), calculado como **escenarios con supuestos explícitos**, no como previsión.

| Hallazgo | Dato |
|---|---|
| Concentración | Televisores y Portátiles aportan el 54,2 % del ingreso |
| Recompra | El 77,9 % de los clientes compra en más de una fecha y aporta el 91,8 % del ingreso de ventas |
| Descuentos | 257.737 € concedidos (3,1 % sobre precio de lista); 2,02 unidades por línea sin descuento y 1,96 con un 20 % |
| Temporada | El último trimestre pesa el 23,9 %, menos del 25 % de un reparto uniforme |
| Venta cruzada | Solo el 0,1 % de las compras de producto principal incluye un accesorio |

## Recomendaciones

| # | Acción | Impacto estimado |
|---|---|---|
| 1 | Activar la recompra (campaña de segunda compra y recordatorios) | ≈ +436 mil € (+5,5 %) |
| 2 | Campaña de temporada alta en la web (octubre a diciembre) | ≈ +100 mil € (+1,3 %) |
| 3 | Tope del 10 % en descuentos con prueba A/B | ≈ +59 mil € (+0,7 %) |
| 4 | Accesorio junto al producto principal | ≈ +30 mil € (+0,4 %) |

Son impactos sobre ingresos, no sobre margen: el archivo no tiene costes. Los supuestos de cada escenario están en el dashboard, pestaña **Resumen Ejecutivo**.

## Problemas de calidad de datos detectados

1. **Clave de pedido poco fiable:** 177 filas duplicadas exactas, y `id_pedido` se repite entre clientes y fechas distintos.
2. **Fechas en tres formatos**, con cerca del 27 % ambiguo entre día/mes y mes/día. Se asume día/mes/año.
3. **Categorías inconsistentes:** 16 etiquetas para unas 9 categorías reales.

También hay nulos con formas distintas (`N/D`, `-`, vacío), precios como texto (`261,43 €`), cantidades negativas y espacios sobrantes.

## Estructura del repositorio

```
├── data/
│   ├── ventas_techmart_2024.csv   # datos originales
│   └── ventas_limpias.csv         # resultado de la limpieza
├── src/
│   └── clean_data.py              # limpieza con pandas
├── sql/
│   └── queries.sql                # 7 consultas de negocio
├── dashboard/
│   └── index.html                 # dashboard interactivo (abrir en el navegador)
├── requirements.txt
└── README.md
```

## Cómo reproducirlo

```bash
pip install -r requirements.txt
python src/clean_data.py data/ventas_techmart_2024.csv data/ventas_limpias.csv
```

El script imprime las filas limpias y los ingresos netos (7.989.107,51 €). Para las consultas, carga `data/ventas_limpias.csv` en una tabla llamada `ventas`. Por ejemplo, con SQLite:

```bash
sqlite3 techmart.db
.mode csv
.import --skip 1 data/ventas_limpias.csv ventas
.read sql/queries.sql
```

Las consultas usan SQL estándar (agregaciones, funciones de ventana y CTE), probadas en SQLite. El dashboard carga Chart.js desde un CDN, así que necesita conexión a internet.

## Supuestos por validar

- Moneda en euros, precio antes de descuento y sin dato de IVA.
- Descuento vacío = 0 %.
- Las cantidades negativas son devoluciones y restan.
- Ordenadores se agrupa con Portátiles y Telefonía con Smartphones.
- Una «compra» es una combinación de cliente y fecha, porque `id_pedido` no es fiable. Casi todas las compras tienen una sola línea, algo que habría que validar con el sistema de origen.

## Herramientas

Python (pandas), SQL, HTML y JavaScript (Chart.js). Siguiente paso previsto: versión del dashboard en Power BI y medición de margen al incorporar costes.
