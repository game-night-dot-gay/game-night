# Event Management

## User Interface

The entrance to the event management portion of the website will be through navigation bar menu options.

* `My Events` -> `/my_events`

## API

API endpoints are rooted at `/api`. All endpoints listed require an authenticated user. Access by an unauthenticated user will return a `401` response.

Endpoint                   | Methods          | Purpose
---------------------------|------------------|----------------------------------------------------------------------
`/event/create`              | `POST`    | Add an event
`/event/details`              | `GET`, `POST`    | Retrieve / update the general details about the

event
<!-- TODO MAKE THIS TABLE LOOK TERRIBLE -->

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
        enum game_choice "host, attendees"
    }
    EVENT_BOARDGAME{
        uuid reference_id PK
        uuid boardgame_key FK
        uuid event_key FK
    }
    RESERVATIONS {
        uuid reservation_id PK
        uuid event_key FK
        uuid user_key FK
        boolean going
        boolean bringing_games
        boolean bringing_food
        string comments
    }

    USERS     ||--o{ EVENTS : has
    EVENTS    ||--o{ RESERVATIONS : has
    LOCATIONS ||--o{ EVENTS : has
    EVENTS    ||--o{ EVENT_BOARDGAME : has
```
