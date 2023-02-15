--1

CREATE TABLE Categories
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL
)

CREATE TABLE Locations
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL,
Municipality VARCHAR(50),
Province VARCHAR(50)
)

CREATE TABLE Sites
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(100) NOT NULL,
LocationId INT FOREIGN KEY REFERENCES Locations(Id) NOT NULL,
CategoryId INT FOREIGN KEY REFERENCES Categories(Id) NOT NULL,
Establishment VARCHAR(15)
)

CREATE TABLE Tourists
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL,
Age INT CHECK(Age BETWEEN 0 AND 120) NOT NULL,
PhoneNumber VARCHAR(20) NOT NULL,
Nationality VARCHAR(30) NOT NULL,
Reward VARCHAR(20)
)

CREATE TABLE SitesTourists
(
TouristId INT FOREIGN KEY REFERENCES Tourists(Id),
SiteId INT FOREIGN KEY REFERENCES Sites(Id),
PRIMARY KEY (TouristId, SiteId)
)

CREATE TABLE BonusPrizes
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL
)

CREATE TABLE TouristsBonusPrizes
(
TouristId INT FOREIGN KEY REFERENCES Tourists(Id),
BonusPrizeId INT FOREIGN KEY REFERENCES BonusPrizes(Id),
PRIMARY KEY (TouristId, BonusPrizeId)
)

--2


INSERT INTO Tourists
(Name, Age, PhoneNumber, Nationality, Reward)
VALUES
('Borislava Kazakova',52,'+359896354244','Bulgaria',NULL),
('Peter Bosh',48,'+447911844141','UK',NULL),
('Martin Smith',29,'+353863818592','Ireland','Bronze badge'),
('Svilen Dobrev',49,'+359986584786','Bulgaria','Silver badge'),
('Kremena Popova',38,'+359893298604','Bulgaria',NULL)

INSERT INTO Sites
(Name, LocationId, CategoryId, Establishment)
VALUES
('Ustra fortress',90,7,'X'),
('Karlanovo Pyramids',65,7,NULL),
('The Tomb of Tsar Sevt',63,8,'V BC'),
('Sinite Kamani Natural Park',17,1,NULL),
('St. Petka of Bulgaria – Rupite',92,6,'1994')


--3

UPDATE Sites
SET Establishment = '(not defined)'
WHERE Establishment IS NULL

--4

DELETE FROM 
TouristsBonusPrizes 
WHERE BonusPrizeId = (SELECT 
							Id
						FROM BonusPrizes
						WHERE Name = 'Sleeping bag')

DELETE FROM BonusPrizes
WHERE Name = 'Sleeping bag'

--5

SELECT 
	Name,
	Age,
	PhoneNumber,
	Nationality
FROM Tourists
ORDER BY Nationality, Age DESC, Name

--6

SELECT 
	s.Name,
	l.Name,
	s.Establishment,
	c.Name
FROM Sites AS s
LEFT JOIN Locations AS l on s.LocationId = l.Id
LEFT JOIN Categories AS c ON s.CategoryId = c.Id
ORDER BY c.Name DESC, l.Name, s.Name

--7

SELECT 
	l.Province, 
	l.Municipality, 
	l.Name,
	COUNT(s.Id) AS CountOfSites
FROM Locations AS l
JOIN Sites AS s ON s.LocationId = l.Id
WHERE l.Province = 'Sofia'
GROUP BY l.Province, l.Municipality, l.Name
ORDER BY CountOfSites DESC, l.Name

--8

SELECT
	s.Name,
	l.Name,
	l.Municipality,
	l.Province,
	s.Establishment
FROM Sites AS s
JOIN Locations AS l ON l.Id = s.LocationId
WHERE l.Name NOT LIKE '[BMD]%'
AND s.Establishment LIKE '%BC'
ORDER BY s.Name

--9

SELECT 
	t.Name,
	t.Age,
	t.PhoneNumber,
	t.Nationality,
	ISNULL(b.Name,'(no bonus prize)')AS Reward
FROM Tourists AS t
LEFT JOIN TouristsBonusPrizes AS tb ON t.Id = tb.TouristId
LEFT JOIN BonusPrizes AS b ON tb.BonusPrizeId = b.Id
ORDER BY t.Name

--10

SELECT DISTINCT
	SUBSTRING(t.Name, CHARINDEX(' ',t.Name)+1,LEN(t.NAME)) AS LastName,
	t.Nationality,
	t.Age,
	t.PhoneNumber
FROM Tourists AS t
JOIN SitesTourists AS st ON st.TouristId = t.Id
JOIN Sites AS s ON st.SiteId = s.Id
JOIN Categories AS c ON s.CategoryId = c.Id
WHERE c.Name = 'History and archaeology'
ORDER BY LastName

--11

GO

CREATE FUNCTION udf_GetTouristsCountOnATouristSite (@Site VARCHAR(100))
RETURNS INT
AS
BEGIN
	DECLARE @result INT = (SELECT
								Count(*)
							FROM Sites AS s
							JOIN SitesTourists AS st ON st.SiteId = s.Id
							WHERE s.Name = @site)


	RETURN @result
END


GO

--12

CREATE PROCEDURE usp_AnnualRewardLottery @TouristName VARCHAR(50)
AS

BEGIN
	DECLARE @visits INT = (SELECT
							COUNT(*)
						FROM Tourists AS t
						JOIN SitesTourists AS st ON st.TouristId = t.Id
						WHERE t.Name = @TouristName)
	SELECT
		@TouristName AS Name,
		CASE
			WHEN @visits >= 100 THEN 'Gold badge' 
			WHEN @visits >= 50 THEN 'Silver badge'
			WHEN @visits >= 25 THEN 'Bronze badge'
		END AS Reward
END