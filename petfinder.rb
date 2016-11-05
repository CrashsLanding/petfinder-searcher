require 'dotenv'
Dotenv.load

require 'json'
require 'petfinder'
require 'rufus-scheduler'
require 'sinatra'
require 'sequel'

api_key = ENV['PETFINDER_API_KEY']
api_secret = ENV['PETFINDER_API_SECRET']
shelter_ids = ENV['PETFINDER_SHELTER_IDS'].split(',')

petfinder = Petfinder::Client.new(api_key, api_secret)

get '/pets/all' do
  pets = []
  shelter_ids.each do |id|
    pets += petfinder.shelter_pets(id, {count:1000})
  end
  pets_output = pets.map { |pet| {
    :name => pet.name,
    :sex => pet.sex,
    :age => pet.age,
    :size => pet.size,
    :breeds => pet.breeds,
    :pet_type => pet.animal }}
  {:pets => pets_output}.to_json
end

get '/pets/:shelter_id' do
  options = {count:1000}
  pets = petfinder.shelter_pets(params['shelter_id'], options)
  pets_output = pets.map { |pet| {
    :name => pet.name,
    :sex => pet.sex,
    :age => pet.age,
    :size => pet.size,
    :breeds => pet.breeds,
    :pet_type => pet.animal }}
  {:pets => pets_output}.to_json
end


scheduler = Rufus::Scheduler.new

scheduler.every '1h' do
  shelter_ids.each do |id|
    pets = petfinder.shelter_pets(id, {count:1000})
    # store pets
  end
end