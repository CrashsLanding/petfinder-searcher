require 'json'
require 'rufus-scheduler'
require 'sinatra'
require 'sequel'
require 'pg'
require_relative 'petfindercreatedatabase.rb'
require_relative 'petfinder_scheduler.rb'

settings = Sinatra::Application.settings

if settings.development?
  require 'dotenv'
  Dotenv.load
end

set :public_folder, Proc.new { File.join(root, "client", "build") }
set :protection, :except => :frame_options

get '/' do
  redirect '/index.html'
end

get '/api/pets/all' do
  headers 'Access-Control-Allow-Origin' => '*'
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
    :shelter => pet[:shelter],
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
  PGconn.connect(:host => uri.hostname,
                 :port => uri.port,
                 :user => uri.user,
                 :password => uri.password,
                 :dbname => uri.path[1..-1])
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
      :shelter => res['sheltername'],
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

scheduler = Rufus::Scheduler.new

scheduler.every '1h' do
  database_url = ENV['DATABASE_URL']
  api_key = ENV['PETFINDER_API_KEY']
  api_secret = ENV['PETFINDER_API_SECRET']
  shelter_ids = ENV['PETFINDER_SHELTER_IDS']

  petfinder_scheduler = PetfinderScheduler.new(database_url, api_key, api_secret, shelter_ids)

  petfinder_scheduler.fill_db()
end
