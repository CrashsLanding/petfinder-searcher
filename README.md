Petfinder Server

### Setup

First, make sure you have your API key and API secret in a file called `.env` in the root of the project.

It should look like:

```
PETFINDER_API_KEY=SomeApiKeyHere
PETFINDER_API_SECRET=SomeApiSecretHere
```

We are using Postgres with pg_config, so you need to have that installed, and accessible from the path before going further. Talk to Kevin is this isn't fixed / easier to deal with, and you're still reading it.

We are using Bundler, so before you go any further, make sure bundler is installed with

``` shell
gem install bundler
```

Install all gems with

``` shell
bundle install
```

Run the app with

``` shell
bundle exec rerun ruby petfinder.rb
```
