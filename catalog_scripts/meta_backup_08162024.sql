--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 16.3

-- Started on 2024-09-05 10:39:35

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 129 (class 2615 OID 685361)
-- Name: meta; Type: SCHEMA; Schema: -; Owner: catalog
--

CREATE SCHEMA meta;


ALTER SCHEMA meta OWNER TO catalog;

--
-- TOC entry 538 (class 1259 OID 693694)
-- Name: data_product_source_id_seq; Type: SEQUENCE; Schema: meta; Owner: etl_writer
--

CREATE SEQUENCE meta.data_product_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE meta.data_product_source_id_seq OWNER TO etl_writer;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 537 (class 1259 OID 693688)
-- Name: data_product_source; Type: TABLE; Schema: meta; Owner: etl_writer
--

CREATE TABLE meta.data_product_source (
    data_product_id bigint NOT NULL,
    source_id bigint DEFAULT nextval('meta.data_product_source_id_seq'::regclass) NOT NULL,
    source_type text NOT NULL,
    path text NOT NULL,
    active_flag boolean DEFAULT false,
    polling_frequency text,
    source_level text DEFAULT 'PUBLIC'::text
);


ALTER TABLE meta.data_product_source OWNER TO etl_writer;

--
-- TOC entry 536 (class 1259 OID 693686)
-- Name: data_product_id_seq; Type: SEQUENCE; Schema: meta; Owner: etl_writer
--

CREATE SEQUENCE meta.data_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE meta.data_product_id_seq OWNER TO etl_writer;

--
-- TOC entry 535 (class 1259 OID 693679)
-- Name: data_product; Type: TABLE; Schema: meta; Owner: etl_writer
--

CREATE TABLE meta.data_product (
    data_product_id bigint DEFAULT nextval('meta.data_product_id_seq'::regclass) NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    schema_prefix text NOT NULL,
    dcat_meta_catalog_id bigint,
    egis_publish_flag boolean NOT NULL
);


ALTER TABLE meta.data_product OWNER TO etl_writer;

--
-- TOC entry 539 (class 1259 OID 695680)
-- Name: data_product_sources_view; Type: VIEW; Schema: meta; Owner: etl_writer
--

CREATE VIEW meta.data_product_sources_view AS
 SELECT p.data_product_id AS collection_id,
    p.name AS collection_name,
    p.schema_prefix AS collection_schema,
    p.short_name AS collection_code,
    p.egis_publish_flag,
    s.source_id,
    s.source_type,
    s.path,
    s.source_level
   FROM (meta.data_product p
     JOIN meta.data_product_source s ON ((p.data_product_id = s.data_product_id)))
  WHERE (s.source_level = 'PUBLIC'::text)
  ORDER BY p.data_product_id;


ALTER VIEW meta.data_product_sources_view OWNER TO etl_writer;

--
-- TOC entry 540 (class 1259 OID 695685)
-- Name: data_products_view; Type: VIEW; Schema: meta; Owner: egdbadmin
--

CREATE VIEW meta.data_products_view AS
 SELECT p.data_product_id AS collection_id,
    p.name AS collection_name,
    p.schema_prefix AS collection_schema,
    p.short_name AS collection_code,
    p.egis_publish_flag,
    s.source_id,
    s.source_type,
    s.path,
    s.source_level
   FROM (meta.data_product p
     LEFT JOIN meta.data_product_source s ON ((p.data_product_id = s.data_product_id)))
  ORDER BY p.data_product_id;


ALTER VIEW meta.data_products_view OWNER TO egdbadmin;

--
-- TOC entry 542 (class 1259 OID 695904)
-- Name: distinct_columns_view; Type: VIEW; Schema: meta; Owner: egdbadmin
--

CREATE VIEW meta.distinct_columns_view AS
 SELECT DISTINCT c.column_name,
    string_agg((((c.table_schema)::text || '.'::text) || (c.table_name)::text), ','::text) AS tables
   FROM information_schema.columns c
  WHERE ((EXISTS ( SELECT 1
           FROM meta.data_product
          WHERE (lower(data_product.schema_prefix) = (c.table_schema)::name))) AND ((c.table_name)::name !~~ '%_1'::text) AND ((c.table_name)::name !~~ 'i%'::text) AND ((c.table_name)::name !~~ '%_old'::text) AND ((c.column_name)::name !~~ 'objectid_%'::text))
  GROUP BY c.column_name
  ORDER BY c.column_name;


ALTER VIEW meta.distinct_columns_view OWNER TO egdbadmin;

--
-- TOC entry 7538 (class 0 OID 693679)
-- Dependencies: 535
-- Data for Name: data_product; Type: TABLE DATA; Schema: meta; Owner: etl_writer
--

INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'CSPI', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (2, 'Corps Water Management System', 'CWMS', 'CWMS', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (3, 'Dredging Information System', 'DIS', 'DIS', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (4, 'Flood Inundation Mapping', 'FIM', 'FIM', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (5, 'Formerly Used Defense Sites', 'FUDS', 'FUDS', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (6, 'Ice Jam Database', 'IB', 'IB', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (7, 'Inland Electronic Navigational Charts', 'IENC', 'IENC', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (11, 'National Channel Framework', 'NCF', 'NCF', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (12, 'National Inventory of Dams', 'NID', 'NID', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (21, 'National Levee Database', 'NLD', 'NLD', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (10, 'Navigation and Civil Works Decision Support', 'NDC', 'NDC', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (16, 'Real Estate Management Geospatial', 'REMIS', 'REMIS', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (15, 'Recreation', 'RECREATION', 'RECREATION', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (18, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES', 'BOUNDARIES', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (19, 'USACE Master Site List', 'MSL', 'MSL', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (17, 'USACE Reservoirs', 'RESERVOIR', 'RESERVOIR', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (20, 'USACE Survey Monument Archives', 'USMART', 'USMART', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (23, 'Inland Waterways ', 'INW', 'INW', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (24, 'Military Installations Training Areas', 'MIRTA', 'MIRTA', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (25, 'Port Statistical Areas', 'PORT', 'PORT', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (22, 'National Coastal Structures', 'NCS', 'NCS', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (13, 'National Sediment Management Framework ', 'NSMF', 'NSMF', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (8, 'Joint Airborne Lidar Bathymetry', 'JABLTCX', 'JABLTCX', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (9, 'USACE Jurisdictional Determinations', 'JURISDICTION', 'JURISDICTION', NULL, false);
INSERT INTO meta.data_product (data_product_id, name, short_name, schema_prefix, dcat_meta_catalog_id, egis_publish_flag) VALUES (14, 'Operations & Maintenance ', 'OMBIL', 'OMBIL', NULL, false);


--
-- TOC entry 7540 (class 0 OID 693688)
-- Dependencies: 537
-- Data for Name: data_product_source; Type: TABLE DATA; Schema: meta; Owner: etl_writer
--

INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (21, 72, 'FEATURE_SERVER', ' https://ags03.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer', false, 'DAILY', 'RESTRICTED');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (21, 73, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer', true, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (12, 51, 'FEATURE_SERVER', 'https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NID_v1/FeatureServer', true, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (1, 9, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer', true, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (2, 53, 'FEATURE_SERVER', 'https://cwms-data.usace.army.mil/cwms-data/basins', false, 'DAILY', 'RESTRICTED');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (3, 52, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (5, 33, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (6, 34, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Current_Ice_Jams/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (6, 55, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Ice_Jams_Historic/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (7, 35, 'FEATURE_SERVER', 'https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (10, 46, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/linktons/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (10, 36, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/pports21/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (10, 47, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (10, 48, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Docks/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (11, 37, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (13, 38, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (14, 6, 'FEATURE_SERVER', 'https://cwbi.ops.usace.army.mil/   ', false, 'DAILY', 'RESTRICTED');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (15, 49, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_recreation_areas/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (16, 39, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (17, 40, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_rez/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (18, 43, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_dist/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (18, 44, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_div/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (18, 41, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (18, 42, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_cw_divisions/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (20, 45, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (22, 50, 'FEATURE_SERVER', 'https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (23, 71, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Standardized_Inland_Waterway_Polygons/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (23, 67, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/Hosted/AIS_NWN/FeatureServer/0', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (24, 68, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/mirta/FeatureServer', false, 'DAILY', 'PUBLIC');
INSERT INTO meta.data_product_source (data_product_id, source_id, source_type, path, active_flag, polling_frequency, source_level) VALUES (25, 69, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Port_Statistical_Area/FeatureServer', false, 'DAILY', 'PUBLIC');


--
-- TOC entry 7550 (class 0 OID 0)
-- Dependencies: 536
-- Name: data_product_id_seq; Type: SEQUENCE SET; Schema: meta; Owner: etl_writer
--

SELECT pg_catalog.setval('meta.data_product_id_seq', 25, true);


--
-- TOC entry 7551 (class 0 OID 0)
-- Dependencies: 538
-- Name: data_product_source_id_seq; Type: SEQUENCE SET; Schema: meta; Owner: etl_writer
--

SELECT pg_catalog.setval('meta.data_product_source_id_seq', 73, true);


--
-- TOC entry 7377 (class 2606 OID 693685)
-- Name: data_product pk_data_product; Type: CONSTRAINT; Schema: meta; Owner: etl_writer
--

ALTER TABLE ONLY meta.data_product
    ADD CONSTRAINT pk_data_product PRIMARY KEY (data_product_id);


--
-- TOC entry 7381 (class 2606 OID 695707)
-- Name: data_product_source pk_source_id; Type: CONSTRAINT; Schema: meta; Owner: etl_writer
--

ALTER TABLE ONLY meta.data_product_source
    ADD CONSTRAINT pk_source_id PRIMARY KEY (source_id);


--
-- TOC entry 7378 (class 1259 OID 695664)
-- Name: fki_fk_data_product; Type: INDEX; Schema: meta; Owner: etl_writer
--

CREATE INDEX fki_fk_data_product ON meta.data_product_source USING btree (data_product_id);


--
-- TOC entry 7379 (class 1259 OID 695724)
-- Name: fki_fk_data_product_id; Type: INDEX; Schema: meta; Owner: etl_writer
--

CREATE INDEX fki_fk_data_product_id ON meta.data_product_source USING btree (data_product_id);


--
-- TOC entry 7382 (class 2606 OID 695719)
-- Name: data_product_source fk_data_product_id; Type: FK CONSTRAINT; Schema: meta; Owner: etl_writer
--

ALTER TABLE ONLY meta.data_product_source
    ADD CONSTRAINT fk_data_product_id FOREIGN KEY (data_product_id) REFERENCES meta.data_product(data_product_id) NOT VALID;


--
-- TOC entry 7547 (class 0 OID 0)
-- Dependencies: 129
-- Name: SCHEMA meta; Type: ACL; Schema: -; Owner: catalog
--

REVOKE ALL ON SCHEMA meta FROM catalog;
GRANT USAGE ON SCHEMA meta TO catalog WITH GRANT OPTION;
GRANT USAGE ON SCHEMA meta TO PUBLIC;


--
-- TOC entry 7548 (class 0 OID 0)
-- Dependencies: 537
-- Name: TABLE data_product_source; Type: ACL; Schema: meta; Owner: etl_writer
--

GRANT SELECT ON TABLE meta.data_product_source TO PUBLIC;


--
-- TOC entry 7549 (class 0 OID 0)
-- Dependencies: 535
-- Name: TABLE data_product; Type: ACL; Schema: meta; Owner: etl_writer
--

GRANT SELECT ON TABLE meta.data_product TO PUBLIC;


-- Completed on 2024-09-05 10:39:36

--
-- PostgreSQL database dump complete
--

