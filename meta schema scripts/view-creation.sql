
create or replace view meta.product_table_counts as
 SELECT table_schema,
    count(table_name) AS entity_count
   FROM information_schema.tables
  WHERE table_catalog::name = 'egdb'::name AND (EXISTS ( SELECT 1
           FROM meta.data_collection p
          WHERE lower(p.acronym::text) = tables.table_schema::name))
  GROUP BY table_schema;

create or replace view meta.column_stats_view as
 SELECT table_schema,
    column_name,
    string_agg(DISTINCT table_name::text, ', '::text) AS string_agg
   FROM information_schema.columns
  WHERE (EXISTS ( SELECT 1
           FROM meta.data_collection dc
          WHERE dc.acronym::text = upper(columns.table_schema::text)))
  GROUP BY table_schema, column_name
  ORDER BY table_schema, column_name;


  create or replace view meta.data_artifacts_view as
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
           FROM meta.data_collection p
          WHERE lower(p.acronym::text) = t.table_schema::name))
  ORDER BY t.table_schema, t.table_name;