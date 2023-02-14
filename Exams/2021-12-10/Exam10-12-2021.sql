CREATE DATABASE Airport

USE Airport

CREATE TABLE Passengers
(
Id INT PRIMARY KEY IDENTITY,
FullName VARCHAR(100) UNIQUE NOT NULL,
Email VARCHAR(50) UNIQUE NOT NULL
)

CREATE TABLE Pilots
(
Id INT PRIMARY KEY IDENTITY,
FirstName VARCHAR(30) UNIQUE NOT NULL,
LastName VARCHAR(30) UNIQUE NOT NULL,
Age TINYINT CHECK(Age >=21 AND Age<=62) NOT NULL,
Rating FLOAT CHECK(Rating>=0.0 AND Rating <= 10.0)
)

CREATE TABLE AircraftTypes
(
Id INT PRIMARY KEY IDENTITY,
TypeName VARCHAR(30) UNIQUE NOT NULL
)

CREATE TABLE Aircraft
(
Id INT PRIMARY KEY IDENTITY,
Manufacturer VARCHAR(25) NOT NULL,
Model VARCHAR(30) NOT NULL,
[Year] INT NOT NULL,
FlightHours INT,
Condition CHAR(1) NOT NULL,
TypeId INT FOREIGN KEY REFERENCES AircraftTypes(Id) NOT NULL
)

CREATE TABLE PilotsAircraft
(
AircraftId INT FOREIGN KEY REFERENCES Aircraft(Id) NOT NULL,
PilotId INT FOREIGN KEY REFERENCES Pilots(Id) NOT NULL,
PRIMARY KEY(AircraftId, PilotId)
)

CREATE TABLE Airports
(
	Id INT PRIMARY KEY IDENTITY,
	AirportName VARCHAR(70) UNIQUE NOT NULL,
	Country VARCHAR(100) UNIQUE NOT NULL
)

CREATE TABLE FlightDestinations
(
Id INT PRIMARY KEY IDENTITY,
AirportId INT FOREIGN KEY REFERENCES Airports(Id) NOT NULL,
[Start] DATETIME NOT NULL,
AircraftId INT FOREIGN KEY REFERENCES Aircraft(Id) NOT NULL,
PassengerId INT FOREIGN KEY REFERENCES Passengers(Id) NOT NULL,
TicketPrice DECIMAL(18,2) DEFAULT 15 NOT NULL
)

--2
INSERT INTO Passengers
(FullName, Email)
SELECT 
	CONCAT(FirstName, ' ', LastName),
	CONCAT(FirstName,LastName, '@gmail.com')
FROM Pilots
WHERE Id BETWEEN 5 AND 15
--3
UPDATE Aircraft
SET Condition = 'A'
WHERE Condition IN ('C','B')
AND (FlightHours IS NULL OR FlightHours <=100)
AND Year >= 2013
--4
DELETE 
FROM Passengers
WHERE LEN(FullName) <= 10


--5
SELECT 
Manufacturer,
Model,
FlightHours,
Condition
FROM Aircraft
ORDER BY FlightHours DESC

--6
SELECT 
FirstName,
LastName,
Manufacturer,
Model,
FlightHours
FROM Pilots AS p
JOIN PilotsAircraft AS pa
ON p.Id = pa.PilotId
JOIN Aircraft AS a
ON pa.AircraftId = a.Id
WHERE a.FlightHours IS NOT NULL AND a.FlightHours <= 304
ORDER BY FlightHours DESC, p.FirstName

--7

SELECT TOP(20)
	fd.Id AS DestinationId,
	fd.Start,
	p.FullName,
	a.AirportName,
	fd.TicketPrice
FROM FlightDestinations AS fd
JOIN Passengers AS p ON p.Id = fd.PassengerId
JOIN Airports AS a on fd.AirportId = a.Id
WHERE DATEPART(DAY, Start) % 2 = 0
ORDER BY fd.TicketPrice DESC, a.AirportName

--8

SELECT
	a.Id,
	a.Manufacturer,
	a.FlightHours,
	COUNT(f.Id) AS FlightDestinationCounts,
	ROUND(AVG(f.TicketPrice),2) AS AvgPrice
FROM Aircraft AS a
LEFT JOIN FlightDestinations AS f ON f.AircraftId = a.Id
GROUP BY a.Id, a.Manufacturer, a.FlightHours
HAVING COUNT(f.Id) > 1
ORDER BY 4 DESC, 1

--9

SELECT 
	p.FullName,
	COUNT(a.Id),
	SUM(f.TicketPrice)
FROM Passengers AS p
JOIN FlightDestinations AS f ON f.PassengerId = p.Id
JOIN Aircraft AS a ON a.Id = f.AircraftId
WHERE SUBSTRING(p.FullName, 2, 1) = 'a'
GROUP BY p.Id, p.FullName
HAVING COUNT(a.Id)>1
ORDER BY p.FullName

--10
SELECT 
	ap.AirportName,
	fd.Start AS DayTime,
	fd.TicketPrice,
	p.FullName,
	a.Manufacturer,
	a.Model
FROM FlightDestinations AS fd
LEFT JOIN Airports AS ap ON ap.Id = fd.AirportId
LEFT JOIN Passengers AS p on fd.PassengerId = p.Id
LEFT JOIN Aircraft AS a on a.Id = fd.AircraftId
WHERE DATEPART(HOUR,fd.Start) >= 6
AND (DATEPART(HOUR, fd.Start) < 20
	OR(DATEPART(HOUR,fd.Start) = 20 AND DATEPART(MINUTE, fd.Start) = 0))
AND fd.TicketPrice > 2500
ORDER BY a.Model 


--11
GO 

CREATE FUNCTION udf_FlightDestinationsByEmail(@email VARCHAR(50))
RETURNS INT
AS
BEGIN
	RETURN ISNULL((SELECT 
				COUNT(f.Id)
			FROM Passengers AS p
			JOIN FlightDestinations AS f ON f.PassengerId = p.Id
			WHERE p.Email = @email
			GROUP BY p.Id),0)
END

GO

--12
CREATE PROCEDURE usp_SearchByAirportName @airportName VARCHAR(70)
AS 
BEGIN
	SELECT 
		ap.AirportName,
		p.FullName,
		CASE
			WHEN fd.TicketPrice <= 400 THEN 'Low'
			WHEN fd.TicketPrice > 1501 THEN 'High'
			ELSE 'Medium'
		END AS LevelOfTicketPrice,
		a.Manufacturer,
		a.Condition,
		at.TypeName
	FROM Airports AS ap
	JOIN FlightDestinations AS fd ON fd.AirportId = ap.Id
	JOIN Aircraft AS a on fd.AircraftId = a.Id
	JOIN Passengers AS p on fd.PassengerId = p.Id
	JOIN AircraftTypes AS at ON a.TypeId = at.Id
	WHERE ap.AirportName = @airportName
	ORDER BY a.Manufacturer, p.FullName
END



EXEC usp_SearchByAirportName 'Sir Seretse Khama International Airport'