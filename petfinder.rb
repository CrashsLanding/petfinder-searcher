require 'dotenv'
Dotenv.load

require 'petfinder'
require 'sinatra'
require 'json'
require 'sequel'

api_key = ENV['PETFINDER_API_KEY']
api_secret = ENV['PETFINDER_API_SECRET']

petfinder = Petfinder::Client.new(api_key, api_secret)



get '/pets' do
  pets = petfinder.find_pets('cat', '49505')
  names = pets.map { |pet| pet.name }
  {:names => names}.to_json
end
