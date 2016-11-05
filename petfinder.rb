require 'json'
require 'petfinder'
require 'rufus-scheduler'
require 'sinatra'
require 'sinatra/cross_origin'
require 'sequel'
require 'pg'

settings = Sinatra::Application.settings

if settings.development?
  require 'dotenv'
  Dotenv.load
end

configure do
  enable :cross_origin
end

class PetfinderServer < Sinatra::Base

  get '/pets/all' do
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
      :photoUrl => 'https://www.wired.com/wp-content/uploads/2015/09/google-logo.jpg'}}
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

  def get_connection
    uri = URI.parse(ENV['DATABASE_URL'])
    PGconn.connect(:host => uri.hostname, :port => uri.port, :user => uri.user, :password => uri.password, :dbname => uri.path[1..-1])
  end

  def get_all_pets()
    conn = get_connection()
    

  end
end

class PetfinderScheduler

  def initialize()
    @api_key = ENV['PETFINDER_API_KEY']
    @api_secret = ENV['PETFINDER_API_SECRET']
    @shelter_ids = ENV['PETFINDER_SHELTER_IDS'].split(',')
    @database_url = ENV['DATABASE_URL']

    @petfinder = Petfinder::Client.new(@api_key, @api_secret)
  end

  def get_connection
    uri = URI.parse(@database_url)
    PGconn.connect(:host => uri.hostname, :port => uri.port, :user => uri.user, :password => uri.password, :dbname => uri.path[1..-1])
  end

  def add_shelter(shelter)
    conn = nil
    begin
      conn = get_connection
      conn.prepare('addShelter', "SELECT AddShelter($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13);")
      conn.exec_prepared('addShelter', [shelter.id, shelter.name, shelter.address1, shelter.address2, shelter.city, shelter.state, shelter.zip, shelter.country, shelter.latitude, shelter.longitude, shelter.phone, shelter.fax, shelter.email])
    rescue StandardError => e
      puts e
      puts e.backtrace
    ensure
      conn.close unless conn.nil?
    end
  end

  def add_pet(pet)
    conn = nil
    begin
      conn = get_connection
      conn.prepare('addPet', "SELECT AddPetStaging($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);")
      conn.prepare('addPetContact', "SELECT AddPetContactStaging($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)")
      conn.prepare('addPetOption', "SELECT AddPetOptionStaging($1, $2);")
      conn.prepare('addPetBreed', "SELECT AddPetBreedStaging($1, $2);")
      conn.prepare('addPetPhoto', "SELECT AddPetPhotoStaging($1, $2, $3, $4);")
      conn.prepare('truncateStaging', "SELECT TruncateStagingTables();")

      conn.exec_prepared('truncateStaging')
      conn.exec_prepared('addPet', [pet.id, pet.name, pet.animal, pet.mix, pet.age, pet.shelter_id, pet.shelter_pet_id, pet.sex, pet.size, pet.description, pet.last_update, pet.status])

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

      contact = parse_contact_info(pet.contact)
      if contact.empty?
        puts 'Error processing contacts.'
        return
      end
      conn.exec_prepared('addPetContact', [pet.id, contact['name'], contact['address1'], contact['address2'], contact['city'], contact['state'], contact['zip'], contact['phone'], contact['fax'], contact['email']])
    rescue StandardError => e
      puts e
      puts e.backtrace
    ensure
      conn.close unless conn.nil?
    end
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

  def fill_db()
    @shelter_ids.each do |id|
      add_shelter(@petfinder.shelter(id))

      pets = @petfinder.shelter_pets(id, {count: 1000})
      add_pet(pets.first)
      pets.each do |pet|
        add_pet(pet)
      end
      store pets
    end
  end
end

patfinder_server = PetfinderServer.new
scheduler = Rufus::Scheduler.new

scheduler.every '1h' do
  petfinder_scheduler = PetfinderScheduler.new
  petfinder_scheduler.fill_db()
end

scheduler.in '10s' do
  petfinder_scheduler = PetfinderScheduler.new
  petfinder_scheduler.fill_db()
end