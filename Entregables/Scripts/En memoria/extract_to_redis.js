import pg from 'pg';
import { createClient } from 'redis';
import fs from 'fs';

// Configuración de conexión a PostgreSQL
const pgConfig = {
  user: 'postgres',
  host: 'localhost',
  database: 'restaurant_db', // Cambia esto al nombre de tu base de datos
  password: 'postgres',      // Cambia esto a tu contraseña
  port: 5432,
};

// Configuración de conexión a Redis, base de dato
const redisConfig = {
  url: 'redis://localhost:6379',
};

// Función principal
async function main() {
  // Conectar a PostgreSQL
  const pgClient = new pg.Client(pgConfig);
  await pgClient.connect();
  console.log('Conectado a PostgreSQL');

  // Conectar a Redis
  const redisClient = createClient(redisConfig);
  redisClient.on('error', (err) => console.log('Error de Redis:', err));
  await redisClient.connect();
  console.log('Conectado a Redis');

  try {
    // Crear archivo para comandos Redis
    const redisCommands = fs.createWriteStream('redis_commands.txt');
    
    // 1. Extraer establecimientos y sus horarios
    console.log('\n1. Extrayendo establecimientos y horarios...');
    const establecimientos = await pgClient.query(`
      SELECT id, nombre, categoria, hora_apertura, hora_cierre, dias_laborales, telefono, rating
      FROM establecimientos
    `);
    
    // Convertir hora de cierre a minutos desde medianoche para ordenar
    for (const est of establecimientos.rows) {
      const horasCierre = est.hora_cierre.split(':');
      let minutosCierre = parseInt(horasCierre[0]) * 60 + parseInt(horasCierre[1]);
      
      // Si cierra después de medianoche (por ejemplo, 01:00), ajustar
      if (minutosCierre < 300 && horasCierre[0] < 5) {
        minutosCierre += 1440; // Añadir 24 horas en minutos
      }
      
      // Añadir al conjunto ordenado de establecimientos por hora de cierre
      await redisClient.zAdd('establecimientos:por_hora_cierre', {
        score: minutosCierre,
        value: est.id.toString()
      });
      
      // Guardar comando para archivo
      redisCommands.write(`ZADD establecimientos:por_hora_cierre ${minutosCierre} "${est.id}"\n`);
      
      // Guardar detalles del establecimiento
      await redisClient.hSet(`establecimiento:${est.id}`, {
        nombre: est.nombre,
        categoria: est.categoria || '',
        hora_apertura: est.hora_apertura || '',
        hora_cierre: est.hora_cierre || '',
        dias_laborales: est.dias_laborales || '',
        telefono: est.telefono || '',
        rating: est.rating?.toString() || ''
      });
      
      // Guardar comando para archivo
      redisCommands.write(`HSET establecimiento:${est.id} nombre "${est.nombre}" categoria "${est.categoria || ''}" hora_apertura "${est.hora_apertura || ''}" hora_cierre "${est.hora_cierre || ''}" dias_laborales "${est.dias_laborales || ''}" telefono "${est.telefono || ''}" rating "${est.rating || ''}"\n`);
    }
    console.log(`Cargados ${establecimientos.rows.length} establecimientos en Redis`);
    
    // 2. Extraer promociones
    console.log('\n2. Extrayendo promociones...');
    const promociones = await pgClient.query(`
      SELECT id, oferta, fecha_inicio, fecha_expiracion, establecimiento_id
      FROM promociones
      WHERE fecha_expiracion >= CURRENT_DATE
    `);
    
    // Fecha actual para comparar
    const fechaActual = new Date();
    
    for (const promo of promociones.rows) {
      // Convertir fecha de expiración a timestamp Unix
      const fechaExp = new Date(promo.fecha_expiracion);
      const timestampExp = Math.floor(fechaExp.getTime() / 1000);
      
      // Añadir a conjunto ordenado de promociones activas
      await redisClient.zAdd('promociones:activas', {
        score: timestampExp,
        value: promo.id.toString()
      });
      
      // Guardar comando para archivo
      redisCommands.write(`ZADD promociones:activas ${timestampExp} "${promo.id}"\n`);
      
      // Guardar detalles de la promoción
      await redisClient.hSet(`promocion:${promo.id}`, {
        oferta: promo.oferta,
        fecha_inicio: promo.fecha_inicio?.toISOString().split('T')[0] || '',
        fecha_expiracion: promo.fecha_expiracion?.toISOString().split('T')[0] || '',
        establecimiento_id: promo.establecimiento_id?.toString() || ''
      });
      
      // Guardar comando para archivo
      redisCommands.write(`HSET promocion:${promo.id} oferta "${promo.oferta}" fecha_inicio "${promo.fecha_inicio?.toISOString().split('T')[0] || ''}" fecha_expiracion "${promo.fecha_expiracion?.toISOString().split('T')[0] || ''}" establecimiento_id "${promo.establecimiento_id || ''}"\n`);
      
      // Añadir promoción al conjunto de promociones del establecimiento
      if (promo.establecimiento_id) {
        await redisClient.sAdd(`establecimiento:${promo.establecimiento_id}:promociones`, promo.id.toString());
        redisCommands.write(`SADD establecimiento:${promo.establecimiento_id}:promociones "${promo.id}"\n`);
      }
    }
    console.log(`Cargadas ${promociones.rows.length} promociones en Redis`);
    
    // 3. Extraer visitas de establecimientos
    console.log('\n3. Extrayendo datos de visitas...');
    // Simulamos datos de visitas basados en pedidos o reservas
    const visitas = await pgClient.query(`
      SELECT establecimiento_id, COUNT(*) as total_visitas
      FROM pedidos
      GROUP BY establecimiento_id
    `);
    
    for (const visita of visitas.rows) {
      // Añadir al conjunto ordenado de establecimientos por visitas
      await redisClient.zAdd('establecimientos:por_visitas', {
        score: parseInt(visita.total_visitas),
        value: visita.establecimiento_id.toString()
      });
      
      // Guardar comando para archivo
      redisCommands.write(`ZADD establecimientos:por_visitas ${visita.total_visitas} "${visita.establecimiento_id}"\n`);
    }
    console.log(`Cargados datos de visitas para ${visitas.rows.length} establecimientos en Redis`);
    
    // También podemos extraer visitas por mes
    const visitasPorMes = await pgClient.query(`
      SELECT establecimiento_id, 
             TO_CHAR(fecha_pedido, 'YYYYMM') as mes,
             COUNT(*) as total_visitas
      FROM pedidos
      WHERE fecha_pedido >= CURRENT_DATE - INTERVAL '3 months'
      GROUP BY establecimiento_id, TO_CHAR(fecha_pedido, 'YYYYMM')
    `);
    
    for (const visita of visitasPorMes.rows) {
      // Añadir al conjunto ordenado de establecimientos por visitas mensuales
      await redisClient.zAdd(`establecimientos:por_visitas:${visita.mes}`, {
        score: parseInt(visita.total_visitas),
        value: visita.establecimiento_id.toString()
      });
      
      // Guardar comando para archivo
      redisCommands.write(`ZADD establecimientos:por_visitas:${visita.mes} ${visita.total_visitas} "${visita.establecimiento_id}"\n`);
    }
    console.log(`Cargados datos de visitas mensuales para ${visitasPorMes.rows.length} registros en Redis`);
    
    // 4. Extraer platillos más consumidos por establecimiento
    console.log('\n4. Extrayendo platillos más consumidos...');
    const platillosConsumidos = await pgClient.query(`
      SELECT p.establecimiento_id, dp.comida_id, c.nombre, c.precio, c.descripcion,
             COUNT(*) as total_consumos
      FROM detalle_pedidos dp
      JOIN pedidos p ON dp.pedido_id = p.id
      JOIN comidas c ON dp.comida_id = c.id
      GROUP BY p.establecimiento_id, dp.comida_id, c.nombre, c.precio, c.descripcion
    `);
    
    for (const platillo of platillosConsumidos.rows) {
      // Añadir al conjunto ordenado de platillos por consumo para cada establecimiento
      await redisClient.zAdd(`establecimiento:${platillo.establecimiento_id}:platillos_por_consumo`, {
        score: parseInt(platillo.total_consumos),
        value: platillo.comida_id.toString()
      });
      
      // Guardar comando para archivo
      redisCommands.write(`ZADD establecimiento:${platillo.establecimiento_id}:platillos_por_consumo ${platillo.total_consumos} "${platillo.comida_id}"\n`);
      
      // Guardar detalles del platillo
      await redisClient.hSet(`platillo:${platillo.comida_id}`, {
        nombre: platillo.nombre,
        precio: platillo.precio?.toString() || '',
        descripcion: platillo.descripcion || ''
      });
      
      // Guardar comando para archivo
      redisCommands.write(`HSET platillo:${platillo.comida_id} nombre "${platillo.nombre}" precio "${platillo.precio || ''}" descripcion "${platillo.descripcion || ''}"\n`);
    }
    console.log(`Cargados ${platillosConsumidos.rows.length} registros de consumo de platillos en Redis`);
    
    redisCommands.end();
    console.log('\nTodos los comandos Redis han sido guardados en redis_commands.txt');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    // Cerrar conexiones
    await pgClient.end();
    await redisClient.quit();
    console.log('\nConexiones cerradas');
  }
}

main().catch(console.error);