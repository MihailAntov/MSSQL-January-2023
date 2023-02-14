--1

SELECT TOP(5)
	EmployeeID,
	JobTitle,
	e.AddressID,
	a.AddressText
FROM Employees AS e
JOIN Addresses AS a
ON (e.AddressID = a.AddressID)
ORDER BY a.AddressID

--2
SELECT TOP (50)
	FirstName,
	LastName,
	t.Name,
	a.AddressText	
FROM Employees AS e
JOIN Addresses AS a
ON (e.AddressID = a.AddressID)
JOIN Towns AS t
ON (a.TownID = t.TownID)
ORDER BY e.FirstName, e.LastName

--3
SELECT
	EmployeeID,
	FirstName,
	LastName,
	d.Name AS DepartmentName
FROM Employees AS e
JOIN Departments AS d
ON(e.DepartmentID = d.DepartmentID)
WHERE(d.Name = 'Sales')
ORDER BY EmployeeID

--4
SELECT TOP(5)
	EmployeeID,
	FirstName,
	Salary,
	d.Name

FROM Employees AS e
JOIN Departments AS d
ON(e.DepartmentID = d.DepartmentID)
WHERE (Salary > 15000)
ORDER BY (e.DepartmentID)

--5
SELECT TOP(3)
	e.EmployeeID,
	FirstName
FROM Employees AS e
LEFT JOIN EmployeesProjects AS ep
ON(e.EmployeeID = ep.EmployeeID)
WHERE ep.ProjectID IS NULL
ORDER BY e.EmployeeID

--6

SELECT 
	FirstName,
	LastName,
	HireDate,
	d.Name
FROM Employees AS e
JOIN Departments AS d
ON(e.DepartmentID = d.DepartmentID)
WHERE HireDate > '1999-01-01'
AND d.Name IN ('Sales','Finance')
ORDER BY HireDate

--7

SELECT TOP(5)
	e.EmployeeID,
	FirstName,
	p.Name
FROM Employees AS e
JOIN EmployeesProjects AS ep
ON (e.EmployeeID = ep.EmployeeID)
JOIN Projects AS p
ON(ep.ProjectID = p.ProjectID)
WHERE p.StartDate > '2002-08-13' AND p.EndDate IS NULL
ORDER BY EmployeeID

--8

SELECT
	e.EmployeeID,
	FirstName,
	CASE
		WHEN DATEPART(YEAR, p.StartDate) >= 2005 THEN NULL
		ELSE p.Name
	END
FROM Employees AS e
JOIN EmployeesProjects AS ep
ON(e.EmployeeID = ep.EmployeeID)
JOIN Projects AS p
ON (ep.ProjectID = p.ProjectID)
WHERE e.EmployeeID = 24

--9

SELECT 
	e.EmployeeID,
	e.FirstName,
	e.ManagerID,
	m.FirstName
	
FROM Employees AS e
JOIN Employees AS m
ON (e.ManagerID = m.EmployeeID)
WHERE e.ManagerID IN (3,7)
ORDER BY e.EmployeeID

--10

SELECT TOP(50)
	e.EmployeeID,
	CONCAT(e.FirstName,' ', e.LastName) AS EmployeeName,
	CONCAT(m.FirstName,' ', m.LastName) AS ManagerName,
	d.Name AS DepartmentName
FROM Employees AS e
JOIN Employees AS m
ON (e.ManagerID = m.EmployeeID)
JOIN Departments AS d
ON (e.DepartmentID = d.DepartmentID)
ORDER BY e.EmployeeID

--11

SELECT TOP(1)
	AVG(Salary) AS MinAverageSalary
FROM Employees
GROUP BY (DepartmentID)
ORDER BY 1 

-- GEOGRAPHY

--12
SELECT 
	c.CountryCode,
	m.MountainRange,
	p.PeakName,
	p.Elevation
FROM Mountains AS m
JOIN MountainsCountries AS mc
ON (m.Id = mc.MountainId)
JOIN Countries AS c
ON(mc.CountryCode = c.CountryCode)
JOIN Peaks AS p
ON(p.MountainId = m.Id)
WHERE c.CountryName = 'Bulgaria'
AND p.Elevation > 2835
ORDER BY p.Elevation DESC

--13

SELECT 
	c.CountryCode,
	COUNT(m.MountainRange) AS MountainRanges
FROM Mountains AS m
JOIN MountainsCountries AS mc
ON(m.Id = mc.MountainId)
JOIN Countries AS c
ON(c.CountryCode = mc.CountryCode)
WHERE c.CountryName IN ('United States','Russia','Bulgaria')
GROUP BY (c.CountryCode)

--14

SELECT TOP(5)
	c.CountryName,
	r.RiverName
FROM Countries AS c
LEFT JOIN CountriesRivers AS cr
ON (c.CountryCode = cr.CountryCode)
LEFT JOIN Rivers AS r
ON (cr.RiverId = r.Id)
LEFT JOIN Continents AS con
ON(c.ContinentCode = con.ContinentCode)
WHERE con.ContinentName = 'Africa'
ORDER BY c.CountryName

--15


SELECT 
	OrderedCountries.ContinentCode,
	OrderedCountries.CurrencyCode,
	OrderedCountries.CurrencyUsage
FROM Continents AS con
JOIN 
	(
		SELECT 
			COUNT(CurrencyCode) AS CurrencyUsage,
			DENSE_RANK() OVER (PARTITION BY ContinentCode
								ORDER BY COUNT(CurrencyCode) DESC) 
			AS Rank,
			c.ContinentCode,
			c.CurrencyCode

		FROM Countries AS c
		GROUP BY c.ContinentCode, c.CurrencyCode
		HAVING COUNT(CurrencyCode) > 1
	) AS OrderedCountries
	ON (con.ContinentCode = OrderedCountries.ContinentCode)
	WHERE OrderedCountries.Rank = 1



--16
SELECT 
	COUNT(c.CountryCode)
FROM Countries AS c
LEFT JOIN MountainsCountries AS mc
ON(c.CountryCode = mc.CountryCode)
LEFT JOIN Mountains AS m
ON(m.Id = mc.MountainId)
WHERE MountainId IS NULL

--17

SELECT TOP(5)
	c.CountryName,
	MAX(p.Elevation) AS HighestPeakElevation,
	MAX(r.Length) AS LongestRiverLength
FROM Countries AS c
LEFT OUTER JOIN MountainsCountries AS mc
ON(c.CountryCode = mc.CountryCode)
LEFT OUTER JOIN Mountains AS m
ON(m.Id = mc.MountainId)
LEFT OUTER JOIN 
Peaks AS p
ON(p.MountainId = m.Id)
LEFT OUTER JOIN CountriesRivers AS cr
ON(c.CountryCode = cr.CountryCode)
LEFT OUTER JOIN Rivers AS r
ON(r.Id = cr.RiverId)
GROUP BY c.CountryName

ORDER BY HighestPeakElevation DESC, LongestRiverLength DESC, c.CountryName

--18

WITH cte_rankedPeaks (Country, Peakname, Elevation, Mountain, RANK)
AS 
(
SELECT
	c.CountryName AS Country,
	ISNULL(p.PeakName,'(no highest peak)') AS 'Highest Peak Name',
	ISNULL(p.Elevation,0) AS 'Highest Peak Elevation',
	ISNULL(m.MountainRange, '(no mountain)') AS 'Mountain',
	RANK() OVER (PARTITION BY c.CountryName ORDER BY p.Elevation DESC) AS Rank
FROM Countries AS c
LEFT JOIN MountainsCountries AS mc
ON c.CountryCode = mc.CountryCode
LEFT JOIN Mountains AS m
ON m.Id = mc.MountainId
LEFT JOIN Peaks AS p
ON p.MountainId = m.Id

GROUP BY c.CountryName, p.PeakName, m.MountainRange, p.Elevation

)

SELECT 
	Country, Peakname, Elevation, Mountain
FROM cte_rankedPeaks
WHERE Rank = 1
ORDER BY Country, Peakname





