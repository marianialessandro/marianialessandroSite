-- File: nutrizionista_schema_mysql.sql
-- Target: MySQL 8.0+
-- ESEGUIBILE: crea da zero il database `nutrizionista`.
-- ATTENZIONE: contiene DROP DATABASE IF EXISTS nutrizionista.
--
-- ============================================================================
-- Database: nutrizionista
-- Target: MySQL 8.0+
-- Derivato dallo schema Notion "Nutrizionista" (snapshot 2026-09-02)
--
-- Obiettivi:
--   1. Ricreare in forma relazionale i 9 database Notion.
--   2. Rappresentare le relation Notion tramite FOREIGN KEY.
--   3. Rappresentare i rollup tramite VIEW/aggregazioni, senza duplicare dati.
--   4. Fornire una libreria estesa di query INSERT / SELECT / UPDATE / DELETE.
--
-- Convenzioni:
--   - PK surrogate BIGINT UNSIGNED AUTO_INCREMENT.
--   - DATE per date pure, DATETIME per eventi con data/ora.
--   - DECIMAL per quantità, kcal e macro.
--   - TINYINT(1) per checkbox.
--   - ENUM per i select Notion a vocabolario chiuso.
--   - Le query di esempio usano variabili @... per evitare valori hard-coded.
-- ============================================================================

SET NAMES utf8mb4;
SET time_zone = '+02:00';

DROP DATABASE IF EXISTS nutrizionista;
CREATE DATABASE nutrizionista
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE nutrizionista;

-- ============================================================================
-- 1. TABELLE
-- ============================================================================

CREATE TABLE diario_giornaliero (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  giorno VARCHAR(255) NOT NULL,
  data DATE NOT NULL,
  data_fine DATE NULL,

  tipo_giornata ENUM(
    'Riposo',
    'Allenamento',
    'Sociale',
    'Mista',
    'Non definita'
  ) NOT NULL DEFAULT 'Non definita',

  giornata_chiusa TINYINT(1) NOT NULL DEFAULT 0,

  target_kcal DECIMAL(10,2) NULL,
  target_proteine_g DECIMAL(10,2) NULL,
  target_carboidrati_g DECIMAL(10,2) NULL,
  target_grassi_g DECIMAL(10,2) NULL,
  target_fibre_g DECIMAL(10,2) NULL,

  acqua_l DECIMAL(6,2) NULL,
  caffe DECIMAL(8,2) NULL,
  alcol_unita DECIMAL(8,2) NULL,
  passi INT UNSIGNED NULL,
  sonno_ore DECIMAL(5,2) NULL,

  sonno_qualita_0_10 DECIMAL(4,2) NULL,
  fame_pranzo_0_10 DECIMAL(4,2) NULL,
  fame_pomeriggio_0_10 DECIMAL(4,2) NULL,
  fame_nervosa_0_10 DECIMAL(4,2) NULL,
  energia_post_pranzo_0_10 DECIMAL(4,2) NULL,
  aderenza_0_10 DECIMAL(4,2) NULL,

  note TEXT NULL,
  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_diario_data (data),

  CONSTRAINT chk_diario_data_intervallo
    CHECK (data_fine IS NULL OR data_fine >= data),

  CONSTRAINT chk_diario_sonno_qualita
    CHECK (sonno_qualita_0_10 IS NULL OR sonno_qualita_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_diario_fame_pranzo
    CHECK (fame_pranzo_0_10 IS NULL OR fame_pranzo_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_diario_fame_pomeriggio
    CHECK (fame_pomeriggio_0_10 IS NULL OR fame_pomeriggio_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_diario_fame_nervosa
    CHECK (fame_nervosa_0_10 IS NULL OR fame_nervosa_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_diario_energia_post_pranzo
    CHECK (energia_post_pranzo_0_10 IS NULL OR energia_post_pranzo_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_diario_aderenza
    CHECK (aderenza_0_10 IS NULL OR aderenza_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_diario_target_nonnegativi
    CHECK (
      (target_kcal IS NULL OR target_kcal >= 0)
      AND (target_proteine_g IS NULL OR target_proteine_g >= 0)
      AND (target_carboidrati_g IS NULL OR target_carboidrati_g >= 0)
      AND (target_grassi_g IS NULL OR target_grassi_g >= 0)
      AND (target_fibre_g IS NULL OR target_fibre_g >= 0)
    )
) ENGINE=InnoDB;


CREATE TABLE pasti (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pasto VARCHAR(255) NOT NULL,
  data_ora DATETIME NULL,
  data_ora_fine DATETIME NULL,

  tipo ENUM(
    'Colazione',
    'Pranzo',
    'Cena',
    'Spuntino',
    'Bevanda',
    'Alcol',
    'Pasto libero',
    'Altro'
  ) NOT NULL DEFAULT 'Altro',

  contesto ENUM(
    'Casa',
    'Fuori',
    'Universita',
    'Vending',
    'Delivery',
    'Ristorante',
    'Altro'
  ) NOT NULL DEFAULT 'Altro',

  libero_sociale TINYINT(1) NOT NULL DEFAULT 0,
  fame_nervosa TINYINT(1) NOT NULL DEFAULT 0,

  fame_prima_0_10 DECIMAL(4,2) NULL,
  sazieta_dopo_0_10 DECIMAL(4,2) NULL,
  energia_dopo_0_10 DECIMAL(4,2) NULL,
  gradimento_0_10 DECIMAL(4,2) NULL,

  note TEXT NULL,
  giornata_id BIGINT UNSIGNED NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_pasti_giornata (giornata_id),
  KEY idx_pasti_data_ora (data_ora),
  KEY idx_pasti_tipo (tipo),
  KEY idx_pasti_contesto (contesto),

  CONSTRAINT fk_pasti_giornata
    FOREIGN KEY (giornata_id)
    REFERENCES diario_giornaliero(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT chk_pasti_intervallo
    CHECK (data_ora_fine IS NULL OR data_ora IS NULL OR data_ora_fine >= data_ora),

  CONSTRAINT chk_pasti_fame
    CHECK (fame_prima_0_10 IS NULL OR fame_prima_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_pasti_sazieta
    CHECK (sazieta_dopo_0_10 IS NULL OR sazieta_dopo_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_pasti_energia
    CHECK (energia_dopo_0_10 IS NULL OR energia_dopo_0_10 BETWEEN 0 AND 10),

  CONSTRAINT chk_pasti_gradimento
    CHECK (gradimento_0_10 IS NULL OR gradimento_0_10 BETWEEN 0 AND 10)
) ENGINE=InnoDB;


CREATE TABLE alimenti_prodotti (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  alimento_prodotto VARCHAR(255) NOT NULL,
  marca VARCHAR(255) NULL,

  categoria ENUM(
    'Proteina',
    'Carboidrato',
    'Grasso/condimento',
    'Latticino',
    'Legume',
    'Snack',
    'Bevanda',
    'Salsa',
    'Pasto completo',
    'Altro'
  ) NOT NULL DEFAULT 'Altro',

  stato ENUM(
    'Preferito',
    'Ammesso',
    'Occasionale',
    'Da provare',
    'Escluso'
  ) NOT NULL DEFAULT 'Ammesso',

  kcal_100g DECIMAL(10,3) NULL,
  proteine_100g DECIMAL(10,3) NULL,
  carboidrati_100g DECIMAL(10,3) NULL,
  grassi_100g DECIMAL(10,3) NULL,
  fibre_100g DECIMAL(10,3) NULL,
  zuccheri_100g DECIMAL(10,3) NULL,
  sale_100g DECIMAL(10,3) NULL,

  porzione_tipica_g DECIMAL(10,3) NULL,
  kcal_porzione DECIMAL(10,3) NULL,

  ingredienti_note TEXT NULL,

  fonte ENUM(
    'Etichetta',
    'Sito ufficiale',
    'Database',
    'Stima',
    'Utente'
  ) NULL,

  url_fonte VARCHAR(2048) NULL,
  ultimo_controllo DATE NULL,
  verificato TINYINT(1) NOT NULL DEFAULT 0,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_prodotti_nome (alimento_prodotto),
  KEY idx_prodotti_marca (marca),
  KEY idx_prodotti_categoria (categoria),
  KEY idx_prodotti_stato (stato),
  KEY idx_prodotti_verificato (verificato),

  CONSTRAINT chk_prodotti_valori_nonnegativi
    CHECK (
      (kcal_100g IS NULL OR kcal_100g >= 0)
      AND (proteine_100g IS NULL OR proteine_100g >= 0)
      AND (carboidrati_100g IS NULL OR carboidrati_100g >= 0)
      AND (grassi_100g IS NULL OR grassi_100g >= 0)
      AND (fibre_100g IS NULL OR fibre_100g >= 0)
      AND (zuccheri_100g IS NULL OR zuccheri_100g >= 0)
      AND (sale_100g IS NULL OR sale_100g >= 0)
      AND (porzione_tipica_g IS NULL OR porzione_tipica_g >= 0)
      AND (kcal_porzione IS NULL OR kcal_porzione >= 0)
    )
) ENGINE=InnoDB;


CREATE TABLE voci_alimentari (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  voce VARCHAR(255) NOT NULL,
  data_ora DATETIME NULL,
  data_ora_fine DATETIME NULL,

  quantita DECIMAL(12,3) NULL,

  unita ENUM(
    'g',
    'ml',
    'pezzo',
    'porzione',
    'bustina',
    'bicchiere',
    'lattina',
    'altro'
  ) NOT NULL DEFAULT 'altro',

  descrizione_quantita VARCHAR(500) NULL,

  peso ENUM(
    'Crudo',
    'Cotto',
    'Non applicabile',
    'Non noto'
  ) NOT NULL DEFAULT 'Non noto',

  kcal DECIMAL(10,3) NULL,
  proteine_g DECIMAL(10,3) NULL,
  carboidrati_g DECIMAL(10,3) NULL,
  grassi_g DECIMAL(10,3) NULL,
  fibre_g DECIMAL(10,3) NULL,
  zuccheri_g DECIMAL(10,3) NULL,
  alcol_g DECIMAL(10,3) NULL,

  fonte_valori ENUM(
    'Etichetta',
    'Sito ufficiale',
    'Prodotto registrato',
    'Database',
    'Stima',
    'Utente'
  ) NULL,

  affidabilita ENUM(
    'Alta',
    'Media',
    'Bassa'
  ) NULL,

  note TEXT NULL,

  giornata_id BIGINT UNSIGNED NULL,
  pasto_id BIGINT UNSIGNED NULL,
  prodotto_id BIGINT UNSIGNED NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),

  KEY idx_voci_giornata (giornata_id),
  KEY idx_voci_pasto (pasto_id),
  KEY idx_voci_prodotto (prodotto_id),
  KEY idx_voci_data_ora (data_ora),
  KEY idx_voci_fonte (fonte_valori),
  KEY idx_voci_affidabilita (affidabilita),

  CONSTRAINT fk_voci_giornata
    FOREIGN KEY (giornata_id)
    REFERENCES diario_giornaliero(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_voci_pasto
    FOREIGN KEY (pasto_id)
    REFERENCES pasti(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_voci_prodotto
    FOREIGN KEY (prodotto_id)
    REFERENCES alimenti_prodotti(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,

  CONSTRAINT chk_voci_intervallo
    CHECK (data_ora_fine IS NULL OR data_ora IS NULL OR data_ora_fine >= data_ora),

  CONSTRAINT chk_voci_valori_nonnegativi
    CHECK (
      (quantita IS NULL OR quantita >= 0)
      AND (kcal IS NULL OR kcal >= 0)
      AND (proteine_g IS NULL OR proteine_g >= 0)
      AND (carboidrati_g IS NULL OR carboidrati_g >= 0)
      AND (grassi_g IS NULL OR grassi_g >= 0)
      AND (fibre_g IS NULL OR fibre_g >= 0)
      AND (zuccheri_g IS NULL OR zuccheri_g >= 0)
      AND (alcol_g IS NULL OR alcol_g >= 0)
    )
) ENGINE=InnoDB;


CREATE TABLE peso_misure (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rilevazione VARCHAR(255) NOT NULL,
  data DATE NOT NULL,

  peso_kg DECIMAL(7,3) NULL,
  vita_cm DECIMAL(7,2) NULL,
  fianchi_cm DECIMAL(7,2) NULL,
  torace_cm DECIMAL(7,2) NULL,
  massa_grassa_pct DECIMAL(6,3) NULL,
  massa_muscolare_kg DECIMAL(7,3) NULL,

  fonte ENUM(
    'Bilancia',
    'Metro',
    'BIA',
    'DEXA',
    'Altro'
  ) NULL,

  affidabilita ENUM(
    'Alta',
    'Media',
    'Bassa'
  ) NULL,

  condizioni TEXT NULL,
  note TEXT NULL,

  giornata_id BIGINT UNSIGNED NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_misure_giornata (giornata_id),
  KEY idx_misure_data (data),
  KEY idx_misure_fonte (fonte),

  CONSTRAINT fk_misure_giornata
    FOREIGN KEY (giornata_id)
    REFERENCES diario_giornaliero(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT chk_misure_nonnegative
    CHECK (
      (peso_kg IS NULL OR peso_kg > 0)
      AND (vita_cm IS NULL OR vita_cm > 0)
      AND (fianchi_cm IS NULL OR fianchi_cm > 0)
      AND (torace_cm IS NULL OR torace_cm > 0)
      AND (massa_grassa_pct IS NULL OR massa_grassa_pct BETWEEN 0 AND 100)
      AND (massa_muscolare_kg IS NULL OR massa_muscolare_kg > 0)
    )
) ENGINE=InnoDB;


CREATE TABLE attivita_allenamenti (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  attivita VARCHAR(255) NOT NULL,
  data_ora DATETIME NULL,

  tipo ENUM(
    'Camminata',
    'Pesi',
    'Corsa',
    'Bici',
    'Sport',
    'Altro'
  ) NOT NULL DEFAULT 'Altro',

  fonte ENUM(
    'Apple Watch',
    'Manuale',
    'Altro wearable',
    'Stima'
  ) NOT NULL DEFAULT 'Manuale',

  durata_min DECIMAL(10,2) NULL,
  distanza_km DECIMAL(10,3) NULL,
  passi INT UNSIGNED NULL,
  calorie_attive_dispositivo DECIMAL(10,3) NULL,
  fc_media DECIMAL(7,2) NULL,
  fc_max DECIMAL(7,2) NULL,
  intensita_percepita_0_10 DECIMAL(4,2) NULL,

  note TEXT NULL,
  giornata_id BIGINT UNSIGNED NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_attivita_giornata (giornata_id),
  KEY idx_attivita_data_ora (data_ora),
  KEY idx_attivita_tipo (tipo),
  KEY idx_attivita_fonte (fonte),

  CONSTRAINT fk_attivita_giornata
    FOREIGN KEY (giornata_id)
    REFERENCES diario_giornaliero(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT chk_attivita_nonnegative
    CHECK (
      (durata_min IS NULL OR durata_min >= 0)
      AND (distanza_km IS NULL OR distanza_km >= 0)
      AND (calorie_attive_dispositivo IS NULL OR calorie_attive_dispositivo >= 0)
      AND (fc_media IS NULL OR fc_media >= 0)
      AND (fc_max IS NULL OR fc_max >= 0)
      AND (
        intensita_percepita_0_10 IS NULL
        OR intensita_percepita_0_10 BETWEEN 0 AND 10
      )
    )
) ENGINE=InnoDB;


CREATE TABLE integratori (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  integratore VARCHAR(255) NOT NULL,
  marca VARCHAR(255) NULL,
  dose DECIMAL(12,3) NULL,

  unita_dose ENUM(
    'mg',
    'g',
    'mcg',
    'UI',
    'capsula',
    'compressa',
    'misurino',
    'altro'
  ) NOT NULL DEFAULT 'altro',

  frequenza VARCHAR(255) NULL,
  momento VARCHAR(255) NULL,
  motivo TEXT NULL,
  note_composizione TEXT NULL,

  stato ENUM(
    'Attivo',
    'Occasionale',
    'Sospeso',
    'Da valutare'
  ) NOT NULL DEFAULT 'Da valutare',

  data_inizio DATE NULL,
  data_fine DATE NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_integratori_nome (integratore),
  KEY idx_integratori_stato (stato),

  CONSTRAINT chk_integratori_dose
    CHECK (dose IS NULL OR dose >= 0),

  CONSTRAINT chk_integratori_date
    CHECK (data_fine IS NULL OR data_inizio IS NULL OR data_fine >= data_inizio)
) ENGINE=InnoDB;


CREATE TABLE assunzioni (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  assunzione VARCHAR(255) NOT NULL,
  data_ora DATETIME NOT NULL,

  integratore_id BIGINT UNSIGNED NULL,
  giornata_id BIGINT UNSIGNED NULL,

  dose_assunta DECIMAL(12,3) NULL,

  unita ENUM(
    'mg',
    'g',
    'mcg',
    'UI',
    'capsula',
    'compressa',
    'misurino',
    'altro'
  ) NOT NULL DEFAULT 'altro',

  esito ENUM(
    'Preso',
    'Saltato',
    'Non noto'
  ) NOT NULL DEFAULT 'Non noto',

  note TEXT NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_assunzioni_giornata (giornata_id),
  KEY idx_assunzioni_integratore (integratore_id),
  KEY idx_assunzioni_data_ora (data_ora),
  KEY idx_assunzioni_esito (esito),

  CONSTRAINT fk_assunzioni_integratore
    FOREIGN KEY (integratore_id)
    REFERENCES integratori(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,

  CONSTRAINT fk_assunzioni_giornata
    FOREIGN KEY (giornata_id)
    REFERENCES diario_giornaliero(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT chk_assunzioni_dose
    CHECK (dose_assunta IS NULL OR dose_assunta >= 0)
) ENGINE=InnoDB;


CREATE TABLE osservazioni_apprendimenti (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  osservazione VARCHAR(255) NOT NULL,
  data DATE NULL,

  tipo ENUM(
    'Preferenza',
    'Esclusione',
    'Fame',
    'Energia',
    'Sazieta',
    'Gradimento',
    'Digestione',
    'Praticita',
    'Performance',
    'Regola',
    'Correzione',
    'Altro'
  ) NOT NULL DEFAULT 'Altro',

  fonte ENUM(
    'Utente',
    'Osservazione trend',
    'Assistente'
  ) NOT NULL DEFAULT 'Utente',

  dettaglio TEXT NULL,
  apprendimento TEXT NULL,
  azione_futura TEXT NULL,
  valutazione_0_10 DECIMAL(4,2) NULL,

  attiva TINYINT(1) NOT NULL DEFAULT 1,
  regola_stabile TINYINT(1) NOT NULL DEFAULT 0,

  giornata_id BIGINT UNSIGNED NULL,
  pasto_id BIGINT UNSIGNED NULL,

  creato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aggiornato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  KEY idx_osservazioni_data (data),
  KEY idx_osservazioni_tipo (tipo),
  KEY idx_osservazioni_attiva (attiva),
  KEY idx_osservazioni_regola (regola_stabile),
  KEY idx_osservazioni_giornata (giornata_id),
  KEY idx_osservazioni_pasto (pasto_id),

  CONSTRAINT fk_osservazioni_giornata
    FOREIGN KEY (giornata_id)
    REFERENCES diario_giornaliero(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_osservazioni_pasto
    FOREIGN KEY (pasto_id)
    REFERENCES pasti(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT chk_osservazioni_valutazione
    CHECK (
      valutazione_0_10 IS NULL
      OR valutazione_0_10 BETWEEN 0 AND 10
    )
) ENGINE=InnoDB;


-- ============================================================================
-- 2. TRIGGER DI COERENZA
-- ============================================================================
-- Se una voce alimentare è associata a un pasto, la giornata della voce deve
-- coincidere con quella del pasto. Se giornata_id è NULL viene ereditata.
-- Lo stesso principio viene applicato alle osservazioni legate a un pasto.
-- ============================================================================

DELIMITER $$

CREATE TRIGGER trg_voci_bi_coerenza_giornata
BEFORE INSERT ON voci_alimentari
FOR EACH ROW
BEGIN
  DECLARE v_giornata_id BIGINT UNSIGNED DEFAULT NULL;

  IF NEW.pasto_id IS NOT NULL THEN
    SELECT giornata_id
      INTO v_giornata_id
    FROM pasti
    WHERE id = NEW.pasto_id;

    IF NEW.giornata_id IS NULL THEN
      SET NEW.giornata_id = v_giornata_id;
    ELSEIF v_giornata_id IS NOT NULL AND NEW.giornata_id <> v_giornata_id THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Voce alimentare e pasto appartengono a giornate diverse';
    END IF;
  END IF;
END$$


CREATE TRIGGER trg_voci_bu_coerenza_giornata
BEFORE UPDATE ON voci_alimentari
FOR EACH ROW
BEGIN
  DECLARE v_giornata_id BIGINT UNSIGNED DEFAULT NULL;

  IF NEW.pasto_id IS NOT NULL THEN
    SELECT giornata_id
      INTO v_giornata_id
    FROM pasti
    WHERE id = NEW.pasto_id;

    IF NEW.giornata_id IS NULL THEN
      SET NEW.giornata_id = v_giornata_id;
    ELSEIF v_giornata_id IS NOT NULL AND NEW.giornata_id <> v_giornata_id THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Voce alimentare e pasto appartengono a giornate diverse';
    END IF;
  END IF;
END$$


CREATE TRIGGER trg_osservazioni_bi_coerenza_giornata
BEFORE INSERT ON osservazioni_apprendimenti
FOR EACH ROW
BEGIN
  DECLARE v_giornata_id BIGINT UNSIGNED DEFAULT NULL;

  IF NEW.pasto_id IS NOT NULL THEN
    SELECT giornata_id
      INTO v_giornata_id
    FROM pasti
    WHERE id = NEW.pasto_id;

    IF NEW.giornata_id IS NULL THEN
      SET NEW.giornata_id = v_giornata_id;
    ELSEIF v_giornata_id IS NOT NULL AND NEW.giornata_id <> v_giornata_id THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Osservazione e pasto appartengono a giornate diverse';
    END IF;
  END IF;
END$$


CREATE TRIGGER trg_osservazioni_bu_coerenza_giornata
BEFORE UPDATE ON osservazioni_apprendimenti
FOR EACH ROW
BEGIN
  DECLARE v_giornata_id BIGINT UNSIGNED DEFAULT NULL;

  IF NEW.pasto_id IS NOT NULL THEN
    SELECT giornata_id
      INTO v_giornata_id
    FROM pasti
    WHERE id = NEW.pasto_id;

    IF NEW.giornata_id IS NULL THEN
      SET NEW.giornata_id = v_giornata_id;
    ELSEIF v_giornata_id IS NOT NULL AND NEW.giornata_id <> v_giornata_id THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Osservazione e pasto appartengono a giornate diverse';
    END IF;
  END IF;
END$$

DELIMITER ;


-- ============================================================================
-- 3. VIEW CHE SOSTITUISCONO I ROLLUP NOTION
-- ============================================================================

CREATE OR REPLACE VIEW v_pasti_totali AS
SELECT
  p.id AS pasto_id,
  p.giornata_id,
  p.pasto,
  p.data_ora,
  p.tipo,
  p.contesto,
  p.libero_sociale,
  p.fame_nervosa,
  p.fame_prima_0_10,
  p.sazieta_dopo_0_10,
  p.energia_dopo_0_10,
  p.gradimento_0_10,
  p.note,
  COUNT(v.id) AS numero_voci,
  COALESCE(SUM(v.kcal), 0) AS totale_kcal,
  COALESCE(SUM(v.proteine_g), 0) AS totale_proteine_g,
  COALESCE(SUM(v.carboidrati_g), 0) AS totale_carboidrati_g,
  COALESCE(SUM(v.grassi_g), 0) AS totale_grassi_g,
  COALESCE(SUM(v.fibre_g), 0) AS totale_fibre_g,
  COALESCE(SUM(v.zuccheri_g), 0) AS totale_zuccheri_g,
  COALESCE(SUM(v.alcol_g), 0) AS totale_alcol_g
FROM pasti p
LEFT JOIN voci_alimentari v
  ON v.pasto_id = p.id
GROUP BY
  p.id,
  p.giornata_id,
  p.pasto,
  p.data_ora,
  p.tipo,
  p.contesto,
  p.libero_sociale,
  p.fame_nervosa,
  p.fame_prima_0_10,
  p.sazieta_dopo_0_10,
  p.energia_dopo_0_10,
  p.gradimento_0_10,
  p.note;


CREATE OR REPLACE VIEW v_diario_nutrizione AS
SELECT
  d.id AS giornata_id,
  d.data,
  d.giorno,
  d.tipo_giornata,
  d.giornata_chiusa,
  d.target_kcal,
  d.target_proteine_g,
  d.target_carboidrati_g,
  d.target_grassi_g,
  d.target_fibre_g,
  COALESCE(p.numero_pasti, 0) AS numero_pasti,
  COALESCE(v.numero_voci, 0) AS numero_voci,
  COALESCE(v.totale_kcal, 0) AS totale_kcal,
  COALESCE(v.totale_proteine_g, 0) AS totale_proteine_g,
  COALESCE(v.totale_carboidrati_g, 0) AS totale_carboidrati_g,
  COALESCE(v.totale_grassi_g, 0) AS totale_grassi_g,
  COALESCE(v.totale_fibre_g, 0) AS totale_fibre_g,
  COALESCE(v.totale_zuccheri_g, 0) AS totale_zuccheri_g,
  COALESCE(v.totale_alcol_g, 0) AS totale_alcol_g
FROM diario_giornaliero d
LEFT JOIN (
  SELECT
    giornata_id,
    COUNT(*) AS numero_pasti
  FROM pasti
  GROUP BY giornata_id
) p
  ON p.giornata_id = d.id
LEFT JOIN (
  SELECT
    giornata_id,
    COUNT(*) AS numero_voci,
    SUM(kcal) AS totale_kcal,
    SUM(proteine_g) AS totale_proteine_g,
    SUM(carboidrati_g) AS totale_carboidrati_g,
    SUM(grassi_g) AS totale_grassi_g,
    SUM(fibre_g) AS totale_fibre_g,
    SUM(zuccheri_g) AS totale_zuccheri_g,
    SUM(alcol_g) AS totale_alcol_g
  FROM voci_alimentari
  GROUP BY giornata_id
) v
  ON v.giornata_id = d.id;


CREATE OR REPLACE VIEW v_diario_attivita AS
SELECT
  d.id AS giornata_id,
  d.data,
  COUNT(a.id) AS numero_attivita,
  COALESCE(SUM(a.durata_min), 0) AS attivita_durata_totale_min,
  COALESCE(SUM(a.distanza_km), 0) AS attivita_distanza_totale_km,
  COALESCE(SUM(a.calorie_attive_dispositivo), 0) AS calorie_attive_device,
  COALESCE(SUM(a.passi), 0) AS passi_da_attivita,
  AVG(a.fc_media) AS fc_media_attivita,
  MAX(a.fc_max) AS fc_max_giornata
FROM diario_giornaliero d
LEFT JOIN attivita_allenamenti a
  ON a.giornata_id = d.id
GROUP BY d.id, d.data;


CREATE OR REPLACE VIEW v_diario_completo AS
SELECT
  n.giornata_id,
  n.data,
  n.giorno,
  n.tipo_giornata,
  n.giornata_chiusa,

  n.target_kcal,
  n.target_proteine_g,
  n.target_carboidrati_g,
  n.target_grassi_g,
  n.target_fibre_g,

  n.numero_pasti,
  n.numero_voci,
  n.totale_kcal,
  n.totale_proteine_g,
  n.totale_carboidrati_g,
  n.totale_grassi_g,
  n.totale_fibre_g,
  n.totale_zuccheri_g,
  n.totale_alcol_g,

  a.numero_attivita,
  a.attivita_durata_totale_min,
  a.attivita_distanza_totale_km,
  a.calorie_attive_device,
  a.passi_da_attivita,
  a.fc_media_attivita,
  a.fc_max_giornata,

  n.target_kcal - n.totale_kcal AS scostamento_kcal_da_target,
  n.target_proteine_g - n.totale_proteine_g AS scostamento_proteine_g,
  n.target_carboidrati_g - n.totale_carboidrati_g AS scostamento_carboidrati_g,
  n.target_grassi_g - n.totale_grassi_g AS scostamento_grassi_g,
  n.target_fibre_g - n.totale_fibre_g AS scostamento_fibre_g
FROM v_diario_nutrizione n
LEFT JOIN v_diario_attivita a
  ON a.giornata_id = n.giornata_id;


CREATE OR REPLACE VIEW v_integratori_aderenza AS
SELECT
  i.id AS integratore_id,
  i.integratore,
  i.marca,
  i.stato,
  COUNT(a.id) AS assunzioni_registrate,
  SUM(CASE WHEN a.esito = 'Preso' THEN 1 ELSE 0 END) AS prese,
  SUM(CASE WHEN a.esito = 'Saltato' THEN 1 ELSE 0 END) AS saltate,
  SUM(CASE WHEN a.esito = 'Non noto' THEN 1 ELSE 0 END) AS non_note,
  ROUND(
    100 * SUM(CASE WHEN a.esito = 'Preso' THEN 1 ELSE 0 END)
      / NULLIF(
          SUM(CASE WHEN a.esito IN ('Preso', 'Saltato') THEN 1 ELSE 0 END),
          0
        ),
    2
  ) AS aderenza_pct
FROM integratori i
LEFT JOIN assunzioni a
  ON a.integratore_id = i.id
GROUP BY i.id, i.integratore, i.marca, i.stato;

-- ============================================================================
-- 22. PROCEDURE OPZIONALI DI COMODO
-- ============================================================================
-- Non sono indispensabili al modello dati, ma rendono più semplice usare
-- il database da un backend/API.

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_or_create_giornata$$
CREATE PROCEDURE sp_get_or_create_giornata(
  IN p_data DATE,
  OUT p_giornata_id BIGINT UNSIGNED
)
BEGIN
  INSERT INTO diario_giornaliero (
    giorno,
    data,
    tipo_giornata
  ) VALUES (
    DATE_FORMAT(p_data, '%Y-%m-%d'),
    p_data,
    'Non definita'
  )
  ON DUPLICATE KEY UPDATE
    id = LAST_INSERT_ID(id);

  SET p_giornata_id = LAST_INSERT_ID();
END$$


DROP PROCEDURE IF EXISTS sp_delete_giornata$$
CREATE PROCEDURE sp_delete_giornata(
  IN p_giornata_id BIGINT UNSIGNED
)
BEGIN
  DELETE FROM diario_giornaliero
  WHERE id = p_giornata_id;
END$$


DROP PROCEDURE IF EXISTS sp_ricalcola_voce_da_prodotto$$
CREATE PROCEDURE sp_ricalcola_voce_da_prodotto(
  IN p_voce_id BIGINT UNSIGNED
)
BEGIN
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
  WHERE v.id = p_voce_id
    AND v.unita = 'g'
    AND v.quantita IS NOT NULL;
END$$

DELIMITER ;

-- ============================================================================
-- 24. NOTE DI MAPPING NOTION -> SQL
-- ============================================================================
--
-- Diario Giornaliero
--   Notion relation "Pasti"                  -> pasti.giornata_id
--   Notion relation "Voci alimentari"        -> voci_alimentari.giornata_id
--   Notion relation "Misure"                 -> peso_misure.giornata_id
--   Notion relation "Attivita"               -> attivita_allenamenti.giornata_id
--   Notion relation "Assunzioni integratori" -> assunzioni.giornata_id
--   Rollup nutrizionali                      -> v_diario_nutrizione
--   Rollup attività                          -> v_diario_attivita
--
-- Pasti
--   Notion relation "Giornata"               -> pasti.giornata_id
--   Notion relation "Voci"                   -> voci_alimentari.pasto_id
--   Rollup nutrizionali                      -> v_pasti_totali
--
-- Voci Alimentari
--   Notion relation "Giornata"               -> voci_alimentari.giornata_id
--   Notion relation "Pasto"                  -> voci_alimentari.pasto_id
--   Notion relation "Prodotto"               -> voci_alimentari.prodotto_id
--
-- Alimenti & Prodotti
--   Notion relation "Consumi"                -> relazione inversa da
--                                               voci_alimentari.prodotto_id
--
-- Peso & Misure
--   Notion relation "Giornata"               -> peso_misure.giornata_id
--
-- Attività & Allenamenti
--   Notion relation "Giornata"               -> attivita_allenamenti.giornata_id
--
-- Integratori
--   Notion relation "Assunzioni"             -> relazione inversa da
--                                               assunzioni.integratore_id
--
-- Osservazioni & Apprendimenti
--   Notion relation "Giornata"               -> osservazioni_apprendimenti.giornata_id
--   Notion relation "Pasto"                  -> osservazioni_apprendimenti.pasto_id
--
-- Assunzioni
--   Notion relation "Integratore"             -> assunzioni.integratore_id
--   Notion relation "Giornata"                -> assunzioni.giornata_id
--
-- I created_time Notion sono modellati con creato TIMESTAMP DEFAULT CURRENT_TIMESTAMP.
-- I rollup non vengono memorizzati: vengono sempre derivati dai dati atomici.
-- ============================================================================
