//
// *** Consultas para la colección "estadisticas_establecimientos" ***
//

// Encontrar registros donde el consumo total sea mayor a un valor específico
db["estadisticas_establecimientos"].find({
  "Consumo total": { $gt: 100 },
});

// Obtener el total de visitas y el consumo total agrupado por establecimiento
db["estadisticas_establecimientos"].aggregate([
  {
    $group: {
      _id: "$establecimiento_id",
      totalVisitas: { $sum: "$visitas_totales" },
      totalConsumo: { $sum: "$Consumo total" },
    },
  },
  { $sort: { totalVisitas: -1 } },
]);

// Calcular el consumo promedio por mes a lo largo de todos los establecimientos
db["estadisticas_establecimientos"].aggregate([
  {
    $group: {
      _id: "$mes",
      avgConsumo: { $avg: "$Consumo total" },
    },
  },
  { $sort: { _id: 1 } },
]);

//
// *** Consultas para la colección "estadisticas_reviews" ***
//

// Obtener todos los registros de reviews de un establecimiento específico
db["estadisticas_reviews"].find({ establecimiento_id: 1 });

// Buscar registros con calificación promedio menor a un número específico.
db["estadisticas_reviews"].find({
  promedio_calificacion: { $lt: 3 },
});

// Calcular la calificación promedio global por establecimiento y el total de reviews
db["estadisticas_reviews"].aggregate([
  {
    $group: {
      _id: "$establecimiento_id",
      avgRating: { $avg: "$promedio_calificacion" },
      totalReviews: { $sum: "$total_reviews" },
    },
  },
  { $sort: { avgRating: -1 } },
]);

// Extraer documentos donde la distribución de calificaciones tenga reviews de 5 estrellas
db["estadisticas_reviews"].aggregate([
  {
    $project: {
      establecimiento_id: 1,
      mes: 1,
      reviews5: "$distribucion_calificaciones.5",
    },
  },
  { $match: { reviews5: { $gt: 0 } } },
]);

//
// *** Consultas para la colección "platillos_estrella" ***
//

// Buscar registros de un establecimiento en un mes específico
db["platillos_estrella"].find({
  establecimiento_id: 1,
  mes: "2024-02",
});

// Obtener el total de unidades vendidas por platillo en todos los documentos
db["platillos_estrella"].aggregate([
  { $unwind: "$platillos" },
  {
    $group: {
      _id: "$platillos.platillo_id",
      nombre: { $first: "$platillos.nombre" },
      totalCantidad: { $sum: "$platillos.cantidad" },
    },
  },
  { $sort: { totalCantidad: -1 } },
]);

// Calcular ventas totales por mes y establecimiento
db["platillos_estrella"].aggregate([
  { $unwind: "$platillos" },
  {
    $group: {
      _id: { establecimiento_id: "$establecimiento_id", mes: "$mes" },
      totalVentas: { $sum: "$platillos.cantidad" },
    },
  },
  { $sort: { "_id.mes": 1 } },
]);
