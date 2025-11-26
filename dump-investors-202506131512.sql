--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10
-- Dumped by pg_dump version 17.0

-- Started on 2025-06-13 15:12:53

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 9 (class 2615 OID 18808)
-- Name: public; Type: SCHEMA; Schema: -; Owner: devmultilenden
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO devmultilenden;

--
-- TOC entry 10156 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: devmultilenden
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 1969 (class 1247 OID 1539115)
-- Name: gst_type; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.gst_type AS ENUM (
    'I',
    'C'
);


ALTER TYPE public.gst_type OWNER TO devmultilenden;

--
-- TOC entry 1972 (class 1247 OID 1662202)
-- Name: mandate_tracker_status; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.mandate_tracker_status AS ENUM (
    'INITIATED',
    'COMPLETED',
    'EXPIRED',
    'CANCELLED',
    'TEST'
);


ALTER TYPE public.mandate_tracker_status OWNER TO devmultilenden;

--
-- TOC entry 1975 (class 1247 OID 1621201)
-- Name: new_status; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.new_status AS ENUM (
    'INITIATED',
    'COMPLETED',
    'EXPIRED',
    'CANCELLED'
);


ALTER TYPE public.new_status OWNER TO devmultilenden;

--
-- TOC entry 1978 (class 1247 OID 1453606)
-- Name: notification_type_enum; Type: TYPE; Schema: public; Owner: usrinvoswrt
--

CREATE TYPE public.notification_type_enum AS ENUM (
    'loans_availability',
    'new_loans_available'
);


ALTER TYPE public.notification_type_enum OWNER TO usrinvoswrt;

--
-- TOC entry 2973 (class 1247 OID 1883390)
-- Name: reward_status; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.reward_status AS ENUM (
    'PENDING',
    'AVAILABLE',
    'COMPLETED',
    'EXPIRED'
);


ALTER TYPE public.reward_status OWNER TO devmultilenden;

--
-- TOC entry 1981 (class 1247 OID 1537720)
-- Name: stl_product_type_enum; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.stl_product_type_enum AS ENUM (
    'MONTHLY',
    'DAILY'
);


ALTER TYPE public.stl_product_type_enum OWNER TO devmultilenden;

--
-- TOC entry 1984 (class 1247 OID 1137883)
-- Name: user_action; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.user_action AS ENUM (
    'SUBMITTED',
    'CANCELLED',
    'SKIPPED'
);


ALTER TYPE public.user_action OWNER TO devmultilenden;

--
-- TOC entry 1987 (class 1247 OID 1137888)
-- Name: user_source; Type: TYPE; Schema: public; Owner: devmultilenden
--

CREATE TYPE public.user_source AS ENUM (
    'IOS',
    'ANDROID'
);


ALTER TYPE public.user_source OWNER TO devmultilenden;

--
-- TOC entry 1255 (class 1255 OID 18846)
-- Name: compare_arrays(text[], text[]); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.compare_arrays(arr1_text text[], arr2_text text[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    arr1 TEXT[];
    arr2 TEXT[];
BEGIN
    -- Convert text arrays to text[] if needed
    arr1 := arr1_text;
    arr2 := arr2_text;

    -- Check if they are equal
    IF arr1 = arr2 THEN
        RETURN TRUE;
    END IF;

    -- Check if they have the same elements (ignoring order)
    RETURN NOT EXISTS (
        SELECT elem FROM unnest(arr1) AS elem
        EXCEPT
        SELECT elem FROM unnest(arr2) AS elem
    ) AND NOT EXISTS (
        SELECT elem FROM unnest(arr2) AS elem
        EXCEPT
        SELECT elem FROM unnest(arr1) AS elem
    );
END;
$$;


ALTER FUNCTION public.compare_arrays(arr1_text text[], arr2_text text[]) OWNER TO devmultilenden;

--
-- TOC entry 1313 (class 1255 OID 18895)
-- Name: encrypt_data(text, text); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.encrypt_data(data_value text, cipher_key_hex text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    encrypted_data BYTEA;
BEGIN
    -- Encrypt the data using AES-256 without ECB mode specification
    encrypted_data := encrypt(data_value::bytea, decode(cipher_key_hex, 'hex'), 'aes-128');
    RETURN encode(encrypted_data, 'hex'); -- Return as a hexadecimal string
END;
$$;


ALTER FUNCTION public.encrypt_data(data_value text, cipher_key_hex text) OWNER TO devmultilenden;

--
-- TOC entry 1315 (class 1255 OID 18897)
-- Name: fn_generate_auto_lending_transaction_id(character varying); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.fn_generate_auto_lending_transaction_id(transaction_type character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_milliseconds BIGINT;
BEGIN
    v_milliseconds := (SELECT SUBSTRING((extract(epoch from clock_timestamp()) * 1000000)::bigint::VARCHAR, 3, 14));

-- 	IF transaction_type = 'MANUAL REPAYMENT TRANSFER' THEN
--         RETURN 'MLAD' || v_milliseconds;
-- 	ELSIF transaction_type = 'SHORT TERM LENDING REPAYMENT TRANSFER' OR transaction_type = 'LUMPSUM REPAYMENT TRANSFER' THEN
--     	RETURN 'OTLRD' || v_milliseconds;
--     ELSIF transaction_type = 'MEDIUM TERM LENDING REPAYMENT TRANSFER' THEN
-- 	    RETURN 'MTLRD' || v_milliseconds;
-- 	ELSIF transaction_type  IN  ('BPE PRINCIPAL REPAYMENT TRANSFER', 'BPE INTEREST REPAYMENT TRANSFER') THEN
-- 	    RETURN 'BPERD' || v_milliseconds;
--     ELSE
-- 	    RETURN 'ALRD' || v_milliseconds;
--     END IF;
    IF transaction_type IN ('BPE PRINCIPAL REPAYMENT TRANSFER', 'BPE INTEREST REPAYMENT TRANSFER') THEN
        RETURN 'BPERD' || v_milliseconds;
    ELSE
        RETURN 'INVW' || v_milliseconds;
    END IF;
End;
$$;


ALTER FUNCTION public.fn_generate_auto_lending_transaction_id(transaction_type character varying) OWNER TO devmultilenden;

--
-- TOC entry 1320 (class 1255 OID 18902)
-- Name: generate_aml_tracking_id(integer, integer); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.generate_aml_tracking_id(length integer, attempt integer DEFAULT 1) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    characters TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    new_aml_tracking_id TEXT := '';
    i INT;
    id_exists BOOLEAN;
BEGIN
    -- Generate a random alphanumeric string
    FOR i IN 1..length LOOP
        new_aml_tracking_id := new_aml_tracking_id || substr(characters, floor(random() * length(characters) + 1)::int, 1);
    END LOOP;

    -- Check if the generated ID already exists in the table
    SELECT EXISTS (
        SELECT 1 FROM lendenapp_userkyctracker
        WHERE lendenapp_userkyctracker.aml_tracking_id = new_aml_tracking_id
    ) INTO id_exists;

    -- If unique, return the tracking ID
    IF NOT id_exists THEN
        RETURN new_aml_tracking_id;
    END IF;

    -- Retry recursively up to 3 times
    IF attempt < 4 THEN
        RETURN generate_aml_tracking_id(length, attempt + 1); -- Recursive call
    ELSE
        RETURN NULL; -- Fail after 3 retries
    END IF;
END;
$$;


ALTER FUNCTION public.generate_aml_tracking_id(length integer, attempt integer) OWNER TO devmultilenden;

--
-- TOC entry 1321 (class 1255 OID 18903)
-- Name: generate_random_number_with_digits(integer); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.generate_random_number_with_digits(num_digits integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    min_val BIGINT;
    max_val BIGINT;
    result BIGINT;
BEGIN
    -- Set the minimum and maximum values for the number of digits
    min_val := POWER(10, num_digits - 1);
    max_val := POWER(10, num_digits) - 1;

    -- Generate a random number within the range
    result := FLOOR(RANDOM() * (max_val - min_val + 1) + min_val);

    RETURN result;
END;
$$;


ALTER FUNCTION public.generate_random_number_with_digits(num_digits integer) OWNER TO devmultilenden;

--
-- TOC entry 1322 (class 1255 OID 18904)
-- Name: get_dynamic_cig_query(integer); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.get_dynamic_cig_query(preference_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    pref_list TEXT[];
    dynamic_conditions TEXT := '';
    tenure_conditions TEXT := '';
    risk_conditions TEXT := '';
    income_conditions TEXT := '';
    borrower_type_conditions TEXT := '';
    roi_conditions TEXT := '';
    final_conditions TEXT := '';
BEGIN
    -- Get the list of true columns from the preference table
    pref_list := get_true_columns(preference_id);

    -- If pref_list is empty, return a condition that will return no rows (FALSE)
    IF array_length(pref_list, 1) IS NULL THEN
        RETURN ''; -- This will make the WHERE clause always false, returning no rows
    END IF;

    -- Loop through preferences and build conditions
    FOR i IN array_lower(pref_list, 1) .. array_upper(pref_list, 1)
    LOOP
        CASE pref_list[i]
            -- Tenure conditions
--            WHEN 'tenure_below_3M' THEN
--                tenure_conditions := tenure_conditions || ' OR t_cig.tenure < 3';
--            WHEN 'tenure_3_to_1Y' THEN
--                tenure_conditions := tenure_conditions || ' OR t_cig.tenure = 3';
--            WHEN 'above_1Y' THEN
--                tenure_conditions := tenure_conditions || ' OR t_cig.tenure > 12';

            -- Risk conditions
            WHEN 'risk_high' THEN
                risk_conditions := risk_conditions || ' OR t_cig.risk_type = ''HIGH''';
            WHEN 'risk_medium' THEN
                risk_conditions := risk_conditions || ' OR t_cig.risk_type = ''MEDIUM''';
            WHEN 'risk_low' THEN
                risk_conditions := risk_conditions || ' OR t_cig.risk_type = ''LOW''';

            -- Income conditions
            WHEN 'income_below_25K' THEN
                income_conditions := income_conditions || ' OR t_cig.income_value < 25000';
            WHEN 'income_25K_to_50K' THEN
                income_conditions := income_conditions || ' OR t_cig.income_value BETWEEN 25000 AND 50000';
            WHEN 'income_50K_to_1L' THEN
                income_conditions := income_conditions || ' OR t_cig.income_value BETWEEN 50000 AND 100000';
            WHEN 'income_above_1L' THEN
                income_conditions := income_conditions || ' OR t_cig.income_value > 100000';

            -- Borrower type conditions
            WHEN 'salaried' THEN
                borrower_type_conditions := borrower_type_conditions || ' OR t_cig.borrower_type = ''SALARIED''';
            WHEN 'business' THEN
                borrower_type_conditions := borrower_type_conditions || ' OR t_cig.borrower_type = ''BUSINESS''';

            -- Lending ROI conditions
            WHEN 'lending_roi_15_18' THEN
                roi_conditions := roi_conditions || ' OR t_cig.interest_rate BETWEEN 15 AND 18';
            WHEN 'lending_roi_18_24' THEN
                roi_conditions := roi_conditions || ' OR t_cig.interest_rate BETWEEN 18 AND 24';
            WHEN 'lending_roi_24_30' THEN
                roi_conditions := roi_conditions || ' OR t_cig.interest_rate BETWEEN 24 AND 30';
            WHEN 'lending_roi_30_40' THEN
                roi_conditions := roi_conditions || ' OR t_cig.interest_rate BETWEEN 30 AND 40';
            WHEN 'lending_roi_40_60' THEN
                roi_conditions := roi_conditions || ' OR t_cig.interest_rate BETWEEN 40 AND 60';

            ELSE
                dynamic_conditions := dynamic_conditions;
        END CASE;
    END LOOP;

    -- Remove leading ' OR ' from each category condition (if any conditions were added)
    IF length(tenure_conditions) > 0 THEN
        tenure_conditions := '(' || substring(tenure_conditions FROM 5) || ')';
    END IF;
    IF length(risk_conditions) > 0 THEN
        risk_conditions := '(' || substring(risk_conditions FROM 5) || ')';
    END IF;
    IF length(income_conditions) > 0 THEN
        income_conditions := '(' || substring(income_conditions FROM 5) || ')';
    END IF;
    IF length(borrower_type_conditions) > 0 THEN
        borrower_type_conditions := '(' || substring(borrower_type_conditions FROM 5) || ')';
    END IF;
    IF length(roi_conditions) > 0 THEN
        roi_conditions := '(' || substring(roi_conditions FROM 5) || ')';
    END IF;

    -- Combine all conditions with AND
    IF LENGTH(tenure_conditions || risk_conditions || income_conditions || borrower_type_conditions || roi_conditions) > 0 THEN
    final_conditions := 
        ' AND ' ||
        COALESCE(tenure_conditions, '') ||
        CASE 
            WHEN LENGTH(tenure_conditions) > 0 AND LENGTH(risk_conditions) > 0 THEN ' AND ' 
            ELSE '' 
        END ||
        COALESCE(risk_conditions, '') ||
        CASE 
            WHEN LENGTH(tenure_conditions || risk_conditions) > 0 AND LENGTH(income_conditions) > 0 THEN ' AND ' 
            ELSE '' 
        END ||
        COALESCE(income_conditions, '') ||
        CASE 
            WHEN LENGTH(tenure_conditions || risk_conditions || income_conditions) > 0 AND LENGTH(borrower_type_conditions) > 0 THEN ' AND ' 
            ELSE '' 
        END ||
        COALESCE(borrower_type_conditions, '') ||
        CASE 
            WHEN LENGTH(tenure_conditions || risk_conditions || income_conditions || borrower_type_conditions) > 0 AND LENGTH(roi_conditions) > 0 THEN ' AND ' 
            ELSE '' 
        END ||
        COALESCE(roi_conditions, '');
ELSE
    final_conditions := ''; -- or handle it however you want if there are no conditions
END IF;
    -- Return the final dynamic query conditions for the WHERE clause
    RETURN final_conditions;
END;
$$;


ALTER FUNCTION public.get_dynamic_cig_query(preference_id integer) OWNER TO devmultilenden;

--
-- TOC entry 1326 (class 1255 OID 18905)
-- Name: get_otl_product_filter_query(integer, integer[]); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.get_otl_product_filter_query(tenure integer, v_loan_tenure integer[] DEFAULT '{3}'::integer[]) RETURNS TABLE(dynamic_query text, min_per_loan_amount numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_condition TEXT := '';      -- To accumulate conditions for each product_type and loan_tenure
    v_product RECORD;            -- To iterate over records in the product config table
BEGIN
    RAISE INFO 'loan_tenure list1: %', v_loan_tenure;

    -- Loop through product config to construct the dynamic condition
    FOR v_product IN 
        (SELECT product_name, TRUNC(loan_tenure)::INT AS loan_tenure 
         FROM qafmpp.t_otl_product_config 
         WHERE otl_tenure = tenure 
           AND loan_tenure = ANY(v_loan_tenure)) -- Use 'ANY' to match values in array
    LOOP
        -- If there's already a condition, append an OR
        IF v_condition != '' THEN
            v_condition := v_condition || ' OR ';
        END IF;

        -- Add the current condition (partner_code = product_name AND tenure = loan_tenure)
        v_condition := v_condition || 
                       '(t_cig.partner_code = ''' || v_product.product_name || ''' AND t_cig.tenure = ' || v_product.loan_tenure || ')';
    END LOOP;

    -- Fetch the minimum per_loan_amount from the product config table where loan_tenure is in the list
    SELECT MIN(per_loan_amount) INTO min_per_loan_amount
    FROM qafmpp.t_otl_product_config
    WHERE loan_tenure = ANY(v_loan_tenure); -- Ensure minimum amount corresponds to the provided loan_tenure

    -- If conditions exist, prepend 'AND', otherwise set dynamic_query to NULL
    IF v_condition != '' THEN
        v_condition := 'AND ' || '(' || v_condition || ')';
        dynamic_query := v_condition;
    ELSE
        dynamic_query := NULL;
    END IF;

    -- Return the dynamic query and the minimum per_loan_amount
    RETURN QUERY SELECT dynamic_query, min_per_loan_amount;
END $$;


ALTER FUNCTION public.get_otl_product_filter_query(tenure integer, v_loan_tenure integer[]) OWNER TO devmultilenden;

--
-- TOC entry 1327 (class 1255 OID 18906)
-- Name: get_true_columns(integer); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.get_true_columns(preference_id integer) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    col_names TEXT[] := '{}';  -- Initialize empty array for column names
    pref_row JSON;             -- Variable to hold the row as JSON
    key TEXT;                  -- Variable for iterating over JSON keys
BEGIN
    -- Fetch the row as a JSON object, ignoring NULL values
    SELECT row_to_json(t)
    INTO pref_row
    FROM (
        SELECT "tenure_below_3M" , "tenure_3_to_1Y", "above_1Y", "risk_high", "risk_medium", "risk_low",
               "income_below_25K", "income_25K_to_50K", "income_50K_to_1L", "income_above_1L",
               "salaried", "business", "lending_roi_15_18", "lending_roi_18_24",
               "lending_roi_24_30", "lending_roi_30_40", "lending_roi_40_60"
        FROM qafmpp.t_preference_master
        WHERE id = preference_id
    ) t;

    -- Loop through each key-value pair in the JSON object
    FOR key IN SELECT * FROM json_object_keys(pref_row)
    LOOP
        -- Check if the value for the key is TRUE
        IF pref_row ->> key = 'true' THEN
            -- Append the column name (key) to the array
            col_names := array_append(col_names, key);
        END IF;
    END LOOP;

    -- Return the array of column names with TRUE values
    RETURN col_names;
END;
$$;


ALTER FUNCTION public.get_true_columns(preference_id integer) OWNER TO devmultilenden;

--
-- TOC entry 1330 (class 1255 OID 18909)
-- Name: lendenapp_account_trigger_function(); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.lendenapp_account_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
		IF TG_OP='DELETE' then	
		   INSERT INTO lendenapp_historicalaccount (history_type,history_date,id,"number", status,previous_balance,"action",action_amount,balance,bank_account_id,user_id,task_id,user_source_group_id, created_date, updated_date)
				VALUES ('-', now(), OLD.id, OLD.number, OLD.status, OLD.previous_balance, OLD.action , OLD.action_amount, OLD.balance, OLD.bank_account_id, OLD.user_id, OLD.task_id, OLD.user_source_group_id, OLD.created_date, OLD.updated_date); 
	  	END IF;
	  
	  	IF TG_OP='UPDATE' THEN	
	       INSERT INTO lendenapp_historicalaccount (history_type,history_date,id,"number", status,previous_balance,"action",action_amount,balance,bank_account_id,user_id,task_id,user_source_group_id, created_date, updated_date)
			    VALUES  ('~', now(), OLD.id, OLD.number, OLD.status, OLD.previous_balance, OLD.action , OLD.action_amount, OLD.balance, OLD.bank_account_id, OLD.user_id, OLD.task_id, OLD.user_source_group_id, OLD.created_date, OLD.updated_date);  
    	END IF;
	  
		RETURN NEW;

	END;
$$;


ALTER FUNCTION public.lendenapp_account_trigger_function() OWNER TO devmultilenden;

--
-- TOC entry 1335 (class 1255 OID 18910)
-- Name: lendenapp_transaction_trigger_function(); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.lendenapp_transaction_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

  IF TG_OP='DELETE' THEN	
    INSERT INTO lendenapp_historicaltransaction (history_date,history_type,id,transaction_id,response_id,"type",type_id,amount,status,status_date,description,details,remark,"date",previous_balance,updated_balance,rejection_reason,from_user_id,to_user_id,task_id,utr_no,user_source_group_id,created_date,updated_date)
		VALUES (now(),'-',OLD.id,OLD.transaction_id,OLD.response_id,OLD."type",OLD.type_id,OLD.amount,OLD.status,OLD.status_date,OLD.description,OLD.details,OLD.remark,OLD."date",OLD.previous_balance,OLD.updated_balance,OLD.rejection_reason,OLD.from_user_id,OLD.to_user_id,OLD.task_id,OLD.utr_no,OLD.user_source_group_id,OLD.created_date,OLD.updated_date);

  END IF;
  
  IF TG_OP='UPDATE' THEN	
    INSERT INTO lendenapp_historicaltransaction (history_date,history_type,id,transaction_id,response_id,"type",type_id,amount,status,status_date,description,details,remark,"date",previous_balance,updated_balance,rejection_reason,from_user_id,to_user_id,task_id,utr_no,user_source_group_id,created_date,updated_date)
		VALUES (now(),'~',OLD.id,OLD.transaction_id,OLD.response_id,OLD."type",OLD.type_id,OLD.amount,OLD.status,OLD.status_date,OLD.description,OLD.details,OLD.remark,OLD."date",OLD.previous_balance,OLD.updated_balance,OLD.rejection_reason,OLD.from_user_id,OLD.to_user_id,OLD.task_id,OLD.utr_no,OLD.user_source_group_id,OLD.created_date,OLD.updated_date);
  
    END IF;
  
    RETURN NEW;
    
END;
$$;


ALTER FUNCTION public.lendenapp_transaction_trigger_function() OWNER TO devmultilenden;

--
-- TOC entry 1336 (class 1255 OID 18911)
-- Name: lendenapp_txntrackaccount_trigger_function(); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.lendenapp_txntrackaccount_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

  IF TG_OP='DELETE' THEN	
    INSERT INTO lendenapp_historicaltracktxnamount (history_date,history_type,id,transaction_id,initial_amount,"type",action_amount,expiry_dtm,balance,reversal_txn_id,user_source_group_id,created_date,updated_date)
		VALUES (now(),'-',OLD.id,OLD.transaction_id,OLD.initial_amount,OLD."type",OLD.action_amount,OLD.expiry_dtm,OLD.balance,OLD.reversal_txn_id,OLD.user_source_group_id,OLD.created_date,OLD.updated_date);

  END IF;
  
  IF TG_OP='UPDATE' THEN	
    INSERT INTO lendenapp_historicaltracktxnamount (history_date,history_type,id,transaction_id,initial_amount,"type",action_amount,expiry_dtm,balance,reversal_txn_id,user_source_group_id,created_date,updated_date)
		VALUES (now(),'~',OLD.id,OLD.transaction_id,OLD.initial_amount,OLD."type",OLD.action_amount,OLD.expiry_dtm,OLD.balance,OLD.reversal_txn_id,OLD.user_source_group_id,OLD.created_date,OLD.updated_date);
  
    END IF;
  
    RETURN NEW;
    
END;
$$;


ALTER FUNCTION public.lendenapp_txntrackaccount_trigger_function() OWNER TO devmultilenden;

--
-- TOC entry 1251 (class 1255 OID 18937)
-- Name: prc_auto_lending_transaction_dump(); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_auto_lending_transaction_dump()
    LANGUAGE plpgsql
    AS $$
DECLARE
   v_repayment_records        RECORD;
   v_manual_repayments_record RECORD;
   v_account_record           RECORD;
   txn_id                     VARCHAR;
   v_auto_withdrawal_type     VARCHAR;
   v_auto_withdrawal_txn_id   BIGINT;
   v_user_source_group_id     BIGINT;
   v_customuser_id            BIGINT;
   v_cp_id                    BIGINT;
   v_repayment_transfer_id    BIGINT;
   is_mandate_active_flag     BOOLEAN;
   v_withdrawal_status        VARCHAR;
   v_temp_transfer_type       VARCHAR;
BEGIN
   CREATE TEMP TABLE temp_repayment_mapping
   (
       type                 VARCHAR,
       repayment_id         BIGINT,
       user_source_group_id BIGINT,
       to_user_id           BIGINT,
       mandate_active       BOOLEAN,
       amount               NUMERIC
   ) ON COMMIT DROP;
   CREATE INDEX idx_temp_repayment_mapping_user_group ON temp_repayment_mapping(user_source_group_id);
--     CREATE INDEX idx_temp_repayment_mapping_to_user ON temp_repayment_mapping(to_user_id);
--     CREATE INDEX idx_temp_repayment_mapping_type ON temp_repayment_mapping(type);
--     CREATE INDEX idx_temp_repayment_mapping_mandate_active ON temp_repayment_mapping(mandate_active);
   -- Step 1: Loop through each record in lendenapp_transaction_repayment_temp
   FOR v_repayment_records IN
       SELECT * FROM lendenapp_transaction_repayment_temp
       LOOP
            raise info 'v_repayment_records, %, %', v_repayment_records.user_id, v_repayment_records.type;
            SELECT id into v_customuser_id FROM lendenapp_customuser WHERE user_id = v_repayment_records.user_id;

            IF v_repayment_records.channel_partner_id IS NOT NULL THEN
                SELECT id into v_cp_id
                FROM lendenapp_channelpartner
                WHERE partner_id = v_repayment_records.channel_partner_id;
            END IF;
            
            raise notice 'v_customuser_id, v_repayment_records.channel_partner_id, %, %', v_customuser_id, v_repayment_records.channel_partner_id;
            
            SELECT lusg.id INTO v_user_source_group_id
            FROM lendenapp_user_source_group lusg
            JOIN lendenapp_source ls ON lusg.source_id = ls.id
            WHERE lusg.user_id = v_customuser_id
              AND ls.source_name = v_repayment_records.user_source
              AND (
                  v_cp_id IS NULL
                  OR lusg.channel_partner_id = v_cp_id
              );

           is_mandate_active_flag := false;
           -- Generate a new transaction ID
           txn_id := fn_generate_auto_lending_transaction_id(v_repayment_records.type);
           -- Fetch the user's account info with locking
           SELECT id, balance
           INTO v_account_record
           FROM lendenapp_account
           WHERE user_source_group_id = v_user_source_group_id FOR UPDATE NOWAIT;
           -- Insert record into lendenapp_transaction
           INSERT INTO lendenapp_transaction (transaction_id, type, amount, description, from_user_id,
                                              to_user_id, type_id, status, user_source_group_id, date, status_date)
           VALUES (v_repayment_records.transaction_id, v_repayment_records.type, v_repayment_records.amount,
                   v_repayment_records.description, v_repayment_records.from_user_id, v_customuser_id,
                   v_repayment_records.type_id, v_repayment_records.status, v_user_source_group_id,
                   now(), (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::DATE)
           RETURNING id INTO v_repayment_transfer_id;
           -- Update account with the new balance
           UPDATE lendenapp_account
           SET balance          = balance + v_repayment_records.amount,
               previous_balance = v_account_record.balance,
               updated_date     = now(),
               action_amount    = v_repayment_records.amount,
               action           = 'CREDIT'
           WHERE id = v_account_record.id;
           -- Fetch mandate status for AL schemes
           IF v_repayment_records.type='AUTO LENDING REPAYMENT TRANSFER' THEN
               SELECT (CASE WHEN lsi.mandate_id IS NOT NULL THEN TRUE ELSE FALSE END)
                  INTO is_mandate_active_flag
               FROM lendenapp_schemeinfo lsi
               WHERE lsi.scheme_id = v_repayment_records.scheme_id;
           END IF;
           -- Insert into temp_repayment_mapping for further processing
           v_temp_transfer_type := (CASE WHEN v_repayment_records.type='AUTO LENDING REPAYMENT TRANSFER' THEN 'AUTO LENDING REPAYMENT TRANSFER'
                                    WHEN v_repayment_records.type='BPE PRINCIPAL REPAYMENT TRANSFER' THEN 'BPE PRINCIPAL REPAYMENT TRANSFER'
                                    WHEN v_repayment_records.type='BPE INTEREST REPAYMENT TRANSFER' THEN 'BPE INTEREST REPAYMENT TRANSFER'
                                    WHEN v_repayment_records.type='BPE BLOCK INTEREST REPAYMENT TRANSFER' THEN 'BPE BLOCK INTEREST REPAYMENT TRANSFER'
                                    ELSE 'MANUAL REPAYMENT TRANSFER' END);
           INSERT INTO temp_repayment_mapping(repayment_id, user_source_group_id, to_user_id, mandate_active, amount, type)
           VALUES (v_repayment_transfer_id, v_user_source_group_id,
                   v_customuser_id, COALESCE(is_mandate_active_flag, FALSE),
                   v_repayment_records.amount, v_temp_transfer_type);
           IF v_repayment_records.type IN ('AUTO LENDING REPAYMENT TRANSFER', 'MANUAL REPAYMENT TRANSFER',
                                           'LUMPSUM REPAYMENT TRANSFER', 'MEDIUM TERM LENDING REPAYMENT TRANSFER',
                                           'SHORT TERM LENDING REPAYMENT TRANSFER') THEN
               -- Insert into lendenapp_scheme_repayment_details
               INSERT INTO lendenapp_scheme_repayment_details
               (purpose_ref_id, debit_amount, unique_record_id, user_source_group_id,
                is_reinvestment_processed, repayment_id, is_mandate_active, type, principal, interest)
               VALUES (v_repayment_records.scheme_id, v_repayment_records.amount,
                       (SELECT 'UD' || upper(substr(md5(random()::text || clock_timestamp()), 1, 18))),
                       v_user_source_group_id,
                       FALSE, v_repayment_transfer_id,
                       COALESCE(is_mandate_active_flag, FALSE), v_repayment_records.type,
                  v_repayment_records.principal, v_repayment_records.interest);
           END IF;
   END LOOP;
   -- Step 2: Process repayments in bulk
   FOR v_manual_repayments_record IN
       (SELECT sum(amount) transaction_sum, user_source_group_id, to_user_id, type, mandate_active
        FROM temp_repayment_mapping
        GROUP BY user_source_group_id, to_user_id, type, mandate_active)
   LOOP
        txn_id := fn_generate_auto_lending_transaction_id(v_manual_repayments_record.type);
        -- Fetch account information with locking
        SELECT id, balance INTO v_account_record
        FROM lendenapp_account WHERE user_source_group_id = v_manual_repayments_record.user_source_group_id FOR UPDATE NOWAIT;
        v_auto_withdrawal_type :=
            CASE
                WHEN v_manual_repayments_record.type = 'MANUAL REPAYMENT TRANSFER' THEN 'REPAYMENT AUTO WITHDRAWAL'
--                  WHEN v_manual_repayments_record.type = 'LUMPSUM REPAYMENT TRANSFER' THEN 'LUMPSUM AUTO WITHDRAWAL'
--                  WHEN v_manual_repayments_record.type = 'MEDIUM TERM LENDING REPAYMENT TRANSFER' THEN 'MEDIUM TERM LENDING AUTO WITHDRAWAL'
--                  WHEN v_manual_repayments_record.type = 'SHORT TERM LENDING REPAYMENT TRANSFER' THEN 'SHORT TERM LENDING AUTO WITHDRAWAL'
                WHEN v_manual_repayments_record.type = 'BPE PRINCIPAL REPAYMENT TRANSFER' THEN 'BPE PRINCIPAL REPAYMENT AUTO WITHDRAWAL'
                WHEN v_manual_repayments_record.type = 'BPE INTEREST REPAYMENT TRANSFER' THEN 'BPE INTEREST REPAYMENT AUTO WITHDRAWAL'
                WHEN v_manual_repayments_record.type = 'BPE BLOCK INTEREST REPAYMENT TRANSFER' THEN 'BPE BLOCK INTEREST REPAYMENT WITHDRAWAL'
                ELSE 'AUTO LENDING REPAYMENT WITHDRAWAL'
           END;
        v_withdrawal_status := (CASE WHEN v_manual_repayments_record.type IN
                               ('BPE PRINCIPAL REPAYMENT TRANSFER', 'BPE INTEREST REPAYMENT TRANSFER', 'BPE BLOCK INTEREST REPAYMENT TRANSFER')
                               THEN 'SUCCESS' ELSE 'SCHEDULED' END);
        -- Insert the clubbed transaction into lendenapp_transaction
        INSERT INTO lendenapp_transaction (transaction_id, type, amount, description, from_user_id,
                                           status, user_source_group_id, date, status_date)
        VALUES (txn_id, v_auto_withdrawal_type, v_manual_repayments_record.transaction_sum,
                'Money withdrawn from account', v_manual_repayments_record.to_user_id,
                v_withdrawal_status, v_manual_repayments_record.user_source_group_id, now(), (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::DATE)
        RETURNING id INTO v_auto_withdrawal_txn_id;
        -- Update the account balance
        UPDATE lendenapp_account
        SET    balance          = balance - v_manual_repayments_record.transaction_sum,
               previous_balance = v_account_record.balance,
               updated_date     = now(),
               action_amount    = v_manual_repayments_record.transaction_sum,
               action           = 'DEBIT'
        WHERE id = v_account_record.id;
        --Update withdrawal transaction_id for AUTO LENDING
        IF v_manual_repayments_record.type IN ('AUTO LENDING REPAYMENT TRANSFER', 'MANUAL REPAYMENT TRANSFER',
                                           'LUMPSUM REPAYMENT TRANSFER', 'MEDIUM TERM LENDING REPAYMENT TRANSFER',
                                           'SHORT TERM LENDING REPAYMENT TRANSFER') THEN
           UPDATE lendenapp_scheme_repayment_details SET withdrawal_transaction_id=v_auto_withdrawal_txn_id
           WHERE repayment_id IN (SELECT repayment_id FROM temp_repayment_mapping
                                  WHERE user_source_group_id = v_manual_repayments_record.user_source_group_id
                                  AND mandate_active = v_manual_repayments_record.mandate_active and type=v_manual_repayments_record.type);
        END IF;
   END LOOP;
  TRUNCATE table lendenapp_transaction_repayment_temp;
END ;
$$;


ALTER PROCEDURE public.prc_auto_lending_transaction_dump() OWNER TO devmultilenden;

--
-- TOC entry 1348 (class 1255 OID 18940)
-- Name: prc_auto_lending_transaction_dump_backup(); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_auto_lending_transaction_dump_backup()
    LANGUAGE plpgsql
    AS $$
DECLARE
   v_repayment_records RECORD;
   v_manual_repayments_record RECORD;
   v_account_record RECORD;
   txn_id VARCHAR;
   v_auto_withdrawal_type VARCHAR;
   v_auto_withdrawal_txn_id BIGINT;
   v_repayment_transfer_id BIGINT;
   v_scheme_info_id BIGINT;

BEGIN

    CREATE TEMP TABLE temp_repayment_mapping (
       repayment_id BIGINT,
       user_source_group_id BIGINT,
       to_user_id BIGINT,
       type VARCHAR
   ) ON COMMIT DROP;

   -- Loop through each record in lendenapp_transaction_repayment_temp
   FOR v_repayment_records IN
       SELECT * FROM lendenapp_transaction_repayment_temp
   LOOP
--     -- Generate a new transaction ID
       txn_id := fn_generate_auto_lending_transaction_id(v_repayment_records.type);

       SELECT id, balance INTO v_account_record FROM lendenapp_account
       WHERE user_source_group_id=v_repayment_records.user_source_group_id FOR UPDATE NOWAIT;

       -- Insert the record as it is into lendenapp_transaction
       INSERT INTO lendenapp_transaction (transaction_id, type, created_date, amount, description, from_user_id, to_user_id,
                                          type_id, status, user_source_group_id, date, status_date)
       VALUES (v_repayment_records.transaction_id, v_repayment_records.type, v_repayment_records.created_date,  v_repayment_records.amount,
               v_repayment_records.description, v_repayment_records.from_user_id, v_repayment_records.to_user_id,
               v_repayment_records.type_id, v_repayment_records.status, v_repayment_records.user_source_group_id,
               now(), CURRENT_DATE) RETURNING id INTO v_repayment_transfer_id;

       UPDATE lendenapp_account
       SET balance=balance + v_repayment_records.amount, previous_balance=v_account_record.balance,
           updated_date=now(), action_amount=v_repayment_records.amount, action='CREDIT'
       WHERE id=v_account_record.id;
        
        v_scheme_info_id := (SELECT id FROM lendenapp_schemeinfo WHERE scheme_id=v_repayment_records.scheme_id);

        IF v_repayment_records.type='AUTO LENDING REPAYMENT TRANSFER' THEN
            INSERT INTO lendenapp_scheme_repayment_details
            (purpose_ref_id, debit_amount, unique_record_id, user_source_group_id,
             scheme_info_id, is_reinvestment_processed, repayment_id)
            VALUES (v_repayment_records.scheme_id, v_repayment_records.amount,
                    (SELECT 'UD' || upper(substr(md5(random()::text || clock_timestamp()), 1, 18))),
                    v_repayment_records.user_source_group_id, v_scheme_info_id,
                    FALSE, v_repayment_transfer_id);

            INSERT INTO temp_repayment_mapping(repayment_id, user_source_group_id, to_user_id, type)
            VALUES (v_repayment_transfer_id, v_repayment_records.user_source_group_id,
                    v_repayment_records.to_user_id, v_repayment_records.type);
        END IF;

--        IF v_repayment_records.type = 'AUTO LENDING REPAYMENT TRANSFER' THEN
--               -- Insert a new record with the generated transaction ID
--               INSERT INTO lendenapp_transaction (transaction_id, type, created_date, amount, description, from_user_id, to_user_id,
--                                           type_id, status, user_source_group_id, date, status_date)
--               VALUES (txn_id, 'AUTO LENDING REPAYMENT WITHDRAWAL', now(), v_repayment_records.amount,
--                v_repayment_records.description, v_repayment_records.to_user_id,
--                null, v_repayment_records.type_id, 'SCHEDULED', v_repayment_records.user_source_group_id,
--                now(), CURRENT_DATE);
--
--              UPDATE lendenapp_account
--              SET balance=balance - v_repayment_records.amount, previous_balance=v_account_record.balance + v_repayment_records.amount,
--                  updated_date=now(), action_amount=v_repayment_records.amount, action='DEBIT'
--              WHERE id=v_account_record.id;
--        END IF;
   END LOOP;

   --Process manual repayments in bulk
   FOR v_manual_repayments_record IN
       (
            SELECT sum(amount) transaction_sum, user_source_group_id, to_user_id, type
            FROM lendenapp_transaction_repayment_temp
            GROUP BY user_source_group_id, to_user_id, type
       )
   LOOP
        txn_id := fn_generate_auto_lending_transaction_id(v_manual_repayments_record.type);
        SELECT id, balance INTO v_account_record FROM lendenapp_account
        WHERE user_source_group_id=v_manual_repayments_record.user_source_group_id FOR UPDATE NOWAIT;

        v_auto_withdrawal_type := (CASE WHEN v_manual_repayments_record.type='MANUAL REPAYMENT TRANSFER'
                                   THEN 'MANUAL LENDING AUTO WITHDRAWAL'
                                   ELSE 'AUTO LENDING REPAYMENT DEBIT' END);

        INSERT INTO lendenapp_transaction (transaction_id, type, created_date, amount, description, from_user_id, to_user_id,
                                           status, user_source_group_id, date, status_date)
        VALUES (txn_id, v_auto_withdrawal_type, now(), v_manual_repayments_record.transaction_sum,
                'Money withdrawn from account', v_manual_repayments_record.to_user_id,
                null, 'SCHEDULED', v_manual_repayments_record.user_source_group_id,
                now(), CURRENT_DATE) RETURNING id INTO v_auto_withdrawal_txn_id;

        UPDATE lendenapp_account
        SET balance=balance - v_manual_repayments_record.transaction_sum,
            previous_balance=v_account_record.balance,
            updated_date=now(), action_amount=v_manual_repayments_record.transaction_sum, action='DEBIT'
        WHERE id=v_account_record.id;

        --Update auto withdrawal txn_id in lendenapp_scheme_repayment_details
        UPDATE lendenapp_scheme_repayment_details
        SET withdrawal_transaction_id = v_auto_withdrawal_txn_id
        WHERE repayment_id IN (
           SELECT repayment_id FROM temp_repayment_mapping
           WHERE user_source_group_id = v_manual_repayments_record.user_source_group_id
        );

   END LOOP ;

--    TRUNCATE table lendenapp_transaction_repayment_temp;

END;
$$;


ALTER PROCEDURE public.prc_auto_lending_transaction_dump_backup() OWNER TO devmultilenden;

--
-- TOC entry 1349 (class 1255 OID 18941)
-- Name: prc_auto_lending_transaction_dump_v2(); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_auto_lending_transaction_dump_v2()
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_repayment_records        RECORD;
    v_manual_repayments_record RECORD;
    v_account_record           RECORD;
    txn_id                     VARCHAR;
    v_auto_withdrawal_type     VARCHAR;
    v_auto_withdrawal_txn_id   BIGINT;
    v_repayment_transfer_id    BIGINT;
    is_mandate_active_flag     BOOLEAN;
    v_withdrawal_status        VARCHAR;
    v_temp_transfer_type       VARCHAR;

BEGIN

    CREATE TEMP TABLE temp_repayment_mapping
    (
        type                 VARCHAR,
        repayment_id         BIGINT,
        user_source_group_id BIGINT,
        to_user_id           BIGINT,
        mandate_active       BOOLEAN,
        amount               NUMERIC
    ) ON COMMIT DROP;

    CREATE INDEX idx_temp_repayment_mapping_user_group ON temp_repayment_mapping(user_source_group_id);
--     CREATE INDEX idx_temp_repayment_mapping_to_user ON temp_repayment_mapping(to_user_id);
--     CREATE INDEX idx_temp_repayment_mapping_type ON temp_repayment_mapping(type);
--     CREATE INDEX idx_temp_repayment_mapping_mandate_active ON temp_repayment_mapping(mandate_active);

    -- Step 1: Loop through each record in lendenapp_transaction_repayment_temp
    FOR v_repayment_records IN
        SELECT * FROM lendenapp_transaction_repayment_temp
        LOOP
            -- Generate a new transaction ID
            txn_id := fn_generate_auto_lending_transaction_id(v_repayment_records.type);

            -- Fetch the user's account info with locking
            SELECT id, balance
            INTO v_account_record
            FROM lendenapp_account
            WHERE user_source_group_id = v_repayment_records.user_source_group_id FOR UPDATE NOWAIT;

            -- Insert record into lendenapp_transaction
            INSERT INTO lendenapp_transaction (transaction_id, type, amount, description, from_user_id,
                                               to_user_id, type_id, status, user_source_group_id, date, status_date)
            VALUES (v_repayment_records.transaction_id, v_repayment_records.type, v_repayment_records.amount,
                    v_repayment_records.description, v_repayment_records.from_user_id, v_repayment_records.to_user_id,
                    v_repayment_records.type_id, v_repayment_records.status, v_repayment_records.user_source_group_id,
                    now(), (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::DATE)
            RETURNING id INTO v_repayment_transfer_id;

            -- Update account with the new balance
            UPDATE lendenapp_account
            SET balance          = balance + v_repayment_records.amount,
                previous_balance = v_account_record.balance,
                updated_date     = now(),
                action_amount    = v_repayment_records.amount,
                action           = 'CREDIT'
            WHERE id = v_account_record.id;

            -- Fetch mandate status for AL schemes
--             IF v_repayment_records.type='AUTO LENDING REPAYMENT TRANSFER' THEN
--                 SELECT (CASE WHEN lsi.mandate_id IS NOT NULL THEN TRUE ELSE FALSE END)
--                    INTO is_mandate_active_flag
--                 FROM lendenapp_schemeinfo lsi
--                 WHERE lsi.scheme_id = v_repayment_records.scheme_id;
--             END IF;

            -- Insert into temp_repayment_mapping for further processing
--             v_temp_transfer_type := (CASE WHEN v_repayment_records.type='AUTO LENDING REPAYMENT TRANSFER' THEN 'AUTO LENDING REPAYMENT TRANSFER'
--                                      WHEN v_repayment_records.type='BPE PRINCIPAL REPAYMENT TRANSFER' THEN 'BPE PRINCIPAL REPAYMENT TRANSFER'
--                                      WHEN v_repayment_records.type='BPE INTEREST REPAYMENT TRANSFER' THEN 'BPE INTEREST REPAYMENT TRANSFER'
--                                      ELSE 'MANUAL REPAYMENT TRANSFER' END);
--             INSERT INTO temp_repayment_mapping(repayment_id, user_source_group_id, to_user_id, mandate_active, amount, type)
--             VALUES (v_repayment_transfer_id, v_repayment_records.user_source_group_id,
--                     v_repayment_records.to_user_id, COALESCE(is_mandate_active_flag, FALSE),
--                     v_repayment_records.amount, v_temp_transfer_type);

            IF v_repayment_records.type IN ('AUTO LENDING REPAYMENT TRANSFER', 'MANUAL REPAYMENT TRANSFER',
                                            'LUMPSUM REPAYMENT TRANSFER', 'MEDIUM TERM LENDING REPAYMENT TRANSFER',
                                            'SHORT TERM LENDING REPAYMENT TRANSFER') THEN
                -- Insert into lendenapp_scheme_repayment_details
                INSERT INTO lendenapp_scheme_repayment_details
                (purpose_ref_id, debit_amount, unique_record_id, user_source_group_id,
                 is_reinvestment_processed, repayment_id, is_mandate_active)
                VALUES (v_repayment_records.scheme_id, v_repayment_records.amount,
                        (SELECT 'UD' || upper(substr(md5(random()::text || clock_timestamp()), 1, 18))),
                        v_repayment_records.user_source_group_id,
                        FALSE, v_repayment_transfer_id,
                        COALESCE(is_mandate_active_flag, FALSE));
            END IF;
    END LOOP;

    -- Step 2: Process repayments in bulk
    FOR v_manual_repayments_record IN
--         (SELECT sum(amount) transaction_sum, user_source_group_id, to_user_id, type, mandate_active
--          FROM temp_repayment_mapping
--          GROUP BY user_source_group_id, to_user_id, type, mandate_active)
        (
            SELECT
                lt.user_source_group_id,
                lt.to_user_id,
                CASE
                    WHEN lt.type  = 'AUTO LENDING REPAYMENT TRANSFER' THEN 'AUTO LENDING REPAYMENT TRANSFER'
                    WHEN lt.type = 'BPE PRINCIPAL REPAYMENT TRANSFER' THEN 'BPE PRINCIPAL REPAYMENT TRANSFER'
                    when lt.type = 'BPE INTEREST REPAYMENT TRANSFER' THEN 'BPE INTEREST REPAYMENT TRANSFER'
                    ELSE 'MANUAL REPAYMENT TRANSFER'
                END AS type,
                CASE
                    when ls.mandate_id is not null then true
                    else false
                end as is_active,
                sum(lt.amount) transaction_sum
            FROM lendenapp_transaction_repayment_temp lt
            LEFT JOIN lendenapp_schemeinfo ls on ls.scheme_id = lt.scheme_id
                        AND ls.investment_type ='AUTO_LENDING'
            GROUP BY
                lt.user_source_group_id,
                CASE
                    WHEN lt.type = 'AUTO LENDING REPAYMENT TRANSFER' THEN 'AUTO LENDING REPAYMENT TRANSFER'
                    WHEN lt.type = 'BPE PRINCIPAL REPAYMENT TRANSFER' THEN 'BPE PRINCIPAL REPAYMENT TRANSFER'
                    WHEN lt.type = 'BPE INTEREST REPAYMENT TRANSFER' then 'BPE INTEREST REPAYMENT TRANSFER'
                    ELSE 'MANUAL REPAYMENT TRANSFER'
                end,
                (CASE WHEN ls.mandate_id IS NOT NULL THEN TRUE
                    else false
                end),
                lt.to_user_id
        )
    LOOP
         txn_id := fn_generate_auto_lending_transaction_id(v_manual_repayments_record.type);

         -- Fetch account information with locking
         SELECT id, balance INTO v_account_record
         FROM lendenapp_account WHERE user_source_group_id = v_manual_repayments_record.user_source_group_id FOR UPDATE NOWAIT;

         v_auto_withdrawal_type :=
             CASE
                 WHEN v_manual_repayments_record.type = 'MANUAL REPAYMENT TRANSFER' THEN 'REPAYMENT AUTO WITHDRAWAL'
--                  WHEN v_manual_repayments_record.type = 'LUMPSUM REPAYMENT TRANSFER' THEN 'LUMPSUM AUTO WITHDRAWAL'
--                  WHEN v_manual_repayments_record.type = 'MEDIUM TERM LENDING REPAYMENT TRANSFER' THEN 'MEDIUM TERM LENDING AUTO WITHDRAWAL'
--                  WHEN v_manual_repayments_record.type = 'SHORT TERM LENDING REPAYMENT TRANSFER' THEN 'SHORT TERM LENDING AUTO WITHDRAWAL'
                 WHEN v_manual_repayments_record.type = 'BPE PRINCIPAL REPAYMENT TRANSFER' THEN 'BPE PRINCIPAL REPAYMENT AUTO WITHDRAWAL'
                 WHEN v_manual_repayments_record.type = 'BPE INTEREST REPAYMENT TRANSFER' THEN 'BPE INTEREST REPAYMENT AUTO WITHDRAWAL'
                 ELSE 'AUTO LENDING REPAYMENT WITHDRAWAL'
            END;

         v_withdrawal_status := (CASE WHEN v_manual_repayments_record.type IN
                                ('BPE PRINCIPAL REPAYMENT TRANSFER', 'BPE INTEREST REPAYMENT TRANSFER') THEN 'SUCCESS' ELSE 'SCHEDULED' END);
         -- Insert the clubbed transaction into lendenapp_transaction
         INSERT INTO lendenapp_transaction (transaction_id, type, amount, description, from_user_id,
                                            status, user_source_group_id, date, status_date)
         VALUES (txn_id, v_auto_withdrawal_type, v_manual_repayments_record.transaction_sum,
                 'Money withdrawn from account', v_manual_repayments_record.to_user_id,
                 v_withdrawal_status, v_manual_repayments_record.user_source_group_id, now(),
                 (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::DATE)
         RETURNING id INTO v_auto_withdrawal_txn_id;

         -- Update the account balance
         UPDATE lendenapp_account
         SET    balance          = balance - v_manual_repayments_record.transaction_sum,
                previous_balance = v_account_record.balance,
                updated_date     = now(),
                action_amount    = v_manual_repayments_record.transaction_sum,
                action           = 'DEBIT'
         WHERE id = v_account_record.id;

         --Update withdrawal transaction_id for AUTO LENDING
         IF v_manual_repayments_record.type IN ('AUTO LENDING REPAYMENT TRANSFER', 'MANUAL REPAYMENT TRANSFER',
                                            'LUMPSUM REPAYMENT TRANSFER', 'MEDIUM TERM LENDING REPAYMENT TRANSFER',
                                            'SHORT TERM LENDING REPAYMENT TRANSFER') THEN
            UPDATE lendenapp_scheme_repayment_details SET withdrawal_transaction_id=v_auto_withdrawal_txn_id
            WHERE repayment_id IN (SELECT repayment_id FROM temp_repayment_mapping
                                   WHERE user_source_group_id = v_manual_repayments_record.user_source_group_id
                                   AND mandate_active = v_manual_repayments_record.is_active and type=v_manual_repayments_record.type);
         END IF;
    END LOOP;

   TRUNCATE table lendenapp_transaction_repayment_temp;

END ;
$$;


ALTER PROCEDURE public.prc_auto_lending_transaction_dump_v2() OWNER TO devmultilenden;

--
-- TOC entry 1350 (class 1255 OID 18944)
-- Name: prc_cp_mcp_migration(bigint); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_cp_mcp_migration(IN v_user_pk bigint)
    LANGUAGE plpgsql
    AS $$

		DECLARE 
	        v_user_record  record;
	    BEGIN
	    select * into v_user_record from qamono.lendenapp_customuser where id= v_user_pk;
	        
	    raise info 'hello';
	    
	    INSERT INTO lendenapp_customuser (id, user_id, password, encoded_pan, encoded_aadhar, encoded_mobile,
	          encoded_email, ucic_code, mobile_number, pan, first_name, middle_name, last_name, email,
	          email_verification, dob, gender, marital_status, aadhar, gross_annual_income, "type", device_id,
	          is_active, last_login, created_date, modified_date, is_migrated)
	    select id, user_id, password, encoded_pan, encoded_aadhar, encoded_mobile,
	          encoded_email, ucic_code, mobile_number, pan, first_name, middle_name, last_name, email,
	          email_verification, dob, gender, marital_status, aadhar, gross_annual_income, "type", device_id,
	          is_active, last_login, created_date, modified_date, is_migrated from qamono.lendenapp_customuser where id = v_user_pk;
	    
	    raise info  'hello1';
	    
	    INSERT INTO lendenapp_customuser_groups(id, customuser_id, group_id)
	        select id, customuser_id, group_id from qamono.lendenapp_customuser_groups where customuser_id = v_user_pk;
	    
	    raise info  'hello2';
	
	    INSERT INTO lendenapp_channelpartner (id, partner_id, "type", status, user_id, referred_by_id, created_date,
	                  updated_date, listed_date)
	        select id, partner_id, "type", status, user_id, referred_by_id, created_date,updated_date ,listed_date from qamono.lendenapp_channelpartner where user_id = v_user_pk;
	    
	    raise info  'hello3';
	
	    INSERT INTO lendenapp_document (
	            id, type, file, description, user_id, task_id, created_date, modified_date
	        )
	        SELECT
	            id, type, file, description, user_id, task_id, created_date, modified_date FROM qamono.lendenapp_document ld WHERE ld.user_id = v_user_pk;
	    
	    raise info  'hello4';
	
	    INSERT INTO lendenapp_bankaccount ( id, user_id, task_id, "number", "type", ifsc_code, bank_id, "name",
	            purpose, cashfree_dtm, is_active, encoded_number, created_date, updated_date
	        )
	        SELECT
	            id, user_id, task_id, "number", "type", ifsc_code, bank_id, "name", purpose, cashfree_dtm, is_active,
	            encoded_number, created_date, updated_date FROM qamono.lendenapp_bankaccount lb WHERE lb.user_id = v_user_pk;
	    
	    raise info  'hello5';
	
	    INSERT INTO lendenapp_convertedreferral(id, user_id, referred_by_id, created_date, updated_date)
	    SELECT id, user_id, referred_by_id, created_date, updated_date FROM qamono.lendenapp_convertedreferral WHERE user_id = v_user_pk;
	    
	--       select 10/0;
	   
	   
	   raise info  'hello6';
 
         INSERT INTO lendenapp_address (id, "type", "location", city, state, country, pin, landmark, email,
             is_verified, created_date, updated_date
         )
             SELECT id, "type", "location", city, state, country, pin, landmark, email, is_verified,
                    created_date, updated_date FROM qamono.lendenapp_address WHERE email = v_user_record.email;
          raise info  'hello7';
 
         INSERT INTO lendenapp_task(id, checklist, created_date, updated_date, assigned_by_id, created_by_id)
             SELECT lt.id, lp.additional_info, lt.created_date, lt.updated_date, lt.assigned_by_id, lt.created_by_id
                 FROM lendenapp_task lt
                 join qamono.lendenapp_customuser lc on lt.created_by_id  = lc.id
                 join qamono.lendenapp_prospect lp on lp.email  = lc.email
                 WHERE lc.id = v_user_pk;
         
         raise info  'hello8';
 
         INSERT INTO lendenapp_reference (id, "comment", email, mobile_number, "name", relation, "type", dob, gender,
                                         pan, encoded_mobile, encoded_email, encoded_pan, user_id, task_id,
                                          created_date, updated_date)
             SELECT id, "comment", email, mobile_number, "name", relation, "type", dob, gender, pan, encoded_mobile,
                    encoded_email, encoded_pan, user_id, task_id, created_date, updated_date FROM qamono.lendenapp_reference WHERE user_id = v_user_pk;
 
         IF upper(v_user_record.type) <> 'INDIVIDUAL' then
 
             insert into lendenapp_reference (id, "name", relation, "type", gst_number, pan, encoded_pan, user_id,
                                              task_id, created_date, updated_date)
                 select lr.id , lc.first_name, 'COMPANY', 'COMPANY_DETAILS', lc.gst_number, lc.pan, lc.encoded_pan,
                        v_user_pk, lr.task_id, lr.created_date, lr.updated_date
                 from qamono.lendenapp_customuser lc
                 join qamono.lendenapp_reference lr on lc.id = lr.user_id
                 join qamono.lendenapp_task lt on lt.id = lr.task_id
                 where  lt.created_by_id = v_user_pk and lr."type"  is null and lr.relation is null order by lr.id limit 1;
         end if;
        
        update qamono.lendenapp_customuser 
        set new_ios_migrated= true 
        where id = v_user_pk;
       
	    RAISE INFO 'Insert successful';
	
		EXCEPTION	
		    WHEN OTHERS THEN
		        RAISE INFO 'Other exception occurred.';
		        DECLARE
		             v_error_state TEXT;
		             v_error_message TEXT;
		             v_error_detail TEXT;
		             v_error_hint TEXT;
		             v_error_context TEXT;
		        BEGIN
		             RAISE NOTICE 'ERROR OCCURRED %', v_user_pk;
		             GET STACKED DIAGNOSTICS
		                 v_error_state = RETURNED_SQLSTATE,
		                 v_error_message = MESSAGE_TEXT,
		                 v_error_detail = PG_EXCEPTION_DETAIL,
		                 v_error_hint = PG_EXCEPTION_HINT,
		                 v_error_context = PG_EXCEPTION_CONTEXT;
		 
		             INSERT INTO lendenapp_migration_error_log (
		                     is_resolved, created_dtm, migration_type, err_message, err_details, err_context, user_source_id)
		             VALUES (false, NOW(), 'prc_cp_mcp_migration', v_error_message, v_error_detail, v_error_context, v_user_pk);
		 
		             RAISE INFO 'THE FOLLOWING ERROR OCCURRED % % % % %', v_error_state, v_error_message, v_error_detail, v_error_hint, v_error_context;
		        END;
END;
$$;


ALTER PROCEDURE public.prc_cp_mcp_migration(IN v_user_pk bigint) OWNER TO devmultilenden;

--
-- TOC entry 1352 (class 1255 OID 18947)
-- Name: prc_create_retail_lender(character varying); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_create_retail_lender(IN mobile_no character varying)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    lender_id BIGINT;
    investor_id VARCHAR;
    lender_pan VARCHAR;
    email VARCHAR;
    lender_name VARCHAR;
    user_pk BIGINT;
    user_source_id BIGINT;
    acc_no VARCHAR;
    track_id VARCHAR;
    track_id_rekyc VARCHAR;
    bank_acc_no VARCHAR;
    bank_acc_id INT;
    lender_checklist VARCHAR;
BEGIN
    
    -- CHECK MOBILE NUMBER LENGTH
    IF length(mobile_no) <> 10 THEN
        RAISE EXCEPTION 'Mobile number % length is invalid', mobile_no;
    end if;
    
    -- CHECK IF MOBILE NUMBER ALREADY EXIST
    SELECT id into lender_id from lendenapp_customuser where mobile_number = mobile_no;
    IF lender_id IS NOT NULL THEN
        RAISE EXCEPTION 'Mobile number % already exists', mobile_no;
    end if;

    investor_id = 'SANJ' || generate_random_number_with_digits(6);
    lender_pan = 'ZAMPA' || generate_random_number_with_digits(4) || 'S';
    email = 'sanjog' || generate_random_number_with_digits(4) || '@gmail.com';
    lender_name = 'SANJOG' || generate_random_number_with_digits(4);
    acc_no = 'LENZ' || generate_random_number_with_digits(12);
    track_id = '2410' || generate_random_number_with_digits(12);
    track_id_rekyc = '2410' || generate_random_number_with_digits(12);
    bank_acc_no = generate_random_number_with_digits(15);
    lender_checklist = '{''web_version'': ''3.0.0'', ''android_version'': ''4.1.3'', ''ios_version'': ''4.0.7'', ''completed_steps'': [''ID DETAIL'', ''LIVE KYC'', ''LEGAL AUTHORIZATION'', ''BANK ACCOUNT'', ''FMPP SKIPPED''], ''last_updated'': ''2024-10-30 11:23:51.625831'', ''account_status'': ''LISTED''}';
    
    -- CUSTOMUSER
    
    INSERT INTO lendenapp_customuser (user_id, password, encoded_pan, encoded_aadhar, encoded_mobile, 
                                      encoded_email, ucic_code, mobile_number, pan, first_name, middle_name, 
                                      last_name, email, email_verification, dob, gender, marital_status, 
                                      aadhar, gross_annual_income, type, device_id, is_active, last_login, 
                                      created_date, modified_date, is_migrated, adid)
    VALUES (investor_id, 'pbkdf2_sha256$24000$RhraFt2kjJ0E$c9vcpofJac0RqCYFM9A6DF+C8RhPv1DGgc5wZqxaoBY=', lender_pan, null,
            mobile_no, email, null, mobile_no, lender_pan, lender_name, null,
            null, email, TRUE, '2000-12-27', 'Male', 'Single', null, '10000',
            'INDIVIDUAL', null, TRUE, null,  now(), now(), FALSE, null);

    raise notice 'user_id %', investor_id;

    SELECT id into user_pk from lendenapp_customuser where mobile_number = mobile_no;
    
--     -- USER SOURCE GROUP
--     INSERT INTO lendenapp_user_source_group (user_id, source_id, channel_partner_id, status, created_at, updated_at, group_id)
--     VALUES (user_pk, 7, null, 'ACTIVE', now(), now(), 6);
--     
--     -- CUSTOMUSER GROUPS
--     INSERT INTO lendenapp_customuser_groups (customuser_id, group_id, source_id)
--     VALUES (user_pk, 6, null);
-- 
--     SELECT id into user_source_id from lendenapp_user_source_group where user_id=user_pk;
--     
--     -- USER KYC
--     INSERT INTO lendenapp_userkyc (tracking_id, status, poi_name, poa_name, json_response, service_type,
--                                    user_kyc_consent, task_id, user_id, user_source_group_id, created_date,
--                                    updated_date, event_status, provider, event_code, status_code)
--     VALUES (track_id, 'COMPLETED', null, null, null, 'INITIATE KYC',
--             TRUE, null, user_pk, user_source_id, now(), now(),
--             null, null, null, null);
--     
--     -- USER KYC TRACKER
--     INSERT INTO lendenapp_userkyctracker (tracking_id, status, kyc_type, next_kyc_date, risk_type, kyc_source, 
--                                           is_latest_kyc, task_id, user_id, next_due_diligence_date, aml_category, 
--                                           user_source_group_id, created_date, updated_date, is_cersai_uploaded) 
--     VALUES (track_id, 'SUCCESS', 'LIVE KYC', now()::DATE, null, 'MANUAL',
--             false, null, user_pk, null, 'APPROVED', user_source_id,
--             now(), now(), false);
--     
--     INSERT INTO lendenapp_userkyctracker (tracking_id, status, kyc_type, next_kyc_date, risk_type, kyc_source, 
--                                           is_latest_kyc, task_id, user_id, next_due_diligence_date, aml_category, 
--                                           user_source_group_id, created_date, updated_date, is_cersai_uploaded) 
--     VALUES (track_id_rekyc, 'SUCCESS', 'RE KYC', '2030-10-31', null, 'MANUAL',
--             false, null, user_pk, null, null, user_source_id,
--             now(), now(), false);
--     
--     -- BANKACCOUNT
--     INSERT INTO lendenapp_bankaccount (user_id, task_id, number, type, ifsc_code, bank_id, name, purpose, cashfree_dtm,
--                                        is_active, encoded_number, created_date, updated_date, user_source_group_id,
--                                        name_match_score, name_match_result)
--     VALUES (user_pk, null, bank_acc_no, 'SAVINGS', 'YESB0000876', 1911, lender_name,
--             'PRIMARY', now(), TRUE, null, now(), now(),
--             user_source_id, null, null);
-- 
--     SELECT id INTO bank_acc_id from lendenapp_bankaccount where user_source_group_id=user_source_id;
--     
--     -- ACCOUNT
--     INSERT INTO lendenapp_account (user_id, status, number, action, balance, action_amount, previous_balance, bank_account_id,
--                                    task_id, user_source_group_id, created_date, updated_date, listed_date)
--     VALUES (user_pk, 'LISTED', acc_no, null, 0, 0, 0, bank_acc_id,
--             null, user_source_id, now(), now(), now()::DATE);
--     
--     -- TASK
--     INSERT INTO lendenapp_task (checklist, assigned_by_id, created_by_id, user_source_group_id)
--     VALUES (lender_checklist, user_pk, user_pk, user_source_id);
--     
--     -- DOCUMENT
--     INSERT INTO lendenapp_document (type, file, description, user_id, task_id, user_source_group_id,
--                                     created_date, modified_date, remark)
--     VALUES ('authorization_letter', 'documents/2024/09/13/1348BDE8B056D9F686BD89A4.pdf', null, user_pk,
--             null, user_source_id, now(), now(), 'SUBMITTED');
-- 
--     INSERT INTO lendenapp_document (type, file, description, user_id, task_id, user_source_group_id,
--                                     created_date, modified_date, remark)
--     VALUES ('lender_agreement', 'documents/2024/09/13/2A71CFACA40A326CC54651F9.pdf', null, user_pk,
--             null, user_source_id, now(), now(), 'SUBMITTED');

END;
$_$;


ALTER PROCEDURE public.prc_create_retail_lender(IN mobile_no character varying) OWNER TO devmultilenden;

--
-- TOC entry 1351 (class 1255 OID 18950)
-- Name: prc_fetch_live_and_funded_loan_count(); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_fetch_live_and_funded_loan_count()
    LANGUAGE plpgsql
    AS $_$
	declare 
		v_live_loan_count BIGINT;
		v_funded_loan_count BIGINT;
	
	BEGIN

		select count(*) into v_funded_loan_count from qafmpp.t_investor_scheme tis 
		join qafmpp.t_dpis_details tdd on tdd.investor_scheme_id = tis.id 
		join qafmpp.t_cig_details tcd on tcd.dpis_id = tdd.dpis_id
		join qafmpp.t_cig tc on tc.id = tcd.cig_id 
		where tis.investment_type_id = 194 and tis.partner_code_id = 49 and tc.created_dtm  > NOW() - INTERVAL '30 DAY' 
		and tc.is_cig_disbursed and not tc.is_cancelled
		and tis.deleted IS NULL and tdd.deleted IS NULL and tcd.deleted IS NULL 
		and tc.deleted IS NULL;	
		
		SELECT COUNT(*) into v_live_loan_count
		FROM qafmpp.t_cig
		WHERE is_cig_disbursed = FALSE
		  AND funding_stopped = FALSE
		  AND is_cancelled = FALSE
		  AND is_closed = FALSE
		  AND is_modified_roi = FALSE
		  AND is_app_visible = TRUE
		  AND is_sold_off = FALSE
		  AND deleted IS NULL
		  AND loan_id ~ '^[^_]+$'
		  AND amount_to_be_funded > 
		      CASE 
		          WHEN is_modified_roi = TRUE THEN investment_amount
		          ELSE investment_amount + 1000
		      END;

		 
		 raise notice 'live loan count = %, funded loan count = %', v_live_loan_count, v_funded_loan_count;
		
	END;
$_$;


ALTER PROCEDURE public.prc_fetch_live_and_funded_loan_count() OWNER TO devmultilenden;

--
-- TOC entry 1354 (class 1255 OID 1963094)
-- Name: prc_fetch_live_and_funded_loan_count_prod(); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.prc_fetch_live_and_funded_loan_count_prod()
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        v_live_loan_count BIGINT;
       v_funded_loan_count BIGINT;
       v_max_id BIGINT;
    BEGIN

       select count(*) into v_funded_loan_count from t_investor_scheme tis
       join t_dpis_details tdd on tdd.investor_scheme_id = tis.id
       join t_cig_details tcd on tcd.dpis_id = tdd.dpis_id
       join t_cig tc on tc.id = tcd.cig_id
       where tis.investment_type_id = 194 and tis.partner_code_id = 49 and tc.created_dtm  > NOW() - INTERVAL '30 DAY'
       and tc.is_cig_disbursed and not tc.is_cancelled
       and tis.deleted IS NULL and tdd.deleted IS NULL and tcd.deleted IS NULL
       and tc.deleted IS NULL;

       SELECT COUNT(*) into v_live_loan_count
       FROM t_cig
       WHERE is_cig_disbursed = FALSE
         AND funding_stopped = FALSE
         AND is_cancelled = FALSE
         AND is_closed = FALSE
         --AND is_modified_roi = FALSE
         AND is_app_visible = TRUE
         AND is_sold_off = FALSE
         AND deleted IS NULL
         AND loan_id ~ '^[^_]+$'
         and investment_amount < amount_to_be_funded
         /*AND amount_to_be_funded >
             CASE
                 WHEN is_modified_roi = TRUE THEN investment_amount
                 ELSE investment_amount + 1000
             end*/
         and created_dtm <= (
           select coalesce((((now() + interval '5:30 hours')::date)-date_difference +cig_to_time::text::time)- interval '5:30 hours',now())
           from t_cig_funding_master where scheme_type = 'MANUAL_LENDING'
           AND TO_CHAR((now() + interval '5:30 hours'),'HH24:MI:SS')::TIME BETWEEN from_time and to_time
           );

       /*select total_count --into v_live_loan_count
       from (
       SELECT COUNT(*)  as "total_count",
       sum(case when (amount_to_be_funded - investment_amount >= 1000) then 1 else 0 end) as "1000",
       sum(case when (amount_to_be_funded - investment_amount >= 500) then 1 else 0 end) as "500",
       sum(case when (amount_to_be_funded - investment_amount >= 250) then 1 else 0 end) as "250"
       FROM t_cig
       WHERE is_cig_disbursed = FALSE
         AND funding_stopped = FALSE
         AND is_cancelled = FALSE
         AND is_closed = FALSE
         --AND is_modified_roi = FALSE
         AND is_app_visible = TRUE
         AND is_sold_off = FALSE
         AND deleted IS NULL
         AND loan_id ~ '^[^_]+$'
         and investment_amount < amount_to_be_funded
        /* AND amount_to_be_funded >
             CASE
                 WHEN is_modified_roi = TRUE THEN investment_amount
                 ELSE investment_amount + 1000
             end*/
         and created_dtm <= (
           select coalesce((((now() + interval '5:30 hours')::date)-date_difference +cig_to_time::text::time)- interval '5:30 hours',now())
           from t_cig_funding_master where scheme_type = 'MANUAL_LENDING'
           AND TO_CHAR((now() + interval '5:30 hours'),'HH24:MI:SS')::TIME BETWEEN from_time and to_time
           )
       ) as "data";*/


       select coalesce(max(id), 0) into v_max_id from investors.lendenapp_analytical_data lad;

       insert into investors.lendenapp_analytical_data (id, key, value, created_date, updated_date)
       values (v_max_id+1, 'live_loan_count', v_live_loan_count, now(), now()),
       (v_max_id+2, 'funded_loan_count', v_funded_loan_count, now(), now());

    EXCEPTION
          WHEN OTHERS THEN
            DECLARE
          my_ex_state text;
          my_ex_message text;
          my_ex_detail text;
          my_ex_hint text;
          my_ex_ctx text;
        BEGIN
            raise notice 'ERROR OCCURED';
            GET STACKED DIAGNOSTICS
              my_ex_state   = RETURNED_SQLSTATE,
              my_ex_message = MESSAGE_TEXT,
              my_ex_detail  = PG_EXCEPTION_DETAIL,
              my_ex_hint    = PG_EXCEPTION_HINT,
              my_ex_ctx     = PG_EXCEPTION_CONTEXT
            ;
            INSERT INTO t_error_log (sp_name,err_state,err_message,err_details,err_hint,err_context,created_dtm,updated_dtm) values
                                     ('PRC_FETCH_LIVE_AND_FUNDED_LOAN_COUNT',my_ex_state,my_ex_message,my_ex_detail,my_ex_hint,my_ex_ctx,now(),now());
             raise info 'THE FOLLOWING ERROR OCCURED % % % % %', my_ex_state,my_ex_message,my_ex_detail,my_ex_hint,my_ex_ctx;

        END;
    END;

$_$;


ALTER PROCEDURE public.prc_fetch_live_and_funded_loan_count_prod() OWNER TO devmultilenden;

--
-- TOC entry 1252 (class 1255 OID 18951)
-- Name: return_one(); Type: FUNCTION; Schema: public; Owner: devmultilenden
--

CREATE FUNCTION public.return_one() RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN 1;
END;
$$;


ALTER FUNCTION public.return_one() OWNER TO devmultilenden;

--
-- TOC entry 1353 (class 1255 OID 18952)
-- Name: test_exception(bigint); Type: PROCEDURE; Schema: public; Owner: devmultilenden
--

CREATE PROCEDURE public.test_exception(IN v_user_pk bigint)
    LANGUAGE plpgsql
    AS $$
	DECLARE 
        v_user_record  record;
	begin
        raise info 'Processing for CP-id: %', v_user_pk;
       
        INSERT INTO lendenapp_convertedreferral(id,user_id,referred_by_id,created_date,updated_date)
        SELECT id,user_id,referred_by_id,created_date,updated_date
            FROM qamono.lendenapp_convertedreferral WHERE user_id = 752292;
   
        raise info  'hello6';
        raise info 'inserted --------';

	EXCEPTION
	    WHEN OTHERS THEN
	        raise info 'inside exception';
	
	END;
$$;


ALTER PROCEDURE public.test_exception(IN v_user_pk bigint) OWNER TO devmultilenden;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 1240 (class 1259 OID 1971353)
-- Name: ath_group; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.ath_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.ath_group OWNER TO devmultilenden;

--
-- TOC entry 10158 (class 0 OID 0)
-- Dependencies: 1240
-- Name: COLUMN ath_group.id; Type: COMMENT; Schema: public; Owner: devmultilenden
--

COMMENT ON COLUMN public.ath_group.id IS 'Column for id with data type integer.';


--
-- TOC entry 10159 (class 0 OID 0)
-- Dependencies: 1240
-- Name: COLUMN ath_group.name; Type: COMMENT; Schema: public; Owner: devmultilenden
--

COMMENT ON COLUMN public.ath_group.name IS 'Column for name with data type character varying(150).';


--
-- TOC entry 226 (class 1259 OID 727933)
-- Name: auth_group; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO usrinvoswrt;

--
-- TOC entry 225 (class 1259 OID 727932)
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_group_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10160 (class 0 OID 0)
-- Dependencies: 225
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- TOC entry 1080 (class 1259 OID 1949022)
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO devmultilenden;

--
-- TOC entry 1079 (class 1259 OID 1949021)
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_permission_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10161 (class 0 OID 0)
-- Dependencies: 1079
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- TOC entry 1078 (class 1259 OID 1949004)
-- Name: auth_user; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


ALTER TABLE public.auth_user OWNER TO devmultilenden;

--
-- TOC entry 1077 (class 1259 OID 1949003)
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.auth_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_user_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10162 (class 0 OID 0)
-- Dependencies: 1077
-- Name: auth_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.auth_user_id_seq OWNED BY public.auth_user.id;


--
-- TOC entry 258 (class 1259 OID 964180)
-- Name: authtoken_token; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.authtoken_token (
    key character varying(40) NOT NULL,
    created timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.authtoken_token OWNER TO usrinvoswrt;

--
-- TOC entry 836 (class 1259 OID 1539379)
-- Name: lendenapp_day_wise_fee_bifurcation; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_day_wise_fee_bifurcation (
    user_id character varying(100),
    amount numeric(18,2),
    purpose character varying(10),
    transaction_date date,
    partner_code character varying(10),
    status character varying(20)
);


ALTER TABLE public.lendenapp_day_wise_fee_bifurcation OWNER TO devmultilenden;

--
-- TOC entry 1239 (class 1259 OID 1961593)
-- Name: daily_fee_summary; Type: MATERIALIZED VIEW; Schema: public; Owner: devmultilenden
--

CREATE MATERIALIZED VIEW public.daily_fee_summary AS
 SELECT lendenapp_day_wise_fee_bifurcation.user_id,
    lendenapp_day_wise_fee_bifurcation.transaction_date,
    lendenapp_day_wise_fee_bifurcation.partner_code,
    sum(
        CASE
            WHEN ((lendenapp_day_wise_fee_bifurcation.purpose)::text = 'FF001'::text) THEN lendenapp_day_wise_fee_bifurcation.amount
            ELSE (0)::numeric
        END) AS ff,
    sum(
        CASE
            WHEN ((lendenapp_day_wise_fee_bifurcation.purpose)::text = 'CF001'::text) THEN lendenapp_day_wise_fee_bifurcation.amount
            ELSE (0)::numeric
        END) AS cf,
    sum(
        CASE
            WHEN ((lendenapp_day_wise_fee_bifurcation.purpose)::text = 'RF001'::text) THEN lendenapp_day_wise_fee_bifurcation.amount
            ELSE (0)::numeric
        END) AS rf
   FROM public.lendenapp_day_wise_fee_bifurcation
  WHERE ((lendenapp_day_wise_fee_bifurcation.transaction_date = (CURRENT_DATE - 1)) AND ((lendenapp_day_wise_fee_bifurcation.status)::text = 'PROCESSING'::text))
  GROUP BY lendenapp_day_wise_fee_bifurcation.user_id, lendenapp_day_wise_fee_bifurcation.transaction_date, lendenapp_day_wise_fee_bifurcation.partner_code
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.daily_fee_summary OWNER TO devmultilenden;

--
-- TOC entry 757 (class 1259 OID 1260864)
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO devmultilenden;

--
-- TOC entry 756 (class 1259 OID 1260863)
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 755 (class 1259 OID 1260856)
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO devmultilenden;

--
-- TOC entry 754 (class 1259 OID 1260855)
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 792 (class 1259 OID 1529208)
-- Name: employee; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.employee (
    id integer NOT NULL,
    name character varying(50),
    gender character varying(10) NOT NULL,
    salary numeric(10,2),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.employee OWNER TO devmultilenden;

--
-- TOC entry 791 (class 1259 OID 1529207)
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10163 (class 0 OID 0)
-- Dependencies: 791
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.employee_id_seq OWNED BY public.employee.id;


--
-- TOC entry 734 (class 1259 OID 982139)
-- Name: fcm_django_fcmdevice; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.fcm_django_fcmdevice (
    id bigint NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    device_id character varying(30),
    registration_id text,
    type character varying(10) NOT NULL,
    user_id integer NOT NULL,
    user_source_group_id bigint,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    appsflyer_id character varying(50)
);


ALTER TABLE public.fcm_django_fcmdevice OWNER TO devmultilenden;

--
-- TOC entry 733 (class 1259 OID 982138)
-- Name: fcm_django_fcmdevice_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.fcm_django_fcmdevice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fcm_django_fcmdevice_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10164 (class 0 OID 0)
-- Dependencies: 733
-- Name: fcm_django_fcmdevice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.fcm_django_fcmdevice_id_seq OWNED BY public.fcm_django_fcmdevice.id;


--
-- TOC entry 254 (class 1259 OID 923877)
-- Name: lendenapp_account; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_account (
    id integer NOT NULL,
    user_id integer NOT NULL,
    status character varying(10),
    number character varying(25),
    action character varying(10),
    balance numeric(18,4) DEFAULT 0.0 NOT NULL,
    action_amount numeric(18,4) DEFAULT 0.0,
    previous_balance numeric(18,4) DEFAULT 0.0,
    bank_account_id integer,
    task_id integer,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    listed_date date
);


ALTER TABLE public.lendenapp_account OWNER TO usrinvoswrt;

--
-- TOC entry 236 (class 1259 OID 736562)
-- Name: lendenapp_channelpartner; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_channelpartner (
    id integer NOT NULL,
    partner_id character varying(10) NOT NULL,
    type character varying(50) NOT NULL,
    status character varying(50) NOT NULL,
    user_id integer NOT NULL,
    referred_by_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    listed_date date,
    registration_number character varying(20)
);


ALTER TABLE public.lendenapp_channelpartner OWNER TO usrinvoswrt;

--
-- TOC entry 234 (class 1259 OID 735486)
-- Name: lendenapp_customuser; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_customuser (
    id integer NOT NULL,
    user_id character varying(20),
    password character varying(100),
    encoded_pan character varying(100),
    encoded_aadhar character varying(150),
    encoded_mobile character varying(100),
    encoded_email character varying(200),
    ucic_code character varying(12),
    mobile_number character varying(15),
    pan character varying(15),
    first_name character varying(100),
    middle_name character varying(10),
    last_name character varying(10),
    email character varying(100),
    email_verification boolean DEFAULT false NOT NULL,
    dob date,
    gender character varying(6),
    marital_status character varying(10),
    aadhar character varying(25),
    gross_annual_income character varying(25),
    type character varying(30),
    device_id character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    last_login timestamp with time zone,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_migrated boolean,
    adid character varying(100),
    ckycr_number character varying(20),
    is_valid_pan boolean DEFAULT false,
    mnrl_status character varying(50) DEFAULT 'APPROVED'::character varying
);


ALTER TABLE public.lendenapp_customuser OWNER TO usrinvoswrt;

--
-- TOC entry 228 (class 1259 OID 727942)
-- Name: lendenapp_source; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_source (
    id integer NOT NULL,
    source_name character varying(15) NOT NULL,
    source_full_name character varying(100),
    name_check boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_source OWNER TO usrinvoswrt;

--
-- TOC entry 240 (class 1259 OID 801246)
-- Name: lendenapp_task; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_task (
    id integer NOT NULL,
    checklist text,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    assigned_by_id integer,
    created_by_id integer NOT NULL,
    user_source_group_id integer
);


ALTER TABLE public.lendenapp_task OWNER TO usrinvoswrt;

--
-- TOC entry 238 (class 1259 OID 745144)
-- Name: lendenapp_user_source_group; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_user_source_group (
    id integer NOT NULL,
    user_id integer NOT NULL,
    source_id integer NOT NULL,
    channel_partner_id integer,
    status character varying(10),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    group_id integer NOT NULL,
    CONSTRAINT lendenapp_user_source_group_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('CLOSED'::character varying)::text])))
);


ALTER TABLE public.lendenapp_user_source_group OWNER TO usrinvoswrt;

--
-- TOC entry 758 (class 1259 OID 1260942)
-- Name: investor_dashboard_view; Type: MATERIALIZED VIEW; Schema: public; Owner: devmultilenden
--

CREATE MATERIALIZED VIEW public.investor_dashboard_view AS
 SELECT lc2.referred_by_id AS mcp_id,
    lc3.id AS cp_id,
    lc3.user_id AS cp_user_id,
    lc3.first_name AS cp_name,
    lc.id AS investor_id,
    lc.user_id AS investor_user_id,
    lc.first_name AS investor_name,
    lc.encoded_mobile AS mobile_number,
    lc.encoded_email AS email,
    date(lt.created_date) AS created_date,
    lc2.type AS partner_type,
    lc2.partner_id,
    la.balance,
    la.status AS account_status,
    lusg.id AS user_source_id,
    lt.checklist,
    la.number AS account_number,
    lc.type AS inv_type
   FROM ((((((public.lendenapp_user_source_group lusg
     JOIN public.lendenapp_source ls ON ((ls.id = lusg.source_id)))
     JOIN public.lendenapp_channelpartner lc2 ON ((lc2.id = lusg.channel_partner_id)))
     JOIN public.lendenapp_customuser lc ON ((lc.id = lusg.user_id)))
     JOIN public.lendenapp_customuser lc3 ON ((lc3.id = lc2.user_id)))
     JOIN public.lendenapp_task lt ON ((lt.user_source_group_id = lusg.id)))
     JOIN public.lendenapp_account la ON ((la.user_source_group_id = lusg.id)))
  WHERE (ls.id = ANY (ARRAY[3, 8, 11, 21]))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.investor_dashboard_view OWNER TO devmultilenden;

--
-- TOC entry 1076 (class 1259 OID 1883486)
-- Name: lendenapp_job_master; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_job_master (
    id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    job_name character varying(100) NOT NULL,
    is_job_enabled boolean DEFAULT false NOT NULL,
    is_batch_enabled boolean DEFAULT false NOT NULL
);


ALTER TABLE public.lendenapp_job_master OWNER TO devmultilenden;

--
-- TOC entry 1075 (class 1259 OID 1883485)
-- Name: job_status_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.job_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_status_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10165 (class 0 OID 0)
-- Dependencies: 1075
-- Name: job_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.job_status_id_seq OWNED BY public.lendenapp_job_master.id;


--
-- TOC entry 753 (class 1259 OID 1236166)
-- Name: lendenap_user_states_final; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenap_user_states_final (
    id integer NOT NULL,
    pan character varying(30),
    encoded_pan character varying,
    user_id character varying(50),
    state character varying
);


ALTER TABLE public.lendenap_user_states_final OWNER TO devmultilenden;

--
-- TOC entry 752 (class 1259 OID 1236165)
-- Name: lendenap_user_states_final_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenap_user_states_final_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenap_user_states_final_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10167 (class 0 OID 0)
-- Dependencies: 752
-- Name: lendenap_user_states_final_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenap_user_states_final_id_seq OWNED BY public.lendenap_user_states_final.id;


--
-- TOC entry 253 (class 1259 OID 923876)
-- Name: lendenapp_account_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_account_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10168 (class 0 OID 0)
-- Dependencies: 253
-- Name: lendenapp_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_account_id_seq OWNED BY public.lendenapp_account.id;


--
-- TOC entry 260 (class 1259 OID 964301)
-- Name: lendenapp_address; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_address (
    id bigint NOT NULL,
    type character varying(15),
    location character varying(255) NOT NULL,
    city character varying(50) NOT NULL,
    state character varying(50) NOT NULL,
    country character varying(50) NOT NULL,
    pin character varying(8) NOT NULL,
    landmark character varying(255) NOT NULL,
    email character varying(100),
    is_verified boolean DEFAULT false NOT NULL,
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encoded_email character varying(255),
    user_id integer
);


ALTER TABLE public.lendenapp_address OWNER TO usrinvoswrt;

--
-- TOC entry 259 (class 1259 OID 964300)
-- Name: lendenapp_address_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_address_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10169 (class 0 OID 0)
-- Dependencies: 259
-- Name: lendenapp_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_address_id_seq OWNED BY public.lendenapp_address.id;


--
-- TOC entry 835 (class 1259 OID 1539330)
-- Name: lendenapp_address_v2; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_address_v2 (
    id bigint NOT NULL,
    type character varying(15),
    location character varying(255) NOT NULL,
    city character varying(50) NOT NULL,
    state character varying(50) NOT NULL,
    country character varying(50) NOT NULL,
    pin character varying(8) NOT NULL,
    landmark character varying(255),
    email character varying(100),
    is_verified boolean DEFAULT false NOT NULL,
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encoded_email character varying(255),
    user_id integer
);


ALTER TABLE public.lendenapp_address_v2 OWNER TO devmultilenden;

--
-- TOC entry 834 (class 1259 OID 1539329)
-- Name: lendenapp_address_v2_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_address_v2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_address_v2_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10170 (class 0 OID 0)
-- Dependencies: 834
-- Name: lendenapp_address_v2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_address_v2_id_seq OWNED BY public.lendenapp_address_v2.id;


--
-- TOC entry 785 (class 1259 OID 1525903)
-- Name: lendenapp_aml; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_aml (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_source_group_id integer,
    tracking_id character varying(50),
    entity_source character varying(10),
    matched_name character varying(250),
    name_score smallint,
    dob_score smallint,
    pan_score smallint,
    address_score smallint,
    is_pep boolean DEFAULT false NOT NULL,
    match_status character varying(10),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    matched_dob character varying(25),
    matched_pan character varying(400),
    matched_address character varying(400),
    kyc_tracking_id character varying(50)
);


ALTER TABLE public.lendenapp_aml OWNER TO devmultilenden;

--
-- TOC entry 784 (class 1259 OID 1525902)
-- Name: lendenapp_aml_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_aml_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_aml_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10171 (class 0 OID 0)
-- Dependencies: 784
-- Name: lendenapp_aml_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_aml_id_seq OWNED BY public.lendenapp_aml.id;


--
-- TOC entry 787 (class 1259 OID 1525924)
-- Name: lendenapp_amltracker; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_amltracker (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    tracking_id character varying(50),
    aml_check boolean DEFAULT false NOT NULL,
    is_pep boolean DEFAULT false NOT NULL,
    is_uapa boolean DEFAULT false NOT NULL,
    is_unsc boolean DEFAULT false NOT NULL,
    match_status character varying(10),
    status character varying(10),
    remark character varying(100),
    next_due_diligence_date date,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_profile_upload boolean DEFAULT false NOT NULL
);


ALTER TABLE public.lendenapp_amltracker OWNER TO devmultilenden;

--
-- TOC entry 786 (class 1259 OID 1525923)
-- Name: lendenapp_amltracker_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_amltracker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_amltracker_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10172 (class 0 OID 0)
-- Dependencies: 786
-- Name: lendenapp_amltracker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_amltracker_id_seq OWNED BY public.lendenapp_amltracker.id;


--
-- TOC entry 789 (class 1259 OID 1528105)
-- Name: lendenapp_analytical_data; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_analytical_data (
    id integer NOT NULL,
    key character varying(50),
    value integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    cohort_config_id integer
);


ALTER TABLE public.lendenapp_analytical_data OWNER TO devmultilenden;

--
-- TOC entry 788 (class 1259 OID 1528104)
-- Name: lendenapp_analytical_data_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_analytical_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_analytical_data_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10173 (class 0 OID 0)
-- Dependencies: 788
-- Name: lendenapp_analytical_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_analytical_data_id_seq OWNED BY public.lendenapp_analytical_data.id;


--
-- TOC entry 749 (class 1259 OID 1137894)
-- Name: lendenapp_app_rating; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_app_rating (
    id integer NOT NULL,
    rating smallint,
    action public.user_action,
    remark character varying(200),
    screen_name character varying(100),
    source public.user_source,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_app_rating OWNER TO devmultilenden;

--
-- TOC entry 748 (class 1259 OID 1137893)
-- Name: lendenapp_app_rating_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_app_rating_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_app_rating_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10175 (class 0 OID 0)
-- Dependencies: 748
-- Name: lendenapp_app_rating_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_app_rating_id_seq OWNED BY public.lendenapp_app_rating.id;


--
-- TOC entry 869 (class 1259 OID 1752350)
-- Name: lendenapp_application_config; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_application_config (
    id integer NOT NULL,
    config_type text NOT NULL,
    logical_reference text NOT NULL,
    config_key text NOT NULL,
    config_value jsonb NOT NULL,
    is_active boolean DEFAULT true,
    created_dtm timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dtm timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    db_only boolean DEFAULT false
);


ALTER TABLE public.lendenapp_application_config OWNER TO devmultilenden;

--
-- TOC entry 868 (class 1259 OID 1752349)
-- Name: lendenapp_application_config_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_application_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_application_config_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10176 (class 0 OID 0)
-- Dependencies: 868
-- Name: lendenapp_application_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_application_config_id_seq OWNED BY public.lendenapp_application_config.id;


--
-- TOC entry 262 (class 1259 OID 964318)
-- Name: lendenapp_applicationinfo; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_applicationinfo (
    id bigint NOT NULL,
    version character varying(10),
    using_since timestamp with time zone,
    comment text,
    user_id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_applicationinfo OWNER TO usrinvoswrt;

--
-- TOC entry 261 (class 1259 OID 964317)
-- Name: lendenapp_applicationinfo_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_applicationinfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_applicationinfo_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10177 (class 0 OID 0)
-- Dependencies: 261
-- Name: lendenapp_applicationinfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_applicationinfo_id_seq OWNED BY public.lendenapp_applicationinfo.id;


--
-- TOC entry 230 (class 1259 OID 727986)
-- Name: lendenapp_bank; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_bank (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    is_operational boolean DEFAULT false NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_bank OWNER TO usrinvoswrt;

--
-- TOC entry 229 (class 1259 OID 727985)
-- Name: lendenapp_bank_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_bank_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_bank_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10178 (class 0 OID 0)
-- Dependencies: 229
-- Name: lendenapp_bank_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_bank_id_seq OWNED BY public.lendenapp_bank.id;


--
-- TOC entry 242 (class 1259 OID 801592)
-- Name: lendenapp_bankaccount; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_bankaccount (
    id integer NOT NULL,
    user_id integer NOT NULL,
    task_id integer,
    number character varying(30) NOT NULL,
    type character varying(15),
    ifsc_code character varying(15),
    bank_id integer,
    name character varying(100),
    purpose character varying(15),
    cashfree_dtm timestamp with time zone,
    is_active boolean DEFAULT true,
    encoded_number character varying(255),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_source_group_id integer,
    name_match_score character varying(6),
    name_match_result character varying(30),
    is_valid_account boolean DEFAULT false,
    mandate_id integer,
    mandate_status character varying(15),
    update_count integer DEFAULT 0
);


ALTER TABLE public.lendenapp_bankaccount OWNER TO usrinvoswrt;

--
-- TOC entry 241 (class 1259 OID 801591)
-- Name: lendenapp_bankaccount_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_bankaccount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_bankaccount_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10179 (class 0 OID 0)
-- Dependencies: 241
-- Name: lendenapp_bankaccount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_bankaccount_id_seq OWNED BY public.lendenapp_bankaccount.id;


--
-- TOC entry 771 (class 1259 OID 1456777)
-- Name: lendenapp_banklist; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_banklist (
    id integer NOT NULL,
    bank_name character varying(100) NOT NULL,
    bank_code character varying NOT NULL,
    tpv_approved boolean DEFAULT true,
    bank_icon character varying(255),
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now()
);


ALTER TABLE public.lendenapp_banklist OWNER TO devmultilenden;

--
-- TOC entry 770 (class 1259 OID 1456776)
-- Name: lendenapp_banklist_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_banklist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_banklist_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10180 (class 0 OID 0)
-- Dependencies: 770
-- Name: lendenapp_banklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_banklist_id_seq OWNED BY public.lendenapp_banklist.id;


--
-- TOC entry 1070 (class 1259 OID 1883378)
-- Name: lendenapp_campaign; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_campaign (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(50) NOT NULL,
    reward_amount numeric(18,4) NOT NULL,
    rule jsonb,
    expiry_days integer,
    active boolean DEFAULT true,
    start_date date,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    end_date date,
    wallet_id integer,
    campaign_id integer
);


ALTER TABLE public.lendenapp_campaign OWNER TO devmultilenden;

--
-- TOC entry 1069 (class 1259 OID 1883377)
-- Name: lendenapp_campaign_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_campaign_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_campaign_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10181 (class 0 OID 0)
-- Dependencies: 1069
-- Name: lendenapp_campaign_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_campaign_id_seq OWNED BY public.lendenapp_campaign.id;


--
-- TOC entry 1074 (class 1259 OID 1883438)
-- Name: lendenapp_campaign_wallet; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_campaign_wallet (
    id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    total_amount numeric(18,4) DEFAULT 0 NOT NULL,
    available_amount numeric(18,4) DEFAULT 0 NOT NULL,
    redeemed_amount numeric(18,4) DEFAULT 0 NOT NULL,
    expired_amount numeric(18,4) DEFAULT 0 NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now()
);


ALTER TABLE public.lendenapp_campaign_wallet OWNER TO devmultilenden;

--
-- TOC entry 1073 (class 1259 OID 1883437)
-- Name: lendenapp_campaign_wallet_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_campaign_wallet_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_campaign_wallet_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10182 (class 0 OID 0)
-- Dependencies: 1073
-- Name: lendenapp_campaign_wallet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_campaign_wallet_id_seq OWNED BY public.lendenapp_campaign_wallet.id;


--
-- TOC entry 235 (class 1259 OID 736561)
-- Name: lendenapp_channelpartner_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_channelpartner_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_channelpartner_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10183 (class 0 OID 0)
-- Dependencies: 235
-- Name: lendenapp_channelpartner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_channelpartner_id_seq OWNED BY public.lendenapp_channelpartner.id;


--
-- TOC entry 730 (class 1259 OID 982103)
-- Name: lendenapp_ckycthirdpartydata; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_ckycthirdpartydata (
    id bigint NOT NULL,
    action character varying(20) NOT NULL,
    json_request jsonb,
    json_response jsonb NOT NULL,
    status character varying(20) NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    task_id integer,
    user_id bigint NOT NULL,
    user_source_group_id bigint NOT NULL
);


ALTER TABLE public.lendenapp_ckycthirdpartydata OWNER TO devmultilenden;

--
-- TOC entry 729 (class 1259 OID 982102)
-- Name: lendenapp_ckycthirdpartydata_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_ckycthirdpartydata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_ckycthirdpartydata_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10184 (class 0 OID 0)
-- Dependencies: 729
-- Name: lendenapp_ckycthirdpartydata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_ckycthirdpartydata_id_seq OWNED BY public.lendenapp_ckycthirdpartydata.id;


--
-- TOC entry 798 (class 1259 OID 1533224)
-- Name: lendenapp_cohort_config; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_cohort_config (
    id integer NOT NULL,
    purpose_id integer NOT NULL,
    cohort_category character varying(30) NOT NULL,
    weightage integer NOT NULL,
    is_enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    config_values jsonb,
    modify_cohort boolean DEFAULT true
);


ALTER TABLE public.lendenapp_cohort_config OWNER TO devmultilenden;

--
-- TOC entry 797 (class 1259 OID 1533223)
-- Name: lendenapp_cohert_config_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_cohert_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_cohert_config_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10185 (class 0 OID 0)
-- Dependencies: 797
-- Name: lendenapp_cohert_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_cohert_config_id_seq OWNED BY public.lendenapp_cohort_config.id;


--
-- TOC entry 796 (class 1259 OID 1533199)
-- Name: lendenapp_cohort_purpose; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_cohort_purpose (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    is_enabled boolean DEFAULT false,
    add_cohort boolean DEFAULT true
);


ALTER TABLE public.lendenapp_cohort_purpose OWNER TO devmultilenden;

--
-- TOC entry 795 (class 1259 OID 1533198)
-- Name: lendenapp_cohert_purpose_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_cohert_purpose_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_cohert_purpose_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10186 (class 0 OID 0)
-- Dependencies: 795
-- Name: lendenapp_cohert_purpose_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_cohert_purpose_id_seq OWNED BY public.lendenapp_cohort_purpose.id;


--
-- TOC entry 728 (class 1259 OID 980030)
-- Name: lendenapp_communicationpreference; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_communicationpreference (
    id integer NOT NULL,
    type character varying(150),
    mail boolean,
    sms boolean,
    platform boolean,
    app boolean,
    status character varying(50) NOT NULL,
    activation_date timestamp with time zone,
    deactivation_date timestamp with time zone,
    creation_date timestamp with time zone,
    updation_date timestamp with time zone,
    user_id integer NOT NULL
);


ALTER TABLE public.lendenapp_communicationpreference OWNER TO usrinvoswrt;

--
-- TOC entry 727 (class 1259 OID 980029)
-- Name: lendenapp_communicationpreference_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_communicationpreference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_communicationpreference_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10187 (class 0 OID 0)
-- Dependencies: 727
-- Name: lendenapp_communicationpreference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_communicationpreference_id_seq OWNED BY public.lendenapp_communicationpreference.id;


--
-- TOC entry 246 (class 1259 OID 801657)
-- Name: lendenapp_convertedreferral; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_convertedreferral (
    id integer NOT NULL,
    user_id integer NOT NULL,
    referred_by_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_convertedreferral OWNER TO usrinvoswrt;

--
-- TOC entry 245 (class 1259 OID 801656)
-- Name: lendenapp_convertedreferral_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_convertedreferral_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_convertedreferral_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10189 (class 0 OID 0)
-- Dependencies: 245
-- Name: lendenapp_convertedreferral_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_convertedreferral_id_seq OWNED BY public.lendenapp_convertedreferral.id;


--
-- TOC entry 867 (class 1259 OID 1547492)
-- Name: lendenapp_counter; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_counter (
    id integer NOT NULL,
    updated_date timestamp without time zone DEFAULT now(),
    prefix character varying(10),
    last_used_number integer DEFAULT 0
);


ALTER TABLE public.lendenapp_counter OWNER TO devmultilenden;

--
-- TOC entry 866 (class 1259 OID 1547491)
-- Name: lendenapp_counter_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_counter_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_counter_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10190 (class 0 OID 0)
-- Dependencies: 866
-- Name: lendenapp_counter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_counter_id_seq OWNED BY public.lendenapp_counter.id;


--
-- TOC entry 872 (class 1259 OID 1875185)
-- Name: lendenapp_cp_staff; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_cp_staff (
    id integer NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_id integer,
    channel_partner_id integer,
    cp_id integer,
    is_active boolean,
    has_edit_access boolean
);


ALTER TABLE public.lendenapp_cp_staff OWNER TO devmultilenden;

--
-- TOC entry 871 (class 1259 OID 1875184)
-- Name: lendenapp_cp_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_cp_staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_cp_staff_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10191 (class 0 OID 0)
-- Dependencies: 871
-- Name: lendenapp_cp_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_cp_staff_id_seq OWNED BY public.lendenapp_cp_staff.id;


--
-- TOC entry 1082 (class 1259 OID 1949151)
-- Name: lendenapp_cp_staff_log; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_cp_staff_log (
    id integer NOT NULL,
    owner_cp_id integer NOT NULL,
    staff_id integer NOT NULL,
    user_id integer NOT NULL,
    user_source_group_id integer,
    activity character varying(55) NOT NULL,
    remark character varying(255),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone
);


ALTER TABLE public.lendenapp_cp_staff_log OWNER TO devmultilenden;

--
-- TOC entry 1081 (class 1259 OID 1949150)
-- Name: lendenapp_cp_staff_log_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_cp_staff_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_cp_staff_log_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10192 (class 0 OID 0)
-- Dependencies: 1081
-- Name: lendenapp_cp_staff_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_cp_staff_log_id_seq OWNED BY public.lendenapp_cp_staff_log.id;


--
-- TOC entry 244 (class 1259 OID 801623)
-- Name: lendenapp_customuser_groups; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_customuser_groups (
    id integer NOT NULL,
    customuser_id integer NOT NULL,
    group_id integer NOT NULL,
    source_id integer
);


ALTER TABLE public.lendenapp_customuser_groups OWNER TO usrinvoswrt;

--
-- TOC entry 243 (class 1259 OID 801622)
-- Name: lendenapp_customuser_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_customuser_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_customuser_groups_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10193 (class 0 OID 0)
-- Dependencies: 243
-- Name: lendenapp_customuser_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_customuser_groups_id_seq OWNED BY public.lendenapp_customuser_groups.id;


--
-- TOC entry 233 (class 1259 OID 735485)
-- Name: lendenapp_customuser_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_customuser_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_customuser_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10194 (class 0 OID 0)
-- Dependencies: 233
-- Name: lendenapp_customuser_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_customuser_id_seq OWNED BY public.lendenapp_customuser.id;


--
-- TOC entry 250 (class 1259 OID 865964)
-- Name: lendenapp_document; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_document (
    id integer NOT NULL,
    type character varying(50) NOT NULL,
    file character varying(100) NOT NULL,
    description character varying(100),
    user_id integer NOT NULL,
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    remark character varying(100),
    fiscal_year character varying(10)
);


ALTER TABLE public.lendenapp_document OWNER TO usrinvoswrt;

--
-- TOC entry 249 (class 1259 OID 865963)
-- Name: lendenapp_document_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_document_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_document_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10195 (class 0 OID 0)
-- Dependencies: 249
-- Name: lendenapp_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_document_id_seq OWNED BY public.lendenapp_document.id;


--
-- TOC entry 831 (class 1259 OID 1537911)
-- Name: lendenapp_filters_and_sort_logs; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_filters_and_sort_logs (
    id integer NOT NULL,
    filters text NOT NULL,
    sort_by text NOT NULL,
    "limit" integer,
    "offset" integer,
    user_source_group_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_filters_and_sort_logs OWNER TO devmultilenden;

--
-- TOC entry 830 (class 1259 OID 1537910)
-- Name: lendenapp_filters_and_sort_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_filters_and_sort_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_filters_and_sort_logs_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10196 (class 0 OID 0)
-- Dependencies: 830
-- Name: lendenapp_filters_and_sort_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_filters_and_sort_logs_id_seq OWNED BY public.lendenapp_filters_and_sort_logs.id;


--
-- TOC entry 802 (class 1259 OID 1534653)
-- Name: lendenapp_fmi_withdrawals; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_fmi_withdrawals (
    id integer NOT NULL,
    transaction_id character varying(50),
    fmi_txn_id character varying(50),
    amount numeric(18,4),
    status character(2),
    failure_reason character varying(500),
    credited_date timestamp without time zone,
    transaction_mode character varying(10),
    transaction_requested_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    utr character varying(30),
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    message_code character varying(12),
    processed_by_id integer,
    batch_number character varying(30),
    fmi_batch_number character varying(30)
);


ALTER TABLE public.lendenapp_fmi_withdrawals OWNER TO devmultilenden;

--
-- TOC entry 801 (class 1259 OID 1534652)
-- Name: lendenapp_fmi_withdrawals_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_fmi_withdrawals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_fmi_withdrawals_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10197 (class 0 OID 0)
-- Dependencies: 801
-- Name: lendenapp_fmi_withdrawals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_fmi_withdrawals_id_seq OWNED BY public.lendenapp_fmi_withdrawals.id;


--
-- TOC entry 290 (class 1259 OID 964736)
-- Name: lendenapp_historicalaccount; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_historicalaccount (
    history_id integer NOT NULL,
    history_type character varying(1) NOT NULL,
    history_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id integer NOT NULL,
    number character varying(25),
    status character varying(10),
    previous_balance numeric(18,4) DEFAULT 0.0,
    action character varying(10),
    action_amount numeric(18,4) DEFAULT 0.0,
    balance numeric(18,4) DEFAULT 0.0 NOT NULL,
    bank_account_id integer,
    user_id integer NOT NULL,
    task_id integer,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_historicalaccount OWNER TO usrinvoswrt;

--
-- TOC entry 289 (class 1259 OID 964735)
-- Name: lendenapp_historicalaccount_history_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_historicalaccount_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_historicalaccount_history_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10198 (class 0 OID 0)
-- Dependencies: 289
-- Name: lendenapp_historicalaccount_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_historicalaccount_history_id_seq OWNED BY public.lendenapp_historicalaccount.history_id;


--
-- TOC entry 292 (class 1259 OID 964751)
-- Name: lendenapp_historicalbankaccount; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_historicalbankaccount (
    history_id integer NOT NULL,
    history_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    history_type character varying(1) NOT NULL,
    id integer NOT NULL,
    name character varying(100),
    number character varying(30) NOT NULL,
    type character varying(15),
    purpose character varying(15),
    ifsc_code character varying(15),
    bank_id integer,
    user_id integer,
    task_id integer,
    is_active boolean DEFAULT true,
    cashfree_dtm timestamp with time zone,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_historicalbankaccount OWNER TO usrinvoswrt;

--
-- TOC entry 291 (class 1259 OID 964750)
-- Name: lendenapp_historicalbankaccount_history_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_historicalbankaccount_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_historicalbankaccount_history_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10199 (class 0 OID 0)
-- Dependencies: 291
-- Name: lendenapp_historicalbankaccount_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_historicalbankaccount_history_id_seq OWNED BY public.lendenapp_historicalbankaccount.history_id;


--
-- TOC entry 310 (class 1259 OID 964863)
-- Name: lendenapp_historicalcustomuser; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_historicalcustomuser (
    history_id integer NOT NULL,
    history_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    history_type character varying(1) NOT NULL,
    id integer NOT NULL,
    password character varying(100),
    user_id character varying(20) NOT NULL,
    encoded_pan character varying(100),
    encoded_aadhar character varying(150),
    encoded_email character varying(200),
    encoded_mobile character varying(100),
    type character varying(30),
    first_name character varying(100),
    middle_name character varying(10),
    last_name character varying(10),
    gender character varying(6),
    mobile_number character varying(15),
    email character varying(100),
    email_verification boolean DEFAULT false NOT NULL,
    dob date,
    marital_status character varying(10),
    aadhar character varying(25),
    pan character varying(15),
    is_active boolean DEFAULT false NOT NULL,
    device_id character varying(50),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_historicalcustomuser OWNER TO usrinvoswrt;

--
-- TOC entry 309 (class 1259 OID 964862)
-- Name: lendenapp_historicalcustomuser_history_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_historicalcustomuser_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_historicalcustomuser_history_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10200 (class 0 OID 0)
-- Dependencies: 309
-- Name: lendenapp_historicalcustomuser_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_historicalcustomuser_history_id_seq OWNED BY public.lendenapp_historicalcustomuser.history_id;


--
-- TOC entry 306 (class 1259 OID 964838)
-- Name: lendenapp_historicaltask; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_historicaltask (
    history_id integer NOT NULL,
    history_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    history_type character varying(1) NOT NULL,
    id integer NOT NULL,
    checklist text,
    assigned_by_id integer,
    created_by_id integer NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_historicaltask OWNER TO usrinvoswrt;

--
-- TOC entry 305 (class 1259 OID 964837)
-- Name: lendenapp_historicaltask_history_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_historicaltask_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_historicaltask_history_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10201 (class 0 OID 0)
-- Dependencies: 305
-- Name: lendenapp_historicaltask_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_historicaltask_history_id_seq OWNED BY public.lendenapp_historicaltask.history_id;


--
-- TOC entry 779 (class 1259 OID 1524827)
-- Name: lendenapp_historicaltracktxnamount; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_historicaltracktxnamount (
    history_id integer NOT NULL,
    history_type character varying(1) NOT NULL,
    history_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id integer NOT NULL,
    transaction_id integer NOT NULL,
    initial_amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    action_amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    expiry_dtm timestamp with time zone NOT NULL,
    type character varying(35) NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    balance numeric(18,4) DEFAULT 0.0 NOT NULL,
    reversal_txn_id character varying(34)
);


ALTER TABLE public.lendenapp_historicaltracktxnamount OWNER TO devmultilenden;

--
-- TOC entry 778 (class 1259 OID 1524826)
-- Name: lendenapp_historicaltracktxnamount_history_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_historicaltracktxnamount_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_historicaltracktxnamount_history_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10202 (class 0 OID 0)
-- Dependencies: 778
-- Name: lendenapp_historicaltracktxnamount_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_historicaltracktxnamount_history_id_seq OWNED BY public.lendenapp_historicaltracktxnamount.history_id;


--
-- TOC entry 308 (class 1259 OID 964850)
-- Name: lendenapp_historicaltransaction; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_historicaltransaction (
    history_id integer NOT NULL,
    history_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    history_type character varying(1) NOT NULL,
    id integer NOT NULL,
    transaction_id character varying(255) NOT NULL,
    response_id character varying(50),
    type character varying(50),
    type_id character varying(45),
    amount numeric(18,4),
    status character varying(15),
    status_date date,
    description character varying(1000),
    details character varying(200),
    remark character varying(100),
    date timestamp with time zone,
    previous_balance numeric(18,4),
    updated_balance numeric(18,4),
    rejection_reason text,
    from_user_id integer,
    to_user_id integer,
    task_id integer,
    utr_no character varying(30),
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_historicaltransaction OWNER TO usrinvoswrt;

--
-- TOC entry 307 (class 1259 OID 964849)
-- Name: lendenapp_historicaltransaction_history_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_historicaltransaction_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_historicaltransaction_history_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10203 (class 0 OID 0)
-- Dependencies: 307
-- Name: lendenapp_historicaltransaction_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_historicaltransaction_history_id_seq OWNED BY public.lendenapp_historicaltransaction.history_id;


--
-- TOC entry 732 (class 1259 OID 982119)
-- Name: lendenapp_investorutminfo; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_investorutminfo (
    id bigint NOT NULL,
    utm_campaign character varying(100),
    utm_medium character varying(50),
    utm_source character varying(30),
    utm_term character varying(150),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    task_id integer,
    user_id bigint NOT NULL,
    user_source_group_id bigint NOT NULL
);


ALTER TABLE public.lendenapp_investorutminfo OWNER TO devmultilenden;

--
-- TOC entry 731 (class 1259 OID 982118)
-- Name: lendenapp_investorutminfo_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_investorutminfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_investorutminfo_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10204 (class 0 OID 0)
-- Dependencies: 731
-- Name: lendenapp_investorutminfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_investorutminfo_id_seq OWNED BY public.lendenapp_investorutminfo.id;


--
-- TOC entry 743 (class 1259 OID 1078970)
-- Name: lendenapp_mandate; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_mandate (
    id bigint NOT NULL,
    tracking_id character varying(100) NOT NULL,
    frequency character varying(20) NOT NULL,
    mandate_type character varying(20),
    first_deduction_amount double precision DEFAULT 0,
    umrn_number character varying(50),
    max_amount double precision,
    mandate_status character varying(20),
    mandate_end_date date,
    mandate_start_date date,
    remarks character varying(120),
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    user_source_group_id integer NOT NULL,
    mandate_tracker_id integer NOT NULL,
    attempt_count integer
);


ALTER TABLE public.lendenapp_mandate OWNER TO usrinvoswrt;

--
-- TOC entry 742 (class 1259 OID 1078969)
-- Name: lendenapp_mandate_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_mandate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_mandate_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10205 (class 0 OID 0)
-- Dependencies: 742
-- Name: lendenapp_mandate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_mandate_id_seq OWNED BY public.lendenapp_mandate.id;


--
-- TOC entry 741 (class 1259 OID 1078948)
-- Name: lendenapp_mandatetracker; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_mandatetracker (
    id bigint NOT NULL,
    max_amount double precision,
    mandate_type character varying(20) NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    expiry_date timestamp with time zone,
    status public.mandate_tracker_status NOT NULL,
    user_source_group_id integer NOT NULL,
    remarks character varying(50),
    scheme_info_id integer,
    mandate_reference_id character varying(20)
);


ALTER TABLE public.lendenapp_mandatetracker OWNER TO usrinvoswrt;

--
-- TOC entry 740 (class 1259 OID 1078947)
-- Name: lendenapp_mandatetracker_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_mandatetracker_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_mandatetracker_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10206 (class 0 OID 0)
-- Dependencies: 740
-- Name: lendenapp_mandatetracker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_mandatetracker_id_seq OWNED BY public.lendenapp_mandatetracker.id;


--
-- TOC entry 257 (class 1259 OID 956131)
-- Name: lendenapp_migration_error_log; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_migration_error_log (
    id bigint NOT NULL,
    is_resolved boolean DEFAULT false,
    created_dtm timestamp with time zone,
    migration_type character varying(100),
    err_message text,
    err_details text,
    err_context text,
    user_source_id integer
);


ALTER TABLE public.lendenapp_migration_error_log OWNER TO usrinvoswrt;

--
-- TOC entry 256 (class 1259 OID 956130)
-- Name: lendenapp_migration_error_log_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_migration_error_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_migration_error_log_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10207 (class 0 OID 0)
-- Dependencies: 256
-- Name: lendenapp_migration_error_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_migration_error_log_id_seq OWNED BY public.lendenapp_migration_error_log.id;


--
-- TOC entry 744 (class 1259 OID 1079392)
-- Name: lendenapp_nach_presentation; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_nach_presentation (
    purpose_ref_id character varying(30),
    debit_date date,
    debit_amount double precision,
    unique_record_id character varying(100),
    user_source_group_id integer NOT NULL,
    payment_reference_id character varying(100),
    status character varying(20),
    remarks text,
    batch_number character varying(50),
    umrn character varying(100),
    transaction_id bigint,
    is_processed boolean DEFAULT false,
    scheme_info_id integer,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    id bigint NOT NULL,
    product_type character varying(20) DEFAULT 'AUTO_LENDING'::character varying NOT NULL
);


ALTER TABLE public.lendenapp_nach_presentation OWNER TO usrinvoswrt;

--
-- TOC entry 294 (class 1259 OID 964763)
-- Name: lendenapp_notification; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_notification (
    id integer NOT NULL,
    message character varying(500),
    type character varying(20),
    status character varying(20),
    click_count smallint NOT NULL,
    from_user_id integer,
    to_user_id integer,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_notification OWNER TO usrinvoswrt;

--
-- TOC entry 293 (class 1259 OID 964762)
-- Name: lendenapp_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_notification_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10208 (class 0 OID 0)
-- Dependencies: 293
-- Name: lendenapp_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_notification_id_seq OWNED BY public.lendenapp_notification.id;


--
-- TOC entry 773 (class 1259 OID 1523123)
-- Name: lendenapp_notifications; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_notifications (
    id integer NOT NULL,
    notification_id character varying(255) NOT NULL,
    expiry_dtm timestamp without time zone,
    title character varying(255) NOT NULL,
    description text,
    action character varying(255),
    type character varying(50),
    category character varying(50),
    is_notified boolean DEFAULT false,
    created_dtm timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dtm timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_source_group_id integer
);


ALTER TABLE public.lendenapp_notifications OWNER TO devmultilenden;

--
-- TOC entry 772 (class 1259 OID 1523122)
-- Name: lendenapp_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_notifications_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10209 (class 0 OID 0)
-- Dependencies: 772
-- Name: lendenapp_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_notifications_id_seq OWNED BY public.lendenapp_notifications.id;


--
-- TOC entry 264 (class 1259 OID 964334)
-- Name: lendenapp_offline_payment_request; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_offline_payment_request (
    id bigint NOT NULL,
    request_id character varying(16) NOT NULL,
    amount numeric(19,4) NOT NULL,
    payment_mode character varying(25) NOT NULL,
    deposit_date date NOT NULL,
    reference_number character varying(50) NOT NULL,
    status character varying(20),
    comment character varying(120),
    document_id integer[] NOT NULL,
    investor_id integer NOT NULL,
    requested_by_id integer NOT NULL,
    task_id integer,
    transaction_id integer,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_offline_payment_request OWNER TO usrinvoswrt;

--
-- TOC entry 263 (class 1259 OID 964333)
-- Name: lendenapp_offline_payment_request_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_offline_payment_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_offline_payment_request_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10210 (class 0 OID 0)
-- Dependencies: 263
-- Name: lendenapp_offline_payment_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_offline_payment_request_id_seq OWNED BY public.lendenapp_offline_payment_request.id;


--
-- TOC entry 266 (class 1259 OID 964362)
-- Name: lendenapp_offline_payment_verification; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_offline_payment_verification (
    id bigint NOT NULL,
    status character varying(10),
    remark character varying(120),
    request_id integer NOT NULL,
    verified_by_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_offline_payment_verification OWNER TO usrinvoswrt;

--
-- TOC entry 265 (class 1259 OID 964361)
-- Name: lendenapp_offline_payment_verification_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_offline_payment_verification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_offline_payment_verification_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10211 (class 0 OID 0)
-- Dependencies: 265
-- Name: lendenapp_offline_payment_verification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_offline_payment_verification_id_seq OWNED BY public.lendenapp_offline_payment_verification.id;


--
-- TOC entry 805 (class 1259 OID 1536662)
-- Name: lendenapp_otl_scheme_loan_mapping; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
)
PARTITION BY RANGE (created_date);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping OWNER TO devmultilenden;

--
-- TOC entry 806 (class 1259 OID 1536929)
-- Name: lendenapp_otl_scheme_loan_mapping_202501; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202501 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202501 OWNER TO devmultilenden;

--
-- TOC entry 807 (class 1259 OID 1536934)
-- Name: lendenapp_otl_scheme_loan_mapping_202502; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202502 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202502 OWNER TO devmultilenden;

--
-- TOC entry 808 (class 1259 OID 1536939)
-- Name: lendenapp_otl_scheme_loan_mapping_202503; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202503 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202503 OWNER TO devmultilenden;

--
-- TOC entry 809 (class 1259 OID 1536944)
-- Name: lendenapp_otl_scheme_loan_mapping_202504; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202504 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202504 OWNER TO devmultilenden;

--
-- TOC entry 810 (class 1259 OID 1536949)
-- Name: lendenapp_otl_scheme_loan_mapping_202505; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202505 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202505 OWNER TO devmultilenden;

--
-- TOC entry 811 (class 1259 OID 1536954)
-- Name: lendenapp_otl_scheme_loan_mapping_202506; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202506 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202506 OWNER TO devmultilenden;

--
-- TOC entry 812 (class 1259 OID 1536959)
-- Name: lendenapp_otl_scheme_loan_mapping_202507; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202507 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202507 OWNER TO devmultilenden;

--
-- TOC entry 813 (class 1259 OID 1536964)
-- Name: lendenapp_otl_scheme_loan_mapping_202508; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202508 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202508 OWNER TO devmultilenden;

--
-- TOC entry 814 (class 1259 OID 1536969)
-- Name: lendenapp_otl_scheme_loan_mapping_202509; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202509 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202509 OWNER TO devmultilenden;

--
-- TOC entry 815 (class 1259 OID 1536974)
-- Name: lendenapp_otl_scheme_loan_mapping_202510; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202510 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202510 OWNER TO devmultilenden;

--
-- TOC entry 816 (class 1259 OID 1536979)
-- Name: lendenapp_otl_scheme_loan_mapping_202511; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202511 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202511 OWNER TO devmultilenden;

--
-- TOC entry 817 (class 1259 OID 1536984)
-- Name: lendenapp_otl_scheme_loan_mapping_202512; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202512 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202512 OWNER TO devmultilenden;

--
-- TOC entry 818 (class 1259 OID 1536989)
-- Name: lendenapp_otl_scheme_loan_mapping_202601; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202601 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202601 OWNER TO devmultilenden;

--
-- TOC entry 819 (class 1259 OID 1536994)
-- Name: lendenapp_otl_scheme_loan_mapping_202602; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202602 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202602 OWNER TO devmultilenden;

--
-- TOC entry 820 (class 1259 OID 1536999)
-- Name: lendenapp_otl_scheme_loan_mapping_202603; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202603 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202603 OWNER TO devmultilenden;

--
-- TOC entry 821 (class 1259 OID 1537004)
-- Name: lendenapp_otl_scheme_loan_mapping_202604; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202604 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202604 OWNER TO devmultilenden;

--
-- TOC entry 822 (class 1259 OID 1537009)
-- Name: lendenapp_otl_scheme_loan_mapping_202605; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202605 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202605 OWNER TO devmultilenden;

--
-- TOC entry 823 (class 1259 OID 1537014)
-- Name: lendenapp_otl_scheme_loan_mapping_202606; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202606 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202606 OWNER TO devmultilenden;

--
-- TOC entry 824 (class 1259 OID 1537019)
-- Name: lendenapp_otl_scheme_loan_mapping_202607; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202607 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202607 OWNER TO devmultilenden;

--
-- TOC entry 825 (class 1259 OID 1537024)
-- Name: lendenapp_otl_scheme_loan_mapping_202608; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202608 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202608 OWNER TO devmultilenden;

--
-- TOC entry 826 (class 1259 OID 1537029)
-- Name: lendenapp_otl_scheme_loan_mapping_202609; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202609 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202609 OWNER TO devmultilenden;

--
-- TOC entry 827 (class 1259 OID 1537034)
-- Name: lendenapp_otl_scheme_loan_mapping_202610; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202610 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202610 OWNER TO devmultilenden;

--
-- TOC entry 828 (class 1259 OID 1537039)
-- Name: lendenapp_otl_scheme_loan_mapping_202611; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202611 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202611 OWNER TO devmultilenden;

--
-- TOC entry 829 (class 1259 OID 1537044)
-- Name: lendenapp_otl_scheme_loan_mapping_202612; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_202612 (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100),
    user_source_group_id integer NOT NULL,
    is_available boolean,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone NOT NULL,
    lent_amount numeric(18,4),
    is_selected boolean DEFAULT true NOT NULL,
    repayment_frequency character varying,
    partner_id integer,
    is_modified boolean DEFAULT false
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_202612 OWNER TO devmultilenden;

--
-- TOC entry 769 (class 1259 OID 1456138)
-- Name: lendenapp_otl_scheme_loan_mapping_old; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_old (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(100) NOT NULL,
    user_source_group_id integer NOT NULL,
    partner_id integer,
    is_available boolean DEFAULT true,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone DEFAULT now(),
    lent_amount numeric(18,4),
    is_selected_new boolean DEFAULT true NOT NULL,
    is_selected boolean DEFAULT true NOT NULL
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_old OWNER TO devmultilenden;

--
-- TOC entry 768 (class 1259 OID 1456132)
-- Name: lendenapp_otl_scheme_loan_mapping_temp; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_temp (
    id integer NOT NULL,
    otl_tracker_id integer NOT NULL,
    loan_id character varying(30) NOT NULL,
    user_source_group_id integer NOT NULL,
    partner_id integer,
    is_available boolean DEFAULT true,
    loan_roi numeric(5,2),
    ldc_score smallint,
    loan_amount numeric(18,4),
    loan_tenure smallint,
    borrower_name character varying(255),
    created_date timestamp with time zone DEFAULT now()
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_temp OWNER TO devmultilenden;

--
-- TOC entry 766 (class 1259 OID 1455694)
-- Name: lendenapp_otl_scheme_loan_mapping_v2; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_v2 (
    id integer NOT NULL,
    otl_tracker_id integer,
    loan_id character varying(30) NOT NULL,
    user_source_group_id integer NOT NULL,
    partner_id integer,
    is_available boolean DEFAULT true,
    created_date timestamp with time zone DEFAULT now(),
    loan_roi numeric(10,2),
    ldc_score integer,
    loan_amount numeric(15,2),
    loan_tenure numeric(10,1),
    borrower_name character varying(255)
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_v2 OWNER TO devmultilenden;

--
-- TOC entry 767 (class 1259 OID 1455704)
-- Name: lendenapp_otl_scheme_loan_mapping_v3; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_loan_mapping_v3 (
    id integer NOT NULL,
    otl_tracker_id integer,
    loan_id character varying(30) NOT NULL,
    user_source_group_id integer NOT NULL,
    partner_id integer,
    is_available boolean DEFAULT true,
    created_date timestamp with time zone DEFAULT now(),
    loan_roi numeric(10,2),
    ldc_score integer,
    loan_amount numeric(15,2),
    loan_tenure numeric(10,1),
    borrower_name character varying(255)
);


ALTER TABLE public.lendenapp_otl_scheme_loan_mapping_v3 OWNER TO devmultilenden;

--
-- TOC entry 763 (class 1259 OID 1449336)
-- Name: lendenapp_otl_scheme_tracker; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_otl_scheme_tracker (
    id integer NOT NULL,
    scheme_id character varying(30) NOT NULL,
    batch_number character varying(30) NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    is_latest boolean DEFAULT false,
    amount_per_loan numeric(18,4),
    loan_count integer,
    user_source_group_id integer,
    expiry_dtm timestamp with time zone,
    preference_id integer,
    tenure integer,
    to_be_notified boolean DEFAULT false,
    status character varying(30),
    lending_amount numeric(18,4),
    transaction_id integer,
    notification_type public.notification_type_enum,
    loan_tenure character varying(20),
    investment_type character varying(50),
    max_lending_amount numeric(18,4),
    product_type public.stl_product_type_enum,
    priority_order integer DEFAULT 1
);


ALTER TABLE public.lendenapp_otl_scheme_tracker OWNER TO devmultilenden;

--
-- TOC entry 762 (class 1259 OID 1449335)
-- Name: lendenapp_otl_scheme_tracker_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_otl_scheme_tracker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_otl_scheme_tracker_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10212 (class 0 OID 0)
-- Dependencies: 762
-- Name: lendenapp_otl_scheme_tracker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_otl_scheme_tracker_id_seq OWNED BY public.lendenapp_otl_scheme_tracker.id;


--
-- TOC entry 268 (class 1259 OID 964381)
-- Name: lendenapp_partneruserconsentlog; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_partneruserconsentlog (
    id bigint NOT NULL,
    unique_id character varying(10) NOT NULL,
    consent_type character varying(20),
    details jsonb NOT NULL,
    otp character varying(6) NOT NULL,
    otp_count integer,
    status character varying(10) NOT NULL,
    otp_expiry_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    investor_id integer NOT NULL,
    partner_id integer,
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_partneruserconsentlog OWNER TO usrinvoswrt;

--
-- TOC entry 267 (class 1259 OID 964380)
-- Name: lendenapp_partneruserconsentlog_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_partneruserconsentlog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_partneruserconsentlog_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10213 (class 0 OID 0)
-- Dependencies: 267
-- Name: lendenapp_partneruserconsentlog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_partneruserconsentlog_id_seq OWNED BY public.lendenapp_partneruserconsentlog.id;


--
-- TOC entry 781 (class 1259 OID 1525433)
-- Name: lendenapp_user_metadata; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_metadata (
    id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    passcode character varying(50) NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_valid boolean DEFAULT false
);


ALTER TABLE public.lendenapp_user_metadata OWNER TO devmultilenden;

--
-- TOC entry 780 (class 1259 OID 1525432)
-- Name: lendenapp_passcode_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_passcode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_passcode_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10214 (class 0 OID 0)
-- Dependencies: 780
-- Name: lendenapp_passcode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_passcode_id_seq OWNED BY public.lendenapp_user_metadata.id;


--
-- TOC entry 270 (class 1259 OID 964405)
-- Name: lendenapp_paymentlink; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_paymentlink (
    id bigint NOT NULL,
    reference_id character varying(50) NOT NULL,
    invoice_id character varying(25),
    status character varying(10) NOT NULL,
    payment_gateway character varying(10) NOT NULL,
    link character varying(255),
    payment_id character varying(50),
    order_id character varying(30),
    amount numeric(19,4) NOT NULL,
    raw_response jsonb,
    raw_request jsonb,
    note character varying(50),
    created_by_id integer NOT NULL,
    created_for_id integer NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_paymentlink OWNER TO usrinvoswrt;

--
-- TOC entry 269 (class 1259 OID 964404)
-- Name: lendenapp_paymentlink_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_paymentlink_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_paymentlink_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10215 (class 0 OID 0)
-- Dependencies: 269
-- Name: lendenapp_paymentlink_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_paymentlink_id_seq OWNED BY public.lendenapp_paymentlink.id;


--
-- TOC entry 232 (class 1259 OID 728338)
-- Name: lendenapp_pincode_state_master; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_pincode_state_master (
    id integer NOT NULL,
    pincode integer NOT NULL,
    state_iso_code character varying(3) NOT NULL,
    district character varying(50),
    state character varying(50),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT lendenapp_pincode_state_master_pincode_check CHECK (((pincode >= 100000) AND (pincode <= 999999)))
);


ALTER TABLE public.lendenapp_pincode_state_master OWNER TO usrinvoswrt;

--
-- TOC entry 231 (class 1259 OID 728337)
-- Name: lendenapp_pincode_state_master_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_pincode_state_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_pincode_state_master_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10216 (class 0 OID 0)
-- Dependencies: 231
-- Name: lendenapp_pincode_state_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_pincode_state_master_id_seq OWNED BY public.lendenapp_pincode_state_master.id;


--
-- TOC entry 314 (class 1259 OID 964965)
-- Name: lendenapp_reference; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_reference (
    id integer NOT NULL,
    comment character varying(255),
    email character varying(100),
    mobile_number character varying(15),
    name character varying(100),
    relation character varying(30),
    type character varying(25),
    dob date,
    gender character varying(10),
    pan character varying(21),
    encoded_mobile character varying(100),
    encoded_email character varying(200),
    encoded_pan character varying(100),
    user_id integer NOT NULL,
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    gst_number character varying(50)
);


ALTER TABLE public.lendenapp_reference OWNER TO usrinvoswrt;

--
-- TOC entry 313 (class 1259 OID 964964)
-- Name: lendenapp_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_reference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_reference_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10217 (class 0 OID 0)
-- Dependencies: 313
-- Name: lendenapp_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_reference_id_seq OWNED BY public.lendenapp_reference.id;


--
-- TOC entry 1072 (class 1259 OID 1883411)
-- Name: lendenapp_reward; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_reward (
    id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    related_user_source_group_id integer NOT NULL,
    campaign_id integer NOT NULL,
    amount numeric(18,4) NOT NULL,
    expiry_date date,
    status public.reward_status NOT NULL,
    redeemed_on date,
    metadata jsonb,
    transaction_id character varying(100) NOT NULL,
    utr_no character varying(100),
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    reminder_date date
);


ALTER TABLE public.lendenapp_reward OWNER TO devmultilenden;

--
-- TOC entry 1071 (class 1259 OID 1883410)
-- Name: lendenapp_reward_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_reward_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_reward_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10218 (class 0 OID 0)
-- Dependencies: 1071
-- Name: lendenapp_reward_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_reward_id_seq OWNED BY public.lendenapp_reward.id;


--
-- TOC entry 745 (class 1259 OID 1080120)
-- Name: lendenapp_scheme_reinvestment_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_scheme_reinvestment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_scheme_reinvestment_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10219 (class 0 OID 0)
-- Dependencies: 745
-- Name: lendenapp_scheme_reinvestment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_scheme_reinvestment_id_seq OWNED BY public.lendenapp_nach_presentation.id;


--
-- TOC entry 760 (class 1259 OID 1310018)
-- Name: lendenapp_scheme_repayment_details; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_scheme_repayment_details (
    id bigint NOT NULL,
    purpose_ref_id character varying(30),
    debit_amount numeric(18,4),
    unique_record_id character varying(100),
    user_source_group_id integer,
    scheme_reinvestment_id integer,
    withdrawal_transaction_id integer,
    is_reinvestment_processed boolean DEFAULT false,
    repayment_id integer,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    is_mandate_active boolean DEFAULT false,
    is_communication boolean DEFAULT false,
    is_pushed_to_zoho boolean DEFAULT false,
    type character varying(50),
    principal numeric(18,2) DEFAULT 0.0,
    interest numeric(18,2) DEFAULT 0.0
);


ALTER TABLE public.lendenapp_scheme_repayment_details OWNER TO devmultilenden;

--
-- TOC entry 759 (class 1259 OID 1310017)
-- Name: lendenapp_scheme_repayment_details_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_scheme_repayment_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_scheme_repayment_details_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10220 (class 0 OID 0)
-- Dependencies: 759
-- Name: lendenapp_scheme_repayment_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_scheme_repayment_details_id_seq OWNED BY public.lendenapp_scheme_repayment_details.id;


--
-- TOC entry 794 (class 1259 OID 1530347)
-- Name: lendenapp_schemefilters_logs; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_schemefilters_logs (
    id bigint NOT NULL,
    filter_data json NOT NULL,
    sort_data json NOT NULL,
    loan_count integer,
    user_source_group_id integer NOT NULL,
    created_date timestamp with time zone,
    updated_date timestamp without time zone DEFAULT now()
);


ALTER TABLE public.lendenapp_schemefilters_logs OWNER TO devmultilenden;

--
-- TOC entry 793 (class 1259 OID 1530346)
-- Name: lendenapp_schemefilters_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_schemefilters_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_schemefilters_logs_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10221 (class 0 OID 0)
-- Dependencies: 793
-- Name: lendenapp_schemefilters_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_schemefilters_logs_id_seq OWNED BY public.lendenapp_schemefilters_logs.id;


--
-- TOC entry 739 (class 1259 OID 1078920)
-- Name: lendenapp_schemeinfo; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_schemeinfo (
    id bigint NOT NULL,
    scheme_id character varying(30) NOT NULL,
    tenure integer,
    amount double precision,
    investment_type character varying(50),
    user_source_group_id integer NOT NULL,
    transaction_id integer NOT NULL,
    start_date date,
    maturity_date date,
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    preference_id integer,
    status character varying(20),
    mandate_id integer,
    is_matured boolean DEFAULT false,
    scheme_cancelled_dtm timestamp with time zone,
    mandate_linked_dtm timestamp with time zone
);


ALTER TABLE public.lendenapp_schemeinfo OWNER TO usrinvoswrt;

--
-- TOC entry 738 (class 1259 OID 1078919)
-- Name: lendenapp_schemeinfo_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_schemeinfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_schemeinfo_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10222 (class 0 OID 0)
-- Dependencies: 738
-- Name: lendenapp_schemeinfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_schemeinfo_id_seq OWNED BY public.lendenapp_schemeinfo.id;


--
-- TOC entry 751 (class 1259 OID 1187481)
-- Name: lendenapp_snorkel_stuck_transaction; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_snorkel_stuck_transaction (
    id integer NOT NULL,
    amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    cms_number character varying(30),
    reference_number character varying(50),
    remarks character varying(30),
    utr_no character varying(50),
    snorkel_status character varying(30),
    status character varying(30),
    purge_date date,
    created_date timestamp with time zone DEFAULT now() NOT NULL,
    updated_date timestamp with time zone DEFAULT now() NOT NULL,
    add_money_account character varying(30),
    add_money_ifsc_code character varying(15),
    add_money_account_holder character varying(100),
    type character varying(50),
    add_money_bank_name character varying(150)
);


ALTER TABLE public.lendenapp_snorkel_stuck_transaction OWNER TO devmultilenden;

--
-- TOC entry 750 (class 1259 OID 1187480)
-- Name: lendenapp_snorkel_stuck_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_snorkel_stuck_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_snorkel_stuck_transaction_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10223 (class 0 OID 0)
-- Dependencies: 750
-- Name: lendenapp_snorkel_stuck_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_snorkel_stuck_transaction_id_seq OWNED BY public.lendenapp_snorkel_stuck_transaction.id;


--
-- TOC entry 227 (class 1259 OID 727941)
-- Name: lendenapp_source_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_source_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_source_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10224 (class 0 OID 0)
-- Dependencies: 227
-- Name: lendenapp_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_source_id_seq OWNED BY public.lendenapp_source.id;


--
-- TOC entry 833 (class 1259 OID 1539134)
-- Name: lendenapp_state_codes_master; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_state_codes_master (
    id integer NOT NULL,
    state character varying(5) NOT NULL,
    code integer NOT NULL
);


ALTER TABLE public.lendenapp_state_codes_master OWNER TO devmultilenden;

--
-- TOC entry 832 (class 1259 OID 1539133)
-- Name: lendenapp_state_codes_master_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_state_codes_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_state_codes_master_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10225 (class 0 OID 0)
-- Dependencies: 832
-- Name: lendenapp_state_codes_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_state_codes_master_id_seq OWNED BY public.lendenapp_state_codes_master.id;


--
-- TOC entry 239 (class 1259 OID 801245)
-- Name: lendenapp_task_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_task_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10226 (class 0 OID 0)
-- Dependencies: 239
-- Name: lendenapp_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_task_id_seq OWNED BY public.lendenapp_task.id;


--
-- TOC entry 870 (class 1259 OID 1834260)
-- Name: lendenapp_test; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_test (
    transaction_id character varying(255)
);


ALTER TABLE public.lendenapp_test OWNER TO devmultilenden;

--
-- TOC entry 272 (class 1259 OID 964426)
-- Name: lendenapp_thirdparty_clevertap_events; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdparty_clevertap_events (
    id bigint NOT NULL,
    event_name character varying(30) NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_thirdparty_clevertap_events OWNER TO usrinvoswrt;

--
-- TOC entry 271 (class 1259 OID 964425)
-- Name: lendenapp_thirdparty_clevertap_events_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdparty_clevertap_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdparty_clevertap_events_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10227 (class 0 OID 0)
-- Dependencies: 271
-- Name: lendenapp_thirdparty_clevertap_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdparty_clevertap_events_id_seq OWNED BY public.lendenapp_thirdparty_clevertap_events.id;


--
-- TOC entry 274 (class 1259 OID 964436)
-- Name: lendenapp_thirdparty_clevertap_logs; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdparty_clevertap_logs (
    id bigint NOT NULL,
    user_id character varying(12) NOT NULL,
    event_id integer NOT NULL,
    status character varying(15) NOT NULL,
    event_data json,
    failure_reason character varying(100),
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_unique_id character varying(100)
);


ALTER TABLE public.lendenapp_thirdparty_clevertap_logs OWNER TO usrinvoswrt;

--
-- TOC entry 273 (class 1259 OID 964435)
-- Name: lendenapp_thirdparty_clevertap_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdparty_clevertap_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdparty_clevertap_logs_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10228 (class 0 OID 0)
-- Dependencies: 273
-- Name: lendenapp_thirdparty_clevertap_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdparty_clevertap_logs_id_seq OWNED BY public.lendenapp_thirdparty_clevertap_logs.id;


--
-- TOC entry 747 (class 1259 OID 1080726)
-- Name: lendenapp_thirdparty_crif_logs; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_thirdparty_crif_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    report_id character varying,
    inquiry_id character varying,
    crif_report_data jsonb,
    created_date timestamp with time zone,
    updated_date timestamp with time zone,
    status character varying
);


ALTER TABLE public.lendenapp_thirdparty_crif_logs OWNER TO devmultilenden;

--
-- TOC entry 746 (class 1259 OID 1080725)
-- Name: lendenapp_thirdparty_crif_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_thirdparty_crif_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdparty_crif_logs_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10229 (class 0 OID 0)
-- Dependencies: 746
-- Name: lendenapp_thirdparty_crif_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_thirdparty_crif_logs_id_seq OWNED BY public.lendenapp_thirdparty_crif_logs.id;


--
-- TOC entry 726 (class 1259 OID 980016)
-- Name: lendenapp_thirdparty_event_logs; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdparty_event_logs (
    id integer NOT NULL,
    source character varying(50),
    data json,
    response json,
    created_dtm timestamp with time zone,
    user_id_pk integer,
    data_type character varying(20),
    status_code integer
);


ALTER TABLE public.lendenapp_thirdparty_event_logs OWNER TO usrinvoswrt;

--
-- TOC entry 725 (class 1259 OID 980015)
-- Name: lendenapp_thirdparty_event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdparty_event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdparty_event_logs_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10230 (class 0 OID 0)
-- Dependencies: 725
-- Name: lendenapp_thirdparty_event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdparty_event_logs_id_seq OWNED BY public.lendenapp_thirdparty_event_logs.id;


--
-- TOC entry 304 (class 1259 OID 964826)
-- Name: lendenapp_thirdparty_zoho_logs; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdparty_zoho_logs (
    id integer NOT NULL,
    user_id integer,
    status character varying(20),
    failure_reason character varying(200),
    request_data jsonb,
    response_data jsonb,
    task_id integer,
    event_name character varying(50),
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_thirdparty_zoho_logs OWNER TO usrinvoswrt;

--
-- TOC entry 303 (class 1259 OID 964825)
-- Name: lendenapp_thirdparty_zoho_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdparty_zoho_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdparty_zoho_logs_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10231 (class 0 OID 0)
-- Dependencies: 303
-- Name: lendenapp_thirdparty_zoho_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdparty_zoho_logs_id_seq OWNED BY public.lendenapp_thirdparty_zoho_logs.id;


--
-- TOC entry 286 (class 1259 OID 964708)
-- Name: lendenapp_thirdpartycashfree; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdpartycashfree (
    id bigint NOT NULL,
    action character varying(15) NOT NULL,
    json_request jsonb,
    json_response jsonb,
    status character varying(20),
    comments character varying(30),
    user_id integer NOT NULL,
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    account_status character varying(20),
    name_at_bank character varying(100),
    bank_name character varying(100),
    message character varying(150)
);


ALTER TABLE public.lendenapp_thirdpartycashfree OWNER TO usrinvoswrt;

--
-- TOC entry 285 (class 1259 OID 964707)
-- Name: lendenapp_thirdpartycashfree_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdpartycashfree_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdpartycashfree_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10232 (class 0 OID 0)
-- Dependencies: 285
-- Name: lendenapp_thirdpartycashfree_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdpartycashfree_id_seq OWNED BY public.lendenapp_thirdpartycashfree.id;


--
-- TOC entry 288 (class 1259 OID 964725)
-- Name: lendenapp_thirdpartydata; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdpartydata (
    id bigint NOT NULL,
    source character varying(10),
    action character varying(50),
    response text NOT NULL,
    status character varying(10) NOT NULL,
    comments text,
    json_response jsonb,
    task_id integer,
    user_id integer NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_thirdpartydata OWNER TO usrinvoswrt;

--
-- TOC entry 287 (class 1259 OID 964724)
-- Name: lendenapp_thirdpartydata_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdpartydata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdpartydata_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10233 (class 0 OID 0)
-- Dependencies: 287
-- Name: lendenapp_thirdpartydata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdpartydata_id_seq OWNED BY public.lendenapp_thirdpartydata.id;


--
-- TOC entry 276 (class 1259 OID 964445)
-- Name: lendenapp_thirdpartydatahyperverge; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_thirdpartydatahyperverge (
    id bigint NOT NULL,
    action character varying(40) NOT NULL,
    json_request jsonb,
    json_response jsonb,
    status character varying(10),
    task_id integer,
    user_id integer NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_thirdpartydatahyperverge OWNER TO usrinvoswrt;

--
-- TOC entry 275 (class 1259 OID 964444)
-- Name: lendenapp_thirdpartydatahyperverge_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_thirdpartydatahyperverge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_thirdpartydatahyperverge_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10234 (class 0 OID 0)
-- Dependencies: 275
-- Name: lendenapp_thirdpartydatahyperverge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_thirdpartydatahyperverge_id_seq OWNED BY public.lendenapp_thirdpartydatahyperverge.id;


--
-- TOC entry 278 (class 1259 OID 964462)
-- Name: lendenapp_timeline; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_timeline (
    id bigint NOT NULL,
    activity character varying(55) NOT NULL,
    detail character varying(120),
    task_id integer,
    user_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_timeline OWNER TO usrinvoswrt;

--
-- TOC entry 277 (class 1259 OID 964461)
-- Name: lendenapp_timeline_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_timeline_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_timeline_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10235 (class 0 OID 0)
-- Dependencies: 277
-- Name: lendenapp_timeline_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_timeline_id_seq OWNED BY public.lendenapp_timeline.id;


--
-- TOC entry 775 (class 1259 OID 1523183)
-- Name: lendenapp_track_txn_amount; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_track_txn_amount (
    id integer NOT NULL,
    transaction_id integer NOT NULL,
    initial_amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    action_amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    expiry_dtm timestamp with time zone NOT NULL,
    type character varying(20) NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    balance numeric(18,4) DEFAULT 0.0 NOT NULL,
    reversal_txn_id integer
);


ALTER TABLE public.lendenapp_track_txn_amount OWNER TO devmultilenden;

--
-- TOC entry 774 (class 1259 OID 1523182)
-- Name: lendenapp_track_txn_amount_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_track_txn_amount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_track_txn_amount_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10236 (class 0 OID 0)
-- Dependencies: 774
-- Name: lendenapp_track_txn_amount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_track_txn_amount_id_seq OWNED BY public.lendenapp_track_txn_amount.id;


--
-- TOC entry 248 (class 1259 OID 857839)
-- Name: lendenapp_transaction; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_transaction (
    id integer NOT NULL,
    transaction_id character varying(255) NOT NULL,
    type character varying(50),
    amount numeric(18,4) DEFAULT 0.0,
    date timestamp with time zone,
    from_user_id integer,
    to_user_id integer,
    status character varying(15),
    remark character varying(100),
    description character varying(1000),
    type_id character varying(45),
    response_id character varying(100),
    task_id integer,
    previous_balance numeric(18,2) DEFAULT 0.0,
    updated_balance numeric(18,2) DEFAULT 0.0,
    details character varying(200),
    rejection_reason character varying(1000),
    utr_no character varying(100),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_source_group_id integer NOT NULL,
    reversal_txn_id integer,
    status_date date
);


ALTER TABLE public.lendenapp_transaction OWNER TO usrinvoswrt;

--
-- TOC entry 783 (class 1259 OID 1525552)
-- Name: lendenapp_transaction_amount_tracker; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_transaction_amount_tracker (
    id integer NOT NULL,
    transaction_id integer NOT NULL,
    initial_amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    action_amount numeric(18,4) DEFAULT 0.0 NOT NULL,
    expiry_dtm timestamp with time zone NOT NULL,
    type character varying(30) NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    balance numeric(18,4) DEFAULT 0.0 NOT NULL,
    reversal_txn_id character varying(34)
);


ALTER TABLE public.lendenapp_transaction_amount_tracker OWNER TO devmultilenden;

--
-- TOC entry 782 (class 1259 OID 1525551)
-- Name: lendenapp_transaction_amount_tracker_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_transaction_amount_tracker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_transaction_amount_tracker_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10237 (class 0 OID 0)
-- Dependencies: 782
-- Name: lendenapp_transaction_amount_tracker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_transaction_amount_tracker_id_seq OWNED BY public.lendenapp_transaction_amount_tracker.id;


--
-- TOC entry 247 (class 1259 OID 857838)
-- Name: lendenapp_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_transaction_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10238 (class 0 OID 0)
-- Dependencies: 247
-- Name: lendenapp_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_transaction_id_seq OWNED BY public.lendenapp_transaction.id;


--
-- TOC entry 737 (class 1259 OID 1078842)
-- Name: lendenapp_transaction_repayment_temp; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_transaction_repayment_temp (
    transaction_id character varying(255),
    type character varying(100),
    created_date timestamp with time zone DEFAULT now(),
    updated_date timestamp with time zone DEFAULT now(),
    amount double precision,
    description character varying(1000),
    from_user_id bigint,
    to_user_id bigint,
    type_id character varying(50),
    status character varying(50),
    user_source_group_id bigint,
    is_processed boolean DEFAULT false,
    scheme_id character varying(30) NOT NULL,
    principal numeric(18,2) DEFAULT 0.0,
    interest numeric(18,2) DEFAULT 0.0,
    user_id character varying(10),
    user_source character varying(10),
    channel_partner_id character varying(20)
);


ALTER TABLE public.lendenapp_transaction_repayment_temp OWNER TO usrinvoswrt;

--
-- TOC entry 296 (class 1259 OID 964779)
-- Name: lendenapp_transactionaudit; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_transactionaudit (
    id integer NOT NULL,
    action character varying(10) NOT NULL,
    action_datetime timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action_by_id integer NOT NULL,
    transaction_id integer NOT NULL
);


ALTER TABLE public.lendenapp_transactionaudit OWNER TO usrinvoswrt;

--
-- TOC entry 295 (class 1259 OID 964778)
-- Name: lendenapp_transactionaudit_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_transactionaudit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_transactionaudit_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10239 (class 0 OID 0)
-- Dependencies: 295
-- Name: lendenapp_transactionaudit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_transactionaudit_id_seq OWNED BY public.lendenapp_transactionaudit.id;


--
-- TOC entry 777 (class 1259 OID 1523204)
-- Name: lendenapp_txn_activity_log; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_txn_activity_log (
    id integer NOT NULL,
    activity character varying(55) NOT NULL,
    detail character varying(120),
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_txn_activity_log OWNER TO devmultilenden;

--
-- TOC entry 776 (class 1259 OID 1523203)
-- Name: lendenapp_txn_activity_log_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_txn_activity_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_txn_activity_log_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10240 (class 0 OID 0)
-- Dependencies: 776
-- Name: lendenapp_txn_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_txn_activity_log_id_seq OWNED BY public.lendenapp_txn_activity_log.id;


--
-- TOC entry 280 (class 1259 OID 964476)
-- Name: lendenapp_upimandatetransactionlog; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_upimandatetransactionlog (
    id integer NOT NULL,
    execute_request_id character varying(40),
    txn_status character varying(10),
    amount numeric(19,4) NOT NULL,
    lenden_transaction_id integer,
    mandate_id integer,
    execute_txn_dtm timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reinvest_status character varying(10),
    transaction_date date,
    code character varying(35),
    remark character varying(50),
    created_dtm timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_dtm timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_upimandatetransactionlog OWNER TO usrinvoswrt;

--
-- TOC entry 279 (class 1259 OID 964475)
-- Name: lendenapp_upimandatetransactionlog_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_upimandatetransactionlog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_upimandatetransactionlog_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10241 (class 0 OID 0)
-- Dependencies: 279
-- Name: lendenapp_upimandatetransactionlog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_upimandatetransactionlog_id_seq OWNED BY public.lendenapp_upimandatetransactionlog.id;


--
-- TOC entry 800 (class 1259 OID 1533239)
-- Name: lendenapp_user_cohort_mapping; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_cohort_mapping (
    id integer NOT NULL,
    purpose_id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    config_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lendenapp_user_cohort_mapping OWNER TO devmultilenden;

--
-- TOC entry 799 (class 1259 OID 1533238)
-- Name: lendenapp_user_cohert_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_user_cohert_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_user_cohert_mapping_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10242 (class 0 OID 0)
-- Dependencies: 799
-- Name: lendenapp_user_cohert_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_user_cohert_mapping_id_seq OWNED BY public.lendenapp_user_cohort_mapping.id;


--
-- TOC entry 838 (class 1259 OID 1539403)
-- Name: lendenapp_user_gst; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst (
    id integer NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
)
PARTITION BY RANGE (transaction_date);


ALTER TABLE public.lendenapp_user_gst OWNER TO devmultilenden;

--
-- TOC entry 837 (class 1259 OID 1539402)
-- Name: lendenapp_user_gst_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.lendenapp_user_gst_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_user_gst_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10243 (class 0 OID 0)
-- Dependencies: 837
-- Name: lendenapp_user_gst_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.lendenapp_user_gst_id_seq OWNED BY public.lendenapp_user_gst.id;


--
-- TOC entry 839 (class 1259 OID 1539410)
-- Name: lendenapp_user_gst_202503; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202503 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202503 OWNER TO devmultilenden;

--
-- TOC entry 840 (class 1259 OID 1539416)
-- Name: lendenapp_user_gst_202504; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202504 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202504 OWNER TO devmultilenden;

--
-- TOC entry 841 (class 1259 OID 1539422)
-- Name: lendenapp_user_gst_202505; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202505 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202505 OWNER TO devmultilenden;

--
-- TOC entry 842 (class 1259 OID 1539428)
-- Name: lendenapp_user_gst_202506; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202506 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202506 OWNER TO devmultilenden;

--
-- TOC entry 843 (class 1259 OID 1539434)
-- Name: lendenapp_user_gst_202507; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202507 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202507 OWNER TO devmultilenden;

--
-- TOC entry 844 (class 1259 OID 1539440)
-- Name: lendenapp_user_gst_202508; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202508 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202508 OWNER TO devmultilenden;

--
-- TOC entry 845 (class 1259 OID 1539446)
-- Name: lendenapp_user_gst_202509; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202509 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202509 OWNER TO devmultilenden;

--
-- TOC entry 846 (class 1259 OID 1539452)
-- Name: lendenapp_user_gst_202510; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202510 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202510 OWNER TO devmultilenden;

--
-- TOC entry 847 (class 1259 OID 1539458)
-- Name: lendenapp_user_gst_202511; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202511 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202511 OWNER TO devmultilenden;

--
-- TOC entry 848 (class 1259 OID 1539464)
-- Name: lendenapp_user_gst_202512; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202512 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202512 OWNER TO devmultilenden;

--
-- TOC entry 849 (class 1259 OID 1539470)
-- Name: lendenapp_user_gst_202601; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202601 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202601 OWNER TO devmultilenden;

--
-- TOC entry 850 (class 1259 OID 1539476)
-- Name: lendenapp_user_gst_202602; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202602 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202602 OWNER TO devmultilenden;

--
-- TOC entry 851 (class 1259 OID 1539482)
-- Name: lendenapp_user_gst_202603; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202603 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202603 OWNER TO devmultilenden;

--
-- TOC entry 852 (class 1259 OID 1539488)
-- Name: lendenapp_user_gst_202604; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202604 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202604 OWNER TO devmultilenden;

--
-- TOC entry 853 (class 1259 OID 1539494)
-- Name: lendenapp_user_gst_202605; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202605 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202605 OWNER TO devmultilenden;

--
-- TOC entry 854 (class 1259 OID 1539500)
-- Name: lendenapp_user_gst_202606; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202606 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202606 OWNER TO devmultilenden;

--
-- TOC entry 855 (class 1259 OID 1539506)
-- Name: lendenapp_user_gst_202607; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202607 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202607 OWNER TO devmultilenden;

--
-- TOC entry 856 (class 1259 OID 1539512)
-- Name: lendenapp_user_gst_202608; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202608 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202608 OWNER TO devmultilenden;

--
-- TOC entry 857 (class 1259 OID 1539518)
-- Name: lendenapp_user_gst_202609; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202609 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202609 OWNER TO devmultilenden;

--
-- TOC entry 858 (class 1259 OID 1539524)
-- Name: lendenapp_user_gst_202610; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202610 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202610 OWNER TO devmultilenden;

--
-- TOC entry 859 (class 1259 OID 1539530)
-- Name: lendenapp_user_gst_202611; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202611 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202611 OWNER TO devmultilenden;

--
-- TOC entry 860 (class 1259 OID 1539536)
-- Name: lendenapp_user_gst_202612; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202612 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202612 OWNER TO devmultilenden;

--
-- TOC entry 861 (class 1259 OID 1539542)
-- Name: lendenapp_user_gst_202701; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202701 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202701 OWNER TO devmultilenden;

--
-- TOC entry 862 (class 1259 OID 1539548)
-- Name: lendenapp_user_gst_202702; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202702 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202702 OWNER TO devmultilenden;

--
-- TOC entry 863 (class 1259 OID 1539554)
-- Name: lendenapp_user_gst_202703; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202703 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202703 OWNER TO devmultilenden;

--
-- TOC entry 1083 (class 1259 OID 1950247)
-- Name: lendenapp_user_gst_202704; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202704 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202704 OWNER TO devmultilenden;

--
-- TOC entry 1084 (class 1259 OID 1950253)
-- Name: lendenapp_user_gst_202705; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202705 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202705 OWNER TO devmultilenden;

--
-- TOC entry 1085 (class 1259 OID 1950259)
-- Name: lendenapp_user_gst_202706; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202706 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202706 OWNER TO devmultilenden;

--
-- TOC entry 1086 (class 1259 OID 1950265)
-- Name: lendenapp_user_gst_202707; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202707 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202707 OWNER TO devmultilenden;

--
-- TOC entry 1087 (class 1259 OID 1950271)
-- Name: lendenapp_user_gst_202708; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202708 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202708 OWNER TO devmultilenden;

--
-- TOC entry 1088 (class 1259 OID 1950277)
-- Name: lendenapp_user_gst_202709; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202709 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202709 OWNER TO devmultilenden;

--
-- TOC entry 1089 (class 1259 OID 1950283)
-- Name: lendenapp_user_gst_202710; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202710 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202710 OWNER TO devmultilenden;

--
-- TOC entry 1090 (class 1259 OID 1950289)
-- Name: lendenapp_user_gst_202711; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202711 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202711 OWNER TO devmultilenden;

--
-- TOC entry 1091 (class 1259 OID 1950295)
-- Name: lendenapp_user_gst_202712; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202712 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202712 OWNER TO devmultilenden;

--
-- TOC entry 1092 (class 1259 OID 1950301)
-- Name: lendenapp_user_gst_202801; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202801 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202801 OWNER TO devmultilenden;

--
-- TOC entry 1093 (class 1259 OID 1950307)
-- Name: lendenapp_user_gst_202802; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202802 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202802 OWNER TO devmultilenden;

--
-- TOC entry 1094 (class 1259 OID 1950313)
-- Name: lendenapp_user_gst_202803; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202803 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202803 OWNER TO devmultilenden;

--
-- TOC entry 1095 (class 1259 OID 1950319)
-- Name: lendenapp_user_gst_202804; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202804 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202804 OWNER TO devmultilenden;

--
-- TOC entry 1096 (class 1259 OID 1950325)
-- Name: lendenapp_user_gst_202805; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202805 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202805 OWNER TO devmultilenden;

--
-- TOC entry 1097 (class 1259 OID 1950331)
-- Name: lendenapp_user_gst_202806; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202806 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202806 OWNER TO devmultilenden;

--
-- TOC entry 1098 (class 1259 OID 1950337)
-- Name: lendenapp_user_gst_202807; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202807 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202807 OWNER TO devmultilenden;

--
-- TOC entry 1099 (class 1259 OID 1950343)
-- Name: lendenapp_user_gst_202808; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202808 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202808 OWNER TO devmultilenden;

--
-- TOC entry 1100 (class 1259 OID 1950349)
-- Name: lendenapp_user_gst_202809; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202809 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202809 OWNER TO devmultilenden;

--
-- TOC entry 1101 (class 1259 OID 1950355)
-- Name: lendenapp_user_gst_202810; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202810 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202810 OWNER TO devmultilenden;

--
-- TOC entry 1102 (class 1259 OID 1950361)
-- Name: lendenapp_user_gst_202811; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202811 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202811 OWNER TO devmultilenden;

--
-- TOC entry 1103 (class 1259 OID 1950367)
-- Name: lendenapp_user_gst_202812; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202812 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202812 OWNER TO devmultilenden;

--
-- TOC entry 1104 (class 1259 OID 1950373)
-- Name: lendenapp_user_gst_202901; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202901 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202901 OWNER TO devmultilenden;

--
-- TOC entry 1105 (class 1259 OID 1950379)
-- Name: lendenapp_user_gst_202902; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202902 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202902 OWNER TO devmultilenden;

--
-- TOC entry 1106 (class 1259 OID 1950385)
-- Name: lendenapp_user_gst_202903; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202903 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202903 OWNER TO devmultilenden;

--
-- TOC entry 1107 (class 1259 OID 1950391)
-- Name: lendenapp_user_gst_202904; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202904 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202904 OWNER TO devmultilenden;

--
-- TOC entry 1108 (class 1259 OID 1950397)
-- Name: lendenapp_user_gst_202905; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202905 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202905 OWNER TO devmultilenden;

--
-- TOC entry 1109 (class 1259 OID 1950403)
-- Name: lendenapp_user_gst_202906; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202906 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202906 OWNER TO devmultilenden;

--
-- TOC entry 1110 (class 1259 OID 1950409)
-- Name: lendenapp_user_gst_202907; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202907 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202907 OWNER TO devmultilenden;

--
-- TOC entry 1111 (class 1259 OID 1950415)
-- Name: lendenapp_user_gst_202908; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202908 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202908 OWNER TO devmultilenden;

--
-- TOC entry 1112 (class 1259 OID 1950421)
-- Name: lendenapp_user_gst_202909; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202909 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202909 OWNER TO devmultilenden;

--
-- TOC entry 1113 (class 1259 OID 1950427)
-- Name: lendenapp_user_gst_202910; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202910 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202910 OWNER TO devmultilenden;

--
-- TOC entry 1114 (class 1259 OID 1950433)
-- Name: lendenapp_user_gst_202911; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202911 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202911 OWNER TO devmultilenden;

--
-- TOC entry 1115 (class 1259 OID 1950439)
-- Name: lendenapp_user_gst_202912; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_202912 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_202912 OWNER TO devmultilenden;

--
-- TOC entry 1116 (class 1259 OID 1950445)
-- Name: lendenapp_user_gst_203001; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203001 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203001 OWNER TO devmultilenden;

--
-- TOC entry 1117 (class 1259 OID 1950451)
-- Name: lendenapp_user_gst_203002; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203002 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203002 OWNER TO devmultilenden;

--
-- TOC entry 1118 (class 1259 OID 1950457)
-- Name: lendenapp_user_gst_203003; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203003 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203003 OWNER TO devmultilenden;

--
-- TOC entry 1119 (class 1259 OID 1950463)
-- Name: lendenapp_user_gst_203004; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203004 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203004 OWNER TO devmultilenden;

--
-- TOC entry 1120 (class 1259 OID 1950469)
-- Name: lendenapp_user_gst_203005; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203005 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203005 OWNER TO devmultilenden;

--
-- TOC entry 1121 (class 1259 OID 1950475)
-- Name: lendenapp_user_gst_203006; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203006 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203006 OWNER TO devmultilenden;

--
-- TOC entry 1122 (class 1259 OID 1950481)
-- Name: lendenapp_user_gst_203007; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203007 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203007 OWNER TO devmultilenden;

--
-- TOC entry 1123 (class 1259 OID 1950487)
-- Name: lendenapp_user_gst_203008; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203008 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203008 OWNER TO devmultilenden;

--
-- TOC entry 1124 (class 1259 OID 1950493)
-- Name: lendenapp_user_gst_203009; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203009 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203009 OWNER TO devmultilenden;

--
-- TOC entry 1125 (class 1259 OID 1950499)
-- Name: lendenapp_user_gst_203010; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203010 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203010 OWNER TO devmultilenden;

--
-- TOC entry 1126 (class 1259 OID 1950505)
-- Name: lendenapp_user_gst_203011; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203011 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203011 OWNER TO devmultilenden;

--
-- TOC entry 1127 (class 1259 OID 1950511)
-- Name: lendenapp_user_gst_203012; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203012 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203012 OWNER TO devmultilenden;

--
-- TOC entry 1128 (class 1259 OID 1950517)
-- Name: lendenapp_user_gst_203101; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203101 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203101 OWNER TO devmultilenden;

--
-- TOC entry 1129 (class 1259 OID 1950523)
-- Name: lendenapp_user_gst_203102; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203102 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203102 OWNER TO devmultilenden;

--
-- TOC entry 1130 (class 1259 OID 1950529)
-- Name: lendenapp_user_gst_203103; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203103 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203103 OWNER TO devmultilenden;

--
-- TOC entry 1131 (class 1259 OID 1950535)
-- Name: lendenapp_user_gst_203104; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203104 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203104 OWNER TO devmultilenden;

--
-- TOC entry 1132 (class 1259 OID 1950541)
-- Name: lendenapp_user_gst_203105; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203105 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203105 OWNER TO devmultilenden;

--
-- TOC entry 1133 (class 1259 OID 1950547)
-- Name: lendenapp_user_gst_203106; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203106 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203106 OWNER TO devmultilenden;

--
-- TOC entry 1134 (class 1259 OID 1950553)
-- Name: lendenapp_user_gst_203107; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203107 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203107 OWNER TO devmultilenden;

--
-- TOC entry 1135 (class 1259 OID 1950559)
-- Name: lendenapp_user_gst_203108; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203108 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203108 OWNER TO devmultilenden;

--
-- TOC entry 1136 (class 1259 OID 1950565)
-- Name: lendenapp_user_gst_203109; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203109 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203109 OWNER TO devmultilenden;

--
-- TOC entry 1137 (class 1259 OID 1950571)
-- Name: lendenapp_user_gst_203110; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203110 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203110 OWNER TO devmultilenden;

--
-- TOC entry 1138 (class 1259 OID 1950577)
-- Name: lendenapp_user_gst_203111; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203111 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203111 OWNER TO devmultilenden;

--
-- TOC entry 1139 (class 1259 OID 1950583)
-- Name: lendenapp_user_gst_203112; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203112 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203112 OWNER TO devmultilenden;

--
-- TOC entry 1140 (class 1259 OID 1950589)
-- Name: lendenapp_user_gst_203201; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203201 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203201 OWNER TO devmultilenden;

--
-- TOC entry 1141 (class 1259 OID 1950595)
-- Name: lendenapp_user_gst_203202; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203202 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203202 OWNER TO devmultilenden;

--
-- TOC entry 1142 (class 1259 OID 1950601)
-- Name: lendenapp_user_gst_203203; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203203 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203203 OWNER TO devmultilenden;

--
-- TOC entry 1143 (class 1259 OID 1950607)
-- Name: lendenapp_user_gst_203204; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203204 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203204 OWNER TO devmultilenden;

--
-- TOC entry 1144 (class 1259 OID 1950613)
-- Name: lendenapp_user_gst_203205; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203205 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203205 OWNER TO devmultilenden;

--
-- TOC entry 1145 (class 1259 OID 1950619)
-- Name: lendenapp_user_gst_203206; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203206 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203206 OWNER TO devmultilenden;

--
-- TOC entry 1146 (class 1259 OID 1950625)
-- Name: lendenapp_user_gst_203207; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203207 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203207 OWNER TO devmultilenden;

--
-- TOC entry 1147 (class 1259 OID 1950631)
-- Name: lendenapp_user_gst_203208; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203208 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203208 OWNER TO devmultilenden;

--
-- TOC entry 1148 (class 1259 OID 1950637)
-- Name: lendenapp_user_gst_203209; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203209 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203209 OWNER TO devmultilenden;

--
-- TOC entry 1149 (class 1259 OID 1950643)
-- Name: lendenapp_user_gst_203210; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203210 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203210 OWNER TO devmultilenden;

--
-- TOC entry 1150 (class 1259 OID 1950649)
-- Name: lendenapp_user_gst_203211; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203211 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203211 OWNER TO devmultilenden;

--
-- TOC entry 1151 (class 1259 OID 1950655)
-- Name: lendenapp_user_gst_203212; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203212 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203212 OWNER TO devmultilenden;

--
-- TOC entry 1152 (class 1259 OID 1950661)
-- Name: lendenapp_user_gst_203301; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203301 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203301 OWNER TO devmultilenden;

--
-- TOC entry 1153 (class 1259 OID 1950667)
-- Name: lendenapp_user_gst_203302; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203302 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203302 OWNER TO devmultilenden;

--
-- TOC entry 1154 (class 1259 OID 1950673)
-- Name: lendenapp_user_gst_203303; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203303 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203303 OWNER TO devmultilenden;

--
-- TOC entry 1155 (class 1259 OID 1950679)
-- Name: lendenapp_user_gst_203304; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203304 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203304 OWNER TO devmultilenden;

--
-- TOC entry 1156 (class 1259 OID 1950685)
-- Name: lendenapp_user_gst_203305; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203305 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203305 OWNER TO devmultilenden;

--
-- TOC entry 1157 (class 1259 OID 1950691)
-- Name: lendenapp_user_gst_203306; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203306 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203306 OWNER TO devmultilenden;

--
-- TOC entry 1158 (class 1259 OID 1950697)
-- Name: lendenapp_user_gst_203307; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203307 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203307 OWNER TO devmultilenden;

--
-- TOC entry 1159 (class 1259 OID 1950703)
-- Name: lendenapp_user_gst_203308; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203308 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203308 OWNER TO devmultilenden;

--
-- TOC entry 1160 (class 1259 OID 1950709)
-- Name: lendenapp_user_gst_203309; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203309 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203309 OWNER TO devmultilenden;

--
-- TOC entry 1161 (class 1259 OID 1950715)
-- Name: lendenapp_user_gst_203310; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203310 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203310 OWNER TO devmultilenden;

--
-- TOC entry 1162 (class 1259 OID 1950721)
-- Name: lendenapp_user_gst_203311; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203311 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203311 OWNER TO devmultilenden;

--
-- TOC entry 1163 (class 1259 OID 1950727)
-- Name: lendenapp_user_gst_203312; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203312 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203312 OWNER TO devmultilenden;

--
-- TOC entry 1164 (class 1259 OID 1950733)
-- Name: lendenapp_user_gst_203401; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203401 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203401 OWNER TO devmultilenden;

--
-- TOC entry 1165 (class 1259 OID 1950739)
-- Name: lendenapp_user_gst_203402; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203402 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203402 OWNER TO devmultilenden;

--
-- TOC entry 1166 (class 1259 OID 1950745)
-- Name: lendenapp_user_gst_203403; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203403 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203403 OWNER TO devmultilenden;

--
-- TOC entry 1167 (class 1259 OID 1950751)
-- Name: lendenapp_user_gst_203404; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203404 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203404 OWNER TO devmultilenden;

--
-- TOC entry 1168 (class 1259 OID 1950757)
-- Name: lendenapp_user_gst_203405; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203405 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203405 OWNER TO devmultilenden;

--
-- TOC entry 1169 (class 1259 OID 1950763)
-- Name: lendenapp_user_gst_203406; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203406 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203406 OWNER TO devmultilenden;

--
-- TOC entry 1170 (class 1259 OID 1950769)
-- Name: lendenapp_user_gst_203407; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203407 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203407 OWNER TO devmultilenden;

--
-- TOC entry 1171 (class 1259 OID 1950775)
-- Name: lendenapp_user_gst_203408; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203408 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203408 OWNER TO devmultilenden;

--
-- TOC entry 1172 (class 1259 OID 1950781)
-- Name: lendenapp_user_gst_203409; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203409 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203409 OWNER TO devmultilenden;

--
-- TOC entry 1173 (class 1259 OID 1950787)
-- Name: lendenapp_user_gst_203410; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203410 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203410 OWNER TO devmultilenden;

--
-- TOC entry 1174 (class 1259 OID 1950793)
-- Name: lendenapp_user_gst_203411; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203411 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203411 OWNER TO devmultilenden;

--
-- TOC entry 1175 (class 1259 OID 1950799)
-- Name: lendenapp_user_gst_203412; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203412 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203412 OWNER TO devmultilenden;

--
-- TOC entry 1176 (class 1259 OID 1950805)
-- Name: lendenapp_user_gst_203501; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203501 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203501 OWNER TO devmultilenden;

--
-- TOC entry 1177 (class 1259 OID 1950811)
-- Name: lendenapp_user_gst_203502; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203502 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203502 OWNER TO devmultilenden;

--
-- TOC entry 1178 (class 1259 OID 1950817)
-- Name: lendenapp_user_gst_203503; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203503 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203503 OWNER TO devmultilenden;

--
-- TOC entry 1179 (class 1259 OID 1950823)
-- Name: lendenapp_user_gst_203504; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203504 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203504 OWNER TO devmultilenden;

--
-- TOC entry 1180 (class 1259 OID 1950829)
-- Name: lendenapp_user_gst_203505; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203505 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203505 OWNER TO devmultilenden;

--
-- TOC entry 1181 (class 1259 OID 1950835)
-- Name: lendenapp_user_gst_203506; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203506 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203506 OWNER TO devmultilenden;

--
-- TOC entry 1182 (class 1259 OID 1950841)
-- Name: lendenapp_user_gst_203507; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203507 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203507 OWNER TO devmultilenden;

--
-- TOC entry 1183 (class 1259 OID 1950847)
-- Name: lendenapp_user_gst_203508; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203508 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203508 OWNER TO devmultilenden;

--
-- TOC entry 1184 (class 1259 OID 1950853)
-- Name: lendenapp_user_gst_203509; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203509 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203509 OWNER TO devmultilenden;

--
-- TOC entry 1185 (class 1259 OID 1950859)
-- Name: lendenapp_user_gst_203510; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203510 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203510 OWNER TO devmultilenden;

--
-- TOC entry 1186 (class 1259 OID 1950865)
-- Name: lendenapp_user_gst_203511; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203511 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203511 OWNER TO devmultilenden;

--
-- TOC entry 1187 (class 1259 OID 1950871)
-- Name: lendenapp_user_gst_203512; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203512 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203512 OWNER TO devmultilenden;

--
-- TOC entry 1188 (class 1259 OID 1950877)
-- Name: lendenapp_user_gst_203601; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203601 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203601 OWNER TO devmultilenden;

--
-- TOC entry 1189 (class 1259 OID 1950883)
-- Name: lendenapp_user_gst_203602; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203602 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203602 OWNER TO devmultilenden;

--
-- TOC entry 1190 (class 1259 OID 1950889)
-- Name: lendenapp_user_gst_203603; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203603 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203603 OWNER TO devmultilenden;

--
-- TOC entry 1191 (class 1259 OID 1950895)
-- Name: lendenapp_user_gst_203604; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203604 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203604 OWNER TO devmultilenden;

--
-- TOC entry 1192 (class 1259 OID 1950901)
-- Name: lendenapp_user_gst_203605; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203605 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203605 OWNER TO devmultilenden;

--
-- TOC entry 1193 (class 1259 OID 1950907)
-- Name: lendenapp_user_gst_203606; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203606 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203606 OWNER TO devmultilenden;

--
-- TOC entry 1194 (class 1259 OID 1950913)
-- Name: lendenapp_user_gst_203607; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203607 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203607 OWNER TO devmultilenden;

--
-- TOC entry 1195 (class 1259 OID 1950919)
-- Name: lendenapp_user_gst_203608; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203608 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203608 OWNER TO devmultilenden;

--
-- TOC entry 1196 (class 1259 OID 1950925)
-- Name: lendenapp_user_gst_203609; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203609 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203609 OWNER TO devmultilenden;

--
-- TOC entry 1197 (class 1259 OID 1950931)
-- Name: lendenapp_user_gst_203610; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203610 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203610 OWNER TO devmultilenden;

--
-- TOC entry 1198 (class 1259 OID 1950937)
-- Name: lendenapp_user_gst_203611; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203611 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203611 OWNER TO devmultilenden;

--
-- TOC entry 1199 (class 1259 OID 1950943)
-- Name: lendenapp_user_gst_203612; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203612 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203612 OWNER TO devmultilenden;

--
-- TOC entry 1200 (class 1259 OID 1950949)
-- Name: lendenapp_user_gst_203701; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203701 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203701 OWNER TO devmultilenden;

--
-- TOC entry 1201 (class 1259 OID 1950955)
-- Name: lendenapp_user_gst_203702; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203702 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203702 OWNER TO devmultilenden;

--
-- TOC entry 1202 (class 1259 OID 1950961)
-- Name: lendenapp_user_gst_203703; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203703 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203703 OWNER TO devmultilenden;

--
-- TOC entry 1203 (class 1259 OID 1950967)
-- Name: lendenapp_user_gst_203704; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203704 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203704 OWNER TO devmultilenden;

--
-- TOC entry 1204 (class 1259 OID 1950973)
-- Name: lendenapp_user_gst_203705; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203705 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203705 OWNER TO devmultilenden;

--
-- TOC entry 1205 (class 1259 OID 1950979)
-- Name: lendenapp_user_gst_203706; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203706 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203706 OWNER TO devmultilenden;

--
-- TOC entry 1206 (class 1259 OID 1950985)
-- Name: lendenapp_user_gst_203707; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203707 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203707 OWNER TO devmultilenden;

--
-- TOC entry 1207 (class 1259 OID 1950991)
-- Name: lendenapp_user_gst_203708; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203708 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203708 OWNER TO devmultilenden;

--
-- TOC entry 1208 (class 1259 OID 1950997)
-- Name: lendenapp_user_gst_203709; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203709 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203709 OWNER TO devmultilenden;

--
-- TOC entry 1209 (class 1259 OID 1951003)
-- Name: lendenapp_user_gst_203710; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203710 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203710 OWNER TO devmultilenden;

--
-- TOC entry 1210 (class 1259 OID 1951009)
-- Name: lendenapp_user_gst_203711; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203711 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203711 OWNER TO devmultilenden;

--
-- TOC entry 1211 (class 1259 OID 1951015)
-- Name: lendenapp_user_gst_203712; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203712 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203712 OWNER TO devmultilenden;

--
-- TOC entry 1212 (class 1259 OID 1951021)
-- Name: lendenapp_user_gst_203801; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203801 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203801 OWNER TO devmultilenden;

--
-- TOC entry 1213 (class 1259 OID 1951027)
-- Name: lendenapp_user_gst_203802; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203802 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203802 OWNER TO devmultilenden;

--
-- TOC entry 1214 (class 1259 OID 1951033)
-- Name: lendenapp_user_gst_203803; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203803 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203803 OWNER TO devmultilenden;

--
-- TOC entry 1215 (class 1259 OID 1951039)
-- Name: lendenapp_user_gst_203804; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203804 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203804 OWNER TO devmultilenden;

--
-- TOC entry 1216 (class 1259 OID 1951045)
-- Name: lendenapp_user_gst_203805; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203805 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203805 OWNER TO devmultilenden;

--
-- TOC entry 1217 (class 1259 OID 1951051)
-- Name: lendenapp_user_gst_203806; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203806 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203806 OWNER TO devmultilenden;

--
-- TOC entry 1218 (class 1259 OID 1951057)
-- Name: lendenapp_user_gst_203807; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203807 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203807 OWNER TO devmultilenden;

--
-- TOC entry 1219 (class 1259 OID 1951063)
-- Name: lendenapp_user_gst_203808; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203808 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203808 OWNER TO devmultilenden;

--
-- TOC entry 1220 (class 1259 OID 1951069)
-- Name: lendenapp_user_gst_203809; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203809 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203809 OWNER TO devmultilenden;

--
-- TOC entry 1221 (class 1259 OID 1951075)
-- Name: lendenapp_user_gst_203810; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203810 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203810 OWNER TO devmultilenden;

--
-- TOC entry 1222 (class 1259 OID 1951081)
-- Name: lendenapp_user_gst_203811; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203811 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203811 OWNER TO devmultilenden;

--
-- TOC entry 1223 (class 1259 OID 1951087)
-- Name: lendenapp_user_gst_203812; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203812 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203812 OWNER TO devmultilenden;

--
-- TOC entry 1224 (class 1259 OID 1951093)
-- Name: lendenapp_user_gst_203901; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203901 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203901 OWNER TO devmultilenden;

--
-- TOC entry 1225 (class 1259 OID 1951099)
-- Name: lendenapp_user_gst_203902; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203902 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203902 OWNER TO devmultilenden;

--
-- TOC entry 1226 (class 1259 OID 1951105)
-- Name: lendenapp_user_gst_203903; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203903 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203903 OWNER TO devmultilenden;

--
-- TOC entry 1227 (class 1259 OID 1951111)
-- Name: lendenapp_user_gst_203904; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203904 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203904 OWNER TO devmultilenden;

--
-- TOC entry 1228 (class 1259 OID 1951117)
-- Name: lendenapp_user_gst_203905; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203905 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203905 OWNER TO devmultilenden;

--
-- TOC entry 1229 (class 1259 OID 1951123)
-- Name: lendenapp_user_gst_203906; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203906 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203906 OWNER TO devmultilenden;

--
-- TOC entry 1230 (class 1259 OID 1951129)
-- Name: lendenapp_user_gst_203907; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203907 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203907 OWNER TO devmultilenden;

--
-- TOC entry 1231 (class 1259 OID 1951135)
-- Name: lendenapp_user_gst_203908; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203908 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203908 OWNER TO devmultilenden;

--
-- TOC entry 1232 (class 1259 OID 1951141)
-- Name: lendenapp_user_gst_203909; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203909 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203909 OWNER TO devmultilenden;

--
-- TOC entry 1233 (class 1259 OID 1951147)
-- Name: lendenapp_user_gst_203910; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203910 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203910 OWNER TO devmultilenden;

--
-- TOC entry 1234 (class 1259 OID 1951153)
-- Name: lendenapp_user_gst_203911; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203911 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203911 OWNER TO devmultilenden;

--
-- TOC entry 1235 (class 1259 OID 1951159)
-- Name: lendenapp_user_gst_203912; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_203912 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_203912 OWNER TO devmultilenden;

--
-- TOC entry 1236 (class 1259 OID 1951165)
-- Name: lendenapp_user_gst_204001; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_204001 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_204001 OWNER TO devmultilenden;

--
-- TOC entry 1237 (class 1259 OID 1951171)
-- Name: lendenapp_user_gst_204002; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_204002 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_204002 OWNER TO devmultilenden;

--
-- TOC entry 1238 (class 1259 OID 1951177)
-- Name: lendenapp_user_gst_204003; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_user_gst_204003 (
    id integer DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass) NOT NULL,
    taxable_amount numeric(18,2),
    cgst numeric(18,2),
    sgst numeric(18,2),
    igst numeric(18,2),
    purpose character varying(10),
    partner_code character varying(10),
    in_invoice_id character varying(16),
    ci_invoice_id character varying(16),
    in_invoice_date date,
    ci_invoice_date date,
    transaction_date date NOT NULL,
    state character varying(50),
    state_code integer,
    user_id integer,
    created_date timestamp with time zone,
    amount numeric(18,2),
    in_document_id integer,
    ci_document_id integer
);


ALTER TABLE public.lendenapp_user_gst_204003 OWNER TO devmultilenden;

--
-- TOC entry 298 (class 1259 OID 964792)
-- Name: lendenapp_user_report_log; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_user_report_log (
    id integer NOT NULL,
    scheme_id character varying(20),
    report_type character varying(30) NOT NULL,
    sent_date timestamp with time zone,
    status character varying(10),
    user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_user_report_log OWNER TO usrinvoswrt;

--
-- TOC entry 297 (class 1259 OID 964791)
-- Name: lendenapp_user_report_log_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_user_report_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_user_report_log_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10244 (class 0 OID 0)
-- Dependencies: 297
-- Name: lendenapp_user_report_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_user_report_log_id_seq OWNED BY public.lendenapp_user_report_log.id;


--
-- TOC entry 237 (class 1259 OID 745143)
-- Name: lendenapp_user_source_group_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_user_source_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_user_source_group_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10245 (class 0 OID 0)
-- Dependencies: 237
-- Name: lendenapp_user_source_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_user_source_group_id_seq OWNED BY public.lendenapp_user_source_group.id;


--
-- TOC entry 282 (class 1259 OID 964490)
-- Name: lendenapp_userconsentlog; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_userconsentlog (
    id bigint NOT NULL,
    consent_type character varying(50),
    consent_value character varying(10),
    remark character varying(250),
    task_id integer,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id integer
);


ALTER TABLE public.lendenapp_userconsentlog OWNER TO usrinvoswrt;

--
-- TOC entry 281 (class 1259 OID 964489)
-- Name: lendenapp_userconsentlog_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_userconsentlog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_userconsentlog_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10246 (class 0 OID 0)
-- Dependencies: 281
-- Name: lendenapp_userconsentlog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_userconsentlog_id_seq OWNED BY public.lendenapp_userconsentlog.id;


--
-- TOC entry 252 (class 1259 OID 865991)
-- Name: lendenapp_userkyc; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_userkyc (
    id integer NOT NULL,
    tracking_id character varying(30) NOT NULL,
    status character varying(15),
    poi_name character varying(100),
    poa_name character varying(100),
    json_response jsonb,
    service_type character varying(20),
    user_kyc_consent boolean DEFAULT true NOT NULL,
    task_id integer,
    user_id integer NOT NULL,
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_status character varying(15),
    provider character varying(30),
    event_code character varying(100),
    status_code smallint
);


ALTER TABLE public.lendenapp_userkyc OWNER TO usrinvoswrt;

--
-- TOC entry 251 (class 1259 OID 865990)
-- Name: lendenapp_userkyc_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_userkyc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_userkyc_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10247 (class 0 OID 0)
-- Dependencies: 251
-- Name: lendenapp_userkyc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_userkyc_id_seq OWNED BY public.lendenapp_userkyc.id;


--
-- TOC entry 316 (class 1259 OID 967007)
-- Name: lendenapp_userkyctracker; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_userkyctracker (
    id integer NOT NULL,
    tracking_id character varying(50),
    status character varying(20) NOT NULL,
    kyc_type character varying(20) NOT NULL,
    next_kyc_date date,
    risk_type character varying(10),
    kyc_source character varying(20) NOT NULL,
    is_latest_kyc boolean DEFAULT false NOT NULL,
    task_id bigint,
    user_id bigint NOT NULL,
    next_due_diligence_date date,
    aml_category character varying(20),
    user_source_group_id integer,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_cersai_uploaded boolean DEFAULT false NOT NULL,
    aml_tracking_id character varying(50),
    aml_check boolean DEFAULT false NOT NULL,
    is_pep boolean DEFAULT false NOT NULL,
    is_uapa boolean DEFAULT false NOT NULL,
    is_unsc boolean DEFAULT false NOT NULL,
    aml_status character varying(10),
    aml_remark character varying(200),
    is_profile_upload boolean DEFAULT false NOT NULL,
    overall_is_pep boolean DEFAULT false NOT NULL,
    re_aml_status character varying(20),
    name_match_status character varying(15)
);


ALTER TABLE public.lendenapp_userkyctracker OWNER TO usrinvoswrt;

--
-- TOC entry 315 (class 1259 OID 967006)
-- Name: lendenapp_userkyctracker_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_userkyctracker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_userkyctracker_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10248 (class 0 OID 0)
-- Dependencies: 315
-- Name: lendenapp_userkyctracker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_userkyctracker_id_seq OWNED BY public.lendenapp_userkyctracker.id;


--
-- TOC entry 300 (class 1259 OID 964806)
-- Name: lendenapp_userotp; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_userotp (
    id integer NOT NULL,
    mobile_number character varying(15) NOT NULL,
    key character varying(6) NOT NULL,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_userotp OWNER TO usrinvoswrt;

--
-- TOC entry 299 (class 1259 OID 964805)
-- Name: lendenapp_userotp_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_userotp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_userotp_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10249 (class 0 OID 0)
-- Dependencies: 299
-- Name: lendenapp_userotp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_userotp_id_seq OWNED BY public.lendenapp_userotp.id;


--
-- TOC entry 284 (class 1259 OID 964499)
-- Name: lendenapp_userupimandate; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_userupimandate (
    id integer NOT NULL,
    scheme_id character varying(20),
    mandate_request_id character varying(20) NOT NULL,
    subscription_name character varying(30) NOT NULL,
    subscription_description character varying(50) NOT NULL,
    frequency character varying(10),
    first_deduction_amount numeric(19,4) NOT NULL,
    recurring_count integer,
    max_amount numeric(19,4) NOT NULL,
    recurring_start_dtm timestamp with time zone,
    recurring_end_dtm timestamp with time zone,
    mandate_status character varying(10),
    scheme_status boolean DEFAULT false NOT NULL,
    pause_date date,
    cancel_date date,
    lenden_transaction_id integer,
    next_installment_dtm timestamp with time zone,
    user_id integer,
    remarks character varying(35),
    task_id bigint,
    user_source_group_id integer NOT NULL,
    created_dtm timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_dtm timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_userupimandate OWNER TO usrinvoswrt;

--
-- TOC entry 283 (class 1259 OID 964498)
-- Name: lendenapp_userupimandate_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_userupimandate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_userupimandate_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10250 (class 0 OID 0)
-- Dependencies: 283
-- Name: lendenapp_userupimandate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_userupimandate_id_seq OWNED BY public.lendenapp_userupimandate.id;


--
-- TOC entry 312 (class 1259 OID 964933)
-- Name: lendenapp_utilitypreferences; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_utilitypreferences (
    id integer NOT NULL,
    utility_name character varying(50) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    remarks character varying(100),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_utilitypreferences OWNER TO usrinvoswrt;

--
-- TOC entry 311 (class 1259 OID 964932)
-- Name: lendenapp_utilitypreferences_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_utilitypreferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_utilitypreferences_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10251 (class 0 OID 0)
-- Dependencies: 311
-- Name: lendenapp_utilitypreferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_utilitypreferences_id_seq OWNED BY public.lendenapp_utilitypreferences.id;


--
-- TOC entry 302 (class 1259 OID 964816)
-- Name: lendenapp_withdrawalsummary; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.lendenapp_withdrawalsummary (
    id integer NOT NULL,
    transaction_sum numeric(18,4) NOT NULL,
    user_count smallint NOT NULL,
    transaction_count smallint NOT NULL,
    batch_reference_number character varying(30) NOT NULL,
    withdrawal_filename_reference character varying(120) NOT NULL,
    withdrawal_datetime timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.lendenapp_withdrawalsummary OWNER TO usrinvoswrt;

--
-- TOC entry 301 (class 1259 OID 964815)
-- Name: lendenapp_withdrawalsummary_id_seq; Type: SEQUENCE; Schema: public; Owner: usrinvoswrt
--

CREATE SEQUENCE public.lendenapp_withdrawalsummary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lendenapp_withdrawalsummary_id_seq OWNER TO usrinvoswrt;

--
-- TOC entry 10252 (class 0 OID 0)
-- Dependencies: 301
-- Name: lendenapp_withdrawalsummary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: usrinvoswrt
--

ALTER SEQUENCE public.lendenapp_withdrawalsummary_id_seq OWNED BY public.lendenapp_withdrawalsummary.id;


--
-- TOC entry 865 (class 1259 OID 1539568)
-- Name: lendenapp_zoho_user_data; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.lendenapp_zoho_user_data (
    id bigint NOT NULL,
    user_id integer,
    user_source_group_id integer,
    user_name character varying(100),
    user_email character varying(100),
    zoho_user_id bigint NOT NULL,
    owner_id bigint,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    to_update boolean DEFAULT false NOT NULL
);


ALTER TABLE public.lendenapp_zoho_user_data OWNER TO devmultilenden;

--
-- TOC entry 804 (class 1259 OID 1536577)
-- Name: mv_lender_cp_data; Type: MATERIALIZED VIEW; Schema: public; Owner: devmultilenden
--

CREATE MATERIALIZED VIEW public.mv_lender_cp_data AS
 SELECT lc.first_name AS lender_name,
    lc.encoded_email AS lender_email,
    lc.user_id AS lender_user_id,
    lc.id AS user_pk,
    la.status AS account_status,
    lc3.first_name AS cp_name,
    lc2.partner_id,
    lc.encoded_mobile AS lender_mobile,
    lc3.user_id AS cp_user_id,
    lc3.id AS cp_pk,
    lc3.encoded_email AS cp_email,
    lc3.encoded_mobile AS cp_mobile,
    ls.source_name,
    lusg.id AS user_source_group_id
   FROM (((((public.lendenapp_user_source_group lusg
     JOIN public.lendenapp_customuser lc ON ((lc.id = lusg.user_id)))
     JOIN public.lendenapp_source ls ON ((ls.id = lusg.source_id)))
     JOIN public.lendenapp_account la ON ((la.user_source_group_id = lusg.id)))
     LEFT JOIN public.lendenapp_channelpartner lc2 ON ((lc2.id = lusg.channel_partner_id)))
     LEFT JOIN public.lendenapp_customuser lc3 ON ((lc3.id = lc2.user_id)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_lender_cp_data OWNER TO devmultilenden;

--
-- TOC entry 1241 (class 1259 OID 1971425)
-- Name: pivot_tables; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.pivot_tables (
    table_catalog character varying(255),
    table_schema character varying(255),
    table_name character varying(255),
    columns_with_datatypes text,
    description character varying(250)
);


ALTER TABLE public.pivot_tables OWNER TO devmultilenden;

--
-- TOC entry 255 (class 1259 OID 932562)
-- Name: raw_all_investor_data; Type: TABLE; Schema: public; Owner: usrinvoswrt
--

CREATE TABLE public.raw_all_investor_data (
    customuser_id integer,
    customuser_user_id character varying(255),
    customuser_password character varying(300),
    customuser_ucic_code character varying(20),
    customuser_mobile_number character varying(64),
    customuser_pan character varying(64),
    customuser_first_name character varying(500),
    customuser_middle_name character varying(150),
    customuser_last_name character varying(150),
    customuser_email character varying(255),
    customuser_email_verification boolean,
    customuser_dob date,
    customuser_gender character varying(50),
    customuser_marital_status character varying(15),
    customuser_aadhar character varying(64),
    customuser_gross_annual_income character varying(50),
    customuser_type character varying(40),
    customuser_device_id character varying(255),
    customuser_is_active boolean,
    customuser_last_login timestamp with time zone,
    customuser_created_date timestamp with time zone,
    customuser_modified_date timestamp with time zone,
    customuser_is_migrated boolean,
    source_group_id integer,
    source_group_user_id integer,
    source_group_source_id integer,
    source_group_group_id integer,
    source_group_channel_partner_id integer,
    source_group_status character varying(20),
    source_group_created_at timestamp without time zone,
    source_group_updated_at timestamp without time zone,
    task_id integer,
    task_checklist text,
    task_updated_date timestamp with time zone,
    task_assigned_by_id integer,
    task_created_by_id integer,
    task_user_source_group_id numeric,
    task_created_date timestamp with time zone,
    account_id integer,
    account_user_id integer,
    account_status character varying(10),
    account_number character varying(25),
    account_action character varying(10),
    account_balance double precision,
    account_action_amount double precision,
    account_previous_balance double precision,
    account_bank_account_id integer,
    account_task_id integer,
    account_created_date timestamp with time zone,
    account_updated_date timestamp with time zone,
    custom_group_id integer,
    custom_group_customuser_id integer,
    custom_group_group_id integer,
    customuser_migrated boolean DEFAULT false,
    primary_tables_migrated boolean DEFAULT false,
    secondary_tables_migrated boolean DEFAULT false,
    customuser_adid character varying(100),
    account_listed_date date
);


ALTER TABLE public.raw_all_investor_data OWNER TO usrinvoswrt;

--
-- TOC entry 736 (class 1259 OID 1069926)
-- Name: reverse_penny_drop; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.reverse_penny_drop (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_source_group_id integer NOT NULL,
    tracking_id character varying(50),
    verification_id character varying(16) NOT NULL,
    status character varying(10) NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    remark text
);


ALTER TABLE public.reverse_penny_drop OWNER TO devmultilenden;

--
-- TOC entry 735 (class 1259 OID 1069925)
-- Name: reverse_penny_drop_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.reverse_penny_drop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reverse_penny_drop_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10253 (class 0 OID 0)
-- Dependencies: 735
-- Name: reverse_penny_drop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.reverse_penny_drop_id_seq OWNED BY public.reverse_penny_drop.id;


--
-- TOC entry 761 (class 1259 OID 1342768)
-- Name: user_state; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.user_state (
    mobile character varying(20),
    state character varying(100)
);


ALTER TABLE public.user_state OWNER TO devmultilenden;

--
-- TOC entry 790 (class 1259 OID 1528572)
-- Name: v_live_loan_count; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.v_live_loan_count (
    count bigint
);


ALTER TABLE public.v_live_loan_count OWNER TO devmultilenden;

--
-- TOC entry 764 (class 1259 OID 1454118)
-- Name: v_tracking_records; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.v_tracking_records (
    id integer,
    scheme_id character varying(30),
    batch_number character varying(30),
    created_date timestamp with time zone,
    updated_date timestamp with time zone,
    is_latest boolean,
    amount_per_loan numeric(18,4),
    loan_count integer,
    user_source_group_id integer,
    expiry_dtm timestamp with time zone,
    preference_id integer,
    tenure integer,
    to_be_notified boolean,
    status character varying(30),
    lending_amount numeric(18,4),
    transaction_id integer,
    notification_type public.notification_type_enum
);


ALTER TABLE public.v_tracking_records OWNER TO devmultilenden;

--
-- TOC entry 803 (class 1259 OID 1535513)
-- Name: vipul_analysis; Type: TABLE; Schema: public; Owner: devmultilenden
--

CREATE TABLE public.vipul_analysis (
    api character varying,
    "time" timestamp without time zone,
    user_id character varying
);


ALTER TABLE public.vipul_analysis OWNER TO devmultilenden;

--
-- TOC entry 864 (class 1259 OID 1539567)
-- Name: zoho_user_data_id_seq; Type: SEQUENCE; Schema: public; Owner: devmultilenden
--

CREATE SEQUENCE public.zoho_user_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zoho_user_data_id_seq OWNER TO devmultilenden;

--
-- TOC entry 10254 (class 0 OID 0)
-- Dependencies: 864
-- Name: zoho_user_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: devmultilenden
--

ALTER SEQUENCE public.zoho_user_data_id_seq OWNED BY public.lendenapp_zoho_user_data.id;


--
-- TOC entry 7455 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202501; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202501 FOR VALUES FROM ('2024-12-31 18:30:00+00') TO ('2025-01-31 18:30:00+00');


--
-- TOC entry 7456 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202502; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202502 FOR VALUES FROM ('2025-01-31 18:30:00+00') TO ('2025-02-28 18:30:00+00');


--
-- TOC entry 7457 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202503; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202503 FOR VALUES FROM ('2025-02-28 18:30:00+00') TO ('2025-03-31 18:30:00+00');


--
-- TOC entry 7458 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202504; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202504 FOR VALUES FROM ('2025-03-31 18:30:00+00') TO ('2025-04-30 18:30:00+00');


--
-- TOC entry 7459 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202505; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202505 FOR VALUES FROM ('2025-04-30 18:30:00+00') TO ('2025-05-31 18:30:00+00');


--
-- TOC entry 7460 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202506; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202506 FOR VALUES FROM ('2025-05-31 18:30:00+00') TO ('2025-06-30 18:30:00+00');


--
-- TOC entry 7461 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202507; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202507 FOR VALUES FROM ('2025-06-30 18:30:00+00') TO ('2025-07-31 18:30:00+00');


--
-- TOC entry 7462 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202508; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202508 FOR VALUES FROM ('2025-07-31 18:30:00+00') TO ('2025-08-31 18:30:00+00');


--
-- TOC entry 7463 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202509; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202509 FOR VALUES FROM ('2025-08-31 18:30:00+00') TO ('2025-09-30 18:30:00+00');


--
-- TOC entry 7464 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202510; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202510 FOR VALUES FROM ('2025-09-30 18:30:00+00') TO ('2025-10-31 18:30:00+00');


--
-- TOC entry 7465 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202511; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202511 FOR VALUES FROM ('2025-10-31 18:30:00+00') TO ('2025-11-30 18:30:00+00');


--
-- TOC entry 7466 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202512; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202512 FOR VALUES FROM ('2025-11-30 18:30:00+00') TO ('2025-12-31 18:30:00+00');


--
-- TOC entry 7467 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202601; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202601 FOR VALUES FROM ('2025-12-31 18:30:00+00') TO ('2026-01-31 18:30:00+00');


--
-- TOC entry 7468 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202602; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202602 FOR VALUES FROM ('2026-01-31 18:30:00+00') TO ('2026-02-28 18:30:00+00');


--
-- TOC entry 7469 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202603; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202603 FOR VALUES FROM ('2026-02-28 18:30:00+00') TO ('2026-03-31 18:30:00+00');


--
-- TOC entry 7470 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202604; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202604 FOR VALUES FROM ('2026-03-31 18:30:00+00') TO ('2026-04-30 18:30:00+00');


--
-- TOC entry 7471 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202605; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202605 FOR VALUES FROM ('2026-04-30 18:30:00+00') TO ('2026-05-31 18:30:00+00');


--
-- TOC entry 7472 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202606; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202606 FOR VALUES FROM ('2026-05-31 18:30:00+00') TO ('2026-06-30 18:30:00+00');


--
-- TOC entry 7473 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202607; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202607 FOR VALUES FROM ('2026-06-30 18:30:00+00') TO ('2026-07-31 18:30:00+00');


--
-- TOC entry 7474 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202608; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202608 FOR VALUES FROM ('2026-07-31 18:30:00+00') TO ('2026-08-31 18:30:00+00');


--
-- TOC entry 7475 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202609; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202609 FOR VALUES FROM ('2026-08-31 18:30:00+00') TO ('2026-09-30 18:30:00+00');


--
-- TOC entry 7476 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202610; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202610 FOR VALUES FROM ('2026-09-30 18:30:00+00') TO ('2026-10-31 18:30:00+00');


--
-- TOC entry 7477 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202611; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202611 FOR VALUES FROM ('2026-10-31 18:30:00+00') TO ('2026-11-30 18:30:00+00');


--
-- TOC entry 7478 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202612; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202612 FOR VALUES FROM ('2026-11-30 18:30:00+00') TO ('2026-12-31 18:30:00+00');


--
-- TOC entry 7479 (class 0 OID 0)
-- Name: lendenapp_user_gst_202503; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202503 FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');


--
-- TOC entry 7480 (class 0 OID 0)
-- Name: lendenapp_user_gst_202504; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202504 FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');


--
-- TOC entry 7481 (class 0 OID 0)
-- Name: lendenapp_user_gst_202505; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202505 FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');


--
-- TOC entry 7482 (class 0 OID 0)
-- Name: lendenapp_user_gst_202506; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202506 FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');


--
-- TOC entry 7483 (class 0 OID 0)
-- Name: lendenapp_user_gst_202507; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202507 FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');


--
-- TOC entry 7484 (class 0 OID 0)
-- Name: lendenapp_user_gst_202508; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202508 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 7485 (class 0 OID 0)
-- Name: lendenapp_user_gst_202509; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202509 FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');


--
-- TOC entry 7486 (class 0 OID 0)
-- Name: lendenapp_user_gst_202510; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202510 FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');


--
-- TOC entry 7487 (class 0 OID 0)
-- Name: lendenapp_user_gst_202511; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202511 FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');


--
-- TOC entry 7488 (class 0 OID 0)
-- Name: lendenapp_user_gst_202512; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202512 FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');


--
-- TOC entry 7489 (class 0 OID 0)
-- Name: lendenapp_user_gst_202601; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202601 FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');


--
-- TOC entry 7490 (class 0 OID 0)
-- Name: lendenapp_user_gst_202602; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202602 FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');


--
-- TOC entry 7491 (class 0 OID 0)
-- Name: lendenapp_user_gst_202603; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202603 FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');


--
-- TOC entry 7492 (class 0 OID 0)
-- Name: lendenapp_user_gst_202604; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202604 FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');


--
-- TOC entry 7493 (class 0 OID 0)
-- Name: lendenapp_user_gst_202605; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202605 FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');


--
-- TOC entry 7494 (class 0 OID 0)
-- Name: lendenapp_user_gst_202606; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202606 FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');


--
-- TOC entry 7495 (class 0 OID 0)
-- Name: lendenapp_user_gst_202607; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202607 FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');


--
-- TOC entry 7496 (class 0 OID 0)
-- Name: lendenapp_user_gst_202608; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202608 FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');


--
-- TOC entry 7497 (class 0 OID 0)
-- Name: lendenapp_user_gst_202609; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202609 FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');


--
-- TOC entry 7498 (class 0 OID 0)
-- Name: lendenapp_user_gst_202610; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202610 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');


--
-- TOC entry 7499 (class 0 OID 0)
-- Name: lendenapp_user_gst_202611; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202611 FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');


--
-- TOC entry 7500 (class 0 OID 0)
-- Name: lendenapp_user_gst_202612; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202612 FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


--
-- TOC entry 7501 (class 0 OID 0)
-- Name: lendenapp_user_gst_202701; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202701 FOR VALUES FROM ('2027-01-01') TO ('2027-02-01');


--
-- TOC entry 7502 (class 0 OID 0)
-- Name: lendenapp_user_gst_202702; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202702 FOR VALUES FROM ('2027-02-01') TO ('2027-03-01');


--
-- TOC entry 7503 (class 0 OID 0)
-- Name: lendenapp_user_gst_202703; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202703 FOR VALUES FROM ('2027-03-01') TO ('2027-04-01');


--
-- TOC entry 7504 (class 0 OID 0)
-- Name: lendenapp_user_gst_202704; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202704 FOR VALUES FROM ('2027-04-01') TO ('2027-05-01');


--
-- TOC entry 7505 (class 0 OID 0)
-- Name: lendenapp_user_gst_202705; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202705 FOR VALUES FROM ('2027-05-01') TO ('2027-06-01');


--
-- TOC entry 7506 (class 0 OID 0)
-- Name: lendenapp_user_gst_202706; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202706 FOR VALUES FROM ('2027-06-01') TO ('2027-07-01');


--
-- TOC entry 7507 (class 0 OID 0)
-- Name: lendenapp_user_gst_202707; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202707 FOR VALUES FROM ('2027-07-01') TO ('2027-08-01');


--
-- TOC entry 7508 (class 0 OID 0)
-- Name: lendenapp_user_gst_202708; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202708 FOR VALUES FROM ('2027-08-01') TO ('2027-09-01');


--
-- TOC entry 7509 (class 0 OID 0)
-- Name: lendenapp_user_gst_202709; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202709 FOR VALUES FROM ('2027-09-01') TO ('2027-10-01');


--
-- TOC entry 7510 (class 0 OID 0)
-- Name: lendenapp_user_gst_202710; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202710 FOR VALUES FROM ('2027-10-01') TO ('2027-11-01');


--
-- TOC entry 7511 (class 0 OID 0)
-- Name: lendenapp_user_gst_202711; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202711 FOR VALUES FROM ('2027-11-01') TO ('2027-12-01');


--
-- TOC entry 7512 (class 0 OID 0)
-- Name: lendenapp_user_gst_202712; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202712 FOR VALUES FROM ('2027-12-01') TO ('2028-01-01');


--
-- TOC entry 7513 (class 0 OID 0)
-- Name: lendenapp_user_gst_202801; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202801 FOR VALUES FROM ('2028-01-01') TO ('2028-02-01');


--
-- TOC entry 7514 (class 0 OID 0)
-- Name: lendenapp_user_gst_202802; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202802 FOR VALUES FROM ('2028-02-01') TO ('2028-03-01');


--
-- TOC entry 7515 (class 0 OID 0)
-- Name: lendenapp_user_gst_202803; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202803 FOR VALUES FROM ('2028-03-01') TO ('2028-04-01');


--
-- TOC entry 7516 (class 0 OID 0)
-- Name: lendenapp_user_gst_202804; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202804 FOR VALUES FROM ('2028-04-01') TO ('2028-05-01');


--
-- TOC entry 7517 (class 0 OID 0)
-- Name: lendenapp_user_gst_202805; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202805 FOR VALUES FROM ('2028-05-01') TO ('2028-06-01');


--
-- TOC entry 7518 (class 0 OID 0)
-- Name: lendenapp_user_gst_202806; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202806 FOR VALUES FROM ('2028-06-01') TO ('2028-07-01');


--
-- TOC entry 7519 (class 0 OID 0)
-- Name: lendenapp_user_gst_202807; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202807 FOR VALUES FROM ('2028-07-01') TO ('2028-08-01');


--
-- TOC entry 7520 (class 0 OID 0)
-- Name: lendenapp_user_gst_202808; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202808 FOR VALUES FROM ('2028-08-01') TO ('2028-09-01');


--
-- TOC entry 7521 (class 0 OID 0)
-- Name: lendenapp_user_gst_202809; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202809 FOR VALUES FROM ('2028-09-01') TO ('2028-10-01');


--
-- TOC entry 7522 (class 0 OID 0)
-- Name: lendenapp_user_gst_202810; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202810 FOR VALUES FROM ('2028-10-01') TO ('2028-11-01');


--
-- TOC entry 7523 (class 0 OID 0)
-- Name: lendenapp_user_gst_202811; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202811 FOR VALUES FROM ('2028-11-01') TO ('2028-12-01');


--
-- TOC entry 7524 (class 0 OID 0)
-- Name: lendenapp_user_gst_202812; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202812 FOR VALUES FROM ('2028-12-01') TO ('2029-01-01');


--
-- TOC entry 7525 (class 0 OID 0)
-- Name: lendenapp_user_gst_202901; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202901 FOR VALUES FROM ('2029-01-01') TO ('2029-02-01');


--
-- TOC entry 7526 (class 0 OID 0)
-- Name: lendenapp_user_gst_202902; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202902 FOR VALUES FROM ('2029-02-01') TO ('2029-03-01');


--
-- TOC entry 7527 (class 0 OID 0)
-- Name: lendenapp_user_gst_202903; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202903 FOR VALUES FROM ('2029-03-01') TO ('2029-04-01');


--
-- TOC entry 7528 (class 0 OID 0)
-- Name: lendenapp_user_gst_202904; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202904 FOR VALUES FROM ('2029-04-01') TO ('2029-05-01');


--
-- TOC entry 7529 (class 0 OID 0)
-- Name: lendenapp_user_gst_202905; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202905 FOR VALUES FROM ('2029-05-01') TO ('2029-06-01');


--
-- TOC entry 7530 (class 0 OID 0)
-- Name: lendenapp_user_gst_202906; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202906 FOR VALUES FROM ('2029-06-01') TO ('2029-07-01');


--
-- TOC entry 7531 (class 0 OID 0)
-- Name: lendenapp_user_gst_202907; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202907 FOR VALUES FROM ('2029-07-01') TO ('2029-08-01');


--
-- TOC entry 7532 (class 0 OID 0)
-- Name: lendenapp_user_gst_202908; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202908 FOR VALUES FROM ('2029-08-01') TO ('2029-09-01');


--
-- TOC entry 7533 (class 0 OID 0)
-- Name: lendenapp_user_gst_202909; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202909 FOR VALUES FROM ('2029-09-01') TO ('2029-10-01');


--
-- TOC entry 7534 (class 0 OID 0)
-- Name: lendenapp_user_gst_202910; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202910 FOR VALUES FROM ('2029-10-01') TO ('2029-11-01');


--
-- TOC entry 7535 (class 0 OID 0)
-- Name: lendenapp_user_gst_202911; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202911 FOR VALUES FROM ('2029-11-01') TO ('2029-12-01');


--
-- TOC entry 7536 (class 0 OID 0)
-- Name: lendenapp_user_gst_202912; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_202912 FOR VALUES FROM ('2029-12-01') TO ('2030-01-01');


--
-- TOC entry 7537 (class 0 OID 0)
-- Name: lendenapp_user_gst_203001; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203001 FOR VALUES FROM ('2030-01-01') TO ('2030-02-01');


--
-- TOC entry 7538 (class 0 OID 0)
-- Name: lendenapp_user_gst_203002; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203002 FOR VALUES FROM ('2030-02-01') TO ('2030-03-01');


--
-- TOC entry 7539 (class 0 OID 0)
-- Name: lendenapp_user_gst_203003; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203003 FOR VALUES FROM ('2030-03-01') TO ('2030-04-01');


--
-- TOC entry 7540 (class 0 OID 0)
-- Name: lendenapp_user_gst_203004; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203004 FOR VALUES FROM ('2030-04-01') TO ('2030-05-01');


--
-- TOC entry 7541 (class 0 OID 0)
-- Name: lendenapp_user_gst_203005; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203005 FOR VALUES FROM ('2030-05-01') TO ('2030-06-01');


--
-- TOC entry 7542 (class 0 OID 0)
-- Name: lendenapp_user_gst_203006; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203006 FOR VALUES FROM ('2030-06-01') TO ('2030-07-01');


--
-- TOC entry 7543 (class 0 OID 0)
-- Name: lendenapp_user_gst_203007; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203007 FOR VALUES FROM ('2030-07-01') TO ('2030-08-01');


--
-- TOC entry 7544 (class 0 OID 0)
-- Name: lendenapp_user_gst_203008; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203008 FOR VALUES FROM ('2030-08-01') TO ('2030-09-01');


--
-- TOC entry 7545 (class 0 OID 0)
-- Name: lendenapp_user_gst_203009; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203009 FOR VALUES FROM ('2030-09-01') TO ('2030-10-01');


--
-- TOC entry 7546 (class 0 OID 0)
-- Name: lendenapp_user_gst_203010; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203010 FOR VALUES FROM ('2030-10-01') TO ('2030-11-01');


--
-- TOC entry 7547 (class 0 OID 0)
-- Name: lendenapp_user_gst_203011; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203011 FOR VALUES FROM ('2030-11-01') TO ('2030-12-01');


--
-- TOC entry 7548 (class 0 OID 0)
-- Name: lendenapp_user_gst_203012; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203012 FOR VALUES FROM ('2030-12-01') TO ('2031-01-01');


--
-- TOC entry 7549 (class 0 OID 0)
-- Name: lendenapp_user_gst_203101; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203101 FOR VALUES FROM ('2031-01-01') TO ('2031-02-01');


--
-- TOC entry 7550 (class 0 OID 0)
-- Name: lendenapp_user_gst_203102; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203102 FOR VALUES FROM ('2031-02-01') TO ('2031-03-01');


--
-- TOC entry 7551 (class 0 OID 0)
-- Name: lendenapp_user_gst_203103; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203103 FOR VALUES FROM ('2031-03-01') TO ('2031-04-01');


--
-- TOC entry 7552 (class 0 OID 0)
-- Name: lendenapp_user_gst_203104; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203104 FOR VALUES FROM ('2031-04-01') TO ('2031-05-01');


--
-- TOC entry 7553 (class 0 OID 0)
-- Name: lendenapp_user_gst_203105; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203105 FOR VALUES FROM ('2031-05-01') TO ('2031-06-01');


--
-- TOC entry 7554 (class 0 OID 0)
-- Name: lendenapp_user_gst_203106; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203106 FOR VALUES FROM ('2031-06-01') TO ('2031-07-01');


--
-- TOC entry 7555 (class 0 OID 0)
-- Name: lendenapp_user_gst_203107; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203107 FOR VALUES FROM ('2031-07-01') TO ('2031-08-01');


--
-- TOC entry 7556 (class 0 OID 0)
-- Name: lendenapp_user_gst_203108; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203108 FOR VALUES FROM ('2031-08-01') TO ('2031-09-01');


--
-- TOC entry 7557 (class 0 OID 0)
-- Name: lendenapp_user_gst_203109; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203109 FOR VALUES FROM ('2031-09-01') TO ('2031-10-01');


--
-- TOC entry 7558 (class 0 OID 0)
-- Name: lendenapp_user_gst_203110; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203110 FOR VALUES FROM ('2031-10-01') TO ('2031-11-01');


--
-- TOC entry 7559 (class 0 OID 0)
-- Name: lendenapp_user_gst_203111; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203111 FOR VALUES FROM ('2031-11-01') TO ('2031-12-01');


--
-- TOC entry 7560 (class 0 OID 0)
-- Name: lendenapp_user_gst_203112; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203112 FOR VALUES FROM ('2031-12-01') TO ('2032-01-01');


--
-- TOC entry 7561 (class 0 OID 0)
-- Name: lendenapp_user_gst_203201; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203201 FOR VALUES FROM ('2032-01-01') TO ('2032-02-01');


--
-- TOC entry 7562 (class 0 OID 0)
-- Name: lendenapp_user_gst_203202; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203202 FOR VALUES FROM ('2032-02-01') TO ('2032-03-01');


--
-- TOC entry 7563 (class 0 OID 0)
-- Name: lendenapp_user_gst_203203; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203203 FOR VALUES FROM ('2032-03-01') TO ('2032-04-01');


--
-- TOC entry 7564 (class 0 OID 0)
-- Name: lendenapp_user_gst_203204; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203204 FOR VALUES FROM ('2032-04-01') TO ('2032-05-01');


--
-- TOC entry 7565 (class 0 OID 0)
-- Name: lendenapp_user_gst_203205; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203205 FOR VALUES FROM ('2032-05-01') TO ('2032-06-01');


--
-- TOC entry 7566 (class 0 OID 0)
-- Name: lendenapp_user_gst_203206; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203206 FOR VALUES FROM ('2032-06-01') TO ('2032-07-01');


--
-- TOC entry 7567 (class 0 OID 0)
-- Name: lendenapp_user_gst_203207; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203207 FOR VALUES FROM ('2032-07-01') TO ('2032-08-01');


--
-- TOC entry 7568 (class 0 OID 0)
-- Name: lendenapp_user_gst_203208; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203208 FOR VALUES FROM ('2032-08-01') TO ('2032-09-01');


--
-- TOC entry 7569 (class 0 OID 0)
-- Name: lendenapp_user_gst_203209; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203209 FOR VALUES FROM ('2032-09-01') TO ('2032-10-01');


--
-- TOC entry 7570 (class 0 OID 0)
-- Name: lendenapp_user_gst_203210; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203210 FOR VALUES FROM ('2032-10-01') TO ('2032-11-01');


--
-- TOC entry 7571 (class 0 OID 0)
-- Name: lendenapp_user_gst_203211; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203211 FOR VALUES FROM ('2032-11-01') TO ('2032-12-01');


--
-- TOC entry 7572 (class 0 OID 0)
-- Name: lendenapp_user_gst_203212; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203212 FOR VALUES FROM ('2032-12-01') TO ('2033-01-01');


--
-- TOC entry 7573 (class 0 OID 0)
-- Name: lendenapp_user_gst_203301; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203301 FOR VALUES FROM ('2033-01-01') TO ('2033-02-01');


--
-- TOC entry 7574 (class 0 OID 0)
-- Name: lendenapp_user_gst_203302; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203302 FOR VALUES FROM ('2033-02-01') TO ('2033-03-01');


--
-- TOC entry 7575 (class 0 OID 0)
-- Name: lendenapp_user_gst_203303; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203303 FOR VALUES FROM ('2033-03-01') TO ('2033-04-01');


--
-- TOC entry 7576 (class 0 OID 0)
-- Name: lendenapp_user_gst_203304; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203304 FOR VALUES FROM ('2033-04-01') TO ('2033-05-01');


--
-- TOC entry 7577 (class 0 OID 0)
-- Name: lendenapp_user_gst_203305; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203305 FOR VALUES FROM ('2033-05-01') TO ('2033-06-01');


--
-- TOC entry 7578 (class 0 OID 0)
-- Name: lendenapp_user_gst_203306; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203306 FOR VALUES FROM ('2033-06-01') TO ('2033-07-01');


--
-- TOC entry 7579 (class 0 OID 0)
-- Name: lendenapp_user_gst_203307; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203307 FOR VALUES FROM ('2033-07-01') TO ('2033-08-01');


--
-- TOC entry 7580 (class 0 OID 0)
-- Name: lendenapp_user_gst_203308; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203308 FOR VALUES FROM ('2033-08-01') TO ('2033-09-01');


--
-- TOC entry 7581 (class 0 OID 0)
-- Name: lendenapp_user_gst_203309; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203309 FOR VALUES FROM ('2033-09-01') TO ('2033-10-01');


--
-- TOC entry 7582 (class 0 OID 0)
-- Name: lendenapp_user_gst_203310; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203310 FOR VALUES FROM ('2033-10-01') TO ('2033-11-01');


--
-- TOC entry 7583 (class 0 OID 0)
-- Name: lendenapp_user_gst_203311; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203311 FOR VALUES FROM ('2033-11-01') TO ('2033-12-01');


--
-- TOC entry 7584 (class 0 OID 0)
-- Name: lendenapp_user_gst_203312; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203312 FOR VALUES FROM ('2033-12-01') TO ('2034-01-01');


--
-- TOC entry 7585 (class 0 OID 0)
-- Name: lendenapp_user_gst_203401; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203401 FOR VALUES FROM ('2034-01-01') TO ('2034-02-01');


--
-- TOC entry 7586 (class 0 OID 0)
-- Name: lendenapp_user_gst_203402; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203402 FOR VALUES FROM ('2034-02-01') TO ('2034-03-01');


--
-- TOC entry 7587 (class 0 OID 0)
-- Name: lendenapp_user_gst_203403; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203403 FOR VALUES FROM ('2034-03-01') TO ('2034-04-01');


--
-- TOC entry 7588 (class 0 OID 0)
-- Name: lendenapp_user_gst_203404; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203404 FOR VALUES FROM ('2034-04-01') TO ('2034-05-01');


--
-- TOC entry 7589 (class 0 OID 0)
-- Name: lendenapp_user_gst_203405; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203405 FOR VALUES FROM ('2034-05-01') TO ('2034-06-01');


--
-- TOC entry 7590 (class 0 OID 0)
-- Name: lendenapp_user_gst_203406; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203406 FOR VALUES FROM ('2034-06-01') TO ('2034-07-01');


--
-- TOC entry 7591 (class 0 OID 0)
-- Name: lendenapp_user_gst_203407; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203407 FOR VALUES FROM ('2034-07-01') TO ('2034-08-01');


--
-- TOC entry 7592 (class 0 OID 0)
-- Name: lendenapp_user_gst_203408; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203408 FOR VALUES FROM ('2034-08-01') TO ('2034-09-01');


--
-- TOC entry 7593 (class 0 OID 0)
-- Name: lendenapp_user_gst_203409; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203409 FOR VALUES FROM ('2034-09-01') TO ('2034-10-01');


--
-- TOC entry 7594 (class 0 OID 0)
-- Name: lendenapp_user_gst_203410; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203410 FOR VALUES FROM ('2034-10-01') TO ('2034-11-01');


--
-- TOC entry 7595 (class 0 OID 0)
-- Name: lendenapp_user_gst_203411; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203411 FOR VALUES FROM ('2034-11-01') TO ('2034-12-01');


--
-- TOC entry 7596 (class 0 OID 0)
-- Name: lendenapp_user_gst_203412; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203412 FOR VALUES FROM ('2034-12-01') TO ('2035-01-01');


--
-- TOC entry 7597 (class 0 OID 0)
-- Name: lendenapp_user_gst_203501; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203501 FOR VALUES FROM ('2035-01-01') TO ('2035-02-01');


--
-- TOC entry 7598 (class 0 OID 0)
-- Name: lendenapp_user_gst_203502; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203502 FOR VALUES FROM ('2035-02-01') TO ('2035-03-01');


--
-- TOC entry 7599 (class 0 OID 0)
-- Name: lendenapp_user_gst_203503; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203503 FOR VALUES FROM ('2035-03-01') TO ('2035-04-01');


--
-- TOC entry 7600 (class 0 OID 0)
-- Name: lendenapp_user_gst_203504; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203504 FOR VALUES FROM ('2035-04-01') TO ('2035-05-01');


--
-- TOC entry 7601 (class 0 OID 0)
-- Name: lendenapp_user_gst_203505; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203505 FOR VALUES FROM ('2035-05-01') TO ('2035-06-01');


--
-- TOC entry 7602 (class 0 OID 0)
-- Name: lendenapp_user_gst_203506; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203506 FOR VALUES FROM ('2035-06-01') TO ('2035-07-01');


--
-- TOC entry 7603 (class 0 OID 0)
-- Name: lendenapp_user_gst_203507; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203507 FOR VALUES FROM ('2035-07-01') TO ('2035-08-01');


--
-- TOC entry 7604 (class 0 OID 0)
-- Name: lendenapp_user_gst_203508; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203508 FOR VALUES FROM ('2035-08-01') TO ('2035-09-01');


--
-- TOC entry 7605 (class 0 OID 0)
-- Name: lendenapp_user_gst_203509; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203509 FOR VALUES FROM ('2035-09-01') TO ('2035-10-01');


--
-- TOC entry 7606 (class 0 OID 0)
-- Name: lendenapp_user_gst_203510; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203510 FOR VALUES FROM ('2035-10-01') TO ('2035-11-01');


--
-- TOC entry 7607 (class 0 OID 0)
-- Name: lendenapp_user_gst_203511; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203511 FOR VALUES FROM ('2035-11-01') TO ('2035-12-01');


--
-- TOC entry 7608 (class 0 OID 0)
-- Name: lendenapp_user_gst_203512; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203512 FOR VALUES FROM ('2035-12-01') TO ('2036-01-01');


--
-- TOC entry 7609 (class 0 OID 0)
-- Name: lendenapp_user_gst_203601; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203601 FOR VALUES FROM ('2036-01-01') TO ('2036-02-01');


--
-- TOC entry 7610 (class 0 OID 0)
-- Name: lendenapp_user_gst_203602; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203602 FOR VALUES FROM ('2036-02-01') TO ('2036-03-01');


--
-- TOC entry 7611 (class 0 OID 0)
-- Name: lendenapp_user_gst_203603; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203603 FOR VALUES FROM ('2036-03-01') TO ('2036-04-01');


--
-- TOC entry 7612 (class 0 OID 0)
-- Name: lendenapp_user_gst_203604; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203604 FOR VALUES FROM ('2036-04-01') TO ('2036-05-01');


--
-- TOC entry 7613 (class 0 OID 0)
-- Name: lendenapp_user_gst_203605; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203605 FOR VALUES FROM ('2036-05-01') TO ('2036-06-01');


--
-- TOC entry 7614 (class 0 OID 0)
-- Name: lendenapp_user_gst_203606; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203606 FOR VALUES FROM ('2036-06-01') TO ('2036-07-01');


--
-- TOC entry 7615 (class 0 OID 0)
-- Name: lendenapp_user_gst_203607; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203607 FOR VALUES FROM ('2036-07-01') TO ('2036-08-01');


--
-- TOC entry 7616 (class 0 OID 0)
-- Name: lendenapp_user_gst_203608; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203608 FOR VALUES FROM ('2036-08-01') TO ('2036-09-01');


--
-- TOC entry 7617 (class 0 OID 0)
-- Name: lendenapp_user_gst_203609; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203609 FOR VALUES FROM ('2036-09-01') TO ('2036-10-01');


--
-- TOC entry 7618 (class 0 OID 0)
-- Name: lendenapp_user_gst_203610; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203610 FOR VALUES FROM ('2036-10-01') TO ('2036-11-01');


--
-- TOC entry 7619 (class 0 OID 0)
-- Name: lendenapp_user_gst_203611; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203611 FOR VALUES FROM ('2036-11-01') TO ('2036-12-01');


--
-- TOC entry 7620 (class 0 OID 0)
-- Name: lendenapp_user_gst_203612; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203612 FOR VALUES FROM ('2036-12-01') TO ('2037-01-01');


--
-- TOC entry 7621 (class 0 OID 0)
-- Name: lendenapp_user_gst_203701; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203701 FOR VALUES FROM ('2037-01-01') TO ('2037-02-01');


--
-- TOC entry 7622 (class 0 OID 0)
-- Name: lendenapp_user_gst_203702; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203702 FOR VALUES FROM ('2037-02-01') TO ('2037-03-01');


--
-- TOC entry 7623 (class 0 OID 0)
-- Name: lendenapp_user_gst_203703; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203703 FOR VALUES FROM ('2037-03-01') TO ('2037-04-01');


--
-- TOC entry 7624 (class 0 OID 0)
-- Name: lendenapp_user_gst_203704; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203704 FOR VALUES FROM ('2037-04-01') TO ('2037-05-01');


--
-- TOC entry 7625 (class 0 OID 0)
-- Name: lendenapp_user_gst_203705; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203705 FOR VALUES FROM ('2037-05-01') TO ('2037-06-01');


--
-- TOC entry 7626 (class 0 OID 0)
-- Name: lendenapp_user_gst_203706; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203706 FOR VALUES FROM ('2037-06-01') TO ('2037-07-01');


--
-- TOC entry 7627 (class 0 OID 0)
-- Name: lendenapp_user_gst_203707; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203707 FOR VALUES FROM ('2037-07-01') TO ('2037-08-01');


--
-- TOC entry 7628 (class 0 OID 0)
-- Name: lendenapp_user_gst_203708; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203708 FOR VALUES FROM ('2037-08-01') TO ('2037-09-01');


--
-- TOC entry 7629 (class 0 OID 0)
-- Name: lendenapp_user_gst_203709; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203709 FOR VALUES FROM ('2037-09-01') TO ('2037-10-01');


--
-- TOC entry 7630 (class 0 OID 0)
-- Name: lendenapp_user_gst_203710; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203710 FOR VALUES FROM ('2037-10-01') TO ('2037-11-01');


--
-- TOC entry 7631 (class 0 OID 0)
-- Name: lendenapp_user_gst_203711; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203711 FOR VALUES FROM ('2037-11-01') TO ('2037-12-01');


--
-- TOC entry 7632 (class 0 OID 0)
-- Name: lendenapp_user_gst_203712; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203712 FOR VALUES FROM ('2037-12-01') TO ('2038-01-01');


--
-- TOC entry 7633 (class 0 OID 0)
-- Name: lendenapp_user_gst_203801; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203801 FOR VALUES FROM ('2038-01-01') TO ('2038-02-01');


--
-- TOC entry 7634 (class 0 OID 0)
-- Name: lendenapp_user_gst_203802; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203802 FOR VALUES FROM ('2038-02-01') TO ('2038-03-01');


--
-- TOC entry 7635 (class 0 OID 0)
-- Name: lendenapp_user_gst_203803; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203803 FOR VALUES FROM ('2038-03-01') TO ('2038-04-01');


--
-- TOC entry 7636 (class 0 OID 0)
-- Name: lendenapp_user_gst_203804; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203804 FOR VALUES FROM ('2038-04-01') TO ('2038-05-01');


--
-- TOC entry 7637 (class 0 OID 0)
-- Name: lendenapp_user_gst_203805; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203805 FOR VALUES FROM ('2038-05-01') TO ('2038-06-01');


--
-- TOC entry 7638 (class 0 OID 0)
-- Name: lendenapp_user_gst_203806; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203806 FOR VALUES FROM ('2038-06-01') TO ('2038-07-01');


--
-- TOC entry 7639 (class 0 OID 0)
-- Name: lendenapp_user_gst_203807; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203807 FOR VALUES FROM ('2038-07-01') TO ('2038-08-01');


--
-- TOC entry 7640 (class 0 OID 0)
-- Name: lendenapp_user_gst_203808; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203808 FOR VALUES FROM ('2038-08-01') TO ('2038-09-01');


--
-- TOC entry 7641 (class 0 OID 0)
-- Name: lendenapp_user_gst_203809; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203809 FOR VALUES FROM ('2038-09-01') TO ('2038-10-01');


--
-- TOC entry 7642 (class 0 OID 0)
-- Name: lendenapp_user_gst_203810; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203810 FOR VALUES FROM ('2038-10-01') TO ('2038-11-01');


--
-- TOC entry 7643 (class 0 OID 0)
-- Name: lendenapp_user_gst_203811; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203811 FOR VALUES FROM ('2038-11-01') TO ('2038-12-01');


--
-- TOC entry 7644 (class 0 OID 0)
-- Name: lendenapp_user_gst_203812; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203812 FOR VALUES FROM ('2038-12-01') TO ('2039-01-01');


--
-- TOC entry 7645 (class 0 OID 0)
-- Name: lendenapp_user_gst_203901; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203901 FOR VALUES FROM ('2039-01-01') TO ('2039-02-01');


--
-- TOC entry 7646 (class 0 OID 0)
-- Name: lendenapp_user_gst_203902; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203902 FOR VALUES FROM ('2039-02-01') TO ('2039-03-01');


--
-- TOC entry 7647 (class 0 OID 0)
-- Name: lendenapp_user_gst_203903; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203903 FOR VALUES FROM ('2039-03-01') TO ('2039-04-01');


--
-- TOC entry 7648 (class 0 OID 0)
-- Name: lendenapp_user_gst_203904; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203904 FOR VALUES FROM ('2039-04-01') TO ('2039-05-01');


--
-- TOC entry 7649 (class 0 OID 0)
-- Name: lendenapp_user_gst_203905; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203905 FOR VALUES FROM ('2039-05-01') TO ('2039-06-01');


--
-- TOC entry 7650 (class 0 OID 0)
-- Name: lendenapp_user_gst_203906; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203906 FOR VALUES FROM ('2039-06-01') TO ('2039-07-01');


--
-- TOC entry 7651 (class 0 OID 0)
-- Name: lendenapp_user_gst_203907; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203907 FOR VALUES FROM ('2039-07-01') TO ('2039-08-01');


--
-- TOC entry 7652 (class 0 OID 0)
-- Name: lendenapp_user_gst_203908; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203908 FOR VALUES FROM ('2039-08-01') TO ('2039-09-01');


--
-- TOC entry 7653 (class 0 OID 0)
-- Name: lendenapp_user_gst_203909; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203909 FOR VALUES FROM ('2039-09-01') TO ('2039-10-01');


--
-- TOC entry 7654 (class 0 OID 0)
-- Name: lendenapp_user_gst_203910; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203910 FOR VALUES FROM ('2039-10-01') TO ('2039-11-01');


--
-- TOC entry 7655 (class 0 OID 0)
-- Name: lendenapp_user_gst_203911; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203911 FOR VALUES FROM ('2039-11-01') TO ('2039-12-01');


--
-- TOC entry 7656 (class 0 OID 0)
-- Name: lendenapp_user_gst_203912; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_203912 FOR VALUES FROM ('2039-12-01') TO ('2040-01-01');


--
-- TOC entry 7657 (class 0 OID 0)
-- Name: lendenapp_user_gst_204001; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_204001 FOR VALUES FROM ('2040-01-01') TO ('2040-02-01');


--
-- TOC entry 7658 (class 0 OID 0)
-- Name: lendenapp_user_gst_204002; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_204002 FOR VALUES FROM ('2040-02-01') TO ('2040-03-01');


--
-- TOC entry 7659 (class 0 OID 0)
-- Name: lendenapp_user_gst_204003; Type: TABLE ATTACH; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ATTACH PARTITION public.lendenapp_user_gst_204003 FOR VALUES FROM ('2040-03-01') TO ('2040-04-01');


--
-- TOC entry 7660 (class 2604 OID 19851)
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- TOC entry 8083 (class 2604 OID 1949025)
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- TOC entry 8082 (class 2604 OID 1949007)
-- Name: auth_user id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_user ALTER COLUMN id SET DEFAULT nextval('public.auth_user_id_seq'::regclass);


--
-- TOC entry 7946 (class 2604 OID 19852)
-- Name: employee id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.employee ALTER COLUMN id SET DEFAULT nextval('public.employee_id_seq'::regclass);


--
-- TOC entry 7837 (class 2604 OID 19853)
-- Name: fcm_django_fcmdevice id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.fcm_django_fcmdevice ALTER COLUMN id SET DEFAULT nextval('public.fcm_django_fcmdevice_id_seq'::regclass);


--
-- TOC entry 7872 (class 2604 OID 19854)
-- Name: lendenap_user_states_final id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenap_user_states_final ALTER COLUMN id SET DEFAULT nextval('public.lendenap_user_states_final_id_seq'::regclass);


--
-- TOC entry 7711 (class 2604 OID 19855)
-- Name: lendenapp_account id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_account_id_seq'::regclass);


--
-- TOC entry 7722 (class 2604 OID 19856)
-- Name: lendenapp_address id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_address ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_address_id_seq'::regclass);


--
-- TOC entry 8018 (class 2604 OID 19857)
-- Name: lendenapp_address_v2 id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_address_v2 ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_address_v2_id_seq'::regclass);


--
-- TOC entry 7931 (class 2604 OID 19858)
-- Name: lendenapp_aml id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_aml ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_aml_id_seq'::regclass);


--
-- TOC entry 7935 (class 2604 OID 19859)
-- Name: lendenapp_amltracker id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_amltracker ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_amltracker_id_seq'::regclass);


--
-- TOC entry 7943 (class 2604 OID 19860)
-- Name: lendenapp_analytical_data id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_analytical_data ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_analytical_data_id_seq'::regclass);


--
-- TOC entry 7865 (class 2604 OID 19861)
-- Name: lendenapp_app_rating id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_app_rating ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_app_rating_id_seq'::regclass);


--
-- TOC entry 8055 (class 2604 OID 1752353)
-- Name: lendenapp_application_config id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_application_config ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_application_config_id_seq'::regclass);


--
-- TOC entry 7726 (class 2604 OID 19863)
-- Name: lendenapp_applicationinfo id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_applicationinfo ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_applicationinfo_id_seq'::regclass);


--
-- TOC entry 7665 (class 2604 OID 19864)
-- Name: lendenapp_bank id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bank ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_bank_id_seq'::regclass);


--
-- TOC entry 7688 (class 2604 OID 19865)
-- Name: lendenapp_bankaccount id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bankaccount ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_bankaccount_id_seq'::regclass);


--
-- TOC entry 7898 (class 2604 OID 19866)
-- Name: lendenapp_banklist id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_banklist ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_banklist_id_seq'::regclass);


--
-- TOC entry 8063 (class 2604 OID 1883381)
-- Name: lendenapp_campaign id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_campaign ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_campaign_id_seq'::regclass);


--
-- TOC entry 8070 (class 2604 OID 1883441)
-- Name: lendenapp_campaign_wallet id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_campaign_wallet ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_campaign_wallet_id_seq'::regclass);


--
-- TOC entry 7679 (class 2604 OID 19867)
-- Name: lendenapp_channelpartner id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_channelpartner ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_channelpartner_id_seq'::regclass);


--
-- TOC entry 7831 (class 2604 OID 19868)
-- Name: lendenapp_ckycthirdpartydata id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_ckycthirdpartydata ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_ckycthirdpartydata_id_seq'::regclass);


--
-- TOC entry 7953 (class 2604 OID 19869)
-- Name: lendenapp_cohort_config id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cohort_config ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_cohert_config_id_seq'::regclass);


--
-- TOC entry 7950 (class 2604 OID 19870)
-- Name: lendenapp_cohort_purpose id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cohort_purpose ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_cohert_purpose_id_seq'::regclass);


--
-- TOC entry 7830 (class 2604 OID 19871)
-- Name: lendenapp_communicationpreference id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_communicationpreference ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_communicationpreference_id_seq'::regclass);


--
-- TOC entry 7695 (class 2604 OID 19872)
-- Name: lendenapp_convertedreferral id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_convertedreferral ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_convertedreferral_id_seq'::regclass);


--
-- TOC entry 8052 (class 2604 OID 19873)
-- Name: lendenapp_counter id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_counter ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_counter_id_seq'::regclass);


--
-- TOC entry 8060 (class 2604 OID 1875188)
-- Name: lendenapp_cp_staff id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_cp_staff_id_seq'::regclass);


--
-- TOC entry 8084 (class 2604 OID 1949154)
-- Name: lendenapp_cp_staff_log id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff_log ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_cp_staff_log_id_seq'::regclass);


--
-- TOC entry 7672 (class 2604 OID 19874)
-- Name: lendenapp_customuser id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_customuser_id_seq'::regclass);


--
-- TOC entry 7694 (class 2604 OID 19875)
-- Name: lendenapp_customuser_groups id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser_groups ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_customuser_groups_id_seq'::regclass);


--
-- TOC entry 7704 (class 2604 OID 19876)
-- Name: lendenapp_document id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_document ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_document_id_seq'::regclass);


--
-- TOC entry 8015 (class 2604 OID 19877)
-- Name: lendenapp_filters_and_sort_logs id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_filters_and_sort_logs ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_filters_and_sort_logs_id_seq'::regclass);


--
-- TOC entry 7961 (class 2604 OID 19878)
-- Name: lendenapp_fmi_withdrawals id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_fmi_withdrawals ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_fmi_withdrawals_id_seq'::regclass);


--
-- TOC entry 7770 (class 2604 OID 19879)
-- Name: lendenapp_historicalaccount history_id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicalaccount ALTER COLUMN history_id SET DEFAULT nextval('public.lendenapp_historicalaccount_history_id_seq'::regclass);


--
-- TOC entry 7777 (class 2604 OID 19880)
-- Name: lendenapp_historicalbankaccount history_id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicalbankaccount ALTER COLUMN history_id SET DEFAULT nextval('public.lendenapp_historicalbankaccount_history_id_seq'::regclass);


--
-- TOC entry 7805 (class 2604 OID 19881)
-- Name: lendenapp_historicalcustomuser history_id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicalcustomuser ALTER COLUMN history_id SET DEFAULT nextval('public.lendenapp_historicalcustomuser_history_id_seq'::regclass);


--
-- TOC entry 7797 (class 2604 OID 19882)
-- Name: lendenapp_historicaltask history_id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicaltask ALTER COLUMN history_id SET DEFAULT nextval('public.lendenapp_historicaltask_history_id_seq'::regclass);


--
-- TOC entry 7914 (class 2604 OID 19883)
-- Name: lendenapp_historicaltracktxnamount history_id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_historicaltracktxnamount ALTER COLUMN history_id SET DEFAULT nextval('public.lendenapp_historicaltracktxnamount_history_id_seq'::regclass);


--
-- TOC entry 7801 (class 2604 OID 19884)
-- Name: lendenapp_historicaltransaction history_id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicaltransaction ALTER COLUMN history_id SET DEFAULT nextval('public.lendenapp_historicaltransaction_history_id_seq'::regclass);


--
-- TOC entry 7834 (class 2604 OID 19885)
-- Name: lendenapp_investorutminfo id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_investorutminfo ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_investorutminfo_id_seq'::regclass);


--
-- TOC entry 8077 (class 2604 OID 1883489)
-- Name: lendenapp_job_master id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_job_master ALTER COLUMN id SET DEFAULT nextval('public.job_status_id_seq'::regclass);


--
-- TOC entry 7855 (class 2604 OID 19886)
-- Name: lendenapp_mandate id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandate ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_mandate_id_seq'::regclass);


--
-- TOC entry 7852 (class 2604 OID 19887)
-- Name: lendenapp_mandatetracker id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandatetracker ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_mandatetracker_id_seq'::regclass);


--
-- TOC entry 7720 (class 2604 OID 19888)
-- Name: lendenapp_migration_error_log id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_migration_error_log ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_migration_error_log_id_seq'::regclass);


--
-- TOC entry 7862 (class 2604 OID 19889)
-- Name: lendenapp_nach_presentation id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_nach_presentation ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_scheme_reinvestment_id_seq'::regclass);


--
-- TOC entry 7782 (class 2604 OID 19890)
-- Name: lendenapp_notification id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_notification ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_notification_id_seq'::regclass);


--
-- TOC entry 7902 (class 2604 OID 19891)
-- Name: lendenapp_notifications id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_notifications ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_notifications_id_seq'::regclass);


--
-- TOC entry 7729 (class 2604 OID 19892)
-- Name: lendenapp_offline_payment_request id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_request ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_offline_payment_request_id_seq'::regclass);


--
-- TOC entry 7732 (class 2604 OID 19893)
-- Name: lendenapp_offline_payment_verification id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_verification ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_offline_payment_verification_id_seq'::regclass);


--
-- TOC entry 7882 (class 2604 OID 19894)
-- Name: lendenapp_otl_scheme_tracker id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_tracker ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_otl_scheme_tracker_id_seq'::regclass);


--
-- TOC entry 7735 (class 2604 OID 19895)
-- Name: lendenapp_partneruserconsentlog id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_partneruserconsentlog ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_partneruserconsentlog_id_seq'::regclass);


--
-- TOC entry 7739 (class 2604 OID 19896)
-- Name: lendenapp_paymentlink id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_paymentlink ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_paymentlink_id_seq'::regclass);


--
-- TOC entry 7669 (class 2604 OID 19897)
-- Name: lendenapp_pincode_state_master id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_pincode_state_master ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_pincode_state_master_id_seq'::regclass);


--
-- TOC entry 7815 (class 2604 OID 19898)
-- Name: lendenapp_reference id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_reference ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_reference_id_seq'::regclass);


--
-- TOC entry 8067 (class 2604 OID 1883414)
-- Name: lendenapp_reward id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_reward ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_reward_id_seq'::regclass);


--
-- TOC entry 7873 (class 2604 OID 19899)
-- Name: lendenapp_scheme_repayment_details id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_scheme_repayment_details_id_seq'::regclass);


--
-- TOC entry 7948 (class 2604 OID 19900)
-- Name: lendenapp_schemefilters_logs id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_schemefilters_logs ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_schemefilters_logs_id_seq'::regclass);


--
-- TOC entry 7848 (class 2604 OID 19901)
-- Name: lendenapp_schemeinfo id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_schemeinfo ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_schemeinfo_id_seq'::regclass);


--
-- TOC entry 7868 (class 2604 OID 19902)
-- Name: lendenapp_snorkel_stuck_transaction id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_snorkel_stuck_transaction ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_snorkel_stuck_transaction_id_seq'::regclass);


--
-- TOC entry 7661 (class 2604 OID 19903)
-- Name: lendenapp_source id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_source ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_source_id_seq'::regclass);


--
-- TOC entry 8017 (class 2604 OID 19904)
-- Name: lendenapp_state_codes_master id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_state_codes_master ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_state_codes_master_id_seq'::regclass);


--
-- TOC entry 7685 (class 2604 OID 19905)
-- Name: lendenapp_task id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_task ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_task_id_seq'::regclass);


--
-- TOC entry 7742 (class 2604 OID 19906)
-- Name: lendenapp_thirdparty_clevertap_events id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_clevertap_events ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdparty_clevertap_events_id_seq'::regclass);


--
-- TOC entry 7745 (class 2604 OID 19907)
-- Name: lendenapp_thirdparty_clevertap_logs id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_clevertap_logs ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdparty_clevertap_logs_id_seq'::regclass);


--
-- TOC entry 7864 (class 2604 OID 19908)
-- Name: lendenapp_thirdparty_crif_logs id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_thirdparty_crif_logs ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdparty_crif_logs_id_seq'::regclass);


--
-- TOC entry 7829 (class 2604 OID 19909)
-- Name: lendenapp_thirdparty_event_logs id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_event_logs ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdparty_event_logs_id_seq'::regclass);


--
-- TOC entry 7794 (class 2604 OID 19910)
-- Name: lendenapp_thirdparty_zoho_logs id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_zoho_logs ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdparty_zoho_logs_id_seq'::regclass);


--
-- TOC entry 7764 (class 2604 OID 19911)
-- Name: lendenapp_thirdpartycashfree id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartycashfree ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdpartycashfree_id_seq'::regclass);


--
-- TOC entry 7767 (class 2604 OID 19912)
-- Name: lendenapp_thirdpartydata id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartydata ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdpartydata_id_seq'::regclass);


--
-- TOC entry 7747 (class 2604 OID 19913)
-- Name: lendenapp_thirdpartydatahyperverge id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartydatahyperverge ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_thirdpartydatahyperverge_id_seq'::regclass);


--
-- TOC entry 7750 (class 2604 OID 19914)
-- Name: lendenapp_timeline id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_timeline ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_timeline_id_seq'::regclass);


--
-- TOC entry 7906 (class 2604 OID 19915)
-- Name: lendenapp_track_txn_amount id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_track_txn_amount ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_track_txn_amount_id_seq'::regclass);


--
-- TOC entry 7698 (class 2604 OID 19916)
-- Name: lendenapp_transaction id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transaction ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_transaction_id_seq'::regclass);


--
-- TOC entry 7925 (class 2604 OID 19917)
-- Name: lendenapp_transaction_amount_tracker id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_transaction_amount_tracker ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_transaction_amount_tracker_id_seq'::regclass);


--
-- TOC entry 7785 (class 2604 OID 19918)
-- Name: lendenapp_transactionaudit id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transactionaudit ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_transactionaudit_id_seq'::regclass);


--
-- TOC entry 7912 (class 2604 OID 19919)
-- Name: lendenapp_txn_activity_log id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_txn_activity_log ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_txn_activity_log_id_seq'::regclass);


--
-- TOC entry 7753 (class 2604 OID 19920)
-- Name: lendenapp_upimandatetransactionlog id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_upimandatetransactionlog ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_upimandatetransactionlog_id_seq'::regclass);


--
-- TOC entry 7958 (class 2604 OID 19921)
-- Name: lendenapp_user_cohort_mapping id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_cohort_mapping ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_user_cohert_mapping_id_seq'::regclass);


--
-- TOC entry 8022 (class 2604 OID 19922)
-- Name: lendenapp_user_gst id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_user_gst_id_seq'::regclass);


--
-- TOC entry 7921 (class 2604 OID 19923)
-- Name: lendenapp_user_metadata id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_metadata ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_passcode_id_seq'::regclass);


--
-- TOC entry 7787 (class 2604 OID 19924)
-- Name: lendenapp_user_report_log id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_report_log ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_user_report_log_id_seq'::regclass);


--
-- TOC entry 7682 (class 2604 OID 19925)
-- Name: lendenapp_user_source_group id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_source_group ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_user_source_group_id_seq'::regclass);


--
-- TOC entry 7757 (class 2604 OID 19926)
-- Name: lendenapp_userconsentlog id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userconsentlog ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_userconsentlog_id_seq'::regclass);


--
-- TOC entry 7707 (class 2604 OID 19927)
-- Name: lendenapp_userkyc id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyc ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_userkyc_id_seq'::regclass);


--
-- TOC entry 7818 (class 2604 OID 19928)
-- Name: lendenapp_userkyctracker id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyctracker ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_userkyctracker_id_seq'::regclass);


--
-- TOC entry 7790 (class 2604 OID 19929)
-- Name: lendenapp_userotp id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userotp ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_userotp_id_seq'::regclass);


--
-- TOC entry 7760 (class 2604 OID 19930)
-- Name: lendenapp_userupimandate id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userupimandate ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_userupimandate_id_seq'::regclass);


--
-- TOC entry 7811 (class 2604 OID 19931)
-- Name: lendenapp_utilitypreferences id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_utilitypreferences ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_utilitypreferences_id_seq'::regclass);


--
-- TOC entry 7792 (class 2604 OID 19932)
-- Name: lendenapp_withdrawalsummary id; Type: DEFAULT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_withdrawalsummary ALTER COLUMN id SET DEFAULT nextval('public.lendenapp_withdrawalsummary_id_seq'::regclass);


--
-- TOC entry 8048 (class 2604 OID 19933)
-- Name: lendenapp_zoho_user_data id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_zoho_user_data ALTER COLUMN id SET DEFAULT nextval('public.zoho_user_data_id_seq'::regclass);


--
-- TOC entry 7840 (class 2604 OID 19934)
-- Name: reverse_penny_drop id; Type: DEFAULT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.reverse_penny_drop ALTER COLUMN id SET DEFAULT nextval('public.reverse_penny_drop_id_seq'::regclass);


--
-- TOC entry 9333 (class 2606 OID 1971359)
-- Name: ath_group ath_group_name_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.ath_group
    ADD CONSTRAINT ath_group_name_key UNIQUE (name);


--
-- TOC entry 9335 (class 2606 OID 1971357)
-- Name: ath_group ath_group_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.ath_group
    ADD CONSTRAINT ath_group_pkey PRIMARY KEY (id);


--
-- TOC entry 8245 (class 2606 OID 19935)
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- TOC entry 8702 (class 2606 OID 1949029)
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- TOC entry 8704 (class 2606 OID 1949027)
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- TOC entry 8698 (class 2606 OID 1949011)
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- TOC entry 8700 (class 2606 OID 1949015)
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- TOC entry 8317 (class 2606 OID 19936)
-- Name: authtoken_token authtoken_token_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_pkey PRIMARY KEY (key);


--
-- TOC entry 8319 (class 2606 OID 19937)
-- Name: authtoken_token authtoken_token_user_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_key UNIQUE (user_id);


--
-- TOC entry 8453 (class 2606 OID 19938)
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- TOC entry 8455 (class 2606 OID 19939)
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- TOC entry 8451 (class 2606 OID 19940)
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 8499 (class 2606 OID 19941)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- TOC entry 8416 (class 2606 OID 19942)
-- Name: fcm_django_fcmdevice fcm_django_fcmdevice_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.fcm_django_fcmdevice
    ADD CONSTRAINT fcm_django_fcmdevice_pkey PRIMARY KEY (id);


--
-- TOC entry 8381 (class 2606 OID 19943)
-- Name: lendenapp_userotp fk_mobile_number; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userotp
    ADD CONSTRAINT fk_mobile_number UNIQUE (mobile_number);


--
-- TOC entry 8694 (class 2606 OID 1883495)
-- Name: lendenapp_job_master job_status_job_name_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_job_master
    ADD CONSTRAINT job_status_job_name_key UNIQUE (job_name);


--
-- TOC entry 8696 (class 2606 OID 1883493)
-- Name: lendenapp_job_master job_status_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_job_master
    ADD CONSTRAINT job_status_pkey PRIMARY KEY (id);


--
-- TOC entry 8308 (class 2606 OID 19944)
-- Name: lendenapp_account lendenapp_account_bank_account_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account
    ADD CONSTRAINT lendenapp_account_bank_account_id_key UNIQUE (bank_account_id);


--
-- TOC entry 8310 (class 2606 OID 19945)
-- Name: lendenapp_account lendenapp_account_number_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account
    ADD CONSTRAINT lendenapp_account_number_key UNIQUE (number);


--
-- TOC entry 8312 (class 2606 OID 19946)
-- Name: lendenapp_account lendenapp_account_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account
    ADD CONSTRAINT lendenapp_account_pkey PRIMARY KEY (id);


--
-- TOC entry 8321 (class 2606 OID 19947)
-- Name: lendenapp_address lendenapp_address_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_address
    ADD CONSTRAINT lendenapp_address_pkey PRIMARY KEY (id);


--
-- TOC entry 8571 (class 2606 OID 19948)
-- Name: lendenapp_address_v2 lendenapp_address_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_address_v2
    ADD CONSTRAINT lendenapp_address_v2_pkey PRIMARY KEY (id);


--
-- TOC entry 8493 (class 2606 OID 19949)
-- Name: lendenapp_aml lendenapp_aml_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_aml
    ADD CONSTRAINT lendenapp_aml_pkey PRIMARY KEY (id);


--
-- TOC entry 8495 (class 2606 OID 19950)
-- Name: lendenapp_amltracker lendenapp_amltracker_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_amltracker
    ADD CONSTRAINT lendenapp_amltracker_pkey PRIMARY KEY (id);


--
-- TOC entry 8497 (class 2606 OID 19951)
-- Name: lendenapp_analytical_data lendenapp_analytical_data_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_analytical_data
    ADD CONSTRAINT lendenapp_analytical_data_pkey PRIMARY KEY (id);


--
-- TOC entry 8682 (class 2606 OID 1752360)
-- Name: lendenapp_application_config lendenapp_application_config_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_application_config
    ADD CONSTRAINT lendenapp_application_config_pkey PRIMARY KEY (id);


--
-- TOC entry 8324 (class 2606 OID 19953)
-- Name: lendenapp_applicationinfo lendenapp_applicationinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_applicationinfo
    ADD CONSTRAINT lendenapp_applicationinfo_pkey PRIMARY KEY (id);


--
-- TOC entry 8253 (class 2606 OID 19954)
-- Name: lendenapp_bank lendenapp_bank_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bank
    ADD CONSTRAINT lendenapp_bank_pkey PRIMARY KEY (id);


--
-- TOC entry 8286 (class 2606 OID 19955)
-- Name: lendenapp_bankaccount lendenapp_bankaccount_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bankaccount
    ADD CONSTRAINT lendenapp_bankaccount_pkey PRIMARY KEY (id);


--
-- TOC entry 8477 (class 2606 OID 19956)
-- Name: lendenapp_banklist lendenapp_banklist_bank_name_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_banklist
    ADD CONSTRAINT lendenapp_banklist_bank_name_key UNIQUE (bank_name);


--
-- TOC entry 8479 (class 2606 OID 19957)
-- Name: lendenapp_banklist lendenapp_banklist_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_banklist
    ADD CONSTRAINT lendenapp_banklist_pkey PRIMARY KEY (id);


--
-- TOC entry 8688 (class 2606 OID 1883388)
-- Name: lendenapp_campaign lendenapp_campaign_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_campaign
    ADD CONSTRAINT lendenapp_campaign_pkey PRIMARY KEY (id);


--
-- TOC entry 8692 (class 2606 OID 1883449)
-- Name: lendenapp_campaign_wallet lendenapp_campaign_wallet_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_campaign_wallet
    ADD CONSTRAINT lendenapp_campaign_wallet_pkey PRIMARY KEY (id);


--
-- TOC entry 8268 (class 2606 OID 19958)
-- Name: lendenapp_channelpartner lendenapp_channelpartner_partner_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_channelpartner
    ADD CONSTRAINT lendenapp_channelpartner_partner_id_key UNIQUE (partner_id);


--
-- TOC entry 8270 (class 2606 OID 19959)
-- Name: lendenapp_channelpartner lendenapp_channelpartner_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_channelpartner
    ADD CONSTRAINT lendenapp_channelpartner_pkey PRIMARY KEY (id);


--
-- TOC entry 8412 (class 2606 OID 19960)
-- Name: lendenapp_ckycthirdpartydata lendenapp_ckycthirdpartydata_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_ckycthirdpartydata
    ADD CONSTRAINT lendenapp_ckycthirdpartydata_pkey PRIMARY KEY (id);


--
-- TOC entry 8505 (class 2606 OID 19961)
-- Name: lendenapp_cohort_config lendenapp_cohert_config_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cohort_config
    ADD CONSTRAINT lendenapp_cohert_config_pkey PRIMARY KEY (id);


--
-- TOC entry 8501 (class 2606 OID 19962)
-- Name: lendenapp_cohort_purpose lendenapp_cohert_purpose_name_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cohort_purpose
    ADD CONSTRAINT lendenapp_cohert_purpose_name_key UNIQUE (name);


--
-- TOC entry 8503 (class 2606 OID 19963)
-- Name: lendenapp_cohort_purpose lendenapp_cohert_purpose_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cohort_purpose
    ADD CONSTRAINT lendenapp_cohert_purpose_pkey PRIMARY KEY (id);


--
-- TOC entry 8410 (class 2606 OID 19964)
-- Name: lendenapp_communicationpreference lendenapp_communicationpreference_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_communicationpreference
    ADD CONSTRAINT lendenapp_communicationpreference_pkey PRIMARY KEY (id);


--
-- TOC entry 8296 (class 2606 OID 19965)
-- Name: lendenapp_convertedreferral lendenapp_convertedreferral_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_convertedreferral
    ADD CONSTRAINT lendenapp_convertedreferral_pkey PRIMARY KEY (id);


--
-- TOC entry 8678 (class 2606 OID 19966)
-- Name: lendenapp_counter lendenapp_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_counter
    ADD CONSTRAINT lendenapp_counter_pkey PRIMARY KEY (id);


--
-- TOC entry 8707 (class 2606 OID 1949157)
-- Name: lendenapp_cp_staff_log lendenapp_cp_staff_log_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff_log
    ADD CONSTRAINT lendenapp_cp_staff_log_pkey PRIMARY KEY (id);


--
-- TOC entry 8686 (class 2606 OID 1875191)
-- Name: lendenapp_cp_staff lendenapp_cp_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff
    ADD CONSTRAINT lendenapp_cp_staff_pkey PRIMARY KEY (id);


--
-- TOC entry 8261 (class 2606 OID 19967)
-- Name: lendenapp_customuser lendenapp_customuser_aadhar_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser
    ADD CONSTRAINT lendenapp_customuser_aadhar_key UNIQUE (aadhar);


--
-- TOC entry 8290 (class 2606 OID 19968)
-- Name: lendenapp_customuser_groups lendenapp_customuser_groups_customuser_id_group_id_unique; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser_groups
    ADD CONSTRAINT lendenapp_customuser_groups_customuser_id_group_id_unique UNIQUE (customuser_id, group_id);


--
-- TOC entry 8292 (class 2606 OID 19969)
-- Name: lendenapp_customuser_groups lendenapp_customuser_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser_groups
    ADD CONSTRAINT lendenapp_customuser_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 8263 (class 2606 OID 19971)
-- Name: lendenapp_customuser lendenapp_customuser_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser
    ADD CONSTRAINT lendenapp_customuser_pkey PRIMARY KEY (id);


--
-- TOC entry 8304 (class 2606 OID 19973)
-- Name: lendenapp_document lendenapp_document_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_document
    ADD CONSTRAINT lendenapp_document_pkey PRIMARY KEY (id);


--
-- TOC entry 8566 (class 2606 OID 19974)
-- Name: lendenapp_filters_and_sort_logs lendenapp_filters_and_sort_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_filters_and_sort_logs
    ADD CONSTRAINT lendenapp_filters_and_sort_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8512 (class 2606 OID 19975)
-- Name: lendenapp_fmi_withdrawals lendenapp_fmi_withdrawals_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_fmi_withdrawals
    ADD CONSTRAINT lendenapp_fmi_withdrawals_pkey PRIMARY KEY (id);


--
-- TOC entry 8514 (class 2606 OID 19976)
-- Name: lendenapp_fmi_withdrawals lendenapp_fmi_withdrawals_utr_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_fmi_withdrawals
    ADD CONSTRAINT lendenapp_fmi_withdrawals_utr_key UNIQUE (utr);


--
-- TOC entry 8371 (class 2606 OID 19977)
-- Name: lendenapp_historicalaccount lendenapp_historicalaccount_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicalaccount
    ADD CONSTRAINT lendenapp_historicalaccount_pkey PRIMARY KEY (history_id);


--
-- TOC entry 8373 (class 2606 OID 19978)
-- Name: lendenapp_historicalbankaccount lendenapp_historicalbankaccount_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicalbankaccount
    ADD CONSTRAINT lendenapp_historicalbankaccount_pkey PRIMARY KEY (history_id);


--
-- TOC entry 8395 (class 2606 OID 19979)
-- Name: lendenapp_historicalcustomuser lendenapp_historicalcustomuser_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicalcustomuser
    ADD CONSTRAINT lendenapp_historicalcustomuser_pkey PRIMARY KEY (history_id);


--
-- TOC entry 8391 (class 2606 OID 19980)
-- Name: lendenapp_historicaltask lendenapp_historicaltask_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicaltask
    ADD CONSTRAINT lendenapp_historicaltask_pkey PRIMARY KEY (history_id);


--
-- TOC entry 8487 (class 2606 OID 19981)
-- Name: lendenapp_historicaltracktxnamount lendenapp_historicaltracktxnamount_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_historicaltracktxnamount
    ADD CONSTRAINT lendenapp_historicaltracktxnamount_pkey PRIMARY KEY (history_id);


--
-- TOC entry 8393 (class 2606 OID 19982)
-- Name: lendenapp_historicaltransaction lendenapp_historicaltransaction_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_historicaltransaction
    ADD CONSTRAINT lendenapp_historicaltransaction_pkey PRIMARY KEY (history_id);


--
-- TOC entry 8414 (class 2606 OID 19983)
-- Name: lendenapp_investorutminfo lendenapp_investorutminfo_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_investorutminfo
    ADD CONSTRAINT lendenapp_investorutminfo_pkey PRIMARY KEY (id);


--
-- TOC entry 8438 (class 2606 OID 19984)
-- Name: lendenapp_mandate lendenapp_mandate_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandate
    ADD CONSTRAINT lendenapp_mandate_pkey PRIMARY KEY (id);


--
-- TOC entry 8431 (class 2606 OID 19985)
-- Name: lendenapp_mandatetracker lendenapp_mandatetracker_mandate_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandatetracker
    ADD CONSTRAINT lendenapp_mandatetracker_mandate_reference_id_key UNIQUE (mandate_reference_id);


--
-- TOC entry 8433 (class 2606 OID 19986)
-- Name: lendenapp_mandatetracker lendenapp_mandatetracker_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandatetracker
    ADD CONSTRAINT lendenapp_mandatetracker_pkey PRIMARY KEY (id);


--
-- TOC entry 8315 (class 2606 OID 19987)
-- Name: lendenapp_migration_error_log lendenapp_migration_error_log_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_migration_error_log
    ADD CONSTRAINT lendenapp_migration_error_log_pkey PRIMARY KEY (id);


--
-- TOC entry 8375 (class 2606 OID 19988)
-- Name: lendenapp_notification lendenapp_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_notification
    ADD CONSTRAINT lendenapp_notification_pkey PRIMARY KEY (id);


--
-- TOC entry 8481 (class 2606 OID 19989)
-- Name: lendenapp_notifications lendenapp_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_notifications
    ADD CONSTRAINT lendenapp_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 8327 (class 2606 OID 19990)
-- Name: lendenapp_offline_payment_request lendenapp_offline_payment_request_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_request
    ADD CONSTRAINT lendenapp_offline_payment_request_pkey PRIMARY KEY (id);


--
-- TOC entry 8329 (class 2606 OID 19991)
-- Name: lendenapp_offline_payment_request lendenapp_offline_payment_request_request_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_request
    ADD CONSTRAINT lendenapp_offline_payment_request_request_id_key UNIQUE (request_id);


--
-- TOC entry 8331 (class 2606 OID 19992)
-- Name: lendenapp_offline_payment_verification lendenapp_offline_payment_verification_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_verification
    ADD CONSTRAINT lendenapp_offline_payment_verification_pkey PRIMARY KEY (id);


--
-- TOC entry 8516 (class 2606 OID 19993)
-- Name: lendenapp_otl_scheme_loan_mapping lendenapp_otl_scheme_loan_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8518 (class 2606 OID 19994)
-- Name: lendenapp_otl_scheme_loan_mapping_202501 lendenapp_otl_scheme_loan_mapping_202501_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202501
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202501_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8520 (class 2606 OID 19995)
-- Name: lendenapp_otl_scheme_loan_mapping_202502 lendenapp_otl_scheme_loan_mapping_202502_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202502
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202502_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8522 (class 2606 OID 19996)
-- Name: lendenapp_otl_scheme_loan_mapping_202503 lendenapp_otl_scheme_loan_mapping_202503_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202503
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202503_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8524 (class 2606 OID 19997)
-- Name: lendenapp_otl_scheme_loan_mapping_202504 lendenapp_otl_scheme_loan_mapping_202504_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202504
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202504_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8526 (class 2606 OID 19998)
-- Name: lendenapp_otl_scheme_loan_mapping_202505 lendenapp_otl_scheme_loan_mapping_202505_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202505
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202505_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8528 (class 2606 OID 19999)
-- Name: lendenapp_otl_scheme_loan_mapping_202506 lendenapp_otl_scheme_loan_mapping_202506_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202506
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202506_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8530 (class 2606 OID 20000)
-- Name: lendenapp_otl_scheme_loan_mapping_202507 lendenapp_otl_scheme_loan_mapping_202507_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202507
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202507_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8532 (class 2606 OID 20001)
-- Name: lendenapp_otl_scheme_loan_mapping_202508 lendenapp_otl_scheme_loan_mapping_202508_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202508
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202508_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8534 (class 2606 OID 20002)
-- Name: lendenapp_otl_scheme_loan_mapping_202509 lendenapp_otl_scheme_loan_mapping_202509_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202509
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202509_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8536 (class 2606 OID 20003)
-- Name: lendenapp_otl_scheme_loan_mapping_202510 lendenapp_otl_scheme_loan_mapping_202510_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202510
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202510_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8538 (class 2606 OID 20004)
-- Name: lendenapp_otl_scheme_loan_mapping_202511 lendenapp_otl_scheme_loan_mapping_202511_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202511
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202511_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8540 (class 2606 OID 20005)
-- Name: lendenapp_otl_scheme_loan_mapping_202512 lendenapp_otl_scheme_loan_mapping_202512_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202512
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202512_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8542 (class 2606 OID 20006)
-- Name: lendenapp_otl_scheme_loan_mapping_202601 lendenapp_otl_scheme_loan_mapping_202601_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202601
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202601_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8544 (class 2606 OID 20007)
-- Name: lendenapp_otl_scheme_loan_mapping_202602 lendenapp_otl_scheme_loan_mapping_202602_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202602
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202602_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8546 (class 2606 OID 20008)
-- Name: lendenapp_otl_scheme_loan_mapping_202603 lendenapp_otl_scheme_loan_mapping_202603_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202603
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202603_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8548 (class 2606 OID 20009)
-- Name: lendenapp_otl_scheme_loan_mapping_202604 lendenapp_otl_scheme_loan_mapping_202604_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202604
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202604_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8550 (class 2606 OID 20010)
-- Name: lendenapp_otl_scheme_loan_mapping_202605 lendenapp_otl_scheme_loan_mapping_202605_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202605
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202605_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8552 (class 2606 OID 20011)
-- Name: lendenapp_otl_scheme_loan_mapping_202606 lendenapp_otl_scheme_loan_mapping_202606_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202606
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202606_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8554 (class 2606 OID 20012)
-- Name: lendenapp_otl_scheme_loan_mapping_202607 lendenapp_otl_scheme_loan_mapping_202607_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202607
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202607_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8556 (class 2606 OID 20013)
-- Name: lendenapp_otl_scheme_loan_mapping_202608 lendenapp_otl_scheme_loan_mapping_202608_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202608
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202608_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8558 (class 2606 OID 20014)
-- Name: lendenapp_otl_scheme_loan_mapping_202609 lendenapp_otl_scheme_loan_mapping_202609_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202609
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202609_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8560 (class 2606 OID 20015)
-- Name: lendenapp_otl_scheme_loan_mapping_202610 lendenapp_otl_scheme_loan_mapping_202610_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202610
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202610_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8562 (class 2606 OID 20016)
-- Name: lendenapp_otl_scheme_loan_mapping_202611 lendenapp_otl_scheme_loan_mapping_202611_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202611
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202611_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8564 (class 2606 OID 20017)
-- Name: lendenapp_otl_scheme_loan_mapping_202612 lendenapp_otl_scheme_loan_mapping_202612_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_202612
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_202612_pkey PRIMARY KEY (id, created_date);


--
-- TOC entry 8472 (class 2606 OID 20018)
-- Name: lendenapp_otl_scheme_tracker lendenapp_otl_scheme_tracker_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_tracker
    ADD CONSTRAINT lendenapp_otl_scheme_tracker_pkey PRIMARY KEY (id);


--
-- TOC entry 8333 (class 2606 OID 20019)
-- Name: lendenapp_partneruserconsentlog lendenapp_partneruserconsentlog_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_partneruserconsentlog
    ADD CONSTRAINT lendenapp_partneruserconsentlog_pkey PRIMARY KEY (id);


--
-- TOC entry 8335 (class 2606 OID 20020)
-- Name: lendenapp_partneruserconsentlog lendenapp_partneruserconsentlog_unique_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_partneruserconsentlog
    ADD CONSTRAINT lendenapp_partneruserconsentlog_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 8489 (class 2606 OID 20021)
-- Name: lendenapp_user_metadata lendenapp_passcode_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_metadata
    ADD CONSTRAINT lendenapp_passcode_pkey PRIMARY KEY (id);


--
-- TOC entry 8339 (class 2606 OID 20022)
-- Name: lendenapp_paymentlink lendenapp_paymentlink_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_paymentlink
    ADD CONSTRAINT lendenapp_paymentlink_pkey PRIMARY KEY (id);


--
-- TOC entry 8257 (class 2606 OID 20023)
-- Name: lendenapp_pincode_state_master lendenapp_pincode_state_master_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_pincode_state_master
    ADD CONSTRAINT lendenapp_pincode_state_master_pkey PRIMARY KEY (id);


--
-- TOC entry 8399 (class 2606 OID 20024)
-- Name: lendenapp_reference lendenapp_reference_gst_number_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_reference
    ADD CONSTRAINT lendenapp_reference_gst_number_key UNIQUE (gst_number);


--
-- TOC entry 8401 (class 2606 OID 20025)
-- Name: lendenapp_reference lendenapp_reference_pan_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_reference
    ADD CONSTRAINT lendenapp_reference_pan_key UNIQUE (pan);


--
-- TOC entry 8403 (class 2606 OID 20026)
-- Name: lendenapp_reference lendenapp_reference_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_reference
    ADD CONSTRAINT lendenapp_reference_pkey PRIMARY KEY (id);


--
-- TOC entry 8690 (class 2606 OID 1883420)
-- Name: lendenapp_reward lendenapp_reward_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_reward
    ADD CONSTRAINT lendenapp_reward_pkey PRIMARY KEY (id);


--
-- TOC entry 8442 (class 2606 OID 20028)
-- Name: lendenapp_nach_presentation lendenapp_scheme_reinvestment_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_nach_presentation
    ADD CONSTRAINT lendenapp_scheme_reinvestment_pkey PRIMARY KEY (id);


--
-- TOC entry 8444 (class 2606 OID 20029)
-- Name: lendenapp_nach_presentation lendenapp_scheme_reinvestment_unique_record; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_nach_presentation
    ADD CONSTRAINT lendenapp_scheme_reinvestment_unique_record UNIQUE (unique_record_id);


--
-- TOC entry 8463 (class 2606 OID 20030)
-- Name: lendenapp_scheme_repayment_details lendenapp_scheme_repayment_details_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details
    ADD CONSTRAINT lendenapp_scheme_repayment_details_pkey PRIMARY KEY (id);


--
-- TOC entry 8428 (class 2606 OID 20031)
-- Name: lendenapp_schemeinfo lendenapp_schemeinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_schemeinfo
    ADD CONSTRAINT lendenapp_schemeinfo_pkey PRIMARY KEY (id);


--
-- TOC entry 8449 (class 2606 OID 20032)
-- Name: lendenapp_snorkel_stuck_transaction lendenapp_snorkel_stuck_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_snorkel_stuck_transaction
    ADD CONSTRAINT lendenapp_snorkel_stuck_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 8249 (class 2606 OID 20033)
-- Name: lendenapp_source lendenapp_source_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_source
    ADD CONSTRAINT lendenapp_source_pkey PRIMARY KEY (id);


--
-- TOC entry 8568 (class 2606 OID 20034)
-- Name: lendenapp_state_codes_master lendenapp_state_codes_master_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_state_codes_master
    ADD CONSTRAINT lendenapp_state_codes_master_pkey PRIMARY KEY (id);


--
-- TOC entry 8281 (class 2606 OID 20035)
-- Name: lendenapp_task lendenapp_task_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_task
    ADD CONSTRAINT lendenapp_task_pkey PRIMARY KEY (id);


--
-- TOC entry 8345 (class 2606 OID 20036)
-- Name: lendenapp_thirdparty_clevertap_events lendenapp_thirdparty_clevertap_events_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_clevertap_events
    ADD CONSTRAINT lendenapp_thirdparty_clevertap_events_pkey PRIMARY KEY (id);


--
-- TOC entry 8347 (class 2606 OID 20037)
-- Name: lendenapp_thirdparty_clevertap_logs lendenapp_thirdparty_clevertap_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_clevertap_logs
    ADD CONSTRAINT lendenapp_thirdparty_clevertap_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8408 (class 2606 OID 20038)
-- Name: lendenapp_thirdparty_event_logs lendenapp_thirdparty_event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_event_logs
    ADD CONSTRAINT lendenapp_thirdparty_event_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8389 (class 2606 OID 20039)
-- Name: lendenapp_thirdparty_zoho_logs lendenapp_thirdparty_zoho_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_zoho_logs
    ADD CONSTRAINT lendenapp_thirdparty_zoho_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8367 (class 2606 OID 20040)
-- Name: lendenapp_thirdpartycashfree lendenapp_thirdpartycashfree_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartycashfree
    ADD CONSTRAINT lendenapp_thirdpartycashfree_pkey PRIMARY KEY (id);


--
-- TOC entry 8369 (class 2606 OID 20041)
-- Name: lendenapp_thirdpartydata lendenapp_thirdpartydata_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartydata
    ADD CONSTRAINT lendenapp_thirdpartydata_pkey PRIMARY KEY (id);


--
-- TOC entry 8349 (class 2606 OID 20042)
-- Name: lendenapp_thirdpartydatahyperverge lendenapp_thirdpartydatahyperverge_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartydatahyperverge
    ADD CONSTRAINT lendenapp_thirdpartydatahyperverge_pkey PRIMARY KEY (id);


--
-- TOC entry 8351 (class 2606 OID 20043)
-- Name: lendenapp_timeline lendenapp_timeline_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_timeline
    ADD CONSTRAINT lendenapp_timeline_pkey PRIMARY KEY (id);


--
-- TOC entry 8483 (class 2606 OID 20044)
-- Name: lendenapp_track_txn_amount lendenapp_track_txn_amount_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_track_txn_amount
    ADD CONSTRAINT lendenapp_track_txn_amount_pkey PRIMARY KEY (id);


--
-- TOC entry 8491 (class 2606 OID 20045)
-- Name: lendenapp_transaction_amount_tracker lendenapp_transaction_amount_tracker_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_transaction_amount_tracker
    ADD CONSTRAINT lendenapp_transaction_amount_tracker_pkey PRIMARY KEY (id);


--
-- TOC entry 8300 (class 2606 OID 20046)
-- Name: lendenapp_transaction lendenapp_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transaction
    ADD CONSTRAINT lendenapp_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 8302 (class 2606 OID 20047)
-- Name: lendenapp_transaction lendenapp_transaction_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transaction
    ADD CONSTRAINT lendenapp_transaction_transaction_id_key UNIQUE (transaction_id);


--
-- TOC entry 8377 (class 2606 OID 20048)
-- Name: lendenapp_transactionaudit lendenapp_transactionaudit_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transactionaudit
    ADD CONSTRAINT lendenapp_transactionaudit_pkey PRIMARY KEY (id);


--
-- TOC entry 8485 (class 2606 OID 20049)
-- Name: lendenapp_txn_activity_log lendenapp_txn_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_txn_activity_log
    ADD CONSTRAINT lendenapp_txn_activity_log_pkey PRIMARY KEY (id);


--
-- TOC entry 8353 (class 2606 OID 20050)
-- Name: lendenapp_upimandatetransactionlog lendenapp_upimandatetransactionlog_execute_request_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_upimandatetransactionlog
    ADD CONSTRAINT lendenapp_upimandatetransactionlog_execute_request_id_key UNIQUE (execute_request_id);


--
-- TOC entry 8355 (class 2606 OID 20051)
-- Name: lendenapp_upimandatetransactionlog lendenapp_upimandatetransactionlog_mandate_id_59a77a53_uniq; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_upimandatetransactionlog
    ADD CONSTRAINT lendenapp_upimandatetransactionlog_mandate_id_59a77a53_uniq UNIQUE (mandate_id, transaction_date);


--
-- TOC entry 8357 (class 2606 OID 20052)
-- Name: lendenapp_upimandatetransactionlog lendenapp_upimandatetransactionlog_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_upimandatetransactionlog
    ADD CONSTRAINT lendenapp_upimandatetransactionlog_pkey PRIMARY KEY (id);


--
-- TOC entry 8507 (class 2606 OID 20053)
-- Name: lendenapp_user_cohort_mapping lendenapp_user_cohert_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_cohort_mapping
    ADD CONSTRAINT lendenapp_user_cohert_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 8576 (class 2606 OID 20054)
-- Name: lendenapp_user_gst lendenapp_user_gst_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst
    ADD CONSTRAINT lendenapp_user_gst_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8578 (class 2606 OID 20055)
-- Name: lendenapp_user_gst_202503 lendenapp_user_gst_202503_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202503
    ADD CONSTRAINT lendenapp_user_gst_202503_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8582 (class 2606 OID 20056)
-- Name: lendenapp_user_gst_202504 lendenapp_user_gst_202504_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202504
    ADD CONSTRAINT lendenapp_user_gst_202504_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8586 (class 2606 OID 20057)
-- Name: lendenapp_user_gst_202505 lendenapp_user_gst_202505_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202505
    ADD CONSTRAINT lendenapp_user_gst_202505_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8590 (class 2606 OID 20058)
-- Name: lendenapp_user_gst_202506 lendenapp_user_gst_202506_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202506
    ADD CONSTRAINT lendenapp_user_gst_202506_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8594 (class 2606 OID 20059)
-- Name: lendenapp_user_gst_202507 lendenapp_user_gst_202507_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202507
    ADD CONSTRAINT lendenapp_user_gst_202507_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8598 (class 2606 OID 20060)
-- Name: lendenapp_user_gst_202508 lendenapp_user_gst_202508_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202508
    ADD CONSTRAINT lendenapp_user_gst_202508_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8602 (class 2606 OID 20061)
-- Name: lendenapp_user_gst_202509 lendenapp_user_gst_202509_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202509
    ADD CONSTRAINT lendenapp_user_gst_202509_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8606 (class 2606 OID 20062)
-- Name: lendenapp_user_gst_202510 lendenapp_user_gst_202510_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202510
    ADD CONSTRAINT lendenapp_user_gst_202510_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8610 (class 2606 OID 20063)
-- Name: lendenapp_user_gst_202511 lendenapp_user_gst_202511_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202511
    ADD CONSTRAINT lendenapp_user_gst_202511_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8614 (class 2606 OID 20064)
-- Name: lendenapp_user_gst_202512 lendenapp_user_gst_202512_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202512
    ADD CONSTRAINT lendenapp_user_gst_202512_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8618 (class 2606 OID 20065)
-- Name: lendenapp_user_gst_202601 lendenapp_user_gst_202601_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202601
    ADD CONSTRAINT lendenapp_user_gst_202601_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8622 (class 2606 OID 20066)
-- Name: lendenapp_user_gst_202602 lendenapp_user_gst_202602_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202602
    ADD CONSTRAINT lendenapp_user_gst_202602_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8626 (class 2606 OID 20067)
-- Name: lendenapp_user_gst_202603 lendenapp_user_gst_202603_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202603
    ADD CONSTRAINT lendenapp_user_gst_202603_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8630 (class 2606 OID 20068)
-- Name: lendenapp_user_gst_202604 lendenapp_user_gst_202604_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202604
    ADD CONSTRAINT lendenapp_user_gst_202604_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8634 (class 2606 OID 20069)
-- Name: lendenapp_user_gst_202605 lendenapp_user_gst_202605_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202605
    ADD CONSTRAINT lendenapp_user_gst_202605_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8638 (class 2606 OID 20070)
-- Name: lendenapp_user_gst_202606 lendenapp_user_gst_202606_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202606
    ADD CONSTRAINT lendenapp_user_gst_202606_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8642 (class 2606 OID 20071)
-- Name: lendenapp_user_gst_202607 lendenapp_user_gst_202607_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202607
    ADD CONSTRAINT lendenapp_user_gst_202607_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8646 (class 2606 OID 20072)
-- Name: lendenapp_user_gst_202608 lendenapp_user_gst_202608_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202608
    ADD CONSTRAINT lendenapp_user_gst_202608_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8650 (class 2606 OID 20073)
-- Name: lendenapp_user_gst_202609 lendenapp_user_gst_202609_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202609
    ADD CONSTRAINT lendenapp_user_gst_202609_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8654 (class 2606 OID 20074)
-- Name: lendenapp_user_gst_202610 lendenapp_user_gst_202610_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202610
    ADD CONSTRAINT lendenapp_user_gst_202610_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8658 (class 2606 OID 20075)
-- Name: lendenapp_user_gst_202611 lendenapp_user_gst_202611_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202611
    ADD CONSTRAINT lendenapp_user_gst_202611_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8662 (class 2606 OID 20076)
-- Name: lendenapp_user_gst_202612 lendenapp_user_gst_202612_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202612
    ADD CONSTRAINT lendenapp_user_gst_202612_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8666 (class 2606 OID 20077)
-- Name: lendenapp_user_gst_202701 lendenapp_user_gst_202701_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202701
    ADD CONSTRAINT lendenapp_user_gst_202701_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8670 (class 2606 OID 20078)
-- Name: lendenapp_user_gst_202702 lendenapp_user_gst_202702_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202702
    ADD CONSTRAINT lendenapp_user_gst_202702_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8674 (class 2606 OID 20079)
-- Name: lendenapp_user_gst_202703 lendenapp_user_gst_202703_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202703
    ADD CONSTRAINT lendenapp_user_gst_202703_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8709 (class 2606 OID 1950252)
-- Name: lendenapp_user_gst_202704 lendenapp_user_gst_202704_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202704
    ADD CONSTRAINT lendenapp_user_gst_202704_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8713 (class 2606 OID 1950258)
-- Name: lendenapp_user_gst_202705 lendenapp_user_gst_202705_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202705
    ADD CONSTRAINT lendenapp_user_gst_202705_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8717 (class 2606 OID 1950264)
-- Name: lendenapp_user_gst_202706 lendenapp_user_gst_202706_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202706
    ADD CONSTRAINT lendenapp_user_gst_202706_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8721 (class 2606 OID 1950270)
-- Name: lendenapp_user_gst_202707 lendenapp_user_gst_202707_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202707
    ADD CONSTRAINT lendenapp_user_gst_202707_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8725 (class 2606 OID 1950276)
-- Name: lendenapp_user_gst_202708 lendenapp_user_gst_202708_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202708
    ADD CONSTRAINT lendenapp_user_gst_202708_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8729 (class 2606 OID 1950282)
-- Name: lendenapp_user_gst_202709 lendenapp_user_gst_202709_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202709
    ADD CONSTRAINT lendenapp_user_gst_202709_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8733 (class 2606 OID 1950288)
-- Name: lendenapp_user_gst_202710 lendenapp_user_gst_202710_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202710
    ADD CONSTRAINT lendenapp_user_gst_202710_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8737 (class 2606 OID 1950294)
-- Name: lendenapp_user_gst_202711 lendenapp_user_gst_202711_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202711
    ADD CONSTRAINT lendenapp_user_gst_202711_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8741 (class 2606 OID 1950300)
-- Name: lendenapp_user_gst_202712 lendenapp_user_gst_202712_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202712
    ADD CONSTRAINT lendenapp_user_gst_202712_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8745 (class 2606 OID 1950306)
-- Name: lendenapp_user_gst_202801 lendenapp_user_gst_202801_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202801
    ADD CONSTRAINT lendenapp_user_gst_202801_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8749 (class 2606 OID 1950312)
-- Name: lendenapp_user_gst_202802 lendenapp_user_gst_202802_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202802
    ADD CONSTRAINT lendenapp_user_gst_202802_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8753 (class 2606 OID 1950318)
-- Name: lendenapp_user_gst_202803 lendenapp_user_gst_202803_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202803
    ADD CONSTRAINT lendenapp_user_gst_202803_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8757 (class 2606 OID 1950324)
-- Name: lendenapp_user_gst_202804 lendenapp_user_gst_202804_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202804
    ADD CONSTRAINT lendenapp_user_gst_202804_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8761 (class 2606 OID 1950330)
-- Name: lendenapp_user_gst_202805 lendenapp_user_gst_202805_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202805
    ADD CONSTRAINT lendenapp_user_gst_202805_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8765 (class 2606 OID 1950336)
-- Name: lendenapp_user_gst_202806 lendenapp_user_gst_202806_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202806
    ADD CONSTRAINT lendenapp_user_gst_202806_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8769 (class 2606 OID 1950342)
-- Name: lendenapp_user_gst_202807 lendenapp_user_gst_202807_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202807
    ADD CONSTRAINT lendenapp_user_gst_202807_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8773 (class 2606 OID 1950348)
-- Name: lendenapp_user_gst_202808 lendenapp_user_gst_202808_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202808
    ADD CONSTRAINT lendenapp_user_gst_202808_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8777 (class 2606 OID 1950354)
-- Name: lendenapp_user_gst_202809 lendenapp_user_gst_202809_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202809
    ADD CONSTRAINT lendenapp_user_gst_202809_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8781 (class 2606 OID 1950360)
-- Name: lendenapp_user_gst_202810 lendenapp_user_gst_202810_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202810
    ADD CONSTRAINT lendenapp_user_gst_202810_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8785 (class 2606 OID 1950366)
-- Name: lendenapp_user_gst_202811 lendenapp_user_gst_202811_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202811
    ADD CONSTRAINT lendenapp_user_gst_202811_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8789 (class 2606 OID 1950372)
-- Name: lendenapp_user_gst_202812 lendenapp_user_gst_202812_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202812
    ADD CONSTRAINT lendenapp_user_gst_202812_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8793 (class 2606 OID 1950378)
-- Name: lendenapp_user_gst_202901 lendenapp_user_gst_202901_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202901
    ADD CONSTRAINT lendenapp_user_gst_202901_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8797 (class 2606 OID 1950384)
-- Name: lendenapp_user_gst_202902 lendenapp_user_gst_202902_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202902
    ADD CONSTRAINT lendenapp_user_gst_202902_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8801 (class 2606 OID 1950390)
-- Name: lendenapp_user_gst_202903 lendenapp_user_gst_202903_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202903
    ADD CONSTRAINT lendenapp_user_gst_202903_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8805 (class 2606 OID 1950396)
-- Name: lendenapp_user_gst_202904 lendenapp_user_gst_202904_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202904
    ADD CONSTRAINT lendenapp_user_gst_202904_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8809 (class 2606 OID 1950402)
-- Name: lendenapp_user_gst_202905 lendenapp_user_gst_202905_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202905
    ADD CONSTRAINT lendenapp_user_gst_202905_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8813 (class 2606 OID 1950408)
-- Name: lendenapp_user_gst_202906 lendenapp_user_gst_202906_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202906
    ADD CONSTRAINT lendenapp_user_gst_202906_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8817 (class 2606 OID 1950414)
-- Name: lendenapp_user_gst_202907 lendenapp_user_gst_202907_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202907
    ADD CONSTRAINT lendenapp_user_gst_202907_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8821 (class 2606 OID 1950420)
-- Name: lendenapp_user_gst_202908 lendenapp_user_gst_202908_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202908
    ADD CONSTRAINT lendenapp_user_gst_202908_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8825 (class 2606 OID 1950426)
-- Name: lendenapp_user_gst_202909 lendenapp_user_gst_202909_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202909
    ADD CONSTRAINT lendenapp_user_gst_202909_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8829 (class 2606 OID 1950432)
-- Name: lendenapp_user_gst_202910 lendenapp_user_gst_202910_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202910
    ADD CONSTRAINT lendenapp_user_gst_202910_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8833 (class 2606 OID 1950438)
-- Name: lendenapp_user_gst_202911 lendenapp_user_gst_202911_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202911
    ADD CONSTRAINT lendenapp_user_gst_202911_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8837 (class 2606 OID 1950444)
-- Name: lendenapp_user_gst_202912 lendenapp_user_gst_202912_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_202912
    ADD CONSTRAINT lendenapp_user_gst_202912_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8841 (class 2606 OID 1950450)
-- Name: lendenapp_user_gst_203001 lendenapp_user_gst_203001_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203001
    ADD CONSTRAINT lendenapp_user_gst_203001_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8845 (class 2606 OID 1950456)
-- Name: lendenapp_user_gst_203002 lendenapp_user_gst_203002_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203002
    ADD CONSTRAINT lendenapp_user_gst_203002_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8849 (class 2606 OID 1950462)
-- Name: lendenapp_user_gst_203003 lendenapp_user_gst_203003_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203003
    ADD CONSTRAINT lendenapp_user_gst_203003_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8853 (class 2606 OID 1950468)
-- Name: lendenapp_user_gst_203004 lendenapp_user_gst_203004_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203004
    ADD CONSTRAINT lendenapp_user_gst_203004_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8857 (class 2606 OID 1950474)
-- Name: lendenapp_user_gst_203005 lendenapp_user_gst_203005_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203005
    ADD CONSTRAINT lendenapp_user_gst_203005_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8861 (class 2606 OID 1950480)
-- Name: lendenapp_user_gst_203006 lendenapp_user_gst_203006_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203006
    ADD CONSTRAINT lendenapp_user_gst_203006_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8865 (class 2606 OID 1950486)
-- Name: lendenapp_user_gst_203007 lendenapp_user_gst_203007_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203007
    ADD CONSTRAINT lendenapp_user_gst_203007_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8869 (class 2606 OID 1950492)
-- Name: lendenapp_user_gst_203008 lendenapp_user_gst_203008_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203008
    ADD CONSTRAINT lendenapp_user_gst_203008_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8873 (class 2606 OID 1950498)
-- Name: lendenapp_user_gst_203009 lendenapp_user_gst_203009_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203009
    ADD CONSTRAINT lendenapp_user_gst_203009_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8877 (class 2606 OID 1950504)
-- Name: lendenapp_user_gst_203010 lendenapp_user_gst_203010_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203010
    ADD CONSTRAINT lendenapp_user_gst_203010_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8881 (class 2606 OID 1950510)
-- Name: lendenapp_user_gst_203011 lendenapp_user_gst_203011_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203011
    ADD CONSTRAINT lendenapp_user_gst_203011_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8885 (class 2606 OID 1950516)
-- Name: lendenapp_user_gst_203012 lendenapp_user_gst_203012_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203012
    ADD CONSTRAINT lendenapp_user_gst_203012_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8889 (class 2606 OID 1950522)
-- Name: lendenapp_user_gst_203101 lendenapp_user_gst_203101_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203101
    ADD CONSTRAINT lendenapp_user_gst_203101_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8893 (class 2606 OID 1950528)
-- Name: lendenapp_user_gst_203102 lendenapp_user_gst_203102_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203102
    ADD CONSTRAINT lendenapp_user_gst_203102_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8897 (class 2606 OID 1950534)
-- Name: lendenapp_user_gst_203103 lendenapp_user_gst_203103_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203103
    ADD CONSTRAINT lendenapp_user_gst_203103_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8901 (class 2606 OID 1950540)
-- Name: lendenapp_user_gst_203104 lendenapp_user_gst_203104_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203104
    ADD CONSTRAINT lendenapp_user_gst_203104_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8905 (class 2606 OID 1950546)
-- Name: lendenapp_user_gst_203105 lendenapp_user_gst_203105_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203105
    ADD CONSTRAINT lendenapp_user_gst_203105_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8909 (class 2606 OID 1950552)
-- Name: lendenapp_user_gst_203106 lendenapp_user_gst_203106_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203106
    ADD CONSTRAINT lendenapp_user_gst_203106_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8913 (class 2606 OID 1950558)
-- Name: lendenapp_user_gst_203107 lendenapp_user_gst_203107_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203107
    ADD CONSTRAINT lendenapp_user_gst_203107_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8917 (class 2606 OID 1950564)
-- Name: lendenapp_user_gst_203108 lendenapp_user_gst_203108_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203108
    ADD CONSTRAINT lendenapp_user_gst_203108_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8921 (class 2606 OID 1950570)
-- Name: lendenapp_user_gst_203109 lendenapp_user_gst_203109_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203109
    ADD CONSTRAINT lendenapp_user_gst_203109_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8925 (class 2606 OID 1950576)
-- Name: lendenapp_user_gst_203110 lendenapp_user_gst_203110_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203110
    ADD CONSTRAINT lendenapp_user_gst_203110_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8929 (class 2606 OID 1950582)
-- Name: lendenapp_user_gst_203111 lendenapp_user_gst_203111_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203111
    ADD CONSTRAINT lendenapp_user_gst_203111_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8933 (class 2606 OID 1950588)
-- Name: lendenapp_user_gst_203112 lendenapp_user_gst_203112_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203112
    ADD CONSTRAINT lendenapp_user_gst_203112_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8937 (class 2606 OID 1950594)
-- Name: lendenapp_user_gst_203201 lendenapp_user_gst_203201_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203201
    ADD CONSTRAINT lendenapp_user_gst_203201_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8941 (class 2606 OID 1950600)
-- Name: lendenapp_user_gst_203202 lendenapp_user_gst_203202_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203202
    ADD CONSTRAINT lendenapp_user_gst_203202_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8945 (class 2606 OID 1950606)
-- Name: lendenapp_user_gst_203203 lendenapp_user_gst_203203_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203203
    ADD CONSTRAINT lendenapp_user_gst_203203_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8949 (class 2606 OID 1950612)
-- Name: lendenapp_user_gst_203204 lendenapp_user_gst_203204_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203204
    ADD CONSTRAINT lendenapp_user_gst_203204_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8953 (class 2606 OID 1950618)
-- Name: lendenapp_user_gst_203205 lendenapp_user_gst_203205_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203205
    ADD CONSTRAINT lendenapp_user_gst_203205_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8957 (class 2606 OID 1950624)
-- Name: lendenapp_user_gst_203206 lendenapp_user_gst_203206_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203206
    ADD CONSTRAINT lendenapp_user_gst_203206_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8961 (class 2606 OID 1950630)
-- Name: lendenapp_user_gst_203207 lendenapp_user_gst_203207_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203207
    ADD CONSTRAINT lendenapp_user_gst_203207_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8965 (class 2606 OID 1950636)
-- Name: lendenapp_user_gst_203208 lendenapp_user_gst_203208_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203208
    ADD CONSTRAINT lendenapp_user_gst_203208_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8969 (class 2606 OID 1950642)
-- Name: lendenapp_user_gst_203209 lendenapp_user_gst_203209_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203209
    ADD CONSTRAINT lendenapp_user_gst_203209_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8973 (class 2606 OID 1950648)
-- Name: lendenapp_user_gst_203210 lendenapp_user_gst_203210_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203210
    ADD CONSTRAINT lendenapp_user_gst_203210_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8977 (class 2606 OID 1950654)
-- Name: lendenapp_user_gst_203211 lendenapp_user_gst_203211_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203211
    ADD CONSTRAINT lendenapp_user_gst_203211_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8981 (class 2606 OID 1950660)
-- Name: lendenapp_user_gst_203212 lendenapp_user_gst_203212_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203212
    ADD CONSTRAINT lendenapp_user_gst_203212_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8985 (class 2606 OID 1950666)
-- Name: lendenapp_user_gst_203301 lendenapp_user_gst_203301_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203301
    ADD CONSTRAINT lendenapp_user_gst_203301_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8989 (class 2606 OID 1950672)
-- Name: lendenapp_user_gst_203302 lendenapp_user_gst_203302_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203302
    ADD CONSTRAINT lendenapp_user_gst_203302_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8993 (class 2606 OID 1950678)
-- Name: lendenapp_user_gst_203303 lendenapp_user_gst_203303_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203303
    ADD CONSTRAINT lendenapp_user_gst_203303_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8997 (class 2606 OID 1950684)
-- Name: lendenapp_user_gst_203304 lendenapp_user_gst_203304_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203304
    ADD CONSTRAINT lendenapp_user_gst_203304_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9001 (class 2606 OID 1950690)
-- Name: lendenapp_user_gst_203305 lendenapp_user_gst_203305_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203305
    ADD CONSTRAINT lendenapp_user_gst_203305_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9005 (class 2606 OID 1950696)
-- Name: lendenapp_user_gst_203306 lendenapp_user_gst_203306_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203306
    ADD CONSTRAINT lendenapp_user_gst_203306_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9009 (class 2606 OID 1950702)
-- Name: lendenapp_user_gst_203307 lendenapp_user_gst_203307_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203307
    ADD CONSTRAINT lendenapp_user_gst_203307_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9013 (class 2606 OID 1950708)
-- Name: lendenapp_user_gst_203308 lendenapp_user_gst_203308_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203308
    ADD CONSTRAINT lendenapp_user_gst_203308_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9017 (class 2606 OID 1950714)
-- Name: lendenapp_user_gst_203309 lendenapp_user_gst_203309_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203309
    ADD CONSTRAINT lendenapp_user_gst_203309_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9021 (class 2606 OID 1950720)
-- Name: lendenapp_user_gst_203310 lendenapp_user_gst_203310_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203310
    ADD CONSTRAINT lendenapp_user_gst_203310_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9025 (class 2606 OID 1950726)
-- Name: lendenapp_user_gst_203311 lendenapp_user_gst_203311_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203311
    ADD CONSTRAINT lendenapp_user_gst_203311_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9029 (class 2606 OID 1950732)
-- Name: lendenapp_user_gst_203312 lendenapp_user_gst_203312_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203312
    ADD CONSTRAINT lendenapp_user_gst_203312_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9033 (class 2606 OID 1950738)
-- Name: lendenapp_user_gst_203401 lendenapp_user_gst_203401_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203401
    ADD CONSTRAINT lendenapp_user_gst_203401_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9037 (class 2606 OID 1950744)
-- Name: lendenapp_user_gst_203402 lendenapp_user_gst_203402_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203402
    ADD CONSTRAINT lendenapp_user_gst_203402_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9041 (class 2606 OID 1950750)
-- Name: lendenapp_user_gst_203403 lendenapp_user_gst_203403_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203403
    ADD CONSTRAINT lendenapp_user_gst_203403_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9045 (class 2606 OID 1950756)
-- Name: lendenapp_user_gst_203404 lendenapp_user_gst_203404_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203404
    ADD CONSTRAINT lendenapp_user_gst_203404_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9049 (class 2606 OID 1950762)
-- Name: lendenapp_user_gst_203405 lendenapp_user_gst_203405_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203405
    ADD CONSTRAINT lendenapp_user_gst_203405_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9053 (class 2606 OID 1950768)
-- Name: lendenapp_user_gst_203406 lendenapp_user_gst_203406_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203406
    ADD CONSTRAINT lendenapp_user_gst_203406_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9057 (class 2606 OID 1950774)
-- Name: lendenapp_user_gst_203407 lendenapp_user_gst_203407_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203407
    ADD CONSTRAINT lendenapp_user_gst_203407_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9061 (class 2606 OID 1950780)
-- Name: lendenapp_user_gst_203408 lendenapp_user_gst_203408_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203408
    ADD CONSTRAINT lendenapp_user_gst_203408_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9065 (class 2606 OID 1950786)
-- Name: lendenapp_user_gst_203409 lendenapp_user_gst_203409_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203409
    ADD CONSTRAINT lendenapp_user_gst_203409_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9069 (class 2606 OID 1950792)
-- Name: lendenapp_user_gst_203410 lendenapp_user_gst_203410_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203410
    ADD CONSTRAINT lendenapp_user_gst_203410_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9073 (class 2606 OID 1950798)
-- Name: lendenapp_user_gst_203411 lendenapp_user_gst_203411_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203411
    ADD CONSTRAINT lendenapp_user_gst_203411_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9077 (class 2606 OID 1950804)
-- Name: lendenapp_user_gst_203412 lendenapp_user_gst_203412_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203412
    ADD CONSTRAINT lendenapp_user_gst_203412_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9081 (class 2606 OID 1950810)
-- Name: lendenapp_user_gst_203501 lendenapp_user_gst_203501_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203501
    ADD CONSTRAINT lendenapp_user_gst_203501_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9085 (class 2606 OID 1950816)
-- Name: lendenapp_user_gst_203502 lendenapp_user_gst_203502_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203502
    ADD CONSTRAINT lendenapp_user_gst_203502_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9089 (class 2606 OID 1950822)
-- Name: lendenapp_user_gst_203503 lendenapp_user_gst_203503_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203503
    ADD CONSTRAINT lendenapp_user_gst_203503_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9093 (class 2606 OID 1950828)
-- Name: lendenapp_user_gst_203504 lendenapp_user_gst_203504_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203504
    ADD CONSTRAINT lendenapp_user_gst_203504_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9097 (class 2606 OID 1950834)
-- Name: lendenapp_user_gst_203505 lendenapp_user_gst_203505_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203505
    ADD CONSTRAINT lendenapp_user_gst_203505_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9101 (class 2606 OID 1950840)
-- Name: lendenapp_user_gst_203506 lendenapp_user_gst_203506_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203506
    ADD CONSTRAINT lendenapp_user_gst_203506_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9105 (class 2606 OID 1950846)
-- Name: lendenapp_user_gst_203507 lendenapp_user_gst_203507_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203507
    ADD CONSTRAINT lendenapp_user_gst_203507_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9109 (class 2606 OID 1950852)
-- Name: lendenapp_user_gst_203508 lendenapp_user_gst_203508_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203508
    ADD CONSTRAINT lendenapp_user_gst_203508_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9113 (class 2606 OID 1950858)
-- Name: lendenapp_user_gst_203509 lendenapp_user_gst_203509_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203509
    ADD CONSTRAINT lendenapp_user_gst_203509_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9117 (class 2606 OID 1950864)
-- Name: lendenapp_user_gst_203510 lendenapp_user_gst_203510_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203510
    ADD CONSTRAINT lendenapp_user_gst_203510_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9121 (class 2606 OID 1950870)
-- Name: lendenapp_user_gst_203511 lendenapp_user_gst_203511_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203511
    ADD CONSTRAINT lendenapp_user_gst_203511_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9125 (class 2606 OID 1950876)
-- Name: lendenapp_user_gst_203512 lendenapp_user_gst_203512_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203512
    ADD CONSTRAINT lendenapp_user_gst_203512_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9129 (class 2606 OID 1950882)
-- Name: lendenapp_user_gst_203601 lendenapp_user_gst_203601_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203601
    ADD CONSTRAINT lendenapp_user_gst_203601_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9133 (class 2606 OID 1950888)
-- Name: lendenapp_user_gst_203602 lendenapp_user_gst_203602_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203602
    ADD CONSTRAINT lendenapp_user_gst_203602_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9137 (class 2606 OID 1950894)
-- Name: lendenapp_user_gst_203603 lendenapp_user_gst_203603_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203603
    ADD CONSTRAINT lendenapp_user_gst_203603_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9141 (class 2606 OID 1950900)
-- Name: lendenapp_user_gst_203604 lendenapp_user_gst_203604_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203604
    ADD CONSTRAINT lendenapp_user_gst_203604_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9145 (class 2606 OID 1950906)
-- Name: lendenapp_user_gst_203605 lendenapp_user_gst_203605_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203605
    ADD CONSTRAINT lendenapp_user_gst_203605_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9149 (class 2606 OID 1950912)
-- Name: lendenapp_user_gst_203606 lendenapp_user_gst_203606_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203606
    ADD CONSTRAINT lendenapp_user_gst_203606_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9153 (class 2606 OID 1950918)
-- Name: lendenapp_user_gst_203607 lendenapp_user_gst_203607_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203607
    ADD CONSTRAINT lendenapp_user_gst_203607_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9157 (class 2606 OID 1950924)
-- Name: lendenapp_user_gst_203608 lendenapp_user_gst_203608_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203608
    ADD CONSTRAINT lendenapp_user_gst_203608_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9161 (class 2606 OID 1950930)
-- Name: lendenapp_user_gst_203609 lendenapp_user_gst_203609_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203609
    ADD CONSTRAINT lendenapp_user_gst_203609_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9165 (class 2606 OID 1950936)
-- Name: lendenapp_user_gst_203610 lendenapp_user_gst_203610_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203610
    ADD CONSTRAINT lendenapp_user_gst_203610_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9169 (class 2606 OID 1950942)
-- Name: lendenapp_user_gst_203611 lendenapp_user_gst_203611_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203611
    ADD CONSTRAINT lendenapp_user_gst_203611_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9173 (class 2606 OID 1950948)
-- Name: lendenapp_user_gst_203612 lendenapp_user_gst_203612_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203612
    ADD CONSTRAINT lendenapp_user_gst_203612_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9177 (class 2606 OID 1950954)
-- Name: lendenapp_user_gst_203701 lendenapp_user_gst_203701_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203701
    ADD CONSTRAINT lendenapp_user_gst_203701_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9181 (class 2606 OID 1950960)
-- Name: lendenapp_user_gst_203702 lendenapp_user_gst_203702_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203702
    ADD CONSTRAINT lendenapp_user_gst_203702_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9185 (class 2606 OID 1950966)
-- Name: lendenapp_user_gst_203703 lendenapp_user_gst_203703_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203703
    ADD CONSTRAINT lendenapp_user_gst_203703_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9189 (class 2606 OID 1950972)
-- Name: lendenapp_user_gst_203704 lendenapp_user_gst_203704_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203704
    ADD CONSTRAINT lendenapp_user_gst_203704_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9193 (class 2606 OID 1950978)
-- Name: lendenapp_user_gst_203705 lendenapp_user_gst_203705_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203705
    ADD CONSTRAINT lendenapp_user_gst_203705_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9197 (class 2606 OID 1950984)
-- Name: lendenapp_user_gst_203706 lendenapp_user_gst_203706_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203706
    ADD CONSTRAINT lendenapp_user_gst_203706_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9201 (class 2606 OID 1950990)
-- Name: lendenapp_user_gst_203707 lendenapp_user_gst_203707_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203707
    ADD CONSTRAINT lendenapp_user_gst_203707_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9205 (class 2606 OID 1950996)
-- Name: lendenapp_user_gst_203708 lendenapp_user_gst_203708_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203708
    ADD CONSTRAINT lendenapp_user_gst_203708_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9209 (class 2606 OID 1951002)
-- Name: lendenapp_user_gst_203709 lendenapp_user_gst_203709_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203709
    ADD CONSTRAINT lendenapp_user_gst_203709_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9213 (class 2606 OID 1951008)
-- Name: lendenapp_user_gst_203710 lendenapp_user_gst_203710_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203710
    ADD CONSTRAINT lendenapp_user_gst_203710_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9217 (class 2606 OID 1951014)
-- Name: lendenapp_user_gst_203711 lendenapp_user_gst_203711_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203711
    ADD CONSTRAINT lendenapp_user_gst_203711_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9221 (class 2606 OID 1951020)
-- Name: lendenapp_user_gst_203712 lendenapp_user_gst_203712_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203712
    ADD CONSTRAINT lendenapp_user_gst_203712_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9225 (class 2606 OID 1951026)
-- Name: lendenapp_user_gst_203801 lendenapp_user_gst_203801_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203801
    ADD CONSTRAINT lendenapp_user_gst_203801_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9229 (class 2606 OID 1951032)
-- Name: lendenapp_user_gst_203802 lendenapp_user_gst_203802_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203802
    ADD CONSTRAINT lendenapp_user_gst_203802_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9233 (class 2606 OID 1951038)
-- Name: lendenapp_user_gst_203803 lendenapp_user_gst_203803_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203803
    ADD CONSTRAINT lendenapp_user_gst_203803_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9237 (class 2606 OID 1951044)
-- Name: lendenapp_user_gst_203804 lendenapp_user_gst_203804_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203804
    ADD CONSTRAINT lendenapp_user_gst_203804_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9241 (class 2606 OID 1951050)
-- Name: lendenapp_user_gst_203805 lendenapp_user_gst_203805_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203805
    ADD CONSTRAINT lendenapp_user_gst_203805_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9245 (class 2606 OID 1951056)
-- Name: lendenapp_user_gst_203806 lendenapp_user_gst_203806_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203806
    ADD CONSTRAINT lendenapp_user_gst_203806_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9249 (class 2606 OID 1951062)
-- Name: lendenapp_user_gst_203807 lendenapp_user_gst_203807_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203807
    ADD CONSTRAINT lendenapp_user_gst_203807_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9253 (class 2606 OID 1951068)
-- Name: lendenapp_user_gst_203808 lendenapp_user_gst_203808_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203808
    ADD CONSTRAINT lendenapp_user_gst_203808_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9257 (class 2606 OID 1951074)
-- Name: lendenapp_user_gst_203809 lendenapp_user_gst_203809_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203809
    ADD CONSTRAINT lendenapp_user_gst_203809_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9261 (class 2606 OID 1951080)
-- Name: lendenapp_user_gst_203810 lendenapp_user_gst_203810_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203810
    ADD CONSTRAINT lendenapp_user_gst_203810_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9265 (class 2606 OID 1951086)
-- Name: lendenapp_user_gst_203811 lendenapp_user_gst_203811_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203811
    ADD CONSTRAINT lendenapp_user_gst_203811_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9269 (class 2606 OID 1951092)
-- Name: lendenapp_user_gst_203812 lendenapp_user_gst_203812_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203812
    ADD CONSTRAINT lendenapp_user_gst_203812_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9273 (class 2606 OID 1951098)
-- Name: lendenapp_user_gst_203901 lendenapp_user_gst_203901_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203901
    ADD CONSTRAINT lendenapp_user_gst_203901_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9277 (class 2606 OID 1951104)
-- Name: lendenapp_user_gst_203902 lendenapp_user_gst_203902_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203902
    ADD CONSTRAINT lendenapp_user_gst_203902_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9281 (class 2606 OID 1951110)
-- Name: lendenapp_user_gst_203903 lendenapp_user_gst_203903_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203903
    ADD CONSTRAINT lendenapp_user_gst_203903_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9285 (class 2606 OID 1951116)
-- Name: lendenapp_user_gst_203904 lendenapp_user_gst_203904_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203904
    ADD CONSTRAINT lendenapp_user_gst_203904_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9289 (class 2606 OID 1951122)
-- Name: lendenapp_user_gst_203905 lendenapp_user_gst_203905_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203905
    ADD CONSTRAINT lendenapp_user_gst_203905_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9293 (class 2606 OID 1951128)
-- Name: lendenapp_user_gst_203906 lendenapp_user_gst_203906_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203906
    ADD CONSTRAINT lendenapp_user_gst_203906_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9297 (class 2606 OID 1951134)
-- Name: lendenapp_user_gst_203907 lendenapp_user_gst_203907_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203907
    ADD CONSTRAINT lendenapp_user_gst_203907_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9301 (class 2606 OID 1951140)
-- Name: lendenapp_user_gst_203908 lendenapp_user_gst_203908_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203908
    ADD CONSTRAINT lendenapp_user_gst_203908_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9305 (class 2606 OID 1951146)
-- Name: lendenapp_user_gst_203909 lendenapp_user_gst_203909_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203909
    ADD CONSTRAINT lendenapp_user_gst_203909_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9309 (class 2606 OID 1951152)
-- Name: lendenapp_user_gst_203910 lendenapp_user_gst_203910_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203910
    ADD CONSTRAINT lendenapp_user_gst_203910_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9313 (class 2606 OID 1951158)
-- Name: lendenapp_user_gst_203911 lendenapp_user_gst_203911_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203911
    ADD CONSTRAINT lendenapp_user_gst_203911_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9317 (class 2606 OID 1951164)
-- Name: lendenapp_user_gst_203912 lendenapp_user_gst_203912_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_203912
    ADD CONSTRAINT lendenapp_user_gst_203912_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9321 (class 2606 OID 1951170)
-- Name: lendenapp_user_gst_204001 lendenapp_user_gst_204001_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_204001
    ADD CONSTRAINT lendenapp_user_gst_204001_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9325 (class 2606 OID 1951176)
-- Name: lendenapp_user_gst_204002 lendenapp_user_gst_204002_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_204002
    ADD CONSTRAINT lendenapp_user_gst_204002_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 9329 (class 2606 OID 1951182)
-- Name: lendenapp_user_gst_204003 lendenapp_user_gst_204003_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_gst_204003
    ADD CONSTRAINT lendenapp_user_gst_204003_pkey PRIMARY KEY (id, transaction_date);


--
-- TOC entry 8379 (class 2606 OID 20080)
-- Name: lendenapp_user_report_log lendenapp_user_report_log_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_report_log
    ADD CONSTRAINT lendenapp_user_report_log_pkey PRIMARY KEY (id);


--
-- TOC entry 8275 (class 2606 OID 20081)
-- Name: lendenapp_user_source_group lendenapp_user_source_group_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_source_group
    ADD CONSTRAINT lendenapp_user_source_group_pkey PRIMARY KEY (id);


--
-- TOC entry 8360 (class 2606 OID 20082)
-- Name: lendenapp_userconsentlog lendenapp_userconsentlog_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userconsentlog
    ADD CONSTRAINT lendenapp_userconsentlog_pkey PRIMARY KEY (id);


--
-- TOC entry 8306 (class 2606 OID 20083)
-- Name: lendenapp_userkyc lendenapp_userkyc_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyc
    ADD CONSTRAINT lendenapp_userkyc_pkey PRIMARY KEY (id);


--
-- TOC entry 8406 (class 2606 OID 20084)
-- Name: lendenapp_userkyctracker lendenapp_userkyctracker_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyctracker
    ADD CONSTRAINT lendenapp_userkyctracker_pkey PRIMARY KEY (id);


--
-- TOC entry 8383 (class 2606 OID 20085)
-- Name: lendenapp_userotp lendenapp_userotp_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userotp
    ADD CONSTRAINT lendenapp_userotp_pkey PRIMARY KEY (id);


--
-- TOC entry 8363 (class 2606 OID 20086)
-- Name: lendenapp_userupimandate lendenapp_userupimandate_mandate_request_id_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userupimandate
    ADD CONSTRAINT lendenapp_userupimandate_mandate_request_id_key UNIQUE (mandate_request_id);


--
-- TOC entry 8365 (class 2606 OID 20087)
-- Name: lendenapp_userupimandate lendenapp_userupimandate_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userupimandate
    ADD CONSTRAINT lendenapp_userupimandate_pkey PRIMARY KEY (id);


--
-- TOC entry 8397 (class 2606 OID 20088)
-- Name: lendenapp_utilitypreferences lendenapp_utilitypreferences_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_utilitypreferences
    ADD CONSTRAINT lendenapp_utilitypreferences_pkey PRIMARY KEY (id);


--
-- TOC entry 8385 (class 2606 OID 20089)
-- Name: lendenapp_withdrawalsummary lendenapp_withdrawalsummary_batch_reference_number_key; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_withdrawalsummary
    ADD CONSTRAINT lendenapp_withdrawalsummary_batch_reference_number_key UNIQUE (batch_reference_number);


--
-- TOC entry 8387 (class 2606 OID 20090)
-- Name: lendenapp_withdrawalsummary lendenapp_withdrawalsummary_pkey; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_withdrawalsummary
    ADD CONSTRAINT lendenapp_withdrawalsummary_pkey PRIMARY KEY (id);


--
-- TOC entry 8418 (class 2606 OID 20091)
-- Name: reverse_penny_drop reverse_penny_drop_pkey; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.reverse_penny_drop
    ADD CONSTRAINT reverse_penny_drop_pkey PRIMARY KEY (id);


--
-- TOC entry 8420 (class 2606 OID 20092)
-- Name: reverse_penny_drop reverse_penny_drop_tracking_id_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.reverse_penny_drop
    ADD CONSTRAINT reverse_penny_drop_tracking_id_key UNIQUE (tracking_id);


--
-- TOC entry 8422 (class 2606 OID 20093)
-- Name: reverse_penny_drop reverse_penny_drop_verification_id_key; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.reverse_penny_drop
    ADD CONSTRAINT reverse_penny_drop_verification_id_key UNIQUE (verification_id);


--
-- TOC entry 8466 (class 2606 OID 20094)
-- Name: lendenapp_scheme_repayment_details uniq_record_id; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details
    ADD CONSTRAINT uniq_record_id UNIQUE (unique_record_id);


--
-- TOC entry 8247 (class 2606 OID 1949019)
-- Name: auth_group unique_auth_group_name; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT unique_auth_group_name UNIQUE (name);


--
-- TOC entry 8255 (class 2606 OID 20096)
-- Name: lendenapp_bank unique_bank_name; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bank
    ADD CONSTRAINT unique_bank_name UNIQUE (name);


--
-- TOC entry 8684 (class 2606 OID 1883478)
-- Name: lendenapp_application_config unique_configuration; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_application_config
    ADD CONSTRAINT unique_configuration UNIQUE (config_type, config_key);


--
-- TOC entry 8341 (class 2606 OID 20098)
-- Name: lendenapp_paymentlink unique_order_id; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_paymentlink
    ADD CONSTRAINT unique_order_id UNIQUE (order_id);


--
-- TOC entry 8259 (class 2606 OID 20099)
-- Name: lendenapp_pincode_state_master unique_pincode; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_pincode_state_master
    ADD CONSTRAINT unique_pincode UNIQUE (pincode);


--
-- TOC entry 8343 (class 2606 OID 20100)
-- Name: lendenapp_paymentlink unique_reference_id; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_paymentlink
    ADD CONSTRAINT unique_reference_id UNIQUE (reference_id);


--
-- TOC entry 8251 (class 2606 OID 20101)
-- Name: lendenapp_source unique_source_name; Type: CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_source
    ADD CONSTRAINT unique_source_name UNIQUE (source_name);


--
-- TOC entry 8680 (class 2606 OID 1956928)
-- Name: lendenapp_counter uq_lendenapp_counter_prefix; Type: CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_counter
    ADD CONSTRAINT uq_lendenapp_counter_prefix UNIQUE (prefix);


--
-- TOC entry 8276 (class 1259 OID 801272)
-- Name: idx_assigned_by_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_assigned_by_id ON public.lendenapp_task USING btree (assigned_by_id);


--
-- TOC entry 8282 (class 1259 OID 801601)
-- Name: idx_bankaccount_bank_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_bankaccount_bank_id ON public.lendenapp_bankaccount USING btree (bank_id);


--
-- TOC entry 8283 (class 1259 OID 801602)
-- Name: idx_bankaccount_task_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_bankaccount_task_id ON public.lendenapp_bankaccount USING btree (task_id);


--
-- TOC entry 8284 (class 1259 OID 801603)
-- Name: idx_bankaccount_user_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_bankaccount_user_id ON public.lendenapp_bankaccount USING btree (user_id);


--
-- TOC entry 8271 (class 1259 OID 745171)
-- Name: idx_channel_partner_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_channel_partner_id ON public.lendenapp_user_source_group USING btree (channel_partner_id);


--
-- TOC entry 8277 (class 1259 OID 801271)
-- Name: idx_checklist_gin; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_checklist_gin ON public.lendenapp_task USING gin (to_tsvector('english'::regconfig, checklist));


--
-- TOC entry 8293 (class 1259 OID 801675)
-- Name: idx_convertedreferral_referred_by_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_convertedreferral_referred_by_id ON public.lendenapp_convertedreferral USING btree (referred_by_id);


--
-- TOC entry 8294 (class 1259 OID 801676)
-- Name: idx_convertedreferral_user_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_convertedreferral_user_id ON public.lendenapp_convertedreferral USING btree (user_id);


--
-- TOC entry 8278 (class 1259 OID 801273)
-- Name: idx_created_by_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_created_by_id ON public.lendenapp_task USING btree (created_by_id);


--
-- TOC entry 8297 (class 1259 OID 1531125)
-- Name: idx_created_date; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_created_date ON public.lendenapp_transaction USING btree (created_date);


--
-- TOC entry 8287 (class 1259 OID 801632)
-- Name: idx_customuser_groups_customuser_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_customuser_groups_customuser_id ON public.lendenapp_customuser_groups USING btree (customuser_id);


--
-- TOC entry 8288 (class 1259 OID 801631)
-- Name: idx_customuser_groups_group_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_customuser_groups_group_id ON public.lendenapp_customuser_groups USING btree (group_id);


--
-- TOC entry 8508 (class 1259 OID 1534686)
-- Name: idx_fmi_createddate; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_fmi_createddate ON public.lendenapp_fmi_withdrawals USING btree (created_date);


--
-- TOC entry 8509 (class 1259 OID 1534684)
-- Name: idx_fmi_transaction_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_fmi_transaction_id ON public.lendenapp_fmi_withdrawals USING btree (transaction_id);


--
-- TOC entry 8510 (class 1259 OID 1534685)
-- Name: idx_fmi_usersourcegroupid; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_fmi_usersourcegroupid ON public.lendenapp_fmi_withdrawals USING btree (user_source_group_id);


--
-- TOC entry 8467 (class 1259 OID 1529754)
-- Name: idx_investment_type; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_investment_type ON public.lendenapp_otl_scheme_tracker USING btree (investment_type) WHERE ((investment_type)::text = 'MANUAL_LENDING'::text);


--
-- TOC entry 8456 (class 1259 OID 1260956)
-- Name: idx_investor_cp_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_investor_cp_id ON public.investor_dashboard_view USING btree (cp_id);


--
-- TOC entry 8457 (class 1259 OID 1260957)
-- Name: idx_investor_mcp_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_investor_mcp_id ON public.investor_dashboard_view USING btree (mcp_id);


--
-- TOC entry 8458 (class 1259 OID 1260958)
-- Name: idx_investor_user_source_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_investor_user_source_id ON public.investor_dashboard_view USING btree (user_source_id);


--
-- TOC entry 8459 (class 1259 OID 1533357)
-- Name: idx_is_pushed_to_zoho; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_is_pushed_to_zoho ON public.lendenapp_scheme_repayment_details USING btree (is_pushed_to_zoho) WHERE (is_pushed_to_zoho = false);


--
-- TOC entry 8572 (class 1259 OID 1961607)
-- Name: idx_ldwfb_user_date_purpose; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_ldwfb_user_date_purpose ON public.lendenapp_day_wise_fee_bifurcation USING btree (user_id, transaction_date, purpose);


--
-- TOC entry 8705 (class 1259 OID 1949158)
-- Name: idx_lendenapp_cp_staff_log_owner_cp_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_lendenapp_cp_staff_log_owner_cp_id ON public.lendenapp_cp_staff_log USING btree (owner_cp_id);


--
-- TOC entry 8435 (class 1259 OID 1078990)
-- Name: idx_mandate_link; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_mandate_link ON public.lendenapp_mandate USING btree (mandate_tracker_id);


--
-- TOC entry 8436 (class 1259 OID 1078989)
-- Name: idx_mandate_user_source_group_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_mandate_user_source_group_id ON public.lendenapp_mandate USING btree (user_source_group_id);


--
-- TOC entry 8429 (class 1259 OID 1080276)
-- Name: idx_mandatetracker_scheme_info_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_mandatetracker_scheme_info_id ON public.lendenapp_mandatetracker USING btree (scheme_info_id);


--
-- TOC entry 8473 (class 1259 OID 1456148)
-- Name: idx_otl_partner_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_otl_partner_id ON public.lendenapp_otl_scheme_loan_mapping_old USING btree (partner_id);


--
-- TOC entry 8474 (class 1259 OID 1456149)
-- Name: idx_otl_scheme_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_otl_scheme_id ON public.lendenapp_otl_scheme_loan_mapping_old USING btree (otl_tracker_id);


--
-- TOC entry 8468 (class 1259 OID 1449368)
-- Name: idx_otl_scheme_tracker_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_otl_scheme_tracker_id ON public.lendenapp_otl_scheme_tracker USING btree (scheme_id);


--
-- TOC entry 8469 (class 1259 OID 1449369)
-- Name: idx_otl_tracker_user_source_group_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_otl_tracker_user_source_group_id ON public.lendenapp_otl_scheme_tracker USING btree (user_source_group_id);


--
-- TOC entry 8475 (class 1259 OID 1456150)
-- Name: idx_otl_user_source_group_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_otl_user_source_group_id ON public.lendenapp_otl_scheme_loan_mapping_old USING btree (user_source_group_id);


--
-- TOC entry 8264 (class 1259 OID 736682)
-- Name: idx_partner_id_pattern; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_partner_id_pattern ON public.lendenapp_channelpartner USING btree (partner_id varchar_pattern_ops);


--
-- TOC entry 8336 (class 1259 OID 1527532)
-- Name: idx_payment_gateway; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_payment_gateway ON public.lendenapp_paymentlink USING btree (payment_gateway);


--
-- TOC entry 8404 (class 1259 OID 1536276)
-- Name: idx_re_aml_status; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_re_aml_status ON public.lendenapp_userkyctracker USING btree (re_aml_status) WHERE ((re_aml_status)::text = 'INITIATED'::text);


--
-- TOC entry 8325 (class 1259 OID 1244660)
-- Name: idx_reference_number; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_reference_number ON public.lendenapp_offline_payment_request USING btree (reference_number);


--
-- TOC entry 8265 (class 1259 OID 736673)
-- Name: idx_referred_by_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_referred_by_id ON public.lendenapp_channelpartner USING btree (referred_by_id);


--
-- TOC entry 8439 (class 1259 OID 1079410)
-- Name: idx_reinvestment_user_source_group_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_reinvestment_user_source_group_id ON public.lendenapp_nach_presentation USING btree (user_source_group_id);


--
-- TOC entry 8446 (class 1259 OID 1530618)
-- Name: idx_remarks; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_remarks ON public.lendenapp_snorkel_stuck_transaction USING btree (remarks);


--
-- TOC entry 8460 (class 1259 OID 1531813)
-- Name: idx_repayment_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_repayment_id ON public.lendenapp_scheme_repayment_details USING btree (repayment_id);


--
-- TOC entry 8425 (class 1259 OID 1078938)
-- Name: idx_scheme_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_scheme_id ON public.lendenapp_schemeinfo USING btree (scheme_id);


--
-- TOC entry 8440 (class 1259 OID 1079411)
-- Name: idx_scheme_info_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_scheme_info_id ON public.lendenapp_nach_presentation USING btree (scheme_info_id);


--
-- TOC entry 8272 (class 1259 OID 745170)
-- Name: idx_source_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_source_id ON public.lendenapp_user_source_group USING btree (source_id);


--
-- TOC entry 8447 (class 1259 OID 1530619)
-- Name: idx_status_hold; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_status_hold ON public.lendenapp_snorkel_stuck_transaction USING btree (status) WHERE ((status)::text = 'HOLD'::text);


--
-- TOC entry 8470 (class 1259 OID 1454086)
-- Name: idx_tracker_transaction_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_tracker_transaction_id ON public.lendenapp_otl_scheme_tracker USING btree (transaction_id);


--
-- TOC entry 8426 (class 1259 OID 1078939)
-- Name: idx_transaction_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_transaction_id ON public.lendenapp_schemeinfo USING btree (transaction_id);


--
-- TOC entry 8298 (class 1259 OID 1530620)
-- Name: idx_txn_hold; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_txn_hold ON public.lendenapp_transaction USING btree (status) WHERE ((status)::text = 'HOLD'::text);


--
-- TOC entry 8573 (class 1259 OID 1955832)
-- Name: idx_user_ci_invoice_date; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_user_ci_invoice_date ON ONLY public.lendenapp_user_gst USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8266 (class 1259 OID 736681)
-- Name: idx_user_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_user_id ON public.lendenapp_channelpartner USING btree (user_id);


--
-- TOC entry 8574 (class 1259 OID 1956016)
-- Name: idx_user_in_invoice_date; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_user_in_invoice_date ON ONLY public.lendenapp_user_gst USING btree (user_id, in_invoice_date);


--
-- TOC entry 8279 (class 1259 OID 801274)
-- Name: idx_user_source_group_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_user_source_group_id ON public.lendenapp_task USING btree (user_source_group_id);


--
-- TOC entry 8273 (class 1259 OID 745169)
-- Name: idx_user_source_group_user_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_user_source_group_user_id ON public.lendenapp_user_source_group USING btree (user_id);


--
-- TOC entry 8337 (class 1259 OID 1527535)
-- Name: idx_user_source_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX idx_user_source_id ON public.lendenapp_paymentlink USING btree (user_source_group_id);


--
-- TOC entry 8461 (class 1259 OID 1375557)
-- Name: idx_withdrawal_txn_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX idx_withdrawal_txn_id ON public.lendenapp_scheme_repayment_details USING btree (withdrawal_transaction_id);


--
-- TOC entry 8423 (class 1259 OID 1078851)
-- Name: is_processed_temp_idx; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX is_processed_temp_idx ON public.lendenapp_transaction_repayment_temp USING btree (is_processed);


--
-- TOC entry 8313 (class 1259 OID 1301719)
-- Name: lendenapp_acount_usg_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX lendenapp_acount_usg_id ON public.lendenapp_account USING btree (user_source_group_id);


--
-- TOC entry 8322 (class 1259 OID 1359143)
-- Name: lendenapp_address_user_source_group_id; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX lendenapp_address_user_source_group_id ON public.lendenapp_address USING btree (user_source_group_id);


--
-- TOC entry 8569 (class 1259 OID 1539346)
-- Name: lendenapp_address_user_source_group_id_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_address_user_source_group_id_idx ON public.lendenapp_address_v2 USING btree (user_source_group_id);


--
-- TOC entry 8445 (class 1259 OID 1301770)
-- Name: lendenapp_app_rating_usg_id; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_app_rating_usg_id ON public.lendenapp_app_rating USING btree (user_source_group_id);


--
-- TOC entry 8579 (class 1259 OID 1955833)
-- Name: lendenapp_user_gst_202503_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202503_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202503 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8580 (class 1259 OID 1956017)
-- Name: lendenapp_user_gst_202503_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202503_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202503 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8583 (class 1259 OID 1955834)
-- Name: lendenapp_user_gst_202504_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202504_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202504 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8584 (class 1259 OID 1956018)
-- Name: lendenapp_user_gst_202504_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202504_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202504 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8587 (class 1259 OID 1955835)
-- Name: lendenapp_user_gst_202505_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202505_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202505 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8588 (class 1259 OID 1956019)
-- Name: lendenapp_user_gst_202505_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202505_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202505 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8591 (class 1259 OID 1955836)
-- Name: lendenapp_user_gst_202506_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202506_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202506 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8592 (class 1259 OID 1956020)
-- Name: lendenapp_user_gst_202506_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202506_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202506 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8595 (class 1259 OID 1955837)
-- Name: lendenapp_user_gst_202507_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202507_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202507 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8596 (class 1259 OID 1956021)
-- Name: lendenapp_user_gst_202507_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202507_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202507 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8599 (class 1259 OID 1955838)
-- Name: lendenapp_user_gst_202508_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202508_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202508 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8600 (class 1259 OID 1956022)
-- Name: lendenapp_user_gst_202508_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202508_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202508 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8603 (class 1259 OID 1955839)
-- Name: lendenapp_user_gst_202509_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202509_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202509 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8604 (class 1259 OID 1956023)
-- Name: lendenapp_user_gst_202509_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202509_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202509 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8607 (class 1259 OID 1955840)
-- Name: lendenapp_user_gst_202510_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202510_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202510 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8608 (class 1259 OID 1956024)
-- Name: lendenapp_user_gst_202510_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202510_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202510 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8611 (class 1259 OID 1955841)
-- Name: lendenapp_user_gst_202511_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202511_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202511 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8612 (class 1259 OID 1956025)
-- Name: lendenapp_user_gst_202511_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202511_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202511 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8615 (class 1259 OID 1955842)
-- Name: lendenapp_user_gst_202512_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202512_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202512 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8616 (class 1259 OID 1956026)
-- Name: lendenapp_user_gst_202512_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202512_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202512 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8619 (class 1259 OID 1955843)
-- Name: lendenapp_user_gst_202601_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202601_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202601 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8620 (class 1259 OID 1956027)
-- Name: lendenapp_user_gst_202601_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202601_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202601 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8623 (class 1259 OID 1955844)
-- Name: lendenapp_user_gst_202602_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202602_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202602 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8624 (class 1259 OID 1956028)
-- Name: lendenapp_user_gst_202602_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202602_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202602 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8627 (class 1259 OID 1955845)
-- Name: lendenapp_user_gst_202603_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202603_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202603 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8628 (class 1259 OID 1956029)
-- Name: lendenapp_user_gst_202603_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202603_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202603 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8631 (class 1259 OID 1955846)
-- Name: lendenapp_user_gst_202604_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202604_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202604 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8632 (class 1259 OID 1956030)
-- Name: lendenapp_user_gst_202604_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202604_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202604 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8635 (class 1259 OID 1955847)
-- Name: lendenapp_user_gst_202605_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202605_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202605 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8636 (class 1259 OID 1956031)
-- Name: lendenapp_user_gst_202605_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202605_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202605 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8639 (class 1259 OID 1955848)
-- Name: lendenapp_user_gst_202606_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202606_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202606 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8640 (class 1259 OID 1956032)
-- Name: lendenapp_user_gst_202606_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202606_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202606 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8643 (class 1259 OID 1955849)
-- Name: lendenapp_user_gst_202607_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202607_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202607 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8644 (class 1259 OID 1956033)
-- Name: lendenapp_user_gst_202607_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202607_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202607 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8647 (class 1259 OID 1955850)
-- Name: lendenapp_user_gst_202608_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202608_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202608 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8648 (class 1259 OID 1956034)
-- Name: lendenapp_user_gst_202608_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202608_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202608 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8651 (class 1259 OID 1955851)
-- Name: lendenapp_user_gst_202609_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202609_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202609 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8652 (class 1259 OID 1956035)
-- Name: lendenapp_user_gst_202609_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202609_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202609 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8655 (class 1259 OID 1955852)
-- Name: lendenapp_user_gst_202610_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202610_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202610 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8656 (class 1259 OID 1956036)
-- Name: lendenapp_user_gst_202610_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202610_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202610 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8659 (class 1259 OID 1955853)
-- Name: lendenapp_user_gst_202611_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202611_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202611 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8660 (class 1259 OID 1956037)
-- Name: lendenapp_user_gst_202611_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202611_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202611 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8663 (class 1259 OID 1955854)
-- Name: lendenapp_user_gst_202612_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202612_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202612 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8664 (class 1259 OID 1956038)
-- Name: lendenapp_user_gst_202612_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202612_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202612 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8667 (class 1259 OID 1955855)
-- Name: lendenapp_user_gst_202701_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202701_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202701 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8668 (class 1259 OID 1956039)
-- Name: lendenapp_user_gst_202701_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202701_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202701 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8671 (class 1259 OID 1955856)
-- Name: lendenapp_user_gst_202702_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202702_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202702 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8672 (class 1259 OID 1956040)
-- Name: lendenapp_user_gst_202702_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202702_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202702 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8675 (class 1259 OID 1955857)
-- Name: lendenapp_user_gst_202703_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202703_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202703 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8676 (class 1259 OID 1956041)
-- Name: lendenapp_user_gst_202703_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202703_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202703 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8710 (class 1259 OID 1955858)
-- Name: lendenapp_user_gst_202704_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202704_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202704 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8711 (class 1259 OID 1956042)
-- Name: lendenapp_user_gst_202704_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202704_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202704 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8714 (class 1259 OID 1955859)
-- Name: lendenapp_user_gst_202705_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202705_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202705 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8715 (class 1259 OID 1956043)
-- Name: lendenapp_user_gst_202705_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202705_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202705 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8718 (class 1259 OID 1955860)
-- Name: lendenapp_user_gst_202706_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202706_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202706 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8719 (class 1259 OID 1956044)
-- Name: lendenapp_user_gst_202706_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202706_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202706 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8722 (class 1259 OID 1955861)
-- Name: lendenapp_user_gst_202707_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202707_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202707 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8723 (class 1259 OID 1956045)
-- Name: lendenapp_user_gst_202707_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202707_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202707 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8726 (class 1259 OID 1955862)
-- Name: lendenapp_user_gst_202708_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202708_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202708 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8727 (class 1259 OID 1956046)
-- Name: lendenapp_user_gst_202708_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202708_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202708 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8730 (class 1259 OID 1955863)
-- Name: lendenapp_user_gst_202709_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202709_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202709 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8731 (class 1259 OID 1956047)
-- Name: lendenapp_user_gst_202709_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202709_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202709 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8734 (class 1259 OID 1955864)
-- Name: lendenapp_user_gst_202710_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202710_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202710 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8735 (class 1259 OID 1956048)
-- Name: lendenapp_user_gst_202710_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202710_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202710 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8738 (class 1259 OID 1955865)
-- Name: lendenapp_user_gst_202711_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202711_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202711 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8739 (class 1259 OID 1956049)
-- Name: lendenapp_user_gst_202711_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202711_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202711 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8742 (class 1259 OID 1955866)
-- Name: lendenapp_user_gst_202712_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202712_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202712 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8743 (class 1259 OID 1956050)
-- Name: lendenapp_user_gst_202712_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202712_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202712 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8746 (class 1259 OID 1955867)
-- Name: lendenapp_user_gst_202801_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202801_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202801 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8747 (class 1259 OID 1956051)
-- Name: lendenapp_user_gst_202801_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202801_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202801 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8750 (class 1259 OID 1955868)
-- Name: lendenapp_user_gst_202802_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202802_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202802 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8751 (class 1259 OID 1956052)
-- Name: lendenapp_user_gst_202802_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202802_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202802 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8754 (class 1259 OID 1955869)
-- Name: lendenapp_user_gst_202803_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202803_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202803 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8755 (class 1259 OID 1956053)
-- Name: lendenapp_user_gst_202803_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202803_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202803 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8758 (class 1259 OID 1955870)
-- Name: lendenapp_user_gst_202804_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202804_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202804 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8759 (class 1259 OID 1956054)
-- Name: lendenapp_user_gst_202804_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202804_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202804 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8762 (class 1259 OID 1955871)
-- Name: lendenapp_user_gst_202805_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202805_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202805 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8763 (class 1259 OID 1956055)
-- Name: lendenapp_user_gst_202805_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202805_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202805 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8766 (class 1259 OID 1955872)
-- Name: lendenapp_user_gst_202806_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202806_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202806 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8767 (class 1259 OID 1956056)
-- Name: lendenapp_user_gst_202806_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202806_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202806 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8770 (class 1259 OID 1955873)
-- Name: lendenapp_user_gst_202807_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202807_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202807 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8771 (class 1259 OID 1956057)
-- Name: lendenapp_user_gst_202807_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202807_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202807 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8774 (class 1259 OID 1955874)
-- Name: lendenapp_user_gst_202808_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202808_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202808 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8775 (class 1259 OID 1956058)
-- Name: lendenapp_user_gst_202808_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202808_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202808 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8778 (class 1259 OID 1955875)
-- Name: lendenapp_user_gst_202809_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202809_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202809 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8779 (class 1259 OID 1956059)
-- Name: lendenapp_user_gst_202809_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202809_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202809 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8782 (class 1259 OID 1955876)
-- Name: lendenapp_user_gst_202810_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202810_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202810 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8783 (class 1259 OID 1956060)
-- Name: lendenapp_user_gst_202810_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202810_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202810 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8786 (class 1259 OID 1955877)
-- Name: lendenapp_user_gst_202811_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202811_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202811 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8787 (class 1259 OID 1956061)
-- Name: lendenapp_user_gst_202811_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202811_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202811 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8790 (class 1259 OID 1955878)
-- Name: lendenapp_user_gst_202812_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202812_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202812 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8791 (class 1259 OID 1956062)
-- Name: lendenapp_user_gst_202812_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202812_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202812 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8794 (class 1259 OID 1955879)
-- Name: lendenapp_user_gst_202901_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202901_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202901 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8795 (class 1259 OID 1956063)
-- Name: lendenapp_user_gst_202901_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202901_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202901 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8798 (class 1259 OID 1955880)
-- Name: lendenapp_user_gst_202902_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202902_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202902 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8799 (class 1259 OID 1956064)
-- Name: lendenapp_user_gst_202902_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202902_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202902 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8802 (class 1259 OID 1955881)
-- Name: lendenapp_user_gst_202903_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202903_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202903 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8803 (class 1259 OID 1956065)
-- Name: lendenapp_user_gst_202903_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202903_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202903 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8806 (class 1259 OID 1955882)
-- Name: lendenapp_user_gst_202904_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202904_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202904 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8807 (class 1259 OID 1956066)
-- Name: lendenapp_user_gst_202904_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202904_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202904 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8810 (class 1259 OID 1955883)
-- Name: lendenapp_user_gst_202905_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202905_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202905 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8811 (class 1259 OID 1956067)
-- Name: lendenapp_user_gst_202905_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202905_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202905 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8814 (class 1259 OID 1955884)
-- Name: lendenapp_user_gst_202906_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202906_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202906 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8815 (class 1259 OID 1956068)
-- Name: lendenapp_user_gst_202906_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202906_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202906 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8818 (class 1259 OID 1955885)
-- Name: lendenapp_user_gst_202907_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202907_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202907 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8819 (class 1259 OID 1956069)
-- Name: lendenapp_user_gst_202907_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202907_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202907 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8822 (class 1259 OID 1955886)
-- Name: lendenapp_user_gst_202908_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202908_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202908 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8823 (class 1259 OID 1956070)
-- Name: lendenapp_user_gst_202908_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202908_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202908 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8826 (class 1259 OID 1955887)
-- Name: lendenapp_user_gst_202909_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202909_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202909 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8827 (class 1259 OID 1956071)
-- Name: lendenapp_user_gst_202909_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202909_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202909 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8830 (class 1259 OID 1955888)
-- Name: lendenapp_user_gst_202910_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202910_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202910 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8831 (class 1259 OID 1956072)
-- Name: lendenapp_user_gst_202910_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202910_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202910 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8834 (class 1259 OID 1955889)
-- Name: lendenapp_user_gst_202911_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202911_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202911 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8835 (class 1259 OID 1956073)
-- Name: lendenapp_user_gst_202911_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202911_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202911 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8838 (class 1259 OID 1955890)
-- Name: lendenapp_user_gst_202912_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202912_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_202912 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8839 (class 1259 OID 1956074)
-- Name: lendenapp_user_gst_202912_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_202912_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_202912 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8842 (class 1259 OID 1955891)
-- Name: lendenapp_user_gst_203001_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203001_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203001 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8843 (class 1259 OID 1956075)
-- Name: lendenapp_user_gst_203001_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203001_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203001 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8846 (class 1259 OID 1955892)
-- Name: lendenapp_user_gst_203002_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203002_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203002 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8847 (class 1259 OID 1956076)
-- Name: lendenapp_user_gst_203002_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203002_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203002 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8850 (class 1259 OID 1955893)
-- Name: lendenapp_user_gst_203003_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203003_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203003 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8851 (class 1259 OID 1956077)
-- Name: lendenapp_user_gst_203003_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203003_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203003 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8854 (class 1259 OID 1955894)
-- Name: lendenapp_user_gst_203004_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203004_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203004 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8855 (class 1259 OID 1956078)
-- Name: lendenapp_user_gst_203004_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203004_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203004 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8858 (class 1259 OID 1955895)
-- Name: lendenapp_user_gst_203005_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203005_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203005 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8859 (class 1259 OID 1956079)
-- Name: lendenapp_user_gst_203005_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203005_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203005 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8862 (class 1259 OID 1955896)
-- Name: lendenapp_user_gst_203006_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203006_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203006 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8863 (class 1259 OID 1956080)
-- Name: lendenapp_user_gst_203006_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203006_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203006 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8866 (class 1259 OID 1955897)
-- Name: lendenapp_user_gst_203007_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203007_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203007 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8867 (class 1259 OID 1956081)
-- Name: lendenapp_user_gst_203007_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203007_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203007 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8870 (class 1259 OID 1955898)
-- Name: lendenapp_user_gst_203008_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203008_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203008 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8871 (class 1259 OID 1956082)
-- Name: lendenapp_user_gst_203008_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203008_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203008 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8874 (class 1259 OID 1955899)
-- Name: lendenapp_user_gst_203009_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203009_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203009 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8875 (class 1259 OID 1956083)
-- Name: lendenapp_user_gst_203009_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203009_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203009 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8878 (class 1259 OID 1955900)
-- Name: lendenapp_user_gst_203010_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203010_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203010 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8879 (class 1259 OID 1956084)
-- Name: lendenapp_user_gst_203010_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203010_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203010 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8882 (class 1259 OID 1955901)
-- Name: lendenapp_user_gst_203011_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203011_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203011 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8883 (class 1259 OID 1956085)
-- Name: lendenapp_user_gst_203011_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203011_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203011 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8886 (class 1259 OID 1955902)
-- Name: lendenapp_user_gst_203012_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203012_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203012 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8887 (class 1259 OID 1956086)
-- Name: lendenapp_user_gst_203012_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203012_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203012 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8890 (class 1259 OID 1955903)
-- Name: lendenapp_user_gst_203101_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203101_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203101 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8891 (class 1259 OID 1956087)
-- Name: lendenapp_user_gst_203101_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203101_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203101 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8894 (class 1259 OID 1955904)
-- Name: lendenapp_user_gst_203102_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203102_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203102 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8895 (class 1259 OID 1956088)
-- Name: lendenapp_user_gst_203102_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203102_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203102 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8898 (class 1259 OID 1955905)
-- Name: lendenapp_user_gst_203103_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203103_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203103 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8899 (class 1259 OID 1956089)
-- Name: lendenapp_user_gst_203103_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203103_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203103 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8902 (class 1259 OID 1955906)
-- Name: lendenapp_user_gst_203104_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203104_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203104 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8903 (class 1259 OID 1956090)
-- Name: lendenapp_user_gst_203104_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203104_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203104 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8906 (class 1259 OID 1955907)
-- Name: lendenapp_user_gst_203105_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203105_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203105 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8907 (class 1259 OID 1956091)
-- Name: lendenapp_user_gst_203105_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203105_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203105 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8910 (class 1259 OID 1955908)
-- Name: lendenapp_user_gst_203106_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203106_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203106 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8911 (class 1259 OID 1956092)
-- Name: lendenapp_user_gst_203106_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203106_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203106 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8914 (class 1259 OID 1955909)
-- Name: lendenapp_user_gst_203107_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203107_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203107 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8915 (class 1259 OID 1956093)
-- Name: lendenapp_user_gst_203107_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203107_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203107 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8918 (class 1259 OID 1955910)
-- Name: lendenapp_user_gst_203108_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203108_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203108 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8919 (class 1259 OID 1956094)
-- Name: lendenapp_user_gst_203108_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203108_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203108 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8922 (class 1259 OID 1955911)
-- Name: lendenapp_user_gst_203109_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203109_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203109 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8923 (class 1259 OID 1956095)
-- Name: lendenapp_user_gst_203109_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203109_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203109 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8926 (class 1259 OID 1955912)
-- Name: lendenapp_user_gst_203110_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203110_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203110 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8927 (class 1259 OID 1956096)
-- Name: lendenapp_user_gst_203110_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203110_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203110 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8930 (class 1259 OID 1955913)
-- Name: lendenapp_user_gst_203111_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203111_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203111 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8931 (class 1259 OID 1956097)
-- Name: lendenapp_user_gst_203111_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203111_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203111 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8934 (class 1259 OID 1955914)
-- Name: lendenapp_user_gst_203112_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203112_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203112 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8935 (class 1259 OID 1956098)
-- Name: lendenapp_user_gst_203112_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203112_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203112 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8938 (class 1259 OID 1955915)
-- Name: lendenapp_user_gst_203201_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203201_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203201 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8939 (class 1259 OID 1956099)
-- Name: lendenapp_user_gst_203201_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203201_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203201 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8942 (class 1259 OID 1955916)
-- Name: lendenapp_user_gst_203202_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203202_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203202 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8943 (class 1259 OID 1956100)
-- Name: lendenapp_user_gst_203202_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203202_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203202 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8946 (class 1259 OID 1955917)
-- Name: lendenapp_user_gst_203203_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203203_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203203 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8947 (class 1259 OID 1956101)
-- Name: lendenapp_user_gst_203203_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203203_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203203 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8950 (class 1259 OID 1955918)
-- Name: lendenapp_user_gst_203204_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203204_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203204 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8951 (class 1259 OID 1956102)
-- Name: lendenapp_user_gst_203204_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203204_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203204 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8954 (class 1259 OID 1955919)
-- Name: lendenapp_user_gst_203205_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203205_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203205 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8955 (class 1259 OID 1956103)
-- Name: lendenapp_user_gst_203205_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203205_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203205 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8958 (class 1259 OID 1955920)
-- Name: lendenapp_user_gst_203206_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203206_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203206 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8959 (class 1259 OID 1956104)
-- Name: lendenapp_user_gst_203206_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203206_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203206 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8962 (class 1259 OID 1955921)
-- Name: lendenapp_user_gst_203207_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203207_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203207 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8963 (class 1259 OID 1956105)
-- Name: lendenapp_user_gst_203207_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203207_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203207 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8966 (class 1259 OID 1955922)
-- Name: lendenapp_user_gst_203208_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203208_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203208 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8967 (class 1259 OID 1956106)
-- Name: lendenapp_user_gst_203208_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203208_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203208 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8970 (class 1259 OID 1955923)
-- Name: lendenapp_user_gst_203209_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203209_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203209 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8971 (class 1259 OID 1956107)
-- Name: lendenapp_user_gst_203209_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203209_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203209 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8974 (class 1259 OID 1955924)
-- Name: lendenapp_user_gst_203210_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203210_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203210 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8975 (class 1259 OID 1956108)
-- Name: lendenapp_user_gst_203210_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203210_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203210 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8978 (class 1259 OID 1955925)
-- Name: lendenapp_user_gst_203211_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203211_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203211 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8979 (class 1259 OID 1956109)
-- Name: lendenapp_user_gst_203211_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203211_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203211 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8982 (class 1259 OID 1955926)
-- Name: lendenapp_user_gst_203212_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203212_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203212 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8983 (class 1259 OID 1956110)
-- Name: lendenapp_user_gst_203212_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203212_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203212 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8986 (class 1259 OID 1955927)
-- Name: lendenapp_user_gst_203301_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203301_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203301 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8987 (class 1259 OID 1956111)
-- Name: lendenapp_user_gst_203301_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203301_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203301 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8990 (class 1259 OID 1955928)
-- Name: lendenapp_user_gst_203302_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203302_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203302 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8991 (class 1259 OID 1956112)
-- Name: lendenapp_user_gst_203302_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203302_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203302 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8994 (class 1259 OID 1955929)
-- Name: lendenapp_user_gst_203303_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203303_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203303 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8995 (class 1259 OID 1956113)
-- Name: lendenapp_user_gst_203303_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203303_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203303 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8998 (class 1259 OID 1955930)
-- Name: lendenapp_user_gst_203304_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203304_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203304 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 8999 (class 1259 OID 1956114)
-- Name: lendenapp_user_gst_203304_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203304_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203304 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9002 (class 1259 OID 1955931)
-- Name: lendenapp_user_gst_203305_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203305_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203305 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9003 (class 1259 OID 1956115)
-- Name: lendenapp_user_gst_203305_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203305_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203305 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9006 (class 1259 OID 1955932)
-- Name: lendenapp_user_gst_203306_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203306_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203306 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9007 (class 1259 OID 1956116)
-- Name: lendenapp_user_gst_203306_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203306_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203306 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9010 (class 1259 OID 1955933)
-- Name: lendenapp_user_gst_203307_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203307_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203307 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9011 (class 1259 OID 1956117)
-- Name: lendenapp_user_gst_203307_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203307_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203307 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9014 (class 1259 OID 1955934)
-- Name: lendenapp_user_gst_203308_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203308_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203308 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9015 (class 1259 OID 1956118)
-- Name: lendenapp_user_gst_203308_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203308_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203308 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9018 (class 1259 OID 1955935)
-- Name: lendenapp_user_gst_203309_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203309_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203309 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9019 (class 1259 OID 1956119)
-- Name: lendenapp_user_gst_203309_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203309_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203309 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9022 (class 1259 OID 1955936)
-- Name: lendenapp_user_gst_203310_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203310_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203310 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9023 (class 1259 OID 1956120)
-- Name: lendenapp_user_gst_203310_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203310_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203310 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9026 (class 1259 OID 1955937)
-- Name: lendenapp_user_gst_203311_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203311_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203311 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9027 (class 1259 OID 1956121)
-- Name: lendenapp_user_gst_203311_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203311_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203311 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9030 (class 1259 OID 1955938)
-- Name: lendenapp_user_gst_203312_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203312_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203312 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9031 (class 1259 OID 1956122)
-- Name: lendenapp_user_gst_203312_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203312_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203312 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9034 (class 1259 OID 1955939)
-- Name: lendenapp_user_gst_203401_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203401_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203401 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9035 (class 1259 OID 1956123)
-- Name: lendenapp_user_gst_203401_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203401_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203401 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9038 (class 1259 OID 1955940)
-- Name: lendenapp_user_gst_203402_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203402_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203402 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9039 (class 1259 OID 1956124)
-- Name: lendenapp_user_gst_203402_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203402_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203402 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9042 (class 1259 OID 1955941)
-- Name: lendenapp_user_gst_203403_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203403_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203403 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9043 (class 1259 OID 1956125)
-- Name: lendenapp_user_gst_203403_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203403_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203403 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9046 (class 1259 OID 1955942)
-- Name: lendenapp_user_gst_203404_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203404_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203404 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9047 (class 1259 OID 1956126)
-- Name: lendenapp_user_gst_203404_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203404_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203404 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9050 (class 1259 OID 1955943)
-- Name: lendenapp_user_gst_203405_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203405_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203405 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9051 (class 1259 OID 1956127)
-- Name: lendenapp_user_gst_203405_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203405_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203405 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9054 (class 1259 OID 1955944)
-- Name: lendenapp_user_gst_203406_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203406_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203406 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9055 (class 1259 OID 1956128)
-- Name: lendenapp_user_gst_203406_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203406_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203406 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9058 (class 1259 OID 1955945)
-- Name: lendenapp_user_gst_203407_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203407_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203407 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9059 (class 1259 OID 1956129)
-- Name: lendenapp_user_gst_203407_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203407_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203407 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9062 (class 1259 OID 1955946)
-- Name: lendenapp_user_gst_203408_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203408_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203408 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9063 (class 1259 OID 1956130)
-- Name: lendenapp_user_gst_203408_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203408_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203408 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9066 (class 1259 OID 1955947)
-- Name: lendenapp_user_gst_203409_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203409_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203409 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9067 (class 1259 OID 1956131)
-- Name: lendenapp_user_gst_203409_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203409_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203409 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9070 (class 1259 OID 1955948)
-- Name: lendenapp_user_gst_203410_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203410_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203410 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9071 (class 1259 OID 1956132)
-- Name: lendenapp_user_gst_203410_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203410_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203410 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9074 (class 1259 OID 1955949)
-- Name: lendenapp_user_gst_203411_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203411_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203411 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9075 (class 1259 OID 1956133)
-- Name: lendenapp_user_gst_203411_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203411_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203411 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9078 (class 1259 OID 1955950)
-- Name: lendenapp_user_gst_203412_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203412_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203412 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9079 (class 1259 OID 1956134)
-- Name: lendenapp_user_gst_203412_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203412_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203412 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9082 (class 1259 OID 1955951)
-- Name: lendenapp_user_gst_203501_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203501_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203501 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9083 (class 1259 OID 1956135)
-- Name: lendenapp_user_gst_203501_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203501_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203501 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9086 (class 1259 OID 1955952)
-- Name: lendenapp_user_gst_203502_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203502_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203502 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9087 (class 1259 OID 1956136)
-- Name: lendenapp_user_gst_203502_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203502_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203502 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9090 (class 1259 OID 1955953)
-- Name: lendenapp_user_gst_203503_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203503_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203503 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9091 (class 1259 OID 1956137)
-- Name: lendenapp_user_gst_203503_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203503_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203503 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9094 (class 1259 OID 1955954)
-- Name: lendenapp_user_gst_203504_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203504_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203504 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9095 (class 1259 OID 1956138)
-- Name: lendenapp_user_gst_203504_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203504_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203504 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9098 (class 1259 OID 1955955)
-- Name: lendenapp_user_gst_203505_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203505_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203505 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9099 (class 1259 OID 1956139)
-- Name: lendenapp_user_gst_203505_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203505_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203505 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9102 (class 1259 OID 1955956)
-- Name: lendenapp_user_gst_203506_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203506_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203506 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9103 (class 1259 OID 1956140)
-- Name: lendenapp_user_gst_203506_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203506_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203506 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9106 (class 1259 OID 1955957)
-- Name: lendenapp_user_gst_203507_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203507_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203507 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9107 (class 1259 OID 1956141)
-- Name: lendenapp_user_gst_203507_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203507_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203507 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9110 (class 1259 OID 1955958)
-- Name: lendenapp_user_gst_203508_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203508_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203508 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9111 (class 1259 OID 1956142)
-- Name: lendenapp_user_gst_203508_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203508_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203508 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9114 (class 1259 OID 1955959)
-- Name: lendenapp_user_gst_203509_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203509_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203509 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9115 (class 1259 OID 1956143)
-- Name: lendenapp_user_gst_203509_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203509_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203509 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9118 (class 1259 OID 1955960)
-- Name: lendenapp_user_gst_203510_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203510_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203510 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9119 (class 1259 OID 1956144)
-- Name: lendenapp_user_gst_203510_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203510_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203510 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9122 (class 1259 OID 1955961)
-- Name: lendenapp_user_gst_203511_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203511_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203511 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9123 (class 1259 OID 1956145)
-- Name: lendenapp_user_gst_203511_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203511_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203511 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9126 (class 1259 OID 1955962)
-- Name: lendenapp_user_gst_203512_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203512_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203512 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9127 (class 1259 OID 1956146)
-- Name: lendenapp_user_gst_203512_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203512_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203512 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9130 (class 1259 OID 1955963)
-- Name: lendenapp_user_gst_203601_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203601_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203601 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9131 (class 1259 OID 1956147)
-- Name: lendenapp_user_gst_203601_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203601_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203601 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9134 (class 1259 OID 1955964)
-- Name: lendenapp_user_gst_203602_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203602_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203602 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9135 (class 1259 OID 1956148)
-- Name: lendenapp_user_gst_203602_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203602_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203602 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9138 (class 1259 OID 1955965)
-- Name: lendenapp_user_gst_203603_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203603_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203603 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9139 (class 1259 OID 1956149)
-- Name: lendenapp_user_gst_203603_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203603_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203603 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9142 (class 1259 OID 1955966)
-- Name: lendenapp_user_gst_203604_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203604_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203604 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9143 (class 1259 OID 1956150)
-- Name: lendenapp_user_gst_203604_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203604_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203604 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9146 (class 1259 OID 1955967)
-- Name: lendenapp_user_gst_203605_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203605_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203605 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9147 (class 1259 OID 1956151)
-- Name: lendenapp_user_gst_203605_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203605_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203605 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9150 (class 1259 OID 1955968)
-- Name: lendenapp_user_gst_203606_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203606_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203606 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9151 (class 1259 OID 1956152)
-- Name: lendenapp_user_gst_203606_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203606_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203606 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9154 (class 1259 OID 1955969)
-- Name: lendenapp_user_gst_203607_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203607_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203607 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9155 (class 1259 OID 1956153)
-- Name: lendenapp_user_gst_203607_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203607_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203607 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9158 (class 1259 OID 1955970)
-- Name: lendenapp_user_gst_203608_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203608_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203608 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9159 (class 1259 OID 1956154)
-- Name: lendenapp_user_gst_203608_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203608_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203608 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9162 (class 1259 OID 1955971)
-- Name: lendenapp_user_gst_203609_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203609_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203609 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9163 (class 1259 OID 1956155)
-- Name: lendenapp_user_gst_203609_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203609_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203609 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9166 (class 1259 OID 1955972)
-- Name: lendenapp_user_gst_203610_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203610_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203610 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9167 (class 1259 OID 1956156)
-- Name: lendenapp_user_gst_203610_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203610_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203610 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9170 (class 1259 OID 1955973)
-- Name: lendenapp_user_gst_203611_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203611_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203611 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9171 (class 1259 OID 1956157)
-- Name: lendenapp_user_gst_203611_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203611_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203611 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9174 (class 1259 OID 1955974)
-- Name: lendenapp_user_gst_203612_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203612_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203612 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9175 (class 1259 OID 1956158)
-- Name: lendenapp_user_gst_203612_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203612_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203612 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9178 (class 1259 OID 1955975)
-- Name: lendenapp_user_gst_203701_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203701_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203701 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9179 (class 1259 OID 1956159)
-- Name: lendenapp_user_gst_203701_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203701_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203701 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9182 (class 1259 OID 1955976)
-- Name: lendenapp_user_gst_203702_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203702_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203702 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9183 (class 1259 OID 1956160)
-- Name: lendenapp_user_gst_203702_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203702_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203702 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9186 (class 1259 OID 1955977)
-- Name: lendenapp_user_gst_203703_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203703_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203703 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9187 (class 1259 OID 1956161)
-- Name: lendenapp_user_gst_203703_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203703_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203703 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9190 (class 1259 OID 1955978)
-- Name: lendenapp_user_gst_203704_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203704_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203704 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9191 (class 1259 OID 1956162)
-- Name: lendenapp_user_gst_203704_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203704_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203704 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9194 (class 1259 OID 1955979)
-- Name: lendenapp_user_gst_203705_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203705_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203705 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9195 (class 1259 OID 1956163)
-- Name: lendenapp_user_gst_203705_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203705_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203705 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9198 (class 1259 OID 1955980)
-- Name: lendenapp_user_gst_203706_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203706_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203706 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9199 (class 1259 OID 1956164)
-- Name: lendenapp_user_gst_203706_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203706_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203706 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9202 (class 1259 OID 1955981)
-- Name: lendenapp_user_gst_203707_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203707_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203707 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9203 (class 1259 OID 1956165)
-- Name: lendenapp_user_gst_203707_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203707_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203707 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9206 (class 1259 OID 1955982)
-- Name: lendenapp_user_gst_203708_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203708_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203708 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9207 (class 1259 OID 1956166)
-- Name: lendenapp_user_gst_203708_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203708_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203708 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9210 (class 1259 OID 1955983)
-- Name: lendenapp_user_gst_203709_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203709_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203709 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9211 (class 1259 OID 1956167)
-- Name: lendenapp_user_gst_203709_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203709_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203709 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9214 (class 1259 OID 1955984)
-- Name: lendenapp_user_gst_203710_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203710_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203710 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9215 (class 1259 OID 1956168)
-- Name: lendenapp_user_gst_203710_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203710_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203710 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9218 (class 1259 OID 1955985)
-- Name: lendenapp_user_gst_203711_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203711_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203711 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9219 (class 1259 OID 1956169)
-- Name: lendenapp_user_gst_203711_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203711_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203711 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9222 (class 1259 OID 1955986)
-- Name: lendenapp_user_gst_203712_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203712_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203712 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9223 (class 1259 OID 1956170)
-- Name: lendenapp_user_gst_203712_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203712_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203712 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9226 (class 1259 OID 1955987)
-- Name: lendenapp_user_gst_203801_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203801_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203801 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9227 (class 1259 OID 1956171)
-- Name: lendenapp_user_gst_203801_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203801_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203801 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9230 (class 1259 OID 1955988)
-- Name: lendenapp_user_gst_203802_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203802_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203802 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9231 (class 1259 OID 1956172)
-- Name: lendenapp_user_gst_203802_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203802_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203802 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9234 (class 1259 OID 1955989)
-- Name: lendenapp_user_gst_203803_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203803_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203803 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9235 (class 1259 OID 1956173)
-- Name: lendenapp_user_gst_203803_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203803_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203803 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9238 (class 1259 OID 1955990)
-- Name: lendenapp_user_gst_203804_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203804_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203804 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9239 (class 1259 OID 1956174)
-- Name: lendenapp_user_gst_203804_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203804_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203804 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9242 (class 1259 OID 1955991)
-- Name: lendenapp_user_gst_203805_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203805_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203805 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9243 (class 1259 OID 1956175)
-- Name: lendenapp_user_gst_203805_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203805_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203805 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9246 (class 1259 OID 1955992)
-- Name: lendenapp_user_gst_203806_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203806_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203806 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9247 (class 1259 OID 1956176)
-- Name: lendenapp_user_gst_203806_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203806_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203806 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9250 (class 1259 OID 1955993)
-- Name: lendenapp_user_gst_203807_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203807_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203807 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9251 (class 1259 OID 1956177)
-- Name: lendenapp_user_gst_203807_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203807_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203807 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9254 (class 1259 OID 1955994)
-- Name: lendenapp_user_gst_203808_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203808_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203808 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9255 (class 1259 OID 1956178)
-- Name: lendenapp_user_gst_203808_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203808_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203808 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9258 (class 1259 OID 1955995)
-- Name: lendenapp_user_gst_203809_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203809_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203809 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9259 (class 1259 OID 1956179)
-- Name: lendenapp_user_gst_203809_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203809_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203809 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9262 (class 1259 OID 1955996)
-- Name: lendenapp_user_gst_203810_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203810_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203810 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9263 (class 1259 OID 1956180)
-- Name: lendenapp_user_gst_203810_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203810_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203810 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9266 (class 1259 OID 1955997)
-- Name: lendenapp_user_gst_203811_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203811_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203811 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9267 (class 1259 OID 1956181)
-- Name: lendenapp_user_gst_203811_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203811_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203811 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9270 (class 1259 OID 1955998)
-- Name: lendenapp_user_gst_203812_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203812_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203812 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9271 (class 1259 OID 1956182)
-- Name: lendenapp_user_gst_203812_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203812_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203812 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9274 (class 1259 OID 1955999)
-- Name: lendenapp_user_gst_203901_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203901_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203901 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9275 (class 1259 OID 1956183)
-- Name: lendenapp_user_gst_203901_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203901_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203901 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9278 (class 1259 OID 1956000)
-- Name: lendenapp_user_gst_203902_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203902_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203902 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9279 (class 1259 OID 1956184)
-- Name: lendenapp_user_gst_203902_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203902_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203902 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9282 (class 1259 OID 1956001)
-- Name: lendenapp_user_gst_203903_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203903_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203903 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9283 (class 1259 OID 1956185)
-- Name: lendenapp_user_gst_203903_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203903_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203903 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9286 (class 1259 OID 1956002)
-- Name: lendenapp_user_gst_203904_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203904_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203904 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9287 (class 1259 OID 1956186)
-- Name: lendenapp_user_gst_203904_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203904_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203904 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9290 (class 1259 OID 1956003)
-- Name: lendenapp_user_gst_203905_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203905_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203905 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9291 (class 1259 OID 1956187)
-- Name: lendenapp_user_gst_203905_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203905_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203905 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9294 (class 1259 OID 1956004)
-- Name: lendenapp_user_gst_203906_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203906_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203906 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9295 (class 1259 OID 1956188)
-- Name: lendenapp_user_gst_203906_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203906_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203906 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9298 (class 1259 OID 1956005)
-- Name: lendenapp_user_gst_203907_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203907_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203907 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9299 (class 1259 OID 1956189)
-- Name: lendenapp_user_gst_203907_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203907_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203907 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9302 (class 1259 OID 1956006)
-- Name: lendenapp_user_gst_203908_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203908_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203908 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9303 (class 1259 OID 1956190)
-- Name: lendenapp_user_gst_203908_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203908_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203908 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9306 (class 1259 OID 1956007)
-- Name: lendenapp_user_gst_203909_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203909_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203909 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9307 (class 1259 OID 1956191)
-- Name: lendenapp_user_gst_203909_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203909_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203909 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9310 (class 1259 OID 1956008)
-- Name: lendenapp_user_gst_203910_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203910_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203910 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9311 (class 1259 OID 1956192)
-- Name: lendenapp_user_gst_203910_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203910_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203910 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9314 (class 1259 OID 1956009)
-- Name: lendenapp_user_gst_203911_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203911_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203911 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9315 (class 1259 OID 1956193)
-- Name: lendenapp_user_gst_203911_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203911_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203911 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9318 (class 1259 OID 1956010)
-- Name: lendenapp_user_gst_203912_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203912_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_203912 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9319 (class 1259 OID 1956194)
-- Name: lendenapp_user_gst_203912_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_203912_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_203912 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9322 (class 1259 OID 1956011)
-- Name: lendenapp_user_gst_204001_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_204001_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_204001 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9323 (class 1259 OID 1956195)
-- Name: lendenapp_user_gst_204001_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_204001_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_204001 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9326 (class 1259 OID 1956012)
-- Name: lendenapp_user_gst_204002_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_204002_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_204002 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9327 (class 1259 OID 1956196)
-- Name: lendenapp_user_gst_204002_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_204002_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_204002 USING btree (user_id, in_invoice_date);


--
-- TOC entry 9330 (class 1259 OID 1956013)
-- Name: lendenapp_user_gst_204003_user_id_ci_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_204003_user_id_ci_invoice_date_idx ON public.lendenapp_user_gst_204003 USING btree (user_id, ci_invoice_date);


--
-- TOC entry 9331 (class 1259 OID 1956197)
-- Name: lendenapp_user_gst_204003_user_id_in_invoice_date_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX lendenapp_user_gst_204003_user_id_in_invoice_date_idx ON public.lendenapp_user_gst_204003 USING btree (user_id, in_invoice_date);


--
-- TOC entry 8434 (class 1259 OID 1078967)
-- Name: lendenapp_user_source_group_tracker; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX lendenapp_user_source_group_tracker ON public.lendenapp_mandatetracker USING btree (user_source_group_id);


--
-- TOC entry 8358 (class 1259 OID 1244437)
-- Name: lendenapp_userconsentlog_consent_type_idx; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX lendenapp_userconsentlog_consent_type_idx ON public.lendenapp_userconsentlog USING btree (consent_type);


--
-- TOC entry 8361 (class 1259 OID 1244438)
-- Name: lendenapp_userconsentlog_user_source_group_id_idx; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX lendenapp_userconsentlog_user_source_group_id_idx ON public.lendenapp_userconsentlog USING btree (user_source_group_id);


--
-- TOC entry 8464 (class 1259 OID 1310052)
-- Name: scheme_reinvestment_idx; Type: INDEX; Schema: public; Owner: devmultilenden
--

CREATE INDEX scheme_reinvestment_idx ON public.lendenapp_scheme_repayment_details USING btree (scheme_reinvestment_id);


--
-- TOC entry 8424 (class 1259 OID 1078850)
-- Name: user_source_group_id_temp_idx; Type: INDEX; Schema: public; Owner: usrinvoswrt
--

CREATE INDEX user_source_group_id_temp_idx ON public.lendenapp_transaction_repayment_temp USING btree (user_source_group_id);


--
-- TOC entry 9336 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202501_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202501_pkey;


--
-- TOC entry 9337 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202502_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202502_pkey;


--
-- TOC entry 9338 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202503_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202503_pkey;


--
-- TOC entry 9339 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202504_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202504_pkey;


--
-- TOC entry 9340 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202505_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202505_pkey;


--
-- TOC entry 9341 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202506_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202506_pkey;


--
-- TOC entry 9342 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202507_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202507_pkey;


--
-- TOC entry 9343 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202508_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202508_pkey;


--
-- TOC entry 9344 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202509_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202509_pkey;


--
-- TOC entry 9345 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202510_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202510_pkey;


--
-- TOC entry 9346 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202511_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202511_pkey;


--
-- TOC entry 9347 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202512_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202512_pkey;


--
-- TOC entry 9348 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202601_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202601_pkey;


--
-- TOC entry 9349 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202602_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202602_pkey;


--
-- TOC entry 9350 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202603_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202603_pkey;


--
-- TOC entry 9351 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202604_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202604_pkey;


--
-- TOC entry 9352 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202605_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202605_pkey;


--
-- TOC entry 9353 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202606_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202606_pkey;


--
-- TOC entry 9354 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202607_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202607_pkey;


--
-- TOC entry 9355 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202608_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202608_pkey;


--
-- TOC entry 9356 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202609_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202609_pkey;


--
-- TOC entry 9357 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202610_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202610_pkey;


--
-- TOC entry 9358 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202611_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202611_pkey;


--
-- TOC entry 9359 (class 0 OID 0)
-- Name: lendenapp_otl_scheme_loan_mapping_202612_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_otl_scheme_loan_mapping_pkey ATTACH PARTITION public.lendenapp_otl_scheme_loan_mapping_202612_pkey;


--
-- TOC entry 9360 (class 0 OID 0)
-- Name: lendenapp_user_gst_202503_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202503_pkey;


--
-- TOC entry 9361 (class 0 OID 0)
-- Name: lendenapp_user_gst_202503_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202503_user_id_ci_invoice_date_idx;


--
-- TOC entry 9362 (class 0 OID 0)
-- Name: lendenapp_user_gst_202503_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202503_user_id_in_invoice_date_idx;


--
-- TOC entry 9363 (class 0 OID 0)
-- Name: lendenapp_user_gst_202504_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202504_pkey;


--
-- TOC entry 9364 (class 0 OID 0)
-- Name: lendenapp_user_gst_202504_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202504_user_id_ci_invoice_date_idx;


--
-- TOC entry 9365 (class 0 OID 0)
-- Name: lendenapp_user_gst_202504_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202504_user_id_in_invoice_date_idx;


--
-- TOC entry 9366 (class 0 OID 0)
-- Name: lendenapp_user_gst_202505_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202505_pkey;


--
-- TOC entry 9367 (class 0 OID 0)
-- Name: lendenapp_user_gst_202505_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202505_user_id_ci_invoice_date_idx;


--
-- TOC entry 9368 (class 0 OID 0)
-- Name: lendenapp_user_gst_202505_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202505_user_id_in_invoice_date_idx;


--
-- TOC entry 9369 (class 0 OID 0)
-- Name: lendenapp_user_gst_202506_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202506_pkey;


--
-- TOC entry 9370 (class 0 OID 0)
-- Name: lendenapp_user_gst_202506_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202506_user_id_ci_invoice_date_idx;


--
-- TOC entry 9371 (class 0 OID 0)
-- Name: lendenapp_user_gst_202506_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202506_user_id_in_invoice_date_idx;


--
-- TOC entry 9372 (class 0 OID 0)
-- Name: lendenapp_user_gst_202507_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202507_pkey;


--
-- TOC entry 9373 (class 0 OID 0)
-- Name: lendenapp_user_gst_202507_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202507_user_id_ci_invoice_date_idx;


--
-- TOC entry 9374 (class 0 OID 0)
-- Name: lendenapp_user_gst_202507_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202507_user_id_in_invoice_date_idx;


--
-- TOC entry 9375 (class 0 OID 0)
-- Name: lendenapp_user_gst_202508_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202508_pkey;


--
-- TOC entry 9376 (class 0 OID 0)
-- Name: lendenapp_user_gst_202508_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202508_user_id_ci_invoice_date_idx;


--
-- TOC entry 9377 (class 0 OID 0)
-- Name: lendenapp_user_gst_202508_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202508_user_id_in_invoice_date_idx;


--
-- TOC entry 9378 (class 0 OID 0)
-- Name: lendenapp_user_gst_202509_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202509_pkey;


--
-- TOC entry 9379 (class 0 OID 0)
-- Name: lendenapp_user_gst_202509_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202509_user_id_ci_invoice_date_idx;


--
-- TOC entry 9380 (class 0 OID 0)
-- Name: lendenapp_user_gst_202509_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202509_user_id_in_invoice_date_idx;


--
-- TOC entry 9381 (class 0 OID 0)
-- Name: lendenapp_user_gst_202510_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202510_pkey;


--
-- TOC entry 9382 (class 0 OID 0)
-- Name: lendenapp_user_gst_202510_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202510_user_id_ci_invoice_date_idx;


--
-- TOC entry 9383 (class 0 OID 0)
-- Name: lendenapp_user_gst_202510_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202510_user_id_in_invoice_date_idx;


--
-- TOC entry 9384 (class 0 OID 0)
-- Name: lendenapp_user_gst_202511_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202511_pkey;


--
-- TOC entry 9385 (class 0 OID 0)
-- Name: lendenapp_user_gst_202511_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202511_user_id_ci_invoice_date_idx;


--
-- TOC entry 9386 (class 0 OID 0)
-- Name: lendenapp_user_gst_202511_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202511_user_id_in_invoice_date_idx;


--
-- TOC entry 9387 (class 0 OID 0)
-- Name: lendenapp_user_gst_202512_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202512_pkey;


--
-- TOC entry 9388 (class 0 OID 0)
-- Name: lendenapp_user_gst_202512_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202512_user_id_ci_invoice_date_idx;


--
-- TOC entry 9389 (class 0 OID 0)
-- Name: lendenapp_user_gst_202512_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202512_user_id_in_invoice_date_idx;


--
-- TOC entry 9390 (class 0 OID 0)
-- Name: lendenapp_user_gst_202601_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202601_pkey;


--
-- TOC entry 9391 (class 0 OID 0)
-- Name: lendenapp_user_gst_202601_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202601_user_id_ci_invoice_date_idx;


--
-- TOC entry 9392 (class 0 OID 0)
-- Name: lendenapp_user_gst_202601_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202601_user_id_in_invoice_date_idx;


--
-- TOC entry 9393 (class 0 OID 0)
-- Name: lendenapp_user_gst_202602_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202602_pkey;


--
-- TOC entry 9394 (class 0 OID 0)
-- Name: lendenapp_user_gst_202602_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202602_user_id_ci_invoice_date_idx;


--
-- TOC entry 9395 (class 0 OID 0)
-- Name: lendenapp_user_gst_202602_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202602_user_id_in_invoice_date_idx;


--
-- TOC entry 9396 (class 0 OID 0)
-- Name: lendenapp_user_gst_202603_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202603_pkey;


--
-- TOC entry 9397 (class 0 OID 0)
-- Name: lendenapp_user_gst_202603_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202603_user_id_ci_invoice_date_idx;


--
-- TOC entry 9398 (class 0 OID 0)
-- Name: lendenapp_user_gst_202603_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202603_user_id_in_invoice_date_idx;


--
-- TOC entry 9399 (class 0 OID 0)
-- Name: lendenapp_user_gst_202604_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202604_pkey;


--
-- TOC entry 9400 (class 0 OID 0)
-- Name: lendenapp_user_gst_202604_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202604_user_id_ci_invoice_date_idx;


--
-- TOC entry 9401 (class 0 OID 0)
-- Name: lendenapp_user_gst_202604_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202604_user_id_in_invoice_date_idx;


--
-- TOC entry 9402 (class 0 OID 0)
-- Name: lendenapp_user_gst_202605_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202605_pkey;


--
-- TOC entry 9403 (class 0 OID 0)
-- Name: lendenapp_user_gst_202605_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202605_user_id_ci_invoice_date_idx;


--
-- TOC entry 9404 (class 0 OID 0)
-- Name: lendenapp_user_gst_202605_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202605_user_id_in_invoice_date_idx;


--
-- TOC entry 9405 (class 0 OID 0)
-- Name: lendenapp_user_gst_202606_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202606_pkey;


--
-- TOC entry 9406 (class 0 OID 0)
-- Name: lendenapp_user_gst_202606_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202606_user_id_ci_invoice_date_idx;


--
-- TOC entry 9407 (class 0 OID 0)
-- Name: lendenapp_user_gst_202606_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202606_user_id_in_invoice_date_idx;


--
-- TOC entry 9408 (class 0 OID 0)
-- Name: lendenapp_user_gst_202607_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202607_pkey;


--
-- TOC entry 9409 (class 0 OID 0)
-- Name: lendenapp_user_gst_202607_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202607_user_id_ci_invoice_date_idx;


--
-- TOC entry 9410 (class 0 OID 0)
-- Name: lendenapp_user_gst_202607_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202607_user_id_in_invoice_date_idx;


--
-- TOC entry 9411 (class 0 OID 0)
-- Name: lendenapp_user_gst_202608_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202608_pkey;


--
-- TOC entry 9412 (class 0 OID 0)
-- Name: lendenapp_user_gst_202608_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202608_user_id_ci_invoice_date_idx;


--
-- TOC entry 9413 (class 0 OID 0)
-- Name: lendenapp_user_gst_202608_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202608_user_id_in_invoice_date_idx;


--
-- TOC entry 9414 (class 0 OID 0)
-- Name: lendenapp_user_gst_202609_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202609_pkey;


--
-- TOC entry 9415 (class 0 OID 0)
-- Name: lendenapp_user_gst_202609_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202609_user_id_ci_invoice_date_idx;


--
-- TOC entry 9416 (class 0 OID 0)
-- Name: lendenapp_user_gst_202609_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202609_user_id_in_invoice_date_idx;


--
-- TOC entry 9417 (class 0 OID 0)
-- Name: lendenapp_user_gst_202610_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202610_pkey;


--
-- TOC entry 9418 (class 0 OID 0)
-- Name: lendenapp_user_gst_202610_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202610_user_id_ci_invoice_date_idx;


--
-- TOC entry 9419 (class 0 OID 0)
-- Name: lendenapp_user_gst_202610_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202610_user_id_in_invoice_date_idx;


--
-- TOC entry 9420 (class 0 OID 0)
-- Name: lendenapp_user_gst_202611_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202611_pkey;


--
-- TOC entry 9421 (class 0 OID 0)
-- Name: lendenapp_user_gst_202611_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202611_user_id_ci_invoice_date_idx;


--
-- TOC entry 9422 (class 0 OID 0)
-- Name: lendenapp_user_gst_202611_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202611_user_id_in_invoice_date_idx;


--
-- TOC entry 9423 (class 0 OID 0)
-- Name: lendenapp_user_gst_202612_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202612_pkey;


--
-- TOC entry 9424 (class 0 OID 0)
-- Name: lendenapp_user_gst_202612_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202612_user_id_ci_invoice_date_idx;


--
-- TOC entry 9425 (class 0 OID 0)
-- Name: lendenapp_user_gst_202612_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202612_user_id_in_invoice_date_idx;


--
-- TOC entry 9426 (class 0 OID 0)
-- Name: lendenapp_user_gst_202701_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202701_pkey;


--
-- TOC entry 9427 (class 0 OID 0)
-- Name: lendenapp_user_gst_202701_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202701_user_id_ci_invoice_date_idx;


--
-- TOC entry 9428 (class 0 OID 0)
-- Name: lendenapp_user_gst_202701_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202701_user_id_in_invoice_date_idx;


--
-- TOC entry 9429 (class 0 OID 0)
-- Name: lendenapp_user_gst_202702_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202702_pkey;


--
-- TOC entry 9430 (class 0 OID 0)
-- Name: lendenapp_user_gst_202702_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202702_user_id_ci_invoice_date_idx;


--
-- TOC entry 9431 (class 0 OID 0)
-- Name: lendenapp_user_gst_202702_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202702_user_id_in_invoice_date_idx;


--
-- TOC entry 9432 (class 0 OID 0)
-- Name: lendenapp_user_gst_202703_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202703_pkey;


--
-- TOC entry 9433 (class 0 OID 0)
-- Name: lendenapp_user_gst_202703_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202703_user_id_ci_invoice_date_idx;


--
-- TOC entry 9434 (class 0 OID 0)
-- Name: lendenapp_user_gst_202703_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202703_user_id_in_invoice_date_idx;


--
-- TOC entry 9435 (class 0 OID 0)
-- Name: lendenapp_user_gst_202704_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202704_pkey;


--
-- TOC entry 9436 (class 0 OID 0)
-- Name: lendenapp_user_gst_202704_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202704_user_id_ci_invoice_date_idx;


--
-- TOC entry 9437 (class 0 OID 0)
-- Name: lendenapp_user_gst_202704_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202704_user_id_in_invoice_date_idx;


--
-- TOC entry 9438 (class 0 OID 0)
-- Name: lendenapp_user_gst_202705_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202705_pkey;


--
-- TOC entry 9439 (class 0 OID 0)
-- Name: lendenapp_user_gst_202705_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202705_user_id_ci_invoice_date_idx;


--
-- TOC entry 9440 (class 0 OID 0)
-- Name: lendenapp_user_gst_202705_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202705_user_id_in_invoice_date_idx;


--
-- TOC entry 9441 (class 0 OID 0)
-- Name: lendenapp_user_gst_202706_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202706_pkey;


--
-- TOC entry 9442 (class 0 OID 0)
-- Name: lendenapp_user_gst_202706_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202706_user_id_ci_invoice_date_idx;


--
-- TOC entry 9443 (class 0 OID 0)
-- Name: lendenapp_user_gst_202706_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202706_user_id_in_invoice_date_idx;


--
-- TOC entry 9444 (class 0 OID 0)
-- Name: lendenapp_user_gst_202707_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202707_pkey;


--
-- TOC entry 9445 (class 0 OID 0)
-- Name: lendenapp_user_gst_202707_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202707_user_id_ci_invoice_date_idx;


--
-- TOC entry 9446 (class 0 OID 0)
-- Name: lendenapp_user_gst_202707_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202707_user_id_in_invoice_date_idx;


--
-- TOC entry 9447 (class 0 OID 0)
-- Name: lendenapp_user_gst_202708_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202708_pkey;


--
-- TOC entry 9448 (class 0 OID 0)
-- Name: lendenapp_user_gst_202708_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202708_user_id_ci_invoice_date_idx;


--
-- TOC entry 9449 (class 0 OID 0)
-- Name: lendenapp_user_gst_202708_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202708_user_id_in_invoice_date_idx;


--
-- TOC entry 9450 (class 0 OID 0)
-- Name: lendenapp_user_gst_202709_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202709_pkey;


--
-- TOC entry 9451 (class 0 OID 0)
-- Name: lendenapp_user_gst_202709_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202709_user_id_ci_invoice_date_idx;


--
-- TOC entry 9452 (class 0 OID 0)
-- Name: lendenapp_user_gst_202709_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202709_user_id_in_invoice_date_idx;


--
-- TOC entry 9453 (class 0 OID 0)
-- Name: lendenapp_user_gst_202710_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202710_pkey;


--
-- TOC entry 9454 (class 0 OID 0)
-- Name: lendenapp_user_gst_202710_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202710_user_id_ci_invoice_date_idx;


--
-- TOC entry 9455 (class 0 OID 0)
-- Name: lendenapp_user_gst_202710_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202710_user_id_in_invoice_date_idx;


--
-- TOC entry 9456 (class 0 OID 0)
-- Name: lendenapp_user_gst_202711_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202711_pkey;


--
-- TOC entry 9457 (class 0 OID 0)
-- Name: lendenapp_user_gst_202711_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202711_user_id_ci_invoice_date_idx;


--
-- TOC entry 9458 (class 0 OID 0)
-- Name: lendenapp_user_gst_202711_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202711_user_id_in_invoice_date_idx;


--
-- TOC entry 9459 (class 0 OID 0)
-- Name: lendenapp_user_gst_202712_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202712_pkey;


--
-- TOC entry 9460 (class 0 OID 0)
-- Name: lendenapp_user_gst_202712_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202712_user_id_ci_invoice_date_idx;


--
-- TOC entry 9461 (class 0 OID 0)
-- Name: lendenapp_user_gst_202712_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202712_user_id_in_invoice_date_idx;


--
-- TOC entry 9462 (class 0 OID 0)
-- Name: lendenapp_user_gst_202801_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202801_pkey;


--
-- TOC entry 9463 (class 0 OID 0)
-- Name: lendenapp_user_gst_202801_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202801_user_id_ci_invoice_date_idx;


--
-- TOC entry 9464 (class 0 OID 0)
-- Name: lendenapp_user_gst_202801_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202801_user_id_in_invoice_date_idx;


--
-- TOC entry 9465 (class 0 OID 0)
-- Name: lendenapp_user_gst_202802_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202802_pkey;


--
-- TOC entry 9466 (class 0 OID 0)
-- Name: lendenapp_user_gst_202802_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202802_user_id_ci_invoice_date_idx;


--
-- TOC entry 9467 (class 0 OID 0)
-- Name: lendenapp_user_gst_202802_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202802_user_id_in_invoice_date_idx;


--
-- TOC entry 9468 (class 0 OID 0)
-- Name: lendenapp_user_gst_202803_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202803_pkey;


--
-- TOC entry 9469 (class 0 OID 0)
-- Name: lendenapp_user_gst_202803_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202803_user_id_ci_invoice_date_idx;


--
-- TOC entry 9470 (class 0 OID 0)
-- Name: lendenapp_user_gst_202803_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202803_user_id_in_invoice_date_idx;


--
-- TOC entry 9471 (class 0 OID 0)
-- Name: lendenapp_user_gst_202804_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202804_pkey;


--
-- TOC entry 9472 (class 0 OID 0)
-- Name: lendenapp_user_gst_202804_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202804_user_id_ci_invoice_date_idx;


--
-- TOC entry 9473 (class 0 OID 0)
-- Name: lendenapp_user_gst_202804_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202804_user_id_in_invoice_date_idx;


--
-- TOC entry 9474 (class 0 OID 0)
-- Name: lendenapp_user_gst_202805_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202805_pkey;


--
-- TOC entry 9475 (class 0 OID 0)
-- Name: lendenapp_user_gst_202805_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202805_user_id_ci_invoice_date_idx;


--
-- TOC entry 9476 (class 0 OID 0)
-- Name: lendenapp_user_gst_202805_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202805_user_id_in_invoice_date_idx;


--
-- TOC entry 9477 (class 0 OID 0)
-- Name: lendenapp_user_gst_202806_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202806_pkey;


--
-- TOC entry 9478 (class 0 OID 0)
-- Name: lendenapp_user_gst_202806_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202806_user_id_ci_invoice_date_idx;


--
-- TOC entry 9479 (class 0 OID 0)
-- Name: lendenapp_user_gst_202806_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202806_user_id_in_invoice_date_idx;


--
-- TOC entry 9480 (class 0 OID 0)
-- Name: lendenapp_user_gst_202807_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202807_pkey;


--
-- TOC entry 9481 (class 0 OID 0)
-- Name: lendenapp_user_gst_202807_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202807_user_id_ci_invoice_date_idx;


--
-- TOC entry 9482 (class 0 OID 0)
-- Name: lendenapp_user_gst_202807_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202807_user_id_in_invoice_date_idx;


--
-- TOC entry 9483 (class 0 OID 0)
-- Name: lendenapp_user_gst_202808_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202808_pkey;


--
-- TOC entry 9484 (class 0 OID 0)
-- Name: lendenapp_user_gst_202808_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202808_user_id_ci_invoice_date_idx;


--
-- TOC entry 9485 (class 0 OID 0)
-- Name: lendenapp_user_gst_202808_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202808_user_id_in_invoice_date_idx;


--
-- TOC entry 9486 (class 0 OID 0)
-- Name: lendenapp_user_gst_202809_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202809_pkey;


--
-- TOC entry 9487 (class 0 OID 0)
-- Name: lendenapp_user_gst_202809_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202809_user_id_ci_invoice_date_idx;


--
-- TOC entry 9488 (class 0 OID 0)
-- Name: lendenapp_user_gst_202809_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202809_user_id_in_invoice_date_idx;


--
-- TOC entry 9489 (class 0 OID 0)
-- Name: lendenapp_user_gst_202810_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202810_pkey;


--
-- TOC entry 9490 (class 0 OID 0)
-- Name: lendenapp_user_gst_202810_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202810_user_id_ci_invoice_date_idx;


--
-- TOC entry 9491 (class 0 OID 0)
-- Name: lendenapp_user_gst_202810_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202810_user_id_in_invoice_date_idx;


--
-- TOC entry 9492 (class 0 OID 0)
-- Name: lendenapp_user_gst_202811_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202811_pkey;


--
-- TOC entry 9493 (class 0 OID 0)
-- Name: lendenapp_user_gst_202811_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202811_user_id_ci_invoice_date_idx;


--
-- TOC entry 9494 (class 0 OID 0)
-- Name: lendenapp_user_gst_202811_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202811_user_id_in_invoice_date_idx;


--
-- TOC entry 9495 (class 0 OID 0)
-- Name: lendenapp_user_gst_202812_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202812_pkey;


--
-- TOC entry 9496 (class 0 OID 0)
-- Name: lendenapp_user_gst_202812_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202812_user_id_ci_invoice_date_idx;


--
-- TOC entry 9497 (class 0 OID 0)
-- Name: lendenapp_user_gst_202812_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202812_user_id_in_invoice_date_idx;


--
-- TOC entry 9498 (class 0 OID 0)
-- Name: lendenapp_user_gst_202901_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202901_pkey;


--
-- TOC entry 9499 (class 0 OID 0)
-- Name: lendenapp_user_gst_202901_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202901_user_id_ci_invoice_date_idx;


--
-- TOC entry 9500 (class 0 OID 0)
-- Name: lendenapp_user_gst_202901_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202901_user_id_in_invoice_date_idx;


--
-- TOC entry 9501 (class 0 OID 0)
-- Name: lendenapp_user_gst_202902_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202902_pkey;


--
-- TOC entry 9502 (class 0 OID 0)
-- Name: lendenapp_user_gst_202902_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202902_user_id_ci_invoice_date_idx;


--
-- TOC entry 9503 (class 0 OID 0)
-- Name: lendenapp_user_gst_202902_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202902_user_id_in_invoice_date_idx;


--
-- TOC entry 9504 (class 0 OID 0)
-- Name: lendenapp_user_gst_202903_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202903_pkey;


--
-- TOC entry 9505 (class 0 OID 0)
-- Name: lendenapp_user_gst_202903_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202903_user_id_ci_invoice_date_idx;


--
-- TOC entry 9506 (class 0 OID 0)
-- Name: lendenapp_user_gst_202903_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202903_user_id_in_invoice_date_idx;


--
-- TOC entry 9507 (class 0 OID 0)
-- Name: lendenapp_user_gst_202904_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202904_pkey;


--
-- TOC entry 9508 (class 0 OID 0)
-- Name: lendenapp_user_gst_202904_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202904_user_id_ci_invoice_date_idx;


--
-- TOC entry 9509 (class 0 OID 0)
-- Name: lendenapp_user_gst_202904_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202904_user_id_in_invoice_date_idx;


--
-- TOC entry 9510 (class 0 OID 0)
-- Name: lendenapp_user_gst_202905_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202905_pkey;


--
-- TOC entry 9511 (class 0 OID 0)
-- Name: lendenapp_user_gst_202905_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202905_user_id_ci_invoice_date_idx;


--
-- TOC entry 9512 (class 0 OID 0)
-- Name: lendenapp_user_gst_202905_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202905_user_id_in_invoice_date_idx;


--
-- TOC entry 9513 (class 0 OID 0)
-- Name: lendenapp_user_gst_202906_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202906_pkey;


--
-- TOC entry 9514 (class 0 OID 0)
-- Name: lendenapp_user_gst_202906_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202906_user_id_ci_invoice_date_idx;


--
-- TOC entry 9515 (class 0 OID 0)
-- Name: lendenapp_user_gst_202906_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202906_user_id_in_invoice_date_idx;


--
-- TOC entry 9516 (class 0 OID 0)
-- Name: lendenapp_user_gst_202907_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202907_pkey;


--
-- TOC entry 9517 (class 0 OID 0)
-- Name: lendenapp_user_gst_202907_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202907_user_id_ci_invoice_date_idx;


--
-- TOC entry 9518 (class 0 OID 0)
-- Name: lendenapp_user_gst_202907_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202907_user_id_in_invoice_date_idx;


--
-- TOC entry 9519 (class 0 OID 0)
-- Name: lendenapp_user_gst_202908_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202908_pkey;


--
-- TOC entry 9520 (class 0 OID 0)
-- Name: lendenapp_user_gst_202908_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202908_user_id_ci_invoice_date_idx;


--
-- TOC entry 9521 (class 0 OID 0)
-- Name: lendenapp_user_gst_202908_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202908_user_id_in_invoice_date_idx;


--
-- TOC entry 9522 (class 0 OID 0)
-- Name: lendenapp_user_gst_202909_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202909_pkey;


--
-- TOC entry 9523 (class 0 OID 0)
-- Name: lendenapp_user_gst_202909_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202909_user_id_ci_invoice_date_idx;


--
-- TOC entry 9524 (class 0 OID 0)
-- Name: lendenapp_user_gst_202909_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202909_user_id_in_invoice_date_idx;


--
-- TOC entry 9525 (class 0 OID 0)
-- Name: lendenapp_user_gst_202910_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202910_pkey;


--
-- TOC entry 9526 (class 0 OID 0)
-- Name: lendenapp_user_gst_202910_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202910_user_id_ci_invoice_date_idx;


--
-- TOC entry 9527 (class 0 OID 0)
-- Name: lendenapp_user_gst_202910_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202910_user_id_in_invoice_date_idx;


--
-- TOC entry 9528 (class 0 OID 0)
-- Name: lendenapp_user_gst_202911_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202911_pkey;


--
-- TOC entry 9529 (class 0 OID 0)
-- Name: lendenapp_user_gst_202911_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202911_user_id_ci_invoice_date_idx;


--
-- TOC entry 9530 (class 0 OID 0)
-- Name: lendenapp_user_gst_202911_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202911_user_id_in_invoice_date_idx;


--
-- TOC entry 9531 (class 0 OID 0)
-- Name: lendenapp_user_gst_202912_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_202912_pkey;


--
-- TOC entry 9532 (class 0 OID 0)
-- Name: lendenapp_user_gst_202912_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202912_user_id_ci_invoice_date_idx;


--
-- TOC entry 9533 (class 0 OID 0)
-- Name: lendenapp_user_gst_202912_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_202912_user_id_in_invoice_date_idx;


--
-- TOC entry 9534 (class 0 OID 0)
-- Name: lendenapp_user_gst_203001_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203001_pkey;


--
-- TOC entry 9535 (class 0 OID 0)
-- Name: lendenapp_user_gst_203001_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203001_user_id_ci_invoice_date_idx;


--
-- TOC entry 9536 (class 0 OID 0)
-- Name: lendenapp_user_gst_203001_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203001_user_id_in_invoice_date_idx;


--
-- TOC entry 9537 (class 0 OID 0)
-- Name: lendenapp_user_gst_203002_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203002_pkey;


--
-- TOC entry 9538 (class 0 OID 0)
-- Name: lendenapp_user_gst_203002_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203002_user_id_ci_invoice_date_idx;


--
-- TOC entry 9539 (class 0 OID 0)
-- Name: lendenapp_user_gst_203002_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203002_user_id_in_invoice_date_idx;


--
-- TOC entry 9540 (class 0 OID 0)
-- Name: lendenapp_user_gst_203003_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203003_pkey;


--
-- TOC entry 9541 (class 0 OID 0)
-- Name: lendenapp_user_gst_203003_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203003_user_id_ci_invoice_date_idx;


--
-- TOC entry 9542 (class 0 OID 0)
-- Name: lendenapp_user_gst_203003_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203003_user_id_in_invoice_date_idx;


--
-- TOC entry 9543 (class 0 OID 0)
-- Name: lendenapp_user_gst_203004_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203004_pkey;


--
-- TOC entry 9544 (class 0 OID 0)
-- Name: lendenapp_user_gst_203004_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203004_user_id_ci_invoice_date_idx;


--
-- TOC entry 9545 (class 0 OID 0)
-- Name: lendenapp_user_gst_203004_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203004_user_id_in_invoice_date_idx;


--
-- TOC entry 9546 (class 0 OID 0)
-- Name: lendenapp_user_gst_203005_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203005_pkey;


--
-- TOC entry 9547 (class 0 OID 0)
-- Name: lendenapp_user_gst_203005_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203005_user_id_ci_invoice_date_idx;


--
-- TOC entry 9548 (class 0 OID 0)
-- Name: lendenapp_user_gst_203005_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203005_user_id_in_invoice_date_idx;


--
-- TOC entry 9549 (class 0 OID 0)
-- Name: lendenapp_user_gst_203006_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203006_pkey;


--
-- TOC entry 9550 (class 0 OID 0)
-- Name: lendenapp_user_gst_203006_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203006_user_id_ci_invoice_date_idx;


--
-- TOC entry 9551 (class 0 OID 0)
-- Name: lendenapp_user_gst_203006_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203006_user_id_in_invoice_date_idx;


--
-- TOC entry 9552 (class 0 OID 0)
-- Name: lendenapp_user_gst_203007_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203007_pkey;


--
-- TOC entry 9553 (class 0 OID 0)
-- Name: lendenapp_user_gst_203007_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203007_user_id_ci_invoice_date_idx;


--
-- TOC entry 9554 (class 0 OID 0)
-- Name: lendenapp_user_gst_203007_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203007_user_id_in_invoice_date_idx;


--
-- TOC entry 9555 (class 0 OID 0)
-- Name: lendenapp_user_gst_203008_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203008_pkey;


--
-- TOC entry 9556 (class 0 OID 0)
-- Name: lendenapp_user_gst_203008_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203008_user_id_ci_invoice_date_idx;


--
-- TOC entry 9557 (class 0 OID 0)
-- Name: lendenapp_user_gst_203008_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203008_user_id_in_invoice_date_idx;


--
-- TOC entry 9558 (class 0 OID 0)
-- Name: lendenapp_user_gst_203009_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203009_pkey;


--
-- TOC entry 9559 (class 0 OID 0)
-- Name: lendenapp_user_gst_203009_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203009_user_id_ci_invoice_date_idx;


--
-- TOC entry 9560 (class 0 OID 0)
-- Name: lendenapp_user_gst_203009_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203009_user_id_in_invoice_date_idx;


--
-- TOC entry 9561 (class 0 OID 0)
-- Name: lendenapp_user_gst_203010_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203010_pkey;


--
-- TOC entry 9562 (class 0 OID 0)
-- Name: lendenapp_user_gst_203010_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203010_user_id_ci_invoice_date_idx;


--
-- TOC entry 9563 (class 0 OID 0)
-- Name: lendenapp_user_gst_203010_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203010_user_id_in_invoice_date_idx;


--
-- TOC entry 9564 (class 0 OID 0)
-- Name: lendenapp_user_gst_203011_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203011_pkey;


--
-- TOC entry 9565 (class 0 OID 0)
-- Name: lendenapp_user_gst_203011_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203011_user_id_ci_invoice_date_idx;


--
-- TOC entry 9566 (class 0 OID 0)
-- Name: lendenapp_user_gst_203011_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203011_user_id_in_invoice_date_idx;


--
-- TOC entry 9567 (class 0 OID 0)
-- Name: lendenapp_user_gst_203012_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203012_pkey;


--
-- TOC entry 9568 (class 0 OID 0)
-- Name: lendenapp_user_gst_203012_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203012_user_id_ci_invoice_date_idx;


--
-- TOC entry 9569 (class 0 OID 0)
-- Name: lendenapp_user_gst_203012_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203012_user_id_in_invoice_date_idx;


--
-- TOC entry 9570 (class 0 OID 0)
-- Name: lendenapp_user_gst_203101_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203101_pkey;


--
-- TOC entry 9571 (class 0 OID 0)
-- Name: lendenapp_user_gst_203101_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203101_user_id_ci_invoice_date_idx;


--
-- TOC entry 9572 (class 0 OID 0)
-- Name: lendenapp_user_gst_203101_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203101_user_id_in_invoice_date_idx;


--
-- TOC entry 9573 (class 0 OID 0)
-- Name: lendenapp_user_gst_203102_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203102_pkey;


--
-- TOC entry 9574 (class 0 OID 0)
-- Name: lendenapp_user_gst_203102_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203102_user_id_ci_invoice_date_idx;


--
-- TOC entry 9575 (class 0 OID 0)
-- Name: lendenapp_user_gst_203102_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203102_user_id_in_invoice_date_idx;


--
-- TOC entry 9576 (class 0 OID 0)
-- Name: lendenapp_user_gst_203103_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203103_pkey;


--
-- TOC entry 9577 (class 0 OID 0)
-- Name: lendenapp_user_gst_203103_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203103_user_id_ci_invoice_date_idx;


--
-- TOC entry 9578 (class 0 OID 0)
-- Name: lendenapp_user_gst_203103_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203103_user_id_in_invoice_date_idx;


--
-- TOC entry 9579 (class 0 OID 0)
-- Name: lendenapp_user_gst_203104_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203104_pkey;


--
-- TOC entry 9580 (class 0 OID 0)
-- Name: lendenapp_user_gst_203104_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203104_user_id_ci_invoice_date_idx;


--
-- TOC entry 9581 (class 0 OID 0)
-- Name: lendenapp_user_gst_203104_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203104_user_id_in_invoice_date_idx;


--
-- TOC entry 9582 (class 0 OID 0)
-- Name: lendenapp_user_gst_203105_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203105_pkey;


--
-- TOC entry 9583 (class 0 OID 0)
-- Name: lendenapp_user_gst_203105_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203105_user_id_ci_invoice_date_idx;


--
-- TOC entry 9584 (class 0 OID 0)
-- Name: lendenapp_user_gst_203105_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203105_user_id_in_invoice_date_idx;


--
-- TOC entry 9585 (class 0 OID 0)
-- Name: lendenapp_user_gst_203106_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203106_pkey;


--
-- TOC entry 9586 (class 0 OID 0)
-- Name: lendenapp_user_gst_203106_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203106_user_id_ci_invoice_date_idx;


--
-- TOC entry 9587 (class 0 OID 0)
-- Name: lendenapp_user_gst_203106_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203106_user_id_in_invoice_date_idx;


--
-- TOC entry 9588 (class 0 OID 0)
-- Name: lendenapp_user_gst_203107_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203107_pkey;


--
-- TOC entry 9589 (class 0 OID 0)
-- Name: lendenapp_user_gst_203107_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203107_user_id_ci_invoice_date_idx;


--
-- TOC entry 9590 (class 0 OID 0)
-- Name: lendenapp_user_gst_203107_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203107_user_id_in_invoice_date_idx;


--
-- TOC entry 9591 (class 0 OID 0)
-- Name: lendenapp_user_gst_203108_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203108_pkey;


--
-- TOC entry 9592 (class 0 OID 0)
-- Name: lendenapp_user_gst_203108_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203108_user_id_ci_invoice_date_idx;


--
-- TOC entry 9593 (class 0 OID 0)
-- Name: lendenapp_user_gst_203108_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203108_user_id_in_invoice_date_idx;


--
-- TOC entry 9594 (class 0 OID 0)
-- Name: lendenapp_user_gst_203109_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203109_pkey;


--
-- TOC entry 9595 (class 0 OID 0)
-- Name: lendenapp_user_gst_203109_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203109_user_id_ci_invoice_date_idx;


--
-- TOC entry 9596 (class 0 OID 0)
-- Name: lendenapp_user_gst_203109_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203109_user_id_in_invoice_date_idx;


--
-- TOC entry 9597 (class 0 OID 0)
-- Name: lendenapp_user_gst_203110_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203110_pkey;


--
-- TOC entry 9598 (class 0 OID 0)
-- Name: lendenapp_user_gst_203110_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203110_user_id_ci_invoice_date_idx;


--
-- TOC entry 9599 (class 0 OID 0)
-- Name: lendenapp_user_gst_203110_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203110_user_id_in_invoice_date_idx;


--
-- TOC entry 9600 (class 0 OID 0)
-- Name: lendenapp_user_gst_203111_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203111_pkey;


--
-- TOC entry 9601 (class 0 OID 0)
-- Name: lendenapp_user_gst_203111_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203111_user_id_ci_invoice_date_idx;


--
-- TOC entry 9602 (class 0 OID 0)
-- Name: lendenapp_user_gst_203111_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203111_user_id_in_invoice_date_idx;


--
-- TOC entry 9603 (class 0 OID 0)
-- Name: lendenapp_user_gst_203112_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203112_pkey;


--
-- TOC entry 9604 (class 0 OID 0)
-- Name: lendenapp_user_gst_203112_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203112_user_id_ci_invoice_date_idx;


--
-- TOC entry 9605 (class 0 OID 0)
-- Name: lendenapp_user_gst_203112_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203112_user_id_in_invoice_date_idx;


--
-- TOC entry 9606 (class 0 OID 0)
-- Name: lendenapp_user_gst_203201_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203201_pkey;


--
-- TOC entry 9607 (class 0 OID 0)
-- Name: lendenapp_user_gst_203201_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203201_user_id_ci_invoice_date_idx;


--
-- TOC entry 9608 (class 0 OID 0)
-- Name: lendenapp_user_gst_203201_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203201_user_id_in_invoice_date_idx;


--
-- TOC entry 9609 (class 0 OID 0)
-- Name: lendenapp_user_gst_203202_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203202_pkey;


--
-- TOC entry 9610 (class 0 OID 0)
-- Name: lendenapp_user_gst_203202_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203202_user_id_ci_invoice_date_idx;


--
-- TOC entry 9611 (class 0 OID 0)
-- Name: lendenapp_user_gst_203202_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203202_user_id_in_invoice_date_idx;


--
-- TOC entry 9612 (class 0 OID 0)
-- Name: lendenapp_user_gst_203203_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203203_pkey;


--
-- TOC entry 9613 (class 0 OID 0)
-- Name: lendenapp_user_gst_203203_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203203_user_id_ci_invoice_date_idx;


--
-- TOC entry 9614 (class 0 OID 0)
-- Name: lendenapp_user_gst_203203_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203203_user_id_in_invoice_date_idx;


--
-- TOC entry 9615 (class 0 OID 0)
-- Name: lendenapp_user_gst_203204_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203204_pkey;


--
-- TOC entry 9616 (class 0 OID 0)
-- Name: lendenapp_user_gst_203204_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203204_user_id_ci_invoice_date_idx;


--
-- TOC entry 9617 (class 0 OID 0)
-- Name: lendenapp_user_gst_203204_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203204_user_id_in_invoice_date_idx;


--
-- TOC entry 9618 (class 0 OID 0)
-- Name: lendenapp_user_gst_203205_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203205_pkey;


--
-- TOC entry 9619 (class 0 OID 0)
-- Name: lendenapp_user_gst_203205_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203205_user_id_ci_invoice_date_idx;


--
-- TOC entry 9620 (class 0 OID 0)
-- Name: lendenapp_user_gst_203205_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203205_user_id_in_invoice_date_idx;


--
-- TOC entry 9621 (class 0 OID 0)
-- Name: lendenapp_user_gst_203206_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203206_pkey;


--
-- TOC entry 9622 (class 0 OID 0)
-- Name: lendenapp_user_gst_203206_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203206_user_id_ci_invoice_date_idx;


--
-- TOC entry 9623 (class 0 OID 0)
-- Name: lendenapp_user_gst_203206_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203206_user_id_in_invoice_date_idx;


--
-- TOC entry 9624 (class 0 OID 0)
-- Name: lendenapp_user_gst_203207_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203207_pkey;


--
-- TOC entry 9625 (class 0 OID 0)
-- Name: lendenapp_user_gst_203207_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203207_user_id_ci_invoice_date_idx;


--
-- TOC entry 9626 (class 0 OID 0)
-- Name: lendenapp_user_gst_203207_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203207_user_id_in_invoice_date_idx;


--
-- TOC entry 9627 (class 0 OID 0)
-- Name: lendenapp_user_gst_203208_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203208_pkey;


--
-- TOC entry 9628 (class 0 OID 0)
-- Name: lendenapp_user_gst_203208_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203208_user_id_ci_invoice_date_idx;


--
-- TOC entry 9629 (class 0 OID 0)
-- Name: lendenapp_user_gst_203208_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203208_user_id_in_invoice_date_idx;


--
-- TOC entry 9630 (class 0 OID 0)
-- Name: lendenapp_user_gst_203209_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203209_pkey;


--
-- TOC entry 9631 (class 0 OID 0)
-- Name: lendenapp_user_gst_203209_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203209_user_id_ci_invoice_date_idx;


--
-- TOC entry 9632 (class 0 OID 0)
-- Name: lendenapp_user_gst_203209_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203209_user_id_in_invoice_date_idx;


--
-- TOC entry 9633 (class 0 OID 0)
-- Name: lendenapp_user_gst_203210_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203210_pkey;


--
-- TOC entry 9634 (class 0 OID 0)
-- Name: lendenapp_user_gst_203210_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203210_user_id_ci_invoice_date_idx;


--
-- TOC entry 9635 (class 0 OID 0)
-- Name: lendenapp_user_gst_203210_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203210_user_id_in_invoice_date_idx;


--
-- TOC entry 9636 (class 0 OID 0)
-- Name: lendenapp_user_gst_203211_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203211_pkey;


--
-- TOC entry 9637 (class 0 OID 0)
-- Name: lendenapp_user_gst_203211_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203211_user_id_ci_invoice_date_idx;


--
-- TOC entry 9638 (class 0 OID 0)
-- Name: lendenapp_user_gst_203211_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203211_user_id_in_invoice_date_idx;


--
-- TOC entry 9639 (class 0 OID 0)
-- Name: lendenapp_user_gst_203212_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203212_pkey;


--
-- TOC entry 9640 (class 0 OID 0)
-- Name: lendenapp_user_gst_203212_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203212_user_id_ci_invoice_date_idx;


--
-- TOC entry 9641 (class 0 OID 0)
-- Name: lendenapp_user_gst_203212_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203212_user_id_in_invoice_date_idx;


--
-- TOC entry 9642 (class 0 OID 0)
-- Name: lendenapp_user_gst_203301_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203301_pkey;


--
-- TOC entry 9643 (class 0 OID 0)
-- Name: lendenapp_user_gst_203301_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203301_user_id_ci_invoice_date_idx;


--
-- TOC entry 9644 (class 0 OID 0)
-- Name: lendenapp_user_gst_203301_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203301_user_id_in_invoice_date_idx;


--
-- TOC entry 9645 (class 0 OID 0)
-- Name: lendenapp_user_gst_203302_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203302_pkey;


--
-- TOC entry 9646 (class 0 OID 0)
-- Name: lendenapp_user_gst_203302_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203302_user_id_ci_invoice_date_idx;


--
-- TOC entry 9647 (class 0 OID 0)
-- Name: lendenapp_user_gst_203302_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203302_user_id_in_invoice_date_idx;


--
-- TOC entry 9648 (class 0 OID 0)
-- Name: lendenapp_user_gst_203303_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203303_pkey;


--
-- TOC entry 9649 (class 0 OID 0)
-- Name: lendenapp_user_gst_203303_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203303_user_id_ci_invoice_date_idx;


--
-- TOC entry 9650 (class 0 OID 0)
-- Name: lendenapp_user_gst_203303_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203303_user_id_in_invoice_date_idx;


--
-- TOC entry 9651 (class 0 OID 0)
-- Name: lendenapp_user_gst_203304_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203304_pkey;


--
-- TOC entry 9652 (class 0 OID 0)
-- Name: lendenapp_user_gst_203304_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203304_user_id_ci_invoice_date_idx;


--
-- TOC entry 9653 (class 0 OID 0)
-- Name: lendenapp_user_gst_203304_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203304_user_id_in_invoice_date_idx;


--
-- TOC entry 9654 (class 0 OID 0)
-- Name: lendenapp_user_gst_203305_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203305_pkey;


--
-- TOC entry 9655 (class 0 OID 0)
-- Name: lendenapp_user_gst_203305_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203305_user_id_ci_invoice_date_idx;


--
-- TOC entry 9656 (class 0 OID 0)
-- Name: lendenapp_user_gst_203305_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203305_user_id_in_invoice_date_idx;


--
-- TOC entry 9657 (class 0 OID 0)
-- Name: lendenapp_user_gst_203306_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203306_pkey;


--
-- TOC entry 9658 (class 0 OID 0)
-- Name: lendenapp_user_gst_203306_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203306_user_id_ci_invoice_date_idx;


--
-- TOC entry 9659 (class 0 OID 0)
-- Name: lendenapp_user_gst_203306_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203306_user_id_in_invoice_date_idx;


--
-- TOC entry 9660 (class 0 OID 0)
-- Name: lendenapp_user_gst_203307_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203307_pkey;


--
-- TOC entry 9661 (class 0 OID 0)
-- Name: lendenapp_user_gst_203307_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203307_user_id_ci_invoice_date_idx;


--
-- TOC entry 9662 (class 0 OID 0)
-- Name: lendenapp_user_gst_203307_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203307_user_id_in_invoice_date_idx;


--
-- TOC entry 9663 (class 0 OID 0)
-- Name: lendenapp_user_gst_203308_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203308_pkey;


--
-- TOC entry 9664 (class 0 OID 0)
-- Name: lendenapp_user_gst_203308_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203308_user_id_ci_invoice_date_idx;


--
-- TOC entry 9665 (class 0 OID 0)
-- Name: lendenapp_user_gst_203308_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203308_user_id_in_invoice_date_idx;


--
-- TOC entry 9666 (class 0 OID 0)
-- Name: lendenapp_user_gst_203309_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203309_pkey;


--
-- TOC entry 9667 (class 0 OID 0)
-- Name: lendenapp_user_gst_203309_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203309_user_id_ci_invoice_date_idx;


--
-- TOC entry 9668 (class 0 OID 0)
-- Name: lendenapp_user_gst_203309_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203309_user_id_in_invoice_date_idx;


--
-- TOC entry 9669 (class 0 OID 0)
-- Name: lendenapp_user_gst_203310_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203310_pkey;


--
-- TOC entry 9670 (class 0 OID 0)
-- Name: lendenapp_user_gst_203310_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203310_user_id_ci_invoice_date_idx;


--
-- TOC entry 9671 (class 0 OID 0)
-- Name: lendenapp_user_gst_203310_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203310_user_id_in_invoice_date_idx;


--
-- TOC entry 9672 (class 0 OID 0)
-- Name: lendenapp_user_gst_203311_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203311_pkey;


--
-- TOC entry 9673 (class 0 OID 0)
-- Name: lendenapp_user_gst_203311_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203311_user_id_ci_invoice_date_idx;


--
-- TOC entry 9674 (class 0 OID 0)
-- Name: lendenapp_user_gst_203311_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203311_user_id_in_invoice_date_idx;


--
-- TOC entry 9675 (class 0 OID 0)
-- Name: lendenapp_user_gst_203312_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203312_pkey;


--
-- TOC entry 9676 (class 0 OID 0)
-- Name: lendenapp_user_gst_203312_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203312_user_id_ci_invoice_date_idx;


--
-- TOC entry 9677 (class 0 OID 0)
-- Name: lendenapp_user_gst_203312_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203312_user_id_in_invoice_date_idx;


--
-- TOC entry 9678 (class 0 OID 0)
-- Name: lendenapp_user_gst_203401_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203401_pkey;


--
-- TOC entry 9679 (class 0 OID 0)
-- Name: lendenapp_user_gst_203401_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203401_user_id_ci_invoice_date_idx;


--
-- TOC entry 9680 (class 0 OID 0)
-- Name: lendenapp_user_gst_203401_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203401_user_id_in_invoice_date_idx;


--
-- TOC entry 9681 (class 0 OID 0)
-- Name: lendenapp_user_gst_203402_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203402_pkey;


--
-- TOC entry 9682 (class 0 OID 0)
-- Name: lendenapp_user_gst_203402_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203402_user_id_ci_invoice_date_idx;


--
-- TOC entry 9683 (class 0 OID 0)
-- Name: lendenapp_user_gst_203402_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203402_user_id_in_invoice_date_idx;


--
-- TOC entry 9684 (class 0 OID 0)
-- Name: lendenapp_user_gst_203403_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203403_pkey;


--
-- TOC entry 9685 (class 0 OID 0)
-- Name: lendenapp_user_gst_203403_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203403_user_id_ci_invoice_date_idx;


--
-- TOC entry 9686 (class 0 OID 0)
-- Name: lendenapp_user_gst_203403_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203403_user_id_in_invoice_date_idx;


--
-- TOC entry 9687 (class 0 OID 0)
-- Name: lendenapp_user_gst_203404_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203404_pkey;


--
-- TOC entry 9688 (class 0 OID 0)
-- Name: lendenapp_user_gst_203404_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203404_user_id_ci_invoice_date_idx;


--
-- TOC entry 9689 (class 0 OID 0)
-- Name: lendenapp_user_gst_203404_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203404_user_id_in_invoice_date_idx;


--
-- TOC entry 9690 (class 0 OID 0)
-- Name: lendenapp_user_gst_203405_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203405_pkey;


--
-- TOC entry 9691 (class 0 OID 0)
-- Name: lendenapp_user_gst_203405_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203405_user_id_ci_invoice_date_idx;


--
-- TOC entry 9692 (class 0 OID 0)
-- Name: lendenapp_user_gst_203405_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203405_user_id_in_invoice_date_idx;


--
-- TOC entry 9693 (class 0 OID 0)
-- Name: lendenapp_user_gst_203406_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203406_pkey;


--
-- TOC entry 9694 (class 0 OID 0)
-- Name: lendenapp_user_gst_203406_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203406_user_id_ci_invoice_date_idx;


--
-- TOC entry 9695 (class 0 OID 0)
-- Name: lendenapp_user_gst_203406_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203406_user_id_in_invoice_date_idx;


--
-- TOC entry 9696 (class 0 OID 0)
-- Name: lendenapp_user_gst_203407_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203407_pkey;


--
-- TOC entry 9697 (class 0 OID 0)
-- Name: lendenapp_user_gst_203407_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203407_user_id_ci_invoice_date_idx;


--
-- TOC entry 9698 (class 0 OID 0)
-- Name: lendenapp_user_gst_203407_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203407_user_id_in_invoice_date_idx;


--
-- TOC entry 9699 (class 0 OID 0)
-- Name: lendenapp_user_gst_203408_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203408_pkey;


--
-- TOC entry 9700 (class 0 OID 0)
-- Name: lendenapp_user_gst_203408_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203408_user_id_ci_invoice_date_idx;


--
-- TOC entry 9701 (class 0 OID 0)
-- Name: lendenapp_user_gst_203408_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203408_user_id_in_invoice_date_idx;


--
-- TOC entry 9702 (class 0 OID 0)
-- Name: lendenapp_user_gst_203409_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203409_pkey;


--
-- TOC entry 9703 (class 0 OID 0)
-- Name: lendenapp_user_gst_203409_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203409_user_id_ci_invoice_date_idx;


--
-- TOC entry 9704 (class 0 OID 0)
-- Name: lendenapp_user_gst_203409_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203409_user_id_in_invoice_date_idx;


--
-- TOC entry 9705 (class 0 OID 0)
-- Name: lendenapp_user_gst_203410_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203410_pkey;


--
-- TOC entry 9706 (class 0 OID 0)
-- Name: lendenapp_user_gst_203410_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203410_user_id_ci_invoice_date_idx;


--
-- TOC entry 9707 (class 0 OID 0)
-- Name: lendenapp_user_gst_203410_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203410_user_id_in_invoice_date_idx;


--
-- TOC entry 9708 (class 0 OID 0)
-- Name: lendenapp_user_gst_203411_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203411_pkey;


--
-- TOC entry 9709 (class 0 OID 0)
-- Name: lendenapp_user_gst_203411_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203411_user_id_ci_invoice_date_idx;


--
-- TOC entry 9710 (class 0 OID 0)
-- Name: lendenapp_user_gst_203411_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203411_user_id_in_invoice_date_idx;


--
-- TOC entry 9711 (class 0 OID 0)
-- Name: lendenapp_user_gst_203412_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203412_pkey;


--
-- TOC entry 9712 (class 0 OID 0)
-- Name: lendenapp_user_gst_203412_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203412_user_id_ci_invoice_date_idx;


--
-- TOC entry 9713 (class 0 OID 0)
-- Name: lendenapp_user_gst_203412_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203412_user_id_in_invoice_date_idx;


--
-- TOC entry 9714 (class 0 OID 0)
-- Name: lendenapp_user_gst_203501_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203501_pkey;


--
-- TOC entry 9715 (class 0 OID 0)
-- Name: lendenapp_user_gst_203501_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203501_user_id_ci_invoice_date_idx;


--
-- TOC entry 9716 (class 0 OID 0)
-- Name: lendenapp_user_gst_203501_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203501_user_id_in_invoice_date_idx;


--
-- TOC entry 9717 (class 0 OID 0)
-- Name: lendenapp_user_gst_203502_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203502_pkey;


--
-- TOC entry 9718 (class 0 OID 0)
-- Name: lendenapp_user_gst_203502_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203502_user_id_ci_invoice_date_idx;


--
-- TOC entry 9719 (class 0 OID 0)
-- Name: lendenapp_user_gst_203502_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203502_user_id_in_invoice_date_idx;


--
-- TOC entry 9720 (class 0 OID 0)
-- Name: lendenapp_user_gst_203503_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203503_pkey;


--
-- TOC entry 9721 (class 0 OID 0)
-- Name: lendenapp_user_gst_203503_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203503_user_id_ci_invoice_date_idx;


--
-- TOC entry 9722 (class 0 OID 0)
-- Name: lendenapp_user_gst_203503_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203503_user_id_in_invoice_date_idx;


--
-- TOC entry 9723 (class 0 OID 0)
-- Name: lendenapp_user_gst_203504_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203504_pkey;


--
-- TOC entry 9724 (class 0 OID 0)
-- Name: lendenapp_user_gst_203504_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203504_user_id_ci_invoice_date_idx;


--
-- TOC entry 9725 (class 0 OID 0)
-- Name: lendenapp_user_gst_203504_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203504_user_id_in_invoice_date_idx;


--
-- TOC entry 9726 (class 0 OID 0)
-- Name: lendenapp_user_gst_203505_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203505_pkey;


--
-- TOC entry 9727 (class 0 OID 0)
-- Name: lendenapp_user_gst_203505_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203505_user_id_ci_invoice_date_idx;


--
-- TOC entry 9728 (class 0 OID 0)
-- Name: lendenapp_user_gst_203505_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203505_user_id_in_invoice_date_idx;


--
-- TOC entry 9729 (class 0 OID 0)
-- Name: lendenapp_user_gst_203506_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203506_pkey;


--
-- TOC entry 9730 (class 0 OID 0)
-- Name: lendenapp_user_gst_203506_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203506_user_id_ci_invoice_date_idx;


--
-- TOC entry 9731 (class 0 OID 0)
-- Name: lendenapp_user_gst_203506_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203506_user_id_in_invoice_date_idx;


--
-- TOC entry 9732 (class 0 OID 0)
-- Name: lendenapp_user_gst_203507_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203507_pkey;


--
-- TOC entry 9733 (class 0 OID 0)
-- Name: lendenapp_user_gst_203507_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203507_user_id_ci_invoice_date_idx;


--
-- TOC entry 9734 (class 0 OID 0)
-- Name: lendenapp_user_gst_203507_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203507_user_id_in_invoice_date_idx;


--
-- TOC entry 9735 (class 0 OID 0)
-- Name: lendenapp_user_gst_203508_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203508_pkey;


--
-- TOC entry 9736 (class 0 OID 0)
-- Name: lendenapp_user_gst_203508_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203508_user_id_ci_invoice_date_idx;


--
-- TOC entry 9737 (class 0 OID 0)
-- Name: lendenapp_user_gst_203508_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203508_user_id_in_invoice_date_idx;


--
-- TOC entry 9738 (class 0 OID 0)
-- Name: lendenapp_user_gst_203509_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203509_pkey;


--
-- TOC entry 9739 (class 0 OID 0)
-- Name: lendenapp_user_gst_203509_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203509_user_id_ci_invoice_date_idx;


--
-- TOC entry 9740 (class 0 OID 0)
-- Name: lendenapp_user_gst_203509_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203509_user_id_in_invoice_date_idx;


--
-- TOC entry 9741 (class 0 OID 0)
-- Name: lendenapp_user_gst_203510_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203510_pkey;


--
-- TOC entry 9742 (class 0 OID 0)
-- Name: lendenapp_user_gst_203510_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203510_user_id_ci_invoice_date_idx;


--
-- TOC entry 9743 (class 0 OID 0)
-- Name: lendenapp_user_gst_203510_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203510_user_id_in_invoice_date_idx;


--
-- TOC entry 9744 (class 0 OID 0)
-- Name: lendenapp_user_gst_203511_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203511_pkey;


--
-- TOC entry 9745 (class 0 OID 0)
-- Name: lendenapp_user_gst_203511_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203511_user_id_ci_invoice_date_idx;


--
-- TOC entry 9746 (class 0 OID 0)
-- Name: lendenapp_user_gst_203511_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203511_user_id_in_invoice_date_idx;


--
-- TOC entry 9747 (class 0 OID 0)
-- Name: lendenapp_user_gst_203512_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203512_pkey;


--
-- TOC entry 9748 (class 0 OID 0)
-- Name: lendenapp_user_gst_203512_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203512_user_id_ci_invoice_date_idx;


--
-- TOC entry 9749 (class 0 OID 0)
-- Name: lendenapp_user_gst_203512_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203512_user_id_in_invoice_date_idx;


--
-- TOC entry 9750 (class 0 OID 0)
-- Name: lendenapp_user_gst_203601_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203601_pkey;


--
-- TOC entry 9751 (class 0 OID 0)
-- Name: lendenapp_user_gst_203601_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203601_user_id_ci_invoice_date_idx;


--
-- TOC entry 9752 (class 0 OID 0)
-- Name: lendenapp_user_gst_203601_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203601_user_id_in_invoice_date_idx;


--
-- TOC entry 9753 (class 0 OID 0)
-- Name: lendenapp_user_gst_203602_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203602_pkey;


--
-- TOC entry 9754 (class 0 OID 0)
-- Name: lendenapp_user_gst_203602_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203602_user_id_ci_invoice_date_idx;


--
-- TOC entry 9755 (class 0 OID 0)
-- Name: lendenapp_user_gst_203602_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203602_user_id_in_invoice_date_idx;


--
-- TOC entry 9756 (class 0 OID 0)
-- Name: lendenapp_user_gst_203603_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203603_pkey;


--
-- TOC entry 9757 (class 0 OID 0)
-- Name: lendenapp_user_gst_203603_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203603_user_id_ci_invoice_date_idx;


--
-- TOC entry 9758 (class 0 OID 0)
-- Name: lendenapp_user_gst_203603_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203603_user_id_in_invoice_date_idx;


--
-- TOC entry 9759 (class 0 OID 0)
-- Name: lendenapp_user_gst_203604_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203604_pkey;


--
-- TOC entry 9760 (class 0 OID 0)
-- Name: lendenapp_user_gst_203604_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203604_user_id_ci_invoice_date_idx;


--
-- TOC entry 9761 (class 0 OID 0)
-- Name: lendenapp_user_gst_203604_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203604_user_id_in_invoice_date_idx;


--
-- TOC entry 9762 (class 0 OID 0)
-- Name: lendenapp_user_gst_203605_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203605_pkey;


--
-- TOC entry 9763 (class 0 OID 0)
-- Name: lendenapp_user_gst_203605_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203605_user_id_ci_invoice_date_idx;


--
-- TOC entry 9764 (class 0 OID 0)
-- Name: lendenapp_user_gst_203605_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203605_user_id_in_invoice_date_idx;


--
-- TOC entry 9765 (class 0 OID 0)
-- Name: lendenapp_user_gst_203606_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203606_pkey;


--
-- TOC entry 9766 (class 0 OID 0)
-- Name: lendenapp_user_gst_203606_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203606_user_id_ci_invoice_date_idx;


--
-- TOC entry 9767 (class 0 OID 0)
-- Name: lendenapp_user_gst_203606_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203606_user_id_in_invoice_date_idx;


--
-- TOC entry 9768 (class 0 OID 0)
-- Name: lendenapp_user_gst_203607_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203607_pkey;


--
-- TOC entry 9769 (class 0 OID 0)
-- Name: lendenapp_user_gst_203607_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203607_user_id_ci_invoice_date_idx;


--
-- TOC entry 9770 (class 0 OID 0)
-- Name: lendenapp_user_gst_203607_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203607_user_id_in_invoice_date_idx;


--
-- TOC entry 9771 (class 0 OID 0)
-- Name: lendenapp_user_gst_203608_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203608_pkey;


--
-- TOC entry 9772 (class 0 OID 0)
-- Name: lendenapp_user_gst_203608_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203608_user_id_ci_invoice_date_idx;


--
-- TOC entry 9773 (class 0 OID 0)
-- Name: lendenapp_user_gst_203608_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203608_user_id_in_invoice_date_idx;


--
-- TOC entry 9774 (class 0 OID 0)
-- Name: lendenapp_user_gst_203609_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203609_pkey;


--
-- TOC entry 9775 (class 0 OID 0)
-- Name: lendenapp_user_gst_203609_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203609_user_id_ci_invoice_date_idx;


--
-- TOC entry 9776 (class 0 OID 0)
-- Name: lendenapp_user_gst_203609_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203609_user_id_in_invoice_date_idx;


--
-- TOC entry 9777 (class 0 OID 0)
-- Name: lendenapp_user_gst_203610_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203610_pkey;


--
-- TOC entry 9778 (class 0 OID 0)
-- Name: lendenapp_user_gst_203610_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203610_user_id_ci_invoice_date_idx;


--
-- TOC entry 9779 (class 0 OID 0)
-- Name: lendenapp_user_gst_203610_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203610_user_id_in_invoice_date_idx;


--
-- TOC entry 9780 (class 0 OID 0)
-- Name: lendenapp_user_gst_203611_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203611_pkey;


--
-- TOC entry 9781 (class 0 OID 0)
-- Name: lendenapp_user_gst_203611_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203611_user_id_ci_invoice_date_idx;


--
-- TOC entry 9782 (class 0 OID 0)
-- Name: lendenapp_user_gst_203611_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203611_user_id_in_invoice_date_idx;


--
-- TOC entry 9783 (class 0 OID 0)
-- Name: lendenapp_user_gst_203612_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203612_pkey;


--
-- TOC entry 9784 (class 0 OID 0)
-- Name: lendenapp_user_gst_203612_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203612_user_id_ci_invoice_date_idx;


--
-- TOC entry 9785 (class 0 OID 0)
-- Name: lendenapp_user_gst_203612_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203612_user_id_in_invoice_date_idx;


--
-- TOC entry 9786 (class 0 OID 0)
-- Name: lendenapp_user_gst_203701_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203701_pkey;


--
-- TOC entry 9787 (class 0 OID 0)
-- Name: lendenapp_user_gst_203701_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203701_user_id_ci_invoice_date_idx;


--
-- TOC entry 9788 (class 0 OID 0)
-- Name: lendenapp_user_gst_203701_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203701_user_id_in_invoice_date_idx;


--
-- TOC entry 9789 (class 0 OID 0)
-- Name: lendenapp_user_gst_203702_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203702_pkey;


--
-- TOC entry 9790 (class 0 OID 0)
-- Name: lendenapp_user_gst_203702_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203702_user_id_ci_invoice_date_idx;


--
-- TOC entry 9791 (class 0 OID 0)
-- Name: lendenapp_user_gst_203702_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203702_user_id_in_invoice_date_idx;


--
-- TOC entry 9792 (class 0 OID 0)
-- Name: lendenapp_user_gst_203703_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203703_pkey;


--
-- TOC entry 9793 (class 0 OID 0)
-- Name: lendenapp_user_gst_203703_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203703_user_id_ci_invoice_date_idx;


--
-- TOC entry 9794 (class 0 OID 0)
-- Name: lendenapp_user_gst_203703_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203703_user_id_in_invoice_date_idx;


--
-- TOC entry 9795 (class 0 OID 0)
-- Name: lendenapp_user_gst_203704_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203704_pkey;


--
-- TOC entry 9796 (class 0 OID 0)
-- Name: lendenapp_user_gst_203704_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203704_user_id_ci_invoice_date_idx;


--
-- TOC entry 9797 (class 0 OID 0)
-- Name: lendenapp_user_gst_203704_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203704_user_id_in_invoice_date_idx;


--
-- TOC entry 9798 (class 0 OID 0)
-- Name: lendenapp_user_gst_203705_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203705_pkey;


--
-- TOC entry 9799 (class 0 OID 0)
-- Name: lendenapp_user_gst_203705_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203705_user_id_ci_invoice_date_idx;


--
-- TOC entry 9800 (class 0 OID 0)
-- Name: lendenapp_user_gst_203705_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203705_user_id_in_invoice_date_idx;


--
-- TOC entry 9801 (class 0 OID 0)
-- Name: lendenapp_user_gst_203706_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203706_pkey;


--
-- TOC entry 9802 (class 0 OID 0)
-- Name: lendenapp_user_gst_203706_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203706_user_id_ci_invoice_date_idx;


--
-- TOC entry 9803 (class 0 OID 0)
-- Name: lendenapp_user_gst_203706_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203706_user_id_in_invoice_date_idx;


--
-- TOC entry 9804 (class 0 OID 0)
-- Name: lendenapp_user_gst_203707_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203707_pkey;


--
-- TOC entry 9805 (class 0 OID 0)
-- Name: lendenapp_user_gst_203707_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203707_user_id_ci_invoice_date_idx;


--
-- TOC entry 9806 (class 0 OID 0)
-- Name: lendenapp_user_gst_203707_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203707_user_id_in_invoice_date_idx;


--
-- TOC entry 9807 (class 0 OID 0)
-- Name: lendenapp_user_gst_203708_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203708_pkey;


--
-- TOC entry 9808 (class 0 OID 0)
-- Name: lendenapp_user_gst_203708_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203708_user_id_ci_invoice_date_idx;


--
-- TOC entry 9809 (class 0 OID 0)
-- Name: lendenapp_user_gst_203708_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203708_user_id_in_invoice_date_idx;


--
-- TOC entry 9810 (class 0 OID 0)
-- Name: lendenapp_user_gst_203709_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203709_pkey;


--
-- TOC entry 9811 (class 0 OID 0)
-- Name: lendenapp_user_gst_203709_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203709_user_id_ci_invoice_date_idx;


--
-- TOC entry 9812 (class 0 OID 0)
-- Name: lendenapp_user_gst_203709_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203709_user_id_in_invoice_date_idx;


--
-- TOC entry 9813 (class 0 OID 0)
-- Name: lendenapp_user_gst_203710_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203710_pkey;


--
-- TOC entry 9814 (class 0 OID 0)
-- Name: lendenapp_user_gst_203710_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203710_user_id_ci_invoice_date_idx;


--
-- TOC entry 9815 (class 0 OID 0)
-- Name: lendenapp_user_gst_203710_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203710_user_id_in_invoice_date_idx;


--
-- TOC entry 9816 (class 0 OID 0)
-- Name: lendenapp_user_gst_203711_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203711_pkey;


--
-- TOC entry 9817 (class 0 OID 0)
-- Name: lendenapp_user_gst_203711_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203711_user_id_ci_invoice_date_idx;


--
-- TOC entry 9818 (class 0 OID 0)
-- Name: lendenapp_user_gst_203711_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203711_user_id_in_invoice_date_idx;


--
-- TOC entry 9819 (class 0 OID 0)
-- Name: lendenapp_user_gst_203712_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203712_pkey;


--
-- TOC entry 9820 (class 0 OID 0)
-- Name: lendenapp_user_gst_203712_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203712_user_id_ci_invoice_date_idx;


--
-- TOC entry 9821 (class 0 OID 0)
-- Name: lendenapp_user_gst_203712_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203712_user_id_in_invoice_date_idx;


--
-- TOC entry 9822 (class 0 OID 0)
-- Name: lendenapp_user_gst_203801_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203801_pkey;


--
-- TOC entry 9823 (class 0 OID 0)
-- Name: lendenapp_user_gst_203801_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203801_user_id_ci_invoice_date_idx;


--
-- TOC entry 9824 (class 0 OID 0)
-- Name: lendenapp_user_gst_203801_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203801_user_id_in_invoice_date_idx;


--
-- TOC entry 9825 (class 0 OID 0)
-- Name: lendenapp_user_gst_203802_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203802_pkey;


--
-- TOC entry 9826 (class 0 OID 0)
-- Name: lendenapp_user_gst_203802_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203802_user_id_ci_invoice_date_idx;


--
-- TOC entry 9827 (class 0 OID 0)
-- Name: lendenapp_user_gst_203802_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203802_user_id_in_invoice_date_idx;


--
-- TOC entry 9828 (class 0 OID 0)
-- Name: lendenapp_user_gst_203803_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203803_pkey;


--
-- TOC entry 9829 (class 0 OID 0)
-- Name: lendenapp_user_gst_203803_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203803_user_id_ci_invoice_date_idx;


--
-- TOC entry 9830 (class 0 OID 0)
-- Name: lendenapp_user_gst_203803_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203803_user_id_in_invoice_date_idx;


--
-- TOC entry 9831 (class 0 OID 0)
-- Name: lendenapp_user_gst_203804_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203804_pkey;


--
-- TOC entry 9832 (class 0 OID 0)
-- Name: lendenapp_user_gst_203804_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203804_user_id_ci_invoice_date_idx;


--
-- TOC entry 9833 (class 0 OID 0)
-- Name: lendenapp_user_gst_203804_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203804_user_id_in_invoice_date_idx;


--
-- TOC entry 9834 (class 0 OID 0)
-- Name: lendenapp_user_gst_203805_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203805_pkey;


--
-- TOC entry 9835 (class 0 OID 0)
-- Name: lendenapp_user_gst_203805_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203805_user_id_ci_invoice_date_idx;


--
-- TOC entry 9836 (class 0 OID 0)
-- Name: lendenapp_user_gst_203805_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203805_user_id_in_invoice_date_idx;


--
-- TOC entry 9837 (class 0 OID 0)
-- Name: lendenapp_user_gst_203806_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203806_pkey;


--
-- TOC entry 9838 (class 0 OID 0)
-- Name: lendenapp_user_gst_203806_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203806_user_id_ci_invoice_date_idx;


--
-- TOC entry 9839 (class 0 OID 0)
-- Name: lendenapp_user_gst_203806_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203806_user_id_in_invoice_date_idx;


--
-- TOC entry 9840 (class 0 OID 0)
-- Name: lendenapp_user_gst_203807_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203807_pkey;


--
-- TOC entry 9841 (class 0 OID 0)
-- Name: lendenapp_user_gst_203807_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203807_user_id_ci_invoice_date_idx;


--
-- TOC entry 9842 (class 0 OID 0)
-- Name: lendenapp_user_gst_203807_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203807_user_id_in_invoice_date_idx;


--
-- TOC entry 9843 (class 0 OID 0)
-- Name: lendenapp_user_gst_203808_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203808_pkey;


--
-- TOC entry 9844 (class 0 OID 0)
-- Name: lendenapp_user_gst_203808_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203808_user_id_ci_invoice_date_idx;


--
-- TOC entry 9845 (class 0 OID 0)
-- Name: lendenapp_user_gst_203808_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203808_user_id_in_invoice_date_idx;


--
-- TOC entry 9846 (class 0 OID 0)
-- Name: lendenapp_user_gst_203809_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203809_pkey;


--
-- TOC entry 9847 (class 0 OID 0)
-- Name: lendenapp_user_gst_203809_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203809_user_id_ci_invoice_date_idx;


--
-- TOC entry 9848 (class 0 OID 0)
-- Name: lendenapp_user_gst_203809_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203809_user_id_in_invoice_date_idx;


--
-- TOC entry 9849 (class 0 OID 0)
-- Name: lendenapp_user_gst_203810_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203810_pkey;


--
-- TOC entry 9850 (class 0 OID 0)
-- Name: lendenapp_user_gst_203810_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203810_user_id_ci_invoice_date_idx;


--
-- TOC entry 9851 (class 0 OID 0)
-- Name: lendenapp_user_gst_203810_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203810_user_id_in_invoice_date_idx;


--
-- TOC entry 9852 (class 0 OID 0)
-- Name: lendenapp_user_gst_203811_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203811_pkey;


--
-- TOC entry 9853 (class 0 OID 0)
-- Name: lendenapp_user_gst_203811_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203811_user_id_ci_invoice_date_idx;


--
-- TOC entry 9854 (class 0 OID 0)
-- Name: lendenapp_user_gst_203811_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203811_user_id_in_invoice_date_idx;


--
-- TOC entry 9855 (class 0 OID 0)
-- Name: lendenapp_user_gst_203812_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203812_pkey;


--
-- TOC entry 9856 (class 0 OID 0)
-- Name: lendenapp_user_gst_203812_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203812_user_id_ci_invoice_date_idx;


--
-- TOC entry 9857 (class 0 OID 0)
-- Name: lendenapp_user_gst_203812_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203812_user_id_in_invoice_date_idx;


--
-- TOC entry 9858 (class 0 OID 0)
-- Name: lendenapp_user_gst_203901_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203901_pkey;


--
-- TOC entry 9859 (class 0 OID 0)
-- Name: lendenapp_user_gst_203901_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203901_user_id_ci_invoice_date_idx;


--
-- TOC entry 9860 (class 0 OID 0)
-- Name: lendenapp_user_gst_203901_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203901_user_id_in_invoice_date_idx;


--
-- TOC entry 9861 (class 0 OID 0)
-- Name: lendenapp_user_gst_203902_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203902_pkey;


--
-- TOC entry 9862 (class 0 OID 0)
-- Name: lendenapp_user_gst_203902_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203902_user_id_ci_invoice_date_idx;


--
-- TOC entry 9863 (class 0 OID 0)
-- Name: lendenapp_user_gst_203902_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203902_user_id_in_invoice_date_idx;


--
-- TOC entry 9864 (class 0 OID 0)
-- Name: lendenapp_user_gst_203903_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203903_pkey;


--
-- TOC entry 9865 (class 0 OID 0)
-- Name: lendenapp_user_gst_203903_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203903_user_id_ci_invoice_date_idx;


--
-- TOC entry 9866 (class 0 OID 0)
-- Name: lendenapp_user_gst_203903_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203903_user_id_in_invoice_date_idx;


--
-- TOC entry 9867 (class 0 OID 0)
-- Name: lendenapp_user_gst_203904_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203904_pkey;


--
-- TOC entry 9868 (class 0 OID 0)
-- Name: lendenapp_user_gst_203904_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203904_user_id_ci_invoice_date_idx;


--
-- TOC entry 9869 (class 0 OID 0)
-- Name: lendenapp_user_gst_203904_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203904_user_id_in_invoice_date_idx;


--
-- TOC entry 9870 (class 0 OID 0)
-- Name: lendenapp_user_gst_203905_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203905_pkey;


--
-- TOC entry 9871 (class 0 OID 0)
-- Name: lendenapp_user_gst_203905_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203905_user_id_ci_invoice_date_idx;


--
-- TOC entry 9872 (class 0 OID 0)
-- Name: lendenapp_user_gst_203905_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203905_user_id_in_invoice_date_idx;


--
-- TOC entry 9873 (class 0 OID 0)
-- Name: lendenapp_user_gst_203906_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203906_pkey;


--
-- TOC entry 9874 (class 0 OID 0)
-- Name: lendenapp_user_gst_203906_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203906_user_id_ci_invoice_date_idx;


--
-- TOC entry 9875 (class 0 OID 0)
-- Name: lendenapp_user_gst_203906_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203906_user_id_in_invoice_date_idx;


--
-- TOC entry 9876 (class 0 OID 0)
-- Name: lendenapp_user_gst_203907_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203907_pkey;


--
-- TOC entry 9877 (class 0 OID 0)
-- Name: lendenapp_user_gst_203907_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203907_user_id_ci_invoice_date_idx;


--
-- TOC entry 9878 (class 0 OID 0)
-- Name: lendenapp_user_gst_203907_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203907_user_id_in_invoice_date_idx;


--
-- TOC entry 9879 (class 0 OID 0)
-- Name: lendenapp_user_gst_203908_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203908_pkey;


--
-- TOC entry 9880 (class 0 OID 0)
-- Name: lendenapp_user_gst_203908_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203908_user_id_ci_invoice_date_idx;


--
-- TOC entry 9881 (class 0 OID 0)
-- Name: lendenapp_user_gst_203908_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203908_user_id_in_invoice_date_idx;


--
-- TOC entry 9882 (class 0 OID 0)
-- Name: lendenapp_user_gst_203909_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203909_pkey;


--
-- TOC entry 9883 (class 0 OID 0)
-- Name: lendenapp_user_gst_203909_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203909_user_id_ci_invoice_date_idx;


--
-- TOC entry 9884 (class 0 OID 0)
-- Name: lendenapp_user_gst_203909_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203909_user_id_in_invoice_date_idx;


--
-- TOC entry 9885 (class 0 OID 0)
-- Name: lendenapp_user_gst_203910_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203910_pkey;


--
-- TOC entry 9886 (class 0 OID 0)
-- Name: lendenapp_user_gst_203910_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203910_user_id_ci_invoice_date_idx;


--
-- TOC entry 9887 (class 0 OID 0)
-- Name: lendenapp_user_gst_203910_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203910_user_id_in_invoice_date_idx;


--
-- TOC entry 9888 (class 0 OID 0)
-- Name: lendenapp_user_gst_203911_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203911_pkey;


--
-- TOC entry 9889 (class 0 OID 0)
-- Name: lendenapp_user_gst_203911_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203911_user_id_ci_invoice_date_idx;


--
-- TOC entry 9890 (class 0 OID 0)
-- Name: lendenapp_user_gst_203911_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203911_user_id_in_invoice_date_idx;


--
-- TOC entry 9891 (class 0 OID 0)
-- Name: lendenapp_user_gst_203912_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_203912_pkey;


--
-- TOC entry 9892 (class 0 OID 0)
-- Name: lendenapp_user_gst_203912_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203912_user_id_ci_invoice_date_idx;


--
-- TOC entry 9893 (class 0 OID 0)
-- Name: lendenapp_user_gst_203912_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_203912_user_id_in_invoice_date_idx;


--
-- TOC entry 9894 (class 0 OID 0)
-- Name: lendenapp_user_gst_204001_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_204001_pkey;


--
-- TOC entry 9895 (class 0 OID 0)
-- Name: lendenapp_user_gst_204001_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_204001_user_id_ci_invoice_date_idx;


--
-- TOC entry 9896 (class 0 OID 0)
-- Name: lendenapp_user_gst_204001_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_204001_user_id_in_invoice_date_idx;


--
-- TOC entry 9897 (class 0 OID 0)
-- Name: lendenapp_user_gst_204002_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_204002_pkey;


--
-- TOC entry 9898 (class 0 OID 0)
-- Name: lendenapp_user_gst_204002_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_204002_user_id_ci_invoice_date_idx;


--
-- TOC entry 9899 (class 0 OID 0)
-- Name: lendenapp_user_gst_204002_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_204002_user_id_in_invoice_date_idx;


--
-- TOC entry 9900 (class 0 OID 0)
-- Name: lendenapp_user_gst_204003_pkey; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.lendenapp_user_gst_pkey ATTACH PARTITION public.lendenapp_user_gst_204003_pkey;


--
-- TOC entry 9901 (class 0 OID 0)
-- Name: lendenapp_user_gst_204003_user_id_ci_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_ci_invoice_date ATTACH PARTITION public.lendenapp_user_gst_204003_user_id_ci_invoice_date_idx;


--
-- TOC entry 9902 (class 0 OID 0)
-- Name: lendenapp_user_gst_204003_user_id_in_invoice_date_idx; Type: INDEX ATTACH; Schema: public; Owner: devmultilenden
--

ALTER INDEX public.idx_user_in_invoice_date ATTACH PARTITION public.lendenapp_user_gst_204003_user_id_in_invoice_date_idx;


--
-- TOC entry 10003 (class 2620 OID 20102)
-- Name: lendenapp_account lendenapp_account_trigger; Type: TRIGGER; Schema: public; Owner: usrinvoswrt
--

CREATE TRIGGER lendenapp_account_trigger AFTER DELETE OR UPDATE ON public.lendenapp_account FOR EACH ROW EXECUTE FUNCTION public.lendenapp_account_trigger_function();


--
-- TOC entry 10002 (class 2620 OID 20103)
-- Name: lendenapp_transaction lendenapp_transaction_trigger; Type: TRIGGER; Schema: public; Owner: usrinvoswrt
--

CREATE TRIGGER lendenapp_transaction_trigger AFTER DELETE OR UPDATE ON public.lendenapp_transaction FOR EACH ROW EXECUTE FUNCTION public.lendenapp_transaction_trigger_function();


--
-- TOC entry 10004 (class 2620 OID 20104)
-- Name: lendenapp_track_txn_amount lendenapp_txntrackaccount_trigger; Type: TRIGGER; Schema: public; Owner: devmultilenden
--

CREATE TRIGGER lendenapp_txntrackaccount_trigger AFTER DELETE OR UPDATE ON public.lendenapp_track_txn_amount FOR EACH ROW EXECUTE FUNCTION public.lendenapp_txntrackaccount_trigger_function();


--
-- TOC entry 10005 (class 2620 OID 20105)
-- Name: lendenapp_transaction_amount_tracker lendenapp_txntrackaccount_trigger; Type: TRIGGER; Schema: public; Owner: devmultilenden
--

CREATE TRIGGER lendenapp_txntrackaccount_trigger AFTER DELETE OR UPDATE ON public.lendenapp_transaction_amount_tracker FOR EACH ROW EXECUTE FUNCTION public.lendenapp_txntrackaccount_trigger_function();


--
-- TOC entry 10001 (class 2606 OID 1949030)
-- Name: auth_permission auth_permission_content_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_fk FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9928 (class 2606 OID 20106)
-- Name: authtoken_token authtoken_token_user_id_35299eff_fk_lendenapp_customuser_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_35299eff_fk_lendenapp_customuser_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9905 (class 2606 OID 20111)
-- Name: lendenapp_user_source_group fk_auth_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_source_group
    ADD CONSTRAINT fk_auth_group_fk FOREIGN KEY (group_id) REFERENCES public.auth_group(id);


--
-- TOC entry 9997 (class 2606 OID 1883431)
-- Name: lendenapp_reward fk_campaign_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_reward
    ADD CONSTRAINT fk_campaign_id FOREIGN KEY (campaign_id) REFERENCES public.lendenapp_campaign(id);


--
-- TOC entry 9987 (class 2606 OID 20116)
-- Name: lendenapp_user_cohort_mapping fk_config; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_cohort_mapping
    ADD CONSTRAINT fk_config FOREIGN KEY (config_id) REFERENCES public.lendenapp_cohort_config(id);


--
-- TOC entry 9916 (class 2606 OID 20121)
-- Name: lendenapp_convertedreferral fk_convertedreferral_referred_by_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_convertedreferral
    ADD CONSTRAINT fk_convertedreferral_referred_by_id FOREIGN KEY (referred_by_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9917 (class 2606 OID 20126)
-- Name: lendenapp_convertedreferral fk_convertedreferral_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_convertedreferral
    ADD CONSTRAINT fk_convertedreferral_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9908 (class 2606 OID 20131)
-- Name: lendenapp_task fk_created_by_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_task
    ADD CONSTRAINT fk_created_by_id FOREIGN KEY (created_by_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9938 (class 2606 OID 20136)
-- Name: lendenapp_paymentlink fk_created_by_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_paymentlink
    ADD CONSTRAINT fk_created_by_id FOREIGN KEY (created_by_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9964 (class 2606 OID 20141)
-- Name: lendenapp_thirdparty_crif_logs fk_customuser; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_thirdparty_crif_logs
    ADD CONSTRAINT fk_customuser FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9913 (class 2606 OID 20146)
-- Name: lendenapp_customuser_groups fk_customuser_groups_customuser_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser_groups
    ADD CONSTRAINT fk_customuser_groups_customuser_id FOREIGN KEY (customuser_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9914 (class 2606 OID 20151)
-- Name: lendenapp_customuser_groups fk_customuser_groups_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser_groups
    ADD CONSTRAINT fk_customuser_groups_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9990 (class 2606 OID 20156)
-- Name: lendenapp_fmi_withdrawals fk_fmi_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_fmi_withdrawals
    ADD CONSTRAINT fk_fmi_transaction_id FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(transaction_id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9991 (class 2606 OID 20161)
-- Name: lendenapp_fmi_withdrawals fk_fmi_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_fmi_withdrawals
    ADD CONSTRAINT fk_fmi_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9943 (class 2606 OID 20166)
-- Name: lendenapp_userupimandate fk_lenden_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userupimandate
    ADD CONSTRAINT fk_lenden_transaction_id FOREIGN KEY (lenden_transaction_id) REFERENCES public.lendenapp_transaction(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9910 (class 2606 OID 20171)
-- Name: lendenapp_bankaccount fk_mandate_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bankaccount
    ADD CONSTRAINT fk_mandate_id FOREIGN KEY (mandate_id) REFERENCES public.lendenapp_mandate(id);


--
-- TOC entry 9936 (class 2606 OID 20176)
-- Name: lendenapp_partneruserconsentlog fk_partner_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_partneruserconsentlog
    ADD CONSTRAINT fk_partner_id FOREIGN KEY (partner_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9986 (class 2606 OID 20181)
-- Name: lendenapp_cohort_config fk_purpose; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cohort_config
    ADD CONSTRAINT fk_purpose FOREIGN KEY (purpose_id) REFERENCES public.lendenapp_cohort_purpose(id);


--
-- TOC entry 9988 (class 2606 OID 20186)
-- Name: lendenapp_user_cohort_mapping fk_purpose; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_cohort_mapping
    ADD CONSTRAINT fk_purpose FOREIGN KEY (purpose_id) REFERENCES public.lendenapp_cohort_purpose(id);


--
-- TOC entry 9903 (class 2606 OID 20191)
-- Name: lendenapp_channelpartner fk_referred_by_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_channelpartner
    ADD CONSTRAINT fk_referred_by_id FOREIGN KEY (referred_by_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9998 (class 2606 OID 1883472)
-- Name: lendenapp_reward fk_related_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_reward
    ADD CONSTRAINT fk_related_user_source_group_id FOREIGN KEY (related_user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9934 (class 2606 OID 20196)
-- Name: lendenapp_offline_payment_verification fk_request_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_verification
    ADD CONSTRAINT fk_request_id FOREIGN KEY (request_id) REFERENCES public.lendenapp_offline_payment_request(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9931 (class 2606 OID 20201)
-- Name: lendenapp_offline_payment_request fk_requested_by_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_request
    ADD CONSTRAINT fk_requested_by_id FOREIGN KEY (requested_by_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9975 (class 2606 OID 20206)
-- Name: lendenapp_track_txn_amount fk_reversal_txn_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_track_txn_amount
    ADD CONSTRAINT fk_reversal_txn_id FOREIGN KEY (reversal_txn_id) REFERENCES public.lendenapp_transaction(id);


--
-- TOC entry 9957 (class 2606 OID 20216)
-- Name: lendenapp_mandatetracker fk_scheme_info_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandatetracker
    ADD CONSTRAINT fk_scheme_info_id FOREIGN KEY (scheme_info_id) REFERENCES public.lendenapp_schemeinfo(id);


--
-- TOC entry 9906 (class 2606 OID 20226)
-- Name: lendenapp_user_source_group fk_source_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_source_group
    ADD CONSTRAINT fk_source_id FOREIGN KEY (source_id) REFERENCES public.lendenapp_source(id);


--
-- TOC entry 9915 (class 2606 OID 20231)
-- Name: lendenapp_customuser_groups fk_source_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_customuser_groups
    ADD CONSTRAINT fk_source_id FOREIGN KEY (source_id) REFERENCES public.lendenapp_source(id);


--
-- TOC entry 9911 (class 2606 OID 20236)
-- Name: lendenapp_bankaccount fk_task_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bankaccount
    ADD CONSTRAINT fk_task_id FOREIGN KEY (task_id) REFERENCES public.lendenapp_task(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9919 (class 2606 OID 20241)
-- Name: lendenapp_document fk_task_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_document
    ADD CONSTRAINT fk_task_id FOREIGN KEY (task_id) REFERENCES public.lendenapp_task(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9922 (class 2606 OID 20246)
-- Name: lendenapp_userkyc fk_task_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyc
    ADD CONSTRAINT fk_task_id FOREIGN KEY (task_id) REFERENCES public.lendenapp_task(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9925 (class 2606 OID 20251)
-- Name: lendenapp_account fk_task_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account
    ADD CONSTRAINT fk_task_id FOREIGN KEY (task_id) REFERENCES public.lendenapp_task(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9961 (class 2606 OID 20256)
-- Name: lendenapp_nach_presentation fk_transaction; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_nach_presentation
    ADD CONSTRAINT fk_transaction FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id);


--
-- TOC entry 9932 (class 2606 OID 20261)
-- Name: lendenapp_offline_payment_request fk_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_request
    ADD CONSTRAINT fk_transaction_id FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9947 (class 2606 OID 20266)
-- Name: lendenapp_transactionaudit fk_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transactionaudit
    ADD CONSTRAINT fk_transaction_id FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9976 (class 2606 OID 20271)
-- Name: lendenapp_track_txn_amount fk_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_track_txn_amount
    ADD CONSTRAINT fk_transaction_id FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9980 (class 2606 OID 20276)
-- Name: lendenapp_transaction_amount_tracker fk_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_transaction_amount_tracker
    ADD CONSTRAINT fk_transaction_id FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9949 (class 2606 OID 20281)
-- Name: lendenapp_thirdparty_event_logs fk_user; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_event_logs
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id_pk) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9904 (class 2606 OID 20286)
-- Name: lendenapp_channelpartner fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_channelpartner
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9907 (class 2606 OID 20291)
-- Name: lendenapp_user_source_group fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_user_source_group
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9912 (class 2606 OID 20296)
-- Name: lendenapp_bankaccount fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_bankaccount
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9920 (class 2606 OID 20301)
-- Name: lendenapp_document fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_document
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9923 (class 2606 OID 20306)
-- Name: lendenapp_userkyc fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyc
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9926 (class 2606 OID 20311)
-- Name: lendenapp_account fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9982 (class 2606 OID 20316)
-- Name: lendenapp_aml fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_aml
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9984 (class 2606 OID 20321)
-- Name: lendenapp_amltracker fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_amltracker
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9989 (class 2606 OID 20326)
-- Name: lendenapp_user_cohort_mapping fk_user_source_group; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_cohort_mapping
    ADD CONSTRAINT fk_user_source_group FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9946 (class 2606 OID 20331)
-- Name: lendenapp_notification fk_user_source_group_d; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_notification
    ADD CONSTRAINT fk_user_source_group_d FOREIGN KEY (id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9909 (class 2606 OID 20336)
-- Name: lendenapp_task fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_task
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9921 (class 2606 OID 20341)
-- Name: lendenapp_document fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_document
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9924 (class 2606 OID 20346)
-- Name: lendenapp_userkyc fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyc
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9927 (class 2606 OID 20351)
-- Name: lendenapp_account fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_account
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9929 (class 2606 OID 20356)
-- Name: lendenapp_address fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_address
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9930 (class 2606 OID 20361)
-- Name: lendenapp_applicationinfo fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_applicationinfo
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9933 (class 2606 OID 20366)
-- Name: lendenapp_offline_payment_request fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_request
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9937 (class 2606 OID 20371)
-- Name: lendenapp_partneruserconsentlog fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_partneruserconsentlog
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9939 (class 2606 OID 20376)
-- Name: lendenapp_paymentlink fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_paymentlink
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9941 (class 2606 OID 20381)
-- Name: lendenapp_thirdpartydatahyperverge fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartydatahyperverge
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9942 (class 2606 OID 20386)
-- Name: lendenapp_timeline fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_timeline
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9944 (class 2606 OID 20391)
-- Name: lendenapp_userupimandate fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userupimandate
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9945 (class 2606 OID 20396)
-- Name: lendenapp_thirdpartycashfree fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdpartycashfree
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9940 (class 2606 OID 20401)
-- Name: lendenapp_thirdparty_clevertap_logs fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_thirdparty_clevertap_logs
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9948 (class 2606 OID 20406)
-- Name: lendenapp_userkyctracker fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_userkyctracker
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9951 (class 2606 OID 20411)
-- Name: lendenapp_ckycthirdpartydata fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_ckycthirdpartydata
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9952 (class 2606 OID 20416)
-- Name: lendenapp_investorutminfo fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_investorutminfo
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9953 (class 2606 OID 20421)
-- Name: fcm_django_fcmdevice fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.fcm_django_fcmdevice
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9965 (class 2606 OID 20426)
-- Name: lendenapp_app_rating fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_app_rating
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9977 (class 2606 OID 20431)
-- Name: lendenapp_track_txn_amount fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_track_txn_amount
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9978 (class 2606 OID 20436)
-- Name: lendenapp_txn_activity_log fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_txn_activity_log
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9981 (class 2606 OID 20441)
-- Name: lendenapp_transaction_amount_tracker fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_transaction_amount_tracker
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9983 (class 2606 OID 20446)
-- Name: lendenapp_aml fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_aml
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9985 (class 2606 OID 20451)
-- Name: lendenapp_amltracker fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_amltracker
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9993 (class 2606 OID 20456)
-- Name: lendenapp_address_v2 fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_address_v2
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 10000 (class 2606 OID 1883457)
-- Name: lendenapp_campaign_wallet fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_campaign_wallet
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9999 (class 2606 OID 1883462)
-- Name: lendenapp_reward fk_user_source_group_id; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_reward
    ADD CONSTRAINT fk_user_source_group_id FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9935 (class 2606 OID 20461)
-- Name: lendenapp_offline_payment_verification fk_verified_by_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_offline_payment_verification
    ADD CONSTRAINT fk_verified_by_id FOREIGN KEY (verified_by_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9950 (class 2606 OID 20466)
-- Name: lendenapp_communicationpreference lendenapp_communica_user_id_e9fb3209_fk_lendenapp_customuser_id; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_communicationpreference
    ADD CONSTRAINT lendenapp_communica_user_id_e9fb3209_fk_lendenapp_customuser_id FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9994 (class 2606 OID 1875192)
-- Name: lendenapp_cp_staff lendenapp_cp_staff_channel_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff
    ADD CONSTRAINT lendenapp_cp_staff_channel_partner_id_fkey FOREIGN KEY (channel_partner_id) REFERENCES public.lendenapp_channelpartner(id);


--
-- TOC entry 9995 (class 2606 OID 1875202)
-- Name: lendenapp_cp_staff lendenapp_cp_staff_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff
    ADD CONSTRAINT lendenapp_cp_staff_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9996 (class 2606 OID 1875197)
-- Name: lendenapp_cp_staff lendenapp_cp_staff_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_cp_staff
    ADD CONSTRAINT lendenapp_cp_staff_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.lendenapp_customuser(id);


--
-- TOC entry 9959 (class 2606 OID 20471)
-- Name: lendenapp_mandate lendenapp_mandate_mandate_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandate
    ADD CONSTRAINT lendenapp_mandate_mandate_tracker_id_fkey FOREIGN KEY (mandate_tracker_id) REFERENCES public.lendenapp_mandatetracker(id);


--
-- TOC entry 9960 (class 2606 OID 20476)
-- Name: lendenapp_mandate lendenapp_mandate_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandate
    ADD CONSTRAINT lendenapp_mandate_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9958 (class 2606 OID 20481)
-- Name: lendenapp_mandatetracker lendenapp_mandatetracker_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_mandatetracker
    ADD CONSTRAINT lendenapp_mandatetracker_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9972 (class 2606 OID 20486)
-- Name: lendenapp_otl_scheme_loan_mapping_v2 lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_v2
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey FOREIGN KEY (otl_tracker_id) REFERENCES public.lendenapp_otl_scheme_tracker(id);


--
-- TOC entry 9973 (class 2606 OID 20491)
-- Name: lendenapp_otl_scheme_loan_mapping_v3 lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_v3
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey FOREIGN KEY (otl_tracker_id) REFERENCES public.lendenapp_otl_scheme_tracker(id);


--
-- TOC entry 9974 (class 2606 OID 20496)
-- Name: lendenapp_otl_scheme_loan_mapping_old lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_loan_mapping_old
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey FOREIGN KEY (otl_tracker_id) REFERENCES public.lendenapp_otl_scheme_tracker(id);


--
-- TOC entry 9992 (class 2606 OID 20501)
-- Name: lendenapp_otl_scheme_loan_mapping lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE public.lendenapp_otl_scheme_loan_mapping
    ADD CONSTRAINT lendenapp_otl_scheme_loan_mapping_otl_tracker_id_fkey FOREIGN KEY (otl_tracker_id) REFERENCES public.lendenapp_otl_scheme_tracker(id);


--
-- TOC entry 9970 (class 2606 OID 20578)
-- Name: lendenapp_otl_scheme_tracker lendenapp_otl_scheme_tracker_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_tracker
    ADD CONSTRAINT lendenapp_otl_scheme_tracker_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id);


--
-- TOC entry 9971 (class 2606 OID 20583)
-- Name: lendenapp_otl_scheme_tracker lendenapp_otl_scheme_tracker_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_otl_scheme_tracker
    ADD CONSTRAINT lendenapp_otl_scheme_tracker_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9979 (class 2606 OID 20588)
-- Name: lendenapp_user_metadata lendenapp_passcode_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_user_metadata
    ADD CONSTRAINT lendenapp_passcode_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9962 (class 2606 OID 20593)
-- Name: lendenapp_nach_presentation lendenapp_scheme_reinvestment_scheme_info_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_nach_presentation
    ADD CONSTRAINT lendenapp_scheme_reinvestment_scheme_info_id_fkey FOREIGN KEY (scheme_info_id) REFERENCES public.lendenapp_schemeinfo(id);


--
-- TOC entry 9963 (class 2606 OID 20598)
-- Name: lendenapp_nach_presentation lendenapp_scheme_reinvestment_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_nach_presentation
    ADD CONSTRAINT lendenapp_scheme_reinvestment_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9966 (class 2606 OID 20603)
-- Name: lendenapp_scheme_repayment_details lendenapp_scheme_repayment_detai_withdrawal_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details
    ADD CONSTRAINT lendenapp_scheme_repayment_detai_withdrawal_transaction_id_fkey FOREIGN KEY (withdrawal_transaction_id) REFERENCES public.lendenapp_transaction(id);


--
-- TOC entry 9967 (class 2606 OID 20608)
-- Name: lendenapp_scheme_repayment_details lendenapp_scheme_repayment_details_repayment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details
    ADD CONSTRAINT lendenapp_scheme_repayment_details_repayment_id_fkey FOREIGN KEY (repayment_id) REFERENCES public.lendenapp_transaction(id);


--
-- TOC entry 9968 (class 2606 OID 20613)
-- Name: lendenapp_scheme_repayment_details lendenapp_scheme_repayment_details_scheme_reinvestment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details
    ADD CONSTRAINT lendenapp_scheme_repayment_details_scheme_reinvestment_id_fkey FOREIGN KEY (scheme_reinvestment_id) REFERENCES public.lendenapp_nach_presentation(id);


--
-- TOC entry 9969 (class 2606 OID 20618)
-- Name: lendenapp_scheme_repayment_details lendenapp_scheme_repayment_details_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.lendenapp_scheme_repayment_details
    ADD CONSTRAINT lendenapp_scheme_repayment_details_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9955 (class 2606 OID 20623)
-- Name: lendenapp_schemeinfo lendenapp_schemeinfo_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_schemeinfo
    ADD CONSTRAINT lendenapp_schemeinfo_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.lendenapp_transaction(id);


--
-- TOC entry 9956 (class 2606 OID 20628)
-- Name: lendenapp_schemeinfo lendenapp_schemeinfo_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_schemeinfo
    ADD CONSTRAINT lendenapp_schemeinfo_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 9918 (class 2606 OID 20633)
-- Name: lendenapp_transaction lendenapp_transaction_task_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: usrinvoswrt
--

ALTER TABLE ONLY public.lendenapp_transaction
    ADD CONSTRAINT lendenapp_transaction_task_id_fk FOREIGN KEY (task_id) REFERENCES public.lendenapp_task(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 9954 (class 2606 OID 20638)
-- Name: reverse_penny_drop reverse_penny_drop_user_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: devmultilenden
--

ALTER TABLE ONLY public.reverse_penny_drop
    ADD CONSTRAINT reverse_penny_drop_user_source_group_id_fkey FOREIGN KEY (user_source_group_id) REFERENCES public.lendenapp_user_source_group(id);


--
-- TOC entry 10157 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: devmultilenden
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 10166 (class 0 OID 0)
-- Dependencies: 753
-- Name: TABLE lendenap_user_states_final; Type: ACL; Schema: public; Owner: devmultilenden
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lendenap_user_states_final TO usrinvoswrt;


--
-- TOC entry 10174 (class 0 OID 0)
-- Dependencies: 749
-- Name: TABLE lendenapp_app_rating; Type: ACL; Schema: public; Owner: devmultilenden
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lendenapp_app_rating TO usrinvoswrt;


--
-- TOC entry 10188 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE lendenapp_convertedreferral; Type: ACL; Schema: public; Owner: usrinvoswrt
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lendenapp_convertedreferral TO devmultilenden;


-- Completed on 2025-06-13 15:12:58

--
-- PostgreSQL database dump complete
--

