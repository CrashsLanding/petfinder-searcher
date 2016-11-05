Petfinder Server

### Setup

First, make sure you have your API key and API secret in a file called `.env` in the root of the project.

It should look like:

```
PETFINDER_API_KEY=SomeApiKeyHere
PETFINDER_API_SECRET=SomeApiSecretHere
PETFINDER_SHELTER_IDS=CommaSeperatedListOfIds
```

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
