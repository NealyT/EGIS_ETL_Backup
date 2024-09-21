
GRANT CREATE ON DATABASE egdb TO etl_writer;

psql -h localhost -U my_user -d my_database
----------------------------------------------------
SELECT table_schema,
       pg_size_pretty(SUM(pg_total_relation_size(table_schema||'.'|| table_name))) AS total_size
FROM  information_schema.tables
group by table_schema
order by table_schema
---------------------------------------------------
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM test7;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM test7;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM test7;
REVOKE ALL ON DATABASE egdb FROM test7;
drop schema test7
REVOKE test7 FROM egdb;
drop role test7
------------------------------------------------------------------------
INSERT INTO etl_loader.column_mapping (column_name, column_name_simple, mapped_column_name, table_schema)
(with a as (
select distinct column_name, regexp_replace(column_name,'_','','g') column_name_simple
	from information_schema.columns
	where table_schema = 'cspi'
	and table_name !~ 'i[0-9]+'
order by column_name_simple),
b as (
select distinct column_name,
	regexp_replace(column_name,'_','','g') column_name_simple,
	column_name as mapped_column_name,
	(select a.column_name from a where a.column_name_simple = regexp_replace(i.column_name,'_','','g')
	and a.column_name like '%_%' limit 1) as matched_column,
	table_schema
	from information_schema.columns i
	where table_schema = 'cspi'
and table_name !~ 'i[0-9]+' order by 1)
	select b.column_name, column_name_simple,
	--coalesce(matched_column,mapped_column_name) best,
	CASE
		WHEN matched_column is not null and matched_column like '%_%' THEN matched_column
		ELSE mapped_column_name
	END AS mapped_column_name,
	table_schema
	from b)
except
	(select column_name, column_name_simple, mapped_column_name, table_schema
	from etl_loader.column_mapping where table_schema='cspi');

------------------------------------------------------------------------
delete from
 sde.sde_layers l
WHERE not exists (SELECT 1 FROM information_schema.schemata s where s.schema_name = l.owner);
------------------------------------------------------------------------
delete from
 sde.sde_layers
WHERE owner = 'nsmf';
------------------------------------------------------------------------
select * from sde.sde_layer_stats s where not exists (select 1
	from sde.sde_layers l where l.layer_id = s.layer_id)
------------------------------------------------------------------------
select * from sde.sde_layer_locks s where not exists (select 1
	from sde.sde_layers l where l.layer_id = s.layer_id)
------------------------------------------------------------------------

select '''nld.'|| revised_name|| ''' as table_name, '||estimated_feature_count||' as estimated, count(*) as count from nld.'|| revised_name
	|| ' union all '
from etl_loader.load_history_item where  load_id = (select max(load_id) from  etl_loader.load_history )
------------------------------------------------------------------------

with a as (
select regexp_replace(column_name,'_','','g') column_name_simple from information_schema.columns
where table_schema = 'cspi'
and table_name !~ 'i[0-9]+'
	group by regexp_replace(column_name,'_','','g')),
	 b as (
select column_name, regexp_replace(column_name,'_','','g') column_name_simple, table_schema, table_name from information_schema.columns
where table_schema = 'cspi'
and table_name !~ 'i[0-9]+'),
c as (
select distinct b.column_name, b.column_name_simple, b.column_name as mapped_column_name, b.table_schema
	from b join a on b.column_name_simple = a.column_name_simple
	where b.column_name != b.column_name_simple)
select 	distinct ROW_NUMBER() OVER (ORDER BY column_name) AS column_mapping_id, c.*
	from c
order by column_name
------------------------------------------------------------------------

select properties_json->>'name' as entity_name,
	json_array_elements(properties_json->'fields')->>'name' as column_name,
	estimated_feature_count
	from  bronze_staging.load_history_item
	where load_id = 4
------------------------------------------------------------------------
select properties_json->>'name' as entity_name,
	estimated_feature_count
	from  bronze_staging.load_history_item
	where load_id = 4

	SELECT load_id,
	json_array_elements(properties_json->'layers')->>'name' as layer_name ,
	json_array_elements(properties_json->'layers')->>'geometryType' as layer_type
	FROM bronze_staging.load_history
	where load_id =4
	union all
		SELECT load_id,
	json_array_elements(properties_json->'tables')->>'name' as layer_name ,
	'na' as layer_type
	FROM bronze_staging.load_history
	where load_id =4
------------------------------------------------------------------------

SELECT load_id, json_array_elements(definition->'layers') AS layers FROM bronze_staging.load_history
ORDER BY load_id ASC
------------------------------------------------------------------------
select * from sde.sde_layers where owner = 'catalog_nld';
------------------------------------------------------------------------
select * from sde.sde_table_registry where schema = 'catalog_nld';
------------------------------------------------------------------------
select * from sde.sde_column_registry where schema = 'catalog_nld';
------------------------------------------------------------------------
select * from pg_stats where schemaname = 'nld'
------------------------------------------------------------------------
SELECT relname, n_live_tup from pg_stat_all_tables  where schemaname = 'nld'
and relname not like 'i%'
------------------------------------------------------------------------
SELECT * FROM pg_depend
------------------------------------------------------------------------
SELECT * FROM pg_user WHERE usename = 'test'
------------------------------------------------------------------------
SELECT
    r.rolname AS role_name,
    n.nspname AS schemaname,
    c.relname AS object_name,
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized view'
        WHEN 'S' THEN 'sequence'
        WHEN 'f' THEN 'foreign table'
        WHEN 'p' THEN 'partitioned table'
        ELSE c.relkind::text
    END AS object_type
FROM
    pg_shdepend d
JOIN
    pg_roles r ON r.oid = d.refobjid
JOIN
    pg_class c ON c.oid = d.objid
JOIN
    pg_namespace n ON c.relnamespace = n.oid
WHERE
    r.rolname = 'test';
------------------------------------------------------------------------