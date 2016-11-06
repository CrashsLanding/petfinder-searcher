require 'sequel'
require 'rexml/document'
require 'uri'

class PetFinderCreateDatabase

	def initialize(database_url)
		@database_url = database_url
	end

	def db_exists?
		uri = URI.parse(@database_url)
		database_name = uri.path[1..-1]
		conn = Sequel.postgres(database_name,
		                       :user => uri.user,
		                       :password => uri.password,
		                       :host => uri.hostname,
		                       :port => uri.port)
		conn.table_exists?(:pets)
	end

	def create_db
		#Setup DB Connection
		uri = URI.parse(@database_url)
		database_name = uri.path[1..-1]
		conn = Sequel.postgres(database_name, :user => uri.user, :password => uri.password, :host => uri.hostname, :port => uri.port)

		#Creates the tables
		conn.run("
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
		DROP TABLE IF EXISTS GenderTypes;
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

		DROP FUNCTION IF EXISTS TruncateStagingTables();
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
			,BreedColor varchar(50)
			,BreedDisplayName varchar(255)
		);

		CREATE TABLE BreedTypesStaging (
			BreedName varchar(255) NOT NULL
		);

		CREATE TABLE GenderTypes (
			GenderPK SERIAL PRIMARY KEY
			,PetFinderGender char(1)
			,GenderDisplayName varchar(10)
		);

		CREATE TABLE OptionTypes (
			OptionTypePK SERIAL PRIMARY KEY
			, OptionTypeName varchar(50) UNIQUE NOT NULL
		);

		CREATE TABLE SizeTypes (
			SizeTypePK SERIAL Primary Key
			,SizeTypeName varchar(2) UNIQUE NOT NULL
			,SizeTypeDisplayName varchar(12)
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
			,GenderPK int NOT NULL REFERENCES GenderTypes(GenderPK)
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

		CREATE OR REPLACE FUNCTION TruncateStagingTables()
		RETURNS void AS $$
		BEGIN
			TRUNCATE petcontactsstaging;
			TRUNCATE petoptionsstaging;
			TRUNCATE petbreedsstaging;
			TRUNCATE petphotosstaging;
			TRUNCATE PetsStaging;
		END
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

		CREATE OR REPLACE FUNCTION ProcessStagingTables()
		RETURNS text as $$
		BEGIN

			--Just delete all the things
			TRUNCATE Pets CASCADE;

			--Insert Pets
			INSERT INTO Pets (
			  PetFinderID
			  ,ShelterPK
			  ,ShelterPetID
			  ,Name
			  ,AnimalTypePK
			  ,GenderPK
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
			  ,gt.GenderPK
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
			JOIN GenderTypes gt ON gt.PetFinderGender = ps.Gender
			WHERE NOT EXISTS (
			  SELECT *
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
				AND p.PetPK = pb.PetPK
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
				AND p.PetPK = pb.PetPK
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
			JOIN Pets p ON p.PetPK = pc.PetPK
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
				WHERE pc.PetPK = p.PetPK
			);

			DELETE FROM PetOptions po
			WHERE NOT EXISTS (
				SELECT 1
				FROM PetOptionsStaging pos
				JOIN OptionTypes ot ON pos.OptionTypeName = ot.OptionTypeName
				JOIN Pets p ON p.PetFinderID = pos.PetFinderID
				WHERE ot.OptionTypePK = po.OptionTypePK
				AND p.PetPK = po.PetPK
			);

			INSERT INTO PetOptions (PetPK, OptionTypePK)
			SELECT p.PetPK
				,ot.OptionTypePK
			FROM PetOptionsStaging pos
			JOIN OptionTypes ot ON pos.OptionTypeName = ot.OptionTypeName
			JOIN Pets p ON p.PetFinderID = pos.PetFinderID
			WHERE NOT EXISTS (
				SELECT 1
				FROM PetOptions po
				WHERE ot.OptionTypePK = po.OptionTypePK
				AND p.PetPK = po.PetPK
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
		RETURN '';
		END
		$$ LANGUAGE plpgsql;

		CREATE OR REPLACE FUNCTION ProcessSpecialShelterPetIDs()
		RETURNS void as $$
		BEGIN
			/*
				The Client we are working with has overloaded the ShelterPetIDs to add additional Options. so like NoClaw a cat may have FELV/FIV they have set the ShelterPetID
				This Function splits the ShelterPetIDs by / and then inserts them as multiple additonal options.

				Specifically not making this parameterized for another delimiter as this is a function that should not be heavily used
			*/
			DROP TABLE IF EXISTS StringsToSplit;
			DROP TABLE IF EXISTS SplitStrings;

			CREATE TEMPORARY TABLE StringsToSplit(
				PetPK int
				,String varchar(100)
			);

			CREATE TEMPORARY TABLE SplitStrings(
				PetPK int
				,String varchar(100)
			);

			INSERT INTO StringsToSplit (PetPK, String)
			SELECT p.PetPK
				,ShelterPetID
			FROM Pets p;

			/*
				This splits the strings out into a table which is
					PetPK and SplitString
					aka VALUES (3,'FELV/FIV');
					Becomes
					PetPK	String
					3		FELV
					3		FIV
				This can probably be done better. if you can find a way to user regexp_split_to_array with a LEFT JOIN LATERAL have at.
			*/
			INSERT INTO SplitStrings (PetPK,String)
			SELECT PetPK,String
			FROM (
				SELECT
					s2s.PetPK
					,split_part(s2s.String,'/',1) as String
				FROM StringsToSplit s2s
				UNION ALL
				SELECT
					s2s.PetPK
					,split_part(s2s.String,'/',2)
				FROM StringsToSplit s2s
				UNION ALL
				SELECT
					s2s.PetPK
					,split_part(s2s.String,'/',3)
				FROM StringsToSplit s2s
				UNION ALL
				SELECT
					s2s.PetPK
					,split_part(s2s.String,'/',4)
				FROM StringsToSplit s2s
				UNION ALL
				SELECT
					s2s.PetPK
					,split_part(s2s.String,'/',5)
				FROM StringsToSplit s2s
				UNION ALL
				SELECT
					s2s.PetPK
					,split_part(s2s.String,'/',6)
				FROM StringsToSplit s2s
			) SplitStrings
			WHERE SplitStrings.String != ''
			ORDER BY PetPK
				,String
			;


			--Add any new Options that dont exist already
			INSERT INTO OptionTypes (OptionTypeName)
			SELECT OtherOptions.String
			FROM (
				SELECT ss.String
				FROM SplitStrings ss
				GROUP BY ss.String
			) OtherOptions
			WHERE NOT EXISTS (
				SELECT 1
				FROM OptionTypes ot
				WHERE ot.OptionTypeName = OtherOptions.String
			)
			;

			INSERT INTO PetOptions (PetPK, OptionTypePK)
			SELECT SpecialOptions.PetPK
				,ot.OptionTypePK
			FROM (
				SELECT
					ss.PetPK
					,ss.String as OptionTypeName
				FROM SplitStrings ss
				GROUP BY ss.PetPK
					,ss.String
			) SpecialOptions
			JOIN OptionTypes ot ON SpecialOptions.OptionTypeName = ot.OptionTypeName
			WHERE NOT EXISTS (
				SELECT 1
				FROM PetOptions po
				WHERE ot.OptionTypePK = po.OptionTypePK
				AND SpecialOptions.PetPK = po.PetPK
			);

			/*
				Dont Do a DELETE from PetOptions like you do in the Main Processing version
				 1. you dont have all of the optins here
				 2. the main processing would have taken care of it already
			*/
		END
		$$ LANGUAGE plpgsql;


		")

		# Populates all of the tables using the xsd
		doc = REXML::Document.new(File.new('petfinder.xsd'))

		animalTypes = conn[:animaltypes]

		REXML::XPath.each(doc, '//xs:simpleType[@name="animalType"]//xs:enumeration/@value') do |e|
		  animalTypes.insert(:animaltypename => e.value)
		end

		petoptiontypes = conn[:optiontypes]

		REXML::XPath.each(doc, '//xs:simpleType[@name="petOptionType"]//xs:enumeration/@value') do |f|
		  petoptiontypes.insert(:optiontypename => f.value)
			# puts f.value
		end

		breedtypesstaging = conn[:breedtypesstaging]

		REXML::XPath.each(doc, '//xs:simpleType[@name="petfinderBreedType"]//xs:enumeration/@value') do |f|
		  breedtypesstaging.insert(:breedname => f.value)
			# puts f.value
		end

		conn.run "
			DROP TABLE IF EXISTS KnownBreedColors;
			CREATE TEMPORARY TABLE KnownBreedColors (
				BreedName varchar(255)
				, BreedColor varchar(50)
				, BreedDisplayName varchar(255)
			);
			/*
				This is very far from a complete list of Colors.

				Feel free to add more.
				Unfortunately PetFinder does not give exact colors for everything and these are just guesses
			*/


			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Black Labrador Retriever' , 'Black' , 'Labrador Retriever' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Black Russian Terrier' , 'Black' , 'Russian Terrier' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair-black' , 'Black' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair-black' , 'Black' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair-black' , 'Black' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby - black' , 'Black' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Black and Tan Coonhound' , 'Black and Tan' , 'Coonhound' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Dalmatian' , 'Black and White' , 'Dalmation' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair-black and white' , 'Black And White' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair-black and white' , 'Black And White' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair-black and white' , 'Black And White' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Chocolate Labrador Retriever' , 'Brown' , 'Labrador Retriever' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair - brown' , 'Brown' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair - brown' , 'Brown' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair - brown' , 'Brown' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby - Brown' , 'Brown' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair - buff' , 'Buff' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair - buff' , 'Buff' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair - buff' , 'Buff' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Golden Retriever' , 'Buff' , 'Golden Retriever' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby - buff' , 'Buff' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair - buff and white' , 'Buff and White' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair - buff and white' , 'Buff and White' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair - buff and white' , 'Buff and White' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair-gray' , 'Gray' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair-gray' , 'Gray' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair-gray' , 'Gray' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair - gray and white' , 'Gray and White' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair - gray and white' , 'Gray and White' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair - gray and white' , 'Gray and White' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby - Grey' , 'Grey' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair-mitted' , 'Mitted' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair - orange' , 'Orange' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair-orange' , 'Orange' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair-orange' , 'Orange' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby - Orange' , 'Orange' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair - orange and white' , 'Orange and White' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair - orange and white' , 'Orange and White' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair - orange and white' , 'Orange and White' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Black Mouth Cur' , 'Other' , 'Black Mouth Cur' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair' , 'Other' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair' , 'Other' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair' , 'Other' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby' , 'Other' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Long Hair-white' , 'White' , 'Domestic Long Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Medium Hair-white' , 'White' , 'Domestic Medium Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Domestic Short Hair-white' , 'White' , 'Domestic Short Hair' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Florida White' , 'White' , 'Florida' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'Tabby - white' , 'White' , 'Tabby' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'West Highland White Terrier Westie' , 'White' , 'West Highland White Terrier Westie' );
			INSERT INTO KnownBreedColors (BreedName, BreedColor, BreedDisplayName) VALUES ( 'White German Shepherd' , 'White' , 'German Shepherd' );

			INSERT INTO BreedTypes (
				BreedName
				,BreedColor
				,BreedDisplayName
			)
			SELECT
				bts2.BreedName
				, COALESCE(kbc.BreedColor,'Other') as BreedColor
				, COALESCE(kbc.BreedDisplayName,bts2.BreedName) as BreedDisplayName
			FROM (
				SELECT bts.BreedName
				FROM BreedTypesStaging bts
				GROUP BY bts.BreedName
			) bts2
			LEFT JOIN KnownBreedColors kbc ON bts2.BreedName = kbc.BreedName;

			DROP TABLE BreedTypesStaging;
		"

		ageTypes = conn[:agetypes]

		REXML::XPath.each(doc, '//xs:simpleType[@name="petAgeType"]//xs:enumeration/@value') do |f|
		  ageTypes.insert(:agetypename => f.value)
			# puts f.value
		end

		conn.run "
			INSERT INTO SizeTypes (SizeTypeName, SizeTypeDisplayName) VALUES ('S', 'Small');
			INSERT INTO SizeTypes (SizeTypeName, SizeTypeDisplayName) VALUES ('M', 'Medium');
			INSERT INTO SizeTypes (SizeTypeName, SizeTypeDisplayName) VALUES ('L', 'Large');
			INSERT INTO SizeTypes (SizeTypeName, SizeTypeDisplayName) VALUES ('XL', 'Extra Large');
		";

		conn.run "
			INSERT INTO GenderTypes (PetFinderGender, GenderDisplayName)
			VALUES ('M','Male');
			INSERT INTO GenderTypes (PetFinderGender, GenderDisplayName)
			VALUES ('F','Female');
		";
	end
#puts doc
end
