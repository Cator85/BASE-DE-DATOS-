-- ==============================================================================
-- PROYECTO: Sistema Integral de Gestión de Centros de Turismo Astronómico
-- HITO 1: Creación de BD y Tablas (DDL)
-- ==============================================================================

DROP DATABASE IF EXISTS turismo_astronomico;
CREATE DATABASE turismo_astronomico;
USE turismo_astronomico;

-- 1. TABLAS MAESTRAS INDEPENDIENTES
CREATE TABLE REGION (
    codigo VARCHAR(10) PRIMARY KEY,
    nombre_oficial VARCHAR(100) NOT NULL,
    superficie_protegida DECIMAL(10,2),
    presupuesto_destinado DECIMAL(15,2),
    otros_antecedentes TEXT
);

CREATE TABLE FENOMENO_ASTRONOMICO (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_primera_observacion DATE,
    frecuencia_estimada VARCHAR(50),
    nivel_interes_cientifico VARCHAR(20)
);

CREATE TABLE VISITANTE (
    id_visitante VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_origen VARCHAR(30)
);

CREATE TABLE PERSONAL (
    cuentas_usuario VARCHAR(50) PRIMARY KEY,
    rol VARCHAR(50) NOT NULL
);

-- 2. JERARQUÍA DE FENÓMENOS (Subtipos)
CREATE TABLE FENOMENO_SOLAR (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    CONSTRAINT fk_fen_solar FOREIGN KEY (codigo_fenomeno) REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
);

CREATE TABLE FENOMENO_LUNAR (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    CONSTRAINT fk_fen_lunar FOREIGN KEY (codigo_fenomeno) REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
);

CREATE TABLE FENOMENO_ESPACIO_PROFUNDO (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    CONSTRAINT fk_fen_espacio FOREIGN KEY (codigo_fenomeno) REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
);

-- 3. TABLA CENTRO (Depende de Región)
CREATE TABLE CENTRO (
    codigo_unico VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_inauguracion DATE,
    altitud INT,
    capacidad_maxima_diaria INT,
    presupuesto_anual DECIMAL(15,2),
    estado_operativo VARCHAR(30),
    nivel_certificacion VARCHAR(50),
    latitud DECIMAL(10,6),
    longitud DECIMAL(10,6),
    codigo_region VARCHAR(10) NOT NULL,
    CONSTRAINT fk_centro_region FOREIGN KEY (codigo_region) REFERENCES REGION(codigo)
);

-- 4. ENTIDADES DÉBILES Y TABLAS DE ROMPIMIENTO (Dependen de Centro)
CREATE TABLE ZONA_OBSERVACION (
    numero_interno VARCHAR(10),
    codigo_unico_centro VARCHAR(10),
    nombre VARCHAR(100) NOT NULL,
    superficie DECIMAL(10,2),
    nivel_oscuridad INT,
    capacidad_maxima INT,
    nivel_acceso VARCHAR(30),
    PRIMARY KEY (numero_interno, codigo_unico_centro),
    CONSTRAINT fk_zona_centro FOREIGN KEY (codigo_unico_centro) REFERENCES CENTRO(codigo_unico)
);

CREATE TABLE EQUIPAMIENTO_ZONA (
    equipamiento VARCHAR(100),
    numero_interno_zona VARCHAR(10),
    codigo_unico_centro VARCHAR(10),
    PRIMARY KEY (equipamiento, numero_interno_zona, codigo_unico_centro),
    CONSTRAINT fk_equip_zona FOREIGN KEY (numero_interno_zona, codigo_unico_centro) 
        REFERENCES ZONA_OBSERVACION(numero_interno, codigo_unico_centro)
);

CREATE TABLE REGISTRO_FENOMENO (
    codigo_fenomeno VARCHAR(15),
    numero_interno_zona VARCHAR(10),
    codigo_unico_centro VARCHAR(10),
    PRIMARY KEY (codigo_fenomeno, numero_interno_zona, codigo_unico_centro),
    CONSTRAINT fk_reg_fenomeno FOREIGN KEY (codigo_fenomeno) REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno),
    CONSTRAINT fk_reg_zona FOREIGN KEY (numero_interno_zona, codigo_unico_centro) 
        REFERENCES ZONA_OBSERVACION(numero_interno, codigo_unico_centro)
);

-- 5. ACTIVIDADES, EVALUACIONES Y RESERVAS
CREATE TABLE ACTIVIDAD (
    codigo VARCHAR(15) PRIMARY KEY,
    fecha DATE NOT NULL,
    horario TIME NOT NULL,
    modalidad VARCHAR(50),
    duracion INT,
    valor DECIMAL(10,2),
    capacidad INT,
    numero_interno_zona VARCHAR(10) NOT NULL,
    codigo_unico_centro VARCHAR(10) NOT NULL,
    CONSTRAINT fk_actividad_zona FOREIGN KEY (numero_interno_zona, codigo_unico_centro) 
        REFERENCES ZONA_OBSERVACION(numero_interno, codigo_unico_centro)
);

CREATE TABLE EVALUACION (
    numero_correlativo INT,
    codigo_actividad VARCHAR(15),
    calificacion INT,
    fecha DATE,
    comentario TEXT,
    PRIMARY KEY (numero_correlativo, codigo_actividad),
    CONSTRAINT fk_evaluacion_actividad FOREIGN KEY (codigo_actividad) REFERENCES ACTIVIDAD(codigo)
);

CREATE TABLE RESERVA (
    id_visitante VARCHAR(15),
    codigo_actividad VARCHAR(15),
    fecha_reserva DATE NOT NULL,
    estado VARCHAR(30),
    asistencia_efectiva INT,
    otras_observaciones TEXT,
    PRIMARY KEY (id_visitante, codigo_actividad),
    CONSTRAINT fk_reserva_visitante FOREIGN KEY (id_visitante) REFERENCES VISITANTE(id_visitante),
    CONSTRAINT fk_reserva_actividad FOREIGN KEY (codigo_actividad) REFERENCES ACTIVIDAD(codigo)
);



USE turismo_astronomico;

DELIMITER $$
CREATE PROCEDURE sp_zonas_mayor_visita(IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT c.nombre AS centro, z.nombre AS zona, 
           COUNT(r.id_visitante) AS total_visitantes_efectivos
    FROM CENTRO c
    JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
    JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
    JOIN RESERVA r ON a.codigo = r.codigo_actividad
    WHERE a.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND r.asistencia_efectiva = 1
    GROUP BY c.codigo_unico, z.numero_interno
    ORDER BY total_visitantes_efectivos DESC;
END$$
DELIMITER ;

CREATE VIEW vw_distribucion_fenomenos AS
SELECT c.nombre AS centro, z.nombre AS zona, 
       CASE 
           WHEN fs.codigo_fenomeno IS NOT NULL THEN 'Solar'
           WHEN fl.codigo_fenomeno IS NOT NULL THEN 'Lunar'
           WHEN fep.codigo_fenomeno IS NOT NULL THEN 'Espacio Profundo'
           ELSE 'No Clasificado'
       END AS tipo_fenomeno,
       COUNT(rf.codigo_fenomeno) AS cantidad_registrada
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN REGISTRO_FENOMENO rf ON z.numero_interno = rf.numero_interno_zona AND z.codigo_unico_centro = rf.codigo_unico_centro
JOIN FENOMENO_ASTRONOMICO fa ON rf.codigo_fenomeno = fa.codigo_fenomeno
LEFT JOIN FENOMENO_SOLAR fs ON fa.codigo_fenomeno = fs.codigo_fenomeno
LEFT JOIN FENOMENO_LUNAR fl ON fa.codigo_fenomeno = fl.codigo_fenomeno
LEFT JOIN FENOMENO_ESPACIO_PROFUNDO fep ON fa.codigo_fenomeno = fep.codigo_fenomeno
GROUP BY c.codigo_unico, z.numero_interno, tipo_fenomeno;

CREATE VIEW vw_asistentes_vs_evaluacion AS
SELECT c.nombre AS centro, z.nombre AS zona, a.codigo AS actividad,
       COUNT(DISTINCT r.id_visitante) AS cantidad_asistentes,
       ROUND(AVG(e.calificacion), 1) AS evaluacion_promedio
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
LEFT JOIN RESERVA r ON a.codigo = r.codigo_actividad AND r.asistencia_efectiva = 1
LEFT JOIN EVALUACION e ON a.codigo = e.codigo_actividad
GROUP BY c.codigo_unico, z.numero_interno, a.codigo;

DELIMITER $$
CREATE PROCEDURE sp_centros_actividades_visitantes(IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT c.nombre AS centro, 
           COUNT(DISTINCT a.codigo) AS total_actividades,
           COUNT(r.id_visitante) AS total_visitantes_asistentes
    FROM CENTRO c
    JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
    JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
    LEFT JOIN RESERVA r ON a.codigo = r.codigo_actividad AND r.asistencia_efectiva = 1
    WHERE a.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY c.codigo_unico
    ORDER BY total_visitantes_asistentes DESC, total_actividades DESC;
END$$
DELIMITER ;

CREATE VIEW vw_tasa_asistencia_zonas AS
SELECT c.nombre AS centro, z.nombre AS zona,
       COUNT(r.id_visitante) AS total_reservas,
       SUM(r.asistencia_efectiva) AS asistencias_reales,
       ROUND((SUM(r.asistencia_efectiva) / COUNT(r.id_visitante)) * 100, 2) AS porcentaje_asistencia
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
JOIN RESERVA r ON a.codigo = r.codigo_actividad
GROUP BY c.codigo_unico, z.numero_interno
ORDER BY porcentaje_asistencia DESC;

CREATE VIEW vw_fenomenos_registros_zona AS
SELECT c.nombre AS centro, z.nombre AS zona, fa.nombre AS fenomeno,
       COUNT(rf.codigo_fenomeno) AS total_veces_registrado
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN REGISTRO_FENOMENO rf ON z.numero_interno = rf.numero_interno_zona AND z.codigo_unico_centro = rf.codigo_unico_centro
JOIN FENOMENO_ASTRONOMICO fa ON rf.codigo_fenomeno = fa.codigo_fenomeno
GROUP BY c.codigo_unico, z.numero_interno, fa.codigo_fenomeno
ORDER BY total_veces_registrado DESC;

CREATE VIEW vw_diversidad_fenomenos_centro AS
SELECT c.nombre AS centro,
       COUNT(DISTINCT rf.codigo_fenomeno) AS total_fenomenos_distintos,
       SUM(CASE WHEN fs.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) AS cant_solares,
       SUM(CASE WHEN fl.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) AS cant_lunares,
       SUM(CASE WHEN fep.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) AS cant_esp_profundo
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN REGISTRO_FENOMENO rf ON z.numero_interno = rf.numero_interno_zona AND z.codigo_unico_centro = rf.codigo_unico_centro
LEFT JOIN FENOMENO_SOLAR fs ON rf.codigo_fenomeno = fs.codigo_fenomeno
LEFT JOIN FENOMENO_LUNAR fl ON rf.codigo_fenomeno = fl.codigo_fenomeno
LEFT JOIN FENOMENO_ESPACIO_PROFUNDO fep ON rf.codigo_fenomeno = fep.codigo_fenomeno
GROUP BY c.codigo_unico, c.nombre
ORDER BY total_fenomenos_distintos DESC;

CREATE VIEW vw_visitantes_mayor_participacion AS
SELECT v.id_visitante, v.nombre,
       COUNT(r.codigo_actividad) AS total_actividades_asistidas,
       SUM(a.valor) AS valor_total_invertido
FROM VISITANTE v
JOIN RESERVA r ON v.id_visitante = r.id_visitante
JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
WHERE r.asistencia_efectiva = 1
GROUP BY v.id_visitante, v.nombre
HAVING COUNT(r.codigo_actividad) > 1
ORDER BY total_actividades_asistidas DESC, valor_total_invertido DESC;

DELIMITER $$
CREATE PROCEDURE sp_actividades_sobre_promedio_centro(IN p_centro VARCHAR(10), IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT a.codigo, a.fecha, z.nombre AS zona, 
           COUNT(r.id_visitante) AS asistentes
    FROM ACTIVIDAD a
    JOIN ZONA_OBSERVACION z ON a.numero_interno_zona = z.numero_interno AND a.codigo_unico_centro = z.codigo_unico_centro
    JOIN RESERVA r ON a.codigo = r.codigo_actividad
    WHERE a.codigo_unico_centro = p_centro 
      AND a.fecha BETWEEN p_fecha_inicio AND p_fecha_fin 
      AND r.asistencia_efectiva = 1
    GROUP BY a.codigo, a.fecha, z.nombre, a.codigo_unico_centro
    HAVING asistentes > (
        SELECT COUNT(r2.id_visitante) / COUNT(DISTINCT a2.codigo)
        FROM ACTIVIDAD a2
        JOIN RESERVA r2 ON a2.codigo = r2.codigo_actividad
        WHERE a2.codigo_unico_centro = a.codigo_unico_centro
          AND a2.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
          AND r2.asistencia_efectiva = 1
    )
    ORDER BY asistentes DESC;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_zonas_oscuridad_superior(IN p_centro VARCHAR(10))
BEGIN
    SELECT z.numero_interno, z.nombre AS zona, z.nivel_oscuridad, a.codigo AS actividad_realizada
    FROM ZONA_OBSERVACION z
    LEFT JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
    WHERE z.codigo_unico_centro = p_centro
      AND z.nivel_oscuridad > (
          SELECT AVG(z2.nivel_oscuridad) 
          FROM ZONA_OBSERVACION z2 
          WHERE z2.codigo_unico_centro = z.codigo_unico_centro
      )
    ORDER BY z.nivel_oscuridad DESC;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_visitantes_destacados(IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT v.id_visitante, v.nombre, 
           COUNT(DISTINCT r.codigo_actividad) AS total_actividades,
           AVG(e.calificacion) AS promedio_evaluacion
    FROM VISITANTE v
    JOIN RESERVA r ON v.id_visitante = r.id_visitante
    JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
    JOIN EVALUACION e ON a.codigo = e.codigo_actividad
    WHERE a.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND r.asistencia_efectiva = 1
    GROUP BY v.id_visitante, v.nombre
    HAVING total_actividades > (
        SELECT COUNT(r2.codigo_actividad) / COUNT(DISTINCT r2.id_visitante)
        FROM RESERVA r2
        JOIN ACTIVIDAD a2 ON r2.codigo_actividad = a2.codigo
        WHERE a2.fecha BETWEEN p_fecha_inicio AND p_fecha_fin AND r2.asistencia_efectiva = 1
    )
    AND promedio_evaluacion > (
        SELECT AVG(e2.calificacion)
        FROM EVALUACION e2
        JOIN ACTIVIDAD a3 ON e2.codigo_actividad = a3.codigo
        WHERE a3.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
    );
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_centros_sobre_promedio(IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT c.codigo_unico, c.nombre AS centro,
           COUNT(r.id_visitante) / COUNT(DISTINCT a.codigo) AS promedio_asistentes_actividad
    FROM CENTRO c
    JOIN ACTIVIDAD a ON c.codigo_unico = a.codigo_unico_centro
    JOIN RESERVA r ON a.codigo = r.codigo_actividad
    WHERE a.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND r.asistencia_efectiva = 1
    GROUP BY c.codigo_unico, c.nombre
    HAVING promedio_asistentes_actividad > (
        SELECT COUNT(r2.id_visitante) / COUNT(DISTINCT a2.codigo)
        FROM ACTIVIDAD a2
        JOIN RESERVA r2 ON a2.codigo = r2.codigo_actividad
        WHERE a2.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
          AND r2.asistencia_efectiva = 1
    );
END$$
DELIMITER ;





USE turismo_astronomico;

-- 1. Insertar fenómenos base generales
INSERT INTO FENOMENO_ASTRONOMICO (codigo_fenomeno, nombre, descripcion, fecha_primera_observacion, frecuencia_estimada, nivel_interes_cientifico) VALUES
('FEN01', 'Eclipse Solar Total', 'Oscurecimiento total del Sol por la Luna', '2019-07-02', 'Baja', 'Alto'),
('FEN02', 'Manchas Solares Activas', 'Actividad magnética intensa en la fotosfera', '2020-01-15', 'Alta', 'Medio'),
('FEN03', 'Superluna de Sangre', 'Luna llena en perigeo con tono rojizo', '2021-04-26', 'Media', 'Bajo'),
('FEN04', 'Eclipse Lunar Parcial', 'Alineación parcial Tierra-Luna', '2022-05-16', 'Media', 'Medio'),
('FEN05', 'Nebulosa de Orion (M42)', 'Nube molecular y vivero estelar visible', '1610-01-01', 'Permanente', 'Alto'),
('FEN06', 'Galaxia de Andromeda (M31)', 'Galaxia espiral vecina del Grupo Local', '964-01-01', 'Permanente', 'Alto');

-- 2. Clasificarlos en sus respectivas categorías (Tablas hijas)
INSERT INTO FENOMENO_SOLAR (codigo_fenomeno) VALUES ('FEN01'), ('FEN02');
INSERT INTO FENOMENO_LUNAR (codigo_fenomeno) VALUES ('FEN03'), ('FEN04');
INSERT INTO FENOMENO_ESPACIO_PROFUNDO (codigo_fenomeno) VALUES ('FEN05'), ('FEN06');

-- 3. Registrar los fenómenos en las zonas de observación para poblar los gráficos
INSERT INTO REGISTRO_FENOMENO (codigo_fenomeno, numero_interno_zona, codigo_unico_centro) 
SELECT 'FEN01', numero_interno, codigo_unico_centro FROM ZONA_OBSERVACION LIMIT 6;

INSERT INTO REGISTRO_FENOMENO (codigo_fenomeno, numero_interno_zona, codigo_unico_centro) 
SELECT 'FEN03', numero_interno, codigo_unico_centro FROM ZONA_OBSERVACION LIMIT 6, 6;

INSERT INTO REGISTRO_FENOMENO (codigo_fenomeno, numero_interno_zona, codigo_unico_centro) 
SELECT 'FEN05', numero_interno, codigo_unico_centro FROM ZONA_OBSERVACION LIMIT 12, 6;