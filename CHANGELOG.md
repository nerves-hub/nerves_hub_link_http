# Changelog

## v0.8.2

* Enhancements
  * Send fwup version to server when connecting. This is required
    If you are using patchable firmware updates.
* Bug fixes
  * Send entire fwup message back to NervesHubLink.Client

## v0.8.1

* Bug fixes
  * Change X headers to X-NervesHub. This was preventing clients from
    receiving firmware updates since current firmware metadata was not
    being reported.

## v0.8.0

* Enhancements
  * Allow ssl_opts to be overridden

## v0.7.4

Move HTTP functionality from `:nerves_hub` to `:nerves_hub_link_http`
