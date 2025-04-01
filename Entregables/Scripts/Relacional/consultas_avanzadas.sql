-- Usuarios cerca de un establecimiento especifico
SELECT
    u.nombre,
    u.email
FROM
    usuarios u
    JOIN establecimientos e ON e.id = 1
WHERE
    ST_DWithin(
        u.ubicacion :: geography,
        e.ubicacion :: geography,
        1000 -- area en metros
    );

--Establecimientos mas cercanos a un usuario
SELECT
    e.nombre,
    ST_Distance(
        e.ubicacion :: geography,
        u.ubicacion :: geography
    ) AS distancia_metros
FROM
    establecimientos e
    JOIN usuarios u ON u.id = 1
ORDER BY
    distancia_metros
LIMIT
    5;

-- Usuarios que han gastado mas dinero en visitas
SELECT
    u.nombre,
    SUM(v.consumo_total) AS total_gastado
FROM
    usuarios u
    JOIN visitas v ON v.usuario_id = u.id
GROUP BY
    u.id
ORDER BY
    total_gastado DESC
LIMIT
    10;

-- Usuarios con mas visitas registradas
SELECT
    u.nombre,
    COUNT(v.id) AS total_visitas
FROM
    usuarios u
    JOIN visitas v ON v.usuario_id = u.id
GROUP BY
    u.id
ORDER BY
    total_visitas DESC
LIMIT
    10;

-- Platillos mas vendidos
SELECT
    p.nombre,
    SUM(dv.cantidad) AS total_vendidos
FROM
    platillos p
    JOIN detalle_visitas dv ON dv.platillo_id = p.id
GROUP BY
    p.id
ORDER BY
    total_vendidos DESC
LIMIT
    10;

-- Ingresos generados por platillo
SELECT
    p.nombre,
    SUM(dv.cantidad * dv.precio_unitario) AS total_ingresos
FROM
    platillos p
    JOIN detalle_visitas dv ON dv.platillo_id = p.id
GROUP BY
    p.id
ORDER BY
    total_ingresos DESC
LIMIT
    10;

-- Promociones activas hoy
SELECT
    oferta,
    fecha_inicio,
    fecha_expiracion,
    e.nombre AS establecimiento
FROM
    promociones pr
    JOIN establecimientos e ON e.id = pr.establecimiento_id
WHERE
    CURRENT_DATE BETWEEN fecha_inicio
    AND fecha_expiracion;

-- Establecimientos con mas promociones en su carrera
SELECT
    e.nombre,
    COUNT(pr.id) AS total_promociones
FROM
    promociones pr
    JOIN establecimientos e ON e.id = pr.establecimiento_id
GROUP BY
    e.id
ORDER BY
    total_promociones DESC
LIMIT
    10;

-- Número de empleados por establecimiento
SELECT
    e.nombre,
    COUNT(emp.id) AS cantidad_empleados
FROM
    empleados emp
    JOIN establecimientos e ON e.id = emp.establecimiento_id
GROUP BY
    e.id
ORDER BY
    cantidad_empleados DESC;

-- Empleados mas antiguos
SELECT
    nombre,
    puesto,
    fecha_contratacion,
    CURRENT_DATE - fecha_contratacion AS dias_en_trabajo
FROM
    empleados
ORDER BY
    fecha_contratacion ASC
LIMIT
    10;

-- Mejores establecimientos segun promedio de calificación
SELECT
    est.nombre,
    ROUND(AVG(r.calificacion), 2) AS promedio_rating,
    COUNT(r.id) AS cantidad_reviews
FROM
    reviews r
    JOIN establecimientos est ON est.id = r.establecimiento_id
GROUP BY
    est.id
HAVING
    COUNT(r.id) > 3
ORDER BY
    promedio_rating DESC
LIMIT
    10;

-- Usuarios con mas reseñas negativas
SELECT
    u.nombre,
    COUNT(r.id) AS resegnas_negativas
FROM
    reviews r
    JOIN usuarios u ON u.id = r.usuario_id
WHERE
    r.calificacion <= 2 -- considerando 2 o menor calificacion como negativa
GROUP BY
    u.id
ORDER BY
    resegnas_negativas DESC;