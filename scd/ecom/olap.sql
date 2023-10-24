-- SCD Type 2 Implementation on PostgreSQL 14
DROP TABLE IF EXISTS staging.dim_seller;
DROP TABLE IF EXISTS staging.dim_user;
DROP TABLE IF EXISTS staging.dim_feedback;
DROP TABLE IF EXISTS staging.dim_product;

DROP TABLE IF EXISTS staging.fct_order_items;
DROP TABLE IF EXISTS staging.dim_date;
DROP TABLE IF EXISTS staging.dim_time;
DROP TABLE IF EXISTS staging.dim_geo;

DROP TABLE IF EXISTS staging.dim_seller;
DROP TABLE IF EXISTS staging.dim_user;
DROP TABLE IF EXISTS staging.dim_feedback;
DROP TABLE IF EXISTS staging.dim_product;

CREATE TABLE staging.dim_seller
	(id SERIAL PRIMARY KEY,
	 "seller_id" VARCHAR NOT NULL,
	 "seller_zip_code" VARCHAR NOT NULL,
	 "seller_city" VARCHAR NOT NULL,
	 "seller_state" VARCHAR NOT NULL,
	 "start_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	 "end_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 	 "is_current" BOOLEAN DEFAULT TRUE NOT NULL,
	 CONSTRAINT "seller_unique_key" UNIQUE ("seller_id", "seller_zip_code", "seller_city", "seller_state")
	);

CREATE TABLE staging.dim_user 
	("id" SERIAL PRIMARY KEY,
	 "user_name" VARCHAR NOT NULL,
	 "customer_zip_code" VARCHAR NOT NULL,
	 "customer_city" VARCHAR NOT NULL,
	 "customer_state" VARCHAR NOT NULL,
	 "start_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	 "end_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 	 "is_current" BOOLEAN DEFAULT TRUE NOT NULL,
	 CONSTRAINT "user_unique_key" UNIQUE ("user_name", "customer_zip_code", "customer_city", "customer_state")
	);

CREATE TABLE staging.dim_feedback 
	("id" SERIAL,
	 "feedback_id" VARCHAR NOT NULL,
	 "order_id" VARCHAR NOT NULL,
	 "feedback_score" INTEGER NOT NULL,
	 "feedback_form_sent_date" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
     "feedback_answer_date" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	 "start_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	 "end_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 	 "is_current" BOOLEAN DEFAULT TRUE NOT NULL,
	 CONSTRAINT "id_pk" PRIMARY KEY ("id"),
	 CONSTRAINT "property_unique_key" UNIQUE ("feedback_id", "order_id", "feedback_score", "feedback_form_sent_date", "feedback_answer_date")
	);

CREATE TABLE staging.dim_product 
	("id" SERIAL PRIMARY KEY,
	 "product_id" VARCHAR NOT NULL,
	 "product_category" VARCHAR NOT NULL,
	 "product_name_lenght" DECIMAL NOT NULL,
	 "product_description_lenght" DECIMAL NOT NULL,
     "product_photos_qty" DECIMAL NOT NULL,
     "product_weight_g" DECIMAL NOT NULL,
     "product_length_cm" DECIMAL NOT NULL,
     "product_height_cm" DECIMAL NOT NULL,
     "product_width_cm" DECIMAL NOT NULL,
	 "start_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	 "end_ts" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 	 "is_current" BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT "product_unique_key" UNIQUE ("product_id", "product_category", "product_name_lenght", "product_description_lenght", "product_photos_qty", 
                                          "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm")
	);

CREATE TABLE staging.dim_date 
  ("date_id" SERIAL PRIMARY KEY,
  "date" DATE,
  "day_name" VARCHAR,
  "day_of_week" INTEGER,
  "day_of_month" INTEGER,
  "day_of_quarter" INTEGER,
  "day_of_year" DECIMAL,
  "week_of_month" INTEGER,
  "week_of_year" DECIMAL,
  "month_actual" DECIMAL,
  "month_name" VARCHAR,
  "month_name_abbreviated" VARCHAR,
  "quarter" DECIMAL,
  "year" DECIMAL,
  "isWeekend" BOOLEAN
);

CREATE TABLE staging.dim_time (
  "time_id" INTEGER PRIMARY KEY,
  "hour" INTEGER,
  "quarter_hour" varchar,
  "minute" smallint,
  "daytime" varchar,
  "daynight" varchar
);

CREATE TABLE staging.dim_geo (
  "geo_id" serial PRIMARY KEY,
  "city" varchar,
  "state" varchar,
  "long" decimal,
  "lat" decimal
);

-- Multiple rows insert
-- There are two sub steps involved. First step is insert records in the live schema, which is the OLTP or data source.
-- The table UNIQUE constraint will check if the dimensions are entirely new to the table. If yes, insert the dimension, dismiss the record otherwise.
-- After that, the after-added dimension table is checked against the data source. 
-- If the dimension table has non-current record, then the is_current column will update to FALSE, and end_ts is updated to current time.

INSERT INTO staging.vendor (seller_id, seller_zip_code, seller_city, seller_state, start_ts, end_ts)
	(SELECT seller_id, 
	 		seller_zip_code, 
	 		seller_city, 
	 		seller_state,
			NOW() AS start_ts,
			'2999-12-31' AS end_ts
	FROM	live.seller)
	ON CONFLICT ON CONSTRAINT vendor_unique_key DO NOTHING;
UPDATE staging.vendor
	SET is_current = FALSE,
		end_ts = NOW()
	WHERE id IN (SELECT id
					FROM smalltest.vendor t
				 	JOIN live.seller l ON l.seller_id = t.seller_id
					WHERE t.is_current = TRUE
					AND (l.seller_zip_code, l.seller_city, l.seller_state) <> (t.seller_zip_code, t.seller_city, t.seller_state));
