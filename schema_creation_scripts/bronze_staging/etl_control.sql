-- Table: bronze_staging.etl_control

DROP TABLE IF EXISTS bronze_staging.etl_control CASCADE;

CREATE TABLE IF NOT EXISTS bronze_staging.etl_control
(
    etl_run_id bigint NOT NULL DEFAULT nextval('bronze_staging.etl_master_table_seq'::regclass),
    source_id bigint NOT NULL,
    run_datetime timestamp without time zone NOT NULL,
    step text COLLATE pg_catalog."default",
    status text COLLATE pg_catalog."default",
	load_id bigint,
    CONSTRAINT pk_etl_run_id PRIMARY KEY (etl_run_id),
    CONSTRAINT fk_etl_source_id FOREIGN KEY (source_id)
        REFERENCES meta.data_product_source (source_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
	 CONSTRAINT fk_load_history_id FOREIGN KEY (load_id)
        REFERENCES bronze_staging.load_history (load_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS bronze_staging.etl_control
    OWNER to bronze_staging;

GRANT ALL ON TABLE bronze_staging.etl_control TO bronze_staging;

create view bronze_staging.etl_control_view as
SELECT s.data_product_id,
    s.source_id,
    s.source_type,
    s.path,
    s.polling_frequency,
    s.source_level,
    ( SELECT max(e.run_datetime) AS max
           FROM bronze_staging.etl_control e
          WHERE e.source_id = s.source_id) AS last_run_datetime
   FROM meta.data_product_source s
  WHERE s.active_flag AND s.source_level = 'PUBLIC'::text;

GRANT ALL ON TABLE bronze_staging.etl_control_view TO bronze_staging;