--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 16.3

-- Started on 2024-08-07 21:22:45

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
-- TOC entry 54 (class 2615 OID 106050)
-- Name: catalog; Type: SCHEMA; Schema: -; Owner: catalog
--

CREATE SCHEMA catalog;


ALTER SCHEMA catalog OWNER TO catalog;

--
-- TOC entry 2058 (class 1255 OID 200281)
-- Name: clean_up_user_privileges(text, text); Type: PROCEDURE; Schema: catalog; Owner: egdbadmin
--

CREATE PROCEDURE catalog.clean_up_user_privileges(IN user_name text, IN db_name text)
    LANGUAGE plpgsql
    AS $$
BEGIN
 	EXECUTE format('REVOKE ALL ON TABLE public.spatial_ref_sys FROM %I', user_name);
	EXECUTE format('REVOKE ALL ON TABLE public.geography_columns FROM %I', user_name);
	EXECUTE format('REVOKE ALL ON TABLE public.geometry_columns FROM %I', user_name);
	EXECUTE format('REVOKE ALL ON SCHEMA public FROM %I', user_name);
	EXECUTE format('REVOKE ALL ON DATABASE %I FROM %I', db_name, user_name);	
	EXECUTE format('ALTER SCHEMA %I OWNER TO catalog', user_name);
END;
$$;


ALTER PROCEDURE catalog.clean_up_user_privileges(IN user_name text, IN db_name text) OWNER TO egdbadmin;

--
-- TOC entry 479 (class 1259 OID 106051)
-- Name: artifact_id_seq; Type: SEQUENCE; Schema: catalog; Owner: catalog
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
-- TOC entry 873 (class 1259 OID 681961)
-- Name: data_collection; Type: TABLE; Schema: catalog; Owner: catalog
--

CREATE TABLE catalog.data_collection (
    collection_id bigint NOT NULL,
    collection_name character varying(256),
    acronym character varying(20)
);


ALTER TABLE catalog.data_collection OWNER TO catalog;

--
-- TOC entry 480 (class 1259 OID 106055)
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
-- TOC entry 874 (class 1259 OID 681966)
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
-- TOC entry 872 (class 1259 OID 681960)
-- Name: data_collection_collection_id_seq; Type: SEQUENCE; Schema: catalog; Owner: catalog
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
-- TOC entry 481 (class 1259 OID 106075)
-- Name: data_collection_filter_id_seq; Type: SEQUENCE; Schema: catalog; Owner: catalog
--

CREATE SEQUENCE catalog.data_collection_filter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalog.data_collection_filter_id_seq OWNER TO catalog;

--
-- TOC entry 482 (class 1259 OID 106076)
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
-- TOC entry 483 (class 1259 OID 106077)
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
-- TOC entry 484 (class 1259 OID 106088)
-- Name: data_products_product_id_seq; Type: SEQUENCE; Schema: catalog; Owner: catalog
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
-- TOC entry 877 (class 1259 OID 682045)
-- Name: load_collection; Type: TABLE; Schema: catalog; Owner: catalog
--

CREATE TABLE catalog.load_collection (
    ogc_fid integer NOT NULL,
    collection_code character varying,
    collection_id character varying,
    collection_name character varying,
    load_datetimestamp character varying,
    wkid character varying,
    layer_count character varying,
    table_count character varying,
    load_status character varying,
    source_file_path character varying,
    url character varying,
    serviceitemid character varying,
    servicedescription character varying,
    description character varying
);


ALTER TABLE catalog.load_collection OWNER TO catalog;

--
-- TOC entry 876 (class 1259 OID 682044)
-- Name: load_collection_ogc_fid_seq; Type: SEQUENCE; Schema: catalog; Owner: catalog
--

CREATE SEQUENCE catalog.load_collection_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalog.load_collection_ogc_fid_seq OWNER TO catalog;

--
-- TOC entry 7541 (class 0 OID 0)
-- Dependencies: 876
-- Name: load_collection_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: catalog; Owner: catalog
--

ALTER SEQUENCE catalog.load_collection_ogc_fid_seq OWNED BY catalog.load_collection.ogc_fid;


--
-- TOC entry 557 (class 1259 OID 426897)
-- Name: load_profile; Type: TABLE; Schema: catalog; Owner: catalog
--

CREATE TABLE catalog.load_profile (
    ogc_fid integer NOT NULL,
    field_1 character varying,
    acronym character varying,
    collection_name character varying,
    entity_name character varying,
    entity_name_revised character varying,
    record_count character varying,
    entity_type character varying,
    filters character varying,
    srid character varying,
    url character varying
);


ALTER TABLE catalog.load_profile OWNER TO catalog;

--
-- TOC entry 556 (class 1259 OID 426896)
-- Name: load_profile_ogc_fid_seq; Type: SEQUENCE; Schema: catalog; Owner: catalog
--

CREATE SEQUENCE catalog.load_profile_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalog.load_profile_ogc_fid_seq OWNER TO catalog;

--
-- TOC entry 7542 (class 0 OID 0)
-- Dependencies: 556
-- Name: load_profile_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: catalog; Owner: catalog
--

ALTER SEQUENCE catalog.load_profile_ogc_fid_seq OWNED BY catalog.load_profile.ogc_fid;


--
-- TOC entry 558 (class 1259 OID 426905)
-- Name: load_stats_view; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.load_stats_view AS
 SELECT lower((load_profile.acronym)::text) AS schema_name,
    lower((load_profile.entity_name_revised)::text) AS table_name,
    load_profile.record_count,
    load_profile.srid,
    ( SELECT (c.reltuples)::bigint AS reltuples
           FROM (pg_class c
             JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
          WHERE ((c.relkind = 'r'::"char") AND (c.relname = lower((load_profile.entity_name_revised)::text)) AND (n.nspname = lower((load_profile.acronym)::text)))) AS loaded_estimate_counts
   FROM catalog.load_profile;


ALTER VIEW catalog.load_stats_view OWNER TO catalog;

--
-- TOC entry 875 (class 1259 OID 681970)
-- Name: product_configs; Type: VIEW; Schema: catalog; Owner: catalog
--

CREATE VIEW catalog.product_configs AS
 WITH a AS (
         SELECT c.collection_id,
            c.collection_name,
            c.acronym,
            ( SELECT min((p.url)::text) AS min
                   FROM catalog.data_product p
                  WHERE ((p.collection_id = c.collection_id) AND ((p.product_type)::text = 'hosted'::text))) AS sample_url,
            ( SELECT string_agg((p.url)::text, ';'::text) AS string_agg
                   FROM catalog.data_product p
                  WHERE ((p.collection_id = c.collection_id) AND ((p.product_type)::text = 'hosted'::text) AND (p.public_url = true))) AS urls,
            ( SELECT p.url
                   FROM catalog.data_product p
                  WHERE ((p.collection_id = c.collection_id) AND ((p.product_type)::text = 'factsheet'::text))) AS factsheet
           FROM catalog.data_collection c
        )
 SELECT a.collection_id,
    a.collection_name,
    a.acronym,
    COALESCE(a.sample_url, (''::character varying)::text) AS sample_url,
    COALESCE(a.urls, ''::text) AS urls,
    COALESCE(a.factsheet, ''::character varying) AS factsheet
   FROM a
  ORDER BY a.collection_name;


ALTER VIEW catalog.product_configs OWNER TO catalog;

--
-- TOC entry 7363 (class 2604 OID 682048)
-- Name: load_collection ogc_fid; Type: DEFAULT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.load_collection ALTER COLUMN ogc_fid SET DEFAULT nextval('catalog.load_collection_ogc_fid_seq'::regclass);


--
-- TOC entry 7362 (class 2604 OID 426900)
-- Name: load_profile ogc_fid; Type: DEFAULT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.load_profile ALTER COLUMN ogc_fid SET DEFAULT nextval('catalog.load_profile_ogc_fid_seq'::regclass);


--
-- TOC entry 7533 (class 0 OID 681961)
-- Dependencies: 873
-- Data for Name: data_collection; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

COPY catalog.data_collection (collection_id, collection_name, acronym) FROM stdin;
1	Coastal Systems Portfolio Initiative	CSPI
2	Corps Water Management System	CWMS
3	Dredging Information System	DIS
4	Flood Inundation Mapping	FIM
5	Formerly Used Defense Sites	FUDS
6	Ice Jam Database	IB
7	Inland Electronic Navigational Charts	IENC
8	Joint Airborn Lidar Bathymetry	JABLTCX
9	USACE Juristictional Determinations	JURISDICTION
10	Navigation and Civil Works Decision Support	NDC
11	National Channel Framework	NCF
12	National Inventory of Dams	NID
13	National Sediment Managment Framework 	NSMF
14	Operations & Maintenence 	OMBIL
15	Recreation	RECREATION
16	Real Estate Management Geospatial	REMIS
17	USACE Reservoirs	RESERVOIR
18	USACE Civil Works and Military Boundaries	BOUNDARIES
19	USACE Master Site List	MSL
20	USACE Survey Monument Archives	USMART
21	National Levee Database	NLD
23	National Coastal Structures Database	NCDB
33	Inland Waterways 	INW
34	Military Installations Training Areas	MIRTA
35	Port Statistical Areas	PORT
\.


--
-- TOC entry 7525 (class 0 OID 106055)
-- Dependencies: 480
-- Data for Name: data_product; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

COPY catalog.data_product (collection_id, product_id, product_type, url, public_url, format, authoritative) FROM stdin;
5	6	website	https://www.usace.army.mil/missions/environmental/formerly-used-defense-sites/	t	\N	\N
4	9	webmap	https://fim.wim.usgs.gov/fim/	t	\N	\N
8	13	website	https://jalbtcx.usace.army.mil/	t	\N	\N
1	1	website	https://www.arcgis.com/apps/MapSeries/index.html?appid=8f0ed6044c2e46948e25672ce0587437	t	\N	\N
2	3	website	https://www.hec.usace.army.mil/cwms	f	\N	\N
14	29	hosted	https://cwbi.ops.usace.army.mil/   	f	\N	f
3	4	website	https://ndc.ops.usace.army.mil/dis/	f	\N	\N
3	8	website	https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support/NDC-Dredges/	f	\N	\N
1	7	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer	t	\N	t
12	19	hosted	tbd	f	\N	f
7	52	factsheet	https://ienccloud.us/	t	\N	\N
21	35	factsheet	https://levees.sec.usace.army.mil	t	\N	\N
8	36	factsheet	https://www.sam.usace.army.mil/Missions/National-Centers-in-Mobile/Joint-Airborne-Lidar-Bathymetry	t	\N	\N
6	37	factsheet	https://icejam.sec.usace.army.mil/ords/f?p=1001:7	t	\N	\N
13	38	factsheet	https://www.erdc.usace.army.mil/Locations/CHL/Sediment-Management	t	\N	\N
14	39	factsheet	https://www.iwr.usace.army.mil/Missions/Civil-Works-Planning-and-Policy-Support/OMBIL	t	\N	\N
15	40	factsheet	https://www.usace.army.mil/missions/civil-works/recreation	t	\N	\N
16	41	factsheet	https://www.sam.usace.army.mil/Missions/Real-Estate	t	\N	\N
18	42	factsheet	https://www.usace.army.mil/Contact/Unit-Websites	t	\N	\N
20	43	factsheet	https://www.agc.army.mil/What-we-do/U-SMART	t	\N	\N
11	44	factsheet	https://navigation.usace.army.mil	t	\N	\N
1	45	factsheet	https://cspi.usace.army.mil	t	\N	\N
9	46	factsheet	https://www.sac.usace.army.mil/Missions/Regulatory/Jurisdictional-Determinations-and-Delineations	t	\N	\N
3	47	factsheet	https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support/NDC-Dredges	t	\N	\N
4	48	factsheet	https://mmc.sec.usace.army.mil/fact-sheets/FactSheet_10_FIM_FactSheet.pdf	t	\N	\N
5	49	factsheet	https://www.usace.army.mil/missions/environmental/formerly-used-defense-sites/	t	\N	\N
2	50	factsheet	https://www.hec.usace.army.mil/confluence/cwp/latest/corps-water-management-system-192381111.html	t	\N	\N
10	51	factsheet	https://www.iwr.usace.army.mil/About/Technical-Centers/NDC-Navigation-and-Civil-Works-Decision-Support	t	\N	\N
12	53	factsheet	https://nid.sec.usace.army.mil/#/	t	\N	\N
17	55	factsheet	https://resreg.spl.usace.army.mil/	t	\N	\N
12	57	download	https://nid.sec.usace.army.mil/api/nation/gpkg	t	\N	\N
23	61	factsheet	https://www.iwr.usace.army.mil/Missions/Coasts/Tales-of-the-Coast/Corps-and-the-Coast/Navigation/Structures/	t	\N	\N
5	10	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer	t	\N	t
6	11	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Current_Ice_Jams/FeatureServer	t	\N	t
7	12	hosted	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer	t	\N	t
10	14	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/pports21/FeatureServer	t	\N	t
11	18	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer	t	\N	t
13	21	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer	t	\N	t
16	22	hosted	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer	t	\N	t
17	23	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_rez/FeatureServer	t	\N	t
18	24	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer	t	\N	t
18	25	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_cw_divisions/FeatureServer	t	\N	t
18	26	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_dist/FeatureServer	t	\N	t
18	27	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_div/FeatureServer	t	\N	t
20	28	hosted	https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer	t	\N	t
10	15	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/linktons/FeatureServer	t	\N	t
10	16	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer	t	\N	t
10	17	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Docks/FeatureServer	t	\N	t
15	34	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_recreation_areas/FeatureServer	t	\N	t
23	56	hosted	https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer	t	\N	t
12	58	hosted	https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NID_v1/FeatureServer	t	\N	t
3	62	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer	t	\N	t
2	30	hosted	https://cwms-data.usace.army.mil/cwms-data/basins	f	\N	t
3	31	website	https://ndc.ops.usace.army.mil/dis/	f	\N	f
6	63	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Ice_Jams_Historic/FeatureServer	t	\N	t
19	64	factsheet	https://www.usace.army.mil/About/Centers-of-Expertise/	t	\N	\N
21	20	hosted	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer	f	\N	f
21	59	hosted	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer	t	\N	t
5	66	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/Formerly_Used_Defense_Sites/FeatureServer	t	\N	t
21	65	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/National_Levee_Database/FeatureServer	t	\N	t
12	67	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/National_Inventory_of_Dams/FeatureServer	t	\N	t
7	68	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/Inland_Electronic_Navigational_Data/FeatureServer	t	\N	t
1	69	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/Coastal_Systems_Portfolio_Initiative/FeatureServer	t	\N	t
23	70	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/National_Coastal_Structures_Database/FeatureServer	t	\N	t
16	71	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/Real_Estate_Management_Geospatial/FeatureServer	t	\N	t
3	72	hosted_egis	https://dev-portal.egis-usace.us/server/rest/services/Dredging_Information_System/FeatureServer	t	\N	t
33	74	hosted	https://geospatial.sec.usace.army.mil/server/rest/services/Hosted/AIS_NWN/FeatureServer/0	t	\N	t
34	75	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/mirta/FeatureServer	t	\N	t
35	76	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Port_Statistical_Area/FeatureServer	t	\N	t
4	5	webmap	https://ags03.sec.usace.army.mil/portal/apps/webappviewer/index.html?id=ca7ff838865349108910a398123ce968	t	\N	t
33	73	hosted	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Standardized_Inland_Waterway_Polygons/FeatureServer	t	\N	t
\.


--
-- TOC entry 7528 (class 0 OID 106077)
-- Dependencies: 483
-- Data for Name: data_product_item; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

COPY catalog.data_product_item (collection_product_id, collection_id, collection_name, acronym, table_title, table_name, artifact_type, record_count, spatial_type, srid, reference_product_id, notest, tags, item_url) FROM stdin;
170	3	Dredging Information System	DIS		dis_output	table	18911	NA	\N	\N	\N	\N	\N
167	3	Dredging Information System	DIS		dis_placements	feature class	18912	POINT	4326	\N	\N	\N	\N
150	5	Formerly Used Defense Sites	FUDS		fuds_munitions_response_site	feature class	1849	GEOMETRY	4326	\N	\N	\N	\N
178	5	Formerly Used Defense Sites	FUDS		fuds_program_district_boundaries	feature class	13	GEOMETRY	4326	\N	\N	\N	\N
145	5	Formerly Used Defense Sites	FUDS		fuds_project_point	feature class	5433	POINT	4326	\N	\N	\N	\N
142	5	Formerly Used Defense Sites	FUDS		fuds_property_point	feature class	10123	POINT	4326	\N	\N	\N	\N
154	5	Formerly Used Defense Sites	FUDS		fuds_property_polygon	feature class	5633	GEOMETRY	4326	\N	\N	\N	\N
165	5	Formerly Used Defense Sites	FUDS		irm_project_boundary	feature class	799	GEOMETRY	4326	\N	\N	\N	\N
173	5	Formerly Used Defense Sites	FUDS		irm_property_boundary	feature class	598	GEOMETRY	4326	\N	\N	\N	\N
159	5	Formerly Used Defense Sites	FUDS		irm_property_point	feature class	598	POINT	4326	\N	\N	\N	\N
40	7	Inland Electronic Navigational Charts	IENC		airport_area	feature class	72	POLYGON	4326	\N	\N	\N	\N
113	7	Inland Electronic Navigational Charts	IENC		airport_area_point	feature class	4	POINT	4326	\N	\N	\N	\N
97	7	Inland Electronic Navigational Charts	IENC		anchor_berth_area	feature class	1	POLYGON	4326	\N	\N	\N	\N
104	7	Inland Electronic Navigational Charts	IENC		berths_area	feature class	1092	POLYGON	4326	\N	\N	\N	\N
50	7	Inland Electronic Navigational Charts	IENC		bridge_area	feature class	3761	POLYGON	4326	\N	\N	\N	\N
120	7	Inland Electronic Navigational Charts	IENC		building_single_point	feature class	892	POINT	4326	\N	\N	\N	\N
88	7	Inland Electronic Navigational Charts	IENC		built_up_area	feature class	995	POLYGON	4326	\N	\N	\N	\N
106	7	Inland Electronic Navigational Charts	IENC		built_up_area_point	feature class	612	POINT	4326	\N	\N	\N	\N
129	7	Inland Electronic Navigational Charts	IENC		buoy_special_purpose_point	feature class	105	POINT	4326	\N	\N	\N	\N
22	7	Inland Electronic Navigational Charts	IENC		cable_area	feature class	32	POLYGON	4326	\N	\N	\N	\N
132	7	Inland Electronic Navigational Charts	IENC		canals_area	feature class	3	POLYGON	4326	\N	\N	\N	\N
109	7	Inland Electronic Navigational Charts	IENC		caution_area	feature class	2912	POLYGON	4326	\N	\N	\N	\N
133	7	Inland Electronic Navigational Charts	IENC		caution_area_point	feature class	41	POINT	4326	\N	\N	\N	\N
32	7	Inland Electronic Navigational Charts	IENC		conveyor_area	feature class	263	POLYGON	4326	\N	\N	\N	\N
41	7	Inland Electronic Navigational Charts	IENC		cranes_area	feature class	37	POLYGON	4326	\N	\N	\N	\N
47	7	Inland Electronic Navigational Charts	IENC		dam_area	feature class	173	POLYGON	4326	\N	\N	\N	\N
54	7	Inland Electronic Navigational Charts	IENC		data_coverage_area	feature class	317	POLYGON	4326	\N	\N	\N	\N
59	7	Inland Electronic Navigational Charts	IENC		data_quality_area	feature class	109	POLYGON	4326	\N	\N	\N	\N
68	7	Inland Electronic Navigational Charts	IENC		dry_dock_area	feature class	2	POLYGON	4326	\N	\N	\N	\N
100	7	Inland Electronic Navigational Charts	IENC		dumping_ground_area	feature class	1	POLYGON	4326	\N	\N	\N	\N
23	7	Inland Electronic Navigational Charts	IENC		ferry_route_line	feature class	30	LINESTRING	4326	\N	\N	\N	\N
119	7	Inland Electronic Navigational Charts	IENC		floating_dock_area	feature class	48	POLYGON	4326	\N	\N	\N	\N
31	7	Inland Electronic Navigational Charts	IENC		floodwall_line	feature class	373	LINESTRING	4326	\N	\N	\N	\N
124	7	Inland Electronic Navigational Charts	IENC		harbour_area	feature class	1	POLYGON	4326	\N	\N	\N	\N
139	7	Inland Electronic Navigational Charts	IENC		hulkes_area	feature class	44	POLYGON	4326	\N	\N	\N	\N
98	7	Inland Electronic Navigational Charts	IENC		isolated_danger_buoy_point	feature class	1	POINT	4326	\N	\N	\N	\N
116	1	Coastal Systems Portfolio Initiative	CSPI	Environmental Work Windows	cspi_initialconstruction	table	293	NA	\N	7	\N	\N	\N
81	1	Coastal Systems Portfolio Initiative	CSPI	Resources at Risk & Locations	cspi_project_extents	feature class	773	GEOMETRY	4326	7	\N	\N	\N
43	1	Coastal Systems Portfolio Initiative	CSPI	CSPI Project Summary & Locations	cspi_project_rollup	feature class	1098	POINT	4326	7	\N	\N	\N
122	1	Coastal Systems Portfolio Initiative	CSPI	Current and Historical Reliability	cspi_reliability_history	table	4033	NA	\N	7	\N	\N	\N
69	1	Coastal Systems Portfolio Initiative	CSPI	Renourishment Locations	cspi_renourishments	feature class	720	POINT	4326	7	\N	\N	\N
4	7	Inland Electronic Navigational Charts	IENC		daymark_point	feature class	4804	POINT	4326	\N	\N	LOCATION	/cwms-data/locations
6	7	Inland Electronic Navigational Charts	IENC		building_single_area	feature class	119201	POLYGON	4326	\N	\N	LOCATION	/cwms-data/counties
7	7	Inland Electronic Navigational Charts	IENC		distance_mark_point	feature class	7452	POINT	4326	\N	\N	LOCATION	/cwms-data/offices
8	7	Inland Electronic Navigational Charts	IENC		conveyor_line	feature class	881	LINESTRING	4326	\N	\N	LOCATION	/cwms-data/units
11	5	Formerly Used Defense Sites	FUDS		fuds_program_division_boundaries	feature class	7	GEOMETRY	4326	\N	\N		/cwms-data/levels
12	7	Inland Electronic Navigational Charts	IENC		harbour_facility_area	feature class	94	POLYGON	4326	\N	\N		/cwms-data/timeseries/category
15	6	Ice Jam Database	IB		current_ice_jams	feature class	66	POINT	4326	\N	\N		/cwms-data/timeseries
17	7	Inland Electronic Navigational Charts	IENC		dam_line	feature class	40	LINESTRING	4326	\N	\N	BASIN	/cwms-data/basins
2	7	Inland Electronic Navigational Charts	IENC		cranes_point	feature class	149	POINT	4326	\N	\N	LOCATION	\N
3	7	Inland Electronic Navigational Charts	IENC		coastline_line	feature class	22711	LINESTRING	4326	\N	\N	LOCATION	/cwms-data/location/group
64	1	Coastal Systems Portfolio Initiative	CSPI	Aquatic Ecosystem Restoration Details & Location	cspi_damagerisk	feature class	1097	POINT	4326	7	\N	\N	\N
112	7	Inland Electronic Navigational Charts	IENC		land_area	feature class	18947	POLYGON	4326	\N	\N	\N	\N
73	7	Inland Electronic Navigational Charts	IENC		land_region_area	feature class	118	POLYGON	4326	\N	\N	\N	\N
28	7	Inland Electronic Navigational Charts	IENC		landmark_area	feature class	6	POLYGON	4326	\N	\N	\N	\N
30	7	Inland Electronic Navigational Charts	IENC		lateral_beacon_point	feature class	3443	POINT	4326	\N	\N	\N	\N
37	7	Inland Electronic Navigational Charts	IENC		lateral_buoy_point	feature class	10	POINT	4326	\N	\N	\N	\N
35	7	Inland Electronic Navigational Charts	IENC		levee_area	feature class	321	POLYGON	4326	\N	\N	\N	\N
38	7	Inland Electronic Navigational Charts	IENC		levee_line	feature class	721	LINESTRING	4326	\N	\N	\N	\N
45	7	Inland Electronic Navigational Charts	IENC		lights_point	feature class	8919	POINT	4326	\N	\N	\N	\N
33	7	Inland Electronic Navigational Charts	IENC		lock_gate_area	feature class	94	POLYGON	4326	\N	\N	\N	\N
44	7	Inland Electronic Navigational Charts	IENC		lock_gate_line	feature class	299	LINESTRING	4326	\N	\N	\N	\N
48	7	Inland Electronic Navigational Charts	IENC		mooring_facility_area	feature class	5784	POLYGON	4326	\N	\N	\N	\N
53	7	Inland Electronic Navigational Charts	IENC		mooring_facility_line	feature class	1	LINESTRING	4326	\N	\N	\N	\N
51	7	Inland Electronic Navigational Charts	IENC		mooring_facility_point	feature class	9744	POINT	4326	\N	\N	\N	\N
82	7	Inland Electronic Navigational Charts	IENC		nautical_publication_information_area	feature class	109	POLYGON	4326	\N	\N	\N	\N
89	7	Inland Electronic Navigational Charts	IENC		navigational_system_of_marks_area	feature class	109	POLYGON	4326	\N	\N	\N	\N
58	7	Inland Electronic Navigational Charts	IENC		notice_mark_point	feature class	266	POINT	4326	\N	\N	\N	\N
62	7	Inland Electronic Navigational Charts	IENC		obstruction_area	feature class	366	POLYGON	4326	\N	\N	\N	\N
60	7	Inland Electronic Navigational Charts	IENC		obstruction_line	feature class	16	LINESTRING	4326	\N	\N	\N	\N
65	7	Inland Electronic Navigational Charts	IENC		obstruction_point	feature class	160	POINT	4326	\N	\N	\N	\N
66	7	Inland Electronic Navigational Charts	IENC		overhead_cable_line	feature class	1629	LINESTRING	4326	\N	\N	\N	\N
72	7	Inland Electronic Navigational Charts	IENC		overhead_pipeline_line	feature class	92	LINESTRING	4326	\N	\N	\N	\N
70	7	Inland Electronic Navigational Charts	IENC		pile_point	feature class	3012	POINT	4326	\N	\N	\N	\N
74	7	Inland Electronic Navigational Charts	IENC		pipe_area	feature class	114	POLYGON	4326	\N	\N	\N	\N
125	7	Inland Electronic Navigational Charts	IENC		pontoon_area	feature class	515	POLYGON	4326	\N	\N	\N	\N
95	7	Inland Electronic Navigational Charts	IENC		pylons_area	feature class	6401	POLYGON	4326	\N	\N	\N	\N
79	7	Inland Electronic Navigational Charts	IENC		pylons_point	feature class	4070	POINT	4326	\N	\N	\N	\N
80	7	Inland Electronic Navigational Charts	IENC		railroad_line	feature class	10576	LINESTRING	4326	\N	\N	\N	\N
85	7	Inland Electronic Navigational Charts	IENC		recommended_track_line	feature class	566	LINESTRING	4326	\N	\N	\N	\N
90	7	Inland Electronic Navigational Charts	IENC		restricted_area	feature class	1233	POLYGON	4326	\N	\N	\N	\N
135	7	Inland Electronic Navigational Charts	IENC		rivers_area	feature class	3655	POLYGON	4326	\N	\N	\N	\N
93	7	Inland Electronic Navigational Charts	IENC		rivers_line	feature class	5735	LINESTRING	4326	\N	\N	\N	\N
99	7	Inland Electronic Navigational Charts	IENC		roadway_line	feature class	93021	LINESTRING	4326	\N	\N	\N	\N
102	7	Inland Electronic Navigational Charts	IENC		sea_area	feature class	222	POLYGON	4326	\N	\N	\N	\N
87	7	Inland Electronic Navigational Charts	IENC		sea_area_point	feature class	1942	POINT	4326	\N	\N	\N	\N
84	7	Inland Electronic Navigational Charts	IENC		sensor_point	feature class	19	POINT	4326	\N	\N	\N	\N
75	7	Inland Electronic Navigational Charts	IENC		shoreline_construction_area	feature class	7821	POLYGON	4326	\N	\N	\N	\N
108	7	Inland Electronic Navigational Charts	IENC		shoreline_construction_line	feature class	28801	LINESTRING	4326	\N	\N	\N	\N
94	7	Inland Electronic Navigational Charts	IENC		shoreline_construction_point	feature class	4720	POINT	4326	\N	\N	\N	\N
114	7	Inland Electronic Navigational Charts	IENC		slope_topline_line	feature class	233	LINESTRING	4326	\N	\N	\N	\N
110	7	Inland Electronic Navigational Charts	IENC		sloping_ground_area	feature class	23	POLYGON	4326	\N	\N	\N	\N
25	7	Inland Electronic Navigational Charts	IENC		small_craft_facility_area	feature class	27	POLYGON	4326	\N	\N	\N	\N
101	7	Inland Electronic Navigational Charts	IENC		small_craft_facility_point	feature class	155	POINT	4326	\N	\N	\N	\N
117	7	Inland Electronic Navigational Charts	IENC		storage_tank_silo_area	feature class	3602	POLYGON	4326	\N	\N	\N	\N
107	7	Inland Electronic Navigational Charts	IENC		storage_tank_silo_point	feature class	1078	POINT	4326	\N	\N	\N	\N
121	7	Inland Electronic Navigational Charts	IENC		submarine_cable_line	feature class	227	LINESTRING	4326	\N	\N	\N	\N
130	7	Inland Electronic Navigational Charts	IENC		submarine_pipeline_line	feature class	1418	LINESTRING	4326	\N	\N	\N	\N
115	7	Inland Electronic Navigational Charts	IENC		submarine_pipeline_point	feature class	902	POINT	4326	\N	\N	\N	\N
52	7	Inland Electronic Navigational Charts	IENC		terminal_area	feature class	39	POLYGON	4326	\N	\N	\N	\N
92	7	Inland Electronic Navigational Charts	IENC		terminal_point	feature class	13	POINT	4326	\N	\N	\N	\N
18	7	Inland Electronic Navigational Charts	IENC		land_region_point	feature class	3612	POINT	4326	\N	\N	\N	/cwms-data/blobs
21	7	Inland Electronic Navigational Charts	IENC		landmark_point	feature class	552	POINT	4326	\N	\N		/cwms-data/specified-levels
20	7	Inland Electronic Navigational Charts	IENC		lock_basin_area	feature class	173	POLYGON	4326	\N	\N	POOL	/cwms-data/pools
123	7	Inland Electronic Navigational Charts	IENC		traffic_signal_station_point	feature class	298	POINT	4326	\N	\N	\N	\N
136	7	Inland Electronic Navigational Charts	IENC		underwater_rock_area	feature class	124	POLYGON	4326	\N	\N	\N	\N
127	7	Inland Electronic Navigational Charts	IENC		underwater_rock_point	feature class	114	POINT	4326	\N	\N	\N	\N
138	7	Inland Electronic Navigational Charts	IENC		waterway_gauge_point	feature class	753	POINT	4326	\N	\N	\N	\N
55	11	National Channel Framework	NCF		channelarea	feature class	2662	GEOMETRY	4326	\N	\N	\N	\N
46	11	National Channel Framework	NCF		channelline	feature class	36153	GEOMETRY	4326	\N	\N	\N	\N
67	11	National Channel Framework	NCF		channelquarter	feature class	24408	GEOMETRY	4326	\N	\N	\N	\N
61	11	National Channel Framework	NCF		channelreach	feature class	12836	GEOMETRY	4326	\N	\N	\N	\N
128	12	National Inventory of Dams	NID		national_inventory_dams	feature class	91886	POINT	0	\N	\N	\N	\N
172	21	National Levee Database	NLD		alignment_lines	feature class	31251	GEOMETRY	4326	\N	\N	\N	\N
153	21	National Levee Database	NLD		boreholes	feature class	47973	POINT	0	\N	\N	\N	\N
176	21	National Levee Database	NLD		channels	feature class	1	LINESTRING	0	\N	\N	\N	\N
181	21	National Levee Database	NLD		closure_structures	feature class	3556	GEOMETRY	4326	\N	\N	\N	\N
149	21	National Levee Database	NLD		cross_sections	feature class	241865	GEOMETRY	4326	\N	\N	\N	\N
143	21	National Levee Database	NLD		crossings	feature class	111239	POINT	0	\N	\N	\N	\N
158	21	National Levee Database	NLD		embankments	feature class	25754	GEOMETRY	4326	\N	\N	\N	\N
163	21	National Levee Database	NLD		floodwalls	feature class	14661	GEOMETRY	4326	\N	\N	\N	\N
166	21	National Levee Database	NLD		frm_lines	feature class	52	GEOMETRY	4326	\N	\N	\N	\N
157	21	National Levee Database	NLD		levee_stations	feature class	440795	POINT	0	\N	\N	\N	\N
144	21	National Levee Database	NLD		leveed_areas	feature class	6610	GEOMETRY	4326	\N	\N	\N	\N
160	21	National Levee Database	NLD		piezometers	feature class	2417	POINT	0	\N	\N	\N	\N
162	21	National Levee Database	NLD		pipe_gates	feature class	9496	POINT	0	\N	\N	\N	\N
169	21	National Levee Database	NLD		pipes	feature class	17369	GEOMETRY	4326	\N	\N	\N	\N
168	21	National Levee Database	NLD		pump_stations	feature class	2090	POINT	0	\N	\N	\N	\N
171	21	National Levee Database	NLD		relief_wells	feature class	10698	POINT	0	\N	\N	\N	\N
177	21	National Levee Database	NLD		system_routes	feature class	6815	GEOMETRY	4326	\N	\N	\N	\N
180	21	National Levee Database	NLD		toe_drains	feature class	1183	GEOMETRY	4326	\N	\N	\N	\N
164	13	National Sediment Managment Framework 	NSMF		borrowarea	feature class	126	POLYGON	4326	\N	\N	\N	\N
174	13	National Sediment Managment Framework 	NSMF		placementarea	feature class	2704	GEOMETRY	4326	\N	\N	\N	\N
161	10	Navigation and Civil Works Decision Support	NDC		dock	feature class	23719	POINT	4326	\N	\N	\N	\N
111	10	Navigation and Civil Works Decision Support	NDC		link tonnages (historic)	feature class	2901	GEOMETRY	4326	\N	\N	\N	\N
175	10	Navigation and Civil Works Decision Support	NDC		link_tonnages_(historic)	feature class	2901	GEOMETRY	4326	\N	\N	\N	\N
71	10	Navigation and Civil Works Decision Support	NDC		linktons	feature class	2900	LINESTRING	4326	\N	\N	\N	\N
146	10	Navigation and Civil Works Decision Support	NDC		lock	feature class	234	POINT	4326	\N	\N	\N	\N
83	10	Navigation and Civil Works Decision Support	NDC		pports21	feature class	150	POINT	4326	\N	\N	\N	\N
34	10	Navigation and Civil Works Decision Support	NDC		principal port	feature class	150	POINT	4326	\N	\N	\N	\N
137	10	Navigation and Civil Works Decision Support	NDC		principal_port	feature class	150	POINT	4326	\N	\N	\N	\N
27	10	Navigation and Civil Works Decision Support	NDC		waterway mile marker	feature class	11406	POINT	4326	\N	\N	\N	\N
103	10	Navigation and Civil Works Decision Support	NDC		waterway network	feature class	6859	GEOMETRY	4326	\N	\N	\N	\N
86	10	Navigation and Civil Works Decision Support	NDC		waterway network node	feature class	6255	POINT	4326	\N	\N	\N	\N
126	10	Navigation and Civil Works Decision Support	NDC		waterway_mile_marker	feature class	11406	POINT	4326	\N	\N	\N	\N
155	10	Navigation and Civil Works Decision Support	NDC		waterway_network	feature class	6859	GEOMETRY	4326	\N	\N	\N	\N
151	10	Navigation and Civil Works Decision Support	NDC		waterway_network_node	feature class	6255	POINT	4326	\N	\N	\N	\N
141	16	Real Estate Management Geospatial	REMIS		disposal area	feature class	18155	GEOMETRY	4326	\N	\N	\N	\N
91	16	Real Estate Management Geospatial	REMIS		disposal line	feature class	8	GEOMETRY	4326	\N	\N	\N	\N
63	16	Real Estate Management Geospatial	REMIS		disposal_area	feature class	18155	GEOMETRY	4326	\N	\N	\N	\N
179	16	Real Estate Management Geospatial	REMIS		disposal_line	feature class	8	GEOMETRY	4326	\N	\N	\N	\N
77	16	Real Estate Management Geospatial	REMIS		land parcel area	feature class	254300	GEOMETRY	4326	\N	\N	\N	\N
105	16	Real Estate Management Geospatial	REMIS		land parcel line	feature class	53	GEOMETRY	4326	\N	\N	\N	\N
76	16	Real Estate Management Geospatial	REMIS		land_parcel_area	feature class	254300	GEOMETRY	4326	\N	\N	\N	\N
26	16	Real Estate Management Geospatial	REMIS		land_parcel_line	feature class	53	GEOMETRY	4326	\N	\N	\N	\N
118	16	Real Estate Management Geospatial	REMIS		outgrant area	feature class	503	GEOMETRY	4326	\N	\N	\N	\N
42	16	Real Estate Management Geospatial	REMIS		outgrant_area	feature class	503	GEOMETRY	4326	\N	\N	\N	\N
140	16	Real Estate Management Geospatial	REMIS		site	feature class	1603	GEOMETRY	4326	\N	\N	\N	\N
156	15	Recreation	RECREATION		recreation_area	feature class	3659	GEOMETRY	4326	\N	\N	\N	\N
16	18	USACE Civil Works and Military Boundaries	BOUNDARIES		usace_districts	feature class	38	GEOMETRY	4326	\N	\N		/cwms-data/ratings
10	7	Inland Electronic Navigational Charts	IENC		wrecks_area	feature class	10	POLYGON	4326	\N	\N		/cwms-data/timezones
36	18	USACE Civil Works and Military Boundaries	BOUNDARIES		usace_divisions	feature class	8	GEOMETRY	4326	\N	\N	\N	\N
29	18	USACE Civil Works and Military Boundaries	BOUNDARIES		usace_military_districts	feature class	24	GEOMETRY	4326	\N	\N	\N	\N
56	17	USACE Reservoirs	RESERVOIR		usace reservoirs	feature class	418	GEOMETRY	4326	\N	\N	\N	\N
147	17	USACE Reservoirs	RESERVOIR		usace_reservoirs	feature class	418	GEOMETRY	4326	\N	\N	\N	\N
152	20	USACE Survey Monument Archives	USMART		local_control_points	feature class	191501	POINT	4326	\N	\N	\N	\N
24	23	National Coastal Structures Database	NCDB		usace_structure_polygon	feature class	1078	POLYGON	4326	56	\N	\N	\N
148	20	USACE Survey Monument Archives	USMART		primary_control_points	feature class	7030	POINT	4326	\N	\N	\N	\N
134	1	Coastal Systems Portfolio Initiative	CSPI	Coastal Storm Risk Management Details & Locations	cspi_csrm_aer_datacheck	table	500	NA	\N	7	\N	\N	\N
57	1	Coastal Systems Portfolio Initiative	CSPI	Coastal Storm Risk Management Details & Locations	cspi_csrm_aer_overview	feature class	464	POINT	4326	7	\N	\N	\N
49	1	Coastal Systems Portfolio Initiative	CSPI	Navigation Details & Locations	cspi_nav_overview	feature class	632	POINT	4326	7	\N	\N	\N
131	1	Coastal Systems Portfolio Initiative	CSPI	Project Milestones/Report Dates	cspi_reports	table	656	NA	\N	7	\N	\N	\N
39	23	National Coastal Structures Database	NCDB		structure_vessel_data	table	66812	NA	\N	56	\N	\N	\N
1	7	Inland Electronic Navigational Charts	IENC		warning_signal_station_point	feature class	508	POINT	4326	\N	Did not load, error when loaded in Map Viewer	\N	\N
1	23	National Coastal Structures Database	NCDB		usace_structure_point	feature Class	\N	POINT	\N	56	Did not load, error when loaded in Map Viewer	\N	\N
96	1	Coastal Systems Portfolio Initiative	CSPI	Dredging Operations (collected by CSPI, which is not the authoritative source)	cspi_dredgingwindows	table	745	NA	\N	7	\N	DREDGING	\N
12	2	Corps Water Management System	CWMS	TimeSeries Categories	\N	\N	\N	\N	\N	\N	\N		/cwms-data/timeseries/category
13	7	Inland Electronic Navigational Charts	IENC		harbour_facility_point	feature class	556	POINT	4326	\N	\N		/cwms-data/timeseries/identifier-descriptor
13	2	Corps Water Management System	CWMS	TimeSeries Identifier	\N	\N	\N	\N	\N	\N	\N		/cwms-data/timeseries/identifier-descriptor
14	7	Inland Electronic Navigational Charts	IENC		canals_line	feature class	1	LINESTRING	4326	\N	\N		/cwms-data/timeseries/group
14	2	Corps Water Management System	CWMS	Timeseries Groups	\N	\N	\N	\N	\N	\N	\N		/cwms-data/timeseries/group
15	2	Corps Water Management System	CWMS	TimeSeries	\N	\N	\N	\N	\N	\N	\N		/cwms-data/timeseries
16	2	Corps Water Management System	CWMS	Ratings	\N	\N	\N	\N	\N	\N	\N		/cwms-data/ratings
17	2	Corps Water Management System	CWMS	Basins	\N	\N	\N	\N	\N	\N	\N	BASIN	/cwms-data/basins
21	2	Corps Water Management System	CWMS	Levels	\N	\N	\N	\N	\N	\N	\N		/cwms-data/specified-levels
20	2	Corps Water Management System	CWMS	Pools	\N	\N	\N	\N	\N	\N	\N	POOL	/cwms-data/pools
18	2	Corps Water Management System	CWMS	Blob	\N	\N	\N	\N	\N	\N	\N	LOCATION CATEGORIES	/cwms-data/blobs
2	2	Corps Water Management System	CWMS	Location Categories	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/location/category
3	2	Corps Water Management System	CWMS	Location Groups	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/location/group
4	2	Corps Water Management System	CWMS	Locations	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/locations
5	7	Inland Electronic Navigational Charts	IENC		lake_area	feature class	4923	POLYGON	4326	\N	\N	LOCATION	/cwms-data/states
5	2	Corps Water Management System	CWMS	States	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/states
6	2	Corps Water Management System	CWMS	Counties	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/counties
7	2	Corps Water Management System	CWMS	Offices	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/offices
8	2	Corps Water Management System	CWMS	Units	\N	\N	\N	\N	\N	\N	\N	LOCATION	/cwms-data/units
9	7	Inland Electronic Navigational Charts	IENC		wrecks_point	feature class	548	POINT	4326	\N	\N		/cwms-data/parameters
9	2	Corps Water Management System	CWMS	Parameters	\N	\N	\N	\N	\N	\N	\N		/cwms-data/parameters
10	2	Corps Water Management System	CWMS	TimeZones	\N	\N	\N	\N	\N	\N	\N		/cwms-data/timezones
11	2	Corps Water Management System	CWMS	Levels	\N	\N	\N	\N	\N	\N	\N		/cwms-data/levels
19	18	USACE Civil Works and Military Boundaries	BOUNDARIES		usace_military_divisions	feature class	8	GEOMETRY	4326	\N	\N		/cwms-data/clobs
19	2	Corps Water Management System	CWMS	Clob	\N	\N	\N	\N	\N	\N	\N		/cwms-data/clobs
\.


--
-- TOC entry 7535 (class 0 OID 682045)
-- Dependencies: 877
-- Data for Name: load_collection; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

COPY catalog.load_collection (ogc_fid, collection_code, collection_id, collection_name, load_datetimestamp, wkid, layer_count, table_count, load_status, source_file_path, url, serviceitemid, servicedescription, description) FROM stdin;
1	BOUNDARIES	18	USACE Civil Works and Military Boundaries	2024-08-07 21:17:27	4326	1	0	preloaded	d:\\bah\\BOUNDARIES\\USACE_Civil_Works_and_Military_Boundaries.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_dist/FeatureServer	c12cd7878abf4b5cae6442cf4007e0d2	Polygons showing USACE Military District boundaries.	USACE Military District boundaries. Polygons were derived from National Atlas states and/or from data provided by the district.
2	BOUNDARIES	18	USACE Civil Works and Military Boundaries	2024-08-07 21:17:27	4326	1	0	preloaded	d:\\bah\\BOUNDARIES\\USACE_Civil_Works_and_Military_Boundaries.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_div/FeatureServer	332c009228ee4dd58edb744ef89a4b56	Polygons showing USACE Military Division boundaries.	USACE Military Division boundaries. Polygons were derived from National Atlas states and/or from data provided by the district.
3	BOUNDARIES	18	USACE Civil Works and Military Boundaries	2024-08-07 21:17:27	4140	1	0	preloaded	d:\\bah\\BOUNDARIES\\USACE_Civil_Works_and_Military_Boundaries.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer	f3e0ba4566094e74910c391eb4ecc99f	USACE Civils Works District Boundaries	Polygons showing USACE Civil Works District boundaries. This dataset was digitized from the NRCS Watershed Boundary Dataset (WBD). Where districts follow administrative boundaries, such as County and State lines, National Atlas and Census datasets were used. USACE District GIS POCs also submitted data to incorporate into this dataset. This dataset has been simplified +/- 30 feet to reduce file size and speed up drawing time. 05/05/20 - Update to show new LRC boundary. Minor change between LRL and LRH.
4	BOUNDARIES	18	USACE Civil Works and Military Boundaries	2024-08-07 21:17:27	4269	1	0	preloaded	d:\\bah\\BOUNDARIES\\USACE_Civil_Works_and_Military_Boundaries.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_cw_divisions/FeatureServer	4cdab8820d7a4f58aaa003be63f059ac	Polygons showing USACE Civil Works Division boundaries.	Polygons showing USACE Civil Works Division boundaries. This dataset was digitized from the NRCS Watershed Boundary Dataset (WBD). Where districts follow administrative boundaries, such as County and State lines, National Atlas and Census datasets were used. USACE District GIS POCs also submitted data to incorporate into this dataset. This dataset has been simplified +/- 30 feet to reduce file size and speed up drawing time. 04/16/20 - Update to show new LRC boundary.
5	CSPI	1	Coastal Systems Portfolio Initiative	2024-08-07 21:17:27	4326	6	5	preloaded	d:\\bah\\CSPI\\Coastal_Systems_Portfolio_Initiative.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer	4dcfec9cc9524526afd54ee2efe32d68	This feature service holds all of the CSPI data collected.  This is the data source that fuels the main CSPI application available.  All data available in this web service is releasable to the public.	<div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'>This feature service holds all of the CSPI data collected as part of the FY2020 Data Call.  This is the data source that fuels the main CSPI application available.  <i>All data available in this web service is releasable to the public.</i></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><br /></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><b>CSPI User Interfaces Available</b></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><a href='https://geoportal.eis.usace.army.mil/s3portal/apps/MapSeries/index.html?appid=52c5969f72874241840332e65873b52c&amp;edit=true&amp;folderid=46fb7344598a4f08a026621183e2cff5' style='color:rgb(0, 121, 193); text-decoration-line:none; font-family:&quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif; font-size:15px;' target='_blank' rel='nofollow ugc noopener noreferrer'>USACE User Interface</a> | <a href='https://arcgis.com/apps/MapSeries/index.html?appid=8f0ed6044c2e46948e25672ce0587437' style='color:rgb(0, 121, 193); text-decoration-line:none; font-family:&quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif; font-size:15px;' target='_blank' rel='nofollow ugc noopener noreferrer'>Public Access Interface</a></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><br /></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><b>Data Content Available in this Web Service</b></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><ul><li>CSPI Project Summary &amp; Locations</li><li>Navigation Details &amp; Locations</li><li>Coastal Storm Risk Management Details &amp; Locations</li><li>Aquatic Ecosystem Restoration Details &amp; Location</li><li>Renourishment Locations</li><li>Resources at Risk &amp; Locations</li><li>Dredging Operations (collected by CSPI, which is not the authoritative source)</li><li>Environmental Work Windows</li><li>Project Milestones/Report Dates*</li><li>Current and Historical Reliability*</li><li>CSRM/AER Initial Construction Details*</li></ul></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><i>*Data is available as a hosted table and doesn't not have shape geometry.</i></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><br /></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'>What is Coastal Systems Portfolio Initiative?The Coastal Systems Portfolio Initiative (CSPI) databases provide an archive for data to support many of the CSPI initiatives.</div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><br /></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'>As the federal agency authorized by Congress to study, plan, design, construct, and renourish coastal risk reduction projects, the USACE is tasked with providing technical input on current and future needs for coastal projects. Accurate, up-to-date, and accessible technical information serves as a valuable resource for decision makers responsible for making balanced, information-based decisions for managing coastal programs.</div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'><br /></div><div style='font-family:&quot;Avenir Next W01&quot;, &quot;Avenir Next W00&quot;, &quot;Avenir Next&quot;, Avenir, &quot;Helvetica Neue&quot;, sans-serif; font-size:16px;'>This web database presents the “big picture” about current and future needs for coastal projects within USACE. As the nation’s engineer, the USACE collected and presented technical data and estimated costs, with consideration of project reliability and risk. The process used by the USACE to examine federal projects as a total system instead of as individual projects will continue to be refined over time. This technical review is an initial systems-based tool that decision makers at any level can use to make more informed judgments as they manage coastal risk reduction projects in the United States, both now and in the near future.</div>
6	DIS	3	Dredging Information System	2024-08-07 21:17:27	4326	1	1	preloaded	d:\\bah\\DIS\\Dredging_Information_System.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer	aaf2d957e7b04e4f8d211918e88db283	Filtered export of the Dredging Information System (DIS) designed for use by the Regional Sediment Managment (RSM) Beneficial Use Viewer.	Filtered export of the Dredging Information System (DIS) designed for use by the Regional Sediment Managment (RSM) Beneficial Use Viewer.
7	FUDS	5	Formerly Used Defense Sites	2024-08-07 21:17:27	4326	9	0	preloaded	d:\\bah\\FUDS\\Formerly_Used_Defense_Sites.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer	3f8354667d5b4b1b8ad7a6e00c3cf3b1	FUDS FY21 and IRM Data. Property and Project geospatial data. Interim Risk Management Data. FUDS Program Division and District Boundaries.	Property and Project geospatial data. Interim Risk Management Data. FUDS Program Division and District Boundaries.
8	IB	6	Ice Jam Database	2024-08-07 21:17:27	102100	1	0	preloaded	d:\\bah\\IB\\Ice_Jam_Database.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Ice_Jams_Historic/FeatureServer	84e7f2e5d37b45268ea5618ae4cf1809		
9	IB	6	Ice Jam Database	2024-08-07 21:17:27	4326	1	0	preloaded	d:\\bah\\IB\\Ice_Jam_Database.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Current_Ice_Jams/FeatureServer	88457ecc8bf149da8c8ac0d4c8bf38d5	Near real-time Ice jams during 2024 water year.	Current Ice Jams
10	IENC	7	Inland Electronic Navigational Charts	2024-08-07 21:17:27	4326	98	0	preloaded	d:\\bah\\IENC\\Inland_Electronic_Navigational_Charts.json	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer		USACE Inland Electronic Navigational Charts data in native S-57 data format have been converted to vector GIS data with all feature class names, attributes and attribute value enumerations translated to common English naming conventions. These IENC data represent 7,265 statute miles of navigational data produced by the US Army Corps of Engineers IENC Program.\n	
11	INW	33	Inland Waterways 	2024-08-07 21:17:27	4326	1	0	preloaded	d:\\bah\\INW\\Inland_Waterways.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Standardized_Inland_Waterway_Polygons/FeatureServer	874da2f0bd89477d9850bd4bfa7f0f68	Inland waterway polygons	
12	INW	33	Inland Waterways 	2024-08-07 21:17:27		0	0	preloaded	d:\\bah\\INW\\Inland_Waterways.json	https://geospatial.sec.usace.army.mil/server/rest/services/Hosted/AIS_NWN/FeatureServer/0			
13	MIRTA	34	Military Installations Training Areas	2024-08-07 21:17:27	4326	2	0	preloaded	d:\\bah\\MIRTA\\Military_Installations_Training_Areas.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/mirta/FeatureServer	fc0f38c5a19a46dbacd92f2fb823ef8c	Military Installations, Ranges, and Training Areas (MIRTA). Publicly releasable locations of DoD Sites in the 50 states, Puerto Rico, and Guam available through data.gov.	The dataset depicts the authoritative locations of the most commonly known Department of Defense (DoD) sites, installations, ranges, and training areas in the United States and Territories. These sites encompass land which is federally owned or otherwise managed. This dataset was created from source data provided by the four Military Service Component headquarters and was compiled by the Defense Installation Spatial Data Infrastructure (DISDI) Program within the Office of the Deputy Under Secretary of Defense for Installations and Environment, Business Enterprise Integration Directorate. Sites were selected from the 2009 Base Structure Report (BSR), a summary of the DoD Real Property Inventory. This list does not necessarily represent a comprehensive collection of all Department of Defense facilities, and only those in the fifty United States and US Territories were considered for inclusion. For inventory purposes, installations are comprised of sites, where a site is defined as a specific geographic location of federally owned or managed land and is assigned to military installation. DoD installations are commonly referred to as a base, camp, post, station, yard, center, homeport facility for any ship, or other activity under the jurisdiction, custody, control of the DoD.
14	NCDB	23	National Coastal Structures Database	2024-08-07 21:17:27	4269	2	1	preloaded	d:\\bah\\NCDB\\National_Coastal_Structures_Database.json	https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer		<div style='text-align:Left;font-size:12pt'><p><span>This map provides the locations of USACE coastal structures.</span></p></div>	<DIV STYLE="text-align:Left;font-size:12pt"><P><SPAN>This map provides the locations of USACE coastal structures.</SPAN></P></DIV>
15	NCF	11	National Channel Framework	2024-08-07 21:17:27	4326	4	0	preloaded	d:\\bah\\NCF\\National_Channel_Framework.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer	9227967a2748410983352b501c0c7b39	This service shows all navigation channels maintained by USACE districts that have completed all or portions of the National Channel Framework through eHydro.	The National Channel Framework (NCF) is an enterprise Geographic Information System (eGIS) database providing information about congressionally authorized navigation channels maintained by the US Army Corps of Engineers. This service includes channel details based on district-managed GIS polygons rather than on CAD-based linework, and is maintained through the eHydro hydrographic survey application. Details include reaches, channel areas, quarters, centerlines, and stationing.
16	NDC	10	Navigation and Civil Works Decision Support	2024-08-07 21:17:27	102100	1	0	preloaded	d:\\bah\\NDC\\Navigation_and_Civil_Works_Decision_Support.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/pports21/FeatureServer	8eb8a75c67e84c22af7acf4268692052		
17	NDC	10	Navigation and Civil Works Decision Support	2024-08-07 21:17:27	102100	1	0	preloaded	d:\\bah\\NDC\\Navigation_and_Civil_Works_Decision_Support.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Docks/FeatureServer	ebb41cfef47a484d86c17a38f4202d19		
18	NDC	10	Navigation and Civil Works Decision Support	2024-08-07 21:17:27		0	0	preloaded	d:\\bah\\NDC\\Navigation_and_Civil_Works_Decision_Support.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/linktons/FeatureServer			
19	NDC	10	Navigation and Civil Works Decision Support	2024-08-07 21:17:27	4326	7	0	preloaded	d:\\bah\\NDC\\Navigation_and_Civil_Works_Decision_Support.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer	349ce90ebfcd47f49401ac4d817b0d58	Layers from the Navigation Data Center	Link Tonnages, Docks, Principle Ports, River Miles, Waterway Network, Waterway Network Nodes, COE Dredge Locations, Dredge Locations.
20	NID	12	National Inventory of Dams	2024-08-07 21:17:27	4326	1	0	preloaded	d:\\bah\\NID\\National_Inventory_of_Dams.json	https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NID_v1/FeatureServer	a4c195b7a6b74f278ff43e5d60c6915d		
21	NLD	21	National Levee Database	2024-08-07 21:17:27	4269	18	0	preloaded	d:\\bah\\NLD\\National_Levee_Database.json	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer	6719c439172b4148b95181c349adebed		
22	NSMF	13	National Sediment Managment Framework 	2024-08-07 21:17:27	4326	2	0	preloaded	d:\\bah\\NSMF\\National_Sediment_Managment_Framework.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer	c0ccbc612e27433c86eaf63b3986a776	Data in this service are intended to serve the dredging and sediment management communities and their stakeholders. The main features are placement and borrow areas managed by USACE.  Each district maintains their respective areas for use in the national program to consolidate and serve out to the public.	<DIV STYLE="text-align:Left;font-size:12pt"><P><SPAN>The Placement and Borrow Area features are stored within the single feature class called placementArea. For purposes of symbolizing separately a definition query is defined on the placementType field.  These areas depict locations managed and maintained by each USACE districts.</SPAN></P></DIV>
23	PORT	35	Port Statistical Areas	2024-08-07 21:17:27	4269	1	0	preloaded	d:\\bah\\PORT\\Port_Statistical_Areas.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Port_Statistical_Area/FeatureServer	b7fd6cec8d8c43e4a141d24170e6d82f	Per Engineering Regulation 1130-2-520, the U.S. Army Corps of Engineers' Navigation Data Center is responsible to collect, compile, publish, and disseminate waterborne commerce statistics.  This task has subsequently been charged to the Waterborne Commerce Statistics Center to perform.  Performance of this work is in accordance with the Rivers and Harbors Appropriation Act of 1922.  Included in this work is the definition of a port area.  A port area is defined in Engineering Pamphlet 1130-2-520  as:\n\n(1) Port limits defined by legislative enactments of state, county, or city governments.\n(2) The corporate limits of a municipality. \n\nThe primary objective of the statistical port boundary project is to utilize a GIS to prepare a USACE enterprise-wide statistical port boundary polygon feature class per EP 1130-2-520 and organized in SDSFIE 4.0.2 format. 	<p><span style='font-size:12.0pt;'>Per\nEngineering Regulation 1130-2-520, USACE’s NDC and WCSC are responsible for\ncollecting, compiling, printing, and distributing all domestic waterborne\ncommerce statistics for which the USACE has responsibility.<span>  </span>Per a 1998 Office of Management and Budget\n(OMB) memorandum, the WCSC inherited the requirement to include foreign\nwaterborne commerce formally executed by the U.S. Census Bureau.<span>  </span>Performance of this work is in accordance\nwith the Rivers and Harbors Appropriation Act of 1922 (33 USC 555).</span></p>\n\n<p><span style='font-size:12pt;'>Engineering\nRegulation 1130-2-520 defines a port as:</span></p>\n\n<p style='margin-left:.5in; text-indent:-.25in;'><span style='font-size:12.0pt;'><span>(1)<span style='font:7.0pt &quot;Times New Roman&quot;;'>   </span></span></span><span style='font-size:12.0pt;'>Port limits defined by\nlegislative enactments of state, county, or city governments.</span></p>\n\n<p style='margin-left:.5in; text-indent:-.25in;'><span style='font-size:12.0pt;'><span>(2)<span style='font:7.0pt &quot;Times New Roman&quot;;'>  </span></span></span><span style='font-size:12.0pt;'>The corporate limits of a\nmunicipality. </span></p>\n\n<p><span style='font-size:12pt;'>At minimum, the feature class includes the following attribution:</span><span style='font-size:12pt;'> </span></p><table border='1' cellpadding='0' cellspacing='0' style='border-collapse:collapse; border:none;'><tbody><tr>\n   <td style='width:119.7pt; border:solid windowtext 1.0pt; background:black; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n   <p style='text-align:center;'><span style='font-size:12.0pt;'><font color='#ffffff'>Attribute Name</font></span></p>\n   </td>\n   <td style='width:250.2pt; border:solid windowtext 1.0pt; border-left:none; background:black; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n   <p style='text-align:center;'><span style='font-size:12.0pt; color:white;'>Definition</span></p>\n   </td>\n   <td style='width:63.0pt; border:solid windowtext 1.0pt; border-left:none; background:black; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n   <p style='text-align:center;'><span style='font-size:12.0pt; color:white;'>Data Type</span></p>\n   </td>\n   <td style='width:45.9pt; border:solid windowtext 1.0pt; border-left:none; background:black; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n   <p style='text-align:center;'><span style='font-size:12.0pt; color:white;'>Length</span></p>\n   </td>\n  </tr></tbody><tbody><tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>featureDescription</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>The\n  narrative describing the feature.<span>  </span>This\n  attribute column will describe how the statistical port boundary was\n  generated using GIS.<span>  </span>It can include\n  the legislative description, a note that the U.S. Census Bureau municipal limit\n  was used, or other details.</span></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>String</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>Max</span></p>\n  </td>\n </tr>\n <tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>featureName</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>The\n  common name of the feature.<span>  </span>This will\n  be the port name as defined by the legislative enactment or the municipality.<span>  </span>Each name should include which State(s) the\n  port is located (ex. Louisville-Jefferson County Riverport Authority, KY).</span></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>String</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>80</span></p>\n  </td>\n </tr>\n <tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>installationId</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>The\n  codes assigned by the DoD Component used to identify the site or group of\n  sites that make up an installation. This field will remain empty, as the\n  project focus is not on military installations.</span></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>String</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>11</span></p>\n  </td>\n </tr>\n <tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>mediaId</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>Used\n  to link the record to associated multimedia records the reference data.<span>  </span>The number used in this column will reference\n  a related “mediaId” table that will store the source document for appropriate\n  legislation or municipality limit reference.</span></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>String</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>40</span></p>\n  </td>\n </tr>\n <tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>metadataId</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>Used\n  to represent or link to feature level metadata.<span>  </span>For this project, a common code for the\n  port area geometry source will be employed.</span></p>\n  <div align='center'>\n  <table border='1' cellpadding='0' cellspacing='0' style='border-collapse:collapse; border:none;'>\n   <tbody><tr>\n    <td style='width:37.55pt; border:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='50'>\n    <p style='text-align:center;'><span style='font-size:12.0pt;'>L</span></p>\n    </td>\n    <td style='width:1.75in; border:solid windowtext 1.0pt; border-left:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='168'>\n    <p><span style='font-size:12.0pt;'>Legislative\n    Enactment</span></p>\n    </td>\n   </tr>\n   <tr>\n    <td style='width:37.55pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='50'>\n    <p style='text-align:center;'><span style='font-size:12.0pt;'>M</span></p>\n    </td>\n    <td style='width:1.75in; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='168'>\n    <p><span style='font-size:12.0pt;'>Municipal\n    Limits</span></p>\n    </td>\n   </tr>\n   <tr>\n    <td style='width:37.55pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='50'>\n    <p style='text-align:center;'><span style='font-size:12.0pt;'>O</span></p>\n    </td>\n    <td style='width:1.75in; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='168'>\n    <p><span style='font-size:12.0pt;'>Other</span></p>\n    </td>\n   </tr>\n  </tbody></table>\n  </div>\n  <p><br /></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>String</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>80</span></p>\n  </td>\n </tr>\n <tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>portIdpk</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>Primary\n  Key.<span>  </span>A unique, user defined identifier\n  for each record or instance of an entity.<span> \n  </span>This will be the existing four-digit port code maintained by WCSC in\n  TOWS.<span>  </span>A crosswalk table will also be\n  created by the PM that correlates legacy TOWS port codes to new UN LOCODE\n  information.</span></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>String</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>40</span></p>\n  </td>\n </tr>\n <tr>\n  <td style='width:119.7pt; border:solid windowtext 1.0pt; border-top:none; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='160'>\n  <p><span style='font-size:12.0pt;'>sdsId</span></p>\n  </td>\n  <td style='width:250.2pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='334'>\n  <p><span style='font-size:12.0pt;'>The\n  unique identifier for all entities in the SDSFIE.<span>  </span>This field will remain empty and will be\n  populated by HQUSACE if sdsID identifiers become necessary to report.</span></p>\n  </td>\n  <td style='width:63.0pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='84'>\n  <p style='text-align:center;'><span style='font-size:12.0pt;'>GUID</span></p>\n  </td>\n  <td style='width:45.9pt; border-top:none; border-left:none; border-bottom:solid windowtext 1.0pt; border-right:solid windowtext 1.0pt; padding:0in 5.4pt 0in 5.4pt;' valign='top' width='61'>\n  <p style='text-align:center;'><br /></p>\n  </td>\n </tr>\n</tbody></table>
24	RECREATION	15	Recreation	2024-08-07 21:17:27		1	0	preloaded	d:\\bah\\RECREATION\\Recreation.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_recreation_areas/FeatureServer	e314790ee1bb4eec982f0b669accb6fc	USACE Recreation Areas	Land associated with Corps reservoirs used for recreational purposes. This data is subject to change in the future.
25	REMIS	16	Real Estate Management Geospatial	2024-08-07 21:17:27	4269	6	0	preloaded	d:\\bah\\REMIS\\Real_Estate_Management_Geospatial.json	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer	3664b038bdf741a1af3c07ce6d32eb26		
26	RESERVOIR	17	USACE Reservoirs	2024-08-07 21:17:27	4326	1	0	preloaded	d:\\bah\\RESERVOIR\\USACE_Reservoirs.json	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_rez/FeatureServer	03e322d7e89b48a9b48e9c3f4bcaf29e	Boundary data for Corps owned and operated reservoirs.\n	This dataset shows maximum conservation pool or is a reasonable representation of the boundaries for reservoirs and lakes owned and operated by USACE. Data is from USACE Districts.
27	USMART	20	USACE Survey Monument Archives	2024-08-07 21:17:27	4326	2	0	preloaded	d:\\bah\\USMART\\USACE_Survey_Monument_Archives.json	https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer	038ec9a310bc43d6bd11aed28e9b8de5		
\.


--
-- TOC entry 7531 (class 0 OID 426897)
-- Dependencies: 557
-- Data for Name: load_profile; Type: TABLE DATA; Schema: catalog; Owner: catalog
--

COPY catalog.load_profile (ogc_fid, field_1, acronym, collection_name, entity_name, entity_name_revised, record_count, entity_type, filters, srid, url) FROM stdin;
1	0	CSPI	Coastal Systems Portfolio Initiative	CSPI_PROJECT_ROLLUP	cspi_project_rollup	1098	Point	Coastal	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/0
2	1	CSPI	Coastal Systems Portfolio Initiative	CSPI_NAV_OVERVIEW	cspi_nav_overview	632	Point	Coastal	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/3
3	2	CSPI	Coastal Systems Portfolio Initiative	CSPI_CSRM_AER_OVERVIEW	cspi_csrm_aer_overview	464	Point	Coastal	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/5
4	3	CSPI	Coastal Systems Portfolio Initiative	CSPI_DAMAGERISK	cspi_damagerisk	1097	Point	Coastal	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/1
5	4	CSPI	Coastal Systems Portfolio Initiative	CSPI_RENOURISHMENTS	cspi_renourishments	720	Point	Coastal	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/6
6	5	CSPI	Coastal Systems Portfolio Initiative	CSPI_PROJECT_EXTENTS	cspi_project_extents	773	Polyline	Coastal	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/2
7	6	CSPI	Coastal Systems Portfolio Initiative	CSPI_DREDGINGWINDOWS	cspi_dredgingwindows	756	Table	Dredging,Coastal		https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/7
8	7	CSPI	Coastal Systems Portfolio Initiative	CSPI_INITIALCONSTRUCTION	cspi_initialconstruction	293	Table	Coastal		https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/10
9	8	CSPI	Coastal Systems Portfolio Initiative	CSPI_RELIABILITY_HISTORY	cspi_reliability_history	4033	Table	Coastal		https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/9
10	9	CSPI	Coastal Systems Portfolio Initiative	CSPI_REPORTS	cspi_reports	659	Table	Commerce,Coastal,Real Estate		https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/8
11	10	CSPI	Coastal Systems Portfolio Initiative	CSPI_CSRM_AER_DATACHECK	cspi_csrm_aer_datacheck	519	Table	Coastal		https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer/15
12	11	DIS	Dredging Information System	DIS_Placements	dis_placements	18912	Point		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer/0
13	12	DIS	Dredging Information System	DIS_Output	dis_output	18912	Table			https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/DIS_Placement_Locations/FeatureServer/3
14	13	FUDS	Formerly Used Defense Sites	FUDS Property Point	fuds_property_point	10123	Point	Real Estate	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/1
15	14	FUDS	Formerly Used Defense Sites	FUDS Project Point	fuds_project_point	5433	Point		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/2
16	15	FUDS	Formerly Used Defense Sites	FUDS Munitions Response Site	fuds_munitions_response_site	1652	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/3
17	16	FUDS	Formerly Used Defense Sites	FUDS Property Polygon	fuds_property_polygon	3009	Polygon	Real Estate	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/4
18	17	FUDS	Formerly Used Defense Sites	IRM Property Point	irm_property_point	598	Point	Real Estate	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/6
19	18	FUDS	Formerly Used Defense Sites	IRM Project Boundary	irm_project_boundary	798	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/7
20	19	FUDS	Formerly Used Defense Sites	IRM Property Boundary	irm_property_boundary	598	Polygon	Real Estate	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/8
21	20	FUDS	Formerly Used Defense Sites	FUDS Program District Boundaries	fuds_program_district_boundaries	13	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/9
22	21	FUDS	Formerly Used Defense Sites	FUDS Program Division Boundaries	fuds_program_division_boundaries	7	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/fuds/FeatureServer/10
23	22	IB	Ice Jam Database	Current Ice Jams	current_ice_jams	66	Point		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Current_Ice_Jams/FeatureServer/0
24	23	IB	Ice Jam Database	Ice_Jams_Historic	ice_jams_historic	9976	Point		0	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/Ice_Jams_Historic/FeatureServer/0
25	24	IENC	Inland Electronic Navigational Charts	SENSOR_POINT	sensor_point	19	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/0
26	25	IENC	Inland Electronic Navigational Charts	TERMINAL_POINT	terminal_point	13	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/1
27	26	IENC	Inland Electronic Navigational Charts	ISOLATED_DANGER_BUOY_POINT	isolated_danger_buoy_point	1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/2
28	27	IENC	Inland Electronic Navigational Charts	BUILT_UP_AREA_POINT	built_up_area_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/3
29	28	IENC	Inland Electronic Navigational Charts	AIRPORT_AREA_POINT	airport_area_point	4	Point	Commerce,Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/4
30	29	IENC	Inland Electronic Navigational Charts	BUILDING_SINGLE_POINT	building_single_point	892	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/5
31	30	IENC	Inland Electronic Navigational Charts	BUOY_SPECIAL_PURPOSE_POINT	buoy_special_purpose_point	105	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/6
32	31	IENC	Inland Electronic Navigational Charts	CAUTION_AREA_POINT	caution_area_point	41	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/7
33	32	IENC	Inland Electronic Navigational Charts	CRANES_POINT	cranes_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/8
34	33	IENC	Inland Electronic Navigational Charts	DAYMARK_POINT	daymark_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/9
35	34	IENC	Inland Electronic Navigational Charts	DISTANCE_MARK_POINT	distance_mark_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/10
36	35	IENC	Inland Electronic Navigational Charts	HARBOUR_FACILITY_POINT	harbour_facility_point	-1	Point	WaterBodies,Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/11
37	36	IENC	Inland Electronic Navigational Charts	LAND_REGION_POINT	land_region_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/12
38	37	IENC	Inland Electronic Navigational Charts	LANDMARK_POINT	landmark_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/13
39	38	IENC	Inland Electronic Navigational Charts	LATERAL_BEACON_POINT	lateral_beacon_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/14
40	39	IENC	Inland Electronic Navigational Charts	LATERAL_BUOY_POINT	lateral_buoy_point	10	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/15
41	40	IENC	Inland Electronic Navigational Charts	LIGHTS_POINT	lights_point	8919	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/16
42	41	IENC	Inland Electronic Navigational Charts	MOORING_FACILITY_POINT	mooring_facility_point	9744	Point	Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/17
43	42	IENC	Inland Electronic Navigational Charts	NOTICE_MARK_POINT	notice_mark_point	266	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/18
44	43	IENC	Inland Electronic Navigational Charts	OBSTRUCTION_POINT	obstruction_point	160	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/19
45	44	IENC	Inland Electronic Navigational Charts	PILE_POINT	pile_point	3012	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/20
46	45	IENC	Inland Electronic Navigational Charts	PYLONS_POINT	pylons_point	4069	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/21
47	46	IENC	Inland Electronic Navigational Charts	SEA_AREA_POINT	sea_area_point	1942	Point	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/22
48	47	IENC	Inland Electronic Navigational Charts	SHORELINE_CONSTRUCTION_POINT	shoreline_construction_point	4720	Point	WaterBodies,Coastal	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/23
49	48	IENC	Inland Electronic Navigational Charts	SMALL_CRAFT_FACILITY_POINT	small_craft_facility_point	155	Point	Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/24
50	49	IENC	Inland Electronic Navigational Charts	STORAGE_TANK_SILO_POINT	storage_tank_silo_point	1078	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/25
51	50	IENC	Inland Electronic Navigational Charts	SUBMARINE_PIPELINE_POINT	submarine_pipeline_point	902	Point	PipeLines	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/26
52	51	IENC	Inland Electronic Navigational Charts	TRAFFIC_SIGNAL_STATION_POINT	traffic_signal_station_point	298	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/27
53	52	IENC	Inland Electronic Navigational Charts	UNDERWATER_ROCK_POINT	underwater_rock_point	114	Point	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/28
54	53	IENC	Inland Electronic Navigational Charts	WATERWAY_GAUGE_POINT	waterway_gauge_point	753	Point	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/29
55	54	IENC	Inland Electronic Navigational Charts	WARNING_SIGNAL_STATION_POINT	warning_signal_station_point	508	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/30
56	55	IENC	Inland Electronic Navigational Charts	WRECKS_POINT	wrecks_point	-1	Point		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/31
57	56	IENC	Inland Electronic Navigational Charts	CANALS_LINE	canals_line	1	Polyline	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/32
58	57	IENC	Inland Electronic Navigational Charts	COASTLINE_LINE	coastline_line	22720	Polyline	WaterBodies,Coastal	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/33
59	58	IENC	Inland Electronic Navigational Charts	CONVEYOR_LINE	conveyor_line	881	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/34
60	59	IENC	Inland Electronic Navigational Charts	DAM_LINE	dam_line	40	Polyline	Structures,Dams	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/35
61	60	IENC	Inland Electronic Navigational Charts	DEPTH_CONTOUR_LINE	depth_contour_line	13384	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/36
62	61	IENC	Inland Electronic Navigational Charts	FERRY_ROUTE_LINE	ferry_route_line	30	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/37
63	62	IENC	Inland Electronic Navigational Charts	FLOODWALL_LINE	floodwall_line	-1	Polyline	Flood	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/38
64	63	IENC	Inland Electronic Navigational Charts	LEVEE_LINE	levee_line	-1	Polyline	Dams,Flood	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/39
65	64	IENC	Inland Electronic Navigational Charts	LOCK_GATE_LINE	lock_gate_line	-1	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/40
66	65	IENC	Inland Electronic Navigational Charts	MOORING_FACILITY_LINE	mooring_facility_line	1	Polyline	Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/41
67	66	IENC	Inland Electronic Navigational Charts	OBSTRUCTION_LINE	obstruction_line	16	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/42
68	67	IENC	Inland Electronic Navigational Charts	OVERHEAD_CABLE_LINE	overhead_cable_line	1629	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/43
69	68	IENC	Inland Electronic Navigational Charts	OVERHEAD_PIPELINE_LINE	overhead_pipeline_line	92	Polyline	PipeLines	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/44
70	69	IENC	Inland Electronic Navigational Charts	RAILROAD_LINE	railroad_line	10576	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/45
71	70	IENC	Inland Electronic Navigational Charts	RECOMMENDED_TRACK_LINE	recommended_track_line	566	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/46
72	71	IENC	Inland Electronic Navigational Charts	RIVERS_LINE	rivers_line	5735	Polyline	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/47
73	72	IENC	Inland Electronic Navigational Charts	ROADWAY_LINE	roadway_line	93021	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/48
74	73	IENC	Inland Electronic Navigational Charts	SHORELINE_CONSTRUCTION_LINE	shoreline_construction_line	28801	Polyline	WaterBodies,Coastal	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/49
75	74	IENC	Inland Electronic Navigational Charts	SLOPE_TOPLINE_LINE	slope_topline_line	233	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/50
76	75	IENC	Inland Electronic Navigational Charts	SUBMARINE_CABLE_LINE	submarine_cable_line	227	Polyline		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/51
77	76	IENC	Inland Electronic Navigational Charts	SUBMARINE_PIPELINE_LINE	submarine_pipeline_line	1418	Polyline	PipeLines	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/52
78	77	IENC	Inland Electronic Navigational Charts	UNDERWATER_ROCK_AREA	underwater_rock_area	-1	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/53
79	78	IENC	Inland Electronic Navigational Charts	WRECKS_AREA	wrecks_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/54
80	79	IENC	Inland Electronic Navigational Charts	SMALL_CRAFT_FACILITY_AREA	small_craft_facility_area	-1	Polygon	Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/55
81	80	IENC	Inland Electronic Navigational Charts	ADMINISTRATIVE_AREA	administrative_area	3131	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/56
82	81	IENC	Inland Electronic Navigational Charts	AIRPORT_AREA	airport_area	72	Polygon	Commerce,Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/57
83	82	IENC	Inland Electronic Navigational Charts	BUILDING_SINGLE_AREA	building_single_area	119201	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/58
84	83	IENC	Inland Electronic Navigational Charts	CABLE_AREA	cable_area	32	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/59
85	84	IENC	Inland Electronic Navigational Charts	CONVEYOR_AREA	conveyor_area	263	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/60
86	85	IENC	Inland Electronic Navigational Charts	CRANES_AREA	cranes_area	37	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/61
87	86	IENC	Inland Electronic Navigational Charts	DAM_AREA	dam_area	173	Polygon	Structures,Dams	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/62
88	87	IENC	Inland Electronic Navigational Charts	DATA_COVERAGE_AREA	data_coverage_area	317	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/63
89	88	IENC	Inland Electronic Navigational Charts	DATA_QUALITY_AREA	data_quality_area	109	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/64
90	89	IENC	Inland Electronic Navigational Charts	DRY_DOCK_AREA	dry_dock_area	2	Polygon	Docks	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/65
91	90	IENC	Inland Electronic Navigational Charts	LAND_REGION_AREA	land_region_area	118	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/66
92	91	IENC	Inland Electronic Navigational Charts	NAUTICAL_PUBLICATION_INFORMATION_AREA	nautical_publication_information_area	109	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/67
93	92	IENC	Inland Electronic Navigational Charts	NAVIGATIONAL_SYSTEM_OF_MARKS_AREA	navigational_system_of_marks_area	109	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/68
94	93	IENC	Inland Electronic Navigational Charts	PYLONS_AREA	pylons_area	6401	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/69
95	94	IENC	Inland Electronic Navigational Charts	SEA_AREA	sea_area	222	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/70
96	95	IENC	Inland Electronic Navigational Charts	SLOPING_GROUND_AREA	sloping_ground_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/71
97	96	IENC	Inland Electronic Navigational Charts	STORAGE_TANK_SILO_AREA	storage_tank_silo_area	3602	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/72
98	97	IENC	Inland Electronic Navigational Charts	PONTOON_AREA	pontoon_area	515	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/73
99	98	IENC	Inland Electronic Navigational Charts	CANALS_AREA	canals_area	3	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/74
100	99	IENC	Inland Electronic Navigational Charts	RIVERS_AREA	rivers_area	3655	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/75
101	100	IENC	Inland Electronic Navigational Charts	LAKE_AREA	lake_area	4923	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/76
102	101	IENC	Inland Electronic Navigational Charts	LOCK_BASIN_AREA	lock_basin_area	173	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/77
103	102	IENC	Inland Electronic Navigational Charts	LOCK_GATE_AREA	lock_gate_area	94	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/78
104	103	IENC	Inland Electronic Navigational Charts	MOORING_FACILITY_AREA	mooring_facility_area	-1	Polygon	Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/79
105	104	IENC	Inland Electronic Navigational Charts	TERMINAL_AREA	terminal_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/80
106	105	IENC	Inland Electronic Navigational Charts	OBSTRUCTION_AREA	obstruction_area	366	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/81
107	106	IENC	Inland Electronic Navigational Charts	PIPE_AREA	pipe_area	114	Polygon	PipeLines	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/82
108	107	IENC	Inland Electronic Navigational Charts	RESTRICTED_AREA	restricted_area	1233	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/83
109	108	IENC	Inland Electronic Navigational Charts	ANCHOR_BERTH_AREA	anchor_berth_area	1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/84
110	109	IENC	Inland Electronic Navigational Charts	BERTHS_AREA	berths_area	1092	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/85
111	110	IENC	Inland Electronic Navigational Charts	CAUTION_AREA	caution_area	2912	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/86
112	111	IENC	Inland Electronic Navigational Charts	FLOATING_DOCK_AREA	floating_dock_area	48	Polygon	Docks	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/87
113	112	IENC	Inland Electronic Navigational Charts	HARBOUR_AREA	harbour_area	1	Polygon	WaterBodies	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/88
114	113	IENC	Inland Electronic Navigational Charts	HULKES_AREA	hulkes_area	44	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/89
115	114	IENC	Inland Electronic Navigational Charts	HARBOUR_FACILITY_AREA	harbour_facility_area	94	Polygon	WaterBodies,Real Estate	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/90
116	115	IENC	Inland Electronic Navigational Charts	LANDMARK_AREA	landmark_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/91
117	116	IENC	Inland Electronic Navigational Charts	LEVEE_AREA	levee_area	321	Polygon	Dams,Flood	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/92
118	117	IENC	Inland Electronic Navigational Charts	BRIDGE_AREA	bridge_area	3761	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/93
119	118	IENC	Inland Electronic Navigational Charts	SHORELINE_CONSTRUCTION_AREA	shoreline_construction_area	7821	Polygon	WaterBodies,Coastal	4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/94
120	119	IENC	Inland Electronic Navigational Charts	BUILT_UP_AREA	built_up_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/95
121	120	IENC	Inland Electronic Navigational Charts	DUMPING_GROUND_AREA	dumping_ground_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/96
122	121	IENC	Inland Electronic Navigational Charts	DEPTH_AREA	depth_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/97
123	122	IENC	Inland Electronic Navigational Charts	LAND_AREA	land_area	-1	Polygon		4326	https://ienccloud.us/arcgis/rest/services/IENC/USACE_IENC_Master_Service/MapServer/98
124	123	NCF	National Channel Framework	ChannelLine	channelline	36153	Polyline	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer/0
125	124	NCF	National Channel Framework	ChannelArea	channelarea	2662	Polygon	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer/1
126	125	NCF	National Channel Framework	ChannelReach	channelreach	12836	Polygon	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer/2
127	126	NCF	National Channel Framework	ChannelQuarter	channelquarter	24408	Polygon	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Channel_Framework/FeatureServer/3
128	127	NCDB	National Coastal Structures Database	USACE Structure Point	usace_structure_point	-1	Point	Structures	4326	https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer/0
129	128	NCDB	National Coastal Structures Database	USACE Structure Polygon	usace_structure_polygon	1078	Polygon	Structures	4326	https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer/1
130	129	NCDB	National Coastal Structures Database	Structure_Vessel_Data	structure_vessel_data	66812	Table	Structures		https://arcgis.usacegis.com/arcgis/rest/services/Development/USACE_Structures/FeatureServer/2
131	130	NID	National Inventory of Dams	Dams	dams	91834	Point	Structures,Dams	4269	https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/NID_v1/FeatureServer/0
132	131	NLD	National Levee Database	Boreholes	boreholes	47973	Point		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/0
133	132	NLD	National Levee Database	Crossings	crossings	111235	Point		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/1
134	133	NLD	National Levee Database	Levee Stations	levee_stations	441517	Point	Dams,Flood	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/2
135	134	NLD	National Levee Database	Piezometers	piezometers	2431	Point		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/3
136	135	NLD	National Levee Database	Pump Stations	pump_stations	2088	Point		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/4
137	136	NLD	National Levee Database	Relief Wells	relief_wells	10699	Point		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/5
138	137	NLD	National Levee Database	Alignment Lines	alignment_lines	31332	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/6
139	138	NLD	National Levee Database	Closure Structures	closure_structures	3623	Polyline	Structures	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/7
140	139	NLD	National Levee Database	Cross Sections	cross_sections	283732	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/8
141	140	NLD	National Levee Database	Embankments	embankments	25737	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/9
142	141	NLD	National Levee Database	Floodwalls	floodwalls	14704	Polyline	Flood	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/10
143	142	NLD	National Levee Database	FRM Lines	frm_lines	52	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/11
144	143	NLD	National Levee Database	Pipe Gates	pipe_gates	9512	Point	PipeLines	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/12
145	144	NLD	National Levee Database	Toe Drains	toe_drains	1192	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/13
146	145	NLD	National Levee Database	Leveed Areas	leveed_areas	6755	Polygon	Dams,Flood	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/14
147	146	NLD	National Levee Database	System Routes	system_routes	6712	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/15
148	147	NLD	National Levee Database	Pipes	pipes	17431	Polyline	PipeLines	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/16
149	148	NLD	National Levee Database	Channels	channels	116	Polyline	WaterBodies	4269	https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/17
150	149	NSMF	National Sediment Managment Framework 	BorrowArea	borrowarea	131	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer/0
151	150	NSMF	National Sediment Managment Framework 	PlacementArea	placementarea	2746	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/National_Sediment_Management_Framework/FeatureServer/1
152	151	NDC	Navigation and Civil Works Decision Support	pports21	pports21	150	Point	Commerce,Real Estate	0	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/pports21/FeatureServer/0
153	152	NDC	Navigation and Civil Works Decision Support	Waterway Mile Marker	waterway_mile_marker	11406	Point	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/0
154	153	NDC	Navigation and Civil Works Decision Support	Principal Port	principal_port	150	Point	Commerce,Real Estate	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/1
155	154	NDC	Navigation and Civil Works Decision Support	Dock	dock	24024	Point	Docks	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/2
156	155	NDC	Navigation and Civil Works Decision Support	Lock	lock	234	Point		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/3
157	156	NDC	Navigation and Civil Works Decision Support	Waterway Network Node	waterway_network_node	6255	Point	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/6
158	157	NDC	Navigation and Civil Works Decision Support	Waterway Network	waterway_network	6859	Polyline	WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/7
159	158	NDC	Navigation and Civil Works Decision Support	Link tonnages (historic)	link_tonnages_(historic)	2901	Polyline		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/ndc/FeatureServer/8
160	159	NDC	Navigation and Civil Works Decision Support	DOCK	dock	23719	Point	Docks	0	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/Docks/FeatureServer/0
161	160	REMIS	Real Estate Management Geospatial	Disposal Line	disposal_line	8	Polyline		4269	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer/0
162	161	REMIS	Real Estate Management Geospatial	Land Parcel Line	land_parcel_line	53	Polyline	Real Estate	4269	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer/1
163	162	REMIS	Real Estate Management Geospatial	Outgrant Area	outgrant_area	503	Polygon		4269	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer/2
164	163	REMIS	Real Estate Management Geospatial	Disposal Area	disposal_area	18155	Polygon		4269	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer/3
165	164	REMIS	Real Estate Management Geospatial	Land Parcel Area	land_parcel_area	254332	Polygon	Real Estate	4269	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer/4
166	165	REMIS	Real Estate Management Geospatial	Site	site	1603	Polygon		4269	https://geospatial.sec.usace.army.mil/server/rest/services/REMIS/cwldm/FeatureServer/5
167	166	RECREATION	Recreation	Recreation Area	recreation_area	3659	Polygon		0	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_recreation_areas/FeatureServer/0
168	167	BOUNDARIES	USACE Civil Works and Military Boundaries	USACE_Districts	usace_districts	38	Polygon		4269	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer/0
169	168	BOUNDARIES	USACE Civil Works and Military Boundaries	USACE Divisions	usace_divisions	8	Polygon		4269	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_cw_divisions/FeatureServer/0
170	169	BOUNDARIES	USACE Civil Works and Military Boundaries	USACE Military Districts	usace_military_districts	24	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_dist/FeatureServer/0
171	170	BOUNDARIES	USACE Civil Works and Military Boundaries	USACE Military Divisions	usace_military_divisions	8	Polygon		4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/usace_mil_div/FeatureServer/0
172	171	RESERVOIR	USACE Reservoirs	USACE Reservoirs	usace_reservoirs	418	Polygon	Dams,WaterBodies	4326	https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_rez/FeatureServer/0
173	172	USMART	USACE Survey Monument Archives	Primary Control Points	primary_control_points	7034	Point		4326	https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer/0
174	173	USMART	USACE Survey Monument Archives	Local Control Points	local_control_points	192221	Point		4326	https://geospatial.sec.usace.army.mil/server/rest/services/USMART/USMART/FeatureServer/1
\.


--
-- TOC entry 7543 (class 0 OID 0)
-- Dependencies: 479
-- Name: artifact_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.artifact_id_seq', 132, true);


--
-- TOC entry 7544 (class 0 OID 0)
-- Dependencies: 872
-- Name: data_collection_collection_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_collection_collection_id_seq', 35, true);


--
-- TOC entry 7545 (class 0 OID 0)
-- Dependencies: 481
-- Name: data_collection_filter_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_collection_filter_id_seq', 1, false);


--
-- TOC entry 7546 (class 0 OID 0)
-- Dependencies: 482
-- Name: data_product_item_id_sequence; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_product_item_id_sequence', 21, true);


--
-- TOC entry 7547 (class 0 OID 0)
-- Dependencies: 484
-- Name: data_products_product_id_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.data_products_product_id_seq', 76, true);


--
-- TOC entry 7548 (class 0 OID 0)
-- Dependencies: 876
-- Name: load_collection_ogc_fid_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.load_collection_ogc_fid_seq', 27, true);


--
-- TOC entry 7549 (class 0 OID 0)
-- Dependencies: 556
-- Name: load_profile_ogc_fid_seq; Type: SEQUENCE SET; Schema: catalog; Owner: catalog
--

SELECT pg_catalog.setval('catalog.load_profile_ogc_fid_seq', 174, true);


--
-- TOC entry 7367 (class 2606 OID 681965)
-- Name: data_collection data_collection_pkey; Type: CONSTRAINT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.data_collection
    ADD CONSTRAINT data_collection_pkey PRIMARY KEY (collection_id);


--
-- TOC entry 7369 (class 2606 OID 682052)
-- Name: load_collection load_collection_pkey; Type: CONSTRAINT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.load_collection
    ADD CONSTRAINT load_collection_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 7365 (class 2606 OID 426904)
-- Name: load_profile load_profile_pkey; Type: CONSTRAINT; Schema: catalog; Owner: catalog
--

ALTER TABLE ONLY catalog.load_profile
    ADD CONSTRAINT load_profile_pkey PRIMARY KEY (ogc_fid);


-- Completed on 2024-08-07 21:22:46

--
-- PostgreSQL database dump complete
--

