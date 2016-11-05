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

DROP FUNCTION IF EXISTS AddPetStaging(
	pPetId int
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
);

DROP FUNCTION IF EXISTS AddPetOptionStaging(int, varchar);
DROP FUNCTION IF EXISTS AddPetBreedStaging(int, varchar);
DROP FUNCTION IF EXISTS AddPetPhotoStaging(int, int, varchar, text);
DROP FUNCTION IF EXISTS AddPetContactStaging(pPetFinderID INT
	,pContactName varchar(255)
	,pAddress1 varchar(1000)
	,pAddress2 varchar(1000)
	,pCity varchar(100)
	,pState char(2)
	,pZip char(5)
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


CREATE OR REPLACE FUNCTION AddPetStaging(
   pPetId int
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
)
RETURNS void AS $$
BEGIN
	INSERT INTO PetsStaging(PetFinderId, ShelterId, ShelterPetID, Name, AnimalTypeName, Mix, AgeTypeName, Gender, SizeTypeName, Description, LastUpdate, PetStatusType)
		VALUES(pPetId, pShelterId, pShelterPetId, pName, pAnimal, pMix, pAgeTypeName, pGender, pSize, pDescription, pLastUpdate, pStatus);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION AddPetContactStaging(
	pPetFinderID INT
	,pContactName varchar(255)
	,pAddress1 varchar(1000)
	,pAddress2 varchar(1000)
	,pCity varchar(100)
	,pState char(2)
	,pZip char(5)
	,pPhone varchar(20)
	,pFax varchar(20)
	,pEmail varchar(254)
)
RETURNS void AS $$
BEGIN
	INSERT INTO PetContactsStaging(PetFinderID, ContactName, Address1, Address2, City, State, Zip, Phone, Fax, Email)
		VALUES(pPetFinderID, pContactName, pAddress1, pAddress2, pCity, pState, pZip, pPhone, pFax, pEmail);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION AddPetOptionStaging(
	pPetFinderID INT
	,pOptionTypeName VARCHAR(50)
)
RETURNS void AS $$
BEGIN
	INSERT INTO petoptionsstaging(PetFinderID, optiontypename)
		VALUES(pPetFinderID, pOptionTypeName);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION AddPetBreedStaging(
	pPetFinderID INT
	,pPetBreedName VARCHAR(255)
)
RETURNS void AS $$
BEGIN
	INSERT INTO PetBreedsStaging(PetFinderID, BreedName)
		VALUES(pPetFinderID, pPetBreedName);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION AddPetPhotoStaging(
	pPetFinderID INT
	,pPhotoId INT
	,pSize VARCHAR(3)
	,pUrl TEXT
)
RETURNS void AS $$
BEGIN
	INSERT INTO petPhotosStaging(PetFinderID, photoid, photosize, photourl)
		VALUES(pPetFinderID, pPhotoId, pSize, pUrl);
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

CREATE OR REPLACE FUNCTION ProcessStaging()
RETURNS text as $$
BEGIN
	CREATE TEMPORARY TABLE PetsToDelete(
		PetPK int
	);
	--Pets Logic
	--Start delete pets
	INSERT INTO PetsToDelete (PetPK)
	SELECT p.PetPK
	FROM Pets p
	WHERE NOT EXISTS (
	 SELECT 1
	 FROM PetsStaging ps
	 WHERE ps.PetFinderID = p.PetFinderID
	);

	DELETE
	FROM PetBreeds
	WHERE PetPK IN (
		SELECT PetPK
		FROM PetsToDelete
	);

	DELETE
	FROM PetPhotos
	WHERE PetPK IN (
		SELECT PetPK
		FROM PetsToDelete
	);

	DELETE
	FROM PetContacts
	WHERE PetPK IN (
		SELECT PetPK
		FROM PetsToDelete
	);

	DELETE
	FROM PetOptions
	WHERE PetPK IN (
		SELECT PetPK
		FROM PetsToDelete
	);

	DELETE
	FROM Pets
	WHERE PetPK IN (
		SELECT PetPK
		FROM PetsToDelete
	);
	--End Delete Pets

	--Update Pets
	UPDATE Pets
	SET ShelterPK = ps2.ShelterPK
		,ShelterPetID = ps2.ShelterPetID
		,Name = ps2.Name
		,AnimalTypePK = ps2.AnimalTypePK
		,Gender = ps2.Gender
		,SizeTypePK = ps2.SizeTypePK
		,Description = ps2.Description
		,LastUpdate = ps2.LastUpdate
		,PetStatusType = ps2.PetStatusType
		,AgeTypePK = ps2.AgeTypePK
	FROM Pets p
	JOIN (
		SELECT ps.PetFinderID
			,s.ShelterPK
			,ps.ShelterPetID
			,ps.Name
			,ant.AnimalTypePK
			,ps.Gender
			,st.SizeTypePK
			,ps.Description
			,ps.LastUpdate
			,ps.PetStatusType
			,agt.AgeTypePK
		FROM PetsStaging ps
		JOIN Shelters s ON ps.ShelterID = s.ShelterID
		JOIN AnimalTypes ant ON ant.AnimalTypeName = ps.AnimalTypeName
		JOIN SizeTypes st ON st.SizeTypeName = ps.SizeTypeName
		JOIN AgeTypes agt ON agt.AgeTypeName = ps.AgeTypeName
	) ps2 ON ps2.PetFinderID = p.PetFinderID;

	--Insert Pets
	INSERT INTO Pets (
		PetFinderID
		,ShelterPK
		,ShelterPetID
		,Name
		,AnimalTypePK
		,Gender
		,SizeTypePK
		,Description
		,LastUpdate
		,PetStatusType
		,AgeTypePK
	)
	SELECT ps.PetFinderID
		,s.ShelterPK
		,ps.ShelterPetID
		,ps.Name
		,ant.AnimalTypePK
		,ps.Gender
		,st.SizeTypePK
		,ps.Description
		,ps.LastUpdate
		,ps.PetStatusType
		,agt.AgeTypePK
	FROM PetsStaging ps
	JOIN Shelters s ON ps.ShelterID = s.ShelterID
	JOIN AnimalTypes ant ON ant.AnimalTypeName = ps.AnimalTypeName
	JOIN SizeTypes st ON st.SizeTypeName = ps.SizeTypeName
	JOIN AgeTypes agt ON agt.AgeTypeName = ps.AgeTypeName
	WHERE NOT EXISTS (
		SELECT 1
		FROM Pets p
		WHERE ps.PetFinderID = p.PetFinderID
		);
	--End Pets

	DELETE FROM PetBreeds pb
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetBreedsStaging pbs
		JOIN BreedTypes bt ON pbs.BreedName = bt.BreedName
		JOIN Pets p ON p.PetFinderID = pbs.PetFinderID
		WHERE bt.BreedTypePK = pb.BreedTypePK
		AND p.PetKey = pb.PetKey
	);

	INSERT INTO PetBreeds (PetPK, BreedTypePK)
	SELECT p.PetPK
		,bt.BreedTypePK
	FROM PetBreedsStaging pbs
	JOIN BreedTypes bt ON pbs.BreedName = bt.BreedName
	JOIN Pets p ON p.PetFinderID = pbs.PetFinderID
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetBreeds pb
		WHERE bt.BreedTypePK = pb.BreedTypePK
		AND p.PetKey = pb.PetKey
	);

	UPDATE PetContacts
	SET ContactName = pcs.ContactName
		,Address1 = pcs.Address1
		,Address2 = pcs.Address2
		,City = pcs.City
		,State = pcs.State
		,Zip = pcs.Zip
		,Phone = pcs.Phone
		,Fax = pcs.Fax
		,Email = pcs.Email
	FROM PetContacts pc
	JOIN Pets p ON p.PetKey = pc.PetKey
	JOIN PetContactsStaging pcs ON pcs.PetFinderID = p.PetFinderID
	;

	INSERT INTO PetContacts (
		PetPK
		,ContactName
		,Address1
		,Address2
		,City
		,State
		,Zip
		,Phone
		,Fax
		,Email
	)
	SELECT p.PetPK
		,pcs.ContactName
		,pcs.Address1
		,pcs.Address2
		,pcs.City
		,pcs.State
		,pcs.Zip
		,pcs.Phone
		,pcs.Fax
		,pcs.Email
	FROM Pets p
	JOIN PetContactsStaging pcs ON pcs.PetFinderID = p.PetFinderID
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetContacts pc
		WHERE pc.PetFinderID = p.PetFinderID
	);

	DELETE FROM PetOptions po
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetOptionsStaging pos
		JOIN OptionTypes ot ON pos.OptionTypeName = ot.OptionTypeName
		JOIN Pets p ON p.PetFinderID = pos.PetFinderID
		WHERE ot.OptionTypePK = po.OptionTypePK
		AND p.PetKey = po.PetKey
	);

	INSERT INTO PetOptions (PetPK, OptionTypePK)
	SELECT p.PetPK
		,ot.OptionTypePK
	FROM PetOptionsStaging pbs
	JOIN OptionTypes ot ON pbs.BreedName = bt.BreedName
	JOIN Pets p ON p.PetFinderID = pbs.PetFinderID
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetOptions pb
		WHERE ot.OptionTypePK = po.OptionTypePK
		AND p.PetKey = po.PetKey
	);

	DELETE FROM PetPhotos pp
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetPhotosStaging pps
		JOIN Pets p On p.PetFinderID = pps.PetFinderID
		WHERE p.PetPK = pp.PetPK
		AND pps.PhotoID = pp.PhotoID
		AND pps.PhotoSize = pp.PhotoSize
		AND pps.PhotoURL = pp.PhotoURL
	);

	INSERT INTO PetPhotos (
		PetPK
		,PhotoID
		,PhotoSize
		,PhotoURL
	)
	SELECT p.PetPK
		,pps.PhotoID
		,pps.PhotoSize
		,pps.PhotoURL
	FROM PetPhotosStaging pps
	JOIN Pets p On p.PetFinderID = pps.PetFinderID
	WHERE NOT EXISTS (
		SELECT 1
		FROM PetPhotos pp
		WHERE p.PetPK = pp.PetPK
		AND pps.PhotoID = pp.PhotoID
		AND pps.PhotoSize = pp.PhotoSize
		AND pps.PhotoURL = pp.PhotoURL
	);

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
