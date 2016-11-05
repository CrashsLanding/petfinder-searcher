require 'sequel'
require 'rexml/document'

#Setup DB Connection
DB = Sequel.postgres('petfinder', :user => 'overlord', :password => 'password', :host => 'localhost')


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

DROP FUNCTION IF EXISTS AddShelter(pShelterID varchar(10)
	,pShelterName varchar(255)
	,pAddress1 varchar(1000)
	,pAddress2 varchar(1000)
	,pCity varchar(100)
	,pState char(2)
	,pZip char(5)
	,pCountry varchar(100)
	,pLatitude decimal
	,pLongitude decimal
	,pPhone varchar(20)
	,pFax varchar(20)
	,pEmail varchar(254));

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
	,PetFinderID int UNIQUE NOT NULL
	,ShelterPK INT REFERENCES Shelters(ShelterPK)
	,ShelterPetID varchar(100)
	,Name varchar(100)
	,AnimalTypePK INT REFERENCES AnimalTypes(AnimalTypePK)
	,mix varchar(3)
	,AgeTypePK INT REFERENCES AgeTypes(AgeTypepk)
	,Gender char(1) NOT NULL
	,SizeTypePK INT REFERENCES SizeTypes(SizeTypePK)
	,Description text
	,LastUpdate timestamp
	,PetStatusType char(1) NOT NULL
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
	,Zip char(5) --Change to 5+4 format if necessary
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

CREATE OR REPLACE FUNCTION AddShelter(
  pShelterID varchar(10)
	,pShelterName varchar(255)
	,pAddress1 varchar(1000)
	,pAddress2 varchar(1000)
	,pCity varchar(100)
	,pState char(2)
	,pZip char(5)
	,pCountry varchar(100)
	,pLatitude decimal
	,pLongitude decimal
	,pPhone varchar(20)
	,pFax varchar(20)
	,pEmail varchar(254))
RETURNS void AS $$
BEGIN
	UPDATE Shelters SET ShelterName = pShelterName, address1 = pAddress1, address2 = pAddress2,
											City = pCity, State = pState, Zip = pZip, Country = pCountry,
											latitude = pLatitude, Longitude = pLongitude, Phone = pPhone, Fax = pFax,
											Email = pEmail
	WHERE shelterID = pShelterID;
	INSERT INTO Shelters(shelterId, sheltername, address1, address2, city, state, zip, country, latitude, longitude, phone, fax, email)
		SELECT pShelterID, pShelterName, pAddress1, pAddress2, pCity, pState, pZip, pCountry, pLatitude, pLongitude, pPhone, pFax, pEmail WHERE NOT EXISTS(SELECT 1 FROM Shelters WHERE ShelterID = pShelterID);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION AddPet(pPetFinderID int
	,pShelterID varchar(10)
	,pShelterPetID varchar(100)
	,pName varchar(100)
	,pmix varchar(3)
	,pGender char(1)
	,pDescription text
	,pPetStatusType char(1)
)
RETURNS void AS $$
BEGIN
	
END
$$ LANGUAGE plpgsql;
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
