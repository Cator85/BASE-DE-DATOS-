# Ejecutar en terminal: streamlit run app.py
# Credenciales: usuario "admin" / clave "123" (Administrador) | usuario "guia" / clave "123" (Guia Cientifico)
import streamlit as st
import pandas as pd
import plotly.express as px
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from datetime import date
import os

st.set_page_config(page_title="Sistema de Turismo Astronomico", layout="wide")

@st.cache_resource
def get_engine():
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
    return create_engine(url_conexion)

engine = get_engine()

# Control de acceso con dos roles diferenciados
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

    # Filtros generales: Centro Astronomico y Periodo (Seccion 10.1)
    df_lista_centros = pd.read_sql("SELECT codigo_unico, nombre FROM CENTRO ORDER BY nombre", engine)
    opciones_centros = ["Todos los centros"] + df_lista_centros['nombre'].tolist()

    df_fechas = pd.read_sql("SELECT MIN(fecha) AS min_f, MAX(fecha) AS max_f FROM ACTIVIDAD", engine)
    fecha_min_bd = df_fechas['min_f'].iloc[0] or date(2024, 1, 1)
    fecha_max_bd = df_fechas['max_f'].iloc[0] or date.today()

    f_col1, f_col2, f_col3 = st.columns([2, 1, 1])
    with f_col1:
        centro_sel = st.selectbox("Filtrar analisis por Centro Astronomico:", opciones_centros)
    with f_col2:
        fecha_inicio = st.date_input("Fecha inicio (Periodo):", value=fecha_min_bd)
    with f_col3:
        fecha_fin = st.date_input("Fecha termino (Periodo):", value=fecha_max_bd)

    filtro_centro_sql = ""
    params_p1 = {"f_ini": fecha_inicio, "f_fin": fecha_fin}
    if centro_sel != "Todos los centros":
        filtro_centro_sql = "AND c.nombre = :centro"
        params_p1["centro"] = centro_sel

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("1. Zonas de Observacion con Mayor Visita")
        query_p1 = text(f"""
            SELECT z.nombre AS Zona, c.nombre AS Centro, COUNT(r.id_visitante) AS Visitantes
            FROM RESERVA r
            JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
            JOIN ZONA_OBSERVACION z ON a.numero_interno_zona = z.numero_interno AND a.codigo_unico_centro = z.codigo_unico_centro
            JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
            WHERE r.asistencia_efectiva = 1
              AND a.fecha BETWEEN :f_ini AND :f_fin
              {filtro_centro_sql}
            GROUP BY z.numero_interno, z.codigo_unico_centro, z.nombre, c.nombre
            ORDER BY Visitantes DESC LIMIT 10
        """)
        df_p1 = pd.read_sql(query_p1, engine, params=params_p1)
        fig1 = px.bar(df_p1, x="Zona", y="Visitantes", color="Centro")
        st.plotly_chart(fig1, use_container_width=True)

    with col2:
        st.subheader("2. Proporcion de Fenomenos Clasificados")

        # Filtro de zona dependiente del centro seleccionado (Seccion 10.1)
        if centro_sel != "Todos los centros":
            df_zonas = pd.read_sql(
                text("""
                    SELECT DISTINCT z.nombre
                    FROM ZONA_OBSERVACION z
                    JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
                    WHERE c.nombre = :centro
                    ORDER BY z.nombre
                """),
                engine,
                params={"centro": centro_sel}
            )
        else:
            df_zonas = pd.read_sql("SELECT DISTINCT nombre FROM ZONA_OBSERVACION ORDER BY nombre", engine)

        zona_sel = st.selectbox("Filtrar fenomenos por Zona:", ["Todas las zonas"] + df_zonas['nombre'].tolist())

        filtros_p2 = []
        params_p2 = {}
        if centro_sel != "Todos los centros":
            filtros_p2.append("c.nombre = :centro")
            params_p2["centro"] = centro_sel
        if zona_sel != "Todas las zonas":
            filtros_p2.append("z.nombre = :zona")
            params_p2["zona"] = zona_sel

        where_p2 = ("WHERE " + " AND ".join(filtros_p2)) if filtros_p2 else ""

        tablas_bd = set(pd.read_sql("SHOW TABLES", engine).iloc[:, 0].tolist())
        tabla_reg = "registro_fenomeno" if "registro_fenomeno" in tablas_bd else "REGISTRO_FENOMENO"

        query_p2 = text(f"""
            SELECT 'Solar' AS Tipo, COUNT(DISTINCT fs.codigo_fenomeno) AS Cantidad
            FROM fenomeno_solar fs
            JOIN {tabla_reg} rf ON fs.codigo_fenomeno = rf.codigo_fenomeno
            JOIN ZONA_OBSERVACION z ON rf.numero_interno_zona = z.numero_interno AND rf.codigo_unico_centro = z.codigo_unico_centro
            JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
            {where_p2}
            UNION ALL
            SELECT 'Lunar', COUNT(DISTINCT fl.codigo_fenomeno)
            FROM fenomeno_lunar fl
            JOIN {tabla_reg} rf ON fl.codigo_fenomeno = rf.codigo_fenomeno
            JOIN ZONA_OBSERVACION z ON rf.numero_interno_zona = z.numero_interno AND rf.codigo_unico_centro = z.codigo_unico_centro
            JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
            {where_p2}
            UNION ALL
            SELECT 'Espacio Profundo', COUNT(DISTINCT fep.codigo_fenomeno)
            FROM fenomeno_espacio_profundo fep
            JOIN {tabla_reg} rf ON fep.codigo_fenomeno = rf.codigo_fenomeno
            JOIN ZONA_OBSERVACION z ON rf.numero_interno_zona = z.numero_interno AND rf.codigo_unico_centro = z.codigo_unico_centro
            JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
            {where_p2}
        """)
        df_p2 = pd.read_sql(query_p2, engine, params=params_p2)
        fig2 = px.pie(df_p2, names='Tipo', values='Cantidad', hole=0.4)
        st.plotly_chart(fig2, use_container_width=True)

    st.markdown("---")
    st.subheader("3. Relacion entre Asistentes y Evaluacion Promedio por Actividad")
    try:
        where_p3 = "WHERE c.nombre = :centro" if centro_sel != "Todos los centros" else ""
        params_p3 = {"centro": centro_sel} if centro_sel != "Todos los centros" else {}
        query_p3_disp = text(f"""
            SELECT a.codigo AS Actividad, c.nombre AS Centro, z.nombre AS Zona,
                   COUNT(DISTINCT r.id_visitante) AS Asistentes,
                   ROUND(AVG(e.calificacion), 2) AS Evaluacion_Promedio
            FROM ACTIVIDAD a
            JOIN ZONA_OBSERVACION z ON a.numero_interno_zona = z.numero_interno AND a.codigo_unico_centro = z.codigo_unico_centro
            JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
            LEFT JOIN RESERVA r ON a.codigo = r.codigo_actividad AND r.asistencia_efectiva = 1
            LEFT JOIN EVALUACION e ON a.codigo = e.codigo_actividad
            {where_p3}
            GROUP BY a.codigo, c.nombre, z.nombre
        """)
        df_disp = pd.read_sql(query_p3_disp, engine, params=params_p3)
        df_disp_validos = df_disp.dropna(subset=['Evaluacion_Promedio'])

        if not df_disp_validos.empty:
            fig_disp = px.scatter(
                df_disp_validos,
                x="Asistentes",
                y="Evaluacion_Promedio",
                color="Centro",
                hover_data=["Actividad", "Zona"],
                title="Dispersion: Cantidad de Asistentes vs. Calificacion Promedio"
            )
            st.plotly_chart(fig_disp, use_container_width=True)
        else:
            st.info("Aun no hay registros en la tabla EVALUACION para graficar la dispersion.")

        with st.expander("Ver tabla de detalle por actividad, centro y zona"):
            st.dataframe(df_disp, use_container_width=True)
    except Exception as e:
        st.warning(f"No se pudo cargar la tabla EVALUACION: {e}")

    st.markdown("---")
    st.subheader("4. Ingresos Generados por Centro (Indicador Propuesto)")
    st.write("Justificacion: Facilita la identificacion de instalaciones rentables para asignacion presupuestaria y priorizacion de inversion.")

    criterio_orden = st.selectbox(
        "Ordenar ingresos por:",
        ["Mayor a Menor (Descendente)", "Menor a Mayor (Ascendente)", "Alfabetico por Nombre de Centro"]
    )

    if criterio_orden == "Mayor a Menor (Descendente)":
        orden_sql = "ORDER BY Ingresos_Totales DESC"
    elif criterio_orden == "Menor a Mayor (Ascendente)":
        orden_sql = "ORDER BY Ingresos_Totales ASC"
    else:
        orden_sql = "ORDER BY c.nombre ASC"

    params_p4 = {"centro": centro_sel} if centro_sel != "Todos los centros" else {}
    query_p4 = text(f"""
        SELECT c.nombre AS Centro, SUM(a.valor) AS Ingresos_Totales
        FROM RESERVA r
        JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
        JOIN CENTRO c ON a.codigo_unico_centro = c.codigo_unico
        WHERE r.asistencia_efectiva = 1 {filtro_centro_sql}
        GROUP BY c.codigo_unico, c.nombre
        {orden_sql}
    """)
    df_p4 = pd.read_sql(query_p4, engine, params=params_p4)
    fig4 = px.bar(df_p4, x="Ingresos_Totales", y="Centro", orientation='h')
    st.plotly_chart(fig4, use_container_width=True)

def mostrar_crud():
    st.title("Gestion de Tablas Maestras (CRUD)")
    tab1, tab2 = st.tabs(["Centros Astronomicos", "Fenomenos Astronomicos"])

    # --- CRUD 1: CENTRO ---
    with tab1:
        st.subheader("Registros Actuales de Centros")
        df_centros = pd.read_sql(
            "SELECT codigo_unico, nombre, codigo_region, estado_operativo, capacidad_maxima_diaria FROM CENTRO",
            engine
        )
        st.dataframe(df_centros, use_container_width=True)

        col1, col2, col3 = st.columns(3)

        with col1:
            st.subheader("Crear Centro")
            with st.form("form_crear_centro"):
                cod = st.text_input("Codigo Unico (Ej: C999)")
                nombre = st.text_input("Nombre del Centro")
                region = st.text_input("Codigo Region (Ej: R01)")
                capacidad = st.number_input("Capacidad Diaria", min_value=10, max_value=1000, value=100)

                if st.form_submit_button("Guardar Registro"):
                    try:
                        with engine.begin() as conn:
                            conn.execute(text("""
                                INSERT INTO CENTRO (codigo_unico, nombre, codigo_region, estado_operativo, capacidad_maxima_diaria)
                                VALUES (:c, :n, :r, 'Operativo', :cap)
                            """), {"c": cod, "n": nombre, "r": region, "cap": capacidad})
                        st.success("Centro registrado.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Error de insercion: {e}")

        with col2:
            st.subheader("Modificar / Desactivar")
            with st.form("form_modificar_centro"):
                cod_mod = st.selectbox("Seleccionar centro", df_centros['codigo_unico'].tolist())
                nuevo_estado = st.selectbox("Nuevo Estado (Desactivacion logica)", ["Operativo", "Mantenimiento", "Cerrado Definitivo"])

                if st.form_submit_button("Aplicar Cambios"):
                    with engine.begin() as conn:
                        conn.execute(
                            text("UPDATE CENTRO SET estado_operativo = :est WHERE codigo_unico = :c"),
                            {"est": nuevo_estado, "c": cod_mod}
                        )
                    st.success("Estado actualizado.")
                    st.rerun()

        with col3:
            st.subheader("Eliminar Centro")
            with st.form("form_eliminar_centro"):
                cod_del = st.selectbox("Centro a eliminar", df_centros['codigo_unico'].tolist(), key="del_centro")
                if st.form_submit_button("Eliminar Registro"):
                    try:
                        with engine.begin() as conn:
                            conn.execute(text("DELETE FROM CENTRO WHERE codigo_unico = :c"), {"c": cod_del})
                        st.success("Centro eliminado.")
                        st.rerun()
                    except Exception:
                        st.warning("No se puede eliminar fisicamente porque tiene zonas asociadas. Use 'Cerrado Definitivo' para desactivacion logica.")

    # --- CRUD 2: FENOMENO ASTRONOMICO ---
    with tab2:
        st.subheader("Registros Actuales de Fenomenos Astronomicos")
        df_fen = pd.read_sql("SELECT * FROM fenomeno_astronomico", engine)
        st.dataframe(df_fen, use_container_width=True)

        f_col1, f_col2, f_col3 = st.columns(3)

        with f_col1:
            st.subheader("Crear Fenomeno")
            with st.form("form_crear_fenomeno"):
                f_cod = st.text_input("Codigo (Ej: F999)")
                f_nom = st.text_input("Nombre del Fenomeno")
                f_desc = st.text_input("Descripcion")
                f_fecha = st.date_input("Primera Observacion", value=date.today())
                f_frec = st.selectbox("Frecuencia Estimada", ["Anual", "Mensual", "Unica", "Decenal"])
                f_int = st.slider("Nivel Interes Cientifico", 1, 10, 5)
                f_tipo = st.selectbox("Clasificacion", ["Solar", "Lunar", "Espacio Profundo"])

                if st.form_submit_button("Guardar Fenomeno"):
                    try:
                        with engine.begin() as conn:
                            conn.execute(text("""
                                INSERT INTO fenomeno_astronomico
                                (codigo_fenomeno, nombre, descripcion, fecha_primera_observacion, frecuencia_estimada, nivel_interes_cientifico)
                                VALUES (:c, :n, :d, :f, :fr, :ni)
                            """), {"c": f_cod, "n": f_nom, "d": f_desc, "f": f_fecha, "fr": f_frec, "ni": f_int})

                            tabla_sub = {
                                "Solar": "fenomeno_solar",
                                "Lunar": "fenomeno_lunar",
                                "Espacio Profundo": "fenomeno_espacio_profundo"
                            }[f_tipo]
                            conn.execute(text(f"INSERT INTO {tabla_sub} (codigo_fenomeno) VALUES (:c)"), {"c": f_cod})
                        st.success("Fenomeno creado y clasificado.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Error al crear fenomeno: {e}")

        with f_col2:
            st.subheader("Modificar Fenomeno")
            if not df_fen.empty:
                with st.form("form_modificar_fenomeno"):
                    f_cod_mod = st.selectbox("Seleccionar fenomeno", df_fen['codigo_fenomeno'].tolist())
                    f_frec_mod = st.selectbox("Nueva Frecuencia", ["Anual", "Mensual", "Unica", "Decenal"])
                    f_int_mod = st.slider("Nuevo Nivel Interes", 1, 10, 7)

                    if st.form_submit_button("Actualizar Fenomeno"):
                        with engine.begin() as conn:
                            conn.execute(text("""
                                UPDATE fenomeno_astronomico
                                SET frecuencia_estimada = :fr, nivel_interes_cientifico = :ni
                                WHERE codigo_fenomeno = :c
                            """), {"fr": f_frec_mod, "ni": f_int_mod, "c": f_cod_mod})
                        st.success("Fenomeno actualizado.")
                        st.rerun()

        with f_col3:
            st.subheader("Eliminar Fenomeno")
            if not df_fen.empty:
                with st.form("form_eliminar_fenomeno"):
                    f_cod_del = st.selectbox("Fenomeno a eliminar", df_fen['codigo_fenomeno'].tolist(), key="del_fen")
                    if st.form_submit_button("Eliminar Fenomeno"):
                        try:
                            with engine.begin() as conn:
                                for sub in ["fenomeno_solar", "fenomeno_lunar", "fenomeno_espacio_profundo"]:
                                    conn.execute(text(f"DELETE FROM {sub} WHERE codigo_fenomeno = :c"), {"c": f_cod_del})
                                conn.execute(text("DELETE FROM fenomeno_astronomico WHERE codigo_fenomeno = :c"), {"c": f_cod_del})
                            st.success("Fenomeno eliminado.")
                            st.rerun()
                        except Exception:
                            st.warning("No se puede eliminar porque esta asociado a registros de observacion en zonas.")

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

    opciones = ["Dashboard Analitico", "Gestion de Maestros (CRUD)", "Ingreso de Reservas"]

    if st.session_state['rol'] == "Guia Cientifico":
        opciones.remove("Gestion de Maestros (CRUD)")

    seleccion = st.sidebar.radio("Modulos", opciones)

    if seleccion == "Dashboard Analitico":
        mostrar_dashboard()
    elif seleccion == "Gestion de Maestros (CRUD)":
        mostrar_crud()
    elif seleccion == "Ingreso de Reservas":
        mostrar_formulario_reserva()
