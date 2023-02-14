CREATE DATABASE Zoo
USE Zoo


CREATE TABLE Owners
(
Id INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(50) NOT NULL,
PhoneNumber VARCHAR(15) NOT NULL,
[Address] VARCHAR(50) 
)

CREATE TABLE AnimalTypes
(
Id INT PRIMARY KEY IDENTITY,
AnimalType VARCHAR(30) NOT NULL
)

CREATE TABLE Cages
(
Id INT PRIMARY KEY IDENTITY,
AnimalTypeId INT FOREIGN KEY REFERENCES AnimalTypes(Id) NOT NULL
)

CREATE TABLE Animals
(
Id INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(30) NOT NULL,
BirthDate DATE NOT NULL,
OwnerId INT FOREIGN KEY REFERENCES Owners(Id),
AnimalTypeId INT FOREIGN KEY REFERENCES AnimalTypes(Id) NOT NULL
)

CREATE TABLE AnimalsCages
(
CageId INT FOREIGN KEY REFERENCES Cages(Id) NOT NULL,
AnimalId INT FOREIGN KEY REFERENCES Animals(Id) NOT NULL,
PRIMARY KEY(CageId, AnimalId)
)

CREATE TABLE VolunteersDepartments
(
Id INT PRIMARY KEY IDENTITY,
DepartmentName VARCHAR(30) NOT NULL
)

CREATE TABLE Volunteers
(
Id INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(50) NOT NULL,
PhoneNumber VARCHAR(15) NOT NULL,
[Address] VARCHAR(50),
AnimalId INT FOREIGN KEY REFERENCES Animals(Id),
DepartmentId INT FOREIGN KEY REFERENCES VolunteersDepartments NOT NULL
)


--2
INSERT INTO Volunteers
(Name, PhoneNumber, Address, AnimalId, DepartmentId)
VALUES
('Anita Kostova', '0896365412', 'Sofia, 5 Rosa str.',15,1),
('Dimitur Stoev','0877564223',null,42,4),
('Kalina Evtimova','0896321112','Silistra, 21 Breza str.',9,7),
('Stoyan Tomov','0898564100','Montana, 1 Bor str.',18,8),
('Boryana Mileva','0888112233',null,31,5)

INSERT INTO Animals
(Name, BirthDate, OwnerId, AnimalTypeId)
VALUES
('Giraffe','2018-09-21',21,1),
('Harpy Eagle','2015-04-17',15,3),
('Hamadryas Baboon','2017-11-02',null,1),
('Tuatara','2021-06-30',2,4)

--3
UPDATE Animals
SET OwnerId = (SELECT Id 
				FROM Owners 
				WHERE Name = 'Kaloqn Stoqnov')
WHERE OwnerId IS NULL

--4

DELETE 
FROM Volunteers 
WHERE DepartmentId = (SELECT Id 
FROM VolunteersDepartments
WHERE DepartmentName = 'Education program assistant')


DELETE  
FROM VolunteersDepartments
WHERE DepartmentName = 'Education program assistant'

--5
SELECT 
	Name,
	PhoneNumber,
	Address,
	AnimalId,
	DepartmentId
FROM Volunteers
ORDER BY Name, AnimalId, DepartmentId

--6

SELECT 
	a.Name,
	at.AnimalType,
	FORMAT(a.BirthDate,'dd.MM.yyy') AS BirthDate
FROM Animals AS a
LEFT JOIN AnimalTypes AS at ON a.AnimalTypeId = at.Id
ORDER BY a.Name 

--7
SELECT
	o.Name,
	COUNT(a.Id) AS CountOfAnimals
FROM Owners AS o
LEFT JOIN Animals AS a ON o.Id = a.OwnerId
GROUP BY o.Id, o.Name

ORDER BY CountOfAnimals DESC, o.Name

--8

SELECT
	CONCAT(o.Name,'-',a.Name) AS OwnersAnimals,
	o.PhoneNumber,
	c.Id AS CageId
FROM Owners AS o
JOIN Animals AS a ON a.OwnerId = o.Id
JOIN AnimalsCages AS ac on a.Id = ac.AnimalId
JOIN Cages AS c on c.Id = ac.CageId
JOIN AnimalTypes AS at ON a.AnimalTypeId = at.Id
WHERE at.AnimalType = 'Mammals'
ORDER BY o.Name, a.Name DESC



--9

SELECT
	v.Name,
	v.PhoneNumber,
	LTRIM(REPLACE(REPLACE(v.Address,'Sofia',''),',','')) AS Address
FROM Volunteers AS v
JOIN VolunteersDepartments AS vd ON v.DepartmentId = vd.Id
WHERE vd.DepartmentName = 'Education program assistant'
AND v.Address LIKE '%Sofia%'
ORDER BY v.Name

--10
SELECT
	a.Name,
	DATEPART(YEAR, a.BirthDate) AS BirthYear,
	at.AnimalType
FROM Animals AS a
JOIN AnimalTypes AS at ON at.Id = a.AnimalTypeId
WHERE DATEDIFF(YEAR, a.BirthDate, '2022-01-01')<5
AND a.OwnerId IS NULL
AND at.AnimalType <> 'Birds'
ORDER BY a.Name



--11

GO


CREATE FUNCTION udf_GetVolunteersCountFromADepartment (@VolunteersDepartment VARCHAR(30))
RETURNS INT
AS
BEGIN
	RETURN (SELECT
				COUNT(v.Id)
			FROM Volunteers AS v
			JOIN VolunteersDepartments AS vd ON v.DepartmentId = vd.Id
			WHERE vd.DepartmentName = @VolunteersDepartment
			GROUP BY vd.DepartmentName)
END

GO

--12

CREATE PROCEDURE usp_AnimalsWithOwnersOrNot @AnimalName VARCHAR(30)
AS
BEGIN
	SELECT 
		a.Name,
		ISNULL(o.Name,'For adoption')
	FROM Animals AS a
	LEFT JOIN Owners AS o ON a.OwnerId = o.Id
	WHERE a.Name = @AnimalName
END

GO

EXEC usp_AnimalsWithOwnersOrNot 'Brown bear'