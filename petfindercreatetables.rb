require 'sequel'
require 'rexml/document'

#Setup DB Connection
DB = Sequel.postgres('petfinder', :user => 'nate', :password => 'test', :host => 'localhost')


#Creates the tables
DB.run "
DROP TABLE IF EXISTS PetPhotos;
DROP TABLE IF EXISTS PetOptions;
DROP TABLE IF EXISTS PetContacts;
DROP TABLE IF EXISTS PetBreeds;
DROP TABLE IF EXISTS Pets;

DROP TABLE IF EXISTS Shelters;

DROP TABLE IF EXISTS SizeTypes;
DROP TABLE IF EXISTS OptionTypes;
DROP TABLE IF EXISTS BreedTypesStaging;
DROP TABLE IF EXISTS BreedTypes;
DROP TABLE IF EXISTS AnimalTypes;
DROP TABLE IF EXISTS AgeTypes;

CREATE TABLE AgeTypes(
	AgeTypePK serial PRIMARY KEY
	,AgeTypeName varchar(10) UNIQUE NOT NULL
);

CREATE TABLE AnimalTypes (
	AnimalTypePK SERIAL PRIMARY KEY
	,AnimalTypeName varchar(50) UNIQUE NOT NULL
);

CREATE TABLE BreedTypes (
	BreedTypePK SERIAL PRIMARY KEY
	,BreedName varchar(255) UNIQUE NOT NULL
);

CREATE TABLE BreedTypesStaging (
	BreedName varchar(255) NOT NULL
);

CREATE TABLE OptionTypes (
	OptionTypePK SERIAL PRIMARY KEY
	, OptionTypeName varchar(50) UNIQUE NOT NULL
);

CREATE TABLE SizeTypes (
	SizeTypePK SERIAL Primary Key
	,SizeTypeName varchar(2) UNIQUE NOT NULL
);

CREATE TABLE Shelters (
	ShelterPK SERIAL PRIMARY KEY
	,ShelterID varchar(10) UNIQUE NOT NULL
	,ShelterName varchar(255)
	,Address1 varchar(1000)
	,Address2 varchar(1000)
	,City varchar(100)
	,State char(2)
	,Zip char(5) --Change to 5+4 format if nessisarry
	,Country varchar(100)
	,Latitude decimal
	,Longitude decimal
	,Phone varchar(20) --not sure of the format so giving it extra space
	,Fax varchar(20)
	,Email varchar(254)
);

CREATE TABLE Pets (
	PetPK SERIAL PRIMARY KEY
	,PetFinderID int UNIQUE
	,ShelterPK INT REFERENCES Shelters(ShelterPK)
	,ShelterPetID varchar(100)
	,Name varchar(100)
	,AnimalTypePK INT REFERENCES AnimalTypes(AnimalTypePK)
	,Gender char(1) NOT NULL
	,SizeTypePK INT REFERENCES SizeTypes(SizeTypePK)
	,Description varchar(2000)
	,LastUpdate timestamp
	,PetStatusType char(1) NOT NULL
	,AgeTypePK INT REFERENCES AgeTypes(AgeTypepk)
);

CREATE TABLE PetBreeds (
	PetBreedsPK serial PRIMARY KEY
	,PetPK INT REFERENCES Pets(PetPK)
	,BreedTypePK INT REFERENCES BreedTypes(BreedTypePK)
	,UNIQUE (PetPK,BreedTypePK)
);

CREATE TABLE PetContacts (
	PetContactPK SERIAL PRIMARY KEY
	,PetPK INT REFERENCES Pets(PetPK) UNIQUE --Right now I think this is a vertical partition. Will need to review data to be sure
	,ContactName varchar(255)
	,Address1 varchar(1000)
	,Address2 varchar(1000)
	,City varchar(100)
	,State char(2)
	,Zip char(5) --Change to 5+4 format if nessisarry
	,Phone varchar(20) --not sure of the format so giving it extra space
	,Fax varchar(20)
	,Email varchar(254)
);

CREATE TABLE PetOptions (
	PetOptionPK SERIAL PRIMARY KEY
	,PetPK INT REFERENCES Pets(PetPK)
	,OptionTypePK INT REFERENCES OptionTypes(OptionTypePK)
);

CREATE TABLE PetPhotos (
	PetPhotoPK serial PRIMARY KEY
	,PetPK INT REFERENCES Pets(PetPK)
	,PhotoID int
	,PhotoSize varchar(3)
	,PhotoLocation varchar(1000)
);
"


# Populates all of the tables using the xsd
doc = REXML::Document.new(File.new('petfinder.xsd'))


AnimalTypes = DB[:animaltypes]

REXML::XPath.each(doc, '//xs:simpleType[@name="animalType"]//xs:enumeration/@value') do |e|
  AnimalTypes.insert(:animaltypename => e.value)
end

petoptiontypes = DB[:optiontypes]

REXML::XPath.each(doc, '//xs:simpleType[@name="petOptionType"]//xs:enumeration/@value') do |f|
  petoptiontypes.insert(:optiontypename => f.value)
	# puts f.value
end

breedtypesstaging = DB[:breedtypesstaging]

REXML::XPath.each(doc, '//xs:simpleType[@name="petfinderBreedType"]//xs:enumeration/@value') do |f|
  breedtypesstaging.insert(:breedname => f.value)
	# puts f.value
end

DB.run "
	INSERT INTO BreedTypes (
		BreedName
	)
	SELECT BreedName
	FROM BreedTypesStaging
	GROUP BY BreedName;
"

AgeTypes = DB[:agetypes]

REXML::XPath.each(doc, '//xs:simpleType[@name="petAgeType"]//xs:enumeration/@value') do |f|
  AgeTypes.insert(:agetypename => f.value)
	# puts f.value
end

SizeTypes = DB[:sizetypes]

REXML::XPath.each(doc, '//xs:simpleType[@name="petSizeType"]//xs:enumeration/@value') do |f|
  SizeTypes.insert(:sizetypename => f.value)
	# puts f.value
end

#puts doc
