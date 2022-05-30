# Home Page

The home page will be the user's main point of contact with the application, especially when installed as a [Progressive Web App](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps). As such, it should present all of the information necessary for the core workflows of the application (mainly scheduling and attending events).

## UI

The UI should be mobile friendly.

* There should be a top bar.
  * On the left, there should be the application's logo.
  * On the right, there should be a series of options
    * In widescreen, these options should always display
    * On mobile, there should be an expand/collapse toggle
    * First, there should be "Profile", which links to `/profile`
    * Next, there should be "Boardgames", which links to `/boardgame_library`
    * If the user is an admin, there should be "Admin", which links to `/admin`
    * Lastly, there should be a "Log out option", which links to `/auth/logout`
* In the center, there should be a section labeled "Your Upcoming Events"
  * This should display all of the events you have RSVP'd for or are hosting
  * This should have a grid listing on widescreen and a stacked group listing on mobile
  * The first column should be the date & time
  * The second column should be the vague location of the event
    * This should display an indicator if the user is the one hosting
  * The third column should be a "details" link that takes you to `/events/<event ID>`
* Below that, there should be a section labeled "Upcoming Events"
  * This should display all of the events you are not RSVP'd for and are not hosting
  * This should have a grid listing on widescreen and a stacked group listing on mobile
  * The first column should be the date & time
  * The second column should be the vague location of the event
  * The third column should be a "details" link that takes you to `/events/<event ID>`

## API

API endpoints are rooted at `/api`. All endpoints listed require an authenticated user. Access by an unauthenticated user will return a `401` response.

Endpoint           | Methods | Purpose
-------------------|---------|------------------------------------------------------------------------------------------------------------------------------------
`/events/upcoming` | `GET`   | Return all events that are upcoming, separated into a list that the user is hosting or attending and all others
