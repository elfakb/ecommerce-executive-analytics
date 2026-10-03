-- ============================================================
-- Cost assumptions (ESTIMATES, not real data).
-- Profit = price - price*cogs_rate - freight_value*freight_absorbed_share
-- ============================================================

-- Two categories missing from the translation file
INSERT INTO product_category_translation VALUES
 ('pc_gamer', 'pc_gamer'),
 ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_preparers')
ON CONFLICT DO NOTHING;

DROP TABLE IF EXISTS cost_parameters;
CREATE TABLE cost_parameters (
    param_name  TEXT PRIMARY KEY,
    param_value NUMERIC(6,3) NOT NULL,
    description TEXT
);

INSERT INTO cost_parameters VALUES
 ('default_cogs_rate',      0.650, 'COGS share of price for categories without a specific rate'),
 ('cogs_multiplier',        1.000, 'Scenario knob: 1.10 = all COGS rates 10% higher (sensitivity analysis)'),
 ('freight_absorbed_share', 1.000, 'Share of freight_value borne by the company (0 to 1)');

DROP TABLE IF EXISTS category_cost_assumptions;
CREATE TABLE category_cost_assumptions (
    category_english TEXT PRIMARY KEY,
    cogs_rate        NUMERIC(4,3) NOT NULL CHECK (cogs_rate BETWEEN 0 AND 1),
    rationale        TEXT
);

INSERT INTO category_cost_assumptions VALUES
 ('computers',                0.780, 'Commoditized electronics'),
 ('computers_accessories',    0.700, 'Commoditized electronics'),
 ('electronics',              0.750, 'Commoditized electronics'),
 ('telephony',                0.720, 'Commoditized electronics'),
 ('tablets_printing_image',   0.750, 'Commoditized electronics'),
 ('consoles_games',           0.750, 'Low-margin gaming hardware'),
 ('small_appliances',         0.740, 'Appliances'),
 ('home_appliances',          0.740, 'Appliances'),
 ('air_conditioning',         0.740, 'Appliances'),
 ('auto',                     0.700, 'Auto parts'),
 ('food_drink',               0.750, 'Low-margin grocery-like'),
 ('baby',                     0.680, 'Mid margin'),
 ('bed_bath_table',           0.620, 'Home textile'),
 ('housewares',               0.620, 'Home goods'),
 ('furniture_decor',          0.600, 'Furniture'),
 ('office_furniture',         0.600, 'Furniture'),
 ('garden_tools',             0.620, 'Tools'),
 ('sports_leisure',           0.620, 'Sports'),
 ('toys',                     0.640, 'Toys'),
 ('pet_shop',                 0.640, 'Pet supplies'),
 ('stationery',               0.600, 'Stationery'),
 ('health_beauty',            0.500, 'Beauty and personal care'),
 ('perfumery',                0.480, 'Beauty and personal care'),
 ('watches_gifts',            0.520, 'Gift items'),
 ('cool_stuff',               0.520, 'Gift items'),
 ('fashion_bags_accessories', 0.500, 'Fashion'),
 ('luggage_accessories',      0.550, 'Fashion/accessories'),
 ('books_general_interest',   0.600, 'Books');
