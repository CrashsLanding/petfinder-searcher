Petfinder Searcher

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/CrashsLanding/petfinder-searcher/tree/master)

You have found a sweet stand-alone petfinder search app. All you need to get it up and running is a Heroku account and your petfinder API credentials. It can be run as a standalone application or embedded in your existing website with an iframe.

# React Front-End

### Setup

The code for the client is found in `/client`. The client is a React app that is compiled and served up by the Sinatra back-end. You can adapt the client to your needs and build the client using `npm run build`, then commit the updated assets to git and push away.

```
cd client
npm install
CUSTOMIZE THE CLIENT
npm run build
git add .
git commit -m "made some sweet changes"
git push
```

### Local Development

One can run the React app locally to make it a lot easier to make changes, the code can be reloaded automatically rather than building after every change. cd into the client directory, change the `config.js` file to point at your local Sinatra app (uncomment the line in there pointing to localhost and comment out the relative endpoint) and run the React server with `npm start`, this will launch a server at `http://localhost:3000`. Run the Sinatra app separately using `bundle exec rerun ruby petfinder.rb` from the root of the project.

# Sinatra Back-End

### Setup

First, make sure you have your API key and API secret in a file called `.env` in the root of the project.

It should look like:

```
PETFINDER_API_KEY=SomeApiKeyHere
PETFINDER_API_SECRET=SomeApiSecretHere
PETFINDER_SHELTER_IDS=Comma,Seperated,List,Of,Ids
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

Run the server with

``` shell
bundle exec rerun ruby petfinder.rb
```

Run the client with

``` shell
cd client && npm start
```
