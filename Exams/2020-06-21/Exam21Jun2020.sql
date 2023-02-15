--1



CREATE TABLE Cities
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(20) NOT NULL,
CountryCode CHAR(2) NOT NULL
)

CREATE TABLE Hotels
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(30) NOT NULL,
CityId INT NOT NULL FOREIGN KEY REFERENCES Cities(Id),
EmployeeCount INT NOT NULL,
BaseRate DECIMAL(18,2)
)

CREATE TABLE Rooms
(
Id INT PRIMARY KEY IDENTITY,
Price DECIMAL(18,2) NOT NULL,
Type NVARCHAR(20) NOT NULL,
Beds INT NOT NULL,
HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotels(Id)
)

CREATE TABLE Trips
(
Id INT PRIMARY KEY IDENTITY,
RoomId INT NOT NULL FOREIGN KEY REFERENCES Rooms(Id),
BookDate DATE NOT NULL,
ArrivalDate DATE NOT NULL,
ReturnDate DATE NOT NULL,
CancelDate DATE,
CHECK(ArrivalDate < ReturnDate),
CHECK(BookDate < ArrivalDate)
)

CREATE TABLE Accounts
(
Id INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(50) NOT NULL,
MiddleName NVARCHAR(20),
LastName NVARCHAR(50) NOT NULL,
CityId INT NOT NULL FOREIGN KEY REFERENCES Cities(Id),
BirthDate DATE NOT NULL,
Email VARCHAR(100) NOT NULL UNIQUE
)

CREATE Table AccountsTrips
(
AccountId INT NOT NULL FOREIGN KEY REFERENCES Accounts(Id),
TripId INT NOT NULL FOREIGN KEY REFERENCES Trips(Id),
Luggage INT NOT NULL CHECK(Luggage >= 0),
PRIMARY KEY (AccountId, TripId)
)

--2

INSERT INTO Accounts
(FirstName, MiddleName, LastName, CityId, BirthDate, Email)
VALUES
('John','Smith','Smith',34,'1975-07-21','j_smith@gmail.com'),
('Gosho',NULL,'Petrov',11,'1978-05-16','g_petrov@gmail.com'),
('Ivan','Petrovich','Pavlov',59,'1849-09-26','i_pavlov@softuni.bg'),
('Friedrich','Wilhelm','Nietzsche',2,'1844-10-15','f_nietzsche@softuni.bg')

INSERT INTO Trips
(RoomId, BookDate, ArrivalDate, ReturnDate, CancelDate)
VALUES
(101,'2015-04-12','2015-04-14','2015-04-20','2015-02-02'),
(102,'2015-07-07','2015-07-15','2015-07-22','2015-04-29'),
(103,'2013-07-17','2013-07-23','2013-07-24',NULL),
(104,'2012-03-17','2012-03-31','2012-04-01','2012-01-10'),
(109,'2017-08-07','2017-08-28','2017-08-29',NULL)

--3
UPDATE Rooms
SET Price *= 1.14
WHERE HotelId IN (5,7,9)

--4
DELETE FROM AccountsTrips
WHERE AccountId = 47


--5
SELECT 
	a.FirstName,
	a.LastName,
	FORMAT(a.BirthDate, 'MM-dd-yyyy'),
	c.Name AS Hometown,
	a.Email
FROM Accounts AS a
JOIN Cities AS c ON a.CityId = c.Id
WHERE SUBSTRING(a.Email,1,1) = 'e'
ORDER BY c.Name 


--6

SELECT
	c.Name AS City,
	COUNT(h.Id) AS Hotels
FROM Cities AS c
JOIN Hotels AS h ON c.Id = h.CityId
GROUP BY c.Name
HAVING COUNT(h.Id) > 0
ORDER BY COUNT(h.Id) DESC, c.Name

--7

SELECT 
	a.Id,
	CONCAT(a.FirstName,' ',a.LastName) AS FullName,
	MAX(DATEDIFF(DAY,t.ArrivalDate,t.ReturnDate)) AS LongestTrip,
	MIN(DATEDIFF(DAY,t.ArrivalDate,t.ReturnDate)) AS ShortestTrip
FROM Accounts AS a
JOIN AccountsTrips AS at ON at.AccountId = a.Id
JOIN Trips AS t ON t.Id = at.TripId
WHERE t.CancelDate IS NULL
AND a.MiddleName IS NULL
GROUP BY a.Id, a.FirstName, a.MiddleName, a.LastName
ORDER BY MAX(DATEDIFF(DAY,t.ArrivalDate,t.ReturnDate)) DESC, MIN(DATEDIFF(DAY,t.ArrivalDate,t.ReturnDate))


--8

SELECT TOP(10)
	c.Id,
	c.Name AS City,
	c.CountryCode AS Country,
	COUNT(a.Id) AS Accounts
FROM Cities AS c
JOIN Accounts AS a ON a.CityId = c.Id
GROUP BY c.Id, c.Name, c.CountryCode
ORDER BY COUNT(a.Id) DESC

--9

SELECT 
	a.Id,
	a.Email,
	c.Name,
	COUNT(t.Id) AS Trips
FROM Accounts AS a
JOIN AccountsTrips AS at ON at.AccountId = a.Id
JOIN Trips AS t ON t.Id = at.TripId
JOIN Rooms AS r ON t.RoomId = r.Id
JOIN Hotels AS h ON r.HotelId = h.Id
JOIN Cities AS c ON a.CityId = c.Id
WHERE a.CityId = h.CityId
GROUP BY a.Id, a.Email, c.Name
HAVING COUNT(t.Id) > 0
ORDER BY COUNT(t.Id) DESC, a.Id 


--10

SELECT 
	t.Id,
	CONCAT(a.FirstName, ' '+a.MiddleName,' ', a.LastName) AS FullName,
	ht.Name AS [From],
	c.Name AS [To],
	CASE 
	WHEN t.CancelDate IS NOT NULL THEN 'Canceled'
	ELSE
	CONCAT(DATEDIFF(DAY,ArrivalDate,ReturnDate),' days')
	END AS Duration
FROM Trips AS t
 JOIN AccountsTrips AS at ON at.TripId = t.Id
 JOIN Accounts AS a ON at.AccountId = a.Id
 JOIN Rooms AS r ON t.RoomId = r.Id
 JOIN Hotels AS h ON h.Id = r.HotelId
 JOIN Cities AS c ON c.Id = h.CityId
 JOIN Cities AS ht on a.CityId = ht.Id
 ORDER BY FullName, t.Id

 --11

 GO

 CREATE FUNCTION udf_GetAvailableRoom(@HotelId INT, @Date DATE, @People INT)
 RETURNS VARCHAR(100)
 AS 
 BEGIN
	DECLARE @Results TABLE (Id INT, RoomType VARCHAR(30), Beds INT, Total DECIMAL(18,2))
	INSERT INTO @Results
	SELECT TOP(1)
		r.Id AS Id, 
		r.Type AS RoomType,
		r.Beds AS Beds,
		@People * (h.BaseRate + r.Price) AS Total
	FROM Rooms AS r
	JOIN Hotels AS h ON r.HotelId = h.Id
	JOIN Trips AS t ON t.RoomId = r.Id
	WHERE @HotelId = r.HotelId
	AND r.Beds >= @People
	AND ((@Date < t.ArrivalDate 
	OR @Date > t.ReturnDate
	OR t.CancelDate IS NOT NULL)
	AND DATEPART(YEAR,t.ArrivalDate) = DATEPART(YEAR,@date))
	ORDER BY Total DESC

	DECLARE @Print VARCHAR(100)
	IF
	(SELECT COUNT(*) FROM @Results) = 0
	BEGIN
		SET @Print = 'No rooms available'
	END
	ELSE
	BEGIN	
		SET @Print = (SELECT 
					CONCAT('Room ',r.Id,': ',r.RoomType,' (',r.Beds,' beds) - $',r.Total)
				FROM @Results AS r)
	END
	RETURN @Print
	
 END


 GO



	--12



CREATE OR ALTER PROCEDURE usp_SwitchRoom @TripId INT, @TargetRoomId INT
AS
BEGIN
	DECLARE @currentHotelId INT = (SELECT 
									h.Id
									FROM Hotels AS h
									JOIN Rooms AS r ON h.Id = r.HotelId
									JOIN Trips AS t ON t.RoomId = r.Id
									WHERE t.Id = @TripId)

	DECLARE @TargetHotelId INT = (SELECT
									h.Id 
									FROM Hotels AS h
									JOIN Rooms AS r ON r.HotelId = h.Id
									WHERE r.Id = @TargetRoomId)

	IF @currentHotelId <> @TargetHotelId
	
	THROW 50001,'Target room is in another hotel!',1
	
	
	IF (SELECT 
				Beds
			FROM Rooms
			WHERE Id = @TargetRoomId) < 

			(SELECT 
				COUNT(a.Id)
			FROM Trips AS t
			JOIN AccountsTrips AS at ON t.Id = at.TripId
			JOIN Accounts AS a ON at.AccountId = a.Id
			WHERE t.Id = @TripId)
			
	THROW 50002,'Not enough beds in target room!',1
	

	
	
		UPDATE Trips
		SET RoomId = @TargetRoomId
		WHERE Id = @TripId
	

END

EXEC usp_SwitchRoom 10, 11
SELECT RoomId FROM Trips WHERE Id = 10



GO