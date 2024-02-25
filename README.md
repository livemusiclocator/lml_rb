# LML

To get this running:

Run postgres on the default 5432 port.

```
docker run \
    --rm \
    --name postgres-default \
    -d \
    -p 5432:5432 \
    -e POSTGRES_HOST_AUTH_METHOD=trust \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v postgres-default:/var/lib/postgresql/data \
    postgres
```

Install ruby 3.3.0 (using asdf)

```
```

Install dependencies

```
bundle
```

Create databases

```
bin/rails db:create db:migrate db:seed
```

Start rails

```
bin/rails start
```

Browse to https://localhost:3000/admin and log in as admin@example.com and password password
