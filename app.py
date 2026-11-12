# copia y pega esto para inciar el codigo: & "C:\Users\gator\AppData\Roaming\Python\Python314\scripts\streamlit.exe" run "c:/Users/gator/OneDrive/Documents/VScode/base de datos/app.py"
#el nombre para logearte en la aplicacion es "admin" y la contraseña es "123", para el guia cientifico es "guia" y la contraseña es "123"
import streamlit as st
import pandas as pd
import plotly.express as px
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
import os

st.set_page_config(page_title="Sistema de Turismo Astronomico", layout="wide")

@st.cache_resource
def get_engine():
    db_host = os.environ.get("DB_HOST", "mysql-cator.alwaysdata.net")
    db_user = os.environ.get("DB_USER", "cator_admin")
    db_pass = os.environ.get("DB_PASS", "Pollux5907") 
    db_name = os.environ.get("DB_NAME", "cator_data-base")
    
    # Creamos la URL de manera limpia y estructurada para evitar errores de sintaxis
    url_conexion = URL.create(
        drivername="mysql+pymysql",
        username=db_user,
        password=db_pass,
        host=db_host,
        port=3306,
        database=db_name
    )
    return create_engine(url_conexion)

engine = get_engine()
# Control de acceso
USUARIOS = {
    "admin": {"password": "123", "rol": "Administrador"},
    "guia": {"password": "123", "rol": "Guia Cientifico"}
}

if 'usuario_actual' not in st.session_state:
    st.session_state['usuario_actual'] = None
    st.session_state['rol'] = None

def login():
    st.title("Sistema de Turismo Astronomico")
    st.subheader("Acceso al sistema")
    
    with st.form("login_form"):
        user = st.text_input("Usuario")
        password = st.text_input("Contrasena", type="password")
        submit = st.form_submit_button("Ingresar")
        
        if submit:
            if user in USUARIOS and USUARIOS[user]["password"] == password:
                st.session_state['usuario_actual'] = user
                st.session_state['rol'] = USUARIOS[user]["rol"]
                st.success("Autenticacion exitosa. Cargando entorno...")
                st.rerun()
            else:
                st.error("Credenciales invalidas.")

def logout():
    st.session_state['usuario_actual'] = None
    st.session_state['rol'] = None
    st.rerun()

def mostrar_dashboard():
    st.title("Dashboard de Indicadores")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("1. Zonas de Observacion con Mayor Visita")
        query_p1 = """
            SELECT z.nombre AS Zona, c.nombre AS Centro, COUNT(r.id_visitante) AS Visitantes
            FROM RESERVA r
            JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
            JOIN ZONA_OBSERVACION z ON a.numero_interno_zona = z.numero_interno AND a.codigo_unico_centro = z.codigo_unico_centro
            JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
            WHERE r.asistencia_efectiva = 1
            GROUP BY z.numero_interno, z.codigo_unico_centro, z.nombre, c.nombre
            ORDER BY Visitantes DESC LIMIT 10
        """
        df_p1 = pd.read_sql(query_p1, engine)
        fig1 = px.bar(df_p1, x="Zona", y="Visitantes", color="Centro")
        st.plotly_chart(fig1, use_container_width=True)

with col2:
        st.subheader("2. Proporcion de Fenomenos Clasificados")
        # Aquí reemplazas el query para que las tablas estén en minúsculas:
        query_p2 = """
            SELECT 'Solar' AS Tipo, COUNT(*) AS Cantidad FROM fenomeno_solar
            UNION ALL
            SELECT 'Lunar', COUNT(*) FROM fenomeno_lunar
            UNION ALL
            SELECT 'Espacio Profundo', COUNT(*) FROM fenomeno_espacio_profundo
        """
        df_p2 = pd.read_sql(query_p2, engine)
        fig2 = px.pie(df_p2, names='Tipo', values='Cantidad', hole=0.4)
        st.plotly_chart(fig2, use_container_width=True)

    st.subheader("3. Ingresos Generados por Centro")
    st.write("Justificacion: Facilita la identificacion de instalaciones rentables para asignacion presupuestaria.")
    
    # Selector interactivo de ordenamiento
    criterio_orden = st.selectbox(
        "Ordenar ingresos por:",
        ["Mayor a Menor (Descendente)", "Menor a Mayor (Ascendente)", "Alfabético por Nombre de Centro"]
    )
    
    # Definimos la cláusula ORDER BY según la elección del usuario
    if criterio_orden == "Mayor a Menor (Descendente)":
        orden_sql = "ORDER BY Ingresos_Totales DESC"
    elif criterio_orden == "Menor a Mayor (Ascendente)":
        orden_sql = "ORDER BY Ingresos_Totales ASC"
    else:
        orden_sql = "ORDER BY c.nombre ASC"

    query_p3 = f"""
        SELECT c.nombre AS Centro, SUM(a.valor) AS Ingresos_Totales
        FROM RESERVA r
        JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
        JOIN CENTRO c ON a.codigo_unico_centro = c.codigo_unico
        WHERE r.asistencia_efectiva = 1
        GROUP BY c.codigo_unico, c.nombre
        {orden_sql}
    """
    df_p3 = pd.read_sql(query_p3, engine)
    
    # Si se ordenó alfabéticamente, orientamos de forma distinta o dejamos barras horizontales
    fig3 = px.bar(df_p3, x="Ingresos_Totales", y="Centro", orientation='h')
    st.plotly_chart(fig3, use_container_width=True)

def mostrar_crud():
    st.title("Gestion de Centros Astronomicos")
    
    st.subheader("Registros Actuales")
    df_centros = pd.read_sql("SELECT codigo_unico, nombre, codigo_region, estado_operativo, capacidad_maxima_diaria FROM CENTRO", engine)
    st.dataframe(df_centros, use_container_width=True)
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Registro de Nuevo Centro")
        with st.form("form_crear_centro"):
            cod = st.text_input("Codigo Unico (Ej: C999)")
            nombre = st.text_input("Nombre del Centro")
            region = st.text_input("Codigo Region (Ej: R01)")
            capacidad = st.number_input("Capacidad Diaria", min_value=10, max_value=1000)
            
            if st.form_submit_button("Guardar Registro"):
                try:
                    with engine.begin() as conn:
                        conn.execute(text("""
                            INSERT INTO CENTRO (codigo_unico, nombre, codigo_region, estado_operativo, capacidad_maxima_diaria)
                            VALUES (:c, :n, :r, 'Operativo', :cap)
                        """), {"c": cod, "n": nombre, "r": region, "cap": capacidad})
                    st.success("Registro completado.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Error de insercion: {e}")

    with col2:
        st.subheader("Modificar Estado Operativo")
        with st.form("form_modificar_centro"):
            cod_mod = st.selectbox("Seleccionar registro", df_centros['codigo_unico'].tolist())
            nuevo_estado = st.selectbox("Nuevo Estado", ["Operativo", "Mantenimiento", "Cerrado Definitivo"])
            
            if st.form_submit_button("Aplicar Cambios"):
                with engine.begin() as conn:
                    conn.execute(text("UPDATE CENTRO SET estado_operativo = :est WHERE codigo_unico = :c"), 
                                 {"est": nuevo_estado, "c": cod_mod})
                st.success("Actualizacion aplicada.")
                st.rerun()

def mostrar_formulario_reserva():
    st.title("Registro de Reserva Transaccional")
    
    df_visitantes = pd.read_sql("SELECT id_visitante, nombre FROM VISITANTE", engine)
    df_actividades = pd.read_sql("SELECT codigo, fecha, modalidad FROM ACTIVIDAD ORDER BY fecha DESC", engine)
    
    opciones_v = df_visitantes['id_visitante'] + " - " + df_visitantes['nombre']
    opciones_a = df_actividades['codigo'] + " (" + df_actividades['fecha'].astype(str) + " - " + df_actividades['modalidad'] + ")"
    
    with st.form("form_reserva_transaccional"):
        sel_visitante = st.selectbox("Visitante asociado", opciones_v)
        sel_actividad = st.selectbox("Actividad requerida", opciones_a)
        fecha_res = st.date_input("Fecha de emision")
        estado_res = st.selectbox("Estado de reserva", ["Confirmada", "Pendiente", "Pagada"])
        
        if st.form_submit_button("Procesar Transaccion"):
            id_v = sel_visitante.split(" - ")[0]
            id_a = sel_actividad.split(" ")[0]
            
            try:
                with engine.begin() as conn:
                    conn.execute(text("""
                        INSERT INTO RESERVA (id_visitante, codigo_actividad, fecha_reserva, estado, asistencia_efectiva)
                        VALUES (:vi, :ac, :fr, :es, 0)
                    """), {"vi": id_v, "ac": id_a, "fr": fecha_res, "es": estado_res})
                st.success("Transaccion procesada correctamente.")
            except Exception as e:
                st.error(f"Error de integridad referencial o duplicidad: {e}")

# Flujo principal
if st.session_state['usuario_actual'] is None:
    login()
else:
    st.sidebar.title("Menu de Navegacion")
    st.sidebar.write(f"Usuario autenticado: {st.session_state['usuario_actual']}")
    st.sidebar.write(f"Rol asignado: {st.session_state['rol']}")
    st.sidebar.button("Cerrar Sesion", on_click=logout)
    st.sidebar.markdown("---")
    
    opciones = ["Dashboard Analitico", "Gestion de Centros", "Ingreso de Reservas"]
    
    if st.session_state['rol'] == "Guia Cientifico":
        opciones.remove("Gestion de Centros")
        
    seleccion = st.sidebar.radio("Modulos", opciones)
    
    if seleccion == "Dashboard Analitico":
        mostrar_dashboard()
    elif seleccion == "Gestion de Centros":
        mostrar_crud()
    elif seleccion == "Ingreso de Reservas":
        mostrar_formulario_reserva()
