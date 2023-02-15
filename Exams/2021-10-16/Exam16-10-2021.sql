CREATE TABLE Sizes
(
Id INT PRIMARY KEY IDENTITY,
Length INT CHECK(Length BETWEEN 10 AND 25) NOT NULL,
RingRange DECIMAL(2,1) CHECK(RingRange BETWEEN 1.5 AND 7.5) NOT NULL
)

CREATE TABLE Tastes
(
Id INT PRIMARY KEY IDENTITY,
TasteType VARCHAR(20) NOT NULL,
TasteStrength VARCHAR(15) NOT NULL,
ImageURL NVARCHAR(100) NOT NULL
)

CREATE TABLE Brands
(
Id INT PRIMARY KEY IDENTITY,
BrandName VARCHAR(30) UNIQUE NOT NULL,
BrandDescription VARCHAR(MAX)
)

CREATE TABLE Cigars
(
Id INT IDENTITY PRIMARY KEY,
CigarName VARCHAR(80) NOT NULL,
BrandId INT FOREIGN KEY REFERENCES Brands(Id) NOT NULL,
TastId INT FOREIGN KEY REFERENCES Tastes(Id) NOT NULL, -- possible typo
SizeId INT FOREIGN KEY REFERENCES Sizes(Id) NOT NULL,
PriceForSingleCigar DECIMAL(18,2) NOT NULL,
ImageURL NVARCHAR(100) NOT NULL,
)

CREATE TABLE Addresses
(
Id INT PRIMARY KEY IDENTITY,
Town VARCHAR(30) NOT NULL,
Country NVARCHAR(30) NOT NULL,
Streat NVARCHAR(100) NOT NULL,
ZIP VARCHAR(20) NOT NULL
)

CREATE TABLE Clients
(
Id INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(30) NOT NULL,
LastName NVARCHAR(30) NOT NULL,
Email NVARCHAR(50) NOT NULL,
AddressId INT FOREIGN KEY REFERENCES Addresses(Id) NOT NULL
)

CREATE TABLE ClientsCigars
(
	ClientId INT FOREIGN KEY REFERENCES Clients(Id),
	CigarId INT FOREIGN KEY REFERENCES Cigars(Id),
	PRIMARY KEY (ClientId, CigarId)
)

--2

INSERT INTO Cigars
(CigarName, BrandId, TastId, SizeId, PriceForSingleCigar, ImageURL)
VALUES
('COHIBA ROBUSTO',9,1,5,15.50,'cohiba-robusto-stick_18.jpg'),
('COHIBA SIGLO I',9,1,10,410.00,'cohiba-siglo-i-stick_12.jpg'),
('HOYO DE MONTERREY LE HOYO DU MAIRE',14,5,11,7.50,'hoyo-du-maire-stick_17.jpg'),
('HOYO DE MONTERREY LE HOYO DE SAN JUAN',14,4,15,32.00,'hoyo-de-san-juan-stick_20.jpg'),
('TRINIDAD COLONIALES',2,3,8,85.21,'trinidad-coloniales-stick_30.jpg')

INSERT INTO Addresses
(Town, Country, Streat, ZIP)
VALUES
('Sofia','Bulgaria','18 Bul. Vasil levski',1000),
('Athens','Greece','4342 McDonald Avenue',10435),
('Zagreb','Croatia','4333 Lauren Drive',10000)

--3

UPDATE Cigars
SET PriceForSingleCigar *= 1.2
WHERE TastId IN (SELECT
					Id
				FROM Tastes
				WHERE TasteType = 'Spicy')

UPDATE Brands
SET BrandDescription = 'New description'
WHERE BrandDescription IS NULL

--4

DELETE FROM ClientsCigars 
WHERE ClientId IN (SELECT Id FROM Clients
					WHERE AddressId IN (SELECT Id
					FROM Addresses
					WHERE Country LIKE 'C%'))

					DELETE FROM Clients 
WHERE AddressId IN (SELECT Id
					FROM Addresses
					WHERE Country LIKE 'C%')

DELETE FROM
Addresses
WHERE Country LIKE 'C%'

--5

SELECT
	CigarName, PriceForSingleCigar, ImageURL
FROM Cigars
ORDER BY PriceForSingleCigar, CigarName DESC

--6

SELECT 
	c.Id, c.CigarName, c.PriceForSingleCigar, t.TasteType, t.TasteStrength
FROM Cigars AS c
JOIN Tastes AS t ON c.TastId = t.Id
WHERE t.TasteType IN ('Earthy','Woody')
ORDER BY c.PriceForSingleCigar DESC

--7

SELECT 
	cl.Id,
	CONCAT(cl.FirstName,' ',cl.LastName) AS ClientName,
	cl.Email
FROM Clients AS cl
LEFT JOIN ClientsCigars AS cc ON cl.Id = cc.ClientId
LEFT JOIN Cigars AS ci ON ci.Id = cc.CigarId
WHERE ci.Id IS NULL
ORDER BY ClientName 

--8

SELECT TOP(5)
	c.CigarName,
	c.PriceForSingleCigar,
	c.ImageURL
FROM Cigars AS c
JOIN Sizes as S ON c.SizeId = s.Id
WHERE s.Length >= 12 AND (c.CigarName LIKE '%ci%'
OR (s.RingRange > 2.55 AND c.PriceForSingleCigar > 50))
ORDER BY c.CigarName, c.PriceForSingleCigar DESC

--9

SELECT 
		r.FullName,
		r.Country,
		r.ZIP,
		r.CigarPrice
	FROM(SELECT 
	CONCAT(cl.FirstName,' ' , cl.LastName) AS FullName,
	ROW_NUMBER() OVER (PARTITION BY cl.Id ORDER BY ci.PriceForSingleCigar DESC) AS rank,
	a.Country,
	a.ZIP,
	CONCAT('$',ci.PriceForSingleCigar) AS CigarPrice
FROM Clients AS cl
JOIN ClientsCigars AS cc ON cc.ClientId = cl.Id
JOIN Cigars AS ci ON ci.Id = cc.CigarId
JOIN Addresses AS a ON cl.AddressId = a.Id
WHERE a.ZIP NOT LIKE '%[^0-9]%') AS r
WHERE r.rank = 1
ORDER BY r.FullName

--10
SELECT 
	cl.LastName,
	CEILING(AVG(s.Length)) AS CiagrLength,
	CEILING(AVG(s.RingRange)) AS CiagrRingRange
FROM Clients AS cl
JOIN ClientsCigars AS cc ON cc.ClientId = cl.Id
JOIN Cigars AS ci ON cc.CigarId = ci.Id
JOIN Sizes AS s ON ci.SizeId = s.Id
WHERE ci.Id IS NOT NULL
GROUP BY cl.LastName
ORDER BY CiagrLength DESC

--11

GO 

CREATE FUNCTION udf_ClientWithCigars(@name NVARCHAR(30))
RETURNS INT
AS
BEGIN
	DECLARE @result INT = (SELECT
								COUNT(cc.CigarId)
							FROM Clients AS cl
							JOIN ClientsCigars AS cc ON cc.ClientId = cl.Id
							WHERE cl.FirstName = @name)
	RETURN @result
END

GO



--12

CREATE PROCEDURE usp_SearchByTaste @taste VARCHAR(20)
AS

BEGIN
	SELECT 
		ci.CigarName,
		CONCAT('$',ci.PriceForSingleCigar) AS Price,
		t.TasteType,
		b.BrandName,
		CONCAT(s.Length, ' cm') AS CigarLength,
		CONCAT(s.RingRange, ' cm') AS CigarRingRange
	FROM Cigars AS ci
	JOIN Tastes AS t ON ci.TastId = t.Id
	JOIN Brands AS b ON ci.BrandId = b.Id
	JOIN Sizes AS s ON ci.SizeId = s.Id
	WHERE t.TasteType = @taste
	ORDER BY CigarLength , CigarRingRange DESC
END

EXEC usp_SearchByTaste 'Woody'