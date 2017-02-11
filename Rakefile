require_relative 'petfinder_scheduler'
require_relative 'petfindercreatedatabase'
require 'dotenv/tasks'

namespace :db do
  desc 'Reprovision the database'
  task create: :dotenv do
    database_url = ENV['DATABASE_URL']

    PetFinderCreateDatabase.new(database_url).create_db
  end

  task import: :dotenv do
    database_url = ENV['DATABASE_URL']
    api_key = ENV['PETFINDER_API_KEY']
    api_secret = ENV['PETFINDER_API_SECRET']
    shelter_ids = ENV['PETFINDER_SHELTER_IDS']

    PetfinderScheduler.new(database_url, api_key, api_secret, shelter_ids).fill_db()
  end

  task update: :dotenv do
    database_url = ENV['DATABASE_URL']
    api_key = ENV['PETFINDER_API_KEY']
    api_secret = ENV['PETFINDER_API_SECRET']
    shelter_ids = ENV['PETFINDER_SHELTER_IDS']

    db_exists = PetFinderCreateDatabase.new(database_url).db_exists?
    PetFinderCreateDatabase.new(database_url).create_db unless db_exists

    PetfinderScheduler.new(database_url, api_key, api_secret, shelter_ids).fill_db()
  end
end

namespace :run do
  task :server do
    sh 'bundle exec rerun ruby petfinder.rb'
  end

  task :client do
    client_path = File.join(File.dirname(__FILE__), '/client')
    sh "cd #{client_path} && npm start"
  end

  task :build do
    client_path = File.join(File.dirname(__FILE__), '/client')
    sh "cd #{client_path} && npm build"
  end
end
