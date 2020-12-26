# Group Управление юзером

# информация о юзере [/user]

## Получить пользователя [GET]

Возвращает ошибку, если пользователь не авторизован

  + response 200 (application/json)

    + Attributes (UserData)

  + response 403 (application/json)

## Обновление [PUT]

Возвращает обновленного пользователя

  + response 200 (application/json)

    + Attributes (UserData)

# фото [/user/photo]

## Обновление [PUT]

  + response 200 (application/json)

    + Attributes (UserData)

## Удаление [DELETE]

  + response 200
