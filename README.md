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

Install ruby version using asdf

```
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
. "$HOME/.asdf/asdf.sh"
asdf plugin add ruby
asdf install
```

Install dependencies

```
brew install libpq postgresql
# may need to add libpq to PATH
bundle
```

Create databases and add seed data

```
bin/rails db:reset
```

Start rails

```
bin/rails start
```

Browse to https://localhost:3000/admin and log in as admin@example.com and password password


## Heroku Stuff

```
# how I made the Heroku deployment

brew tap heroku/brew && brew install heroku
heroku login

# to use Heroku CLI you need a verified account == enter your credit card in your personal account (I think)

heroku create live-music-locator -t glassbeams
heroku stack:set container

```
