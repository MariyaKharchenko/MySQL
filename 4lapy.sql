-- Модель хранения данных интернет-магазина 4lapy.ru

/*В данном курсовом пректе представлена модель хранения данных интернет-магазина 4lapy.ru (в количестве 11 таблиц).
 * Данная БД содержит инфомацию о товарах,их ценах и категориях, а так же о покупателях, их бонусном счёте, 
 * избранных товарах и покупках. 
 * Задачи, которые предстоит решить в данной БД:
 * 1. Вывод представления, в котором необходимо вывести
 * данные покупателя, необходимые для связи с ним, корзина которого 
 * находится в статусе "ожидает оформления
 * 2.Вывод разницы прибыли этого года и прошлого года (в процентах).
 * 3. Подарок покупателю - 3000 бонусных рублей ко дню рождения.
 * 4. Когда был приобретен корм для животных с id = 8.
 * 5. Ввыести покупателя с самым большим бонусным счетом.
 * 6. Вывести покупателей, в "избранном" у которых находятся умные товары.
 * 7. Выяснить, в 2000 году какая переноска для животных пользовалась наибольшей популярностью.
 * 8. Сколько покупателей совершило покупку в 1991 году.
 * 9. Сколько переносок было продано с размером 12.
 * 10. Вывести представление товаров для животных, размером больше 25 см.
 * 11. Ограничение возможности внесения даты рождения больше, чем текущее время.
 */

DROP DATABASE IF EXISTS 4lapy;
CREATE DATABASE 4lapy;
USE 4lapy;

/*Таблица users содержит информацию о покупателях,состоит из 9 столбцов (идентификатор покупателя,
 * имя, фамилия, эл.адрес, пароль покупателя, номер телефона, дата рождения, дата создания аккауна,
 * а так же столбец указывающий на то - действующий ли Клиент или удалённый).
 */
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
    firstname VARCHAR(100),
    lastname VARCHAR(100) COMMENT 'Фамилия', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(100),
    phone BIGINT,
    birthday DATE,
    created_at DATETIME DEFAULT NOW(),
    is_deleted BIT DEFAULT 0,
    
    INDEX users_firstname_lastname_idx(firstname, lastname)
);

/*Таблица animals (животные) состоит из 2 столбцов: идентификатора животного и 
 * столбца наименования животного. */
DROP TABLE IF EXISTS animals;
CREATE TABLE animals(
	id SERIAL PRIMARY KEY,
	name VARCHAR(150)
);

/* Таблица `products` (товары) состоит из 2 столбцов: идентификатора товара и
 * ссылку на идентификатор животного (внешний ключ).
 */
DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
	id SERIAL PRIMARY KEY,
	animal_id BIGINT UNSIGNED,

FOREIGN KEY (animal_id) REFERENCES animals(id) ON UPDATE CASCADE ON DELETE SET NULL
);

/* Таблица `favorites` (избранное) состоит из 4 столбцов: идентификаторов покупателя и товара
 * (составной первичный ключ), ссылку на идентификатор покупателя (внешний ключ), ссылку на 
 * идентификатор товара (внешний ключ), статус товара в "избранном" (дабавлен, удален, 
 * покупается чаще всего).
 */
DROP TABLE IF EXISTS `favorites`;
CREATE TABLE `favorites` (
user_id BIGINT UNSIGNED NOT NULL,
product_id BIGINT UNSIGNED NOT NULL,
PRIMARY KEY (user_id, product_id),
`status` ENUM('added', 'deleted', 'bought most often'),	
    
FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (product_id) REFERENCES `products`(id) ON UPDATE CASCADE ON DELETE CASCADE
);

/* Таблица foods (корм) состоит из 7 столбцов: идентификатора и наименования корма, ссылку на 
 * идентификатор товара (внешний ключ), цену и количество, а так же дату создания и изменения
 * товарной позиции.
 */
DROP TABLE IF EXISTS foods;
CREATE TABLE foods(
	id SERIAL PRIMARY KEY,
	name VARCHAR(255),
	product_id BIGINT UNSIGNED,
	price DECIMAL(10,2) UNSIGNED,
	`count` INT UNSIGNED,
	created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
FOREIGN KEY (product_id) REFERENCES `products`(id) ON UPDATE CASCADE ON DELETE SET NULL
);

/*Таблица `size` (размер) состоит из 3 столбцов: идентификатора размера, столбца 
 * наименования размера и веса.
 */
DROP TABLE IF EXISTS `size`;
CREATE TABLE `size`(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    size_animal INT UNSIGNED NOT NULL
);

/* Таблица carriers (переноски) состоит из 8 столбцов: идентификатор и наименование товарной 
 * позиции, ссылку на идентификатор товара (внешний ключ), ссылку на размер (внешний ключ),
 * цену и количество, а так же дату создания и изменения товарной позиции.
 */
DROP TABLE IF EXISTS carriers;
CREATE TABLE carriers(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    product_id BIGINT UNSIGNED,
    size_id BIGINT UNSIGNED,
    price DECIMAL(10,2) UNSIGNED,
    `count` INT UNSIGNED,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

FOREIGN KEY (product_id) REFERENCES `products`(id) ON UPDATE CASCADE ON DELETE SET NULL,
FOREIGN KEY (size_id) REFERENCES `size`(id) ON UPDATE CASCADE ON DELETE SET NULL
);

/* Таблица smart_goods (умные вещи) состоит из 3 столбцов: идентификатор и наименование товарной 
 * группы, ссылку на идентификатор товара (внешний ключ).
 */
DROP TABLE IF EXISTS smart_goods;
CREATE TABLE smart_goods(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    product_id BIGINT UNSIGNED,
    INDEX smart_good_name_idx(name),

FOREIGN KEY (product_id) REFERENCES `products`(id) ON UPDATE CASCADE ON DELETE SET NULL
);

/* Таблица smart_feed (умные кормушки) состоит из 8 столбцов: идентификатор и наименование товарной 
 * позиции, ссылку на идентификатор товарной группы (внешний ключ), ссылку на размер (внешний ключ),
 * цену и количество, а так же дату создания и изменения товарной позиции.
 */
DROP TABLE IF EXISTS smart_feed;
CREATE TABLE smart_feed(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    smart_good_id BIGINT UNSIGNED,
    size_id BIGINT UNSIGNED,
    price DECIMAL(10,2) UNSIGNED,
    `count` INT UNSIGNED,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

FOREIGN KEY (size_id) REFERENCES `size`(id) ON UPDATE CASCADE ON DELETE SET NULL,
FOREIGN KEY (smart_good_id) REFERENCES smart_goods(id) ON UPDATE CASCADE ON DELETE SET NULL
);

/* Таблица `baskets` (корзина) содержит 8 столбцов: идентификаторы покупки, ссылку на идентификатор
 * покупателя (внешний ключ), ссылку на идентификатор товараы (внешний ключ), количество товара,
 * отобранного в корзину, цену, статус корзины (пуста, ожидает оформления или олата произведена),
 * а так же дату создания и изменения наполнения данной корзины.
 */
DROP TABLE IF EXISTS `baskets`;
CREATE TABLE `baskets` (
id SERIAL PRIMARY KEY,
user_id BIGINT UNSIGNED,
product_id BIGINT UNSIGNED,
product_count INT UNSIGNED NOT NULL,
price DECIMAL(10,2) UNSIGNED,
`status` ENUM('Cart is empty', 'Continue checkout', 'Paid'),
created_at DATETIME DEFAULT NOW(),
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	
FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (product_id) REFERENCES `products`(id) ON UPDATE CASCADE ON DELETE SET NULL
);

/*Таблица bonus_accounts (бонусный счет) состоит из 4 столбцов: идентификатор бонусного счета,
 * ссылку на идентификатор покупателя (внешний ключ), ссылку на корзину (внешний ключ), а так же,
 * столбец бонусного счёта покупателя.
 */
DROP TABLE IF EXISTS bonus_accounts;
CREATE TABLE bonus_accounts (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
    basket_id BIGINT UNSIGNED NOT NULL,
    wallet DECIMAL(10,2) UNSIGNED,
    
FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (basket_id) REFERENCES `baskets`(id) ON UPDATE CASCADE ON DELETE CASCADE
);





