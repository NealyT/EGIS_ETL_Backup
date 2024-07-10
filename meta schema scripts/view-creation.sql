
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