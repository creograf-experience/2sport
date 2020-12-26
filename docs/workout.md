# Group Тренировки

# Список тренировок [/workouts]

## Список [GET]

  + response 200 (application/json)

    + Attributes (WorkoutList)

## Создать тренировку [POST]

  + response 200 (application/json)

    + Attributes (WorkoutData)

# Тренировка [/workouts/{_id}]

+ Parameters

  + _id: `1234567890abcdef12345678` (required, string)

## Обновление [PUT]

  + request

        {
          "track": [[1, 2, 3],[1, 2, 4]],
          "meanSpeed": 50,
          "maxSpeed": 50,
          "distance": 5000,
          "time": 96000,
          "type": "cycling"
        }

  + response 200 (application/json)

    + Attributes (WorkoutData)

## Завершение [POST /workouts/{_id}/finish]

  + response 200

    + Attributes (WorkoutData)

## Удаление [DELETE]

  + response 200
