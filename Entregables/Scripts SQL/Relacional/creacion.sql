CREATE DATABASE "ProyectoFinalDb";

\c "ProyectoFinalDb"

CREATE EXTENSION IF NOT EXISTS postgis;


CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(15) NOT NULL,
    fecha_registro DATE NOT NULL,
    ubicacion geometry(Point, 4326) NOT NULL
);

CREATE TABLE establecimientos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    hora_apertura TIME NOT NULL,
    hora_cierre TIME NOT NULL,
    dias_laborales VARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    categoria VARCHAR(50),
    rating DECIMAL(3, 2),
    fecha_inauguracion DATE NOT NULL,
    ubicacion geometry(Point, 4326) NOT NULL
);

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    puesto VARCHAR(50) NOT NULL,
    fecha_contratacion DATE NOT NULL,
    establecimiento_id INT NOT NULL,
    CONSTRAINT fk_empleados_establecimiento FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
);

CREATE TABLE promociones (
    id SERIAL PRIMARY KEY,
    oferta TEXT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_expiracion DATE NOT NULL,
    establecimiento_id INT NOT NULL,
    CONSTRAINT fk_empleados_establecimiento FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
);

CREATE TABLE comidas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_cocina VARCHAR(50)
);

CREATE TABLE platillos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(6, 2) NOT NULL,
    esta_disponible BOOLEAN,
    comida_id INT NOT NULL,
    establecimiento_id INT NOT NULL,
    CONSTRAINT fk_platillos_comida FOREIGN KEY (comida_id) REFERENCES comidas(id),
    CONSTRAINT fk_platillos_establecimiento FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
);

CREATE TABLE preferencias (
    usuario_id INT NOT NULL,
    comida_id INT NOT NULL,
    PRIMARY KEY (usuario_id, comida_id),
    nivel_preferencia SMALLINT NOT NULL,
    CONSTRAINT fk_preferencias_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_preferencias_comida FOREIGN KEY (comida_id) REFERENCES comidas(id)
);

CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    calificacion SMALLINT NOT NULL,
    comentario TEXT,
    fecha_publicacion TIMESTAMP NOT NULL,
    usuario_id INT NOT NULL,
    establecimiento_id INT NOT NULL,
    CONSTRAINT fk_reviews_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_reviews_establecimiento FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
);

CREATE TABLE visitas (
    id SERIAL PRIMARY KEY,
    fecha_visita TIMESTAMP NOT NULL,
    consumo_total DECIMAL(6, 2) NOT NULL,
    usuario_id INT NOT NULL,
    establecimiento_id INT NOT NULL,
    CONSTRAINT fk_visitas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_visitas_establecimiento FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
);

CREATE TABLE detalle_visitas (
    id SERIAL PRIMARY KEY,
    cantidad INT NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(6, 2),
    visita_id INT NOT NULL,
    platillo_id INT NOT NULL,
    CONSTRAINT fk_detalle_visitas_visita FOREIGN KEY (visita_id) REFERENCES visitas(id),
    CONSTRAINT fk_detalle_visitas_platillo FOREIGN KEY (platillo_id) REFERENCES platillos(id)
);

-- Índices para acelerar consultas
--
CREATE INDEX idx_reviews_calificacion ON reviews (calificacion);

CREATE INDEX idx_reviews_fecha ON reviews (fecha_publicacion);

CREATE INDEX idx_visitas_fecha ON visitas (fecha_visita);

-- Índices espaciales
--
CREATE INDEX idx_usuarios_ubicacion ON usuarios USING GIST (ubicacion);

CREATE INDEX idx_establecimientos_ubicacion ON establecimientos USING GIST (ubicacion);