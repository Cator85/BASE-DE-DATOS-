import pandas as pd
import random
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.engine import URL # <-- Importamos esta nueva herramienta
import os

# 1. Configuración de conexión segura a la Base de Datos
db_host = "mysql-cator-unab.alwaysdata.net"
db_user = "tu_usuario_creado"
db_pass = "tu_contraseña_creada"
db_name = "cator-unab_turismo"

# Creamos la URL de forma segura (soporta contraseñas con caracteres raros y arrobas)
url_conexion = URL.create(
    drivername="mysql+pymysql",
    username=db_user,
    password=db_pass,
    host=db_host,
    port=3306,
    database=db_name
)

engine = create_engine(url_conexion)
NOMBRES = ["Camila Ruiz", "Pedro Luna", "Elena Torres", "Bruno Soto", "Sara Melo", "Juan Perez", "Diego Rojas", "Maria Gonzalez", "Valentina Silva", "Matias Castro"]
CIUDADES = ["Atacama", "Elqui", "Antofagasta", "Coquimbo", "Santiago", "Valparaiso"]
ESTADOS = ['Operativo', 'Mantenimiento', 'Cerrado Temporalmente']
CERTIFICACIONES = ['Basico', 'Avanzado', 'Clase Mundial']

def poblar_con_pandas():
    print("Iniciando proceso de poblamiento masivo...")

    # Regiones
    df_regiones = pd.DataFrame({
        "codigo": [f"R{i:02d}" for i in range(1, 11)],
        "nombre_oficial": [f"Region de {random.choice(CIUDADES)} {i}" for i in range(1, 11)],
        "superficie_protegida": [round(random.uniform(1000, 50000), 2) for _ in range(10)],
        "presupuesto_destinado": [round(random.uniform(5000000, 50000000), 2) for _ in range(10)]
    })
    df_regiones.to_sql(name='REGION', con=engine, if_exists='append', index=False)
    print("-> 10 regiones insertadas.")

    # Centros astronomicos
    df_centros = pd.DataFrame({
        "codigo_unico": [f"C{i:03d}" for i in range(1, 21)],
        "nombre": [f"Observatorio {random.choice(CIUDADES)} {i}" for i in range(1, 21)],
        "fecha_inauguracion": [date(2000 + random.randint(0, 25), random.randint(1, 12), random.randint(1, 28)) for _ in range(20)],
        "altitud": [random.randint(1500, 4500) for _ in range(20)],
        "capacidad_maxima_diaria": [random.randint(50, 500) for _ in range(20)],
        "presupuesto_anual": [round(random.uniform(1000000, 10000000), 2) for _ in range(20)],
        "estado_operativo": [random.choice(ESTADOS) for _ in range(20)],
        "nivel_certificacion": [random.choice(CERTIFICACIONES) for _ in range(20)],
        "latitud": [round(random.uniform(-30.0, -20.0), 6) for _ in range(20)],
        "longitud": [round(random.uniform(-70.0, -68.0), 6) for _ in range(20)],
        "codigo_region": [random.choice(df_regiones['codigo'].tolist()) for _ in range(20)]
    })
    df_centros.to_sql(name='CENTRO', con=engine, if_exists='append', index=False)
    print("-> 20 centros insertados.")

    # Zonas de observacion
    zonas_data = []
    for centro in df_centros['codigo_unico']:
        for j in range(1, random.randint(3, 5)):
            zonas_data.append({
                "numero_interno": f"Z{j:02d}",
                "codigo_unico_centro": centro,
                "nombre": f"Sector {random.choice(['Norte', 'Sur', 'Este', 'Oeste', 'Cupula'])}",
                "superficie": round(random.uniform(100, 1000), 2),
                "nivel_oscuridad": random.randint(1, 10),
                "capacidad_maxima": random.randint(10, 100),
                "nivel_acceso": random.choice(['Publico', 'Cientifico'])
            })
    df_zonas = pd.DataFrame(zonas_data)
    df_zonas.to_sql(name='ZONA_OBSERVACION', con=engine, if_exists='append', index=False)
    print(f"-> {len(df_zonas)} zonas de observacion insertadas.")

    # Visitantes
    df_visitantes = pd.DataFrame({
        "id_visitante": [f"V{i:04d}" for i in range(1, 301)],
        "nombre": [random.choice(NOMBRES) + " " + random.choice(NOMBRES).split()[0] for _ in range(300)],
        "tipo_origen": [random.choice(["Nacional", "Internacional"]) for _ in range(300)]
    })
    df_visitantes.drop_duplicates(subset=['id_visitante'], inplace=True)
    df_visitantes.to_sql(name='VISITANTE', con=engine, if_exists='append', index=False)
    print("-> 300 visitantes insertados.")

    # Actividades
    actividades_data = []
    for i in range(1, 201):
        zona = random.choice(zonas_data)
        actividades_data.append({
            "codigo": f"ACT{i:04d}",
            "fecha": date.today() + timedelta(days=random.randint(-100, 100)),
            "horario": f"{random.randint(18, 23)}:00:00",
            "modalidad": random.choice(['Guiada', 'Libre', 'Taller']),
            "duracion": random.randint(60, 180),
            "valor": random.choice([5000, 10000, 15000, 25000]),
            "capacidad": random.randint(10, 50),
            "numero_interno_zona": zona['numero_interno'],
            "codigo_unico_centro": zona['codigo_unico_centro']
        })
    df_actividades = pd.DataFrame(actividades_data)
    df_actividades.to_sql(name='ACTIVIDAD', con=engine, if_exists='append', index=False)
    print("-> 200 actividades insertadas.")

    # Reservas
    reservas_data = []
    for _ in range(1000):
        reservas_data.append({
            "id_visitante": random.choice(df_visitantes['id_visitante'].tolist()),
            "codigo_actividad": random.choice(df_actividades['codigo'].tolist()),
            "fecha_reserva": date.today() - timedelta(days=random.randint(1, 60)),
            "estado": random.choice(['Confirmada', 'Asistio', 'Cancelada']),
            "asistencia_efectiva": random.choice([1, 0]),
            "otras_observaciones": "Registro autogenerado"
        })
    df_reservas = pd.DataFrame(reservas_data)
    df_reservas.drop_duplicates(subset=['id_visitante', 'codigo_actividad'], inplace=True)
    df_reservas.to_sql(name='RESERVA', con=engine, if_exists='append', index=False)
    print(f"-> {len(df_reservas)} reservas insertadas (duplicados filtrados).")
    
    print("Proceso finalizado. Base de datos poblada correctamente.")

if __name__ == "__main__":
    poblar_con_pandas()
