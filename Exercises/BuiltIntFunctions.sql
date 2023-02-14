--Built-in Functions
--1
SELECT 
	FirstName, 
	LastName 
FROM Employees
WHERE FirstName LIKE 'SA%'


--2
SELECT FirstName,LastName FROM Employees
WHERE LastName LIKE '%ei%'

--3

SELECT FirstName FROM Employees
WHERE DepartmentID IN (3,10) 
AND	  DATEPART(year, HireDate) BETWEEN '1995' and '2005'

--4
SELECT FirstName, LastName FROM Employees
WHERE JobTitle NOT LIKE '%engineer%'

--5 
SELECT Name FROM Towns
WHERE LEN(Name) IN (5,6)
ORDER BY Name

--6
SELECT TownID, Name FROM Towns
WHERE LEFT(Name, 1) IN ('M','K','B','E')
ORDER BY Name

--7

SELECT TownID, Name FROM Towns
WHERE LEFT(Name, 1) NOT IN ('R','B','D')
ORDER BY Name

--8
CREATE VIEW [V_EmployeesHiredAfter2000] AS
SELECT FirstName, LastName FROM Employees
WHERE DATEPART(YEAR, HireDate) > 2000

--9
SELECT FirstName,LastName FROM Employees
WHERE LEN(LastName) = 5

--10, 11
SELECT * FROM
(SELECT
EmployeeID, 
FirstName, 
LastName, 
Salary, 
DENSE_RANK() OVER (PARTITION BY Salary ORDER BY (EmployeeID)) AS Rank
FROM Employees) AS e 
WHERE Salary BETWEEN 10000 AND 50000 
AND e.[Rank] = 2 
ORDER BY Salary DESC

--12
SELECT CountryName AS 'Country Name', IsoCode AS 'ISO Code' FROM Countries
WHERE LOWER(CountryName) LIKE '%a%a%a%'
ORDER BY IsoCode

--13
SELECT 
p.PeakName, 
r.RiverName,
CONCAT(LOWER(LEFT(p.PeakName,LEN(p.PeakName)-1)),LOWER(r.RiverName)) AS Mix
FROM Peaks AS p
JOIN Rivers AS r ON (RIGHT(p.PeakName,1) = LEFT(r.RiverName,1))
ORDER BY Mix

--14
SELECT TOP(50)Name, FORMAT(Start,'yyyy-MM-dd') AS Start FROM Games
WHERE DATEPART(YEAR, Start) IN (2011,2012)
ORDER BY Start, Name 

--15
SELECT Username, 
RIGHT(Email, LEN(Email) - CHARINDEX('@',Email)) 
AS 'Email Provider' 
FROM Users
ORDER BY 'Email Provider', Username

--16
SELECT Username, IpAddress FROM Users
WHERE IpAddress LIKE '___.1%.%.___'
ORDER BY Username

--17
SELECT 
Name, 
CASE
    WHEN DATEPART(HOUR, Start) < 12 THEN 'Morning'
    WHEN DATEPART(HOUR, Start) >= 18 THEN 'Evening'
    ELSE 'Afternoon'
END AS 'Part of the Day',
CASE
    WHEN Duration <=3 THEN 'Extra Short'
    WHEN Duration > 6 THEN 'Long'
	WHEN Duration IS NULL THEN 'Extra Long'
    ELSE 'Short'
END AS 'Duration'
FROM Games
ORDER BY 1,3,2

--18

SELECT 
ProductName, 
OrderDate,
DATEADD(DAY,3,OrderDate) AS [Pay Due],
DATEADD(MONTH,1,OrderDate) AS [Deliver Due]
FROM Orders

--19

CREATE TABLE People
(
Id INT IDENTITY(1,1) PRIMARY KEY,
Name VARCHAR(50) NOT NULL,
Birthdate DATETIME2 NOT NULL
)

INSERT INTO People
(Name, Birthdate)
VALUES
('Ivan','05-02-1990'),
('Joor','05-02-1989'),
('Ian','12-04-2001'),
('Ivo','02-20-1997')

SELECT 
Name,
DATEDIFF(YEAR, Birthdate, GETDATE()) AS 'Age in Years'
FROM 
People