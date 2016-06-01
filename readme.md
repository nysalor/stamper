# stamper

出退勤を保存する（だけ）のAPI

----

## usage

### database

STAMPER_DB_NAME=stamper STAMPER_DB_USER=username STAMPER_DB_PASSWORD=password bundle exec ruby server.rb

### ユーザ作成

#### POST

```
curl -F "name=username" http://localhost:4567/users
```

#### response

```
{
  "success":true,
  "user":
    {
	  "id":1,
	  "name":"username",
	  "token":TOKEN
	  "secret":SECRET
	}
}
```

----

### 出勤

#### POST

```
curl -F "token=TOKEN" -F "secret=SECRET" http://localhost:4567/in

```

#### response

```
{
  "success":true

}
```

----

### 出勤訂正

#### POST

```
curl -F "token=TOKEN" -F "secret=SECRET" -F "time=2016-5-1 10:00:00" http://localhost:4567/in

```

#### response

```
{
  "success":true

}
```

----

### 退勤

#### POST

```
curl -F "token=TOKEN" -F "secret=SECRET" http://localhost:4567/out
```

#### response

```
{
  "success":true

}
```

----

### 退勤訂正

#### POST

```
curl -F "token=TOKEN" -F "secret=SECRET" -F "time=2016-5-1 10:00:00" http://localhost:4567/out

```

#### response

```
{
  "success":true

}
```

----

### csv

#### GET

```
curl "http://localhost:4567/csv/2016/05?token=TOKEN&secret=SECRET"
```

#### response

```
{
  csv: [
    "2016/05/1,10:00,18:00",
    "2016/05/2,10:30,19:00"
   ]
}
```

----

### time count

#### GET

```
curl "http://localhost:4567/timecount/2016/05?token=TOKEN&secret=SECRET"
```

#### response

```
{
  time: "16:30:00"
}
```
