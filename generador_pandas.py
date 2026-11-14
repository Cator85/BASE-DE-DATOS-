import pandas as pd
import random
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
import os

# 1. Configuracion de conexion (compatible con Alwaysdata y Docker)
db_host = os.environ.get("DB_HOST", "mysql-cator.alwaysdata.net")
db_user = os.environ.get("DB_USER", "cator_admin")
db_pass = os.environ.get("DB_PASS", "Pollux5907")
db_name = os.environ.get("DB_NAME", "cator_data-base")

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
ROLES_PERSONAL = ['Administrativo', 'Guia Cientifico', 'Tecnico', 'Investigador']

def poblar_con_pandas():
    print("Iniciando proceso de poblamiento masivo...")

    # 1. Regiones (10 registros - Rango pauta: 5 a 10)
    df_regiones = pd.DataFrame({
        "codigo": [f"R{i:02d}" for i in range(1, 11)],
        "nombre_oficial": [f"Region de {random.choice(CIUDADES)} {i}" for i in range(1, 11)],
        "superficie_protegida": [round(random.uniform(1000, 50000), 2) for _ in range(10)],
        "presupuesto_destinado": [round(random.uniform(5000000, 50000000), 2) for _ in range(10)]
    })
    df_regiones.to_sql(name='REGION', con=engine, if_exists='append', index=False)
    print("-> 10 regiones insertadas.")

    # 2. Centros astronomicos (20 registros - Rango pauta: 12 a 20)
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

    # 3. Zonas de observacion (60 registros - Rango pauta: 35 a 60)
    zonas_data = []
    for centro in df_centros['codigo_unico']:
        for j in range(1, 4):
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

    # 4. Personal (50 registros - Rango pauta: 40 a 80)
    df_personal = pd.DataFrame({
        "cuentas_usuario": [f"staff_{i:02d}@observatorio.cl" for i in range(1, 51)],
        "rol": [random.choice(ROLES_PERSONAL) for _ in range(50)]
    })
    df_personal.to_sql(name='PERSONAL', con=engine, if_exists='append', index=False)
    print("-> 50 registros de personal insertados.")

    # 5. Registro zona-fenomeno (350 registros - Rango pauta: 250 a 500)
    codigos_fen = pd.read_sql("SELECT codigo_fenomeno FROM fenomeno_astronomico", engine)['codigo_fenomeno'].tolist()
    if codigos_fen:
        reg_fen_data = []
        for _ in range(400):
            zona = random.choice(zonas_data)
            reg_fen_data.append({
                "codigo_fenomeno": random.choice(codigos_fen),
                "numero_interno_zona": zona['numero_interno'],
                "codigo_unico_centro": zona['codigo_unico_centro']
            })
        df_reg_fen = pd.DataFrame(reg_fen_data).drop_duplicates()
        df_reg_fen.to_sql(name='REGISTRO_FENOMENO', con=engine, if_exists='append', index=False)
        print(f"-> {len(df_reg_fen)} registros zona-fenomeno insertados.")

    # 6. Visitantes (300 registros - Rango pauta: 150 a 300)
    df_visitantes = pd.DataFrame({
        "id_visitante": [f"V{i:04d}" for i in range(1, 301)],
        "nombre": [random.choice(NOMBRES) + " " + random.choice(NOMBRES).split()[0] for _ in range(300)],
        "tipo_origen": [random.choice(["Nacional", "Internacional"]) for _ in range(300)]
    })
    df_visitantes.drop_duplicates(subset=['id_visitante'], inplace=True)
    df_visitantes.to_sql(name='VISITANTE', con=engine, if_exists='append', index=False)
    print("-> 300 visitantes insertados.")

    # 7. Actividades (200 registros - Rango pauta: 120 a 250)
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

    # 8. Reservas (Rango pauta: 800 a 1500)
    reservas_data = []
    for _ in range(1100):
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

    # 9. Evaluaciones (600 registros - Rango pauta: 400 a 900)
    evaluaciones_data = []
    contador_eval = {}
    for _ in range(600):
        act = random.choice(df_actividades['codigo'].tolist())
        contador_eval[act] = contador_eval.get(act, 0) + 1
        evaluaciones_data.append({
            "numero_correlativo": contador_eval[act],
            "codigo_actividad": act,
            "calificacion": random.randint(1, 5),
            "fecha": date.today() - timedelta(days=random.randint(1, 60)),
            "comentario": "Evaluacion generada automaticamente"
        })
    df_evaluaciones = pd.DataFrame(evaluaciones_data)
    df_evaluaciones.to_sql(name='EVALUACION', con=engine, if_exists='append', index=False)
    print("-> 600 evaluaciones insertadas.")

    print("Proceso finalizado. Base de datos poblada correctamente.")

if __name__ == "__main__":
    poblar_con_pandas()
