# Importing venues from a Google Sheet

A flat spreadsheet of venues is read directly out of Google Sheets, each row is
resolved through the Google Places API for structured address data, matched
against existing venues, created if it is new, and the outcome written back into
the row it came from.

Nothing is downloaded or uploaded. The sheet is the input, the working document
and the record of what happened, so a run can be watched as it goes and re-run
after more rows are added.

## Credentials

Two separate credentials, because they authenticate different things:

| Credential | Used for | Env var |
| --- | --- | --- |
| Service account JSON key | Reading and writing the sheet | `GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS` (base64) |
| API key | Places API text search | `GOOGLE_PLACES_SERVER_KEY` |

A service account is used for Sheets rather than OAuth because there is no user
to consent — access is granted by sharing the sheet with the service account's
email address, the same way you would share it with a colleague. Places has no
per-document concept, so a plain API key is enough.

Every step below is done with `gcloud`, because the console equivalents are a
dozen pages of clicking and impossible to write down accurately for long. The one
exception is sharing the sheet, which has to be done in the Sheets UI.

### 1. Install gcloud

```sh
brew install --cask gcloud-cli
```

The cask used to be called `google-cloud-sdk`; that name still works as an alias
but the current one is `gcloud-cli`. It auto-updates, so `gcloud components
update` will tell you it is managed externally — that is fine and not a problem
to fix.

Check it:

```sh
gcloud version
```

### 2. Authenticate, in its own configuration

A machine that already does other Google Cloud work has an active account
already, and `gcloud` only has one at a time. Give LML its own named
configuration first, so none of this disturbs what is already set up and nothing
later has to be switched back and forth:

```sh
gcloud config configurations create lml     # creates it and makes it active
gcloud auth login
```

`auth login` opens a browser. **Log in as the Google account that should own LML's
cloud resources** — not a work account. This is the step most worth slowing down
on: creating the project under the wrong account puts it in the wrong
organisation with the wrong billing account, and that cannot be fixed afterwards
without moving or recreating the project.

From then on, `gcloud config configurations activate lml` switches to it and
`gcloud config configurations list` shows which one is live. Check both before
running anything that creates a resource:

```sh
gcloud config list        # account and project in play right now
gcloud auth list          # every credentialed account, * marks the active one
```

There is no need to run `gcloud auth application-default login`. That sets up
Application Default Credentials for libraries that look them up implicitly, and
this app does not — it is handed an explicit service account key instead.

### 3. Create the project and attach billing

```sh
gcloud projects create lml-venue-import --name="LML Venue Import"
gcloud config set project lml-venue-import
```

The project id is globally unique across all of Google Cloud, so a plain name is
often taken and it may need a suffix. An existing LML project is fine too — skip
the create and just set it, which is what every later command reads.

Billing has to be enabled, because Places (New) will not serve a request without
it. Sheets is free; Places text search is billed per request with a monthly free
allowance.

```sh
gcloud billing accounts list
gcloud billing projects link lml-venue-import --billing-account=XXXXXX-XXXXXX-XXXXXX
```

Linking billing needs the Billing Account Administrator role on the billing
account, which a personal account has over its own. If it is someone else's, they
have to do this part — or do it in the console, where it is one dropdown.

### 4. Enable the APIs

```sh
gcloud services enable \
  sheets.googleapis.com \
  places.googleapis.com \
  apikeys.googleapis.com
```

`places.googleapis.com` is **Places API (New)**. There is also a legacy "Places
API" (`maps-backend.googleapis.com`); it is a different product with a different
request format and will not serve the `v1/places:searchText` endpoint we call.
Enabling the wrong one is the single most likely reason for a 403 later.

`apikeys.googleapis.com` is only needed so that step 6 can create the Places key
from the terminal.

Confirm all three took:

```sh
gcloud services list --enabled | grep -E "sheets|places|apikeys"
```

### 5. Create the service account and its key

```sh
gcloud iam service-accounts create lml-venue-importer \
  --display-name="LML venue importer"
```

**Grant it no project roles.** It needs none — its only permission is whatever
the sheet is shared with, which is the entire point of using a service account
here. Any `add-iam-policy-binding` you are tempted to run is a wider grant than
this needs.

Then the key:

```sh
gcloud iam service-accounts keys create ~/lml-venue-importer.json \
  --iam-account=lml-venue-importer@lml-venue-import.iam.gserviceaccount.com
```

The private key exists only in that file — Google does not keep a copy. If it is
lost, delete the key (`gcloud iam service-accounts keys list` /
`keys delete`) and create another.

Its email address is what the sheet gets shared with:

```sh
gcloud iam service-accounts list --format="value(email)"
```

The app takes the whole key as one base64 env var rather than a file path, so
there is no secret file to deploy:

```sh
base64 -i ~/lml-venue-importer.json | tr -d '\n'
```

Keep the file until step 8 has put it into both the local and the production
environment, then delete it. (`/*.json` is already gitignored, so a key that lands
in the repo root will not be committed by accident — but it should not live there
either.)

### 6. Create the Places API key

The key is restricted to Places on creation, because an unrestricted key that
leaks is billable by anyone who finds it:

```sh
gcloud services api-keys create \
  --display-name="LML venue import places key" \
  --api-target=service=places.googleapis.com
```

That prints an operation, not the key itself. The secret has to be fetched
separately, which is what the env var wants:

```sh
gcloud services api-keys list --format="value(name)"
gcloud services api-keys get-key-string <the name printed above>
```

`get-key-string` takes either the bare key id or the fully qualified
`projects/…/keys/…` name that `list` prints, so the two commands paste together.

No *application* restriction is set, because this is called server side — the
referrer and Android/iOS restrictions do not apply to it. Add
`--allowed-ips=…` if the production egress IPs are ever known and stable.

### 7. Share the sheet with the service account

This one is manual — there is no `gcloud` for it, since Drive sharing is not a
Cloud resource.

Open the sheet → **Share** → paste the service account email → give it
**Editor** (it writes back ids, status and row colours) → untick *Notify people*,
since there is no inbox on the other end.

That is the whole authorisation step. If it is missed, the importer fails with a
404 on the spreadsheet id rather than a permission error, because an unshared
document is invisible rather than forbidden.

### 8. Configure the environment

Note that none of this uses your `gcloud` login at runtime — that was only for
setting the resources up. The app authenticates as the service account, so the
env vars are all it needs and a machine running the import does not need `gcloud`
installed at all.

Locally, `mise` is already the tool that runs this repo, so put them in a
`mise.local.toml` (already gitignored):

```toml
[env]
GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS = "ewogICJ0eXBlIjog..."
GOOGLE_PLACES_SERVER_KEY = "AIza..."
```

In production (Heroku, per the `Procfile`):

```sh
heroku config:set \
  GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS="$(base64 -i ~/lml-venue-importer.json | tr -d '\n')" \
  GOOGLE_PLACES_SERVER_KEY=AIza...
```

### 9. Check it end to end

```rb
# bin/rails console
Lml::Sheet.service_account_email      # the address the sheet has to be shared with
Lml::Sheet.new("https://docs.google.com/spreadsheets/d/…/edit").rows(worksheet: "venues").first
Lml::GooglePlacesApiClient.new.find("The Espy, St Kilda", region_code: "AU")
```

Three calls, three failure modes to tell apart: the first proves the key decodes,
the second proves the sheet is shared with it, the third proves Places is enabled
and the API key is unrestricted enough.

Then the import itself:

```rb
Lml::VenueImport.call("https://docs.google.com/spreadsheets/d/…/edit")
# => { "created" => 12, "matched" => 3, "ambiguous" => 1 }
```

## The sheet

Row 1 is headers, data starts at row 2. Header names are the contract, column
order is not — columns are addressed by name, so they can be reordered and
unrelated columns can sit between them.

Input columns, all optional except `name`:

| Column | Notes |
| --- | --- |
| `name` | **The only required one.** Joined to `address` to build the Places query. A blank one is flagged rather than looked up. |
| `address` | Free text, as written by whoever researched the venue. Not required, but a name on its own is much more likely to come back ambiguous. |
| `location` | LML's internal location identifier (`melbourne`, `stkilda`, …), not a suburb. Places cannot supply this. |
| `time_zone` | Defaults to `Australia/Melbourne`. Must be one of `Lml::Timezone::CANONICAL_TIMEZONES`. |
| `website`, `email`, `phone` | Copied straight onto the venue. |
| `facebook_url`, `instagram_url`, `location_url` | Copied straight onto the venue. |
| `capacity` | Copied straight across; a number. |
| `vibe`, `notes` | Copied straight across; free text. |
| `tags` | Comma separated, e.g. `live music, band room`. |

Anything else is ignored, so columns tracking who researched a row or what still
needs checking can sit alongside these without upsetting the import.

`postcode`, `latitude` and `longitude` are deliberately **not** read from the
sheet even though they are venue fields — Places supplies them, and a column of
that name is silently ignored. That is the one worth knowing about, since it is a
natural column to add by hand.

Output columns, written back as each row is decided:

| Column | Notes |
| --- | --- |
| `venue_id` | The uuid of the matched or created venue. |
| `import_status` | One of the outcomes below, with an explanation appended where there is one to give. |

Both are appended to the header row by the importer if they are not already
there, so a new sheet only needs the input columns.

### A sample sheet

The smallest useful starting point. Paste this into cell A1 of a new sheet, then
**Data → Split text to columns**:

```csv
name,address,location
The Espy,11 The Esplanade St Kilda,stkilda
Corner Hotel,57 Swan Street Richmond,melbourne
Northcote Social Club,301 High Street Northcote,melbourne
```

Or with every column the importer reads, for a sheet meant to carry the full
research rather than just enough to match on:

```csv
name,address,location,time_zone,website,email,phone,capacity,vibe,tags,facebook_url,instagram_url,location_url,notes
The Espy,11 The Esplanade St Kilda,stkilda,Australia/Melbourne,https://hotelesplanade.com.au,,,800,seaside art deco pub,"live music, band room",,,,four stages
Corner Hotel,57 Swan Street Richmond,melbourne,,https://cornerhotel.com,,,800,sweaty rock room,"live music, rooftop",,,,
```

Note the quoting on `tags` — a comma separated list inside a comma separated
file has to be quoted, and Sheets will strip the quotes on paste. Blank cells are
fine and mean "leave it unset"; `time_zone` is empty on the second row to show it
falling back to `Australia/Melbourne`.

After a run, the same sheet has two more columns and a colour per row:

| name | address | venue_id | import_status |
| --- | --- | --- | --- |
| The Espy | 11 The Esplanade St Kilda | `9f3c…` | `created` 🟩 |
| Corner Hotel | 57 Swan Street Richmond | `1a7e…` | `matched` 🟩 |
| Northcote Social Club | 301 High Street Northcote | | `ambiguous - 2 places: Northcote Social Club \| NSC Bandroom` 🟨 |

Run it again and the first two rows are skipped untouched, while the third is
retried — so the way to work through the yellow rows is to fix the address and
re-run, as many times as it takes.

Every row is coloured as it is processed, so progress is visible while a run is
happening and the shape of the result is readable afterwards without reading a
single cell:

- **light green** — created or matched cleanly
- **light yellow** — needs a person to look at it (ambiguous address, no Places
  result, more than one candidate venue, or a row that raised)
- **unchanged** — already had a `venue_id` from an earlier run, left alone

A row that already carries a `venue_id` is skipped entirely. That is what makes
the import safe to re-run: adding thirty rows to the bottom of the sheet and
running it again touches only those thirty.

## Structured addresses

`GooglePlacesApiClient#find` does a text search and returns, per place, its
`addressComponents`, `location` and `displayName`. The components are flattened
into a hash keyed by component type:

```json
{
  "street_number": "11",
  "route": "The Esplanade",
  "locality": "St Kilda",
  "administrative_area_level_1": "VIC",
  "postal_code": "3182",
  "country": "AU",
  "latitude": "-37.8676",
  "longitude": "144.9756",
  "name": "Hotel Esplanade"
}
```

This needs a migration, since `venues` has nowhere to keep it:

- `address_components` `jsonb` — the hash above, and what matching is done on
- `google_place_id` `string` — Google's stable id for the place, for re-lookup
- `google_business_status` `string` — `OPERATIONAL`, `CLOSED_TEMPORARILY` or
  `CLOSED_PERMANENTLY`

The existing `latitude`, `longitude` and `postcode` columns keep being populated
from the resolved components, so nothing downstream has to learn about the new
column.

### What is asked for, and what it costs

Places bills per request by the **most expensive tier any requested field belongs
to**, so the field mask is the price. Everything in `FIND_FIELDS` is in the **Pro**
tier, which the call was already in for `addressComponents` alone — so all of it
together costs exactly what the original four fields did:

| Field | Used for |
| --- | --- |
| `id`, `displayName`, `formattedAddress`, `location`, `addressComponents` | Matching, and the address itself |
| `googleMapsUri` | `location_url` |
| `timeZone` | `time_zone`, where the sheet gave none — see below |
| `businessStatus` | `google_business_status` — spotting venues that have closed |

Google answers with an IANA identifier, which goes through
`Lml::Timezone.canonical` rather than being taken at face value, because a venue
whose `time_zone` is outside `CANONICAL_TIMEZONES` fails validation:

- Every **modern** Australian IANA zone is already in `CANONICAL_TIMEZONES`, so in
  the normal case there is nothing to map.
- IANA's **deprecated** Australian names (`Australia/Victoria`, `Australia/NSW`,
  `Australia/Yancowinna`, …) map onto ours through `Lml::Timezone::TIMEZONES`.
  Google should never return one, but they are valid identifiers and converting
  them costs nothing.
- Anywhere we have no zone for — an overseas venue resolving to `Europe/London` —
  gives **nil**, and the venue falls back to `Australia/Melbourne` rather than
  becoming unsaveable.

A spec asserts the invariant directly: every identifier in IANA's `Australia/*`
must map to a zone we accept, or a venue in that state would silently get the
Melbourne default.

`websiteUri` and `nationalPhoneNumber` would fill two more columns but are
**Enterprise** tier, and `liveMusic`, `editorialSummary` and the rest of the
atmosphere fields are **Enterprise + Atmosphere**. Adding any of them moves the
SKU for *every* request, including rows that turn out to be duplicates, so it is a
deliberate decision rather than a free one. `types` is free but deliberately not
wired: Google's are noisy (`point_of_interest`, `establishment`) and LML's tags
are curated and user-facing.

At the time of writing the tiers cost $32 / $35 / $40 per 1,000 requests. **The
per-request delta matters much less than the free allowance**, which is 5,000
calls a month on Pro and only 1,000 on either Enterprise tier — so moving up cuts
the free allowance fivefold. With roughly 1,150 venues in total, every tier is
free for a one-off pass; the cost only starts to bite on repeated large runs.

The definitive check on which tier a mask lands in is one real call followed by
reading the SKU off the billing report — Google's own docs disagree with
themselves in places.

### Matching

A subset of the components define address identity and are what an existing
venue is looked up by, using a jsonb containment query:

```rb
Lml::Venue.where("address_components @> ?::jsonb", criteria.to_json)
```

Matching on the structured components rather than on the address string is the
reason to involve Places at all — "11 The Esplanade, St Kilda" and "The
Esplanade, St Kilda VIC 3182" are the same venue and different strings, and no
amount of normalising gets you there reliably.

`@>` is subset matching, so a venue carrying identity keys we did not ask for —
typically a `subpremise` — is a different address in the same building rather
than this one, and is not treated as a match.

Because no existing venue has components until something matches it and fills
them in, a row that finds nothing structurally falls back to a case-insensitive
name match, and a venue matched that way has its components backfilled. The
fallback therefore fades out on its own as the data improves.

| Outcome | Colour | Meaning |
| --- | --- | --- |
| `created` | green | One place, nothing at that address, venue created |
| `matched` | green | One place, exactly one venue with those components (or that name) |
| `already imported` | *unchanged* | Row already had a `venue_id`; skipped before any Places call |
| `no name` | yellow | Nothing to query Places with |
| `not found` | yellow | Places returned no places |
| `ambiguous` | yellow | Places returned more than one place; a few are named in the cell |
| `several venues` | yellow | Several venues share this address; the names are in the cell |
| `same building` | yellow | Venues at this street address, but all with an extra `subpremise` |
| `failed - …` | yellow | The row raised; the message is in the cell and the log |

Refusing to guess on anything yellow is deliberate. A wrong match silently
attaches gigs to the wrong venue, and that is far more expensive to unpick later
than a yellow row is to look at now.

### What a second run costs

The `venue_id` check happens **before** the Places call, so re-running is cheap
but not free — and which rows it asks about again is exactly the green/yellow
split:

| Row from the last run | Second run |
| --- | --- |
| green (`created` / `matched`) | **no Places call.** Skipped on its `venue_id` before anything is asked |
| yellow (`not found`, `ambiguous`, `same building`, …) | **asked again.** No `venue_id` was written, so there is nothing to skip on |

That is the behaviour you want — correcting an address and re-running is how the
yellow rows get worked through — but it means a sheet left sitting full of yellow
rows costs one request per yellow row every single time it is run. A sheet of a
hundred rows where ninety resolved cleanly costs ten requests to run again, not a
hundred.

So: re-run freely while you are fixing rows, but do not leave a large sheet of
unresolvable rows on a schedule. Rows you have given up on are best deleted, or
given a `venue_id` by hand if you have matched them yourself.

## Backfilling the venues we already have

Structural matching only works against venues that have components, and none did
before this existed — which is why the name fallback is there. `Lml::VenueBackfill`
resolves the venues we already have so the fallback stops being needed:

```rb
Lml::VenueBackfill.call(dry_run: true)   # what it would do, spends nothing
Lml::VenueBackfill.call                  # venues with gigs in the last 3 months
Lml::VenueBackfill.call(months: 12)

# => { "filled" => 240, "not found" => 31, "ambiguous" => 13 }
```

It is scoped to venues with a **visible gig** (not hidden, not a draft) in the
window, with no upper bound on the date so anything with something coming up
counts as active too:

```rb
Lml::Venue.with_gigs_since(3.months.ago.to_date)
```

Measured against production: **284 of 1,155 venues** have gigs in the last three
months, 460 in the last twelve. The window is **not** about cost — even all 1,155
fits inside Pro's free monthly allowance. It is about not resolving rows that have
not earned it: a venue nobody has programmed in a year is as likely to be a typo
or a duplicate as a real place, and giving it a structured address only teaches
future imports to match against the mistake.

Outcomes, counted and returned:

| Outcome | Meaning |
| --- | --- |
| `filled` | Resolved cleanly and written |
| `already resolved` | Had components already; skipped before any Places call |
| `not found` | Places returned nothing; left alone |
| `ambiguous` | Places returned more than one place; left alone |
| `failed` | Raised; logged, and the run carries on to the next venue |

There is no sheet to write into and no row to colour here, so anything other than
`filled` is simply left as it was. What needs a person is the difference:

```rb
Lml::Venue.with_gigs_since(3.months.ago.to_date).where(address_components: {})
```

### What gets written, and what is left alone

Three different rules, because "derived" is not one thing:

| | Fields | Rule |
| --- | --- | --- |
| Identity | `address_components`, `google_place_id` | Written **once**, then never again |
| Volatile | `google_business_status` | Rewritten **every** time |
| Fill-ins | `time_zone`, `location_url`, `address`, `postcode`, `latitude`, `longitude` | Written **only if the venue is blank** |

Identity is written once because re-resolving could point a venue at a *different*
place — a name match on two venues sharing a name is enough — and silently moving
an established venue's address is worse than holding a slightly stale one. It is
also all-or-nothing: a venue with components but no place id keeps both as they
are, rather than being told its address came from a place it did not.

Business status is the opposite: whether a venue is still trading is the one thing
here that genuinely changes, and a stale value is the whole problem.

Fill-ins never overwrite, because a blank column is a gap and a filled one is
somebody's research. Google is not a good enough reason to argue with a person.

Finding what has closed since, which is the point of tracking it:

```rb
Lml::Venue.with_gigs_since(3.months.ago.to_date).where(google_business_status: "CLOSED_PERMANENTLY")
```

A permanently closed venue with recent gigs is worth a look either way — either
the gigs are wrong or Google is.

### Transient failures

A run of a few hundred venues will meet the odd failure that has nothing to do
with the request:

- **503** — Google's side is briefly at capacity. Not throttling, and one in a few
  hundred is normal.
- **429** — a rate limit, ours rather than theirs.

`GooglePlacesApiClient` retries both, along with dropped connections, with the
exponential backoff Google's best-practices page asks for: 100 ms, doubling, up to
four attempts. Retrying lives in the client so the sheet import gets it too.

What is deliberately **not** retried is anything waiting cannot fix — a **403**
for an API that is not enabled, a **400** for a malformed request. Google's page
suggests retrying 4XX as well, but that only makes a misconfiguration take four
times as long to report.

A venue that still fails after all four attempts is counted `failed`, logged, and
left unresolved — so the fix is simply to run it again, which only spends requests
on the venues that are still unresolved.

## Looking up one venue, on demand

The backfill is a batch job scoped to venues with recent gigs. `Lml::VenuePlaceLookup`
is the single-venue version, for somebody sitting on a venue's admin page who wants
an answer about *that* venue now — the "Look up in Google Places" button in the
Google Places panel, and `POST /v1/admin/venues/:id/place_lookup` in the admin API.

```rb
Lml::VenuePlaceLookup.call(venue)              # => :matched / :no_match / :ambiguous / :skipped
Lml::VenuePlaceLookup.call(venue, force: true) # ask again anyway
```

```sh
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://api.lml.live/v1/admin/venues/$ID/place_lookup

# {"outcome":"ambiguous","venue":{...,"google_place_id":"ambiguous - 2 matches"}}
```

It resolves exactly as the backfill does — same query (name, then address), same
region bias, and the same three rules above for what gets written. The difference
is what it does when the lookup *does not* settle.

### Unsuccessful lookups are written down

The backfill counts a `not found` and moves on, because the count is the report.
A person clicking a button has no report, so the outcome goes into
`google_place_id` as a marker instead:

| Outcome | `google_place_id` becomes |
| --- | --- |
| One place | its real place id |
| Nothing found | `no match` |
| Several found | `ambiguous - 3 matches` |

Nothing else is written in the unsuccessful cases — an ambiguous venue keeps its
blank `address_components`, and a person decides.

Markers are told apart from real ids by `Lml::Venue#google_place_marker?`: a
Google place id is url-safe base64, so it never contains a space and every marker
does. The show page renders a marker as an orange status tag rather than as an id.

### Asking twice costs twice

Every call is billable, so **anything at all** in `google_place_id` — a real id
*or* a marker — means the question has been asked and the answer stands. The
button is rendered disabled, and the API returns `{"outcome":"skipped"}` without
touching Google.

`force: true` asks again. It is deliberately API-only, with nothing in the UI:
re-spending on a venue should be something you have to mean, and the realistic
caller is a script sweeping the venues that came back `no match` after their
addresses were tidied up.

Forcing still cannot *repoint* a venue that is genuinely resolved — identity is
write-once, per the table above — so a forced lookup on a venue with components
refreshes its business status and leaves its place id alone. Where forcing earns
its keep is on the marker venues, whose `address_components` are blank, so a
second lookup that settles replaces the marker with a real id.

## The code

Modelled on `Management::SupplierLaunches` in fresho-app, which does the same job
for customers and has already been through the failure modes.

| File | Responsibility |
| --- | --- |
| `app/models/lml/sheet.rb` | Google Sheets read/write: rows as hashes keyed by header, `ensure_headers`, `write_row` with cells and a colour |
| `app/models/lml/google_places_api_client.rb` | Faraday wrapper over `places.googleapis.com/v1`, and the field mask that sets the price |
| `app/models/lml/place.rb` | One place as Places returned it: flattened components, matching identity, and what it settles about a venue |
| `app/models/lml/venue_import.rb` | The sheet import: for each row, resolve, match or create, write the outcome back |
| `app/models/lml/venue_backfill.rb` | The same resolution for venues we already have |
| `app/models/lml/venue_place_lookup.rb` | The same resolution for one venue, on demand, recording the unsuccessful outcomes too |

`Lml::Place` is where both of them meet, so there is one answer to "what does
Google tell us about this venue" rather than two that drift apart. It holds
`MATCH_KEYS`, and `Lml::Venue#address_identity` is the same slice taken of a stored
venue — matching is comparing those two.

`Lml::VenueImport.call(url)` and `Lml::VenueBackfill.call` are deliberately just
class methods returning a count per outcome, so wrapping either in a good_job job,
a rake task or an ActiveAdmin action later is a few lines each and none of them
change this.

The show page for a venue has a read-only **Google Places** panel with the place
id, business status, the identity that matching uses and the full components as
indented json. Neither column is in `permit_params`, so the form cannot reach
them — the importer and the backfill are the only writers.

Two things worth knowing before running it at size:

- **Sheets allows about sixty writes a minute per account.** Writing a row at a
  time is what makes a run watchable, and it happens to sit exactly on that
  limit — hence the one second pause per row. A sheet of hundreds of rows wants
  batched column writes instead, at the cost of the live progress.
- **Places text search is billed per request**, one per unprocessed row. Rows
  already carrying a `venue_id` are skipped before any call is made, so re-runs
  are nearly free.
