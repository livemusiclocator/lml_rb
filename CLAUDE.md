# Working in this repo

## Any new button, form or link gets a system spec

A request spec proves the *endpoint* works. It cannot prove the *control* works,
and this repo has now shipped that exact gap three times:

- The price admin form asked for `lml_set_gig` element ids on a form that renders
  `lml_price_gig` ones, so its autocomplete picker never attached to anything.
- "Issue token" in backstage created a token and threw the secret away unseen,
  because Turbo discards a 200 HTML response to a form POST.
- "Grant admin" in ActiveAdmin did nothing, because `link_to ..., method: :post`
  is a plain GET without rails-ujs.

All three had passing request specs. So: **if you add or change a control that a
human clicks — a form, a button, a non-GET link, anything javascript driven —
add an example in `spec/system/` that clicks it.** Prove the spec is capable of
failing by breaking the thing and watching it go red before you commit.

`HEADED=1` puts a real Chrome window on screen, `SLOWMO=0.5` spaces the actions
out, and `page.driver.pause` breaks into it.

### Two traps that caused the above

**ActiveAdmin 3.5 ships no rails-ujs.** `link_to "x", path, method: :post` is
rendered as a GET and silently does nothing. Use a real form with an
authenticity token — every other non-GET action in `app/admin/` already does:

```ruby
form action: grant_admin_admin_user_path(resource), method: :post do
  text_node hidden_field_tag(:authenticity_token, form_authenticity_token)
  input type: :submit, value: "Grant admin access"
end
```

**Turbo discards a 200 HTML response to a form POST.** Either redirect (the
normal answer), return a turbo stream, or opt the form out with
`data: { turbo: false }` — and say why in a comment, or someone will tidy it back.

### Hosts in system specs

Routes are behind subdomain constraints, so a system spec has to arrive on a
host Rails can read a subdomain from. `spec/support/system.rb` defaults to
`api.lml.localhost` for ActiveAdmin and the API; assign
`Capybara.app_host = BACKSTAGE_APP_HOST` for anything under `/backstage`. A new
host also needs adding to `config.hosts` in `config/environments/test.rb` and to
`SYSTEM_SPEC_HOSTS`, or you get a "Blocked hosts" error page instead of your app.

## Specs

Use instance variables set in `before` blocks, not `let` / `let!`. The existing
specs do this consistently.

## Deploys

`.circleci/config.yml` gates deploys behind a manual `hold` job that is not
currently reachable, so deploys go straight to the heroku remote:

```
jj git push --remote origin --bookmark main
jj git push --remote heroku --bookmark main
```

**Migrations run themselves**, in `heroku.yml`'s release phase - after the image
is built, before the new release's dynos start. A failure there means the release
is not promoted and the old dynos keep serving, so a bad migration blocks the
deploy rather than crash-looping the app. Nothing to run by hand.

Two things this app does *not* work the way you would guess:

- **The `Procfile` is inert.** The app is on the `container` stack, so process
  types come from the image, not the `Procfile`. The web dyno runs the
  `Dockerfile`'s `CMD ["./bin/rails", "server"]`, not the `Procfile`'s puma
  line. A `release:` line in the `Procfile` would do nothing either, which is
  why the release phase lives in `heroku.yml`. The `Procfile`'s
  `worker: bundle exec good_job start` is not what would start a worker: the
  dyno formation holds only `web`, so declaring the process type is part of
  turning good_job on whenever there is async work to run. There is none yet,
  which is why nothing is running one.
- **`bin/docker-entrypoint` no longer migrates.** It used to run `db:prepare`
  on every web dyno boot, which raced when web scaled past one, fired on every
  restart, and applied migrations as the new code was already coming up.

The release phase runs while the *old* code is still serving, which is right for
an additive migration and not enough for a destructive one. Dropping or renaming
anything a running old release reads still wants expand and contract across two
deploys. Very long migrations want running out of band, since the release phase
is time limited and a timeout fails the deploy.
