USE kinopoisk_db;

/*
 * Скрипты характерных выборок. 
 * 1. Все фильмы с положительными отзывами.
 * 2. Вывести оценки пользователей к фильмам.
 * 3. Вывести комментарии пользователей.
 * 4. Вывести количество выставленных оценок каждому фильму и среднюю оценку.
 * 5. Вывести рейтинг ТОП 25 лучших фильмов по оценкам, причем оценок должно быть не меньше 5.
 */

-- 1.
SELECT DISTINCT f.name AS film, count(*) AS amount_positive
FROM films f 
	JOIN reviews r ON f.id = r.film_id AND r.review_type = 'positive'
GROUP BY f.id;

-- 2.
SELECT 
	(SELECT login FROM users WHERE id = fr.user_id),
	(SELECT concat(first_name, ' ', last_name) FROM profiles WHERE user_id = fr.user_id) AS name,
	(SELECT name FROM films WHERE id = fr.film_id) AS film,
	rating
FROM films_rating fr ;

-- 3.
SELECT u.login, c.review_id AS review, c.comment 
FROM users u
	JOIN comments c ON u.id = c.user_id;

-- 4.
SELECT f.name AS film, count(*) AS amount, TRUNCATE(avg(fr.rating),2) AS average_rating 
FROM films f 
	JOIN films_rating fr ON f.id = fr.film_id 
GROUP BY f.id;

-- 5.
SELECT f.name AS film, count(*) AS amount, TRUNCATE(avg(fr.rating),2) AS average_rating 
FROM films f 
	JOIN films_rating fr ON f.id = fr.film_id 
GROUP BY f.id
HAVING amount >= 5
ORDER BY average_rating DESC
LIMIT 25;

/*
 * Представления (минимум 2). 
 * 1. Представление средней оценки к фильмам.
 * 2. Представление пользователей, количество оценок, количество рецензий, количество комментарий.
 * 3. Представление фильмы/актеры (actor).
 * 4. Представление ТОП 10 самых активных пользователей (оценки пользователя, рецензии пользователя, комментарии).
 * 5. Представление ТОП 25 лучших фильмов по оценкам, причем оценок должно быть не меньше 5.
 */

-- 1.
CREATE OR REPLACE VIEW average_rating
AS
SELECT f.name AS film, TRUNCATE(avg(fr.rating), 2) AS rating 
FROM films f 
	JOIN films_rating fr ON f.id = fr.film_id 
GROUP BY f.id;

-- 2.
CREATE OR REPLACE VIEW user_activity
AS
SELECT login AS username, 
	(SELECT count(*) FROM films_rating WHERE user_id = u.id) AS number_of_marks,
	(SELECT count(*) FROM reviews WHERE user_id = u.id) AS number_of_reviews,
	(SELECT count(*) FROM comments WHERE user_id = u.id) AS number_of_comments
FROM users u;

-- 3.
CREATE OR REPLACE VIEW actors
AS
SELECT f.name AS film, concat(s.first_name, ' ', s.last_name) AS actor_name  
FROM films f 
	JOIN staff s ON f.id = s.film_id 
	JOIN professions p ON p.name = 'actor';

-- 4.
CREATE OR REPLACE VIEW top_user_activity
AS
SELECT username, real_name, number_of_marks + number_of_reviews + number_of_comments AS sum_activity
FROM(
	SELECT login AS username, 
		(SELECT count(*) FROM films_rating WHERE user_id = u.id) AS number_of_marks,
		(SELECT count(*) FROM reviews WHERE user_id = u.id) AS number_of_reviews,
		(SELECT count(*) FROM comments WHERE user_id = u.id) AS number_of_comments,
		(SELECT concat(first_name, ' ', last_name) FROM profiles WHERE user_id = u.id) AS real_name
	FROM users u
) AS activity
ORDER BY sum_activity DESC
LIMIT 10;

SELECT * FROM actors;
SELECT * FROM average_rating;
SELECT * FROM user_activity;
SELECT * FROM top_user_activity;

-- 5.
CREATE OR REPLACE VIEW top_25_films
AS
SELECT f.name AS film, count(*) AS amount, TRUNCATE(avg(fr.rating),2) AS average_rating 
FROM films f 
	JOIN films_rating fr ON f.id = fr.film_id 
GROUP BY f.id
HAVING amount >= 5
ORDER BY average_rating DESC
LIMIT 25;

/*
 * Процедуры/Функции.
 * 1. Подсчитать полезности/актуальность всех рецензий пользователя.
 * Коэффициент полезности = СУММ(N, (положительный рейтинг рецензии - отрицательный рейтинг рецензии)) / N,
 * где N - суммарное количество рецензий пользователя.
 */
DROP FUNCTION IF EXISTS func_user_utility;
DELIMITER // 
CREATE FUNCTION func_user_utility(for_user_id BIGINT UNSIGNED)
RETURNS FLOAT READS SQL DATA -- так как мы только читаем данные
BEGIN
	DECLARE N INT;
	DECLARE cnt_positive_rating INT;
	DECLARE cnt_useless_rating INT;
	-- Считаем количество всех рецензий пользователя
	SET N = (SELECT COUNT(*) FROM reviews WHERE user_id = for_user_id);
	-- Cчитаем сумму положительного рейтинга во всех рецензиях пользователя
	SET cnt_positive_rating = (SELECT SUM(ratings_positive) FROM reviews WHERE user_id = for_user_id);
	-- Cчитаем сумму отрицательного рейтинга во всех рецензиях пользователя
	SET cnt_useless_rating = (SELECT SUM(ratings_useless) FROM reviews WHERE user_id = for_user_id);
	RETURN (cnt_positive_rating - cnt_useless_rating) / N;
END //
DELIMITER ;

SELECT func_user_utility(10);

/*
 * Триггеры.
 * 1. Нельзя добавить оценку к фильму, если оно не в диапазоне от 1 до 10.
 * 2. Контроль даты рождения.
 */

-- 1.
DROP TRIGGER IF EXISTS check_rating_before_insert;
DELIMITER //
CREATE TRIGGER check_rating_before_insert BEFORE INSERT ON films_rating
FOR EACH ROW 
	BEGIN
		IF NEW.rating > 10 OR NEW.rating < 1 THEN 
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insert canceled. The rating of the film should be in the range from 1 to 10';
		END IF;
	END //
DELIMITER ;

DROP TRIGGER IF EXISTS check_rating_before_update;
DELIMITER //
CREATE TRIGGER check_rating_before_update BEFORE UPDATE ON films_rating
FOR EACH ROW 
	BEGIN
		IF NEW.rating > 10 OR NEW.rating < 1 THEN 
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update canceled. The rating of the film should be in the range from 1 to 10';
		END IF;
	END //
DELIMITER ;

/*INSERT INTO `films_rating` VALUES (1,12,0);
INSERT INTO `films_rating` VALUES (1,12,2);
UPDATE films_rating SET rating = 0 WHERE user_id = 1 AND film_id = 12;
UPDATE films_rating SET rating = 11 WHERE user_id = 1 AND film_id = 12;
UPDATE films_rating SET rating = 2 WHERE user_id = 1 AND film_id = 12;

SELECT * FROM films_rating fr ;*/

-- 2.
DROP TRIGGER IF EXISTS check_birthday_before_insert;
DELIMITER //
CREATE TRIGGER check_birthday_before_insert BEFORE INSERT ON profiles
FOR EACH ROW
	BEGIN
		IF NEW.birthday >= current_date() THEN 
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insert canceled. Birthday must be in the past!';
		END IF;
	END //
DELIMITER ;
	
DROP TRIGGER IF EXISTS check_birthday_before_update;
DELIMITER //
CREATE TRIGGER check_birthday_before_update BEFORE UPDATE ON profiles
FOR EACH ROW
BEGIN 
	IF NEW.birthday >= CURRENT_DATE() THEN -- если полученная дата рождения больше текущей - отправляем сигнал об ошибке
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update canceled. Birthday must be in the past!';
    END IF;
END //
DELIMITER ;
