use madrid_metro;

-- Drop existing tables in reverse order of dependency
DROP TABLE IF EXISTS receives, buys, makes, monthly_card, multi_use_card, transactions, customer, address, discount, price_matrix;

-- Create all tables
CREATE TABLE address (
    zip_code INT NOT NULL,
    city VARCHAR(100) NOT NULL,
    zone VARCHAR(3) NOT NULL,
    PRIMARY KEY (zip_code)
);

-- Create customer table
CREATE TABLE customer (
    customer_id INT auto_increment,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    age_group VARCHAR(20) not null,
    zip_code INT NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(100) NOT NULL,
    student_status boolean not null,
    disability_status BOOLEAN NOT NULL,
    family_normal_status BOOLEAN NOT NULL,
    family_special_status BOOLEAN NOT NULL,
    PRIMARY KEY (customer_id),
    FOREIGN KEY (zip_code) REFERENCES address(zip_code)
);

-- Trigger on insert to assign a customer's age group based on date of birth
DELIMITER $$
CREATE TRIGGER age_group_insert
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    DECLARE new_age INT;
    SET new_age = TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE());
    IF new_age < 26 OR NEW.student_status = TRUE THEN
        SET NEW.age_group = 'Youth/Student';
    ELSEIF new_age >= 65 THEN
        SET NEW.age_group = 'Senior';
    ELSE
        SET NEW.age_group = 'Normal';
    END IF;
END$$
DELIMITER ;

-- Trigger on update to assign a customer's age group based on date of birth
DELIMITER $$
CREATE TRIGGER age_group_update
BEFORE update ON customer
FOR EACH ROW
BEGIN
    DECLARE new_age INT;
    SET new_age = TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE());
    IF new_age < 26 OR NEW.student_status = TRUE THEN
        SET NEW.age_group = 'Youth/Student';
    ELSEIF new_age >= 65 THEN
        SET NEW.age_group = 'Senior';
    ELSE
        SET NEW.age_group = 'Normal';
    END IF;
END$$
DELIMITER ;

-- Price matrix containing the base price for a given zone and age group
create table price_matrix (
	zone varchar(3) not null,
    age_group varchar(20) not null,
    price float not null,
    primary key(zone, age_group)
);

-- Create special discount table
CREATE TABLE discount (
    type_of_discount VARCHAR(25) NOT NULL,
    percent_discount INT NOT NULL,
    PRIMARY KEY (type_of_discount)
);

-- Create monthly card table
CREATE TABLE monthly_card (
    card_id INT AUTO_INCREMENT,
    customer_id INT NOT NULL,
    validity BOOLEAN NOT NULL,
    date_last_charge DATE,
    PRIMARY KEY (card_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- Trigger on insert to determine whether a monthly card is valid
DELIMITER $$
CREATE TRIGGER check_card_validity_insert
BEFORE insert ON monthly_card
FOR EACH ROW
BEGIN
    -- Check if the last charge date is more than 30 days old
    IF DATEDIFF(CURDATE(), NEW.date_last_charge) > 30 THEN
        SET NEW.validity = FALSE;
    ELSE
        SET NEW.validity = TRUE;
    END IF;
END$$
DELIMITER ; 

-- Trigger on update to determine whether a monthly card is valid
DELIMITER $$
CREATE TRIGGER check_card_validity_update
BEFORE update ON monthly_card
FOR EACH ROW
BEGIN
    IF DATEDIFF(CURDATE(), NEW.date_last_charge) > 30 THEN
        SET NEW.validity = FALSE;
    ELSE
        SET NEW.validity = TRUE;
    END IF;
END$$
DELIMITER ; 

-- Create multi use card table
CREATE TABLE multi_use_card (
    card_id INT AUTO_INCREMENT,
    customer_id INT NOT NULL,
    balance FLOAT NOT NULL,
    PRIMARY KEY (card_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- Create transactions table
CREATE TABLE transactions (
    transaction_id INT auto_increment,
    transaction_type VARCHAR(20) NOT NULL,
    transaction_date date not null,
    amount FLOAT NOT NULL,
    PRIMARY KEY (transaction_id)
);

-- Create buys table
CREATE TABLE buys (
    customer_id INT NOT NULL,
    monthly_card_id INT unique,
    multi_use_card_id INT unique,
    PRIMARY KEY (customer_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (monthly_card_id) REFERENCES monthly_card(card_id),
    FOREIGN KEY (multi_use_card_id) REFERENCES multi_use_card(card_id)
);

-- Create makes table
CREATE TABLE makes (
    transaction_id INT NOT NULL,
    monthly_card_id INT,
    multi_card_id INT,
    PRIMARY KEY (transaction_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (monthly_card_id) REFERENCES monthly_card(card_id),
    FOREIGN KEY (multi_card_id) REFERENCES multi_use_card(card_id)
);

-- Create receives table
CREATE TABLE receives (
    customer_id INT NOT NULL,
    type_of_discount VARCHAR(25) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (type_of_discount) REFERENCES discount(type_of_discount),
    PRIMARY KEY (customer_id, type_of_discount)
);

-- Procedure to register a new customer and add them into the database
DELIMITER $$
DROP PROCEDURE IF EXISTS RegisterNewCustomer;
CREATE PROCEDURE `RegisterNewCustomer`(
    IN p_full_name VARCHAR(100),
    IN p_date_of_birth DATE,
    IN p_zip_code INT,
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(100),
    IN p_student_status BOOLEAN,
    IN p_disability_status BOOLEAN,
    IN p_family_normal_status BOOLEAN,
    IN p_family_special_status BOOLEAN
)
BEGIN
    INSERT INTO customer (
        full_name, 
        date_of_birth, 
        zip_code, 
        email, 
        phone_number, 
        student_status, 
        disability_status, 
        family_normal_status, 
        family_special_status
    ) 
    VALUES (
        p_full_name, 
        p_date_of_birth, 
        p_zip_code, 
        p_email, 
        p_phone_number, 
        p_student_status, 
        p_disability_status, 
        p_family_normal_status, 
        p_family_special_status
    );
END$$
DELIMITER ;

-- Insert prices into price matrix
INSERT INTO price_matrix (zone, age_group, price) VALUES
	('A', 'Normal', 54.60),
    ('B1', 'Normal', 63.70),
    ('B2', 'Normal', 72.00),
    ('B3', 'Normal', 82.00),
    ('C1', 'Normal', 89.50),
    ('C2', 'Normal', 99.30),
    ('A', 'Youth/Student', 20.00),
    ('B1', 'Youth/Student', 20.00),
    ('B2', 'Youth/Student', 20.00),
    ('B3', 'Youth/Student', 20.00),
    ('C1', 'Youth/Student', 20.00),
    ('C2', 'Youth/Student', 20.00),
    ('A', 'Senior', 6.30),
    ('B1', 'Senior', 6.30),
    ('B2', 'Senior', 6.30),
    ('B3', 'Senior', 6.30),
    ('C1', 'Senior', 6.30),
    ('C2', 'Senior', 6.30);

-- Insert discounts into discount table
INSERT INTO discount (type_of_discount, percent_discount) VALUES
    ('Family Normal', 20),
    ('Family Special', 40),
    ('Disability', 65),
    ('Senior', 65);

-- Trigger to assign discounts in the receives table based on the customer's information
DELIMITER $$
CREATE TRIGGER after_customer_insert
AFTER INSERT ON customer
FOR EACH ROW
BEGIN
    IF NEW.disability_status THEN
        INSERT INTO receives (customer_id, type_of_discount) VALUES (NEW.customer_id, 'Disability');
    END IF;
    IF NEW.family_special_status THEN
        INSERT INTO receives (customer_id, type_of_discount) VALUES (NEW.customer_id, 'Family Special');
    ELSEIF NEW.family_normal_status THEN
        INSERT INTO receives (customer_id, type_of_discount) VALUES (NEW.customer_id, 'Family Normal');
    END IF;
END$$
DELIMITER ;

-- Assign zone A for every zip code in Madrid beginning with 28-
DROP PROCEDURE IF EXISTS PopulateZipCodes;
DELIMITER $$
CREATE PROCEDURE PopulateZipCodes()
BEGIN
    DECLARE i INT DEFAULT 28000;
    WHILE i <= 28099 DO
        -- Inserting example data, you might want to customize the city and zone based on specific conditions
        INSERT INTO address (zip_code, city, zone) VALUES (i, 'Madrid', 'A');
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Insert zip codes for Zone A into the address table
Call PopulateZipCodes();

-- Insert addresses for Zone B1
INSERT INTO address (zip_code, city, zone) VALUES
(28100, 'Alcobendas', 'B1'),
(28101, 'Alcorcón', 'B1'),
(28102, 'Cantoblanco', 'B1'),
(28103, 'Coslada', 'B1'),
(28104, 'Facultad de Informática', 'B1'),
(28105, 'Getafe', 'B1'),
(28106, 'Leganés', 'B1'),
(28107, 'Paracuellos del Jarama', 'B1'),
(28108, 'Pozuelo de Alarcón', 'B1'),
(28109, 'Rivas Vaciamadrid', 'B1'),
(28110, 'San Fernando de Henares', 'B1'),
(28111, 'San Sebastián de los Reyes', 'B1');

-- Insert addresses for Zone B2
INSERT INTO address (zip_code, city, zone) VALUES
(28200, 'Ajalvir', 'B2'),
(28201, 'Belvis y Los Berrocales Urb.', 'B2'),
(28202, 'Boadilla del Monte', 'B2'),
(28203, 'Fuenlabrada', 'B2'),
(28204, 'Fuente del Fresno Urb.', 'B2'),
(28205, 'Las Matas', 'B2'),
(28206, 'Las Rozas de Madrid', 'B2'),
(28207, 'Majadahonda', 'B2'),
(28208, 'Mejorada del Campo', 'B2'),
(28209, 'Móstoles', 'B2'),
(28210, 'Parla', 'B2'),
(28211, 'Pinto', 'B2'),
(28212, 'Torrejón de Ardoz', 'B2'),
(28213, 'Tres Cantos', 'B2'),
(28214, 'Velilla de San Antonio', 'B2'),
(28215, 'Villaviciosa de Odón', 'B2');

-- Insert addresses for Zone B3
INSERT INTO address (zip_code, city, zone) VALUES
(28300, 'Alcalá de Henares', 'B3'),
(28301, 'Algete', 'B3'),
(28302, 'Arganda', 'B3'),
(28303, 'Arroyomolinos', 'B3'),
(28304, 'Brunete', 'B3'),
(28305, 'Ciempozuelos', 'B3'),
(28306, 'Ciudalcampo', 'B3'),
(28307, 'Cobeña', 'B3'),
(28308, 'Collado Villalba', 'B3'),
(28309, 'Colmenar Viejo', 'B3'),
(28310, 'Colmenarejo', 'B3'),
(28311, 'Daganzo de Arriba', 'B3'),
(28312, 'Galapagar', 'B3'),
(28313, 'Griñón', 'B3'),
(28314, 'Hoyo de Manzanares', 'B3'),
(28315, 'Humanes de Madrid', 'B3'),
(28316, 'Loeches', 'B3'),
(28317, 'Moraleja de Enmedio', 'B3'),
(28318, 'Navalcarnero', 'B3'),
(28319, 'San Agustín de Guadalix', 'B3'),
(28320, 'San Martín de la Vega', 'B3'),
(28321, 'Torrejón de la Calzada', 'B3'),
(28322, 'Torrejón de Velasco', 'B3'),
(28323, 'Torrelodones', 'B3'),
(28324, 'Valdemoro', 'B3'),
(28325, 'Villanueva de la Cañada', 'B3'),
(28326, 'Villanueva del Pardillo', 'B3');

-- Insert addresses for Zone C1
INSERT INTO address (zip_code, city, zone) VALUES
(28400, 'El Álamo', 'C1'),
(28401, 'Alpedrete', 'C1'),
(28402, 'Anchuelo', 'C1'),
(28403, 'Aranjuez', 'C1'),
(28404, 'Batres', 'C1'),
(28405, 'Becerril de la Sierra', 'C1'),
(28406, 'El Boalo y entidades de Mataelpino y Cerceda', 'C1'),
(28407, 'Camarma de Esteruelas', 'C1'),
(28408, 'Campo Real', 'C1'),
(28409, 'Casarrubuelos', 'C1'),
(28410, 'Collado-Mediano', 'C1'),
(28411, 'Cubas de la Sagra', 'C1'),
(28412, 'Chinchón', 'C1'),
(28413, 'El Escorial', 'C1'),
(28414, 'Fresno de Torote', 'C1'),
(28415, 'Fuente el Saz de Jarama', 'C1'),
(28416, 'Guadarrama', 'C1'),
(28417, 'Manzanares El Real', 'C1'),
(28418, 'Meco', 'C1'),
(28419, 'El Molar', 'C1'),
(28420, 'Moralzarzal', 'C1'),
(28421, 'Morata de Tajuña', 'C1'),
(28422, 'Pedrezuela', 'C1'),
(28423, 'Perales de Tajuña', 'C1'),
(28424, 'Pozuelo del Rey', 'C1'),
(28425, 'Quijorna', 'C1'),
(28426, 'Ribatejada', 'C1'),
(28427, 'San Lorenzo de El Escorial', 'C1'),
(28428, 'Los Santos de la Humosa', 'C1'),
(28429, 'Serranillos del Valle', 'C1'),
(28430, 'Sevilla la Nueva', 'C1'),
(28431, 'Soto del Real', 'C1'),
(28432, 'Titulcia', 'C1'),
(28433, 'Torres de la Alameda', 'C1'),
(28434, 'Valdeavero', 'C1'),
(28435, 'Valdemorillo', 'C1'),
(28436, 'Valdeolmos-Alalpardo', 'C1'),
(28437, 'Valdetorres de Jarama', 'C1'),
(28438, 'Valverde de Alcalá', 'C1'),
(28439, 'Villaconejos', 'C1'),
(28440, 'Villalbilla', 'C1');

-- Query/procedure to purchase a new monthly card
DROP PROCEDURE IF EXISTS IssueMonthlyCard;
DELIMITER $$
CREATE PROCEDURE `IssueMonthlyCard`(IN customer_id_param INT)
BEGIN
    DECLARE new_card_id INT;
    DECLARE existing_card_count INT;
    SELECT COUNT(*) INTO existing_card_count FROM monthly_card WHERE customer_id = customer_id_param;
    IF existing_card_count = 0 THEN
        INSERT INTO monthly_card (customer_id, validity, date_last_charge)
        VALUES (customer_id_param, TRUE, CURDATE());
        SET new_card_id = LAST_INSERT_ID();
        IF EXISTS (SELECT 1 FROM buys WHERE customer_id = customer_id_param) THEN
            UPDATE buys SET monthly_card_id = new_card_id WHERE customer_id = customer_id_param;
        ELSE
            INSERT INTO buys (customer_id, monthly_card_id) VALUES (customer_id_param, new_card_id);
        END IF;
    ELSE
        SELECT 'Customer already has a monthly card.' AS Message;
    END IF;
END$$
DELIMITER ;

-- Query/procedure to purchase a new multi use card
DROP PROCEDURE IF EXISTS IssueMultiUseCard;
DELIMITER $$
CREATE PROCEDURE `IssueMultiUseCard`(IN customer_id_param INT)
BEGIN
    DECLARE new_card_id INT;
    INSERT INTO multi_use_card (customer_id, balance) VALUES (customer_id_param, 12.00);
    SET new_card_id = LAST_INSERT_ID();
    IF EXISTS (SELECT 1 FROM buys WHERE customer_id = customer_id_param) THEN
        UPDATE buys SET multi_use_card_id = new_card_id WHERE customer_id = customer_id_param;
    ELSE
        INSERT INTO buys (customer_id, multi_use_card_id) VALUES (customer_id_param, new_card_id);
    END IF;
END$$
DELIMITER ;

-- Query/procedure to reload a multi-use metrocard
DELIMITER $$
DROP PROCEDURE IF EXISTS ReloadMultiUseCard;
CREATE PROCEDURE `ReloadMultiUseCard`(IN card_id_param INT, IN amount DECIMAL(10,2))
BEGIN
    DECLARE current_balance DECIMAL(10,2);
    DECLARE new_balance DECIMAL(10,2);
    DECLARE new_transaction_id INT;
    DECLARE transaction_date DATE;
    SET transaction_date = CURDATE();
    IF amount < 1.7 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The minimum reload amount is 1.7 euros.';
    END IF;
    SELECT balance INTO current_balance
    FROM multi_use_card
    WHERE card_id = card_id_param;
    SET new_balance = current_balance + amount;
    UPDATE multi_use_card
    SET balance = new_balance
    WHERE card_id = card_id_param;
	INSERT INTO transactions(transaction_type, amount, transaction_date)
	VALUES('Reload Multi', amount, CURDATE());
    SET new_transaction_id = LAST_INSERT_ID();
    INSERT INTO makes(transaction_id, multi_card_id)
    VALUES(new_transaction_id, card_id_param);
END$$
DELIMITER ;

-- Query/procedure to replace a monthly metrocard
DROP PROCEDURE IF EXISTS ReplaceMonthlyCard;
DELIMITER $$
CREATE PROCEDURE `ReplaceMonthlyCard`(IN customer_id_param INT)
BEGIN
    DECLARE old_card_id INT;
    SELECT card_id INTO old_card_id FROM monthly_card WHERE customer_id = customer_id_param LIMIT 1;
    IF old_card_id IS NOT NULL THEN
        DELETE FROM makes WHERE monthly_card_id = old_card_id;
        UPDATE buys SET monthly_card_id = NULL WHERE customer_id = customer_id_param;
        DELETE FROM monthly_card WHERE card_id = old_card_id;
        CALL IssueMonthlyCard(customer_id_param);
        SELECT 'Monthly card replaced successfully.' AS Message;
    ELSE
        SELECT 'No monthly card found for this customer.' AS Message;
    END IF;
END$$
DELIMITER ;

-- Query/procedure to replace a multi-use metrocard
DROP PROCEDURE IF EXISTS ReplaceMultiUseCard;
DELIMITER $$
CREATE PROCEDURE `ReplaceMultiUseCard`(IN customer_id_param INT)
BEGIN
    DECLARE old_card_id INT;
    DECLARE old_balance FLOAT;
    DECLARE new_card_id INT;
    SELECT card_id, balance INTO old_card_id, old_balance FROM multi_use_card 
    WHERE customer_id = customer_id_param ORDER BY card_id DESC LIMIT 1;
        IF old_card_id IS NOT NULL THEN
        DELETE FROM makes WHERE multi_card_id = old_card_id;
        DELETE FROM buys WHERE multi_use_card_id = old_card_id;
        DELETE FROM multi_use_card WHERE card_id = old_card_id;
        INSERT INTO multi_use_card (customer_id, balance) 
        VALUES (customer_id_param, old_balance);
        SET new_card_id = LAST_INSERT_ID();
        INSERT INTO buys (customer_id, multi_use_card_id)
        VALUES (customer_id_param, new_card_id);
        SELECT 'Multi-use card replaced successfully, balance transferred.' AS Message;
    ELSE
        SELECT 'No multi-use card found for this customer.' AS Message;
    END IF;
END$$
DELIMITER ;

-- Query/procedure to remove a customer from the database
DROP PROCEDURE IF EXISTS RemoveCustomer;
DELIMITER $$
CREATE PROCEDURE `RemoveCustomer`(IN customer_id_param INT)
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_transactions (
        transaction_id INT
    );
    INSERT INTO temp_transactions (transaction_id)
    SELECT t.transaction_id
    FROM transactions t
    JOIN makes m ON t.transaction_id = m.transaction_id
    WHERE m.monthly_card_id IN (SELECT mc.card_id FROM monthly_card mc WHERE mc.customer_id = customer_id_param)
       OR m.multi_card_id IN (SELECT muc.card_id FROM multi_use_card muc WHERE muc.customer_id = customer_id_param);
    DELETE FROM makes WHERE transaction_id IN (SELECT transaction_id FROM temp_transactions);
    DELETE FROM transactions WHERE transaction_id IN (SELECT transaction_id FROM temp_transactions);
    DROP TEMPORARY TABLE IF EXISTS temp_transactions;
    DELETE FROM buys WHERE customer_id = customer_id_param;
    DELETE FROM monthly_card WHERE customer_id = customer_id_param;
    DELETE FROM multi_use_card WHERE customer_id = customer_id_param;
    DELETE FROM receives WHERE customer_id = customer_id_param;
    DELETE FROM customer WHERE customer_id = customer_id_param;
END$$
DELIMITER ;

-- Query/procedure to calculate the price of a monthly metrocard based on zone, age, and special discounts
DELIMITER $$
DROP PROCEDURE IF EXISTS CalculateMonthlyPrice;
CREATE PROCEDURE `CalculateMonthlyPrice`(IN customer_id_param INT, OUT final_price DECIMAL(10,2))
BEGIN
    DECLARE cust_zone CHAR(2);
    DECLARE cust_age_group VARCHAR(20);
    DECLARE base_price DECIMAL(10,2);
    DECLARE discount_factor DECIMAL(10,2) DEFAULT 1.0;
    DECLARE is_student BOOLEAN;
    DECLARE has_disability BOOLEAN;
    DECLARE has_family_normal BOOLEAN;
    DECLARE has_family_special BOOLEAN;
    SELECT a.zone, c.age_group, c.student_status, c.disability_status, c.family_normal_status, c.family_special_status
    INTO cust_zone, cust_age_group, is_student, has_disability, has_family_normal, has_family_special
    FROM customer c
    JOIN address a ON c.zip_code = a.zip_code
    WHERE c.customer_id = customer_id_param;
    SELECT price INTO base_price
    FROM price_matrix
    WHERE zone = cust_zone AND age_group = cust_age_group;
    IF has_disability OR cust_age_group = 'Senior' THEN
        SET discount_factor = discount_factor * 0.35; 
    END IF;
    IF has_family_normal THEN
        SET discount_factor = discount_factor * 0.8;
    END IF;
    IF has_family_special THEN
        SET discount_factor = discount_factor * 0.6;
    END IF;
    SET final_price = base_price * discount_factor;
END$$
DELIMITER ;

-- Query/procedure to reload a monthly metrocard
DELIMITER $$
DROP PROCEDURE IF EXISTS ReloadMonthlyCard;
CREATE PROCEDURE `ReloadMonthlyCard`(IN card_id_param INT)
BEGIN
    DECLARE customer_var INT;
    DECLARE price DECIMAL(10,2);
    DECLARE transaction_date DATE;
    DECLARE new_transaction_id INT;
    SET transaction_date = CURDATE();
    SELECT customer_id INTO customer_var FROM monthly_card WHERE card_id = card_id_param;
    CALL CalculateMonthlyPrice(customer_var, price);
    UPDATE monthly_card
    SET validity = TRUE, date_last_charge = transaction_date
    WHERE card_id = card_id_param;
    INSERT INTO transactions(transaction_type, transaction_date, amount)
    VALUES ('Reload Monthly', transaction_date, price);
    SET new_transaction_id = LAST_INSERT_ID();  
    INSERT INTO makes(transaction_id, monthly_card_id)
    VALUES (new_transaction_id, card_id_param);
END$$
DELIMITER ;
