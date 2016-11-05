require 'petfinder'

api_key = ''
api_secret = ''

petfinder = Petfinder::Client.new(api_key, api_secret)
shelter = petfinder.shelter('MI988')
puts shelter.name
pets = petfinder.find_pets('cat', '49505')
pets.each do |pet|
  puts pet.id
end
