-- Vista de establecimientos con su promedio de calificación
--
CREATE VIEW vista_establecimientos_rating AS
SELECT
    e.id,
    e.nombre,
    e.categoria,
    e.telefono,
    e.ubicacion,
    COALESCE(AVG(r.calificacion), 0) AS promedio_calificacion
FROM
    establecimientos e
    LEFT JOIN reviews r ON e.id = r.establecimiento_id
GROUP BY
    e.id;

-- Vista de visitas de usuarios con el total gastado
--
CREATE VIEW vista_visitas_usuario AS
SELECT
    v.id,
    u.nombre AS usuario,
    e.nombre AS establecimiento,
    v.fecha_visita,
    v.consumo_total
FROM
    visitas v
    JOIN usuarios u ON v.usuario_id = u.id
    JOIN establecimientos e ON v.establecimiento_id = e.id;

-- Vista de los platillos más vendidos
--
CREATE VIEW vista_platillos_mas_vendidos AS
SELECT
    p.id,
    p.nombre,
    e.nombre AS establecimiento,
    SUM(dv.cantidad) AS total_vendido
FROM
    detalle_visitas dv
    JOIN platillos p ON dv.platillo_id = p.id
    JOIN establecimientos e ON p.establecimiento_id = e.id
GROUP BY
    p.id,
    e.nombre
ORDER BY
    total_vendido DESC;

-- Vista de usuarios y sus preferencias de comida
--
CREATE VIEW vista_usuarios_preferencias AS
SELECT
    u.id,
    u.nombre,
    c.nombre AS comida_preferida,
    p.nivel_preferencia
FROM
    preferencias p
    JOIN usuarios u ON p.usuario_id = u.id
    JOIN comidas c ON p.comida_id = c.id;

-- Vista de establecimientos mas visitado
--
CREATE VIEW establecimientos_mas_visitados AS
SELECT
    e.id,
    e.nombre,
    COUNT(v.id) AS total_visitas
FROM
    establecimientos e
    JOIN visitas v ON e.id = v.establecimiento_id
GROUP BY
    e.id,
    e.nombre
ORDER BY
    total_visitas DESC;

-- Vista de usuarios que mas estan activos
--
CREATE VIEW usuarios_mas_activos AS
SELECT
    u.id,
    u.nombre,
    COUNT(v.id) AS total_visitas
FROM
    usuarios u
    JOIN visitas v ON u.id = v.usuario_id
GROUP BY
    u.id,
    u.nombre
ORDER BY
    total_visitas DESC;

-- Vista de platillos mas vendidos
--
CREATE VIEW platillos_mas_vendidos AS
SELECT
    p.id,
    p.nombre,
    SUM(dv.cantidad) AS total_vendido
FROM
    platillos p
    JOIN detalle_visitas dv ON p.id = dv.platillo_id
GROUP BY
    p.id,
    p.nombre
ORDER BY
    total_vendido DESC;