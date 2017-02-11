require 'pg'
require 'uri'
require 'petfinder'

class PetfinderScheduler
  attr_reader :database_url

  def initialize(database_url, api_key, api_secret, shelter_ids)
    @api_key = api_key
    @api_secret = api_secret
    @shelter_ids = shelter_ids.split(',')
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
      conn.exec_prepared('addPet', [pet.id,
                                    pet.name,
                                    pet.animal,
                                    pet.mix,
                                    pet.age,
                                    pet.shelter_id,
                                    pet.shelter_pet_id,
                                    pet.sex,
                                    pet.size,
                                    pet.description,
                                    pet.last_update,
                                    pet.status])

      pet.options.each do |option|
        option_name = parse_option_name(option)
        conn.exec_prepared('addPetOption', [pet.id, option_name])
      end

      pet.breeds.each do |breed|
        conn.exec_prepared('addPetBreed', [pet.id, breed])
      end

      pic = pet.photos.first
      if pic
        conn.exec_prepared('addPetPhoto', [pet.id, pic.id, 'x', pic.large])
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

  def parse_option_name(option)
    if option == 'hasShots'
      'has shots'
    elsif option == 'noCats'
      'no cats'
    elsif option == 'noDogs'
      'no dogs'
    elsif option == 'specialNeeds'
      'special needs'
    else
      option
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
    puts "Importing pets to the database"
    # Update shelter ids
    @shelter_ids.each { |id| add_shelter(@petfinder.shelter(id))}
    pets = @shelter_ids.flat_map { |id| @petfinder.shelter_pets(id, {count:1000})}
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

      pets.each do |pet|
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
