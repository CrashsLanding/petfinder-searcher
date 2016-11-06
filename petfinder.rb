require 'json'
require 'petfinder'
require 'rufus-scheduler'
require 'sinatra'
require 'sequel'

settings = Sinatra::Application.settings

if settings.development?
  require 'dotenv'
  Dotenv.load
end

set :protection, :except => :frame_options

set :public_folder, Proc.new { File.join(root, "client", "build") }

api_key = ENV['PETFINDER_API_KEY']
api_secret = ENV['PETFINDER_API_SECRET']
shelter_ids = ENV['PETFINDER_SHELTER_IDS'].split(',')

petfinder = Petfinder::Client.new(api_key, api_secret)

get '/' do
  redirect '/index.html'
end

get '/api/pets/all' do
  pets = []
  shelter_ids.each do |id|
    pets += petfinder.shelter_pets(id, {count:1000})
  end
  pets_output = pets.map { |pet| {
    :id => pet.id,
    :name => pet.name,
    :sex => pet.sex,
    :age => pet.age,
    :size => pet.size,
    :breeds => pet.breeds,
    :petType => pet.animal,
    :petfinderUrl => 'https://www.petfinder.com/petdetail/' + pet.id,
    :options => [],
    :photoUrl => 'https://www.wired.com/wp-content/uploads/2015/09/google-logo.jpg'}}
    pets_output[0]['options'] = ['no-claws', 'fiv+']
    pets_output[1]['options'] = ['no-claws']
    pets_output[2]['options'] = ['fiv+']
  {:pets => pets_output}.to_json
end

get '/api/pets/:shelter_id' do
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
