--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 16.3

-- Started on 2024-08-12 21:32:06

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
-- TOC entry 144 (class 2615 OID 685361)
-- Name: bronze_meta; Type: SCHEMA; Schema: -; Owner: bronze_meta
--

CREATE SCHEMA bronze_meta;


ALTER SCHEMA bronze_meta OWNER TO bronze_meta;

--
-- TOC entry 931 (class 1259 OID 693097)
-- Name: artifact_id_seq; Type: SEQUENCE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE SEQUENCE bronze_meta.artifact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bronze_meta.artifact_id_seq OWNER TO bronze_meta;

--
-- TOC entry 841 (class 1259 OID 685548)
-- Name: artifact_type_id_seq; Type: SEQUENCE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE SEQUENCE bronze_meta.artifact_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bronze_meta.artifact_type_id_seq OWNER TO bronze_meta;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 932 (class 1259 OID 693109)
-- Name: artifact_type_lookup; Type: TABLE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE TABLE bronze_meta.artifact_type_lookup (
    artifact_type_id bigint DEFAULT nextval('bronze_meta.artifact_type_id_seq'::regclass) NOT NULL,
    artifact_type text
);


ALTER TABLE bronze_meta.artifact_type_lookup OWNER TO bronze_meta;

--
-- TOC entry 933 (class 1259 OID 693125)
-- Name: artifact_url_xref_id_seq; Type: SEQUENCE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE SEQUENCE bronze_meta.artifact_url_xref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bronze_meta.artifact_url_xref_id_seq OWNER TO bronze_meta;

--
-- TOC entry 934 (class 1259 OID 693135)
-- Name: artifact_url_xref; Type: TABLE; Schema: bronze_meta; Owner: egdbadmin
--

CREATE TABLE bronze_meta.artifact_url_xref (
    artifact_url_xref_id bigint DEFAULT nextval('bronze_meta.artifact_url_xref_id_seq'::regclass) NOT NULL,
    artifact_id bigint NOT NULL,
    url_id bigint NOT NULL
);


ALTER TABLE bronze_meta.artifact_url_xref OWNER TO egdbadmin;

--
-- TOC entry 935 (class 1259 OID 693146)
-- Name: data_artifact; Type: TABLE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE TABLE bronze_meta.data_artifact (
    artifact_id bigint DEFAULT nextval('bronze_meta.artifact_id_seq'::regclass) NOT NULL,
    artifact_type_id bigint NOT NULL,
    artifact_name text NOT NULL,
    artifact_short_name text NOT NULL,
    artifact_schema text NOT NULL,
    dcat_meta_id bigint,
    parent_artifact_id bigint
);


ALTER TABLE bronze_meta.data_artifact OWNER TO bronze_meta;

--
-- TOC entry 840 (class 1259 OID 685534)
-- Name: url_id_seq; Type: SEQUENCE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE SEQUENCE bronze_meta.url_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bronze_meta.url_id_seq OWNER TO bronze_meta;

--
-- TOC entry 839 (class 1259 OID 685526)
-- Name: url; Type: TABLE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE TABLE bronze_meta.url (
    url_id integer DEFAULT nextval('bronze_meta.url_id_seq'::regclass) NOT NULL,
    url_type text,
    url_address text,
    url_level text,
    url_descriptor text
);


ALTER TABLE bronze_meta.url OWNER TO bronze_meta;

--
-- TOC entry 936 (class 1259 OID 693197)
-- Name: collection_urls_view; Type: VIEW; Schema: bronze_meta; Owner: egdbadmin
--

CREATE VIEW bronze_meta.collection_urls_view AS
 SELECT a.artifact_id AS collection_id,
    a.artifact_name AS collection_name,
    a.artifact_schema AS collection_schema,
    a.artifact_short_name AS collection_code,
    u.url_id,
    u.url_type,
    u.url_address,
    u.url_level,
    u.url_descriptor
   FROM (((bronze_meta.data_artifact a
     JOIN bronze_meta.artifact_url_xref x ON ((a.artifact_id = x.artifact_id)))
     JOIN bronze_meta.artifact_type_lookup l ON ((l.artifact_type_id = a.artifact_type_id)))
     JOIN bronze_meta.url u ON ((u.url_id = x.url_id)))
  WHERE (l.artifact_type = 'COLLECTION'::text)
  ORDER BY a.artifact_id;


ALTER VIEW bronze_meta.collection_urls_view OWNER TO egdbadmin;

--
-- TOC entry 937 (class 1259 OID 693202)
-- Name: catalog_product_config_view; Type: VIEW; Schema: bronze_meta; Owner: egdbadmin
--

CREATE VIEW bronze_meta.catalog_product_config_view AS
 WITH a AS (
         SELECT c.collection_id,
            c.collection_name,
            c.collection_code,
            c.collection_schema,
            ( SELECT min(p.url_address) AS min
                   FROM bronze_meta.collection_urls_view p
                  WHERE ((p.collection_id = c.collection_id) AND (p.url_type = 'FEATURE_SERVER'::text))) AS sample_url,
            ( SELECT string_agg(p.url_address, ';'::text) AS string_agg
                   FROM bronze_meta.collection_urls_view p
                  WHERE ((p.collection_id = c.collection_id) AND (p.url_type = 'FEATURE_SERVER'::text) AND (p.url_level = 'PUBLIC'::text))) AS urls,
            ( SELECT min(p.url_address) AS min
                   FROM bronze_meta.collection_urls_view p
                  WHERE ((p.collection_id = c.collection_id) AND (COALESCE(p.url_descriptor, ''::text) = 'FACTSHEET'::text))) AS factsheet
           FROM bronze_meta.collection_urls_view c
          GROUP BY c.collection_id, c.collection_name, c.collection_code, c.collection_schema
        )
 SELECT a.collection_id,
    a.collection_name,
    a.collection_code AS acronym,
    COALESCE(a.sample_url, (''::character varying)::text) AS sample_url,
    COALESCE(a.urls, ''::text) AS urls,
    COALESCE(a.factsheet, (''::character varying)::text) AS factsheet
   FROM a
  ORDER BY a.collection_name;


ALTER VIEW bronze_meta.catalog_product_config_view OWNER TO egdbadmin;

--
-- TOC entry 938 (class 1259 OID 693211)
-- Name: collection_hosted_urls; Type: VIEW; Schema: bronze_meta; Owner: egdbadmin
--

CREATE VIEW bronze_meta.collection_hosted_urls AS
 SELECT v.collection_id,
    v.collection_name,
    v.collection_schema,
    v.collection_code,
    v.url_id,
    v.url_type,
    v.url_address,
    v.url_level,
    v.url_descriptor
   FROM bronze_meta.collection_urls_view v
  WHERE ((v.url_level = 'PUBLIC'::text) AND (v.url_type = 'FEATURE_SERVER'::text))
  ORDER BY v.collection_schema;


ALTER VIEW bronze_meta.collection_hosted_urls OWNER TO egdbadmin;

--
-- TOC entry 842 (class 1259 OID 685561)
-- Name: url_related_id_seq; Type: SEQUENCE; Schema: bronze_meta; Owner: bronze_meta
--

CREATE SEQUENCE bronze_meta.url_related_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bronze_meta.url_related_id_seq OWNER TO bronze_meta;

--
-- TOC entry 7785 (class 0 OID 693109)
-- Dependencies: 932
-- Data for Name: artifact_type_lookup; Type: TABLE DATA; Schema: bronze_meta; Owner: bronze_meta
--

INSERT INTO bronze_meta.artifact_type_lookup (artifact_type_id, artifact_type) VALUES (1, 'COLLECTION');
INSERT INTO bronze_meta.artifact_type_lookup (artifact_type_id, artifact_type) VALUES (2, 'FEATURE');
INSERT INTO bronze_meta.artifact_type_lookup (artifact_type_id, artifact_type) VALUES (3, 'TABLE');
INSERT INTO bronze_meta.artifact_type_lookup (artifact_type_id, artifact_type) VALUES (4, 'RECORD');


--
-- TOC entry 7787 (class 0 OID 693135)
-- Dependencies: 934
-- Data for Name: artifact_url_xref; Type: TABLE DATA; Schema: bronze_meta; Owner: egdbadmin
--

INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (1, 5, 26);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (2, 5, 1);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (3, 4, 2);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (4, 8, 3);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (5, 1, 4);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (6, 2, 5);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (7, 14, 6);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (8, 3, 54);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (9, 3, 7);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (10, 3, 8);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (11, 1, 9);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (12, 12, 10);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (13, 7, 11);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (14, 21, 12);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (15, 8, 13);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (16, 6, 14);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (17, 13, 15);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (18, 14, 16);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (19, 15, 17);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (20, 16, 18);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (21, 18, 19);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (22, 20, 20);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (23, 11, 21);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (24, 1, 22);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (25, 9, 23);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (26, 3, 24);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (27, 4, 25);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (28, 5, 26);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (29, 5, 1);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (30, 2, 27);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (31, 10, 28);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (32, 12, 29);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (33, 17, 30);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (34, 12, 31);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (35, 23, 32);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (36, 5, 33);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (37, 6, 34);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (38, 7, 35);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (39, 10, 36);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (40, 11, 37);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (41, 13, 38);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (42, 16, 39);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (43, 17, 40);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (44, 18, 41);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (45, 18, 42);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (46, 18, 43);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (47, 18, 44);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (48, 20, 45);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (49, 10, 46);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (50, 10, 47);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (51, 10, 48);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (52, 15, 49);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (53, 23, 50);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (54, 12, 51);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (55, 3, 52);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (56, 2, 53);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (57, 3, 54);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (58, 3, 7);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (59, 6, 55);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (60, 19, 56);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (61, 21, 58);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (62, 21, 57);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (63, 21, 58);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (64, 21, 57);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (65, 5, 59);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (66, 21, 60);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (67, 12, 61);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (68, 7, 62);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (69, 1, 63);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (70, 23, 64);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (71, 16, 65);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (72, 3, 66);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (73, 33, 67);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (74, 34, 68);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (75, 35, 69);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (76, 4, 70);
INSERT INTO bronze_meta.artifact_url_xref (artifact_url_xref_id, artifact_id, url_id) VALUES (77, 33, 71);


--
-- TOC entry 7788 (class 0 OID 693146)
-- Dependencies: 935
-- Data for Name: data_artifact; Type: TABLE DATA; Schema: bronze_meta; Owner: bronze_meta
--

INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (1, 1, 'Coastal Systems Portfolio Initiative', 'CSPI', 'CSPI', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (2, 1, 'Corps Water Management System', 'CWMS', 'CWMS', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (3, 1, 'Dredging Information System', 'DIS', 'DIS', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (4, 1, 'Flood Inundation Mapping', 'FIM', 'FIM', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (5, 1, 'Formerly Used Defense Sites', 'FUDS', 'FUDS', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (6, 1, 'Ice Jam Database', 'IB', 'IB', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (7, 1, 'Inland Electronic Navigational Charts', 'IENC', 'IENC', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (8, 1, 'Joint Airborn Lidar Bathymetry', 'JABLTCX', 'JABLTCX', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (9, 1, 'USACE Juristictional Determinations', 'JURISDICTION', 'JURISDICTION', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (10, 1, 'Navigation and Civil Works Decision Support', 'NDC', 'NDC', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (11, 1, 'National Channel Framework', 'NCF', 'NCF', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (12, 1, 'National Inventory of Dams', 'NID', 'NID', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (13, 1, 'National Sediment Managment Framework ', 'NSMF', 'NSMF', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (14, 1, 'Operations & Maintenence ', 'OMBIL', 'OMBIL', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (15, 1, 'Recreation', 'RECREATION', 'RECREATION', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (16, 1, 'Real Estate Management Geospatial', 'REMIS', 'REMIS', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (17, 1, 'USACE Reservoirs', 'RESERVOIR', 'RESERVOIR', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (18, 1, 'USACE Civil Works and Military Boundaries', 'BOUNDARIES', 'BOUNDARIES', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (19, 1, 'USACE Master Site List', 'MSL', 'MSL', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (20, 1, 'USACE Survey Monument Archives', 'USMART', 'USMART', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (21, 1, 'National Levee Database', 'NLD', 'NLD', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (33, 1, 'Inland Waterways ', 'INW', 'INW', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (34, 1, 'Military Installations Training Areas', 'MIRTA', 'MIRTA', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (35, 1, 'Port Statistical Areas', 'PORT', 'PORT', NULL, NULL);
INSERT INTO bronze_meta.data_artifact (artifact_id, artifact_type_id, artifact_name, artifact_short_name, artifact_schema, dcat_meta_id, parent_artifact_id) VALUES (23, 1, 'National Coastal Structures Database', 'NCS', 'NCS', NULL, NULL);


--
-- TOC entry 7780 (class 0 OID 685526)
-- Dependencies: 839
-- Data for Name: url; Type: TABLE DATA; Schema: bronze_meta; Owner: bronze_meta
--

INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (1, 'WEBSITE', 'https://www.usace.army.mil/missions/environmental/formerly-used-defense-sites/', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (2, 'WEBSITE', 'https://fim.wim.usgs.gov/fim/', 'PUBLIC', 'WEBMAP');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (3, 'WEBSITE', 'https://jalbtcx.usace.army.mil/', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (4, 'WEBSITE', 'https://www.arcgis.com/apps/MapSeries/index.html?appid=8f0ed6044c2e46948e25672ce0587437', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (5, 'WEBSITE', 'https://www.hec.usace.army.mil/cwms', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (6, 'FEATURE_SERVER', 'https://cwbi.ops.usace.army.mil/   ', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (7, 'WEBSITE', 'https://ndc.ops.usace.army.mil/dis/', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (8, 'WEBSITE', 'https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support/NDC-Dredges/', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (9, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (10, 'FEATURE_SERVER', 'tbd', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (11, 'WEBSITE', 'https://ienccloud.us/', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (12, 'WEBSITE', 'https://levees.sec.usace.army.mil', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (13, 'WEBSITE', 'https://www.sam.usace.army.mil/Missions/National-Centers-in-Mobile/Joint-Airborne-Lidar-Bathymetry', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (14, 'WEBSITE', 'https://icejam.sec.usace.army.mil/ords/f?p=1001:7', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (15, 'WEBSITE', 'https://www.erdc.usace.army.mil/Locations/CHL/Sediment-Management', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (16, 'WEBSITE', 'https://www.iwr.usace.army.mil/Missions/Civil-Works-Planning-and-Policy-Support/OMBIL', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (17, 'WEBSITE', 'https://www.usace.army.mil/missions/civil-works/recreation', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (18, 'WEBSITE', 'https://www.sam.usace.army.mil/Missions/Real-Estate', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (19, 'WEBSITE', 'https://www.usace.army.mil/Contact/Unit-Websites', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (20, 'WEBSITE', 'https://www.agc.army.mil/What-we-do/U-SMART', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (21, 'WEBSITE', 'https://navigation.usace.army.mil', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (22, 'WEBSITE', 'https://cspi.usace.army.mil', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (23, 'WEBSITE', 'https://www.sac.usace.army.mil/Missions/Regulatory/Jurisdictional-Determinations-and-Delineations', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (24, 'WEBSITE', 'https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support/NDC-Dredges', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (25, 'WEBSITE', 'https://mmc.sec.usace.army.mil/fact-sheets/FactSheet_10_FIM_FactSheet.pdf', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (26, 'WEBSITE', 'https://www.usace.army.mil/missions/environmental/formerly-used-defense-sites/', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (27, 'WEBSITE', 'https://www.hec.usace.army.mil/confluence/cwp/latest/corps-water-management-system-192381111.html', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (28, 'WEBSITE', 'https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (29, 'WEBSITE', 'https://nid.sec.usace.army.mil/#/', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (30, 'WEBSITE', 'https://resreg.spl.usace.army.mil/', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (31, 'WEBSITE', 'https://nid.sec.usace.army.mil/api/nation/gpkg', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (32, 'WEBSITE', 'https://www.iwr.usace.army.mil/Missions/Coasts/Tales-of-the-Coast/Corps-and-the-Coast/Navigation/Structures/', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (33, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (34, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Current_Ice_Jams/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (35, 'FEATURE_SERVER', 'https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (36, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/pports21/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (37, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (38, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (39, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (40, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_rez/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (41, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (42, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_cw_divisions/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (43, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_dist/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (44, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_div/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (45, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (46, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/linktons/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (47, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (48, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Docks/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (49, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_recreation_areas/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (50, 'FEATURE_SERVER', 'https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (51, 'FEATURE_SERVER', 'https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NID_v1/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (52, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (53, 'FEATURE_SERVER', 'https://cwms-data.usace.army.mil/cwms-data/basins', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (54, 'WEBSITE', 'https://ndc.ops.usace.army.mil/dis/', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (55, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Ice_Jams_Historic/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (56, 'WEBSITE', 'https://www.usace.army.mil/About/Centers-of-Expertise/', 'PUBLIC', 'FACTSHEET');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (57, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (58, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (59, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/Formerly_Used_Defense_Sites/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (60, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/National_Levee_Database/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (61, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/National_Inventory_of_Dams/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (62, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/Inland_Electronic_Navigational_Data/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (63, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/Coastal_Systems_Portfolio_Initiative/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (64, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/National_Coastal_Structures_Database/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (65, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/Real_Estate_Management_Geospatial/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (66, 'WEBSITE', 'https://dev-portal.egis-usace.us/server/rest/services/Dredging_Information_System/FeatureServer', 'RESTRICTED', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (67, 'FEATURE_SERVER', 'https://geospatial.sec.usace.army.mil/server/rest/services/Hosted/AIS_NWN/FeatureServer/0', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (68, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/mirta/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (69, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Port_Statistical_Area/FeatureServer', 'PUBLIC', NULL);
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (70, 'WEBSITE', 'https://ags03.sec.usace.army.mil/portal/apps/webappviewer/index.html?id=ca7ff838865349108910a398123ce968', 'PUBLIC', 'WEBMAP');
INSERT INTO bronze_meta.url (url_id, url_type, url_address, url_level, url_descriptor) VALUES (71, 'FEATURE_SERVER', 'https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Standardized_Inland_Waterway_Polygons/FeatureServer', 'PUBLIC', NULL);


--
-- TOC entry 7795 (class 0 OID 0)
-- Dependencies: 931
-- Name: artifact_id_seq; Type: SEQUENCE SET; Schema: bronze_meta; Owner: bronze_meta
--

SELECT pg_catalog.setval('bronze_meta.artifact_id_seq', 61, true);


--
-- TOC entry 7796 (class 0 OID 0)
-- Dependencies: 841
-- Name: artifact_type_id_seq; Type: SEQUENCE SET; Schema: bronze_meta; Owner: bronze_meta
--

SELECT pg_catalog.setval('bronze_meta.artifact_type_id_seq', 4, true);


--
-- TOC entry 7797 (class 0 OID 0)
-- Dependencies: 933
-- Name: artifact_url_xref_id_seq; Type: SEQUENCE SET; Schema: bronze_meta; Owner: bronze_meta
--

SELECT pg_catalog.setval('bronze_meta.artifact_url_xref_id_seq', 1, false);


--
-- TOC entry 7798 (class 0 OID 0)
-- Dependencies: 840
-- Name: url_id_seq; Type: SEQUENCE SET; Schema: bronze_meta; Owner: bronze_meta
--

SELECT pg_catalog.setval('bronze_meta.url_id_seq', 71, true);


--
-- TOC entry 7799 (class 0 OID 0)
-- Dependencies: 842
-- Name: url_related_id_seq; Type: SEQUENCE SET; Schema: bronze_meta; Owner: bronze_meta
--

SELECT pg_catalog.setval('bronze_meta.url_related_id_seq', 77, true);


--
-- TOC entry 7608 (class 2606 OID 693116)
-- Name: artifact_type_lookup artifact_type_pkey; Type: CONSTRAINT; Schema: bronze_meta; Owner: bronze_meta
--

ALTER TABLE ONLY bronze_meta.artifact_type_lookup
    ADD CONSTRAINT artifact_type_pkey PRIMARY KEY (artifact_type_id);


--
-- TOC entry 7610 (class 2606 OID 693152)
-- Name: data_artifact data_artifact_pkey; Type: CONSTRAINT; Schema: bronze_meta; Owner: bronze_meta
--

ALTER TABLE ONLY bronze_meta.data_artifact
    ADD CONSTRAINT data_artifact_pkey PRIMARY KEY (artifact_id);


--
-- TOC entry 7606 (class 2606 OID 685533)
-- Name: url urls_pkey; Type: CONSTRAINT; Schema: bronze_meta; Owner: bronze_meta
--

ALTER TABLE ONLY bronze_meta.url
    ADD CONSTRAINT urls_pkey PRIMARY KEY (url_id);


--
-- TOC entry 7613 (class 2606 OID 693232)
-- Name: data_artifact fk_artifact_type_id; Type: FK CONSTRAINT; Schema: bronze_meta; Owner: bronze_meta
--

ALTER TABLE ONLY bronze_meta.data_artifact
    ADD CONSTRAINT fk_artifact_type_id FOREIGN KEY (artifact_type_id) REFERENCES bronze_meta.artifact_type_lookup(artifact_type_id);


--
-- TOC entry 7611 (class 2606 OID 693222)
-- Name: artifact_url_xref fk_data_artifact; Type: FK CONSTRAINT; Schema: bronze_meta; Owner: egdbadmin
--

ALTER TABLE ONLY bronze_meta.artifact_url_xref
    ADD CONSTRAINT fk_data_artifact FOREIGN KEY (artifact_id) REFERENCES bronze_meta.data_artifact(artifact_id);


--
-- TOC entry 7612 (class 2606 OID 693227)
-- Name: artifact_url_xref fk_url_id; Type: FK CONSTRAINT; Schema: bronze_meta; Owner: egdbadmin
--

ALTER TABLE ONLY bronze_meta.artifact_url_xref
    ADD CONSTRAINT fk_url_id FOREIGN KEY (url_id) REFERENCES bronze_meta.url(url_id);


--
-- TOC entry 7794 (class 0 OID 0)
-- Dependencies: 144
-- Name: SCHEMA bronze_meta; Type: ACL; Schema: -; Owner: bronze_meta
--

GRANT USAGE ON SCHEMA bronze_meta TO PUBLIC;
GRANT USAGE ON SCHEMA bronze_meta TO bronze_staging;


-- Completed on 2024-08-12 21:32:06

--
-- PostgreSQL database dump complete
--

