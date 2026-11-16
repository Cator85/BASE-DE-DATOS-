-- ==============================================================================
-- PROYECTO: Sistema Integral de Gestión de Centros de Turismo Astronómico
-- FASE 2: Script Integral de Implementación (DDL, Restricciones, DML y R1-R12)
-- ==============================================================================

DROP DATABASE IF EXISTS turismo_astronomico;
CREATE DATABASE turismo_astronomico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE turismo_astronomico;

-- ==============================================================================
-- 1. TABLAS MAESTRAS INDEPENDIENTES
-- ==============================================================================
CREATE TABLE REGION (
    codigo VARCHAR(10) PRIMARY KEY,
    nombre_oficial VARCHAR(100) NOT NULL UNIQUE,
    superficie_protegida DECIMAL(12,2) NOT NULL CHECK (superficie_protegida >= 0),
    presupuesto_destinado DECIMAL(15,2) NOT NULL CHECK (presupuesto_destinado >= 0),
    otros_antecedentes TEXT
);

CREATE TABLE FENOMENO_ASTRONOMICO (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_primera_observacion DATE,
    frecuencia_estimada VARCHAR(50),
    nivel_interes_cientifico VARCHAR(20) NOT NULL
);

CREATE TABLE VISITANTE (
    id_visitante VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_origen VARCHAR(30) NOT NULL CHECK (tipo_origen IN ('Nacional', 'Internacional'))
);

CREATE TABLE PERSONAL (
    cuentas_usuario VARCHAR(50) PRIMARY KEY,
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('Administrativo', 'Guia Cientifico', 'Tecnico', 'Investigador'))
);

-- ==============================================================================
-- 2. JERARQUÍA DE FENÓMENOS (Subtipos / Especialización Disjunta)
-- ==============================================================================
CREATE TABLE FENOMENO_SOLAR (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    CONSTRAINT fk_fen_solar FOREIGN KEY (codigo_fenomeno)
        REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE FENOMENO_LUNAR (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    CONSTRAINT fk_fen_lunar FOREIGN KEY (codigo_fenomeno)
        REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE FENOMENO_ESPACIO_PROFUNDO (
    codigo_fenomeno VARCHAR(15) PRIMARY KEY,
    CONSTRAINT fk_fen_espacio FOREIGN KEY (codigo_fenomeno)
        REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ==============================================================================
-- 3. TABLA CENTRO (Depende de Región)
-- ==============================================================================
CREATE TABLE CENTRO (
    codigo_unico VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    fecha_inauguracion DATE,
    altitud INT CHECK (altitud >= 0),
    capacidad_maxima_diaria INT NOT NULL CHECK (capacidad_maxima_diaria > 0),
    presupuesto_anual DECIMAL(15,2) CHECK (presupuesto_anual >= 0),
    estado_operativo VARCHAR(30) NOT NULL DEFAULT 'Operativo'
        CHECK (estado_operativo IN ('Operativo', 'Mantenimiento', 'Cerrado Temporalmente', 'Cerrado Definitivo')),
    nivel_certificacion VARCHAR(50),
    latitud DECIMAL(10,6),
    longitud DECIMAL(10,6),
    codigo_region VARCHAR(10) NOT NULL,
    CONSTRAINT fk_centro_region FOREIGN KEY (codigo_region)
        REFERENCES REGION(codigo)
        ON UPDATE CASCADE
);

-- ==============================================================================
-- 4. ENTIDADES DÉBILES Y TABLAS DE ROMPIMIENTO (Dependen de Centro)
-- ==============================================================================
CREATE TABLE ZONA_OBSERVACION (
    numero_interno VARCHAR(10),
    codigo_unico_centro VARCHAR(10),
    nombre VARCHAR(100) NOT NULL,
    superficie DECIMAL(10,2) CHECK (superficie > 0),
    nivel_oscuridad INT NOT NULL CHECK (nivel_oscuridad BETWEEN 1 AND 10),
    capacidad_maxima INT NOT NULL CHECK (capacidad_maxima > 0),
    nivel_acceso VARCHAR(30) NOT NULL,
    PRIMARY KEY (numero_interno, codigo_unico_centro),
    CONSTRAINT fk_zona_centro FOREIGN KEY (codigo_unico_centro)
        REFERENCES CENTRO(codigo_unico)
        ON UPDATE CASCADE
);

CREATE TABLE EQUIPAMIENTO_ZONA (
    equipamiento VARCHAR(100),
    numero_interno_zona VARCHAR(10),
    codigo_unico_centro VARCHAR(10),
    PRIMARY KEY (equipamiento, numero_interno_zona, codigo_unico_centro),
    CONSTRAINT fk_equip_zona FOREIGN KEY (numero_interno_zona, codigo_unico_centro)
        REFERENCES ZONA_OBSERVACION(numero_interno, codigo_unico_centro)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE REGISTRO_FENOMENO (
    codigo_fenomeno VARCHAR(15),
    numero_interno_zona VARCHAR(10),
    codigo_unico_centro VARCHAR(10),
    PRIMARY KEY (codigo_fenomeno, numero_interno_zona, codigo_unico_centro),
    CONSTRAINT fk_reg_fenomeno FOREIGN KEY (codigo_fenomeno)
        REFERENCES FENOMENO_ASTRONOMICO(codigo_fenomeno)
        ON UPDATE CASCADE,
    CONSTRAINT fk_reg_zona FOREIGN KEY (numero_interno_zona, codigo_unico_centro)
        REFERENCES ZONA_OBSERVACION(numero_interno, codigo_unico_centro)
        ON UPDATE CASCADE
);

-- ==============================================================================
-- 5. ACTIVIDADES, EVALUACIONES Y RESERVAS
-- ==============================================================================
CREATE TABLE ACTIVIDAD (
    codigo VARCHAR(15) PRIMARY KEY,
    fecha DATE NOT NULL,
    horario TIME NOT NULL,
    modalidad VARCHAR(50) NOT NULL,
    duracion INT NOT NULL CHECK (duracion > 0),
    valor DECIMAL(10,2) NOT NULL CHECK (valor >= 0),
    capacidad INT NOT NULL CHECK (capacidad > 0),
    numero_interno_zona VARCHAR(10) NOT NULL,
    codigo_unico_centro VARCHAR(10) NOT NULL,
    CONSTRAINT fk_actividad_zona FOREIGN KEY (numero_interno_zona, codigo_unico_centro)
        REFERENCES ZONA_OBSERVACION(numero_interno, codigo_unico_centro)
        ON UPDATE CASCADE
);

CREATE TABLE EVALUACION (
    numero_correlativo INT,
    codigo_actividad VARCHAR(15),
    calificacion INT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    fecha DATE NOT NULL,
    comentario TEXT,
    PRIMARY KEY (numero_correlativo, codigo_actividad),
    CONSTRAINT fk_evaluacion_actividad FOREIGN KEY (codigo_actividad)
        REFERENCES ACTIVIDAD(codigo)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE RESERVA (
    id_visitante VARCHAR(15),
    codigo_actividad VARCHAR(15),
    fecha_reserva DATE NOT NULL,
    estado VARCHAR(30) NOT NULL,
    asistencia_efectiva INT NOT NULL DEFAULT 0 CHECK (asistencia_efectiva IN (0, 1)),
    otras_observaciones TEXT,
    PRIMARY KEY (id_visitante, codigo_actividad),
    CONSTRAINT fk_reserva_visitante FOREIGN KEY (id_visitante)
        REFERENCES VISITANTE(id_visitante)
        ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_actividad FOREIGN KEY (codigo_actividad)
        REFERENCES ACTIVIDAD(codigo)
        ON UPDATE CASCADE
);

-- ==============================================================================
-- 6. POBLAMIENTO DE DATOS BASE (Para ejecución independiente desde cero)
-- ==============================================================================
INSERT INTO REGION (codigo, nombre_oficial, superficie_protegida, presupuesto_destinado, otros_antecedentes) VALUES
('R01', 'Region de Antofagasta', 45000.00, 42000000.00, 'Cielos despejados en el Desierto de Atacama'),
('R02', 'Region de Atacama', 38500.50, 35000000.00, 'Baja humedad relativa anual'),
('R03', 'Region de Coquimbo', 29400.00, 39000000.00, 'Capital del astroturismo en Valle del Elqui'),
('R04', 'Region de Valparaiso', 12300.00, 18000000.00, 'Observatorios educativos costeros y cordilleranos'),
('R05', 'Region Metropolitana', 9800.00, 22000000.00, 'Centros de divulgacion cientifica');

INSERT INTO CENTRO (codigo_unico, nombre, fecha_inauguracion, altitud, capacidad_maxima_diaria, presupuesto_anual, estado_operativo, nivel_certificacion, latitud, longitud, codigo_region) VALUES
('C001', 'Observatorio Atacama 1', '2012-05-14', 3200, 250, 8500000.00, 'Operativo', 'Clase Mundial', -23.863400, -69.132800, 'R01'),
('C002', 'Observatorio Elqui 2', '2015-09-20', 2400, 300, 7200000.00, 'Operativo', 'Clase Mundial', -30.168900, -70.491200, 'R03'),
('C003', 'Observatorio Coquimbo 3', '2018-03-11', 2100, 180, 5400000.00, 'Operativo', 'Avanzado', -29.953300, -71.339500, 'R03'),
('C004', 'Observatorio Valparaiso 4', '2019-11-02', 1650, 140, 3900000.00, 'Mantenimiento', 'Basico', -33.047200, -71.612700, 'R04'),
('C014', 'Observatorio Elqui 14', '2016-07-19', 2750, 320, 9100000.00, 'Operativo', 'Clase Mundial', -30.051200, -70.512300, 'R03');

INSERT INTO ZONA_OBSERVACION (numero_interno, codigo_unico_centro, nombre, superficie, nivel_oscuridad, capacidad_maxima, nivel_acceso) VALUES
('Z01', 'C001', 'Sector Cupula Principal', 450.00, 10, 80, 'Cientifico'),
('Z02', 'C001', 'Sector Terraza Norte', 320.00, 8, 90, 'Publico'),
('Z01', 'C002', 'Sector Mirador Sur', 500.00, 9, 100, 'Publico'),
('Z01', 'C014', 'Sector Cupula Alta', 600.00, 10, 75, 'Cientifico'),
('Z02', 'C014', 'Sector Explanada Este', 420.00, 7, 120, 'Publico'),
('Z03', 'C014', 'Sector Oeste Profundo', 380.00, 9, 60, 'Publico');

INSERT INTO EQUIPAMIENTO_ZONA (equipamiento, numero_interno_zona, codigo_unico_centro) VALUES
('Telescopio Reflector 16 pulgadas', 'Z01', 'C001'),
('Camara CCD Astrofotografia', 'Z01', 'C001'),
('Binoculares Astronomicos 25x100', 'Z02', 'C001'),
('Telescopio Solar H-Alfa', 'Z01', 'C002'),
('Telescopio Ritchey-Chretien 20 pulgadas', 'Z01', 'C014');

INSERT INTO PERSONAL (cuentas_usuario, rol) VALUES
('admin@observatorio.cl', 'Administrativo'),
('guia1@observatorio.cl', 'Guia Cientifico'),
('tecnico1@observatorio.cl', 'Tecnico'),
('investigador1@observatorio.cl', 'Investigador');

INSERT INTO FENOMENO_ASTRONOMICO (codigo_fenomeno, nombre, descripcion, fecha_primera_observacion, frecuencia_estimada, nivel_interes_cientifico) VALUES
('FEN01', 'Eclipse Solar Total', 'Oscurecimiento total del Sol por la Luna', '2019-07-02', 'Baja', 'Alto'),
('FEN02', 'Manchas Solares Activas', 'Actividad magnetica intensa en la fotosfera', '2020-01-15', 'Alta', 'Medio'),
('FEN03', 'Superluna de Sangre', 'Luna llena en perigeo con tono rojizo', '2021-04-26', 'Media', 'Bajo'),
('FEN04', 'Eclipse Lunar Parcial', 'Alineacion parcial Tierra-Luna', '2022-05-16', 'Media', 'Medio'),
('FEN05', 'Nebulosa de Orion (M42)', 'Nube molecular y vivero estelar visible', '1610-01-01', 'Permanente', 'Alto'),
('FEN06', 'Galaxia de Andromeda (M31)', 'Galaxia espiral vecina del Grupo Local', '0964-01-01', 'Permanente', 'Alto');

INSERT INTO FENOMENO_SOLAR (codigo_fenomeno) VALUES ('FEN01'), ('FEN02');
INSERT INTO FENOMENO_LUNAR (codigo_fenomeno) VALUES ('FEN03'), ('FEN04');
INSERT INTO FENOMENO_ESPACIO_PROFUNDO (codigo_fenomeno) VALUES ('FEN05'), ('FEN06');

INSERT INTO REGISTRO_FENOMENO (codigo_fenomeno, numero_interno_zona, codigo_unico_centro)
SELECT 'FEN01', numero_interno, codigo_unico_centro FROM ZONA_OBSERVACION LIMIT 2;

INSERT INTO REGISTRO_FENOMENO (codigo_fenomeno, numero_interno_zona, codigo_unico_centro)
SELECT 'FEN03', numero_interno, codigo_unico_centro FROM ZONA_OBSERVACION LIMIT 2, 2;

INSERT INTO REGISTRO_FENOMENO (codigo_fenomeno, numero_interno_zona, codigo_unico_centro)
SELECT 'FEN05', numero_interno, codigo_unico_centro FROM ZONA_OBSERVACION LIMIT 4, 2;

INSERT INTO VISITANTE (id_visitante, nombre, tipo_origen) VALUES
('V0001', 'Camila Ruiz', 'Nacional'),
('V0002', 'Sara Melo', 'Internacional'),
('V0003', 'Juan Perez', 'Nacional'),
('V0004', 'Pedro Luna', 'Nacional'),
('V0005', 'Elena Torres', 'Internacional');

INSERT INTO ACTIVIDAD (codigo, fecha, horario, modalidad, duracion, valor, capacidad, numero_interno_zona, codigo_unico_centro) VALUES
('ACT0001', '2025-06-15', '21:00:00', 'Guiada', 120, 15000.00, 40, 'Z01', 'C001'),
('ACT0002', '2025-07-20', '22:00:00', 'Taller', 150, 25000.00, 30, 'Z02', 'C001'),
('ACT0003', '2025-08-10', '20:30:00', 'Guiada', 90, 10000.00, 50, 'Z01', 'C002'),
('ACT0004', '2025-09-05', '21:30:00', 'Guiada', 120, 15000.00, 35, 'Z01', 'C014'),
('ACT0005', '2025-10-12', '23:00:00', 'Libre', 180, 20000.00, 45, 'Z03', 'C014');

INSERT INTO RESERVA (id_visitante, codigo_actividad, fecha_reserva, estado, asistencia_efectiva, otras_observaciones) VALUES
('V0001', 'ACT0001', '2025-06-01', 'Asistio', 1, 'Sin observaciones'),
('V0001', 'ACT0004', '2025-08-25', 'Asistio', 1, 'Reserva web'),
('V0002', 'ACT0001', '2025-06-02', 'Asistio', 1, 'Turista extranjero'),
('V0002', 'ACT0002', '2025-07-10', 'Asistio', 1, 'Incluye equipo'),
('V0002', 'ACT0004', '2025-08-28', 'Asistio', 1, 'Sin observaciones'),
('V0003', 'ACT0003', '2025-08-01', 'Asistio', 1, 'Sin observaciones'),
('V0004', 'ACT0005', '2025-10-01', 'Asistio', 1, 'Sin observaciones'),
('V0005', 'ACT0003', '2025-08-02', 'Cancelada', 0, 'Cancelacion anticipada');

INSERT INTO EVALUACION (numero_correlativo, codigo_actividad, calificacion, fecha, comentario) VALUES
(1, 'ACT0001', 5, '2025-06-16', 'Excelente visibilidad y explicacion'),
(2, 'ACT0001', 4, '2025-06-16', 'Muy buena experiencia nocturna'),
(1, 'ACT0002', 5, '2025-07-21', 'Taller de astrofotografia impecable'),
(1, 'ACT0003', 4, '2025-08-11', 'Buena organizacion'),
(1, 'ACT0004', 5, '2025-09-06', 'Cielos despejados en Elqui');

-- ==============================================================================
-- 7. REQUERIMIENTOS DE INFORMACIÓN EN ORDEN SECUENCIAL (R1 A R12)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- R1 (PROCEDURE): Zonas de observación con mayor cantidad de visitantes en un período
-- ------------------------------------------------------------------------------
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
    GROUP BY c.codigo_unico, c.nombre, z.numero_interno, z.nombre
    ORDER BY total_visitantes_efectivos DESC;
END$$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- R2 (VIEW): Distribución de fenómenos clasificados por centro y zona
-- ------------------------------------------------------------------------------
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
GROUP BY c.codigo_unico, c.nombre, z.numero_interno, z.nombre, tipo_fenomeno;

-- ------------------------------------------------------------------------------
-- R3 (VIEW): Relación entre cantidad de asistentes y evaluación promedio
-- ------------------------------------------------------------------------------
CREATE VIEW vw_asistentes_vs_evaluacion AS
SELECT c.nombre AS centro, z.nombre AS zona, a.codigo AS actividad,
       COUNT(DISTINCT r.id_visitante) AS cantidad_asistentes,
       ROUND(AVG(e.calificacion), 1) AS evaluacion_promedio
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
LEFT JOIN RESERVA r ON a.codigo = r.codigo_actividad AND r.asistencia_efectiva = 1
LEFT JOIN EVALUACION e ON a.codigo = e.codigo_actividad
GROUP BY c.codigo_unico, c.nombre, z.numero_interno, z.nombre, a.codigo;

-- ------------------------------------------------------------------------------
-- R4 (PROCEDURE): Centros con mayor cantidad de actividades y visitantes en un período
-- ------------------------------------------------------------------------------
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
    GROUP BY c.codigo_unico, c.nombre
    ORDER BY total_visitantes_asistentes DESC, total_actividades DESC;
END$$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- R5 (VIEW): Tasa de asistencia efectiva por zonas
-- ------------------------------------------------------------------------------
CREATE VIEW vw_tasa_asistencia_zonas AS
SELECT c.nombre AS centro, z.nombre AS zona,
       COUNT(r.id_visitante) AS total_reservas,
       SUM(r.asistencia_efectiva) AS asistencias_reales,
       ROUND((SUM(r.asistencia_efectiva) / NULLIF(COUNT(r.id_visitante), 0)) * 100, 2) AS porcentaje_asistencia
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
JOIN RESERVA r ON a.codigo = r.codigo_actividad
GROUP BY c.codigo_unico, c.nombre, z.numero_interno, z.nombre
ORDER BY porcentaje_asistencia DESC;

-- ------------------------------------------------------------------------------
-- R6 (VIEW): Fenómenos con mayor cantidad de registros por centro y zona
-- ------------------------------------------------------------------------------
CREATE VIEW vw_fenomenos_registros_zona AS
SELECT c.nombre AS centro, z.nombre AS zona, fa.nombre AS fenomeno,
       COUNT(rf.codigo_fenomeno) AS total_veces_registrado
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN REGISTRO_FENOMENO rf ON z.numero_interno = rf.numero_interno_zona AND z.codigo_unico_centro = rf.codigo_unico_centro
JOIN FENOMENO_ASTRONOMICO fa ON rf.codigo_fenomeno = fa.codigo_fenomeno
GROUP BY c.codigo_unico, c.nombre, z.numero_interno, z.nombre, fa.codigo_fenomeno, fa.nombre
ORDER BY total_veces_registrado DESC;

-- ------------------------------------------------------------------------------
-- R7 (VIEW): Diversidad de fenómenos observados y proporción por tipo en cada centro
-- ------------------------------------------------------------------------------
CREATE VIEW vw_diversidad_fenomenos_centro AS
SELECT c.nombre AS centro,
       COUNT(DISTINCT rf.codigo_fenomeno) AS total_fenomenos_distintos,
       SUM(CASE WHEN fs.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) AS cant_solares,
       ROUND(SUM(CASE WHEN fs.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(rf.codigo_fenomeno), 0), 2) AS prop_solares_pct,
       SUM(CASE WHEN fl.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) AS cant_lunares,
       ROUND(SUM(CASE WHEN fl.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(rf.codigo_fenomeno), 0), 2) AS prop_lunares_pct,
       SUM(CASE WHEN fep.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) AS cant_esp_profundo,
       ROUND(SUM(CASE WHEN fep.codigo_fenomeno IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(rf.codigo_fenomeno), 0), 2) AS prop_esp_profundo_pct
FROM CENTRO c
JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
JOIN REGISTRO_FENOMENO rf ON z.numero_interno = rf.numero_interno_zona AND z.codigo_unico_centro = rf.codigo_unico_centro
LEFT JOIN FENOMENO_SOLAR fs ON rf.codigo_fenomeno = fs.codigo_fenomeno
LEFT JOIN FENOMENO_LUNAR fl ON rf.codigo_fenomeno = fl.codigo_fenomeno
LEFT JOIN FENOMENO_ESPACIO_PROFUNDO fep ON rf.codigo_fenomeno = fep.codigo_fenomeno
GROUP BY c.codigo_unico, c.nombre
ORDER BY total_fenomenos_distintos DESC;

-- ------------------------------------------------------------------------------
-- R8 (VIEW): Visitantes con mayor participación y valor total asociado
-- ------------------------------------------------------------------------------
CREATE VIEW vw_visitantes_mayor_participacion AS
SELECT v.id_visitante, v.nombre,
       COUNT(r.codigo_actividad) AS total_actividades_asistidas,
       COUNT(DISTINCT c.codigo_unico) AS total_centros_visitados,
       SUM(a.valor) AS valor_total_invertido
FROM VISITANTE v
JOIN RESERVA r ON v.id_visitante = r.id_visitante
JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
JOIN ZONA_OBSERVACION z ON a.numero_interno_zona = z.numero_interno AND a.codigo_unico_centro = z.codigo_unico_centro
JOIN CENTRO c ON z.codigo_unico_centro = c.codigo_unico
WHERE r.asistencia_efectiva = 1
GROUP BY v.id_visitante, v.nombre
HAVING COUNT(r.codigo_actividad) > 1
ORDER BY total_actividades_asistidas DESC, valor_total_invertido DESC;

-- ------------------------------------------------------------------------------
-- R9 (PROCEDURE): Actividades que superan el promedio de asistentes del mismo centro
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_r9_actividades_sobre_promedio(
    IN p_centro_codigo VARCHAR(10),
    IN p_fecha_inicio DATE,
    IN p_fecha_termino DATE
)
BEGIN
    SELECT c.nombre AS centro,
           z.nombre AS zona,
           a.codigo AS codigo_actividad,
           COUNT(r.id_visitante) AS total_asistentes
    FROM CENTRO c
    JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
    JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
    LEFT JOIN RESERVA r ON a.codigo = r.codigo_actividad
    WHERE c.codigo_unico = p_centro_codigo
      AND a.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
    GROUP BY a.codigo, c.nombre, z.nombre, a.codigo_unico_centro
    HAVING COUNT(r.id_visitante) > (
        SELECT AVG(sub.asistentes)
        FROM (
            SELECT a2.codigo, a2.codigo_unico_centro, COUNT(r2.id_visitante) AS asistentes
            FROM ACTIVIDAD a2
            LEFT JOIN RESERVA r2 ON a2.codigo = r2.codigo_actividad
            WHERE a2.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
            GROUP BY a2.codigo, a2.codigo_unico_centro
        ) AS sub
        WHERE sub.codigo_unico_centro = a.codigo_unico_centro
    )
    ORDER BY total_asistentes DESC;
END$$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- R10 (PROCEDURE): Zonas con nivel de oscuridad superior al promedio del mismo centro
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_r10_zonas_mayor_oscuridad(
    IN p_centro_codigo VARCHAR(10)
)
BEGIN
    SELECT c.nombre AS centro,
           z.nombre AS zona,
           z.nivel_oscuridad,
           a.codigo AS codigo_actividad
    FROM CENTRO c
    JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
    LEFT JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
    WHERE c.codigo_unico = p_centro_codigo
      AND z.nivel_oscuridad > (
          SELECT AVG(z2.nivel_oscuridad)
          FROM ZONA_OBSERVACION z2
          WHERE z2.codigo_unico_centro = z.codigo_unico_centro
      )
    ORDER BY z.nivel_oscuridad DESC;
END$$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- R11 (PROCEDURE): Visitantes destacados (participación y evaluación > promedio general)
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_r11_visitantes_destacados(
    IN p_fecha_inicio DATE,
    IN p_fecha_termino DATE
)
BEGIN
    SELECT v.id_visitante,
           v.nombre AS visitante,
           COUNT(DISTINCT r.codigo_actividad) AS total_actividades,
           ROUND(AVG(e.calificacion), 2) AS promedio_evaluacion
    FROM VISITANTE v
    JOIN RESERVA r ON v.id_visitante = r.id_visitante
    JOIN ACTIVIDAD a ON r.codigo_actividad = a.codigo
    JOIN EVALUACION e ON a.codigo = e.codigo_actividad
    WHERE a.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
      AND r.asistencia_efectiva = 1
    GROUP BY v.id_visitante, v.nombre
    HAVING COUNT(DISTINCT r.codigo_actividad) > (
        SELECT AVG(actividades_por_visitante)
        FROM (
            SELECT COUNT(DISTINCT r2.codigo_actividad) AS actividades_por_visitante
            FROM RESERVA r2
            JOIN ACTIVIDAD a2 ON r2.codigo_actividad = a2.codigo
            WHERE a2.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
              AND r2.asistencia_efectiva = 1
            GROUP BY r2.id_visitante
        ) AS sub_act
    )
    AND AVG(e.calificacion) > (
        SELECT AVG(e2.calificacion)
        FROM EVALUACION e2
        JOIN ACTIVIDAD a3 ON e2.codigo_actividad = a3.codigo
        WHERE a3.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
    )
    ORDER BY total_actividades DESC, promedio_evaluacion DESC;
END$$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- R12 (PROCEDURE): Centros con promedio de asistentes por actividad > promedio general
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_r12_centros_promedio_asistentes(
    IN p_fecha_inicio DATE,
    IN p_fecha_termino DATE
)
BEGIN
    SELECT c.nombre AS centro,
           COUNT(r.id_visitante) AS total_asistentes,
           COUNT(DISTINCT a.codigo) AS total_actividades,
           ROUND(COUNT(r.id_visitante) * 1.0 / NULLIF(COUNT(DISTINCT a.codigo), 0), 2) AS promedio_asistentes_por_actividad
    FROM CENTRO c
    JOIN ZONA_OBSERVACION z ON c.codigo_unico = z.codigo_unico_centro
    JOIN ACTIVIDAD a ON z.numero_interno = a.numero_interno_zona AND z.codigo_unico_centro = a.codigo_unico_centro
    LEFT JOIN RESERVA r ON a.codigo = r.codigo_actividad
    WHERE a.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
    GROUP BY c.codigo_unico, c.nombre
    HAVING (COUNT(r.id_visitante) * 1.0 / NULLIF(COUNT(DISTINCT a.codigo), 0)) > (
        SELECT AVG(promedio_centro)
        FROM (
            SELECT COUNT(r2.id_visitante) * 1.0 / NULLIF(COUNT(DISTINCT a2.codigo), 0) AS promedio_centro
            FROM CENTRO c2
            JOIN ZONA_OBSERVACION z2 ON c2.codigo_unico = z2.codigo_unico_centro
            JOIN ACTIVIDAD a2 ON z2.numero_interno = a2.numero_interno_zona AND z2.codigo_unico_centro = a2.codigo_unico_centro
            LEFT JOIN RESERVA r2 ON a2.codigo = r2.codigo_actividad
            WHERE a2.fecha BETWEEN p_fecha_inicio AND p_fecha_termino
            GROUP BY c2.codigo_unico
        ) AS sub_general
    )
    ORDER BY promedio_asistentes_por_actividad DESC;
END$$
DELIMITER ;

-- ==============================================================================
-- 8. SENTENCIAS DE VERIFICACIÓN EN ORDEN R1 A R12
-- ==============================================================================
CALL sp_r1_zonas_mayor_visita('2024-01-01', '2026-12-31');                 -- R1
SELECT * FROM vista_r2_distribucion_fenomenos;                           -- R2
SELECT * FROM vista_r3_asistencia_evaluacion;                            -- R3
CALL sp_r4_centros_actividad_visitantes('2024-01-01', '2026-12-31');       -- R4
SELECT * FROM vista_r5_tasa_asistencia;                                  -- R5
SELECT * FROM vista_r6_fenomenos_por_centro_zona;                        -- R6
SELECT * FROM vista_r7_proporcion_fenomenos;                             -- R7
SELECT * FROM vista_r8_participacion_visitantes;                         -- R8
CALL sp_r9_actividades_sobre_promedio('C014', '2024-01-01', '2026-12-31'); -- R9
CALL sp_r10_zonas_mayor_oscuridad('C014');                                 -- R10
CALL sp_r11_visitantes_destacados('2024-01-01', '2026-12-31');             -- R11
CALL sp_r12_centros_promedio_asistentes('2024-01-01', '2026-12-31');       -- R12
