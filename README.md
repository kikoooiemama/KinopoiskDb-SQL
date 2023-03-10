# KinopoiskDb-SQL
Практика SQL и создание модели хранения данных веб-сайта "КиноПоиск".

## Описание задачи
Целью является построение базы данных для киносообщества, расположенного на веб-сайте «КиноПоиск». <br>
Для реализации необходимо обеспечить хранение определенных данных, а именно:
* информации о фильмах (описание, оценки пользователей, саундтреки, кадры из фильмов, трейлеры),
* личных данных пользователей (контакты, друзья, сообщения, фото), 
* рецензий к фильмам (описание, оценка рецензий, комментарии).

Реализовать структуру хранения данных нужно на базе свободной реляционной системы управления базами данных MySQL 8.0.25

## Описание реализованной модели MySQL

### Таблицы:
* Пользователи (users) <br>
Обычный аккаунт с логином, почтой и паролем.

* Профили (profiles) <br>
Личная информация об аккаунте: фото, имя, фамилия, дата рождения, пол, страна, город. Использует таблицу users.

* Фильмы/Сериалы (films) <br>
Информация о кинопродукте: название, режиссер, год создания и т.д.

* Жанры (genres) <br>
Жанры фильмов.

* Фильмы и жанры (films_genres) <br>
Таблица с фильмами и соответствующими этим фильмам жанрами. Использует таблицу genres.

* Профессии (professions) <br>
Профессии работников, которые работали над созданием фильма/сериала. Например, актеры, режиссеры, монтажеры, операторы, сценаристы и т.д.

* Персонал (staff) <br>
Таблица, содержащая информацию обо всех сотрудниках, которые работали над фильмом/сериалом. Использует таблицы professions, films.

* Оценки к фильму/сериалу (films_rating) <br>
Каждый пользователь может ставить свои оценки (от 1 до 10, целое) к тому или иному кинопродукту. Использует таблицы films, users.

* Рецензии (reviews) <br>
Каждый пользователь может написать свою рецензию на любой (просмотренный им) фильм.

* Комментарии к рецензии (comments) <br>
К каждой рецензии под фильмом пользователи могут поставить оставить комментарий. Использует таблицы users, reviews.

* Типы медиа (media_types) <br>
Картинки (image), аудиофайлы (audio), видео (video).

* Медиа (media) <br>
На сайте присутствуют медиафайлы. Например, фотографии для профилей, саундтреки и трейлеры к фильмам. Использует таблицы users, films, media_types.

* Сообщения (messages) <br>
Сообщения из переписки пользователей. Использует таблицу users.

* Друзья (friends) <br>
Друзья пользователей. Запросов на сайте нет, каждый пользователь просто составляет себе список друзей и все. Использует таблицу users.

### Представления:
1. Средние оценки фильмов (average_rating);
2. Пользователи, их количество оценок, рецензий и комментариев
(user_activity);
3. Фильмы/Сериалы и играющие в них актеры (actors);
4. ТОП 10 самых активных пользователей, где учитывались оценки,
рецензии, комментарии (top_user_activity);
5. ТОП 25 лучших фильмов, где средняя оценка, оценок не менее 5
(top_25_films).

### Хранимые процедуры/функции:
1. Подсчет средней полезности всех рецензий пользователя. Коэффициент полезности = СУММ (N, (положительный рейтинг рецензии - отрицательный рейтинг рецензии)) / N, где N - суммарное количество рецензий пользователя. (func_user_utility)

### Триггеры:
1. Нельзя добавить/обновить оценку к фильму, если оно выходит из
интервала [1,10];
2. Контроль даты рождения в профиле.
