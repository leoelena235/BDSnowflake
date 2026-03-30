INSERT INTO dim_country (country_name)
SELECT DISTINCT country_name
FROM (
    SELECT NULLIF(customer_country, '') AS country_name FROM public.mock_data
    UNION
    SELECT NULLIF(seller_country, '') FROM public.mock_data
    UNION
    SELECT NULLIF(store_country, '') FROM public.mock_data
    UNION
    SELECT NULLIF(supplier_country, '') FROM public.mock_data
) t
WHERE country_name IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO dim_pet (pet_type, pet_name, pet_breed)
SELECT DISTINCT
    NULLIF(customer_pet_type, ''),
    NULLIF(customer_pet_name, ''),
    NULLIF(customer_pet_breed, '')
FROM public.mock_data
ON CONFLICT (pet_type, pet_name, pet_breed) DO NOTHING;

INSERT INTO dim_customer (
    source_customer_id,
    first_name,
    last_name,
    age,
    email,
    postal_code,
    country_sk,
    pet_sk
)
SELECT DISTINCT
    m.sale_customer_id,
    m.customer_first_name,
    m.customer_last_name,
    m.customer_age,
    m.customer_email,
    m.customer_postal_code,
    c.country_sk,
    p.pet_sk
FROM public.mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(m.customer_country, '')
LEFT JOIN dim_pet p
    ON p.pet_type  = NULLIF(m.customer_pet_type, '')
   AND p.pet_name  = NULLIF(m.customer_pet_name, '')
   AND p.pet_breed = NULLIF(m.customer_pet_breed, '')
WHERE m.sale_customer_id IS NOT NULL
ON CONFLICT (source_customer_id) DO NOTHING;

INSERT INTO dim_seller (
    source_seller_id,
    first_name,
    last_name,
    email,
    postal_code,
    country_sk
)
SELECT DISTINCT
    m.sale_seller_id,
    m.seller_first_name,
    m.seller_last_name,
    m.seller_email,
    m.seller_postal_code,
    c.country_sk
FROM public.mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(m.seller_country, '')
WHERE m.sale_seller_id IS NOT NULL
ON CONFLICT (source_seller_id) DO NOTHING;

INSERT INTO dim_supplier (
    supplier_name,
    contact_person,
    email,
    phone,
    address,
    city,
    country_sk
)
SELECT DISTINCT
    m.supplier_name,
    m.supplier_contact,
    m.supplier_email,
    m.supplier_phone,
    m.supplier_address,
    m.supplier_city,
    c.country_sk
FROM public.mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(m.supplier_country, '')
WHERE m.supplier_email IS NOT NULL
ON CONFLICT (email) DO NOTHING;

INSERT INTO dim_store (
    store_name,
    location,
    city,
    state,
    country_sk,
    phone,
    email
)
SELECT DISTINCT
    m.store_name,
    m.store_location,
    m.store_city,
    NULLIF(m.store_state, ''),
    c.country_sk,
    m.store_phone,
    m.store_email
FROM public.mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(m.store_country, '')
ON CONFLICT (store_name, location, city, state, phone, email) DO NOTHING;

INSERT INTO dim_product_category (product_category_name)
SELECT DISTINCT NULLIF(product_category, '')
FROM public.mock_data
ON CONFLICT (product_category_name) DO NOTHING;

INSERT INTO dim_pet_category (pet_category_name)
SELECT DISTINCT NULLIF(pet_category, '')
FROM public.mock_data
ON CONFLICT (pet_category_name) DO NOTHING;

INSERT INTO dim_product (
    source_product_id,
    product_name,
    product_category_sk,
    pet_category_sk,
    product_price,
    product_quantity,
    product_weight,
    product_color,
    product_size,
    product_brand,
    product_material,
    product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date
)
SELECT DISTINCT
    m.sale_product_id,
    m.product_name,
    pc.product_category_sk,
    pt.pet_category_sk,
    m.product_price,
    m.product_quantity,
    m.product_weight,
    m.product_color,
    m.product_size,
    m.product_brand,
    m.product_material,
    m.product_description,
    m.product_rating,
    m.product_reviews,
    m.product_release_date,
    m.product_expiry_date
FROM public.mock_data m
LEFT JOIN dim_product_category pc
    ON pc.product_category_name = NULLIF(m.product_category, '')
LEFT JOIN dim_pet_category pt
    ON pt.pet_category_name = NULLIF(m.pet_category, '')
WHERE m.sale_product_id IS NOT NULL
ON CONFLICT (source_product_id) DO NOTHING;

INSERT INTO dim_date (
    full_date,
    day_of_month,
    month_num,
    month_name,
    quarter_num,
    year_num,
    day_of_week_num,
    day_of_week_name
)
SELECT DISTINCT
    m.sale_date,
    EXTRACT(DAY FROM m.sale_date)::SMALLINT,
    EXTRACT(MONTH FROM m.sale_date)::SMALLINT,
    TO_CHAR(m.sale_date, 'Month'),
    EXTRACT(QUARTER FROM m.sale_date)::SMALLINT,
    EXTRACT(YEAR FROM m.sale_date)::INTEGER,
    EXTRACT(ISODOW FROM m.sale_date)::SMALLINT,
    TO_CHAR(m.sale_date, 'Day')
FROM public.mock_data m
WHERE m.sale_date IS NOT NULL
ON CONFLICT (full_date) DO NOTHING;

INSERT INTO fact_sale (
    source_id,
    date_sk,
    customer_sk,
    seller_sk,
    product_sk,
    store_sk,
    supplier_sk,
    sale_quantity,
    sale_total_price
)
SELECT
    m.id,
    d.date_sk,
    c.customer_sk,
    s.seller_sk,
    p.product_sk,
    st.store_sk,
    sp.supplier_sk,
    m.sale_quantity,
    m.sale_total_price
FROM public.mock_data m
LEFT JOIN dim_date d
    ON d.full_date = m.sale_date
LEFT JOIN dim_customer c
    ON c.source_customer_id = m.sale_customer_id
LEFT JOIN dim_seller s
    ON s.source_seller_id = m.sale_seller_id
LEFT JOIN dim_product p
    ON p.source_product_id = m.sale_product_id
LEFT JOIN dim_store st
    ON st.store_name = m.store_name
   AND st.location   = m.store_location
   AND st.city       = m.store_city
   AND st.state      = NULLIF(m.store_state, '')
   AND st.phone      = m.store_phone
   AND st.email      = m.store_email
LEFT JOIN dim_supplier sp
    ON sp.email = m.supplier_email;
