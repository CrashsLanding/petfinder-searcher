require 'json'
require 'petfinder'
require 'rufus-scheduler'
require 'sinatra'
require 'sequel'
require 'pg'
require_relative 'petfindercreatedatabase.rb'

settings = Sinatra::Application.settings

if settings.development?
  require 'dotenv'
  Dotenv.load
end

set :protection, :except => :frame_options

class PetfinderScheduler
  attr_reader :database_url

  def initialize(database_url)
    @api_key = ENV['PETFINDER_API_KEY']
    @api_secret = ENV['PETFINDER_API_SECRET']
    @shelter_ids = ENV['PETFINDER_SHELTER_IDS'].split(',')
    @database_url = database_url

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

  def add_pet(conn, pet)
    begin
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
      puts id
      add_shelter(@petfinder.shelter(id))

      begin
        conn = get_connection()
        conn.prepare('addPet', "SELECT AddPetStaging($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);")
        conn.prepare('addPetContact', "SELECT AddPetContactStaging($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)")
        conn.prepare('addPetOption', "SELECT AddPetOptionStaging($1, $2);")
        conn.prepare('addPetBreed', "SELECT AddPetBreedStaging($1, $2);")
        conn.prepare('addPetPhoto', "SELECT AddPetPhotoStaging($1, $2, $3, $4);")
        conn.prepare('truncateStaging', "SELECT TruncateStagingTables();")
        conn.prepare('processStaging', "SELECT ProcessStagingTables();")
        conn.exec_prepared('truncateStaging')

        pets = @petfinder.shelter_pets(id, {count:1000})
        pets.each do |pet|
          puts pet.id
          add_pet(conn, pet)
        end
        conn.exec_prepared('processStaging')
      rescue StandardError => e
        puts e
        puts e.backtrace
      ensure
        conn.close unless conn.nil?
      end
    end
  end
end

database_url = ENV['DATABASE_URL']
bypass_db_setup = ENV['PETFINDER_BYPASS_DB_SETUP']
unless bypass_db_setup
  create_db = PetFinderCreateDatabase.new(database_url)
  create_db.create_db
end

scheduler = Rufus::Scheduler.new

scheduler.every '1h' do
  database_url = ENV['DATABASE_URL']
  petfinder_scheduler = PetfinderScheduler.new(database_url)
  petfinder_scheduler.fill_db()
end

unless bypass_db_setup
  scheduler.in '1s' do
    puts 'Starting import'
    database_url = ENV['DATABASE_URL']
    petfinder_scheduler = PetfinderScheduler.new(database_url)
    petfinder_scheduler.fill_db()
    puts 'Import complete'
  end
end

class PetfinderServer < Sinatra::Base
  set :public_folder, Proc.new { File.join(root, "client", "build") }

  get '/' do
    redirect '/index.html'
  end

  get '/api/pets/all' do
    headers 'Access-Control-Allow-Origin' => '*'
    headers 'X-Frame-Options' => ''
    pets = get_all_pets()
    pets_output = pets.map { |key, pet| {
      :id => pet[:id],
      :name => pet[:name],
      :sex => pet[:sex],
      :age => pet[:age],
      :size => pet[:size],
      :breeds => pet[:breeds],
      :colors => pet[:colors],
      :petType => pet[:petType],
      :options => pet[:options],
      :petfinderUrl => pet[:petfinderUrl],
      :photoUrl => pet[:photoUrl]}}
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

  def get_connection
    uri = URI.parse(ENV['DATABASE_URL'])
    PGconn.connect(:host => uri.hostname, :port => uri.port, :user => uri.user, :password => uri.password, :dbname => uri.path[1..-1])
  end

  def get_all_pets()
    conn = get_connection()
    results  = conn.exec(
      "SELECT p.petpk, p.petfinderid, p.name, p.mix, p.description, p.petstatustype, s.sheltername, ag.agetypename, g.genderdisplayname, st.sizetypedisplayname, an.animaltypename, pp.photourl
      FROM Pets p
      INNER JOIN Shelters s
      ON p.shelterpk = s.shelterpk
      INNER JOIN AgeTypes ag
      ON p.agetypepk = ag.agetypepk
      INNER JOIN AnimalTypes an
      ON p.animaltypepk = an.animaltypepk
      INNER JOIN GenderTypes g
      ON p.genderpk = g.genderpk
      INNER JOIN SizeTypes st
      ON p.sizetypepk = st.sizetypepk
      INNER JOIN PetPhotos pp
      ON p.petpk = pp.petpk
      WHERE pp.photosize='x';")
    pets = {}
    results.each do |res|
      pets[res['petpk']] = {
        :petPk => res['petpk'],
        :id => res['petfinderid'],
        :name => res['name'],
        :sex => res['genderdisplayname'],
        :age => res['agetypename'],
        :size => res['sizetypedisplayname'],
        :breeds => [],
        :colors => [],
        :options => [],
        :petType => res['animaltypename'],
        :petfinderUrl => 'https://www.petfinder.com/petdetail/' + res['petfinderid'],
        :photoUrl => res['photourl']}
    end

    results = conn.exec(
      'SELECT petpk, bt.breeddisplayname
        FROM petbreeds pb
        INNER JOIN breedtypes bt
        ON pb.breedtypepk = bt.breedtypepk
        GROUP BY petpk, bt.breeddisplayname;'
      )

    results.each do |res|
      pets[res['petpk']][:breeds].push(res['breeddisplayname'])
    end

    results = conn.exec(
      'SELECT petpk, breedcolor
        FROM petbreeds pb
        INNER JOIN breedtypes bt
        ON pb.breedtypepk = bt.breedtypepk
        GROUP BY petpk, bt.breedcolor;'
      )

    results.each do |res|
      pets[res['petpk']][:colors].push(res['breedcolor'])
    end

    results = conn.exec(
      'SELECT petpk, ot.optiontypename
        FROM petoptions po
        INNER JOIN optiontypes ot
        ON po.optiontypepk = ot.optiontypepk
        GROUP BY petpk, ot.optiontypename;'
      )

    results.each do |res|
      pets[res['petpk']][:options].push(res['optiontypename'])
    end

    return pets
  end

  run!
end

petfinder_server = PetfinderServer.new
