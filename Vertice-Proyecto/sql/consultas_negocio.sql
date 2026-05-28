-- Entrega 2 - Proyecto Final Betek - Consultas SQL 
-- Gestión de Proyectos – Empresa de Ingeniería
-- Nombres: Yessenia Arboleda Sanchez, Alex Cano Garcia, Melba Rocio Torres Varon, Karen Daniela Marin

USE ingenieria_proyectos;

-- PREGUNTAS

-- 1. ¿Cuáles son los 5 proyectos con mayor desviación entre presupuesto y costos reales registrados?

SELECT 
    p.id_proyecto,
    p.nombre,
    p.presupuesto,
    IFNULL(SUM(c.valor), 0) AS costo_real,
    (p.presupuesto - IFNULL(SUM(c.valor), 0)) AS desviacion
FROM
    PROYECTOS p
        LEFT JOIN
    COSTOS c ON p.id_proyecto = c.id_proyecto
GROUP BY p.id_proyecto , p.nombre , p.presupuesto
ORDER BY ABS(desviacion) DESC
LIMIT 5;


-- 2. ¿Qué empleados han trabajado 7 o más horas adicionales a las estimadas en sus tareas, y en qué proyectos participan?

SELECT 
    e.nombre AS empleado,
    p.nombre AS proyecto,
    SUM(t.horas_estimadas) AS horas_estimadas,
    SUM(t.horas_reales) AS horas_reales,
    SUM(t.horas_reales) - SUM(t.horas_estimadas) AS horas_extra
FROM
    TAREAS t
        INNER JOIN
    EMPLEADOS e ON t.id_empleado = e.id_empleado
        INNER JOIN
    HISTORIAS_USUARIO h ON t.id_historia = h.id_historia
        INNER JOIN
    SPRINTS s ON h.id_sprint = s.id_sprint
        INNER JOIN
    PROYECTOS p ON s.id_proyecto = p.id_proyecto
GROUP BY e.id_empleado , e.nombre , p.id_proyecto , p.nombre
HAVING SUM(t.horas_reales) > SUM(t.horas_estimadas)
    AND (SUM(t.horas_reales) - SUM(t.horas_estimadas)) >= 7
ORDER BY horas_extra DESC;


-- 3. ¿Cuál es el costo total ejecutado en las categorías de Personal y Materiales para cada proyecto?

SELECT 
    p.nombre AS nombre_proyecto,
    c.categoria,
    SUM(c.valor) AS costo_total
FROM
    PROYECTOS p
        INNER JOIN
    COSTOS c ON c.id_proyecto = p.id_proyecto
WHERE
    c.categoria IN ('Personal' , 'Materiales')
GROUP BY p.id_proyecto , p.nombre , c.categoria
ORDER BY p.nombre , costo_total DESC;


-- 4. ¿Qué clientes concentran la mayor cantidad de proyectos activos y cuál es el valor total contratado con cada uno?

SELECT 
    cl.id_cliente,
    cl.nombre AS nombre_cliente,
    cl.empresa,
    COUNT(p.id_proyecto) AS total_proyectos_activos,
    SUM(p.presupuesto) AS valor_total_contratado,
    AVG(p.presupuesto) AS promedio_por_proyecto
FROM
    CLIENTES cl
        INNER JOIN
    PROYECTOS p ON p.id_cliente = cl.id_cliente
WHERE
    p.estado = 'En ejecución'
GROUP BY cl.id_cliente , cl.nombre , cl.empresa
ORDER BY total_proyectos_activos DESC , valor_total_contratado DESC;


-- 5. ¿Cuántas historias de usuario fueron completadas vs. pendientes por sprint en el proyecto Construcción Puente Vial Honda?

SELECT 
    s.numero_sprint,
    s.objetivo,
    p.nombre AS proyecto,
    COUNT(hu.id_historia) AS total_historias,
    SUM(CASE
        WHEN hu.estado = 'Completada' THEN 1
        ELSE 0
    END) AS historias_completadas,
    SUM(CASE
        WHEN hu.estado != 'Completada' THEN 1
        ELSE 0
    END) AS historias_pendientes
FROM
    SPRINTS s
        INNER JOIN
    PROYECTOS p ON p.id_proyecto = s.id_proyecto
        LEFT JOIN
    HISTORIAS_USUARIO hu ON hu.id_sprint = s.id_sprint
WHERE
    p.id_proyecto = 1
GROUP BY s.id_sprint , s.numero_sprint , s.objetivo , p.nombre
ORDER BY s.numero_sprint;


-- 6. ¿Qué recursos representan el mayor gasto acumulado en asignaciones a proyectos?

SELECT 
    r.nombre AS recurso,
    r.tipo,
    r.unidad_medida,
    r.costo_unitario,
    COUNT(ar.id_asignacion) AS veces_asignado,
    ROUND(SUM(ar.cantidad), 2) AS cantidad_total,
    SUM(ar.costo_calculado) AS gasto_total
FROM
    RECURSOS r
        JOIN
    ASIGNACION_RECURSOS ar ON ar.id_recurso = r.id_recurso
GROUP BY r.id_recurso , r.nombre , r.tipo , r.unidad_medida , r.costo_unitario
ORDER BY gasto_total DESC
LIMIT 10;


-- 7. ¿Cuáles son los empleados más asignados y cuál es su tasa de cumplimiento (tareas completadas /total)?

SELECT 
    e.nombre AS empleado,
    e.cargo,
    e.especialidad,
    COUNT(t.id_tarea) AS total_tareas,
    SUM(CASE
        WHEN t.estado = 'Completada' THEN 1
        ELSE 0
    END) AS tareas_completadas,
    SUM(CASE
        WHEN t.estado = 'Bloqueada' THEN 1
        ELSE 0
    END) AS tareas_bloqueadas,
    ROUND(SUM(t.horas_reales), 1) AS horas_reales_totales
FROM
    EMPLEADOS e
        JOIN
    TAREAS t ON t.id_empleado = e.id_empleado
GROUP BY e.id_empleado , e.nombre , e.cargo , e.especialidad
ORDER BY total_tareas DESC
LIMIT 15;


-- 8. ¿Qué proyectos tienen etapas vencidas sin finalizar, cuántas etapas acumulan y cuántos días lleva la más atrasada?

SELECT 
    p.nombre AS proyecto,
    cl.empresa AS cliente,
    COUNT(ep.id_etapa) AS etapas_vencidas,
    MAX(DATEDIFF(CURDATE(), ep.fecha_fin)) AS max_dias_vencida
FROM
    ETAPAS_PROYECTO ep
        JOIN
    PROYECTOS p ON p.id_proyecto = ep.id_proyecto
        JOIN
    CLIENTES cl ON cl.id_cliente = p.id_cliente
WHERE
    ep.fecha_fin < CURDATE()
        AND p.estado <> 'Finalizado'
GROUP BY p.id_proyecto , p.nombre , cl.empresa
ORDER BY max_dias_vencida DESC;


-- 9. ¿Cuál es la distribución de proyectos por estado y cuánto representa cada estado en valor presupuestado?

SELECT 
    estado,
    COUNT(*) AS num_proyectos,
    SUM(presupuesto) AS presupuesto_total,
    AVG(presupuesto) AS presupuesto_promedio,
    MIN(presupuesto) AS proyecto_menor,
    MAX(presupuesto) AS proyecto_mayor
FROM
    PROYECTOS
GROUP BY estado
ORDER BY num_proyectos DESC;


-- 10. ¿Qué especialidades de ingeniería concentran más horas trabajadas y cuántos empleados tiene cada una?

SELECT 
    e.especialidad,
    COUNT(DISTINCT e.id_empleado) AS num_empleados,
    SUM(t.horas_reales) AS total_horas_reales,
    SUM(t.horas_estimadas) AS total_horas_estimadas,
    ROUND(AVG(t.horas_reales), 1) AS promedio_horas_por_tarea
FROM
    TAREAS t
        JOIN
    EMPLEADOS e ON e.id_empleado = t.id_empleado
GROUP BY e.especialidad
ORDER BY total_horas_reales DESC;

