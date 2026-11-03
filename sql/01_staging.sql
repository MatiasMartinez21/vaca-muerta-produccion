-- 01_staging.sql
-- Carga cruda del CSV de producción no convencional, recorte a Vaca Muerta
-- y tipado explícito de columnas (el CSV viene todo como texto).

CREATE OR REPLACE TABLE stg_vaca_muerta AS
SELECT
    CAST(idpozo AS BIGINT)                                    AS id_pozo,
    CAST(anio   AS INTEGER)                                   AS anio,
    CAST(mes    AS INTEGER)                                   AS mes,
    make_date(CAST(anio AS INTEGER), CAST(mes AS INTEGER), 1) AS fecha,
    TRY_CAST(prod_pet  AS DOUBLE)                             AS prod_pet_m3,    -- petróleo [m3]
    TRY_CAST(prod_gas  AS DOUBLE)                             AS prod_gas_dam3,  -- gas [miles de m3]
    TRY_CAST(prod_agua AS DOUBLE)                             AS prod_agua_m3,   -- agua [m3]
    TRY_CAST(iny_agua  AS DOUBLE)                             AS iny_agua_m3,
    TRY_CAST(iny_gas   AS DOUBLE)                             AS iny_gas_dam3,
    TRY_CAST(tef       AS DOUBLE)                             AS dias_efectivos, -- días con producción en el mes
    trim(empresa)                                            AS empresa,
    trim(sigla)                                              AS sigla,
    lower(trim(formacion))                                   AS formacion,
    trim(areayacimiento)                                     AS area_yacimiento,
    trim(cuenca)                                             AS cuenca,
    trim(provincia)                                          AS provincia,
    trim(tipopozo)                                           AS tipo_pozo,
    trim(tipoestado)                                         AS tipo_estado,
    trim(sub_tipo_recurso)                                   AS sub_tipo_recurso,
    TRY_CAST(coordenadax AS DOUBLE)                          AS lon,            -- longitud
    TRY_CAST(coordenaday AS DOUBLE)                          AS lat             -- latitud
FROM read_csv(getvariable('ruta_prod'), header = true, sample_size = -1)
WHERE lower(trim(formacion)) = 'vaca muerta';
