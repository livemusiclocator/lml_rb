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

install precommit hooks if you want to:

```
lefthook install

```

Create databases and add seed data

```
bin/rails db:reset
```

Make sure www.lml.local resolves to localhost ( /etc/hosts entry or find a better way to do it )

Start dev services (including rails server on port 3000 and some tailwind things)

```
RAILS_DEVELOPMENT_HOSTS=www.lml.local ./bin/dev
```

Browse to https://localhost:3000/admin and log in as admin@example.com and password password


## Active admin styles

Conflicts with tailwind and sass-rails mean we had to take out sass-rails and sass in general. As a result, the active_admin.css has been prebuilt from the former scss code. To refresh these styles, something like the following will work:

+ Restore old active_admin.scss file
+ Add gem "sass-rails" to Gemfile
+ bundle install
+ rails assets:precompile
+ Find active_admin*.css in public/assets/
+ Copy contents to new app/assets/stylesheets/active_admin.css
+ Remove Sass gem and .scss file 

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


# More things to go into the readme

+ How to run locally with front end code
+ Where everthing deploys to and the subdomain constraints active
