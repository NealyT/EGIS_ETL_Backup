--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

-- Started on 2024-07-17 21:08:18

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
-- TOC entry 26 (class 2615 OID 87759)
-- Name: catalog; Type: SCHEMA; Schema: -; Owner: catalog
--
CREATE SCHEMA ogr_system_tables AUTHORIZATION catalog;
CREATE SCHEMA catalog ;


ALTER SCHEMA catalog OWNER TO catalog;

--
-- TOC entry 241 (class 1259 OID 89489)
-- Name: artifact_id_seq; Type: SEQUENCE; Schema: catalog; Owner: postgres
--

CREATE SEQUENCE catalog.artifact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalog.artifact_id_seq OWNER TO catalog;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 242 (class 1259 OID 89498)
-- Name: data_collection; Type: TABLE; Schema: catalog; Owner: catalog
--

CREATE TABLE catalog.data_collection (
    collection_id bigint NOT NULL,
    collection_name character varying(256),
    acronym character varying(20)
);


ALTER TABLE catalog.data_collection OWNER TO catalog;

--
-- TOC entry 244 (class 1259 OID 89504)
-- Name: data_product; Type: TABLE; Schema: catalog; Owner: catalog
--

CREATE TABLE catalog.data_product (
    collection_id bigint,
    product_id bigint NOT NULL,
    product_type character varying(256),
    url character varying(256),
    public_url boolean NOT NULL,
    format character varying(30),
    authoritative boolean
);


ALTER TABLE catalog.data_product OWNER TO catalog;

--
-- TOC entry 248 (class 1259 OID 166188)
-- Name: collection_hosted_url; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.collection_hosted_url AS
 SELECT c.acronym,
    c.collection_id,
    c.collection_name,
    p.url
   FROM (catalog.data_product p
     JOIN catalog.data_collection c ON ((c.collection_id = p.collection_id)))
  WHERE (((p.product_type)::text = 'hosted'::text) AND (p.authoritative = true))
  ORDER BY c.acronym;


ALTER VIEW catalog.collection_hosted_url OWNER TO catalog;

--
-- TOC entry 468 (class 1259 OID 241215)
-- Name: column_stats_view; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.column_stats_view AS
 SELECT table_schema,
    column_name,
    string_agg(DISTINCT (table_name)::text, ', '::text) AS string_agg
   FROM information_schema.columns
  WHERE (EXISTS ( SELECT 1
           FROM catalog.data_collection dc
          WHERE ((dc.acronym)::text = upper((columns.table_schema)::text))))
  GROUP BY table_schema, column_name
  ORDER BY table_schema, column_name;


ALTER VIEW catalog.column_stats_view OWNER TO catalog;

--
-- TOC entry 466 (class 1259 OID 241004)
-- Name: data_artifacts_view; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.data_artifacts_view AS
 SELECT t.table_schema,
    t.table_name,
        CASE
            WHEN (gc.type IS NULL) THEN 'table'::text
            ELSE 'feature class'::text
        END AS artifact_type,
    ( SELECT p.n_tup_ins
           FROM pg_stat_user_tables p
          WHERE ((p.relname = (t.table_name)::name) AND (p.schemaname = (t.table_schema)::name))) AS record_count,
    gc.type AS spatial_type,
    gc.srid
   FROM (information_schema.tables t
     LEFT JOIN public.geometry_columns gc ON ((((t.table_name)::name = gc.f_table_name) AND ((t.table_schema)::name = gc.f_table_schema))))
  WHERE (EXISTS ( SELECT 1
           FROM catalog.data_collection p
          WHERE (lower((p.acronym)::text) = (t.table_schema)::name)))
  ORDER BY t.table_schema, t.table_name;


ALTER VIEW catalog.data_artifacts_view OWNER TO catalog;

--
-- TOC entry 243 (class 1259 OID 89503)
-- Name: data_collection_collection_id_seq; Type: SEQUENCE; Schema: catalog; Owner: postgres
--

ALTER TABLE catalog.data_collection ALTER COLUMN collection_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME catalog.data_collection_collection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 571 (class 1259 OID 362629)
-- Name: data_collection_filter_id_seq; Type: SEQUENCE; Schema: catalog; Owner: postgres
--

CREATE SEQUENCE catalog.data_collection_filter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalog.data_collection_filter_id_seq OWNER TO catalog;

--
-- TOC entry 620 (class 1259 OID 450270)
-- Name: data_product_item_id_sequence; Type: SEQUENCE; Schema: catalog; Owner: catalog
--

CREATE SEQUENCE catalog.data_product_item_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalog.data_product_item_id_sequence OWNER TO catalog;

--
-- TOC entry 619 (class 1259 OID 450265)
-- Name: data_product_item; Type: TABLE; Schema: catalog; Owner: catalog
--

CREATE TABLE catalog.data_product_item (
    collection_product_id integer DEFAULT nextval('catalog.data_product_item_id_sequence'::regclass),
    collection_id integer,
    collection_name character varying(256),
    acronym character varying(20),
    table_title character varying(256),
    table_name character varying(256) COLLATE pg_catalog."C",
    artifact_type character varying(30),
    record_count bigint,
    spatial_type character varying,
    srid integer,
    reference_product_id integer,
    notest character varying(1000),
    tags character varying(1000),
    item_url character varying(250)
);


ALTER TABLE catalog.data_product_item OWNER TO catalog;

--
-- TOC entry 618 (class 1259 OID 450260)
-- Name: data_product_item_view; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.data_product_item_view AS
 SELECT (row_number() OVER ())::integer AS collection_product_id,
    (dc.collection_id)::integer AS collection_id,
    dc.collection_name,
    dc.acronym,
    ''::character varying(256) AS table_title,
    (t.table_name)::character varying(256) AS table_name,
    (
        CASE
            WHEN (gc.type IS NULL) THEN 'table'::text
            ELSE 'feature class'::text
        END)::character varying(30) AS artifact_type,
    ( SELECT p.n_tup_ins
           FROM pg_stat_user_tables p
          WHERE ((p.relname = (t.table_name)::name) AND (p.schemaname = (t.table_schema)::name))) AS record_count,
    COALESCE(gc.type, 'NA'::character varying) AS spatial_type,
    gc.srid
   FROM ((information_schema.tables t
     JOIN catalog.data_collection dc ON (((dc.acronym)::text = upper((t.table_schema)::text))))
     LEFT JOIN public.geometry_columns gc ON ((((t.table_name)::name = gc.f_table_name) AND ((t.table_schema)::name = gc.f_table_schema))))
  WHERE (EXISTS ( SELECT 1
           FROM catalog.data_collection p
          WHERE (lower((p.acronym)::text) = (t.table_schema)::name)))
  ORDER BY dc.collection_name, ((t.table_name)::character varying(256));


ALTER VIEW catalog.data_product_item_view OWNER TO catalog;

--
-- TOC entry 245 (class 1259 OID 89509)
-- Name: data_products_product_id_seq; Type: SEQUENCE; Schema: catalog; Owner: postgres
--

ALTER TABLE catalog.data_product ALTER COLUMN product_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME catalog.data_products_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 467 (class 1259 OID 241210)
-- Name: product_configs; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.product_configs AS
 WITH a AS (
         SELECT c.collection_id,
            c.collection_name,
            c.acronym,
            ( SELECT string_agg((p.url)::text, ';'::text) AS string_agg
                   FROM catalog.data_product p
                  WHERE ((p.collection_id = c.collection_id) AND ((p.product_type)::text = 'hosted'::text) AND (p.public_url = true))) AS urls,
            ( SELECT p.url
                   FROM catalog.data_product p
                  WHERE ((p.collection_id = c.collection_id) AND ((p.product_type)::text = 'factsheet'::text))) AS factsheet
           FROM catalog.data_collection c
        )
 SELECT collection_id,
    collection_name,
    acronym,
    COALESCE(urls, ''::text) AS urls,
    COALESCE(factsheet, ''::character varying) AS factsheet
   FROM a
  ORDER BY collection_name;


ALTER VIEW catalog.product_configs OWNER TO catalog;

--
-- TOC entry 361 (class 1259 OID 176362)
-- Name: product_table_counts; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.product_table_counts AS
 SELECT table_schema,
    count(table_name) AS entity_count
   FROM information_schema.tables
  WHERE (((table_catalog)::name = 'bah_egis'::name) AND (EXISTS ( SELECT 1
           FROM catalog.data_collection p
          WHERE (lower((p.acronym)::text) = (tables.table_schema)::name))))
  GROUP BY table_schema;


ALTER VIEW catalog.product_table_counts OWNER TO catalog;

--
-- TOC entry 6606 (class 0 OID 89498)
-- Dependencies: 242
-- Data for Name: data_collection; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (21, 'National Levee Database', 'NLD');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (6, 'Ice Jam Database', 'IB');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (7, 'Inland Electronic Navigational Charts', 'IENC');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (14, 'Operations & Maintenence ', 'OMBIL');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (15, 'Recreation', 'RECREATION');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (9, 'USACE Juristictional Determinations', 'JURISDICTION');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (16, 'Real Estate Management Geospatial', 'REMIS');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (17, 'USACE Reservoirs', 'RESERVOIR');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (18, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (8, 'Joint Airborn Lidar Bathymetry', 'JABLTCX');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (11, 'National Channel Framework', 'NCF');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (1, 'Coastal Systems Portfolio Initiative', 'CSPI');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (19, 'USACE Master Site List', 'MSL');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (3, 'Dredging Information System', 'DIS');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (4, 'Flood Inundation Mapping', 'FIM');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (5, 'Formerly Used Defense Sites', 'FUDS');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (13, 'National Sediment Managment Framework ', 'NSMF');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (10, 'Navigation and Civil Works Decision Support', 'NDC');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (20, 'USACE Survey Monument Archives', 'USMART');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (12, 'National Inventory of Dams', 'NID');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (2, 'Corps Water Management System', 'CWMS');
INSERT INTO catalog.data_collection (collection_id, collection_name, acronym) OVERRIDING SYSTEM VALUE VALUES (23, 'National Coastal Structures Database', 'NCDB');


--
-- TOC entry 6608 (class 0 OID 89504)
-- Dependencies: 244
-- Data for Name: data_product; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (4, 5, 'webmap', 'https://ags03.sec.usace.army.mil/portal/apps/webappviewer/index.html?id=ca7ff838865349108910a398123ce968', false, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (5, 6, 'website', 'https://www.usace.army.mil/missions/environmental/formerly-used-defense-sites/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (4, 9, 'webmap', 'https://fim.wim.usgs.gov/fim/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (8, 13, 'website', 'https://jalbtcx.usace.army.mil/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'website', 'https://www.arcgis.com/apps/MapSeries/index.html?appid=8f0ed6044c2e46948e25672ce0587437', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (2, 3, 'website', 'https://www.hec.usace.army.mil/cwms', false, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (14, 29, 'hosted', 'https://cwbi.ops.usace.army.mil/   ', false, NULL, false);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (3, 4, 'website', 'https://ndc.ops.usace.army.mil/dis/', false, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (3, 8, 'website', 'https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support/NDC-Dredges/', false, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (1, 7, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (12, 19, 'hosted', 'tbd', false, NULL, false);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (21, 20, 'hosted', 'tbd', false, NULL, false);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (7, 52, 'factsheet', 'https://ienccloud.us/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (21, 35, 'factsheet', 'https://levees.sec.usace.army.mil', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (8, 36, 'factsheet', 'https://www.sam.usace.army.mil/Missions/National-Centers-in-Mobile/Joint-Airborne-Lidar-Bathymetry', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (6, 37, 'factsheet', 'https://icejam.sec.usace.army.mil/ords/f?p=1001:7', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (13, 38, 'factsheet', 'https://www.erdc.usace.army.mil/Locations/CHL/Sediment-Management', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (14, 39, 'factsheet', 'https://www.iwr.usace.army.mil/Missions/Civil-Works-Planning-and-Policy-Support/OMBIL', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (15, 40, 'factsheet', 'https://www.usace.army.mil/missions/civil-works/recreation', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (16, 41, 'factsheet', 'https://www.sam.usace.army.mil/Missions/Real-Estate', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (18, 42, 'factsheet', 'https://www.usace.army.mil/Contact/Unit-Websites', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (20, 43, 'factsheet', 'https://www.agc.army.mil/What-we-do/U-SMART', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (11, 44, 'factsheet', 'https://navigation.usace.army.mil', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (1, 45, 'factsheet', 'https://cspi.usace.army.mil', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (9, 46, 'factsheet', 'https://www.sac.usace.army.mil/Missions/Regulatory/Jurisdictional-Determinations-and-Delineations', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (3, 47, 'factsheet', 'https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support/NDC-Dredges', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (4, 48, 'factsheet', 'https://mmc.sec.usace.army.mil/fact-sheets/FactSheet_10_FIM_FactSheet.pdf', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (5, 49, 'factsheet', 'https://www.usace.army.mil/missions/environmental/formerly-used-defense-sites/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (2, 50, 'factsheet', 'https://www.hec.usace.army.mil/confluence/cwp/latest/corps-water-management-system-192381111.html', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (10, 51, 'factsheet', 'https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (12, 53, 'factsheet', 'https://nid.sec.usace.army.mil/#/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (17, 55, 'factsheet', 'https://resreg.spl.usace.army.mil/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (12, 57, 'download', 'https://nid.sec.usace.army.mil/api/nation/gpkg', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (23, 61, 'factsheet', 'https://www.iwr.usace.army.mil/Missions/Coasts/Tales-of-the-Coast/Corps-and-the-Coast/Navigation/Structures/', true, NULL, NULL);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (5, 10, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (6, 11, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Current_Ice_Jams/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (7, 12, 'hosted', 'https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (10, 14, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/pports21/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (11, 18, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (13, 21, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (16, 22, 'hosted', 'https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (17, 23, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_rez/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (18, 24, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (18, 25, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_cw_divisions/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (18, 26, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_dist/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (18, 27, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_div/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (20, 28, 'hosted', 'https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (10, 15, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/linktons/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (10, 16, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (10, 17, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Docks/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (15, 34, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_recreation_areas/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (23, 56, 'hosted', 'https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (21, 59, 'hosted', 'https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NLD2_PUBLIC_v1/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (12, 58, 'hosted', 'https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NID_v1/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (3, 62, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (2, 30, 'hosted', 'https://cwms-data.usace.army.mil/cwms-data/basins', false, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (3, 31, 'website', 'https://ndc.ops.usace.army.mil/dis/', false, NULL, false);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (6, 63, 'hosted', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Ice_Jams_Historic/FeatureServer', true, NULL, true);
INSERT INTO catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) OVERRIDING SYSTEM VALUE VALUES (19, 64, 'factsheet', 'https://www.usace.army.mil/About/Centers-of-Expertise/', true, NULL, NULL);


--
-- TOC entry 6611 (class 0 OID 450265)
-- Dependencies: 619
-- Data for Name: data_product_item; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (170, 3, 'Dredging Information System', 'DIS', '', 'dis_output', 'table', 18911, 'NA', NULL, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (167, 3, 'Dredging Information System', 'DIS', '', 'dis_placements', 'feature class', 18912, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (150, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'fuds_munitions_response_site', 'feature class', 1849, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (178, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'fuds_program_district_boundaries', 'feature class', 13, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (145, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'fuds_project_point', 'feature class', 5433, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (142, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'fuds_property_point', 'feature class', 10123, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (154, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'fuds_property_polygon', 'feature class', 5633, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (165, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'irm_project_boundary', 'feature class', 799, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (173, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'irm_property_boundary', 'feature class', 598, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (159, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'irm_property_point', 'feature class', 598, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (40, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'airport_area', 'feature class', 72, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (113, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'airport_area_point', 'feature class', 4, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (97, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'anchor_berth_area', 'feature class', 1, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (104, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'berths_area', 'feature class', 1092, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (50, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'bridge_area', 'feature class', 3761, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (120, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'building_single_point', 'feature class', 892, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (88, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'built_up_area', 'feature class', 995, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (106, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'built_up_area_point', 'feature class', 612, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (129, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'buoy_special_purpose_point', 'feature class', 105, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (22, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'cable_area', 'feature class', 32, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (132, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'canals_area', 'feature class', 3, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (109, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'caution_area', 'feature class', 2912, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (133, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'caution_area_point', 'feature class', 41, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (32, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'conveyor_area', 'feature class', 263, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (41, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'cranes_area', 'feature class', 37, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (47, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'dam_area', 'feature class', 173, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (54, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'data_coverage_area', 'feature class', 317, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (59, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'data_quality_area', 'feature class', 109, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (68, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'dry_dock_area', 'feature class', 2, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (100, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'dumping_ground_area', 'feature class', 1, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (23, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'ferry_route_line', 'feature class', 30, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (119, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'floating_dock_area', 'feature class', 48, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (31, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'floodwall_line', 'feature class', 373, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (124, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'harbour_area', 'feature class', 1, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (139, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'hulkes_area', 'feature class', 44, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (98, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'isolated_danger_buoy_point', 'feature class', 1, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (116, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Environmental Work Windows', 'cspi_initialconstruction', 'table', 293, 'NA', NULL, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (81, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Resources at Risk & Locations', 'cspi_project_extents', 'feature class', 773, 'GEOMETRY', 4326, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (43, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'CSPI Project Summary & Locations', 'cspi_project_rollup', 'feature class', 1098, 'POINT', 4326, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (122, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Current and Historical Reliability', 'cspi_reliability_history', 'table', 4033, 'NA', NULL, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (69, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Renourishment Locations', 'cspi_renourishments', 'feature class', 720, 'POINT', 4326, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (4, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'daymark_point', 'feature class', 4804, 'POINT', 4326, NULL, NULL, 'LOCATION', '/cwms-data/locations');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (6, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'building_single_area', 'feature class', 119201, 'POLYGON', 4326, NULL, NULL, 'LOCATION', '/cwms-data/counties');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (7, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'distance_mark_point', 'feature class', 7452, 'POINT', 4326, NULL, NULL, 'LOCATION', '/cwms-data/offices');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (8, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'conveyor_line', 'feature class', 881, 'LINESTRING', 4326, NULL, NULL, 'LOCATION', '/cwms-data/units');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (11, 5, 'Formerly Used Defense Sites', 'FUDS', '', 'fuds_program_division_boundaries', 'feature class', 7, 'GEOMETRY', 4326, NULL, NULL, '', '/cwms-data/levels');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (12, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'harbour_facility_area', 'feature class', 94, 'POLYGON', 4326, NULL, NULL, '', '/cwms-data/timeseries/category');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (15, 6, 'Ice Jam Database', 'IB', '', 'current_ice_jams', 'feature class', 66, 'POINT', 4326, NULL, NULL, '', '/cwms-data/timeseries');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (17, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'dam_line', 'feature class', 40, 'LINESTRING', 4326, NULL, NULL, 'BASIN', '/cwms-data/basins');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (2, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'cranes_point', 'feature class', 149, 'POINT', 4326, NULL, NULL, 'LOCATION', NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (3, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'coastline_line', 'feature class', 22711, 'LINESTRING', 4326, NULL, NULL, 'LOCATION', '/cwms-data/location/group');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (64, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Aquatic Ecosystem Restoration Details & Location', 'cspi_damagerisk', 'feature class', 1097, 'POINT', 4326, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (112, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'land_area', 'feature class', 18947, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (73, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'land_region_area', 'feature class', 118, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (28, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'landmark_area', 'feature class', 6, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (30, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lateral_beacon_point', 'feature class', 3443, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (37, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lateral_buoy_point', 'feature class', 10, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (35, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'levee_area', 'feature class', 321, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (38, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'levee_line', 'feature class', 721, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (45, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lights_point', 'feature class', 8919, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (33, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lock_gate_area', 'feature class', 94, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (44, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lock_gate_line', 'feature class', 299, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (48, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'mooring_facility_area', 'feature class', 5784, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (53, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'mooring_facility_line', 'feature class', 1, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (51, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'mooring_facility_point', 'feature class', 9744, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (82, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'nautical_publication_information_area', 'feature class', 109, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (89, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'navigational_system_of_marks_area', 'feature class', 109, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (58, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'notice_mark_point', 'feature class', 266, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (62, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'obstruction_area', 'feature class', 366, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (60, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'obstruction_line', 'feature class', 16, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (65, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'obstruction_point', 'feature class', 160, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (66, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'overhead_cable_line', 'feature class', 1629, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (72, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'overhead_pipeline_line', 'feature class', 92, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (70, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'pile_point', 'feature class', 3012, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (74, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'pipe_area', 'feature class', 114, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (125, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'pontoon_area', 'feature class', 515, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (95, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'pylons_area', 'feature class', 6401, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (79, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'pylons_point', 'feature class', 4070, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (80, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'railroad_line', 'feature class', 10576, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (85, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'recommended_track_line', 'feature class', 566, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (90, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'restricted_area', 'feature class', 1233, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (135, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'rivers_area', 'feature class', 3655, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (93, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'rivers_line', 'feature class', 5735, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (99, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'roadway_line', 'feature class', 93021, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (102, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'sea_area', 'feature class', 222, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (87, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'sea_area_point', 'feature class', 1942, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (84, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'sensor_point', 'feature class', 19, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (75, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'shoreline_construction_area', 'feature class', 7821, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (108, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'shoreline_construction_line', 'feature class', 28801, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (94, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'shoreline_construction_point', 'feature class', 4720, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (114, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'slope_topline_line', 'feature class', 233, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (110, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'sloping_ground_area', 'feature class', 23, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (25, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'small_craft_facility_area', 'feature class', 27, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (101, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'small_craft_facility_point', 'feature class', 155, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (117, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'storage_tank_silo_area', 'feature class', 3602, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (107, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'storage_tank_silo_point', 'feature class', 1078, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (121, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'submarine_cable_line', 'feature class', 227, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (130, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'submarine_pipeline_line', 'feature class', 1418, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (115, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'submarine_pipeline_point', 'feature class', 902, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (52, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'terminal_area', 'feature class', 39, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (92, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'terminal_point', 'feature class', 13, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (18, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'land_region_point', 'feature class', 3612, 'POINT', 4326, NULL, NULL, NULL, '/cwms-data/blobs');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (21, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'landmark_point', 'feature class', 552, 'POINT', 4326, NULL, NULL, '', '/cwms-data/specified-levels');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (20, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lock_basin_area', 'feature class', 173, 'POLYGON', 4326, NULL, NULL, 'POOL', '/cwms-data/pools');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (123, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'traffic_signal_station_point', 'feature class', 298, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (136, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'underwater_rock_area', 'feature class', 124, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (127, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'underwater_rock_point', 'feature class', 114, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (138, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'waterway_gauge_point', 'feature class', 753, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (55, 11, 'National Channel Framework', 'NCF', '', 'channelarea', 'feature class', 2662, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (46, 11, 'National Channel Framework', 'NCF', '', 'channelline', 'feature class', 36153, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (67, 11, 'National Channel Framework', 'NCF', '', 'channelquarter', 'feature class', 24408, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (61, 11, 'National Channel Framework', 'NCF', '', 'channelreach', 'feature class', 12836, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (128, 12, 'National Inventory of Dams', 'NID', '', 'national_inventory_dams', 'feature class', 91886, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (172, 21, 'National Levee Database', 'NLD', '', 'alignment_lines', 'feature class', 31251, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (153, 21, 'National Levee Database', 'NLD', '', 'boreholes', 'feature class', 47973, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (176, 21, 'National Levee Database', 'NLD', '', 'channels', 'feature class', 1, 'LINESTRING', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (181, 21, 'National Levee Database', 'NLD', '', 'closure_structures', 'feature class', 3556, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (149, 21, 'National Levee Database', 'NLD', '', 'cross_sections', 'feature class', 241865, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (143, 21, 'National Levee Database', 'NLD', '', 'crossings', 'feature class', 111239, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (158, 21, 'National Levee Database', 'NLD', '', 'embankments', 'feature class', 25754, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (163, 21, 'National Levee Database', 'NLD', '', 'floodwalls', 'feature class', 14661, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (166, 21, 'National Levee Database', 'NLD', '', 'frm_lines', 'feature class', 52, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (157, 21, 'National Levee Database', 'NLD', '', 'levee_stations', 'feature class', 440795, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (144, 21, 'National Levee Database', 'NLD', '', 'leveed_areas', 'feature class', 6610, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (160, 21, 'National Levee Database', 'NLD', '', 'piezometers', 'feature class', 2417, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (162, 21, 'National Levee Database', 'NLD', '', 'pipe_gates', 'feature class', 9496, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (169, 21, 'National Levee Database', 'NLD', '', 'pipes', 'feature class', 17369, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (168, 21, 'National Levee Database', 'NLD', '', 'pump_stations', 'feature class', 2090, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (171, 21, 'National Levee Database', 'NLD', '', 'relief_wells', 'feature class', 10698, 'POINT', 0, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (177, 21, 'National Levee Database', 'NLD', '', 'system_routes', 'feature class', 6815, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (180, 21, 'National Levee Database', 'NLD', '', 'toe_drains', 'feature class', 1183, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (164, 13, 'National Sediment Managment Framework ', 'NSMF', '', 'borrowarea', 'feature class', 126, 'POLYGON', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (174, 13, 'National Sediment Managment Framework ', 'NSMF', '', 'placementarea', 'feature class', 2704, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (161, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'dock', 'feature class', 23719, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (111, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'link tonnages (historic)', 'feature class', 2901, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (175, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'link_tonnages_(historic)', 'feature class', 2901, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (71, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'linktons', 'feature class', 2900, 'LINESTRING', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (146, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'lock', 'feature class', 234, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (83, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'pports21', 'feature class', 150, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (34, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'principal port', 'feature class', 150, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (137, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'principal_port', 'feature class', 150, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (27, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'waterway mile marker', 'feature class', 11406, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (103, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'waterway network', 'feature class', 6859, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (86, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'waterway network node', 'feature class', 6255, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (126, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'waterway_mile_marker', 'feature class', 11406, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (155, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'waterway_network', 'feature class', 6859, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (151, 10, 'Navigation and Civil Works Decision Support', 'NDC', '', 'waterway_network_node', 'feature class', 6255, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (141, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'disposal area', 'feature class', 18155, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (91, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'disposal line', 'feature class', 8, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (63, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'disposal_area', 'feature class', 18155, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (179, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'disposal_line', 'feature class', 8, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (77, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'land parcel area', 'feature class', 254300, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (105, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'land parcel line', 'feature class', 53, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (76, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'land_parcel_area', 'feature class', 254300, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (26, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'land_parcel_line', 'feature class', 53, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (118, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'outgrant area', 'feature class', 503, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (42, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'outgrant_area', 'feature class', 503, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (140, 16, 'Real Estate Management Geospatial', 'REMIS', '', 'site', 'feature class', 1603, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (156, 15, 'Recreation', 'RECREATION', '', 'recreation_area', 'feature class', 3659, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (16, 18, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES', '', 'usace_districts', 'feature class', 38, 'GEOMETRY', 4326, NULL, NULL, '', '/cwms-data/ratings');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (10, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'wrecks_area', 'feature class', 10, 'POLYGON', 4326, NULL, NULL, '', '/cwms-data/timezones');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (36, 18, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES', '', 'usace_divisions', 'feature class', 8, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (29, 18, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES', '', 'usace_military_districts', 'feature class', 24, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (56, 17, 'USACE Reservoirs', 'RESERVOIR', '', 'usace reservoirs', 'feature class', 418, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (147, 17, 'USACE Reservoirs', 'RESERVOIR', '', 'usace_reservoirs', 'feature class', 418, 'GEOMETRY', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (152, 20, 'USACE Survey Monument Archives', 'USMART', '', 'local_control_points', 'feature class', 191501, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (24, 23, 'National Coastal Structures Database', 'NCDB', '', 'usace_structure_polygon', 'feature class', 1078, 'POLYGON', 4326, 56, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (148, 20, 'USACE Survey Monument Archives', 'USMART', '', 'primary_control_points', 'feature class', 7030, 'POINT', 4326, NULL, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (134, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Coastal Storm Risk Management Details & Locations', 'cspi_csrm_aer_datacheck', 'table', 500, 'NA', NULL, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (57, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Coastal Storm Risk Management Details & Locations', 'cspi_csrm_aer_overview', 'feature class', 464, 'POINT', 4326, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (49, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Navigation Details & Locations', 'cspi_nav_overview', 'feature class', 632, 'POINT', 4326, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (131, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Project Milestones/Report Dates', 'cspi_reports', 'table', 656, 'NA', NULL, 7, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (39, 23, 'National Coastal Structures Database', 'NCDB', '', 'structure_vessel_data', 'table', 66812, 'NA', NULL, 56, NULL, NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (1, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'warning_signal_station_point', 'feature class', 508, 'POINT', 4326, NULL, 'Did not load, error when loaded in Map Viewer', NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (1, 23, 'National Coastal Structures Database', 'NCDB', '', 'usace_structure_point', 'feature Class', NULL, 'POINT', NULL, 56, 'Did not load, error when loaded in Map Viewer', NULL, NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (96, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'Dredging Operations (collected by CSPI, which is not the authoritative source)', 'cspi_dredgingwindows', 'table', 745, 'NA', NULL, 7, NULL, 'DREDGING', NULL);
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (12, 2, 'Corps Water Management System', 'CWMS', 'TimeSeries Categories', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/timeseries/category');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (13, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'harbour_facility_point', 'feature class', 556, 'POINT', 4326, NULL, NULL, '', '/cwms-data/timeseries/identifier-descriptor');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (13, 2, 'Corps Water Management System', 'CWMS', 'TimeSeries Identifier', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/timeseries/identifier-descriptor');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (14, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'canals_line', 'feature class', 1, 'LINESTRING', 4326, NULL, NULL, '', '/cwms-data/timeseries/group');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (14, 2, 'Corps Water Management System', 'CWMS', 'Timeseries Groups', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/timeseries/group');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (15, 2, 'Corps Water Management System', 'CWMS', 'TimeSeries', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/timeseries');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (16, 2, 'Corps Water Management System', 'CWMS', 'Ratings', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/ratings');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (17, 2, 'Corps Water Management System', 'CWMS', 'Basins', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'BASIN', '/cwms-data/basins');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (21, 2, 'Corps Water Management System', 'CWMS', 'Levels', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/specified-levels');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (20, 2, 'Corps Water Management System', 'CWMS', 'Pools', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'POOL', '/cwms-data/pools');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (18, 2, 'Corps Water Management System', 'CWMS', 'Blob', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION CATEGORIES', '/cwms-data/blobs');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (2, 2, 'Corps Water Management System', 'CWMS', 'Location Categories', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/location/category');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (3, 2, 'Corps Water Management System', 'CWMS', 'Location Groups', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/location/group');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (4, 2, 'Corps Water Management System', 'CWMS', 'Locations', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/locations');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (5, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'lake_area', 'feature class', 4923, 'POLYGON', 4326, NULL, NULL, 'LOCATION', '/cwms-data/states');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (5, 2, 'Corps Water Management System', 'CWMS', 'States', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/states');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (6, 2, 'Corps Water Management System', 'CWMS', 'Counties', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/counties');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (7, 2, 'Corps Water Management System', 'CWMS', 'Offices', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/offices');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (8, 2, 'Corps Water Management System', 'CWMS', 'Units', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'LOCATION', '/cwms-data/units');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (9, 7, 'Inland Electronic Navigational Charts', 'IENC', '', 'wrecks_point', 'feature class', 548, 'POINT', 4326, NULL, NULL, '', '/cwms-data/parameters');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (9, 2, 'Corps Water Management System', 'CWMS', 'Parameters', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/parameters');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (10, 2, 'Corps Water Management System', 'CWMS', 'TimeZones', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/timezones');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (11, 2, 'Corps Water Management System', 'CWMS', 'Levels', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/levels');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (19, 18, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES', '', 'usace_military_divisions', 'feature class', 8, 'GEOMETRY', 4326, NULL, NULL, '', '/cwms-data/clobs');
INSERT INTO catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) VALUES (19, 2, 'Corps Water Management System', 'CWMS', 'Clob', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '/cwms-data/clobs');


--
-- TOC entry 6618 (class 0 OID 0)
-- Dependencies: 241
-- Name: artifact_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.artifact_id_seq', 132, true);


--
-- TOC entry 6619 (class 0 OID 0)
-- Dependencies: 243
-- Name: data_collection_collection_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_collection_collection_id_seq', 32, true);


--
-- TOC entry 6620 (class 0 OID 0)
-- Dependencies: 571
-- Name: data_collection_filter_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_collection_filter_id_seq', 1, false);


--
-- TOC entry 6621 (class 0 OID 0)
-- Dependencies: 620
-- Name: data_product_item_id_sequence; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_product_item_id_sequence', 21, true);


--
-- TOC entry 6622 (class 0 OID 0)
-- Dependencies: 245
-- Name: data_products_product_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_products_product_id_seq', 64, true);


--
-- TOC entry 6449 (class 2606 OID 157309)
-- Name: data_collection data_collection_pkey; Type: CONSTRAINT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.data_collection
    ADD CONSTRAINT data_collection_pkey PRIMARY KEY (collection_id);


--
-- TOC entry 6450 (class 2606 OID 157462)
-- Name: data_product data_products_collection_id_fkey; Type: FK CONSTRAINT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.data_product
    ADD CONSTRAINT data_products_collection_id_fkey FOREIGN KEY (collection_id) REFERENCES catalog.data_collection(collection_id) NOT VALID;


-- Completed on 2024-07-17 21:08:18

--
-- PostgreSQL database dump complete
--

