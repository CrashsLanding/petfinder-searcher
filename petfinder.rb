require 'dotenv'
Dotenv.load

require 'json'
require 'petfinder'
require 'rufus-scheduler'
# require 'sinatra'
require 'sequel'

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

def add_shelter(shelter)
  conn = Sequel.postgres('petfinder', :user => 'overlord', :password => 'password', :host => 'localhost')
  conn.run("SELECT AddShelter('#{shelter.id}',
              '#{shelter.name.gsub('\'','\'\'')}',
              '#{shelter.address1.gsub('\'','\'\'')}',
              '#{shelter.address2.gsub('\'','\'\'')}',
              '#{shelter.city.gsub('\'','\'\'')}',
              '#{shelter.state}',
              '#{shelter.zip}',
              '#{shelter.country.gsub('\'','\'\'')}',
              #{shelter.latitude},
              #{shelter.longitude},
              '#{shelter.phone}',
              '#{shelter.fax}',
              '#{shelter.email}');")
rescue StandardError => e
  puts e
end

def add_pet(pet)
  conn = Sequel.postgres('petfinder', :user => 'overlord', :password => 'password', :host => 'localhost')
  conn.run("SELECT AddPet(
              #{pet.id}
              ,'#{pet.name}'
              ,'#{pet.animal}'
              ,'#{pet.mix}'
              ,'#{pet.age}'
              ,'#{pet.shelter_id}'
              ,'#{pet.shelter_pet_id}'
              ,'#{pet.sex}'
              ,'#{pet.size}'
              ,'#{pet.description.gsub('\'', '\'\'')}'
              ,'#{pet.last_update}'
              ,'#{pet.status}'
    );")

  #pet.breeds
  #pet.options
rescue StandardError => e
  puts e
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