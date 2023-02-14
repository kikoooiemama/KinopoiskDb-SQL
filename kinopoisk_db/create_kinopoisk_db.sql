DROP DATABASE IF EXISTS kinopoisk_db;

CREATE DATABASE kinopoisk_db;

USE kinopoisk_db;

/*
 * 1. Пользователи.
 */
DROP TABLE IF EXISTS users;
CREATE TABLE users(
	id SERIAL PRIMARY KEY,
	login VARCHAR (127) NOT NULL UNIQUE,
	email VARCHAR(255) NOT NULL UNIQUE,
	password_hash CHAR(65) DEFAULT NULL,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	INDEX users_login_idx (login),
	INDEX users_email_idx (email)
);

/*
 * 2. Профили. Связь с users.
 */
DROP TABLE IF EXISTS profiles;
CREATE TABLE profiles(
	user_id SERIAL PRIMARY KEY,
	first_name VARCHAR(127) NOT NULL,
	last_name VARCHAR(127) NOT NULL,
	gender ENUM('male', 'female') NOT NULL, 
	birthday DATE NOT NULL,
	country VARCHAR (127),
	city VARCHAR (127),
	description TEXT,
	CONSTRAINT fk_profiles_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * 3. Фильмы/сериалы. 
 */
DROP TABLE IF EXISTS films;
CREATE TABLE films(
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	year_creation YEAR NOT NULL COMMENT "Год производства",
	duration_in_minutes INT NOT NULL COMMENT "Продолжительность в минутах",
	premiere_world DATE NOT NULL COMMENT "Премьера в Мире",
	premiere_rus DATE COMMENT "Премьера в РФ",
	fees BIGINT COMMENT "Сборы",
	budget BIGINT NOT NULL COMMENT "Бюджет",
	slogan TEXT COMMENT "Слоган",
	country VARCHAR (127),
	KEY (name)
);

/*
 * 4. Жанры.
 */
DROP TABLE IF EXISTS genres;
CREATE TABLE genres(
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR (127) NOT NULL UNIQUE COMMENT "Название жанра (триллер, драма, мелодрама, комедия, боевик и т.д.)"
);

/*
 * 5. Фильмы и соответствующие им жанры. 
 */
DROP TABLE IF EXISTS films_genres;
CREATE TABLE films_genres(
	film_id BIGINT UNSIGNED NOT NULL,
	genre_id INT UNSIGNED NOT NULL,
	PRIMARY KEY (film_id, genre_id),
	CONSTRAINT fk_films_genres_film_id FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_genre_id FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * 6. Профессии.
 */
DROP TABLE IF EXISTS professions;
CREATE TABLE professions(
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR (127) NOT NULL UNIQUE COMMENT "Название профессии (актер, монтажер, режиссер, художник, продюссер и т.д.)"
);

/*
 * 7. Персонал.
 */
DROP TABLE IF EXISTS staff;
CREATE TABLE staff(
	id SERIAL PRIMARY KEY,
	film_id BIGINT UNSIGNED NOT NULL COMMENT "Фильм, место работы",
	profession_id INT UNSIGNED NOT NULL COMMENT "Профессия",
	first_name VARCHAR (127) NOT NULL COMMENT "Имя сотрудника",
	last_name VARCHAR (127) NOT NULL COMMENT "Фамилия сотрудника",
	CONSTRAINT fk_staff_film_id FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_profession_id FOREIGN KEY (profession_id) REFERENCES professions (id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * 8. Оценки к фильму/сериалы. 
 */
DROP TABLE IF EXISTS films_rating;
CREATE TABLE films_rating(
	user_id BIGINT UNSIGNED NOT NULL COMMENT "Пользователь",
	film_id BIGINT UNSIGNED NOT NULL COMMENT "Фильм",
	rating TINYINT UNSIGNED COMMENT "Оценка",
	PRIMARY KEY (user_id, film_id),
	KEY (user_id),
	KEY (film_id),
	CONSTRAINT fk_rating_film_id FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_rating_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * 9. Рецензии.
 * Автор из users, фильм из films.
 */ 
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews(
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL COMMENT "Автор рецензии",
	film_id BIGINT UNSIGNED NOT NULL COMMENT "К какому фильму рецензия",
	review_type ENUM('positive', 'negitive', 'neutral') NOT NULL COMMENT "Положительная, отрицательная, нейтральная", 
	ratings_positive INT UNSIGNED DEFAULT 0 NOT NULL COMMENT "Количество отметок 'Полезно' у рецензии",
	ratings_useless INT UNSIGNED DEFAULT 0 NOT NULL COMMENT "Количество отметок 'Нет' у рецензии", 
	review TEXT NOT NULL COMMENT "Рецензия",
	KEY (user_id),
	KEY (film_id)
);

/*
 * 10. Комментарии к рецензии.
 */
DROP TABLE IF EXISTS comments;
CREATE TABLE comments(
	id SERIAL PRIMARY KEY,
	review_id BIGINT UNSIGNED NOT NULL,
	user_id BIGINT UNSIGNED NOT NULL COMMENT "Комментатор",
	comment TEXT NOT NULL COMMENT "Комментарий",
	KEY (review_id),
	CONSTRAINT fk_comments_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_comments_review_id FOREIGN KEY (review_id) REFERENCES reviews (id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * 11. Типы медиа.
 * Картинки, видео, аудио.
 */
DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(63) NOT NULL UNIQUE
);

/*
 * 12. Медиа.
 * Изображения из фильмов, аватарки пользователей, саундтреки к фильмам, трейлеры к фильмам.
 */
DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL PRIMARY KEY,
	film_id BIGINT UNSIGNED,
	user_id BIGINT UNSIGNED,
	media_types_id INT UNSIGNED NOT NULL,
	file_name VARCHAR(255),
	file_size BIGINT UNSIGNED NOT NULL,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	KEY (media_types_id),
	KEY (user_id),
	KEY (film_id),
	CONSTRAINT fk_media_media_types_id FOREIGN KEY (media_types_id) REFERENCES media_types(id),
	CONSTRAINT fk_media_user_id FOREIGN KEY (user_id) REFERENCES users(id),
	CONSTRAINT fk_media_film_id FOREIGN KEY (film_id) REFERENCES films(id)
);

/*
 * 13. Сообщения. 
 */
DROP TABLE IF EXISTS messages;
CREATE TABLE messages(
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
	to_user_id BIGINT UNSIGNED NOT NULL,
	txt TEXT NOT NULL,
	created_at DATETIME NOT NULL DEFAULT NOW(),
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки",
	INDEX messages_from_user_id_idx (from_user_id),
	INDEX messages_to_user_id_idx (to_user_id),
	CONSTRAINT fk_messages_from_user_id FOREIGN KEY (from_user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_messages_to_user_id FOREIGN KEY (to_user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * 14. Друзья
 * На кинопоиске нет запросов в друзья, ты просто добавляешь себе человека в список друзей и все. Он в твоем списке друзей.
 */
DROP TABLE IF EXISTS friends;
CREATE TABLE friends(
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	friend_id BIGINT UNSIGNED NOT NULL,
	INDEX friends_user_id_idx (user_id),
	INDEX friends_friend_id_idx (friend_id),
	CONSTRAINT fk_friends_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_friends_friend_id FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
);
