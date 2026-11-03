-- 03_hechos.sql
-- Tabla de hechos: producción mensual por pozo + caudales diarios,
-- indicadores técnicos (GOR y corte de agua) y mes de vida del pozo.

CREATE OR REPLACE TABLE fact_produccion AS
SELECT
    s.id_pozo,
    s.fecha,
    s.prod_pet_m3,
    s.prod_gas_dam3,
    s.prod_agua_m3,
    s.iny_agua_m3,
    s.dias_efectivos,
    -- Caudales diarios: normalizan la producción por los días efectivos del mes.
    CASE WHEN s.dias_efectivos > 0 THEN s.prod_pet_m3   / s.dias_efectivos END AS pet_m3_dia,
    CASE WHEN s.dias_efectivos > 0 THEN s.prod_gas_dam3 / s.dias_efectivos END AS gas_dam3_dia,
    -- Indicadores técnicos del reservorio.
    CASE WHEN s.prod_pet_m3 > 0
         THEN (s.prod_gas_dam3 * 1000.0) / s.prod_pet_m3 END                   AS gor_m3_m3,   -- gas[m3] / petróleo[m3]
    CASE WHEN (s.prod_pet_m3 + s.prod_agua_m3) > 0
         THEN s.prod_agua_m3 / (s.prod_pet_m3 + s.prod_agua_m3) END            AS corte_agua,  -- fracción 0-1
    -- Mes de vida del pozo: 0 = primer mes de producción. Es la clave de las curvas tipo.
    datediff('month', p.fecha_primera_produccion, s.fecha)                     AS mes_vida
FROM stg_vaca_muerta s
LEFT JOIN primera_prod p USING (id_pozo);
