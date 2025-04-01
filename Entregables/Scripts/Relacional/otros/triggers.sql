-- Trigger que valida si un platillo esta disponible
--
CREATE OR REPLACE FUNCTION validar_disponibilidad_platillo()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT
            1
        FROM
            platillos
        WHERE
            id = NEW.platillo_id
            AND esta_disponible
    ) THEN RAISE EXCEPTION 'El platillo seleccionado no está disponible';
    END IF;

    RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_disponibilidad
BEFORE INSERT OR UPDATE ON detalle_visitas
FOR EACH ROW
    EXECUTE FUNCTION validar_disponibilidad_platillo();

-- Trigger para actualizar el rating de un establecimiento al insertar una nueva review
--
CREATE OR REPLACE FUNCTION actualizar_rating_trigger()
RETURNS TRIGGER AS $$
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
                establecimiento_id = NEW.establecimiento_id
        )
    WHERE
        id = NEW.establecimiento_id;

    RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_rating
AFTER INSERT OR UPDATE ON reviews
FOR EACH ROW
    EXECUTE FUNCTION actualizar_rating_trigger();

-- Trigger para evitar fechas de visitas futuras
--
CREATE OR REPLACE FUNCTION validar_fecha_visita()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_visita > NOW()
        THEN RAISE EXCEPTION 'La fecha de visita no puede estar en el futuro';
    END IF;

    RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_fecha_visita
BEFORE INSERT OR UPDATE ON visitas
FOR EACH ROW
    EXECUTE FUNCTION validar_fecha_visita();

-- Trigger para asegurarse de que la fecha de expiración de una promoción sea posterior a la de inicio
--
CREATE OR REPLACE FUNCTION validar_fecha_promocion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_expiracion <= NEW.fecha_inicio
        THEN RAISE EXCEPTION 'La fecha de expiración debe ser posterior a la fecha de inicio';
    END IF;

    RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_fecha_promocion
BEFORE INSERT OR UPDATE ON promociones
FOR EACH ROW
    EXECUTE FUNCTION validar_fecha_promocion();

-- Trigger para calcular el precio total en detalle_visitas
--
CREATE OR REPLACE FUNCTION calcular_precio_total()
RETURNS TRIGGER AS $$
BEGIN
    NEW.precio_unitario = (
        SELECT
            precio
        FROM
            platillos
        WHERE
            id = NEW.platillo_id
    ) * NEW.cantidad;

    RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calcular_precio_total
BEFORE INSERT OR UPDATE ON detalle_visitas
FOR EACH ROW
    EXECUTE FUNCTION calcular_precio_total();