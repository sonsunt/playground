-- SCD Type 2 Implementation
DROP TABLE IF EXISTS smalltest.vendor;
CREATE TABLE smalltest.vendor 
	(id SERIAL,
	 seller_id VARCHAR NOT NULL,
	 seller_zip_code VARCHAR NOT NULL,
	 seller_city VARCHAR NOT NULL,
	 seller_state VARCHAR NOT NULL,
	 start_ts TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	 end_ts TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 	 is_current BOOLEAN DEFAULT TRUE NOT NULL,
	 CONSTRAINT id_pk PRIMARY KEY (id),
	 CONSTRAINT vendor_unique_key UNIQUE (seller_id, seller_zip_code, seller_city, seller_state)
	);
		
		
-- Multiple rows insert
-- There are two sub steps involved. First step is insert records in the live schema, which is the OLTP or data source.
-- The table UNIQUE constraint will check if the dimensions are entirely new to the table. If yes, insert the dimension, dismiss the record otherwise.
-- After that, the after-added dimension table is checked against the data source. 
-- If the dimension table has non-current record, then the is_current column will update to FALSE, and end_ts is updated to current time.

INSERT INTO smalltest.vendor (seller_id, seller_zip_code, seller_city, seller_state, start_ts, end_ts)
	(SELECT seller_id, 
	 		seller_zip_code, 
	 		seller_city, 
	 		seller_state,
			NOW() AS start_ts,
			'2999-12-31' AS end_ts
	FROM	live.seller)
	ON CONFLICT ON CONSTRAINT vendor_unique_key DO NOTHING;
UPDATE smalltest.vendor
	SET is_current = FALSE,
		end_ts = NOW()
	WHERE id IN (SELECT id
					FROM smalltest.vendor t
				 	JOIN live.seller l ON l.seller_id = t.seller_id
					WHERE t.is_current = TRUE
					AND (l.seller_zip_code, l.seller_city, l.seller_state) <> (t.seller_zip_code, t.seller_city, t.seller_state));
