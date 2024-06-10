# LML

[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/LAffxdG5hFmx6iynRMGH5a/3NquNLfh34PueBmVqPWSwm/tree/main.svg?style=svg&circle-token=f22edd6262f0dad12f7984f1236d7dc43157ae8c)](https://dl.circleci.com/status-badge/redirect/circleci/LAffxdG5hFmx6iynRMGH5a/3NquNLfh34PueBmVqPWSwm/tree/main)

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
bin/rails server
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

# Deploying..
git push heroku <branchname>:main

# or from main
git push heroku main

# set up secret
bundle
./bin/rails secret
heroku config:set SECRET_KEY_BASE=the_secret_from_above

#add postgres basic plan
heroku addons:create heroku-postgresql:basic

heroku run rake db:migrate
heroku run rake db:seed

# rails console
heroku run bundle exec rails console
AdminUser.create!(email: "your email", password: "some password", time_zone: "Melbourne")

# to get a console
heroku ps:exec --app=live-music-locator 

# tail logs
heroku logs -t
```
