-- ============================================================================
-- File: nutrizionista_query_catalog_mysql.sql
-- Target: MySQL 8.0+
-- Catalogo di query per il database `nutrizionista`.
--
-- IMPORTANTE:
--   Questo file è una RACCOLTA DI ESEMPI, non uno script da eseguire tutto
--   in sequenza. Contiene volutamente INSERT, UPDATE e DELETE.
--   Copiare/eseguire soltanto le query necessarie.
-- ============================================================================

USE nutrizionista;

-- ============================================================================
-- 4. VARIABILI DI ESEMPIO
-- ============================================================================
-- Modificare liberamente prima di eseguire le query successive.

SET @data_rif = '2026-09-09';
SET @data_da = '2026-09-01';
SET @data_a = '2026-09-30';
SET @giornata_id = NULL;
SET @pasto_id = NULL;
SET @prodotto_id = NULL;
SET @integratore_id = NULL;
SET @rilevazione_id = NULL;
SET @attivita_id = NULL;
SET @assunzione_id = NULL;
SET @osservazione_id = NULL;


-- ============================================================================
-- 5. INSERT
-- ============================================================================

-- 5.1 Inserire una giornata
INSERT INTO diario_giornaliero (
  giorno,
  data,
  tipo_giornata,
  giornata_chiusa,
  target_kcal,
  target_proteine_g,
  target_carboidrati_g,
  target_grassi_g,
  target_fibre_g,
  note
) VALUES (
  'Mercoledi 9 settembre 2026',
  @data_rif,
  'Non definita',
  0,
  2200,
  150,
  220,
  70,
  30,
  NULL
);

SET @giornata_id = LAST_INSERT_ID();


-- 5.2 Upsert della giornata per data
INSERT INTO diario_giornaliero (
  giorno,
  data,
  tipo_giornata,
  giornata_chiusa
) VALUES (
  DATE_FORMAT(@data_rif, '%Y-%m-%d'),
  @data_rif,
  'Non definita',
  0
)
ON DUPLICATE KEY UPDATE
  giorno = VALUES(giorno),
  aggiornato = CURRENT_TIMESTAMP;

SELECT id
INTO @giornata_id
FROM diario_giornaliero
WHERE data = @data_rif;


-- 5.3 Inserire un pasto
INSERT INTO pasti (
  pasto,
  data_ora,
  tipo,
  contesto,
  libero_sociale,
  fame_nervosa,
  giornata_id,
  note
) VALUES (
  'Pranzo',
  CONCAT(@data_rif, ' 13:00:00'),
  'Pranzo',
  'Casa',
  0,
  0,
  @giornata_id,
  NULL
);

SET @pasto_id = LAST_INSERT_ID();


-- 5.4 Inserire un prodotto alimentare
INSERT INTO alimenti_prodotti (
  alimento_prodotto,
  marca,
  categoria,
  stato,
  kcal_100g,
  proteine_100g,
  carboidrati_100g,
  grassi_100g,
  fibre_100g,
  zuccheri_100g,
  sale_100g,
  porzione_tipica_g,
  kcal_porzione,
  fonte,
  ultimo_controllo,
  verificato
) VALUES (
  'Prodotto di esempio',
  'Marca di esempio',
  'Proteina',
  'Ammesso',
  150,
  20,
  2,
  6,
  0,
  1,
  0.5,
  100,
  150,
  'Etichetta',
  @data_rif,
  1
);

SET @prodotto_id = LAST_INSERT_ID();


-- 5.5 Inserire una voce alimentare con valori già riferiti alla quantità consumata
INSERT INTO voci_alimentari (
  voce,
  data_ora,
  quantita,
  unita,
  descrizione_quantita,
  peso,
  kcal,
  proteine_g,
  carboidrati_g,
  grassi_g,
  fibre_g,
  zuccheri_g,
  alcol_g,
  fonte_valori,
  affidabilita,
  giornata_id,
  pasto_id,
  prodotto_id,
  note
) VALUES (
  'Prodotto di esempio - 170 g',
  CONCAT(@data_rif, ' 13:05:00'),
  170,
  'g',
  '170 g',
  'Crudo',
  255,
  34,
  3.4,
  10.2,
  0,
  1.7,
  0,
  'Prodotto registrato',
  'Alta',
  @giornata_id,
  @pasto_id,
  @prodotto_id,
  NULL
);


-- 5.6 Inserire una voce calcolando kcal/macro dai valori per 100 g del prodotto
SET @quantita_g = 170;

INSERT INTO voci_alimentari (
  voce,
  data_ora,
  quantita,
  unita,
  peso,
  kcal,
  proteine_g,
  carboidrati_g,
  grassi_g,
  fibre_g,
  zuccheri_g,
  fonte_valori,
  affidabilita,
  giornata_id,
  pasto_id,
  prodotto_id
)
SELECT
  CONCAT(ap.alimento_prodotto, ' - ', @quantita_g, ' g'),
  CONCAT(@data_rif, ' 13:10:00'),
  @quantita_g,
  'g',
  'Crudo',
  ROUND(ap.kcal_100g * @quantita_g / 100, 3),
  ROUND(ap.proteine_100g * @quantita_g / 100, 3),
  ROUND(ap.carboidrati_100g * @quantita_g / 100, 3),
  ROUND(ap.grassi_100g * @quantita_g / 100, 3),
  ROUND(ap.fibre_100g * @quantita_g / 100, 3),
  ROUND(ap.zuccheri_100g * @quantita_g / 100, 3),
  'Prodotto registrato',
  CASE WHEN ap.verificato = 1 THEN 'Alta' ELSE 'Media' END,
  @giornata_id,
  @pasto_id,
  ap.id
FROM alimenti_prodotti ap
WHERE ap.id = @prodotto_id;


-- 5.7 Inserire una misura corporea
INSERT INTO peso_misure (
  rilevazione,
  data,
  peso_kg,
  vita_cm,
  fianchi_cm,
  torace_cm,
  massa_grassa_pct,
  massa_muscolare_kg,
  fonte,
  affidabilita,
  condizioni,
  giornata_id
) VALUES (
  'Rilevazione mattutina',
  @data_rif,
  80.200,
  86.5,
  NULL,
  NULL,
  NULL,
  NULL,
  'Bilancia',
  'Alta',
  'Mattina, a digiuno',
  @giornata_id
);

SET @rilevazione_id = LAST_INSERT_ID();


-- 5.8 Inserire un'attività
INSERT INTO attivita_allenamenti (
  attivita,
  data_ora,
  tipo,
  fonte,
  durata_min,
  distanza_km,
  passi,
  calorie_attive_dispositivo,
  fc_media,
  fc_max,
  intensita_percepita_0_10,
  giornata_id,
  note
) VALUES (
  'Camminata',
  CONCAT(@data_rif, ' 18:30:00'),
  'Camminata',
  'Apple Watch',
  45,
  4.3,
  5800,
  260,
  112,
  148,
  4,
  @giornata_id,
  NULL
);

SET @attivita_id = LAST_INSERT_ID();


-- 5.9 Inserire un integratore
INSERT INTO integratori (
  integratore,
  marca,
  dose,
  unita_dose,
  frequenza,
  momento,
  motivo,
  note_composizione,
  stato,
  data_inizio
) VALUES (
  'Integratore di esempio',
  'Marca di esempio',
  1,
  'capsula',
  '1 volta al giorno',
  'Dopo colazione',
  'Esempio',
  NULL,
  'Attivo',
  @data_rif
);

SET @integratore_id = LAST_INSERT_ID();


-- 5.10 Registrare una singola assunzione
INSERT INTO assunzioni (
  assunzione,
  data_ora,
  integratore_id,
  giornata_id,
  dose_assunta,
  unita,
  esito,
  note
) VALUES (
  'Assunzione integratore di esempio',
  CONCAT(@data_rif, ' 09:00:00'),
  @integratore_id,
  @giornata_id,
  1,
  'capsula',
  'Preso',
  NULL
);

SET @assunzione_id = LAST_INSERT_ID();


-- 5.11 Inserire un'osservazione/apprendimento
INSERT INTO osservazioni_apprendimenti (
  osservazione,
  data,
  tipo,
  fonte,
  dettaglio,
  apprendimento,
  azione_futura,
  valutazione_0_10,
  attiva,
  regola_stabile,
  giornata_id,
  pasto_id
) VALUES (
  'Buona sazietà a pranzo',
  @data_rif,
  'Sazieta',
  'Utente',
  'Sazietà elevata dopo il pasto.',
  'La composizione del pasto è risultata saziante.',
  'Valutare di riutilizzare una composizione simile.',
  8,
  1,
  0,
  @giornata_id,
  @pasto_id
);

SET @osservazione_id = LAST_INSERT_ID();


-- 5.12 Inserimento atomico di giornata + pasto + voci
-- Eseguire tutto il blocco in una singola sessione.
START TRANSACTION;

INSERT INTO diario_giornaliero (
  giorno,
  data,
  tipo_giornata
) VALUES (
  'Giornata transazionale',
  '2026-09-10',
  'Non definita'
)
ON DUPLICATE KEY UPDATE
  id = LAST_INSERT_ID(id);

SET @tx_giornata_id = LAST_INSERT_ID();

INSERT INTO pasti (
  pasto,
  data_ora,
  tipo,
  contesto,
  giornata_id
) VALUES (
  'Cena',
  '2026-09-10 20:00:00',
  'Cena',
  'Casa',
  @tx_giornata_id
);

SET @tx_pasto_id = LAST_INSERT_ID();

INSERT INTO voci_alimentari (
  voce,
  data_ora,
  quantita,
  unita,
  kcal,
  proteine_g,
  carboidrati_g,
  grassi_g,
  fonte_valori,
  affidabilita,
  giornata_id,
  pasto_id
) VALUES
  (
    'Voce A',
    '2026-09-10 20:05:00',
    100,
    'g',
    120,
    20,
    3,
    4,
    'Stima',
    'Media',
    @tx_giornata_id,
    @tx_pasto_id
  ),
  (
    'Voce B',
    '2026-09-10 20:06:00',
    80,
    'g',
    180,
    5,
    28,
    5,
    'Stima',
    'Media',
    @tx_giornata_id,
    @tx_pasto_id
  );

COMMIT;


-- ============================================================================
-- 6. SELECT / INTERROGAZIONE BASE
-- ============================================================================

-- 6.1 Tutte le giornate, dalla più recente
SELECT *
FROM diario_giornaliero
ORDER BY data DESC;


-- 6.2 Giornata specifica
SELECT *
FROM diario_giornaliero
WHERE data = @data_rif;


-- 6.3 Ultimi N giorni
SET @n_giorni = 14;

SELECT *
FROM diario_giornaliero
WHERE data >= CURRENT_DATE - INTERVAL @n_giorni DAY
ORDER BY data DESC;


-- 6.4 Giorni in un intervallo
SELECT *
FROM diario_giornaliero
WHERE data BETWEEN @data_da AND @data_a
ORDER BY data;


-- 6.5 Giornate non chiuse
SELECT *
FROM diario_giornaliero
WHERE giornata_chiusa = 0
ORDER BY data DESC;


-- 6.6 Giornate per tipo
SELECT *
FROM diario_giornaliero
WHERE tipo_giornata = 'Allenamento'
ORDER BY data DESC;


-- 6.7 Pasti di una giornata
SELECT p.*
FROM pasti p
JOIN diario_giornaliero d
  ON d.id = p.giornata_id
WHERE d.data = @data_rif
ORDER BY p.data_ora, p.id;


-- 6.8 Pasti di un certo tipo
SELECT p.*, d.data
FROM pasti p
LEFT JOIN diario_giornaliero d
  ON d.id = p.giornata_id
WHERE p.tipo = 'Cena'
ORDER BY p.data_ora DESC;


-- 6.9 Pasti consumati fuori casa
SELECT p.*, d.data
FROM pasti p
LEFT JOIN diario_giornaliero d
  ON d.id = p.giornata_id
WHERE p.contesto IN ('Fuori', 'Ristorante', 'Delivery')
ORDER BY p.data_ora DESC;


-- 6.10 Pasti liberi/sociali
SELECT p.*, d.data
FROM pasti p
LEFT JOIN diario_giornaliero d
  ON d.id = p.giornata_id
WHERE p.libero_sociale = 1
ORDER BY p.data_ora DESC;


-- 6.11 Pasti con fame nervosa
SELECT p.*, d.data
FROM pasti p
LEFT JOIN diario_giornaliero d
  ON d.id = p.giornata_id
WHERE p.fame_nervosa = 1
ORDER BY p.data_ora DESC;


-- 6.12 Dettaglio di un pasto con tutte le voci
SELECT
  p.id AS pasto_id,
  p.pasto,
  p.tipo,
  p.data_ora AS pasto_data_ora,
  v.id AS voce_id,
  v.voce,
  v.quantita,
  v.unita,
  v.kcal,
  v.proteine_g,
  v.carboidrati_g,
  v.grassi_g,
  v.fibre_g,
  v.zuccheri_g,
  v.alcol_g,
  ap.alimento_prodotto,
  ap.marca
FROM pasti p
LEFT JOIN voci_alimentari v
  ON v.pasto_id = p.id
LEFT JOIN alimenti_prodotti ap
  ON ap.id = v.prodotto_id
WHERE p.id = @pasto_id
ORDER BY v.data_ora, v.id;


-- 6.13 Tutte le voci di una giornata
SELECT
  v.*,
  p.tipo AS tipo_pasto,
  p.pasto,
  ap.alimento_prodotto,
  ap.marca
FROM voci_alimentari v
LEFT JOIN pasti p
  ON p.id = v.pasto_id
LEFT JOIN alimenti_prodotti ap
  ON ap.id = v.prodotto_id
JOIN diario_giornaliero d
  ON d.id = v.giornata_id
WHERE d.data = @data_rif
ORDER BY COALESCE(v.data_ora, p.data_ora), v.id;


-- 6.14 Ricerca testuale nelle voci
SET @testo = '%salmone%';

SELECT *
FROM voci_alimentari
WHERE voce LIKE @testo
   OR descrizione_quantita LIKE @testo
   OR note LIKE @testo
ORDER BY data_ora DESC;


-- 6.15 Catalogo prodotti
SELECT *
FROM alimenti_prodotti
ORDER BY alimento_prodotto, marca;


-- 6.16 Prodotti per categoria
SELECT *
FROM alimenti_prodotti
WHERE categoria = 'Proteina'
ORDER BY alimento_prodotto;


-- 6.17 Prodotti preferiti
SELECT *
FROM alimenti_prodotti
WHERE stato = 'Preferito'
ORDER BY alimento_prodotto;


-- 6.18 Prodotti esclusi
SELECT *
FROM alimenti_prodotti
WHERE stato = 'Escluso'
ORDER BY alimento_prodotto;


-- 6.19 Prodotti non verificati
SELECT *
FROM alimenti_prodotti
WHERE verificato = 0
ORDER BY ultimo_controllo IS NULL DESC, ultimo_controllo;


-- 6.20 Prodotti con controllo vecchio di almeno 6 mesi
SELECT *
FROM alimenti_prodotti
WHERE ultimo_controllo IS NULL
   OR ultimo_controllo < CURRENT_DATE - INTERVAL 6 MONTH
ORDER BY ultimo_controllo;


-- ============================================================================
-- 7. SELECT / ROLLUP NUTRIZIONALI
-- ============================================================================

-- 7.1 Totali di ogni pasto
SELECT *
FROM v_pasti_totali
ORDER BY data_ora DESC;


-- 7.2 Totale del singolo pasto
SELECT *
FROM v_pasti_totali
WHERE pasto_id = @pasto_id;


-- 7.3 Totali nutrizionali giornalieri
SELECT *
FROM v_diario_nutrizione
WHERE data = @data_rif;


-- 7.4 Totali nutrizionali per intervallo
SELECT *
FROM v_diario_nutrizione
WHERE data BETWEEN @data_da AND @data_a
ORDER BY data;


-- 7.5 Scostamento dai target
SELECT
  data,
  totale_kcal,
  target_kcal,
  totale_kcal - target_kcal AS delta_kcal,
  totale_proteine_g,
  target_proteine_g,
  totale_proteine_g - target_proteine_g AS delta_proteine_g,
  totale_carboidrati_g,
  target_carboidrati_g,
  totale_carboidrati_g - target_carboidrati_g AS delta_carboidrati_g,
  totale_grassi_g,
  target_grassi_g,
  totale_grassi_g - target_grassi_g AS delta_grassi_g,
  totale_fibre_g,
  target_fibre_g,
  totale_fibre_g - target_fibre_g AS delta_fibre_g
FROM v_diario_nutrizione
WHERE data BETWEEN @data_da AND @data_a
ORDER BY data;


-- 7.6 Percentuale raggiungimento target
SELECT
  data,
  ROUND(100 * totale_kcal / NULLIF(target_kcal, 0), 1) AS kcal_target_pct,
  ROUND(100 * totale_proteine_g / NULLIF(target_proteine_g, 0), 1)
    AS proteine_target_pct,
  ROUND(100 * totale_carboidrati_g / NULLIF(target_carboidrati_g, 0), 1)
    AS carboidrati_target_pct,
  ROUND(100 * totale_grassi_g / NULLIF(target_grassi_g, 0), 1)
    AS grassi_target_pct,
  ROUND(100 * totale_fibre_g / NULLIF(target_fibre_g, 0), 1)
    AS fibre_target_pct
FROM v_diario_nutrizione
WHERE data BETWEEN @data_da AND @data_a
ORDER BY data;


-- 7.7 Calorie per tipo di pasto nel giorno
SELECT
  p.tipo,
  ROUND(SUM(v.kcal), 2) AS kcal
FROM pasti p
JOIN diario_giornaliero d
  ON d.id = p.giornata_id
LEFT JOIN voci_alimentari v
  ON v.pasto_id = p.id
WHERE d.data = @data_rif
GROUP BY p.tipo
ORDER BY kcal DESC;


-- 7.8 Distribuzione percentuale delle calorie per pasto nel giorno
WITH kcal_per_pasto AS (
  SELECT
    p.id,
    p.pasto,
    p.tipo,
    SUM(v.kcal) AS kcal
  FROM pasti p
  JOIN diario_giornaliero d
    ON d.id = p.giornata_id
  LEFT JOIN voci_alimentari v
    ON v.pasto_id = p.id
  WHERE d.data = @data_rif
  GROUP BY p.id, p.pasto, p.tipo
),
totale AS (
  SELECT SUM(kcal) AS kcal_totali
  FROM kcal_per_pasto
)
SELECT
  k.id,
  k.pasto,
  k.tipo,
  k.kcal,
  ROUND(100 * k.kcal / NULLIF(t.kcal_totali, 0), 1) AS quota_kcal_pct
FROM kcal_per_pasto k
CROSS JOIN totale t
ORDER BY k.kcal DESC;


-- 7.9 Media giornaliera kcal e macro in un intervallo
SELECT
  ROUND(AVG(totale_kcal), 2) AS media_kcal,
  ROUND(AVG(totale_proteine_g), 2) AS media_proteine_g,
  ROUND(AVG(totale_carboidrati_g), 2) AS media_carboidrati_g,
  ROUND(AVG(totale_grassi_g), 2) AS media_grassi_g,
  ROUND(AVG(totale_fibre_g), 2) AS media_fibre_g
FROM v_diario_nutrizione
WHERE data BETWEEN @data_da AND @data_a;


-- 7.10 Minimo, massimo e media kcal
SELECT
  MIN(totale_kcal) AS kcal_min,
  MAX(totale_kcal) AS kcal_max,
  ROUND(AVG(totale_kcal), 2) AS kcal_media
FROM v_diario_nutrizione
WHERE data BETWEEN @data_da AND @data_a;


-- 7.11 Giorni sopra target kcal
SELECT
  data,
  totale_kcal,
  target_kcal,
  totale_kcal - target_kcal AS eccedenza_kcal
FROM v_diario_nutrizione
WHERE target_kcal IS NOT NULL
  AND totale_kcal > target_kcal
ORDER BY eccedenza_kcal DESC;


-- 7.12 Giorni sotto target proteico
SELECT
  data,
  totale_proteine_g,
  target_proteine_g,
  target_proteine_g - totale_proteine_g AS proteine_mancanti_g
FROM v_diario_nutrizione
WHERE target_proteine_g IS NOT NULL
  AND totale_proteine_g < target_proteine_g
ORDER BY proteine_mancanti_g DESC;


-- 7.13 Giorni con fibre sotto target
SELECT
  data,
  totale_fibre_g,
  target_fibre_g,
  target_fibre_g - totale_fibre_g AS fibre_mancanti_g
FROM v_diario_nutrizione
WHERE target_fibre_g IS NOT NULL
  AND totale_fibre_g < target_fibre_g
ORDER BY fibre_mancanti_g DESC;


-- 7.14 Totali settimanali, settimana ISO-like con WEEK(..., 3)
SELECT
  YEARWEEK(data, 3) AS anno_settimana,
  MIN(data) AS primo_giorno,
  MAX(data) AS ultimo_giorno,
  COUNT(*) AS giornate_registrate,
  ROUND(SUM(totale_kcal), 2) AS kcal_totali,
  ROUND(AVG(totale_kcal), 2) AS kcal_medie,
  ROUND(AVG(totale_proteine_g), 2) AS proteine_medie_g,
  ROUND(AVG(totale_carboidrati_g), 2) AS carboidrati_medi_g,
  ROUND(AVG(totale_grassi_g), 2) AS grassi_medi_g
FROM v_diario_nutrizione
GROUP BY YEARWEEK(data, 3)
ORDER BY anno_settimana DESC;


-- 7.15 Totali mensili
SELECT
  DATE_FORMAT(data, '%Y-%m') AS mese,
  COUNT(*) AS giornate_registrate,
  ROUND(SUM(totale_kcal), 2) AS kcal_totali,
  ROUND(AVG(totale_kcal), 2) AS kcal_medie,
  ROUND(AVG(totale_proteine_g), 2) AS proteine_medie_g,
  ROUND(AVG(totale_carboidrati_g), 2) AS carboidrati_medi_g,
  ROUND(AVG(totale_grassi_g), 2) AS grassi_medi_g,
  ROUND(AVG(totale_fibre_g), 2) AS fibre_medie_g
FROM v_diario_nutrizione
GROUP BY DATE_FORMAT(data, '%Y-%m')
ORDER BY mese DESC;


-- 7.16 Media mobile a 7 giorni delle kcal
SELECT
  data,
  totale_kcal,
  ROUND(
    AVG(totale_kcal) OVER (
      ORDER BY data
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),
    2
  ) AS media_mobile_7g_kcal
FROM v_diario_nutrizione
ORDER BY data;


-- 7.17 Media mobile a 7 giorni dei macro
SELECT
  data,
  ROUND(
    AVG(totale_proteine_g) OVER (
      ORDER BY data
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),
    2
  ) AS proteine_media_mobile_7g,
  ROUND(
    AVG(totale_carboidrati_g) OVER (
      ORDER BY data
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),
    2
  ) AS carboidrati_media_mobile_7g,
  ROUND(
    AVG(totale_grassi_g) OVER (
      ORDER BY data
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),
    2
  ) AS grassi_media_mobile_7g
FROM v_diario_nutrizione
ORDER BY data;


-- ============================================================================
-- 8. SELECT / ANALISI DEI PASTI
-- ============================================================================

-- 8.1 Pasti più calorici
SELECT *
FROM v_pasti_totali
ORDER BY totale_kcal DESC
LIMIT 20;


-- 8.2 Media kcal per tipo di pasto
SELECT
  tipo,
  COUNT(*) AS numero_pasti,
  ROUND(AVG(totale_kcal), 2) AS kcal_medie,
  ROUND(AVG(totale_proteine_g), 2) AS proteine_medie_g
FROM v_pasti_totali
GROUP BY tipo
ORDER BY kcal_medie DESC;


-- 8.3 Media sazietà per tipo di pasto
SELECT
  tipo,
  COUNT(*) AS numero_valutazioni,
  ROUND(AVG(sazieta_dopo_0_10), 2) AS sazieta_media
FROM pasti
WHERE sazieta_dopo_0_10 IS NOT NULL
GROUP BY tipo
ORDER BY sazieta_media DESC;


-- 8.4 Media gradimento per contesto
SELECT
  contesto,
  COUNT(*) AS numero_valutazioni,
  ROUND(AVG(gradimento_0_10), 2) AS gradimento_medio
FROM pasti
WHERE gradimento_0_10 IS NOT NULL
GROUP BY contesto
ORDER BY gradimento_medio DESC;


-- 8.5 Relazione fame prima / sazietà dopo
SELECT
  id,
  pasto,
  tipo,
  fame_prima_0_10,
  sazieta_dopo_0_10,
  sazieta_dopo_0_10 - fame_prima_0_10 AS delta_sazieta
FROM pasti
WHERE fame_prima_0_10 IS NOT NULL
  AND sazieta_dopo_0_10 IS NOT NULL
ORDER BY delta_sazieta DESC;


-- 8.6 Pasti con alta sazietà e calorie relativamente basse
SET @soglia_sazieta = 8;
SET @soglia_kcal = 600;

SELECT *
FROM v_pasti_totali
WHERE sazieta_dopo_0_10 >= @soglia_sazieta
  AND totale_kcal <= @soglia_kcal
ORDER BY sazieta_dopo_0_10 DESC, totale_kcal ASC;


-- 8.7 Pasti liberi/sociali: calorie medie
SELECT
  libero_sociale,
  COUNT(*) AS pasti,
  ROUND(AVG(totale_kcal), 2) AS kcal_medie
FROM v_pasti_totali
GROUP BY libero_sociale;


-- 8.8 Confronto casa vs fuori
SELECT
  CASE
    WHEN contesto = 'Casa' THEN 'Casa'
    ELSE 'Fuori casa'
  END AS macro_contesto,
  COUNT(*) AS pasti,
  ROUND(AVG(totale_kcal), 2) AS kcal_medie,
  ROUND(AVG(sazieta_dopo_0_10), 2) AS sazieta_media,
  ROUND(AVG(gradimento_0_10), 2) AS gradimento_medio
FROM v_pasti_totali
GROUP BY
  CASE
    WHEN contesto = 'Casa' THEN 'Casa'
    ELSE 'Fuori casa'
  END;


-- ============================================================================
-- 9. SELECT / ANALISI ALIMENTI E PRODOTTI
-- ============================================================================

-- 9.1 Prodotti più consumati per numero di voci
SELECT
  ap.id,
  ap.alimento_prodotto,
  ap.marca,
  COUNT(v.id) AS consumi
FROM alimenti_prodotti ap
JOIN voci_alimentari v
  ON v.prodotto_id = ap.id
GROUP BY ap.id, ap.alimento_prodotto, ap.marca
ORDER BY consumi DESC, ap.alimento_prodotto
LIMIT 50;


-- 9.2 Prodotti che hanno contribuito più kcal
SELECT
  ap.id,
  ap.alimento_prodotto,
  ap.marca,
  COUNT(v.id) AS consumi,
  ROUND(SUM(v.kcal), 2) AS kcal_totali
FROM alimenti_prodotti ap
JOIN voci_alimentari v
  ON v.prodotto_id = ap.id
GROUP BY ap.id, ap.alimento_prodotto, ap.marca
ORDER BY kcal_totali DESC
LIMIT 50;


-- 9.3 Proteine totali per prodotto
SELECT
  ap.alimento_prodotto,
  ap.marca,
  ROUND(SUM(v.proteine_g), 2) AS proteine_totali_g
FROM alimenti_prodotti ap
JOIN voci_alimentari v
  ON v.prodotto_id = ap.id
GROUP BY ap.id, ap.alimento_prodotto, ap.marca
ORDER BY proteine_totali_g DESC;


-- 9.4 Consumi del singolo prodotto
SELECT
  v.*,
  d.data,
  p.tipo AS tipo_pasto
FROM voci_alimentari v
LEFT JOIN diario_giornaliero d
  ON d.id = v.giornata_id
LEFT JOIN pasti p
  ON p.id = v.pasto_id
WHERE v.prodotto_id = @prodotto_id
ORDER BY v.data_ora DESC;


-- 9.5 Prodotti mai consumati
SELECT ap.*
FROM alimenti_prodotti ap
LEFT JOIN voci_alimentari v
  ON v.prodotto_id = ap.id
WHERE v.id IS NULL
ORDER BY ap.alimento_prodotto;


-- 9.6 Voci non collegate a un prodotto registrato
SELECT *
FROM voci_alimentari
WHERE prodotto_id IS NULL
ORDER BY data_ora DESC;


-- 9.7 Voci stimate
SELECT *
FROM voci_alimentari
WHERE fonte_valori = 'Stima'
ORDER BY data_ora DESC;


-- 9.8 Voci a bassa affidabilità
SELECT *
FROM voci_alimentari
WHERE affidabilita = 'Bassa'
ORDER BY data_ora DESC;


-- 9.9 Voci con macro mancanti
SELECT *
FROM voci_alimentari
WHERE kcal IS NULL
   OR proteine_g IS NULL
   OR carboidrati_g IS NULL
   OR grassi_g IS NULL
ORDER BY data_ora DESC;


-- 9.10 Densità proteica dei prodotti
SELECT
  id,
  alimento_prodotto,
  marca,
  kcal_100g,
  proteine_100g,
  ROUND(
    100 * proteine_100g / NULLIF(kcal_100g, 0),
    2
  ) AS g_proteine_per_100_kcal
FROM alimenti_prodotti
WHERE kcal_100g IS NOT NULL
  AND proteine_100g IS NOT NULL
ORDER BY g_proteine_per_100_kcal DESC;


-- 9.11 Prodotti con dati nutrizionali sospetti:
-- somma macro energetiche che eccede molto le kcal dichiarate.
SELECT
  id,
  alimento_prodotto,
  marca,
  kcal_100g,
  proteine_100g,
  carboidrati_100g,
  grassi_100g,
  ROUND(
    COALESCE(proteine_100g, 0) * 4
    + COALESCE(carboidrati_100g, 0) * 4
    + COALESCE(grassi_100g, 0) * 9,
    2
  ) AS kcal_stimate_da_macro
FROM alimenti_prodotti
WHERE kcal_100g IS NOT NULL
HAVING ABS(kcal_stimate_da_macro - kcal_100g) > 30
ORDER BY ABS(kcal_stimate_da_macro - kcal_100g) DESC;


-- ============================================================================
-- 10. SELECT / PESO E MISURE
-- ============================================================================

-- 10.1 Tutte le rilevazioni
SELECT *
FROM peso_misure
ORDER BY data DESC, id DESC;


-- 10.2 Ultima rilevazione disponibile
SELECT *
FROM peso_misure
ORDER BY data DESC, id DESC
LIMIT 1;


-- 10.3 Ultimo peso disponibile
SELECT
  data,
  peso_kg
FROM peso_misure
WHERE peso_kg IS NOT NULL
ORDER BY data DESC, id DESC
LIMIT 1;


-- 10.4 Differenza peso rispetto alla rilevazione precedente
WITH pesi AS (
  SELECT
    data,
    peso_kg,
    LAG(peso_kg) OVER (
      ORDER BY data, id
    ) AS peso_precedente
  FROM peso_misure
  WHERE peso_kg IS NOT NULL
)
SELECT
  data,
  peso_kg,
  peso_precedente,
  ROUND(peso_kg - peso_precedente, 3) AS delta_kg
FROM pesi
ORDER BY data DESC;


-- 10.5 Variazione totale di peso nell'intervallo
WITH ordinati AS (
  SELECT
    data,
    peso_kg,
    ROW_NUMBER() OVER (ORDER BY data, id) AS rn_asc,
    ROW_NUMBER() OVER (ORDER BY data DESC, id DESC) AS rn_desc
  FROM peso_misure
  WHERE peso_kg IS NOT NULL
    AND data BETWEEN @data_da AND @data_a
)
SELECT
  MAX(CASE WHEN rn_asc = 1 THEN peso_kg END) AS peso_iniziale,
  MAX(CASE WHEN rn_desc = 1 THEN peso_kg END) AS peso_finale,
  ROUND(
    MAX(CASE WHEN rn_desc = 1 THEN peso_kg END)
    - MAX(CASE WHEN rn_asc = 1 THEN peso_kg END),
    3
  ) AS variazione_kg
FROM ordinati;


-- 10.6 Media mobile peso a 7 rilevazioni
SELECT
  data,
  peso_kg,
  ROUND(
    AVG(peso_kg) OVER (
      ORDER BY data, id
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),
    3
  ) AS media_mobile_7_rilevazioni
FROM peso_misure
WHERE peso_kg IS NOT NULL
ORDER BY data;


-- 10.7 Ultime misure corporee non nulle, per colonna
SELECT
  (
    SELECT peso_kg
    FROM peso_misure
    WHERE peso_kg IS NOT NULL
    ORDER BY data DESC, id DESC
    LIMIT 1
  ) AS ultimo_peso_kg,
  (
    SELECT vita_cm
    FROM peso_misure
    WHERE vita_cm IS NOT NULL
    ORDER BY data DESC, id DESC
    LIMIT 1
  ) AS ultima_vita_cm,
  (
    SELECT fianchi_cm
    FROM peso_misure
    WHERE fianchi_cm IS NOT NULL
    ORDER BY data DESC, id DESC
    LIMIT 1
  ) AS ultimi_fianchi_cm,
  (
    SELECT torace_cm
    FROM peso_misure
    WHERE torace_cm IS NOT NULL
    ORDER BY data DESC, id DESC
    LIMIT 1
  ) AS ultimo_torace_cm,
  (
    SELECT massa_grassa_pct
    FROM peso_misure
    WHERE massa_grassa_pct IS NOT NULL
    ORDER BY data DESC, id DESC
    LIMIT 1
  ) AS ultima_massa_grassa_pct,
  (
    SELECT massa_muscolare_kg
    FROM peso_misure
    WHERE massa_muscolare_kg IS NOT NULL
    ORDER BY data DESC, id DESC
    LIMIT 1
  ) AS ultima_massa_muscolare_kg;


-- 10.8 Trend settimanale del peso
SELECT
  YEARWEEK(data, 3) AS anno_settimana,
  MIN(data) AS da_data,
  MAX(data) AS a_data,
  ROUND(AVG(peso_kg), 3) AS peso_medio_kg,
  ROUND(MIN(peso_kg), 3) AS peso_min_kg,
  ROUND(MAX(peso_kg), 3) AS peso_max_kg
FROM peso_misure
WHERE peso_kg IS NOT NULL
GROUP BY YEARWEEK(data, 3)
ORDER BY anno_settimana DESC;


-- ============================================================================
-- 11. SELECT / ATTIVITÀ
-- ============================================================================

-- 11.1 Attività del giorno
SELECT a.*
FROM attivita_allenamenti a
JOIN diario_giornaliero d
  ON d.id = a.giornata_id
WHERE d.data = @data_rif
ORDER BY a.data_ora;


-- 11.2 Rollup attività del giorno
SELECT *
FROM v_diario_attivita
WHERE data = @data_rif;


-- 11.3 Attività per tipo
SELECT
  tipo,
  COUNT(*) AS sessioni,
  ROUND(SUM(durata_min), 2) AS durata_totale_min,
  ROUND(SUM(distanza_km), 2) AS distanza_totale_km,
  ROUND(SUM(calorie_attive_dispositivo), 2) AS kcal_attive_totali,
  ROUND(AVG(fc_media), 2) AS fc_media,
  MAX(fc_max) AS fc_max
FROM attivita_allenamenti
GROUP BY tipo
ORDER BY durata_totale_min DESC;


-- 11.4 Attività per fonte
SELECT
  fonte,
  COUNT(*) AS registrazioni,
  ROUND(SUM(durata_min), 2) AS durata_totale_min,
  ROUND(SUM(calorie_attive_dispositivo), 2) AS kcal_attive_totali
FROM attivita_allenamenti
GROUP BY fonte
ORDER BY registrazioni DESC;


-- 11.5 Totali settimanali di attività
SELECT
  YEARWEEK(d.data, 3) AS anno_settimana,
  MIN(d.data) AS da_data,
  MAX(d.data) AS a_data,
  COUNT(a.id) AS sessioni,
  ROUND(SUM(a.durata_min), 2) AS durata_min,
  ROUND(SUM(a.distanza_km), 2) AS distanza_km,
  ROUND(SUM(a.calorie_attive_dispositivo), 2) AS calorie_attive
FROM diario_giornaliero d
LEFT JOIN attivita_allenamenti a
  ON a.giornata_id = d.id
GROUP BY YEARWEEK(d.data, 3)
ORDER BY anno_settimana DESC;


-- 11.6 Giorni con più calorie attive
SELECT *
FROM v_diario_attivita
ORDER BY calorie_attive_device DESC
LIMIT 20;


-- 11.7 Sessioni ad alta intensità percepita
SELECT *
FROM attivita_allenamenti
WHERE intensita_percepita_0_10 >= 8
ORDER BY data_ora DESC;


-- 11.8 Attività con dati device incompleti
SELECT *
FROM attivita_allenamenti
WHERE fonte = 'Apple Watch'
  AND (
    durata_min IS NULL
    OR calorie_attive_dispositivo IS NULL
  )
ORDER BY data_ora DESC;


-- ============================================================================
-- 12. SELECT / INTEGRATORI E ASSUNZIONI
-- ============================================================================

-- 12.1 Integratori attivi
SELECT *
FROM integratori
WHERE stato = 'Attivo'
ORDER BY integratore;


-- 12.2 Assunzioni del giorno
SELECT
  a.*,
  i.integratore,
  i.marca
FROM assunzioni a
LEFT JOIN integratori i
  ON i.id = a.integratore_id
JOIN diario_giornaliero d
  ON d.id = a.giornata_id
WHERE d.data = @data_rif
ORDER BY a.data_ora;


-- 12.3 Assunzioni saltate
SELECT
  a.*,
  i.integratore,
  i.marca
FROM assunzioni a
LEFT JOIN integratori i
  ON i.id = a.integratore_id
WHERE a.esito = 'Saltato'
ORDER BY a.data_ora DESC;


-- 12.4 Aderenza per integratore
SELECT *
FROM v_integratori_aderenza
ORDER BY aderenza_pct DESC;


-- 12.5 Aderenza per integratore in un intervallo
SELECT
  i.id,
  i.integratore,
  COUNT(a.id) AS registrazioni,
  SUM(a.esito = 'Preso') AS prese,
  SUM(a.esito = 'Saltato') AS saltate,
  ROUND(
    100 * SUM(a.esito = 'Preso')
    / NULLIF(SUM(a.esito IN ('Preso', 'Saltato')), 0),
    2
  ) AS aderenza_pct
FROM integratori i
LEFT JOIN assunzioni a
  ON a.integratore_id = i.id
  AND DATE(a.data_ora) BETWEEN @data_da AND @data_a
GROUP BY i.id, i.integratore
ORDER BY aderenza_pct DESC;


-- 12.6 Ultima assunzione per integratore
WITH ranked AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (
      PARTITION BY a.integratore_id
      ORDER BY a.data_ora DESC, a.id DESC
    ) AS rn
  FROM assunzioni a
)
SELECT
  r.*,
  i.integratore
FROM ranked r
LEFT JOIN integratori i
  ON i.id = r.integratore_id
WHERE r.rn = 1
ORDER BY i.integratore;


-- 12.7 Integratori attivi senza assunzioni registrate
SELECT i.*
FROM integratori i
LEFT JOIN assunzioni a
  ON a.integratore_id = i.id
WHERE i.stato = 'Attivo'
GROUP BY i.id
HAVING COUNT(a.id) = 0
ORDER BY i.integratore;


-- ============================================================================
-- 13. SELECT / OSSERVAZIONI E APPRENDIMENTI
-- ============================================================================

-- 13.1 Osservazioni attive
SELECT *
FROM osservazioni_apprendimenti
WHERE attiva = 1
ORDER BY regola_stabile DESC, data DESC, id DESC;


-- 13.2 Regole stabili attive
SELECT *
FROM osservazioni_apprendimenti
WHERE attiva = 1
  AND regola_stabile = 1
ORDER BY data DESC, id DESC;


-- 13.3 Osservazioni per tipo
SELECT *
FROM osservazioni_apprendimenti
WHERE tipo = 'Sazieta'
ORDER BY data DESC, id DESC;


-- 13.4 Osservazioni di una giornata
SELECT o.*
FROM osservazioni_apprendimenti o
JOIN diario_giornaliero d
  ON d.id = o.giornata_id
WHERE d.data = @data_rif
ORDER BY o.id;


-- 13.5 Osservazioni collegate a un pasto
SELECT
  o.*,
  p.pasto,
  p.tipo,
  p.data_ora
FROM osservazioni_apprendimenti o
JOIN pasti p
  ON p.id = o.pasto_id
WHERE o.pasto_id = @pasto_id
ORDER BY o.data DESC, o.id DESC;


-- 13.6 Distribuzione delle osservazioni per tipo
SELECT
  tipo,
  COUNT(*) AS numero_osservazioni,
  SUM(attiva = 1) AS attive,
  SUM(regola_stabile = 1) AS regole_stabili
FROM osservazioni_apprendimenti
GROUP BY tipo
ORDER BY numero_osservazioni DESC;


-- 13.7 Ricerca full-text semplice via LIKE
SET @ricerca = '%fame%';

SELECT *
FROM osservazioni_apprendimenti
WHERE osservazione LIKE @ricerca
   OR dettaglio LIKE @ricerca
   OR apprendimento LIKE @ricerca
   OR azione_futura LIKE @ricerca
ORDER BY data DESC, id DESC;


-- ============================================================================
-- 14. SELECT / REPORT COMBINATI
-- ============================================================================

-- 14.1 Report completo della giornata
SELECT
  dc.*,
  d.acqua_l,
  d.caffe,
  d.alcol_unita,
  d.passi AS passi_giornata,
  d.sonno_ore,
  d.sonno_qualita_0_10,
  d.fame_pranzo_0_10,
  d.fame_pomeriggio_0_10,
  d.fame_nervosa_0_10,
  d.energia_post_pranzo_0_10,
  d.aderenza_0_10,
  d.note
FROM v_diario_completo dc
JOIN diario_giornaliero d
  ON d.id = dc.giornata_id
WHERE dc.data = @data_rif;


-- 14.2 Calorie ingerite vs calorie attive del device
SELECT
  dc.data,
  dc.totale_kcal AS kcal_ingerite,
  dc.calorie_attive_device,
  dc.totale_kcal - dc.calorie_attive_device
    AS kcal_ingerite_meno_attive_device
FROM v_diario_completo dc
WHERE dc.data BETWEEN @data_da AND @data_a
ORDER BY dc.data;


-- 14.3 Confronto giornate di allenamento vs riposo
SELECT
  tipo_giornata,
  COUNT(*) AS giorni,
  ROUND(AVG(totale_kcal), 2) AS kcal_medie,
  ROUND(AVG(totale_proteine_g), 2) AS proteine_medie_g,
  ROUND(AVG(calorie_attive_device), 2) AS calorie_attive_medie
FROM v_diario_completo
GROUP BY tipo_giornata
ORDER BY tipo_giornata;


-- 14.4 Relazione tra sonno e aderenza
SELECT
  d.data,
  d.sonno_ore,
  d.sonno_qualita_0_10,
  d.aderenza_0_10,
  n.totale_kcal,
  n.target_kcal
FROM diario_giornaliero d
JOIN v_diario_nutrizione n
  ON n.giornata_id = d.id
WHERE d.sonno_ore IS NOT NULL
   OR d.sonno_qualita_0_10 IS NOT NULL
ORDER BY d.data;


-- 14.5 Relazione tra fame nervosa giornaliera e pasti con fame nervosa
SELECT
  d.data,
  d.fame_nervosa_0_10,
  SUM(p.fame_nervosa = 1) AS pasti_con_fame_nervosa,
  COUNT(p.id) AS pasti_totali
FROM diario_giornaliero d
LEFT JOIN pasti p
  ON p.giornata_id = d.id
GROUP BY d.id, d.data, d.fame_nervosa_0_10
ORDER BY d.data;


-- 14.6 Giorni con migliore aderenza al target kcal:
-- scostamento assoluto minimo.
SELECT
  data,
  totale_kcal,
  target_kcal,
  ABS(totale_kcal - target_kcal) AS scostamento_assoluto_kcal
FROM v_diario_nutrizione
WHERE target_kcal IS NOT NULL
ORDER BY scostamento_assoluto_kcal ASC
LIMIT 20;


-- 14.7 Giorni con proteine alte e kcal basse
SELECT
  data,
  totale_kcal,
  totale_proteine_g,
  ROUND(
    100 * totale_proteine_g / NULLIF(totale_kcal, 0),
    2
  ) AS proteine_g_per_100_kcal
FROM v_diario_nutrizione
WHERE totale_kcal > 0
ORDER BY proteine_g_per_100_kcal DESC
LIMIT 20;


-- ============================================================================
-- 15. SELECT / DATA QUALITY E CONSISTENZA
-- ============================================================================

-- 15.1 Pasti senza giornata
SELECT *
FROM pasti
WHERE giornata_id IS NULL;


-- 15.2 Voci senza giornata
SELECT *
FROM voci_alimentari
WHERE giornata_id IS NULL;


-- 15.3 Voci senza pasto
SELECT *
FROM voci_alimentari
WHERE pasto_id IS NULL;


-- 15.4 Voci il cui timestamp non cade nella data della giornata
SELECT
  v.id,
  v.voce,
  v.data_ora,
  d.data
FROM voci_alimentari v
JOIN diario_giornaliero d
  ON d.id = v.giornata_id
WHERE v.data_ora IS NOT NULL
  AND DATE(v.data_ora) <> d.data;


-- 15.5 Pasti il cui timestamp non cade nella data della giornata
SELECT
  p.id,
  p.pasto,
  p.data_ora,
  d.data
FROM pasti p
JOIN diario_giornaliero d
  ON d.id = p.giornata_id
WHERE p.data_ora IS NOT NULL
  AND DATE(p.data_ora) <> d.data;


-- 15.6 Misure con data diversa dalla giornata collegata
SELECT
  pm.id,
  pm.rilevazione,
  pm.data AS data_misura,
  d.data AS data_giornata
FROM peso_misure pm
JOIN diario_giornaliero d
  ON d.id = pm.giornata_id
WHERE pm.data <> d.data;


-- 15.7 Assunzioni con data diversa dalla giornata collegata
SELECT
  a.id,
  a.assunzione,
  a.data_ora,
  d.data AS data_giornata
FROM assunzioni a
JOIN diario_giornaliero d
  ON d.id = a.giornata_id
WHERE DATE(a.data_ora) <> d.data;


-- 15.8 Possibili duplicati di prodotto per nome + marca
SELECT
  alimento_prodotto,
  COALESCE(marca, '') AS marca_norm,
  COUNT(*) AS duplicati,
  GROUP_CONCAT(id ORDER BY id) AS ids
FROM alimenti_prodotti
GROUP BY alimento_prodotto, COALESCE(marca, '')
HAVING COUNT(*) > 1
ORDER BY duplicati DESC;


-- 15.9 Possibili duplicati di voci nella stessa data/ora
SELECT
  giornata_id,
  pasto_id,
  voce,
  data_ora,
  quantita,
  unita,
  COUNT(*) AS duplicati,
  GROUP_CONCAT(id ORDER BY id) AS ids
FROM voci_alimentari
GROUP BY
  giornata_id,
  pasto_id,
  voce,
  data_ora,
  quantita,
  unita
HAVING COUNT(*) > 1
ORDER BY duplicati DESC;


-- 15.10 Giornate senza alcun pasto
SELECT d.*
FROM diario_giornaliero d
LEFT JOIN pasti p
  ON p.giornata_id = d.id
WHERE p.id IS NULL
ORDER BY d.data DESC;


-- 15.11 Giornate con pasti ma senza voci alimentari
SELECT
  d.id,
  d.data,
  COUNT(DISTINCT p.id) AS pasti
FROM diario_giornaliero d
JOIN pasti p
  ON p.giornata_id = d.id
LEFT JOIN voci_alimentari v
  ON v.giornata_id = d.id
GROUP BY d.id, d.data
HAVING COUNT(DISTINCT v.id) = 0
ORDER BY d.data DESC;


-- ============================================================================
-- 16. UPDATE / MODIFICA
-- ============================================================================

-- 16.1 Modificare il tipo di giornata
UPDATE diario_giornaliero
SET tipo_giornata = 'Allenamento'
WHERE id = @giornata_id;


-- 16.2 Chiudere una giornata
UPDATE diario_giornaliero
SET giornata_chiusa = 1
WHERE id = @giornata_id;


-- 16.3 Riaprire una giornata
UPDATE diario_giornaliero
SET giornata_chiusa = 0
WHERE id = @giornata_id;


-- 16.4 Aggiornare i target nutrizionali
UPDATE diario_giornaliero
SET
  target_kcal = 2200,
  target_proteine_g = 150,
  target_carboidrati_g = 220,
  target_grassi_g = 70,
  target_fibre_g = 30
WHERE id = @giornata_id;


-- 16.5 Aggiornare idratazione, caffeina, alcol e passi
UPDATE diario_giornaliero
SET
  acqua_l = 2.5,
  caffe = 2,
  alcol_unita = 0,
  passi = 10000
WHERE id = @giornata_id;


-- 16.6 Aggiornare sonno e valutazioni della giornata
UPDATE diario_giornaliero
SET
  sonno_ore = 7.5,
  sonno_qualita_0_10 = 8,
  fame_pranzo_0_10 = 5,
  fame_pomeriggio_0_10 = 4,
  fame_nervosa_0_10 = 2,
  energia_post_pranzo_0_10 = 8,
  aderenza_0_10 = 9
WHERE id = @giornata_id;


-- 16.7 Modificare un pasto
UPDATE pasti
SET
  contesto = 'Ristorante',
  libero_sociale = 1,
  gradimento_0_10 = 9,
  note = 'Aggiornato'
WHERE id = @pasto_id;


-- 16.8 Spostare un pasto a un'altra giornata
SET @nuova_giornata_id = @giornata_id;

UPDATE pasti
SET giornata_id = @nuova_giornata_id
WHERE id = @pasto_id;

-- IMPORTANTE:
-- Le voci già collegate al pasto non vengono automaticamente spostate.
-- Sincronizzarle esplicitamente:
UPDATE voci_alimentari
SET giornata_id = @nuova_giornata_id
WHERE pasto_id = @pasto_id;


-- 16.9 Modificare quantità e macro di una voce
UPDATE voci_alimentari
SET
  quantita = 180,
  kcal = 270,
  proteine_g = 36,
  carboidrati_g = 3.6,
  grassi_g = 10.8
WHERE id = 1;


-- 16.10 Ricalcolare una voce dai valori per 100 g del prodotto
SET @voce_id = 1;

UPDATE voci_alimentari v
JOIN alimenti_prodotti ap
  ON ap.id = v.prodotto_id
SET
  v.kcal = ROUND(ap.kcal_100g * v.quantita / 100, 3),
  v.proteine_g = ROUND(ap.proteine_100g * v.quantita / 100, 3),
  v.carboidrati_g = ROUND(ap.carboidrati_100g * v.quantita / 100, 3),
  v.grassi_g = ROUND(ap.grassi_100g * v.quantita / 100, 3),
  v.fibre_g = ROUND(ap.fibre_100g * v.quantita / 100, 3),
  v.zuccheri_g = ROUND(ap.zuccheri_100g * v.quantita / 100, 3),
  v.fonte_valori = 'Prodotto registrato',
  v.affidabilita = CASE
    WHEN ap.verificato = 1 THEN 'Alta'
    ELSE 'Media'
  END
WHERE v.id = @voce_id
  AND v.unita = 'g'
  AND v.quantita IS NOT NULL;


-- 16.11 Aggiornare il prodotto di una voce
UPDATE voci_alimentari
SET prodotto_id = @prodotto_id
WHERE id = @voce_id;


-- 16.12 Scollegare una voce dal prodotto
UPDATE voci_alimentari
SET prodotto_id = NULL
WHERE id = @voce_id;


-- 16.13 Modificare i valori nutrizionali di un prodotto
UPDATE alimenti_prodotti
SET
  kcal_100g = 155,
  proteine_100g = 21,
  carboidrati_100g = 2,
  grassi_100g = 6,
  fonte = 'Etichetta',
  ultimo_controllo = CURRENT_DATE,
  verificato = 1
WHERE id = @prodotto_id;


-- 16.14 Cambiare stato di un prodotto
UPDATE alimenti_prodotti
SET stato = 'Preferito'
WHERE id = @prodotto_id;


-- 16.15 Marcare più prodotti come da ricontrollare
UPDATE alimenti_prodotti
SET verificato = 0
WHERE ultimo_controllo < CURRENT_DATE - INTERVAL 1 YEAR;


-- 16.16 Aggiornare una rilevazione corporea
UPDATE peso_misure
SET
  peso_kg = 79.900,
  note = 'Valore corretto'
WHERE id = @rilevazione_id;


-- 16.17 Aggiornare un'attività
UPDATE attivita_allenamenti
SET
  durata_min = 50,
  distanza_km = 4.8,
  calorie_attive_dispositivo = 285
WHERE id = @attivita_id;


-- 16.18 Aggiornare stato integratore
UPDATE integratori
SET
  stato = 'Sospeso',
  data_fine = CURRENT_DATE
WHERE id = @integratore_id;


-- 16.19 Riattivare integratore
UPDATE integratori
SET
  stato = 'Attivo',
  data_fine = NULL
WHERE id = @integratore_id;


-- 16.20 Correggere una singola assunzione
UPDATE assunzioni
SET
  esito = 'Preso',
  dose_assunta = 1,
  note = 'Corretto manualmente'
WHERE id = @assunzione_id;


-- 16.21 Disattivare un'osservazione
UPDATE osservazioni_apprendimenti
SET attiva = 0
WHERE id = @osservazione_id;


-- 16.22 Promuovere un'osservazione a regola stabile
UPDATE osservazioni_apprendimenti
SET
  attiva = 1,
  regola_stabile = 1
WHERE id = @osservazione_id;


-- 16.23 Appendere una nota senza sovrascrivere quella esistente
UPDATE diario_giornaliero
SET note = CONCAT_WS(
  '\n',
  NULLIF(note, ''),
  CONCAT('[', NOW(), '] ', 'Nota aggiunta')
)
WHERE id = @giornata_id;


-- ============================================================================
-- 17. DELETE / RIMOZIONE
-- ============================================================================

-- ATTENZIONE:
-- - Cancellare una giornata elimina in cascata pasti, voci, misure, attività,
--   assunzioni e osservazioni collegate.
-- - Cancellare un pasto elimina in cascata le sue voci e osservazioni.
-- - Cancellare un prodotto NON cancella i consumi: prodotto_id diventa NULL.
-- - Cancellare un integratore NON cancella le assunzioni: integratore_id
--   diventa NULL.


-- 17.1 Eliminare una voce alimentare
DELETE FROM voci_alimentari
WHERE id = @voce_id;


-- 17.2 Eliminare tutte le voci di un pasto
DELETE FROM voci_alimentari
WHERE pasto_id = @pasto_id;


-- 17.3 Eliminare un pasto e i suoi figli per CASCADE
DELETE FROM pasti
WHERE id = @pasto_id;


-- 17.4 Eliminare un prodotto mantenendo lo storico dei consumi
DELETE FROM alimenti_prodotti
WHERE id = @prodotto_id;


-- 17.5 Eliminare una rilevazione corporea
DELETE FROM peso_misure
WHERE id = @rilevazione_id;


-- 17.6 Eliminare un'attività
DELETE FROM attivita_allenamenti
WHERE id = @attivita_id;


-- 17.7 Eliminare una singola assunzione
DELETE FROM assunzioni
WHERE id = @assunzione_id;


-- 17.8 Eliminare un integratore mantenendo le assunzioni storiche
DELETE FROM integratori
WHERE id = @integratore_id;


-- 17.9 Eliminare un'osservazione
DELETE FROM osservazioni_apprendimenti
WHERE id = @osservazione_id;


-- 17.10 Eliminare una giornata intera con tutte le dipendenze
DELETE FROM diario_giornaliero
WHERE id = @giornata_id;


-- 17.11 Eliminare voci potenzialmente duplicate conservando l'ID minore
-- ESEGUIRE PRIMA LA SELECT DI CONTROLLO.
DELETE v1
FROM voci_alimentari v1
JOIN voci_alimentari v2
  ON v1.id > v2.id
  AND v1.giornata_id <=> v2.giornata_id
  AND v1.pasto_id <=> v2.pasto_id
  AND v1.voce = v2.voce
  AND v1.data_ora <=> v2.data_ora
  AND v1.quantita <=> v2.quantita
  AND v1.unita = v2.unita;


-- 17.12 Cancellazione sicura in transazione con controllo preventivo
START TRANSACTION;

SELECT
  d.id,
  d.data,
  (
    SELECT COUNT(*)
    FROM pasti p
    WHERE p.giornata_id = d.id
  ) AS pasti,
  (
    SELECT COUNT(*)
    FROM voci_alimentari v
    WHERE v.giornata_id = d.id
  ) AS voci,
  (
    SELECT COUNT(*)
    FROM attivita_allenamenti a
    WHERE a.giornata_id = d.id
  ) AS attivita
FROM diario_giornaliero d
WHERE d.id = @giornata_id
FOR UPDATE;

-- Se il controllo è corretto, eseguire:
-- DELETE FROM diario_giornaliero WHERE id = @giornata_id;
-- COMMIT;

-- Altrimenti:
ROLLBACK;


-- 17.13 Eliminare dati di test per intervallo di date
-- ATTENZIONE: distruttiva.
DELETE FROM diario_giornaliero
WHERE data BETWEEN '2099-01-01' AND '2099-12-31';


-- ============================================================================
-- 18. QUERY DI MANUTENZIONE E METADATI
-- ============================================================================

-- 18.1 Elenco tabelle
SHOW TABLES;


-- 18.2 Struttura di una tabella
DESCRIBE diario_giornaliero;


-- 18.3 DDL effettivo
SHOW CREATE TABLE voci_alimentari;


-- 18.4 Elenco indici
SHOW INDEX FROM voci_alimentari;


-- 18.5 Dimensione delle tabelle
SELECT
  table_name,
  table_rows,
  ROUND(data_length / 1024 / 1024, 2) AS data_mb,
  ROUND(index_length / 1024 / 1024, 2) AS index_mb,
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS totale_mb
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY totale_mb DESC;


-- 18.6 Foreign key del database
SELECT
  table_name,
  column_name,
  constraint_name,
  referenced_table_name,
  referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE()
  AND referenced_table_name IS NOT NULL
ORDER BY table_name, column_name;


-- 18.7 Conteggio record per tabella
SELECT 'diario_giornaliero' AS tabella, COUNT(*) AS righe
FROM diario_giornaliero
UNION ALL
SELECT 'pasti', COUNT(*) FROM pasti
UNION ALL
SELECT 'voci_alimentari', COUNT(*) FROM voci_alimentari
UNION ALL
SELECT 'alimenti_prodotti', COUNT(*) FROM alimenti_prodotti
UNION ALL
SELECT 'peso_misure', COUNT(*) FROM peso_misure
UNION ALL
SELECT 'attivita_allenamenti', COUNT(*) FROM attivita_allenamenti
UNION ALL
SELECT 'integratori', COUNT(*) FROM integratori
UNION ALL
SELECT 'osservazioni_apprendimenti', COUNT(*) FROM osservazioni_apprendimenti
UNION ALL
SELECT 'assunzioni', COUNT(*) FROM assunzioni;


-- 18.8 Analizzare le tabelle dopo import massivo
ANALYZE TABLE
  diario_giornaliero,
  pasti,
  voci_alimentari,
  alimenti_prodotti,
  peso_misure,
  attivita_allenamenti,
  integratori,
  osservazioni_apprendimenti,
  assunzioni;


-- ============================================================================
-- 19. QUERY UTILI PER API / BACKEND
-- ============================================================================

-- 19.1 Recuperare ID giornata da data
SELECT id
FROM diario_giornaliero
WHERE data = @data_rif;


-- 19.2 Creare la giornata solo se manca e ottenere sempre l'ID
INSERT INTO diario_giornaliero (
  giorno,
  data,
  tipo_giornata
) VALUES (
  DATE_FORMAT(@data_rif, '%Y-%m-%d'),
  @data_rif,
  'Non definita'
)
ON DUPLICATE KEY UPDATE
  id = LAST_INSERT_ID(id);

SET @giornata_id = LAST_INSERT_ID();


-- 19.3 Recuperare un prodotto per ID
SELECT *
FROM alimenti_prodotti
WHERE id = @prodotto_id;


-- 19.4 Ricerca prodotto per nome/marca
SET @nome_prodotto = '%salmone%';
SET @marca = '%';

SELECT *
FROM alimenti_prodotti
WHERE alimento_prodotto LIKE @nome_prodotto
  AND COALESCE(marca, '') LIKE @marca
ORDER BY verificato DESC, alimento_prodotto;


-- 19.5 Paginazione cursor-based per pasti
SET @ultimo_id = 9223372036854775807;
SET @page_size = 50;

SELECT *
FROM pasti
WHERE id < @ultimo_id
ORDER BY id DESC
LIMIT 50;


-- 19.6 Paginazione offset-based
SET @offset = 0;

SELECT *
FROM voci_alimentari
ORDER BY id DESC
LIMIT 50 OFFSET 0;


-- 19.7 ETag-like timestamp per capire se una giornata è cambiata
SELECT
  id,
  data,
  aggiornato
FROM diario_giornaliero
WHERE id = @giornata_id;


-- 19.8 Query JSON: giornata + pasti + voci
SELECT JSON_OBJECT(
  'id', d.id,
  'data', d.data,
  'giorno', d.giorno,
  'tipo_giornata', d.tipo_giornata,
  'giornata_chiusa', d.giornata_chiusa,
  'pasti', (
    SELECT COALESCE(
      JSON_ARRAYAGG(
        JSON_OBJECT(
          'id', x.id,
          'pasto', x.pasto,
          'tipo', x.tipo,
          'data_ora', x.data_ora,
          'totale_kcal', x.totale_kcal
        )
      ),
      JSON_ARRAY()
    )
    FROM v_pasti_totali x
    WHERE x.giornata_id = d.id
  )
) AS giornata_json
FROM diario_giornaliero d
WHERE d.id = @giornata_id;


-- 19.9 Query JSON dettagliata del pasto con voci
SELECT JSON_OBJECT(
  'id', p.id,
  'pasto', p.pasto,
  'tipo', p.tipo,
  'contesto', p.contesto,
  'data_ora', p.data_ora,
  'voci', (
    SELECT COALESCE(
      JSON_ARRAYAGG(
        JSON_OBJECT(
          'id', v.id,
          'voce', v.voce,
          'quantita', v.quantita,
          'unita', v.unita,
          'kcal', v.kcal,
          'proteine_g', v.proteine_g,
          'carboidrati_g', v.carboidrati_g,
          'grassi_g', v.grassi_g,
          'fibre_g', v.fibre_g,
          'prodotto_id', v.prodotto_id
        )
      ),
      JSON_ARRAY()
    )
    FROM voci_alimentari v
    WHERE v.pasto_id = p.id
  )
) AS pasto_json
FROM pasti p
WHERE p.id = @pasto_id;


-- ============================================================================
-- 20. QUERY DI BACKUP LOGICO / EXPORT
-- ============================================================================

-- 20.1 Export logico tabellare della giornata
SELECT
  d.data,
  p.tipo AS tipo_pasto,
  p.pasto,
  v.voce,
  v.quantita,
  v.unita,
  v.kcal,
  v.proteine_g,
  v.carboidrati_g,
  v.grassi_g,
  v.fibre_g,
  v.zuccheri_g,
  v.alcol_g,
  ap.alimento_prodotto,
  ap.marca
FROM diario_giornaliero d
LEFT JOIN pasti p
  ON p.giornata_id = d.id
LEFT JOIN voci_alimentari v
  ON v.pasto_id = p.id
LEFT JOIN alimenti_prodotti ap
  ON ap.id = v.prodotto_id
WHERE d.data = @data_rif
ORDER BY p.data_ora, v.data_ora, v.id;


-- 20.2 Snapshot delle regole attive
SELECT
  id,
  data,
  osservazione,
  tipo,
  dettaglio,
  apprendimento,
  azione_futura,
  valutazione_0_10,
  regola_stabile
FROM osservazioni_apprendimenti
WHERE attiva = 1
ORDER BY regola_stabile DESC, data DESC, id DESC;


-- ============================================================================
-- 21. QUERY PER STATISTICHE AVANZATE
-- ============================================================================

-- 21.1 Quartili approssimati delle kcal giornaliere usando NTILE
WITH ranked AS (
  SELECT
    data,
    totale_kcal,
    NTILE(4) OVER (ORDER BY totale_kcal) AS quartile
  FROM v_diario_nutrizione
  WHERE totale_kcal IS NOT NULL
)
SELECT
  quartile,
  COUNT(*) AS giorni,
  MIN(totale_kcal) AS kcal_min,
  MAX(totale_kcal) AS kcal_max,
  ROUND(AVG(totale_kcal), 2) AS kcal_media
FROM ranked
GROUP BY quartile
ORDER BY quartile;


-- 21.2 Ranking dei giorni più calorici
SELECT
  data,
  totale_kcal,
  DENSE_RANK() OVER (ORDER BY totale_kcal DESC) AS ranking_kcal
FROM v_diario_nutrizione
ORDER BY ranking_kcal, data;


-- 21.3 Ranking dei pasti più sazianti a parità di kcal
SELECT
  pasto_id,
  pasto,
  tipo,
  totale_kcal,
  sazieta_dopo_0_10,
  ROUND(
    sazieta_dopo_0_10 * 100 / NULLIF(totale_kcal, 0),
    3
  ) AS sazieta_per_100_kcal
FROM v_pasti_totali
WHERE sazieta_dopo_0_10 IS NOT NULL
  AND totale_kcal > 0
ORDER BY sazieta_per_100_kcal DESC;


-- 21.4 Frequenza dei contesti dei pasti
SELECT
  contesto,
  COUNT(*) AS pasti,
  ROUND(
    100 * COUNT(*) / SUM(COUNT(*)) OVER (),
    2
  ) AS percentuale
FROM pasti
GROUP BY contesto
ORDER BY pasti DESC;


-- 21.5 Frequenza degli alimenti nel tempo: ultimi 30 giorni
SELECT
  ap.alimento_prodotto,
  ap.marca,
  COUNT(v.id) AS consumi_30g,
  ROUND(SUM(v.kcal), 2) AS kcal_30g
FROM voci_alimentari v
JOIN alimenti_prodotti ap
  ON ap.id = v.prodotto_id
JOIN diario_giornaliero d
  ON d.id = v.giornata_id
WHERE d.data >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY ap.id, ap.alimento_prodotto, ap.marca
ORDER BY consumi_30g DESC, kcal_30g DESC;


-- 21.6 Giorni consecutivi registrati: segmentazione per gap
WITH x AS (
  SELECT
    data,
    DATE_SUB(
      data,
      INTERVAL ROW_NUMBER() OVER (ORDER BY data) DAY
    ) AS grp
  FROM diario_giornaliero
),
streaks AS (
  SELECT
    MIN(data) AS inizio,
    MAX(data) AS fine,
    COUNT(*) AS giorni
  FROM x
  GROUP BY grp
)
SELECT *
FROM streaks
ORDER BY giorni DESC, fine DESC;


-- 21.7 Giorni senza dati nutrizionali ma con giornata creata
SELECT
  d.id,
  d.data,
  d.giorno
FROM diario_giornaliero d
LEFT JOIN voci_alimentari v
  ON v.giornata_id = d.id
GROUP BY d.id, d.data, d.giorno
HAVING COUNT(v.id) = 0
ORDER BY d.data DESC;


-- 21.8 Correlazione "grezza" esportabile: peso vs media kcal ultimi 7 giorni
-- Non calcola il coefficiente di Pearson; prepara le coppie per analisi esterna.
SELECT
  pm.data,
  pm.peso_kg,
  (
    SELECT AVG(n.totale_kcal)
    FROM v_diario_nutrizione n
    WHERE n.data BETWEEN pm.data - INTERVAL 6 DAY AND pm.data
  ) AS media_kcal_7g
FROM peso_misure pm
WHERE pm.peso_kg IS NOT NULL
ORDER BY pm.data;

-- ============================================================================
-- 23. ESEMPI DI CHIAMATA DELLE PROCEDURE
-- ============================================================================

CALL sp_get_or_create_giornata('2026-09-11', @id_giornata_creata);
SELECT @id_giornata_creata;

-- CALL sp_ricalcola_voce_da_prodotto(123);
-- CALL sp_delete_giornata(123);
