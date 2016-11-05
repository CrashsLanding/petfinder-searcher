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
  conn.prepare('addPet', "SELECT AddPetStaging($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);")
  conn.prepare('addPetContact', "SELECT AddPetContactStaging($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)")
  conn.prepare('addPetOption', "SELECT AddPetOptionStaging($1, $2);")
  conn.prepare('addPetBreed', "SELECT AddPetBreedStaging($1, $2);")
  conn.prepare('addPetPhoto', "SELECT AddPetPhotoStaging($1, $2, $3, $4);")

  results = conn.exec_prepared('addPet', [pet.id, pet.name, pet.animal, pet.mix, pet.age, pet.shelter_id, pet.shelter_pet_id, pet.sex, pet.size, pet.description, pet.last_update, pet.status])
  #puts results

  contact = parse_contact_info(pet.contact)
  if contact.empty?
    puts 'Error processing contacts.'
    return
  end
  results = conn.exec_prepared('addPetContact', [pet.id, contact['name'], contact['address1'], contact['address2'], contact['city'], contact['state'], contact['zip'], contact['phone'], contact['fax'], contact['email']])

  pet.options.each do |option|
    conn.exec_prepared('addPetOption', [pet.id, option])
  end

  pet.breeds.each do |breed|
    conn.exec_prepared('addPetBreed', [pet.id, breed])
  end

  pet.photos.each do |pic|
    conn.exec_prepared('addPetPhoto', [pet.id, pic.id, 'x', pic.large])
    conn.exec_prepared('addPetPhoto', [pet.id, pic.id, 'pn', pic.medium])
    conn.exec_prepared('addPetPhoto', [pet.id, pic.id, 'fpm', pic.small])
    conn.exec_prepared('addPetPhoto', [pet.id, pic.id, 'pnt', pic.thumbnail])
    conn.exec_prepared('addPetPhoto', [pet.id, pic.id, 't', pic.tiny])
  end
rescue StandardError => e
  puts e
  puts e.backtrace
end

def parse_contact_info(contact)
  info = {}
  lines = contact.split("\n").map{ |line| line.strip }
  info['name'] = lines[0]
  info['address1'] = lines[1]
  info['address2'] = lines[2]
  info['city'] = lines[3]
  info['state'] = lines[4]
  info['zip'] = lines[5]
  info['phone'] = lines[6]
  info['fax'] = lines[7]
  info['email'] = lines[8]

  info
rescue StandardError => e
  puts e
  puts e.backtrace
  {}
end

shelter_ids = init_shelter_ids()

scheduler = Rufus::Scheduler.new

# scheduler.every '1h' do
  shelter_ids.each do |id|
    add_shelter(petfinder.shelter(id))

    pets = petfinder.shelter_pets(id, {count: 5})
    add_pet(pets.first)
    # pets.each do |pet|
    #   add_pet(pet)
    # end
    # store pets
  end
# end