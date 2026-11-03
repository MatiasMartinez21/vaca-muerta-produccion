-- 02_dimensiones.sql
-- Fecha de primera producción (oficial, del padrón), dimensión de pozos
-- (con operadora normalizada) y dimensión calendario.

-- Fecha de primera producción por pozo.
-- Fuente principal: el padrón oficial (una fila por pozo). Como ~1% de los pozos
-- no figura en el padrón, se usa como respaldo el primer mes con producción
-- efectiva del propio dataset, así ningún pozo queda sin "mes de vida".
CREATE OR REPLACE TABLE primera_prod AS
WITH pozos AS (
    SELECT DISTINCT id_pozo FROM stg_vaca_muerta
),
padron AS (
    SELECT
        CAST(idpozo AS BIGINT)                                    AS id_pozo,
        make_date(CAST(anio AS INTEGER), CAST(mes AS INTEGER), 1) AS f_padron
    FROM read_csv(getvariable('ruta_padron'), header = true, sample_size = -1)
),
primer_mes_con_prod AS (
    SELECT id_pozo, min(fecha) AS f_prod
    FROM stg_vaca_muerta
    WHERE coalesce(prod_pet_m3, 0) + coalesce(prod_gas_dam3, 0) > 0
    GROUP BY id_pozo
),
primera_aparicion AS (
    SELECT id_pozo, min(fecha) AS f_aparicion
    FROM stg_vaca_muerta
    GROUP BY id_pozo
)
SELECT
    pz.id_pozo,
    coalesce(p.f_padron, pm.f_prod, pa.f_aparicion) AS fecha_primera_produccion
FROM pozos pz
LEFT JOIN padron p               USING (id_pozo)
LEFT JOIN primer_mes_con_prod pm USING (id_pozo)
LEFT JOIN primera_aparicion pa   USING (id_pozo);

-- Dimensión de pozos: toma el atributo más reciente de cada pozo (arg_max por fecha)
-- y normaliza la operadora para unificar razones sociales del mismo grupo.
CREATE OR REPLACE TABLE dim_pozo AS
WITH base AS (
    SELECT
        id_pozo,
        arg_max(empresa, fecha)          AS empresa,
        arg_max(sigla, fecha)            AS sigla,
        arg_max(area_yacimiento, fecha)  AS area_yacimiento,
        arg_max(provincia, fecha)        AS provincia,
        arg_max(tipo_pozo, fecha)        AS tipo_pozo,
        arg_max(sub_tipo_recurso, fecha) AS sub_tipo_recurso,
        arg_max(lat, fecha)              AS lat,
        arg_max(lon, fecha)              AS lon
    FROM stg_vaca_muerta
    GROUP BY id_pozo
)
SELECT
    b.id_pozo,
    b.empresa,                                    -- razón social original (trazabilidad)
    -- Operadora normalizada: unifica, p. ej., "VISTA ENERGY ARGENTINA SAU"
    -- y "VISTA OIL & GAS ARGENTINA SAU" bajo un único nombre comercial.
    CASE
        WHEN b.empresa ILIKE 'YPF%'          THEN 'YPF'
        WHEN b.empresa ILIKE 'VISTA%'        THEN 'VISTA ENERGY'
        WHEN b.empresa ILIKE 'PLUSPETROL%'   THEN 'PLUSPETROL'
        WHEN b.empresa ILIKE 'PAN AMERICAN%' THEN 'PAN AMERICAN ENERGY'
        WHEN b.empresa ILIKE 'TOTAL%'        THEN 'TOTALENERGIES'
        WHEN b.empresa ILIKE 'SHELL%'        THEN 'SHELL'
        WHEN b.empresa ILIKE 'TECPETROL%'    THEN 'TECPETROL'
        WHEN b.empresa ILIKE 'EXXON%'        THEN 'EXXONMOBIL'
        WHEN b.empresa ILIKE 'CHEVRON%'      THEN 'CHEVRON'
        WHEN b.empresa ILIKE 'PAMPA%'        THEN 'PAMPA ENERGIA'
        WHEN b.empresa ILIKE 'PHOENIX%'      THEN 'PHOENIX GLOBAL RESOURCES'
        ELSE b.empresa
    END                                           AS operadora,
    b.sigla,
    b.area_yacimiento,
    b.provincia,
    b.tipo_pozo,
    b.sub_tipo_recurso,
    b.lat,
    b.lon,
    pp.fecha_primera_produccion,
    year(pp.fecha_primera_produccion)             AS anio_puesta_marcha
FROM base b
LEFT JOIN primera_prod pp USING (id_pozo);

-- Dimensión calendario (mensual) que cubre todo el rango de datos.
CREATE OR REPLACE TABLE dim_calendario AS
SELECT
    f::DATE              AS fecha,
    year(f)              AS anio,
    month(f)             AS mes,
    'T' || quarter(f)    AS trimestre,
    strftime(f, '%Y-%m') AS anio_mes
FROM (
    SELECT unnest(generate_series(lo, hi, INTERVAL 1 MONTH)) AS f
    FROM (SELECT min(fecha) AS lo, max(fecha) AS hi FROM stg_vaca_muerta)
);
