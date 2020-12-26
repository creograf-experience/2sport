FORMAT: 1A
HOST: http://2sport.creograf-dev.ru/api

# Group Сессия

## Регистрация [POST /auth/registration]
Если ответ ок, то вместе с регой
происходит аутентификация и записывается IP и дата регистрации.

  + Request (application/json)

    + Body

      ```
      {
        "name": "Иван Иванов",
        "email": "ivanov@gmail.com",
        "password": "123456",
        "passConfirm": "123456"
      }
      ```

  + Response 200 (application/json)

    + Attributes (UserData)

  + response 400 (application/json)

    ```
    {
      "name": "email",
      "message": "Пользователь с таким адресом email уже зарегестрирован"
    }
    ```

## Авторизация [POST /auth/login]

  + Request (application/json)

    + Body

      ```
      {
        "email": "ivanov@gmail.com",
        "password": "123456"
      }
      ```

  + Response 200 (application/json)

    + Attributes (UserData)

  + response 401 (application/json)

    ```
    {
      "message": "Неверные логин или пароль"
    }
    ```
