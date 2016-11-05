require 'dotenv'
Dotenv.load

require 'json'
require 'petfinder'
require 'rufus-scheduler'
require 'sinatra'
require 'sequel'

api_key = ENV['PETFINDER_API_KEY']
api_secret = ENV['PETFINDER_API_SECRET']

petfinder = Petfinder::Client.new(api_key, api_secret)



get '/pets' do
  pets = petfinder.find_pets('cat', '49505')
  names = pets.map { |pet| pet.name }
  {:names => names}.to_json
end

get '/pets/:shelter_id' do
  options = {count:1000}
  pets = petfinder.shelter_pets(params['shelter_id'], options)
  names = pets.map { |pet| pet.names}
  {:name => names}.to_json
end

def init_shelter_ids
  ENV['PETFINDER_SHELTER_IDS'].split(',')
end
shelter_ids = init_shelter_ids()

scheduler = Rufus::Scheduler.new

scheduler.every '1h' do
  shelter_ids.each do |id|
    pets = petfinder.shelter_pets(id, {count:1000})
    # store pets
  end
end