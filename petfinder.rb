require 'dotenv'
Dotenv.load

require 'json'
require 'petfinder'
require 'rufus-scheduler'
# require 'sinatra'
require 'sequel'
require 'pg'

api_key = ENV['PETFINDER_API_KEY']
api_secret = ENV['PETFINDER_API_SECRET']

petfinder = Petfinder::Client.new(api_key, api_secret)



# get '/pets' do
#   pets = petfinder.find_pets('cat', '49505')
#   names = pets.map { |pet| pet.name }
#   {:names => names}.to_json
# end

# get '/pets/:shelter_id' do
#   options = {count:1000}
#   pets = petfinder.shelter_pets(params['shelter_id'], options)
#   names = pets.map { |pet| pet.names}
#   {:name => names}.to_json
# end

def init_shelter_ids
  ENV['PETFINDER_SHELTER_IDS'].split(',')
end

def get_connection
  PGconn.connect(:host => 'localhost', :user => 'overlord', :password => 'password', :dbname => 'petfinder', :port => 5432)
end

def add_shelter(shelter)
  conn = get_connection
  conn.prepare('addShelter', "SELECT AddShelter($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13);")
  conn.exec_prepared('addShelter', [shelter.id, shelter.name, shelter.address1, shelter.address2, shelter.city, shelter.state, shelter.zip, shelter.country, shelter.latitude, shelter.longitude, shelter.phone, shelter.fax, shelter.email])
rescue StandardError => e
  puts e
  puts e.backtrace
end

def add_pet(pet)
  conn = get_connection
  #conn = Sequel.postgres('petfinder', :user => 'overlord', :password => 'password', :host => 'localhost')
  conn.prepare('addPet', "SELECT AddPet($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);")
  results = conn.exec_prepared('addPet', [pet.id, pet.name, pet.animal, pet.mix, pet.age, pet.shelter_id, pet.shelter_pet_id, pet.sex, pet.size, pet.description, pet.last_update, pet.status])


  #pet.breeds
  #pet.options
  #pet.contact
  #pet.pictures
  #
rescue StandardError => e
  puts e
  puts e.backtrace
end

shelter_ids = init_shelter_ids()

scheduler = Rufus::Scheduler.new

# scheduler.every '1h' do
  shelter_ids.each do |id|
    add_shelter(petfinder.shelter(id))

    pets = petfinder.shelter_pets(id, {count:5})
    add_pet(pets.first)
    # pets.each do |pet|
    #   add_pet(pet)
    # end
    # store pets
  end
# end