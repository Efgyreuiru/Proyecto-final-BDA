-- Procedimiento para agregar un nuevo usuario
--
CREATE OR REPLACE FUNCTION agregar_usuario(
    nombre VARCHAR,
    email VARCHAR,
    telefono VARCHAR,
    fecha_registro DATE,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO usuarios (
        nombre,
        email,
        telefono,
        fecha_registro,
        ubicacion
    )
    VALUES
    (
        nombre,
        email,
        telefono,
        fecha_registro,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)
    );
END;

$$ LANGUAGE plpgsql;

-- Procedimiento para registrar una visita
--
CREATE OR REPLACE FUNCTION registrar_visita(
    usuario_id INT,
    establecimiento_id INT,
    fecha TIMESTAMP,
    total DECIMAL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO visitas (
        usuario_id,
        establecimiento_id,
        fecha_visita,
        consumo_total
    )
    VALUES
    (
        usuario_id,
        establecimiento_id,
        fecha,
        total
    );
END;

$$ LANGUAGE plpgsql;

-- Procedimiento para agregar una review
--
CREATE OR REPLACE FUNCTION agregar_review(
    usuario_id INT,
    establecimiento_id INT,
    calificacion SMALLINT,
    comentario TEXT,
    fecha TIMESTAMP
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO reviews (
        usuario_id,
        establecimiento_id,
        calificacion,
        comentario,
        fecha_publicacion
    )
    VALUES
    (
        usuario_id,
        establecimiento_id,
        calificacion,
        comentario,
        fecha
    );
END;

$$ LANGUAGE plpgsql;

-- Procedimiento para actualizar el rating de un establecimiento
--
CREATE OR REPLACE FUNCTION actualizar_rating_establecimiento(est_id INT)
RETURNS VOID AS $$
BEGIN
    UPDATE
        establecimientos
    SET
        rating = (
            SELECT
                COALESCE(AVG(calificacion), 0)
            FROM
                reviews
            WHERE
                establecimiento_id = est_id
        )
    WHERE
        id = est_id;
END;

$$ LANGUAGE plpgsql;