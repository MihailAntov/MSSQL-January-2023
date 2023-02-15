--1

CREATE TABLE Countries
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(50) UNIQUE
)

CREATE TABLE Customers
(
Id INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(25),
LastName NVARCHAR(25),
Gender CHAR(1) CHECK(Gender IN ('M','F')),
Age INT,
PhoneNumber CHAR(10),
CountryId INT FOREIGN KEY REFERENCES Countries(Id)
)

CREATE TABLE Products
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(25) UNIQUE,
Description NVARCHAR(250),
Recipe NVARCHAR(MAX),
Price MONEY CHECK(Price > 0)
)

CREATE TABLE Feedbacks
(
Id INT PRIMARY KEY IDENTITY,
Description NVARCHAR(255),
Rate DECIMAL(4,2) CHECK (Rate BETWEEN 0 AND 10),
ProductId INT FOREIGN KEY REFERENCES Products(Id),
CustomerId INT FOREIGN KEY REFERENCES Customers(Id)
)

CREATE TABLE Distributors
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(25) UNIQUE,
AddressText NVARCHAR(30),
Summary NVARCHAR(200),
CountryId INT FOREIGN KEY REFERENCES Countries(Id)
)

CREATE TABLE Ingredients
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(30),
Description NVARCHAR(200),
OriginCountryId INT FOREIGN KEY REFERENCES Countries(Id),
DistributorId INT FOREIGN KEY REFERENCES Distributors(Id)
)

CREATE TABLE ProductsIngredients
(
ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
IngredientId INT NOT NULL FOREIGN KEY REFERENCES Ingredients(Id),
PRIMARY KEY (ProductId, IngredientId)
)

--2
INSERT INTO Distributors
(Name, CountryId, AddressText, Summary)
VALUES
('Deloitte & Touche',2,'6 Arch St #9757','Customizable neutral traveling'),
('Congress Title',13,'58 Hancock St','Customer loyalty'),
('Kitchen People',1,'3 E 31st St #77','Triple-buffered stable delivery'),
('General Color Co Inc',21,'6185 Bohn St #72','Focus group'),
('Beck Corporation',23,'21 E 64th Ave','Quality-focused 4th generation hardware')

INSERT INTO Customers
(FirstName, LastName, Age, Gender, PhoneNumber, CountryId)
VALUES
('Francoise','Rautenstrauch',15,'M','0195698399',5),
('Kendra','Loud',22,'F','0063631526',11),
('Lourdes','Bauswell',50,'M','0139037043',8),
('Hannah','Edmison',18,'F','0043343686',1),
('Tom','Loeza',31,'M','0144876096',23),
('Queenie','Kramarczyk',30,'F','0064215793',29),
('Hiu','Portaro',25,'M','0068277755',16),
('Josefa','Opitz',43,'F','0197887645',17)

--3
UPDATE Ingredients
SET DistributorId = 35
WHERE Name IN ('Bay Leaf','Paprika','Poppy')

UPDATE Ingredients
SET OriginCountryId = 14
WHERE OriginCountryId = 8

--4
DELETE FROM Feedbacks
WHERE CustomerId = 14
OR ProductId = 5

--5

SELECT 
	Name,
	Price,
Description
FROM Products
ORDER BY Price DESC, Name ASC

--6
SELECT
	f.ProductId,
	f.Rate,
	f.Description,
	c.Id AS CustomerId,
	c.Age,
	c.Gender
FROM Feedbacks AS f
JOIN Customers AS c ON f.CustomerId = c.Id
WHERE f.Rate < 5.0
ORDER BY f.ProductId DESC, Rate

--7

SELECT
	CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
	c.PhoneNumber,
	c.Gender
FROM Customers AS c
LEFT JOIN Feedbacks AS f ON c.Id = f.CustomerId
WHERE f.Id IS NULL
ORDER BY c.Id

--8

SELECT 
	c.FirstName,
	c.Age,
	c.PhoneNumber
FROM Customers AS c
JOIN Countries AS s ON c.CountryId = s.Id
WHERE c.Age >= 21
AND (c.FirstName LIKE '%an%' OR c.PhoneNumber LIKE '%38')
AND s.Name <> 'Greece'
ORDER BY c.FirstName, c.Age DESC

--9

SELECT 
d.Name,
i.Name,
p.Name,
AVG(f.Rate)
FROM Distributors AS d
JOIN Ingredients AS i ON i.DistributorId = d.Id
JOIN ProductsIngredients AS ip ON ip.IngredientId = i.Id
JOIN Products AS p on ip.ProductId = p.Id
JOIN Feedbacks AS f ON p.Id = f.ProductId
GROUP BY d.name, i.Name, p.Name
HAVING AVG(f.Rate) BETWEEN 5 AND 8
ORDER BY d.Name, i.Name, p.Name


--10
SELECT CountryName, DistributorName
FROM (SELECT 
	c.Name AS CountryName,
	d.Name AS DistributorName,
	DENSE_RANK() OVER (PARTITION BY c.Name ORDER BY Count(i.Id) DESC) AS rank
	FROM Countries AS c
	LEFT JOIN Distributors AS d ON c.Id = d.CountryId
	LEFT JOIN Ingredients AS i ON d.Id = i.DistributorId 
	GROUP BY c.Name, d.Name) AS r
WHERE r.rank = 1 
ORDER BY CountryName, DistributorName


--11

CREATE VIEW v_UserWithCountries
AS 
SELECT 
	CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
	c.Age,
	c.Gender,
	s.Name AS CountryName
FROM Customers AS c
JOIN Countries AS s ON c.CountryId = s.Id

--12

CREATE TRIGGER tr_DeleteRelations
ON Products
INSTEAD OF DELETE
AS
BEGIN
	
	DELETE FROM ProductsIngredients 
	WHERE ProductId IN (SELECT i.Id
						FROM inserted AS i)

	DELETE FROM Feedbacks 
	WHERE ProductId IN (SELECT i.Id
						FROM inserted AS i)

	DELETE FROM Products 
	WHERE Id IN (SELECT i.Id
						FROM inserted AS i)

END
