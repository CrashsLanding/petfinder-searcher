require 'sequel'
require 'rexml/document'

#DB = Sequel.connect('postgres://nate:test@localhost/petfinder')
DB = Sequel.postgres('petfinder', :user => 'nate', :password => 'test', :host => 'localhost')
#puts DB
DB.run "
DROP TABLE petFinderRecords;
DROP TABLE PetFinderShelters;
DROP TABLE AnimalTypes;



CREATE TABLE PetFinderShelters (
	ShelterPK SERIAL PRIMARY KEY
	,ShelterID varchar(10)
);

CREATE TABLE AnimalTypes (
	AnimalTypeID SERIAL PRIMARY KEY
	,AnimalTypeName varchar(50)
);


CREATE TABLE petFinderRecords (
	PetFinderPK SERIAL PRIMARY KEY
	,petFinderid int UNIQUE
	,ShelterPK INT REFERENCES PetFinderShelters(ShelterPK)
	,shelterPetID varchar(100)
	,Name varchar(100)
);










"

doc = REXML::Document.new(File.new('petfinder.xsd'))
#puts doc

AnimalTypes = DB[:animaltypes]

REXML::XPath.each(doc, '//xs:simpleType[@name="animalType"]//xs:enumeration/@value') do |e|
  AnimalTypes.insert(:animaltypename => e.value)
end
