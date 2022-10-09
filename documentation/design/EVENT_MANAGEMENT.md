# Event Management

## User Interface

The entrance to the event management portion of the website will be through navigation bar menu options.

* `My Events` -> `/my_events`



## API

API endpoints are rooted at `/api`. All endpoints listed require an authenticated user. Access by an unauthenticated user will return a `401` response.

Endpoint                   | Methods          | Purpose
---------------------------|------------------|----------------------------------------------------------------------
`/event/create`              | `POST`    | Add an event
`/event/details`              | `GET`, `POST`    | Retrieve / update the general details about the event


## Database Models

```mermaid
erDiagram
    EVENTS {
        uuid event_id PK
        uuid host_user_key FK
        uuid location_key FK
        string display_name "not null"
        string description "not null"
        enum status "draft, upcoming, past, cancelled"
        timestamp start_time "not null"
        timestamp end_time "not null"
        enum food "bring, order"
        enum games "bring, host_collection, list"
        uuid[] boardgame_keys FK
    }
    RSVPS {
        uuid rsvp_id PK
        uuid event_key FK
        uuid user_key FK
        boolean attending
        boolean bringing_games
        boolean bringing_food
        uuid[] boardgame_ids FK
        string notes
    }
    USERS ||--o{ EVENTS : has
    EVENTS ||--o{ RSVPS : has
    EVENTS ||--o{ LOCATIONS : has
    EVENTS ||--o{ BOARDGAMES : has
```
