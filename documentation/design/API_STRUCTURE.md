# API Structure

## Auth

* Generally requires no session be present
  * `/auth/logout` is the exception (it should reuse some of the code from the `/api` routes)

## API

* Require a valid session cookie to access
  * Might still return auth errors if the user cannot perform the action (admin actions, for example)

## Everything Else

* Use the `ServeDir` -> `ServeFile` of `index.html` -> `500` error workflow
    * Currently, this will cause invalid API requests to respond with HTML. We could make a more-clever `ServeDir` ourselves that correctly differentiates requests with an `application/json` expected response (API traffic) from those expecting frontend resources.
