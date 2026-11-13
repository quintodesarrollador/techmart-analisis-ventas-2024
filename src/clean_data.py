"""Limpieza de ventas_techmart_2024.csv -> ventas_limpias.csv

Uso (desde la raiz del repositorio):
    python src/clean_data.py data/ventas_techmart_2024.csv data/ventas_limpias.csv

Reglas aplicadas (ver README):
- Se eliminan filas duplicadas exactas.
- precio_unitario: texto con coma decimal y simbolo EUR -> numero.
- fecha: tres formatos (AAAA-MM-DD, DD/MM/AAAA, DD-MM-AAAA). Se asume dia/mes/anio.
- categoria: se unifican etiquetas equivalentes (supuesto a validar con el negocio).
- canal: se quitan espacios sobrantes.
- descuento_pct vacio = 0 (supuesto).
- Los nulos disfrazados (N/D, -) pasan a vacio.
"""
import sys
import unicodedata
import pandas as pd

CATEGORIAS = {
    "tv": "Televisores", "televisores": "Televisores",
    "portatiles": "Portátiles", "laptops": "Portátiles", "ordenadores": "Portátiles",
    "smartphones": "Smartphones", "moviles": "Smartphones", "telefonia": "Smartphones",
    "tablets": "Tablets", "accesorios": "Accesorios", "gaming": "Gaming",
    "wearables": "Wearables", "audio": "Audio",
}


def normaliza(texto: str) -> str:
    base = unicodedata.normalize("NFD", texto.lower().strip())
    return "".join(c for c in base if unicodedata.category(c) != "Mn")


def limpia(entrada: str, salida: str) -> pd.DataFrame:
    df = pd.read_csv(entrada, dtype=str).drop_duplicates()

    precio = df.precio_unitario.str.replace("€", "", regex=False).str.strip()
    con_coma = precio.str.contains(",")
    precio = precio.where(~con_coma, precio.str.replace(".", "", regex=False).str.replace(",", ".", regex=False))
    df["precio"] = pd.to_numeric(precio)

    f = df.fecha.str.strip()
    iso = f.str.match(r"\d{4}-\d{2}-\d{2}")
    fecha = pd.Series(pd.NaT, index=df.index)
    fecha[iso] = pd.to_datetime(f[iso], format="%Y-%m-%d")
    fecha[~iso] = pd.to_datetime(f[~iso].str.replace("-", "/"), format="%d/%m/%Y")
    df["fecha"] = pd.to_datetime(fecha)
    df["mes"] = df.fecha.dt.month

    df["cantidad"] = df.cantidad.astype(int)
    df["descuento_pct"] = pd.to_numeric(df.descuento_pct, errors="coerce").fillna(0).astype(int)
    df["categoria"] = df.categoria.map(lambda s: CATEGORIAS[normaliza(s)])
    df["canal"] = df.canal.str.strip()
    for col in ("ciudad_envio", "metodo_pago"):
        df[col] = df[col].str.strip().replace({"N/D": None, "-": None})

    out = df[["id_pedido", "fecha", "mes", "product_id", "categoria", "cantidad", "precio",
              "descuento_pct", "cliente_id", "canal", "ciudad_envio", "pais", "metodo_pago"]]
    out.to_csv(salida, index=False, date_format="%Y-%m-%d")
    return out


if __name__ == "__main__":
    entrada, salida = sys.argv[1], sys.argv[2]
    limpio = limpia(entrada, salida)
    ingresos = (limpio.cantidad * limpio.precio * (1 - limpio.descuento_pct / 100)).sum()
    print(f"{len(limpio)} filas limpias | ingresos netos: {ingresos:,.2f}")
