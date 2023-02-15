CREATE DATABASE ColonialJourney 
USE ColonialJourney


--1

CREATE TABLE Planets
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(30) NOT NULL
)

CREATE TABLE Spaceports
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL,
PlanetId INT NOT NULL FOREIGN KEY REFERENCES Planets(Id)
)

CREATE TABLE Spaceships
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL,
Manufacturer VARCHAR(30) NOT NULL,
LightSpeedRate INT DEFAULT 0
)

CREATE TABLE Colonists
(
Id INT PRIMARY KEY IDENTITY,
FirstName VARCHAR(20) NOT NULL,
LastName VARCHAR(20) NOT NULL,
Ucn VARCHAR(10) NOT NULL UNIQUE,
BirthDate DATE NOT NULL
)

CREATE TABLE Journeys
(
Id INT PRIMARY KEY IDENTITY,
JourneyStart DateTime NOT NULL,
JourneyEnd DateTIme NOT NULL,
Purpose VARCHAR(11) CHECK( Purpose IN ('Medical','Technical','Educational','Military')),
DestinationSpaceportId INT NOT NULL FOREIGN KEY REFERENCES Spaceports(Id),
SpaceshipId INT NOT NULL FOREIGN KEY REFERENCES Spaceships(Id)
)

CREATE TABLE TravelCards
(
Id INT PRIMARY KEY IDENTITY,
CardNumber CHAR(10) NOT NULL UNIQUE,
JobDuringJourney VARCHAR(8) CHECK(JobDuringJourney IN ('Pilot','Engineer','Trooper','Cleaner','Cook')),
ColonistId INT NOT NULL FOREIGN KEY REFERENCES Colonists(Id),
JourneyId INT NOT NULL FOREIGN KEY REFERENCES Journeys(Id)
)

--2

INSERT INTO Planets
(Name)
VALUES
('Mars'),
('Earth'),
('Jupiter'),
('Saturn')

INSERT INTO Spaceships
(Name,Manufacturer,LightSpeedRate)
VALUES
('Golf','VW',3),
('WakaWaka','Wakanda',4),
('Falcon9','SpaceX',1),
('Bed','Vidolov',6)

--3

UPDATE Spaceships
SET LightSpeedRate += 1
WHERE Id BETWEEN 8 AND 12

--4
DELETE FROM TravelCards
WHERE JourneyId IN (SELECT TOP(3) Id
							FROM Journeys
							ORDER BY Id)


DELETE 
FROM JOURNEYS
WHERE Id IN (SELECT TOP(3) Id
							FROM Journeys
							ORDER BY Id)

--5
SELECT
	Id,
	FORMAT(JourneyStart,'dd/MM/yyyy'),
	FORMAT(JourneyEnd,'dd/MM/yyyy')
FROM Journeys
WHERE Purpose = 'Military'
ORDER BY JourneyStart

--6

SELECT 
	c.Id AS id,
	CONCAT(c.FirstName,' ',c.LastName) AS full_name
FROM Colonists AS c
JOIN TravelCards AS t ON t.ColonistId = c.Id
WHERE t.JobDuringJourney = 'Pilot'
ORDER BY c.Id

--7
SELECT 
	COUNT(c.Id) AS count
FROM Colonists AS c
JOIN TravelCards AS t ON c.Id = t.ColonistId
JOIN Journeys AS j ON t.JourneyId = j.Id
WHERE j.Purpose = 'Technical'

--8
SELECT 
	s.Name,
	s.Manufacturer
FROM Spaceships AS s
JOIN Journeys AS j ON j.SpaceshipId = s.Id
JOIN TravelCards AS t ON t.JourneyId = j.Id
JOIN Colonists AS c ON t.ColonistId = c.Id
WHERE t.JobDuringJourney = 'Pilot'
AND DATEDIFF(YEAR,c.BirthDate, '2019-01-01') < 30 
ORDER BY s.Name

--9
SELECT
	p.Name AS PlanetName,
	COUNT(j.Id) AS JourneysCount
FROM Planets AS p
JOIN Spaceports AS s ON s.PlanetId = p.Id
JOIN Journeys AS j on j.DestinationSpaceportId = s.Id
GROUP BY p.Name
ORDER BY COUNT(j.Id) DESC, p.Name 

--10
SELECT * FROM 
(SELECT 
	t.JobDuringJourney,
	CONCAT(c.FirstName,' ',c.LastName) AS FullName,
	RANK() OVER (PARTITION BY t.JobDuringJourney ORDER BY c.BirthDate) AS JobRank
FROM Colonists AS c
JOIN TravelCards AS t ON t.ColonistId = c.Id
JOIN Journeys AS j ON t.JourneyId = j.Id) AS ranked
WHERE ranked.JobRank = 2


--11
GO

CREATE FUNCTION dbo.udf_GetColonistsCount(@PlanetName VARCHAR (30))
RETURNS INT
AS
BEGIN
	RETURN(SELECT
				COUNT(c.Id)
			FROM Colonists AS c
			JOIN TravelCards AS t ON c.Id = t.ColonistId
			JOIN Journeys AS j ON t.JourneyId = j.Id
			JOIN Spaceports AS sp ON sp.Id = j.DestinationSpaceportId
			JOIN Planets AS p ON p.Id = sp.PlanetId
			WHERE p.Name = @PlanetName)
END

GO

--12

CREATE PROCEDURE usp_ChangeJourneyPurpose @JourneyId INT  ,@NewPurpose VARCHAR(11)
AS
BEGIN
	IF @JourneyId NOT IN (SELECT Id FROM Journeys)
		THROW 50100,'The journey does not exist!',1

	ELSE IF (SELECT 
			Purpose
		FROM Journeys 
		WHERE Id = @JourneyId) = @NewPurpose
		THROW 50100, 'You cannot change the purpose!',1
	ELSE
		BEGIN
			UPDATE Journeys
			SET Purpose = @NewPurpose
		WHERE Id = @JourneyId
	END

END

--“Medical”, “Technical”, “Educational”, “Military”.