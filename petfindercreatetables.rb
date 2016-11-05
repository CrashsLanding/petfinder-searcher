require 'sequel'
require 'rexml/document'

#Setup DB Connection
DB = Sequel.postgres('petfinder', :user => 'overlord', :password => 'password', :host => 'localhost')


#Creates the tables
DB.run "
DROP TABLE IF EXISTS PetsStaging;
DROP TABLE IF EXISTS PetPhotosStaging;
DROP TABLE IF EXISTS PetContactsStaging;
DROP TABLE IF EXISTS PetBreedsStaging;
DROP TABLE IF EXISTS PetOptionsStaging;

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

CREATE TABLE PetsStaging (
	PetFinderID INT
	,ShelterID varchar(10)
	,ShelterPetID varchar(100)
	,Name varchar(100)
	,AnimalTypeName varchar(10)
	,Mix varchar(3)
	,AgeTypeName varchar(10)
	,Gender char(1)
	,SizeTypeName varchar(2)
	,Description text
	,LastUpdate timestamp
	,PetStatusType char(1)
);

CREATE TABLE PetBreeds (
	PetBreedsPK serial PRIMARY KEY
	,PetPK INT REFERENCES Pets(PetPK)
	,BreedTypePK INT REFERENCES BreedTypes(BreedTypePK)
	,UNIQUE (PetPK,BreedTypePK)
);

CREATE TABLE PetBreedsStaging (
	PetFinderID int
	,BreedName varchar(255)
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

CREATE TABLE PetContactsStaging (
	PetFinderID INT
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

CREATE TABLE PetOptionsStaging (
	PetFinderID int
	,OptionTypeName varchar(50)
);

CREATE TABLE PetPhotos (
	PetPhotoPK serial PRIMARY KEY
	,PetPK INT REFERENCES Pets(PetPK)
	,PhotoID int
	,PhotoSize varchar(3)
	,PhotoURL text
);

CREATE TABLE PetPhotosStaging (
	PetFinderID int
	,PhotoID int
	,PhotoSize varchar(3)
	,PhotoURL text
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


CREATE OR REPLACE FUNCTION AddPet(pPetId int
	,pName varchar(100)
	,pAnimal varchar(50)
	,pmix varchar(3)
	,pAgeTypeName varchar(10)
	,pShelterId varchar(10)
	,pShelterPetId varchar(100)
	,pGender char(1)
	,pSize varchar(2)
	,pDescription text
	,pLastUpdate timestamp
	,pStatus char(1)
	,pPetStatusType char(1)
)
RETURNS void AS $$
BEGIN

END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION AddPetBreed (
	pPetFinderID int
	,pBreedName varchar(255)
)
RETURNS text AS $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM Pets p
		WHERE p.PetFinderID = pPetFinderID
	)
	THEN
		RETURN 'Could not find Pet';
	END IF;

	--This is just in case a new breed gets added that is not in the xsd
	IF NOT EXISTS (
		SELECT 1
		FROM BreedTypes bt
		WHERE bt.BreedName = pBreedName
	)
	THEN
		INSERT INTO BreedTypes (BreedName)
		SELECT pBreedName;
	END IF;

	INSERT INTO PetBreeds(PetPK, BreedTypePK)
	SELECT p.PetPK
		,bt.BreedTypePK
	FROM Pets p
	CROSS JOIN BreedTypes bt
	WHERE p.PetFinderID = pPetFinderID
	AND bt.BreedName = pBreedName;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION AddPetOptions (
	pPetFinderID int
	,pOptionTypeName varchar(50)
)
RETURNS text AS $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM Pets p
		WHERE p.PetFinderID = pPetFinderID
	)
	THEN
		RETURN 'Could not find Pet';
	END IF;

	--This is just in case a new Pet Option gets added that is not in the xsd
	IF NOT EXISTS (
		SELECT 1
		FROM OptionTypes ot
		WHERE ot.OptionTypeName = pOptionTypeName
	)
	THEN
		INSERT INTO OptionTypes (OptionTypeName)
		SELECT pOptionTypeName;
	END IF;

	INSERT INTO PetOptions(PetPK, OptionTypePK)
	SELECT p.PetPK
		,ot.OptionTypePK
	FROM Pets p
	CROSS JOIN OptionTypes ot
	WHERE p.PetFinderID = pPetFinderID
	AND ot.OptionTypeName = pOptionTypeName;
END
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION DeletePet (
	pPetKey int
)
RETURNS void as $$
BEGIN
	IF EXISTS (SELECT 1 FROM Pets p WHERE p.PetPK = pPetKey)
	THEN
		DELETE
		FROM PetBreeds
		WHERE PetPK = pPetKey;

		DELETE
		FROM PetPhotos
		WHERE PetPK = pPetKey;

		DELETE
		FROM PetContacts
		WHERE PetPK = pPetKey;

		DELETE
		FROM PetOptions
		WHERE PetPK = pPetKey;

		DELETE
		FROM Pets
		WHERE PetPK = pPetKey;
	END IF;
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

	DROP TABLE BreedTypesStaging;
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
