import pandas as pd
import random
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# Conexión directa a Alwaysdata
db_host = "mysql-cator.alwaysdata.net"
db_user = "cator_admin"
db_pass = "Pollux5907" 
db_name = "cator_data-base"

url_conexion = URL.create(
    drivername="mysql+pymysql",
    username=db_user,
    password=db_pass,
    host=db_host,
    port=3306,
    database=db_name
)
engine = create_engine(url_conexion)

print("Generando e inyectando fenómenos astronómicos a la nube...")

fenomenos_data = []
fenomenos_solares = []
fenomenos_lunares = []
fenomenos_profundos = []

# Generando 100 fenómenos aleatorios
for i in range(1, 101):
    codigo = f"F{i:03d}"
    tipo = random.choice(["Solar", "Lunar", "Espacio Profundo"])
    
    fenomenos_data.append({
        "codigo_fenomeno": codigo,
        "nombre": f"Fenomeno {codigo}",
        "descripcion": f"Avistamiento clasificado como {tipo}",
        "fecha_primera_observacion": date(2020 + random.randint(0, 5), random.randint(1, 12), random.randint(1, 28)),
        "frecuencia_estimada": random.choice(["Anual", "Mensual", "Unica", "Decenal"]),
        "nivel_interes_cientifico": random.randint(1, 10)
    })
    
    # Separación por jerarquía / subtipos
    if tipo == "Solar":
        fenomenos_solares.append({"codigo_fenomeno": codigo})
    elif tipo == "Lunar":
        fenomenos_lunares.append({"codigo_fenomeno": codigo})
    else:
        fenomenos_profundos.append({"codigo_fenomeno": codigo})

# Subiendo a la base de datos en minúsculas (para evitar errores en Linux)
pd.DataFrame(fenomenos_data).to_sql(name='fenomeno_astronomico', con=engine, if_exists='replace', index=False)
pd.DataFrame(fenomenos_solares).to_sql(name='fenomeno_solar', con=engine, if_exists='replace', index=False)
pd.DataFrame(fenomenos_lunares).to_sql(name='fenomeno_lunar', con=engine, if_exists='replace', index=False)
pd.DataFrame(fenomenos_profundos).to_sql(name='fenomeno_espacio_profundo', con=engine, if_exists='replace', index=False)

print("¡Proceso finalizado! Las 4 tablas de fenómenos fueron creadas en Alwaysdata.")