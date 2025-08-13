USE 4lapy;

UPDATE animals 
SET name = 'et and cum'
WHERE id = 4;

-- Когда был приобретен корм для животных с id = 8.

SELECT updated_at AS `date`,
product_count AS total
FROM baskets
WHERE id IN (SELECT id FROM animals WHERE id = 8) AND status = 'paid';


-- Ввыести покупателя с самым большим бонусным счетом.

SELECT u.firstname,
	   u.lastname,
	   MAX(ba.wallet) AS total
FROM users u
JOIN bonus_accounts ba ON ba.user_id = u.id
GROUP BY u.id
ORDER BY total DESC
LIMIT 1;


-- Вывести покупателей, в "избранном" у которых находятся умные товары.

SELECT u.firstname,
	   u.lastname 
FROM users u
JOIN favorites f ON u.id = f.user_id
WHERE f.product_id IN (SELECT id FROM smart_goods) 
	AND f.status = 'added' 
	AND u.is_deleted != 1;

-- Выяснить, в 2000 году какая переноска для животных пользовалась наибольшей популярностью.

SELECT c.id, c.name
FROM baskets b
JOIN carriers c ON c.product_id = b.product_id
WHERE b.status = 'Paid' AND b.updated_at LIKE '%2000%'
ORDER BY b.product_count DESC
LIMIT 1
;

-- Сколько покупателей совершило покупку в 1991 году.

SELECT COUNT(*) AS total_purchases
FROM users u
JOIN baskets b ON b.user_id = u.id
WHERE b.status = 'Paid' AND b.updated_at LIKE '%1991%'
GROUP BY b.status;


-- Сколько переносок было продано с размером 12.

SELECT COUNT(*) AS total
FROM carriers c 
JOIN `size` s ON s.id = c.size_id
WHERE s.size_animal = 12;


/*Создать временную таблицу с представления, в котором необходимо вывести
 * данные покупателя, необходимые для связи с ним, корзина которого 
 * находится в статусе "ожидает оформления".
 */

CREATE ALGORITHM = TEMPTABLE VIEW continue_checkout
AS SELECT u.firstname,
	   u.lastname,
	   u.phone,
	   b.product_id,
	   b.price,
	   b.created_at
   FROM users u
   JOIN baskets b ON b.user_id = u.id 
   WHERE b.status = 'Continue checkout';
  
SELECT * FROM continue_checkout;


-- Вывести представление товаров для животных, размером больше 25 см.

 CREATE OR REPLACE VIEW products_2
 AS SELECT c.id, c.name, s.size_animal
 FROM carriers c
 JOIN `size` s ON s.id = c.size_id
 WHERE s.size_animal > 25
 UNION
 SELECT sf.id, sf.name, s.size_animal
 FROM smart_feed sf
 JOIN `size` s ON s.id = sf.size_id
 WHERE s.size_animal > 25
 ORDER BY size_animal;

SELECT * FROM products_2;

-- Написать триггер, предотвращающий внесение даты рождения больше, чем текущее время.

DELIMITER $$
$$
CREATE TRIGGER trigger_birthday
BEFORE INSERT
ON users FOR EACH ROW
BEGIN 
	IF NEW.birthday > CURRENT_DATE() THEN 
	   SIGNAL SQLSTATE '45000'
	   SET MESSAGE_TEXT = 'Сработал триггер! Дата рождения больше, чем настоящее время. Вставка отклонена.';
	END IF;
END
$$
DELIMITER ;

INSERT INTO users (id, firstname, lastname, email, password_hash, phone, birthday)
VALUES (1000, 'Ivan', 'Tsarevich', 'Ivan@gmal.com', 'Ivan', 99991234567, '2122-01-01');

INSERT INTO users (id, firstname, lastname, email, password_hash, phone, birthday)
VALUES (1001, 'Ivan', 'Tsarevich', 'Ivan@gmal.com', 'Ivan', 99991234567, '2022-01-01');


-- Создать процедуру, зачисляющую подарок покупателю - 3000 бонусных рублей ко дню рождения.

-- Создадим уловие для проверки корректности работы процедуры:

INSERT INTO users (id, firstname, lastname, email, password_hash, phone, birthday)
VALUES (1002, 'Ivan', 'Sidorov', 'Ivanushka@gmal.com', 'Ivan', 99991234567, '2021-05-03');

INSERT INTO baskets  (id, product_count)
VALUES (5000, 0);

INSERT INTO bonus_accounts  (user_id, basket_id, wallet)
VALUES (1002, 5000, 500);

SELECT wallet
FROM bonus_accounts
WHERE user_id = 1002 OR user_id = 1; -- Здесь user_id = 1 добавлен для понимания точности работы.

-- Далее, следует сама процедура.

DROP PROCEDURE IF EXISTS `4lapy`.present;

DELIMITER $$
$$
CREATE PROCEDURE `4lapy`.present()
BEGIN
	UPDATE bonus_accounts SET wallet = wallet + 3000 WHERE user_id IN (SELECT
    id FROM users WHERE MONTH(users.birthday) = MONTH(NOW()) 
        AND DAY(users.birthday) = DAY(NOW()))
;
END$$
DELIMITER ;

CALL present();

-- Проверяем.

SELECT wallet
FROM bonus_accounts
WHERE user_id = 1002 OR user_id = 1;


/* Написать функцию, возвращающую разницу прибыли этого года и прошлого года
 * (в процентах).
 */

-- Внесём изменения в таблицу, для наличия продажи в 2022 году.

UPDATE  baskets
SET price = 7300, status = 'Paid' WHERE id = 5000;

SELECT * FROM baskets
WHERE id = 5000;

-- Создадим функцию.

DROP FUNCTION IF EXISTS `4lapy`.total_price;

DELIMITER $$
$$
CREATE FUNCTION `4lapy`.total_price()
RETURNS DECIMAL(10,2) READS SQL DATA
BEGIN
	DECLARE this_year DECIMAL(10,2);
	DECLARE last_year DECIMAL(10,2);

	SET this_year = (
	SELECT SUM(price) 
	FROM baskets
	WHERE YEAR (updated_at) = YEAR (NOW()) AND status = 'Paid'
	);

	SET last_year = (
	SELECT SUM(price) 
	FROM baskets
	WHERE YEAR (updated_at) = YEAR (NOW())-1 AND status = 'Paid'
	);

	CASE
		WHEN this_year > last_year
	    THEN RETURN this_year/last_year*100-100;
	    WHEN this_year = last_year OR this_year < last_year
	    THEN RETURN -(last_year/this_year*100-100);
	END CASE;
END$$
DELIMITER ;


SELECT total_price();

/* В данном случае, прибыль в этом году меньше прибыли, которая была
 * в прошлом году, на 17,62%.
 */

-- Внесём ещё изменения.

UPDATE  baskets
SET price = 5000, status = 'Paid' WHERE id = 1;

SELECT total_price();

/* После изменений в корзине, прибыль этого года стала на 43,25% больше, 
 * чем в прошлом году.
 * */
