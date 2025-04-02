-- En este archivo se guardaran las consultas que nos dan las informaciones
-- para actualizar la base de datos no relacional.

-- Consulta para obtener la información necesaria para actualizar las estadísticas de los establecimientos
SELECT
  establecimiento_id,
  to_char(fecha_visita, 'YYYY-MM') AS mes,
  COUNT(*) AS visitas_totales,
  SUM(consumo_total) AS "Consumo total",
  ROUND(AVG(consumo_total)::numeric, 2) AS promedio_consumo
FROM visitas
GROUP BY establecimiento_id, mes
ORDER BY establecimiento_id, mes;

-- Consulta para obtener la información necesaria para actualizar las estadísticas de las reviews
SELECT 
  establecimiento_id,
  to_char(fecha_publicacion, 'YYYY-MM') AS mes,
  COUNT(*) AS total_reviews,
  ROUND(AVG(calificacion)::numeric, 2) AS promedio_calificacion,
  SUM(CASE WHEN calificacion = 1 THEN 1 ELSE 0 END) AS rating_1,
  SUM(CASE WHEN calificacion = 2 THEN 1 ELSE 0 END) AS rating_2,
  SUM(CASE WHEN calificacion = 3 THEN 1 ELSE 0 END) AS rating_3,
  SUM(CASE WHEN calificacion = 4 THEN 1 ELSE 0 END) AS rating_4,
  SUM(CASE WHEN calificacion = 5 THEN 1 ELSE 0 END) AS rating_5
FROM reviews
GROUP BY establecimiento_id, mes
ORDER BY establecimiento_id, mes;

-- Consulta para obtener la información necesaria para actualizar los platillos estrellas
SELECT 
  v.establecimiento_id,
  to_char(v.fecha_visita, 'YYYY-MM') AS mes,
  p.id AS platillo_id,
  p.nombre,
  SUM(dv.cantidad) AS cantidad
FROM detalle_visitas dv
JOIN visitas v ON dv.visita_id = v.id
JOIN platillos p ON dv.platillo_id = p.id
GROUP BY v.establecimiento_id, mes, p.id, p.nombre
ORDER BY v.establecimiento_id, mes, cantidad DESC;
