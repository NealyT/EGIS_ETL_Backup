--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 16.3

-- Started on 2024-08-16 21:11:22

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
-- TOC entry 143 (class 2615 OID 685168)
-- Name: bronze_staging; Type: SCHEMA; Schema: -; Owner: bronze_staging
--

CREATE SCHEMA bronze_staging;


ALTER SCHEMA bronze_staging OWNER TO bronze_staging;

--
-- TOC entry 845 (class 1259 OID 688298)
-- Name: load_id_seq; Type: SEQUENCE; Schema: bronze_staging; Owner: bronze_staging
--

CREATE SEQUENCE bronze_staging.load_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bronze_staging.load_id_seq OWNER TO bronze_staging;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 870 (class 1259 OID 694251)
-- Name: load_history; Type: TABLE; Schema: bronze_staging; Owner: bronze_staging
--

CREATE TABLE bronze_staging.load_history (
    load_id bigint DEFAULT nextval('bronze_staging.load_id_seq'::regclass) NOT NULL,
    data_product_id bigint NOT NULL,
    source_id bigint NOT NULL,
    source_path text NOT NULL,
    load_datetime timestamp without time zone NOT NULL,
    load_status text,
    source_description text,
    source_capabilities text,
    srid text
);


ALTER TABLE bronze_staging.load_history OWNER TO bronze_staging;

--
-- TOC entry 871 (class 1259 OID 694264)
-- Name: load_history_item; Type: TABLE; Schema: bronze_staging; Owner: bronze_staging
--

CREATE TABLE bronze_staging.load_history_item (
    load_id bigint NOT NULL,
    data_product_id bigint NOT NULL,
    source_id bigint NOT NULL,
    item_id bigint NOT NULL,
    original_name text,
    revised_name text,
    load_status text,
    item_path text,
    srid text,
    last_seq integer,
    original_col_names text[],
    revised_col_names text[],
    original_col_types text[],
    revised_col_types text[],
    configs json
);


ALTER TABLE bronze_staging.load_history_item OWNER TO bronze_staging;

--
-- TOC entry 7490 (class 0 OID 694251)
-- Dependencies: 870
-- Data for Name: load_history; Type: TABLE DATA; Schema: bronze_staging; Owner: bronze_staging
--



--
-- TOC entry 7491 (class 0 OID 694264)
-- Dependencies: 871
-- Data for Name: load_history_item; Type: TABLE DATA; Schema: bronze_staging; Owner: bronze_staging
--



--
-- TOC entry 7498 (class 0 OID 0)
-- Dependencies: 845
-- Name: load_id_seq; Type: SEQUENCE SET; Schema: bronze_staging; Owner: bronze_staging
--

SELECT pg_catalog.setval('bronze_staging.load_id_seq', 23, true);


--
-- TOC entry 7329 (class 2606 OID 694270)
-- Name: load_history_item load_history_item_pkey; Type: CONSTRAINT; Schema: bronze_staging; Owner: bronze_staging
--

ALTER TABLE ONLY bronze_staging.load_history_item
    ADD CONSTRAINT load_history_item_pkey PRIMARY KEY (item_id) INCLUDE (item_id);


--
-- TOC entry 7327 (class 2606 OID 694258)
-- Name: load_history load_history_pkey; Type: CONSTRAINT; Schema: bronze_staging; Owner: bronze_staging
--

ALTER TABLE ONLY bronze_staging.load_history
    ADD CONSTRAINT load_history_pkey PRIMARY KEY (load_id);


--
-- TOC entry 7330 (class 2606 OID 694259)
-- Name: load_history fk_data_product; Type: FK CONSTRAINT; Schema: bronze_staging; Owner: bronze_staging
--

ALTER TABLE ONLY bronze_staging.load_history
    ADD CONSTRAINT fk_data_product FOREIGN KEY (data_product_id) REFERENCES meta.data_product(data_product_id);


--
-- TOC entry 7331 (class 2606 OID 694271)
-- Name: load_history_item load_id_fk; Type: FK CONSTRAINT; Schema: bronze_staging; Owner: bronze_staging
--

ALTER TABLE ONLY bronze_staging.load_history_item
    ADD CONSTRAINT load_id_fk FOREIGN KEY (load_id) REFERENCES bronze_staging.load_history(load_id);


--
-- TOC entry 7497 (class 0 OID 0)
-- Dependencies: 143
-- Name: SCHEMA bronze_staging; Type: ACL; Schema: -; Owner: bronze_staging
--

GRANT USAGE ON SCHEMA bronze_staging TO PUBLIC;


-- Completed on 2024-08-16 21:11:23

--
-- PostgreSQL database dump complete
--

