
-- View: catalog.collection_hosted_url

-- DROP VIEW catalog.collection_hosted_url;

CREATE OR REPLACE VIEW catalog.collection_hosted_url
 AS
 SELECT c.acronym,
    c.collection_id,
    c.collection_name,
    p.url
   FROM catalog.data_product p
     JOIN catalog.data_collection c ON c.collection_id = p.collection_id
  WHERE p.product_type::text = 'hosted'::text AND p.authoritative = true
  ORDER BY c.acronym;

ALTER TABLE catalog.collection_hosted_url
    OWNER TO catalog;



-- View: catalog.column_stats_view

-- DROP VIEW catalog.column_stats_view;

CREATE OR REPLACE VIEW catalog.column_stats_view
 AS
 SELECT columns.table_schema,
    columns.column_name,
    string_agg(DISTINCT columns.table_name::text, ', '::text) AS string_agg
   FROM information_schema.columns
  WHERE (EXISTS ( SELECT 1
           FROM catalog.data_collection dc
          WHERE dc.acronym::text = upper(columns.table_schema::text)))
  GROUP BY columns.table_schema, columns.column_name
  ORDER BY columns.table_schema, columns.column_name;

ALTER TABLE catalog.column_stats_view
    OWNER TO catalog;


    -- View: catalog.data_artifacts_view

-- DROP VIEW catalog.data_artifacts_view;

CREATE OR REPLACE VIEW catalog.data_artifacts_view
 AS
 SELECT t.table_schema,
    t.table_name,
        CASE
            WHEN gc.type IS NULL THEN 'table'::text
            ELSE 'feature class'::text
        END AS artifact_type,
    ( SELECT p.n_tup_ins
           FROM pg_stat_user_tables p
          WHERE p.relname = t.table_name::name AND p.schemaname = t.table_schema::name) AS record_count,
    gc.type AS spatial_type,
    gc.srid
   FROM information_schema.tables t
     LEFT JOIN geometry_columns gc ON t.table_name::name = gc.f_table_name AND t.table_schema::name = gc.f_table_schema
  WHERE (EXISTS ( SELECT 1
           FROM catalog.data_collection p
          WHERE lower(p.acronym::text) = t.table_schema::name OR lower('catalog_'::text || p.acronym::text) = t.table_schema::name))
  ORDER BY t.table_schema, t.table_name;

ALTER TABLE catalog.data_artifacts_view
    OWNER TO catalog;

-- View: catalog.data_product_item_view

-- DROP VIEW catalog.data_product_item_view;

CREATE OR REPLACE VIEW catalog.data_product_item_view
 AS
 SELECT row_number() OVER ()::integer AS collection_product_id,
    dc.collection_id::integer AS collection_id,
    dc.collection_name,
    dc.acronym,
    ''::character varying(256) AS table_title,
    t.table_name::character varying(256) AS table_name,
        CASE
            WHEN gc.type IS NULL THEN 'table'::text
            ELSE 'feature class'::text
        END::character varying(30) AS artifact_type,
    ( SELECT p.n_tup_ins
           FROM pg_stat_user_tables p
          WHERE p.relname = t.table_name::name AND p.schemaname = t.table_schema::name) AS record_count,
    COALESCE(gc.type, 'NA'::character varying) AS spatial_type,
    gc.srid
   FROM information_schema.tables t
     JOIN catalog.data_collection dc ON dc.acronym::text = upper(t.table_schema::text)
     LEFT JOIN geometry_columns gc ON t.table_name::name = gc.f_table_name AND t.table_schema::name = gc.f_table_schema
  WHERE (EXISTS ( SELECT 1
           FROM catalog.data_collection p
          WHERE lower(p.acronym::text) = t.table_schema::name))
  ORDER BY dc.collection_name, (t.table_name::character varying(256));

ALTER TABLE catalog.data_product_item_view
    OWNER TO catalog;


-- View: catalog.load_stats_view

-- DROP VIEW catalog.load_stats_view;

CREATE OR REPLACE VIEW catalog.load_stats_view
 AS
 SELECT lower(load_profile.acronym::text) AS schema_name,
    lower(load_profile.entity_name_revised::text) AS table_name,
    load_profile.record_count,
    load_profile.srid,
    ( SELECT c.reltuples::bigint AS reltuples
           FROM pg_class c
             JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE c.relkind = 'r'::"char" AND c.relname = lower(load_profile.entity_name_revised::text) AND n.nspname = lower(load_profile.acronym::text)) AS loaded_estimate_counts
   FROM catalog.load_profile;

ALTER TABLE catalog.load_stats_view
    OWNER TO egdbadmin;

-- View: catalog.product_configs

-- DROP VIEW catalog.product_configs;

CREATE OR REPLACE VIEW catalog.product_configs
 AS
 WITH a AS (
         SELECT c.collection_id,
            c.collection_name,
            c.acronym,
            ( SELECT min(p.url::text) AS min
                   FROM catalog.data_product p
                  WHERE p.collection_id = c.collection_id AND p.product_type::text = 'hosted'::text) AS sample_url,
            ( SELECT string_agg(p.url::text, ';'::text) AS string_agg
                   FROM catalog.data_product p
                  WHERE p.collection_id = c.collection_id AND p.product_type::text = 'hosted'::text AND p.public_url = true) AS urls,
            ( SELECT p.url
                   FROM catalog.data_product p
                  WHERE p.collection_id = c.collection_id AND p.product_type::text = 'factsheet'::text) AS factsheet
           FROM catalog.data_collection c
        )
 SELECT a.collection_id,
    a.collection_name,
    a.acronym,
    COALESCE(a.sample_url, ''::character varying::text) AS sample_url,
    COALESCE(a.urls, ''::text) AS urls,
    COALESCE(a.factsheet, ''::character varying) AS factsheet
   FROM a
  ORDER BY a.collection_name;

ALTER TABLE catalog.product_configs
    OWNER TO catalog;

-- View: catalog.product_table_counts

-- DROP VIEW catalog.product_table_counts;

CREATE OR REPLACE VIEW catalog.product_table_counts
 AS
 SELECT tables.table_schema,
    count(tables.table_name) AS entity_count
   FROM information_schema.tables
  WHERE tables.table_catalog::name = 'bah_egis'::name AND (EXISTS ( SELECT 1
           FROM catalog.data_collection p
          WHERE lower(p.acronym::text) = tables.table_schema::name))
  GROUP BY tables.table_schema;

ALTER TABLE catalog.product_table_counts
    OWNER TO catalog;