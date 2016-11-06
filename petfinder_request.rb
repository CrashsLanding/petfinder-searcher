require 'dotenv'
Dotenv.load

require 'petfinder'

api_key = ENV['PETFINDER_API_KEY']
api_secret = ENV['PETFINDER_API_SECRET']

petfinder = Petfinder::Client.new(api_key, api_secret)

petfinder.shelter_pets("MI988").map { |p| puts p.status}
petfinder.shelter_pets("MI275").map { |p| puts p.status}
