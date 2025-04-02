-- Función que recomienda establecimientos al usuario
--
CREATE OR REPLACE FUNCTION recomendar_establecimientos(usuario_id INT) 
RETURNS TABLE(id INT, nombre VARCHAR)
LANGUAGE plpgsql AS $$ 
BEGIN 
    RETURN QUERY 
    SELECT 
        e.id,
        e.nombre
    FROM 
        establecimientos e
    JOIN platillos p ON e.id = p.establecimiento_id
    JOIN preferencias pref ON p.comida_id = pref.comida_id
    WHERE 
        pref.usuario_id = recomendar_establecimientos.usuario_id
    ORDER BY 
        pref.nivel_preferencia DESC;
END;
$$;

-- Función para calcular la distancia entre un usuario y un establecimiento
--
CREATE OR REPLACE FUNCTION calcular_distancia(usuario_id INT, establecimiento_id INT)
RETURNS DOUBLE PRECISION AS $$ DECLARE distancia DOUBLE PRECISION;
BEGIN
    SELECT
        ST_DistanceSphere(u.ubicacion, e.ubicacion) INTO distancia
    FROM
        usuarios u,
        establecimientos e
    WHERE
        u.id = usuario_id
        AND e.id = establecimiento_id;

    RETURN distancia;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener el promedio de calificaciones de un establecimiento
--
CREATE OR REPLACE FUNCTION obtener_promedio_calificacion(est_id INT)
RETURNS DECIMAL(3, 2) AS $$ DECLARE promedio DECIMAL(3, 2);
BEGIN
    SELECT
        COALESCE(AVG(calificacion), 0) INTO promedio
    FROM
        reviews
    WHERE
        establecimiento_id = est_id;

    RETURN promedio;
END;
$$ LANGUAGE plpgsql;

-- Función para contar las visitas de un usuario
--
CREATE OR REPLACE FUNCTION contar_visitas_usuario(user_id INT)
RETURNS INT AS $$ DECLARE total_visitas INT;
BEGIN
    SELECT
        COUNT(*) INTO total_visitas
    FROM
        visitas
    WHERE
        usuario_id = user_id;

    RETURN total_visitas;
END;

$$ LANGUAGE plpgsql;

-- Función para obtener el total gastado por un usuario
--
CREATE OR REPLACE FUNCTION obtener_gasto_total_usuario(user_id INT)
RETURNS DECIMAL(10, 2) AS $$ DECLARE total_gasto DECIMAL(10, 2);
BEGIN
    SELECT
        COALESCE(SUM(consumo_total), 0) INTO total_gasto
    FROM
        visitas
    WHERE
        usuario_id = user_id;

    RETURN total_gasto;
END;

$$ LANGUAGE plpgsql;