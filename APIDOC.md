# Live Music Locatior - API Documentation

## Introduction

If you are using this dataset, please acknowledge it with the following:

> Data courtesy of Live Music Locator: https://lml.live

The base URL for the API is:

```
https://api.lml.live
```

A note about timezones: dates do not have a time component, and times are stored as minutes since midnight in the local timezone of the gig. The API will show gigs for a specified date and location - it's up to the client to decide what "today" means.

## Authentication

All API endpoints are open and do not require authentication.

## Endpoints

### Gigs

#### GET /gigs

Index endpoint which returns a list of commonly used API queries.

Params: None

Example:

```
curl https://api.lml.live/gigs | jq
```

```
{
  "links": {
    "_self": {
      "href": "https://api.lml.live/gigs"
    },
    "default": {
      "href": "https://api.lml.live/gigs/query"
    },
    "today": {
      "href": "https://api.lml.live/gigs/query?date_from=2025-01-06&date_to=2025-01-06&location=castlemaine"
    },
    "next_seven_days": {
      "href": "https://api.lml.live/gigs/query?date_from=2025-01-06&date_to=2025-01-13&location=castlemaine"
    },
    "this_weekend": {
      "href": "https://api.lml.live/gigs/query?date_from=2025-01-10&date_to=2025-01-12&location=castlemaine"
    },
    "next_weekend": {
      "href": "https://api.lml.live/gigs/query?date_from=2025-01-17&date_to=2025-01-19&location=castlemaine"
    },
    "on_date": {
      "href": "https://api.lml.live/gigs/query?date_from=date&date_to=date&location=castlemaine",
      "templated": true
    }
  }
}
```

#### GET /gigs/query

Query all gigs by date range and location.

Params: 

```
date_from: Date in format `YYYY-MM-DD` (required)
date_to: Date in format `YYYY-MM-DD` (required)
location: String (required)
token: An API token
```

If no `location`, `date_from`, and `date_to` are provided, returns an empty array. The `location` parameter is a string representing the gig location, for example *melbourne* or *goldfields*. Only fetches gigs for up to 7 days from `date_from` unless a valid `token` is supplied. 

Example:

```
curl https://api.lml.live/gigs/query \
    --url-query location=melbourne \
    --url-query date_from=2025-01-06 \
    --url-query date_to=2025-01-06 | jq '.[:1]'
```

```
[
  {
    "id": "cf7e468c-be2f-4ef3-b392-79583f89d436",
    "name": "DNB Mondays Hello 2025",
    "date": "2025-01-06",
    "ticketing_url": null,
    "start_time": "17:55",
    "start_timestamp": "2025-01-06T17:55:00.000+11:00",
    "duration": null,
    "finish_time": null,
    "finish_timestamp": null,
    "description": null,
    "status": "confirmed",
    "ticket_status": null,
    "series": null,
    "category": null,
    "information_tags": [
      "Free"
    ],
    "genre_tags": [
      "DNB"
    ],
    "venue": {
      "id": "1799e48d-d69b-447e-b021-bde1e3fce9e4",
      "name": "Radio Bar and Cafe",
      "address": "357 Brunswick Street Fitzroy",
      "capacity": 90,
      "website": "https://www.instagram.com/radio_bar/",
      "postcode": "3065",
      "vibe": null,
      "tags": [],
      "location_url": null,
      "latitude": -37.796438,
      "longitude": 144.978574
    },
    "sets": [
      {
        "start_time": null,
        "start_timestamp": null,
        "duration": null,
        "finish_time": null,
        "finish_timestamp": null,
        "act": {
          "id": "8fba6235-6cc2-4e8f-8889-e73735d1d678",
          "name": "DNB Mondays Hello 2025",
          "genres": null
        }
      },
      {
        "start_time": null,
        "start_timestamp": null,
        "duration": null,
        "finish_time": null,
        "finish_timestamp": null,
        "act": {
          "id": "e48bd2b5-4310-4db7-9654-ce9056414515",
          "name": "Radio Bar",
          "genres": null
        }
      }
    ],
    "prices": []
  }
]
```

#### GET /gigs/:id

Find a gig by id.

Params:

```
id: UUID (required)
```

Example:

```
curl https://api.lml.live/gigs/0a4427bc-8968-4253-9cb5-b906ec121b42 | jq
```

```
{
  "id": "0a4427bc-8968-4253-9cb5-b906ec121b42",
  "name": "Black Jesus Experience",
  "date": "2025-02-23",
  "ticketing_url": null,
  "start_time": "18:30",
  "start_timestamp": "2025-02-23T18:30:00.000+11:00",
  "duration": null,
  "finish_time": null,
  "finish_timestamp": null,
  "description": null,
  "status": "confirmed",
  "ticket_status": null,
  "series": null,
  "category": null,
  "information_tags": [
    "free"
  ],
  "genre_tags": [
    "Funk",
    "Hip-Hop",
    "Azmari"
  ],
  "venue": {
    "id": "0e9591fc-2b76-4735-8f63-5b105b657eae",
    "name": "the Horn African Cafe",
    "address": "20 Johnston Street Collingwood",
    "capacity": null,
    "website": "http://thehorncafe.com.au/",
    "postcode": "3066",
    "vibe": "African groove",
    "tags": [],
    "location_url": "37.7989764,144.985427",
    "latitude": -37.798948,
    "longitude": 144.985472
  },
  "sets": [],
  "prices": []
}
```

#### GET /gigs/for/:location/:date

List gigs at specified location and date.

Params:

```
location: String (required)
date: Date in format `YYYY-MM-DD` (required)
```

If no `location` and `date` are provided, returns an empty array. The `location` parameter is a string representing the gig location, for example *melbourne* or *goldfields*.

Example:

```
curl https://api.lml.live/gigs/for/melbourne/2025-01-06 | jq '.[:1]'
```

```
[
  {
    "id": "cf7e468c-be2f-4ef3-b392-79583f89d436",
    "name": "DNB Mondays Hello 2025",
    "date": "2025-01-06",
    "ticketing_url": null,
    "start_time": "17:55",
    "start_timestamp": "2025-01-06T17:55:00.000+11:00",
    "duration": null,
    "finish_time": null,
    "finish_timestamp": null,
    "description": null,
    "status": "confirmed",
    "ticket_status": null,
    "series": null,
    "category": null,
    "information_tags": [
      "Free"
    ],
    "genre_tags": [
      "DNB"
    ],
    "venue": {
      "id": "1799e48d-d69b-447e-b021-bde1e3fce9e4",
      "name": "Radio Bar and Cafe",
      "address": "357 Brunswick Street Fitzroy",
      "capacity": 90,
      "website": "https://www.instagram.com/radio_bar/",
      "postcode": "3065",
      "vibe": null,
      "tags": [],
      "location_url": null,
      "latitude": -37.796438,
      "longitude": 144.978574
    },
    "sets": [
      {
        "start_time": null,
        "start_timestamp": null,
        "duration": null,
        "finish_time": null,
        "finish_timestamp": null,
        "act": {
          "id": "8fba6235-6cc2-4e8f-8889-e73735d1d678",
          "name": "DNB Mondays Hello 2025",
          "genres": null
        }
      },
      {
        "start_time": null,
        "start_timestamp": null,
        "duration": null,
        "finish_time": null,
        "finish_timestamp": null,
        "act": {
          "id": "e48bd2b5-4310-4db7-9654-ce9056414515",
          "name": "Radio Bar",
          "genres": null
        }
      }
    ],
    "prices": []
  }
]
```
