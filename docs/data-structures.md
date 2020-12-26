# Data Structures

## UserData
+ _id: 1234567890abcdef12345678 (string) - ObjectId из mongoDB
+ name: Иван Иванов (required, string) - имя в свободной форме
+ email: ivanov@gmail.com (required, string)
+ gender: m (string) - пол m/f
+ unit: km/h (string) - единица измерения в настройках
+ isVisible: true (boolean) - могут ли пользователя видеть другие
+ isInvitable: true (boolean) - могут ли остальные приглашать на тренеровку
+ showSuggestions: true (boolean) - показывать предложения о возможных
  напарниках
+ suggestMale: true (boolean) - искать мужчин в напарники
+ suggestFemale: true (boolean) - искать женщин в напарники
+ ageRange: 18-25 (string) - искать людей этого возраста
+ dob: `1992-03-05T00:00:00.000Z` (string) - дата рождения
+ city: Челябинск (string) - город
+ photo: `{"profile": {"url": "/images/users/34534534.jpg"}}` (object) - фото

## WorkoutData
+ _id: 1234567890abcdef12345678 (string) - ObjectId из mongoDB
+ user: UserData (UserData) - пользователь
+ track: `[[1,2,3],[1,3,3],[2,3,3]]` - массив координат
+ meanSpeed: 50 (number) - средняя скорость
+ maxSpeed: 50 (number) - максимальная скорость
+ distance: 5000 (number) - общая дистанция
+ time: 96000 (number) - время тренировки в секундах
+ type: running (string) - вид тренировки. Может быть: running,
  cycling, skiing
+ isActive: true (boolean) - активна ли тренировка. Тренировка
  завершается, когда выставляешь isActive: false

## WorkoutList (array)
+ (WorkoutData)
