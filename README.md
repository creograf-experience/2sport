Установка
---------------
1.  ставим nodejs: https://github.com/joyent/node/wiki/installation
2.  ставим mongodb: http://docs.mongodb.org/manual/installation/
3.  устанавливаем git и клонируем репозиторий VitalCMS
4.  ставим глобальные пакеты npm:
    `$ sudo npm install -g coffee-script jasmine-node grunt-cli bower`
5.  зависимости сервера: 
    `$ sudo npm install`
6.  зависимости клиентсайда: 
    `$ bower install`
7.  собираем пакеты из bower в один файл:
    `$ grunt bower`
8.  заряжаем базу данными по умолчанию:
    `$ grunt db:seed`

10.  запускаем сервер:
     `$ grunt`
11.  админка по адресу http://localhost:3000/cms/
     логин: **admin**
     пароль: **lady8ug**

Задачи Grunt
------------------
`$ grunt`
тестит, компилирует кофе, jade, запускает сервер, запускает watch
при изменении серверного кода пока нужно перезапускать

Диагностика
-------------------
**Тесты**

`$ grunt test`

**Профайлинг**

1.  добавляем `require('look')()` первой строчкой в /app/app.coffee
2.  открываем браузер по адресу http://localhost:5959

**Дебаг веб-сервера**

http://localhost:5858

**Бенчмарки** 

1.  ставим апачевский джентельменский набор:
    `sudo apt-get install apache2-utils` или аналог в нашей системе
2.  запускаем бенчмарк, например, на 10 пользователей по 100 запросов:
    `ab -l -r -n 1000 -c 10 -H "Accept-Encoding: gzip, deflate" localhost:3000/`
3.  запускаем сервер в режиме для бенчмарка
    `grunt server:bench`