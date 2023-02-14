--1

SELECT 
	p.provider as [Email Provider],
	COUNT (*) AS [Number Of Users]
FROM
(
SELECT SUBSTRING(Email, CHARINDEX('@', Email)+1,LEN(Email)) AS provider
FROM Users
) AS p
GROUP BY p.provider
ORDER BY 2 DESC, 1

--2

SELECT 
	g.Name AS [Game],
	gt.Name AS [Game Type],
	u.Username,
	ug.Level,
	ug.Cash,
	c.Name
FROM UsersGames AS ug
JOIN Games AS g
ON ug.GameId = g.Id
JOIN Users AS u
ON u.Id = ug.UserId
JOIN GameTypes AS gt
ON gt.Id = g.GameTypeId
JOIN Characters AS c
ON c.Id = ug.CharacterId
ORDER BY ug.Level DESC, u.Username, g.Name

--3

SELECT
	u.Username,
	g.Name AS [Game],
	COUNT(i.Price) AS [Items Count],
	SUM(i.Price) AS [Items Price]

FROM UserGameItems AS ugi
JOIN UsersGames AS ug
ON ugi.UserGameId = ug.Id
JOIN Users AS u
ON u.Id = ug.UserId
JOIN Items AS i
ON i.Id = ugi.ItemId
JOIN Games AS g
ON g.Id = ug.GameId
GROUP BY u.Username, g.Name
HAVING COUNT(i.Price) >= 10
ORDER BY COUNT(i.Price) DESC, SUM(i.Price) DESC, u.Username

--4
GO




SELECT 
	u.Username,
	g.Name AS Game,
	MAX(c.Name) AS [Character],
	SUM(its.Strength) + MAX(cs.Strength) +	MAX(gts.Strength) AS Strength,
	SUM(its.Defence) +	MAX(cs.Defence) +	MAX(gts.Defence)AS Defence,
	SUM(its.Speed) +	MAX(cs.Speed) +		MAX(gts.Speed) AS Speed,
	SUM(its.Mind) +		MAX(cs.Mind) +		MAX(gts.Mind) AS Mind,
	SUM(its.Luck) +		MAX(cs.Luck) +		MAX(gts.Luck) AS Luck
	
FROM Users AS u
 JOIN UsersGames AS ug		ON ug.UserId = u.Id 
 JOIN UserGameItems AS ugi	ON ugi.UserGameId = ug.Id
 JOIN Items AS i				ON i.Id = ugi.ItemId
 JOIN Games AS g				ON g.Id = ug.GameId
 JOIN Characters AS c		ON ug.CharacterId = c.Id
 JOIN GameTypes AS gt		ON g.GameTypeId = gt.Id
 JOIN [Statistics] AS its	ON i.StatisticId = its.Id
 JOIN [Statistics] AS gts	ON gt.BonusStatsId = gts.Id
 JOIN [Statistics] AS cs		ON c.StatisticId = cs.Id
GROUP BY u.Username, g.Name
ORDER BY Strength DESC, Defence DESC, Speed DESC, Mind DESC, Luck DESC

--5

SELECT 
	i.Name, 
	i.Price,
	i.MinLevel,
	s.Strength,
	s.Defence,
	s.Speed,
	s.Luck,
	s.Mind
FROM Items AS i
JOIN [Statistics] AS s
ON i.StatisticId = s.Id
WHERE s.Mind > (SELECT
					AVG(s.Mind)
				FROM Items AS i
				JOIN [Statistics] AS s
				ON i.StatisticId = s.Id)
AND	s.Luck > (SELECT
					AVG(s.luck)
				FROM Items AS i
				JOIN [Statistics] AS s
				ON i.StatisticId = s.Id)
AND s.Speed > (SELECT
					AVG(s.Speed)
				FROM Items AS i
				JOIN [Statistics] AS s
				ON i.StatisticId = s.Id)


--6

SELECT 
	i.Name,
	i.Price,
	i.MinLevel,
	gt.Name
FROM Items AS i
LEFT JOIN GameTypeForbiddenItems AS gfi
ON i.Id = gfi.ItemId
LEFT JOIN GameTypes AS gt
ON gt.Id = gfi.GameTypeId
ORDER BY gt.Name DESC, i.Name


--7

BEGIN TRANSACTION
DECLARE @total DECIMAL(19,4)
SET @total = (SELECT
			Sum(Price)
			FROM Items
			WHERE Name IN ('Blackguard', 'Bottomless Potion of Amplification', 'Eye of Etlich (Diablo III)', 'Gem of Efficacious Toxin', 'Golden Gorget of Leoric', 'Hellfire Amulet')) 
	

INSERT INTO UserGameItems 
(ItemId, UserGameId)
SELECT
	ids.Id,
	uid.Id
FROM (SELECT Id 
		FROM Items
		WHERE Name IN ('Blackguard', 'Bottomless Potion of Amplification', 'Eye of Etlich (Diablo III)', 'Gem of Efficacious Toxin', 'Golden Gorget of Leoric', 'Hellfire Amulet')) AS ids
		CROSS JOIN (SELECT ug.Id
					FROM UsersGames AS ug
					JOIN Games AS g
					ON g.Id = ug.GameId
					JOIN Users AS u
					ON u.Id = ug.UserId
					WHERE u.Username = 'Alex' AND g.Name = 'Edinburgh') AS uid

UPDATE UsersGames
SET Cash = Cash - @total
WHERE Id = (SELECT ug.Id
					FROM UsersGames AS ug
					JOIN Games AS g
					ON g.Id = ug.GameId
					JOIN Users AS u
					ON u.Id = ug.UserId
					WHERE u.Username = 'Alex' AND g.Name = 'Edinburgh')

SELECT 
	u.Username,
	g.Name,
	ug.Cash,
	i.Name
FROM UsersGames AS ug
JOIN Games AS g
ON ug.GameId = g.Id
JOIN Users AS u
ON u.Id = ug.UserId
JOIN UserGameItems AS ugi
ON ugi.UserGameId = ug.Id
JOIN Items AS i
ON i.Id = ugi.ItemId
WHERE g.Name = 'Edinburgh'

COMMIT


--8
SELECT 
	p.PeakName,
	m.MountainRange,
	p.Elevation
FROM Peaks AS p
JOIN Mountains AS m
ON p.MountainId = m.Id
ORDER BY p.Elevation DESC, p.PeakName

--9


SELECT 
	p.PeakName,
	m.MountainRange,
	c.CountryName,
	con.ContinentName
FROM Peaks AS p
JOIN Mountains AS m
ON p.MountainId = m.Id
JOIN MountainsCountries AS mc
ON m.Id = mc.MountainId
JOIN Countries AS c
ON c.CountryCode = mc.CountryCode
JOIN Continents AS con
ON con.ContinentCode = c.ContinentCode
ORDER BY p.PeakName, c.CountryName

--10
SELECT 
	c.CountryName,
	con.ContinentName,
	ISNULL(COUNT(r.Length) ,'0') AS RiversCount,
	ISNULL(SUM(r.Length) ,'0') AS TotalLength
FROM Countries AS c
LEFT JOIN CountriesRivers AS cr ON c.CountryCode = cr.CountryCode
LEFT JOIN Rivers AS r ON r.Id = cr.RiverId
LEFT JOIN Continents AS con  ON con.ContinentCode = c.ContinentCode
GROUP BY c.CountryName, c.CountryCode, con.ContinentName
ORDER BY RiversCount DESC, TotalLength DESC, c.CountryName

--11

SELECT 
	r.CurrencyCode,
	r.Description,
	COUNT(c.CurrencyCode) AS NumberOfCountries
FROM Currencies AS r
LEFT JOIN Countries AS c
ON c.CurrencyCode = r.CurrencyCode
GROUP BY r.CurrencyCode, r.Description
ORDER BY NumberOfCountries DESC, r.Description

--12

SELECT
	con.ContinentName,
	SUM(c.AreaInSqKm) AS CountriesArea,
	SUM(CONVERT(BIGINT,c.Population)) AS CountriesPopulation
FROM Continents AS con
LEFT JOIN Countries AS c ON c.ContinentCode = con.ContinentCode
GROUP BY con.ContinentName

ORDER BY CountriesPopulation DESC

--13

CREATE TABLE Monasteries 
(
Id INT PRIMARY KEY IDENTITY,
Name NVARCHAR(50) UNIQUE,
CountryCode CHAR(2) FOREIGN KEY REFERENCES Countries(CountryCode))

INSERT INTO Monasteries(Name, CountryCode) VALUES
('Rila Monastery “St. Ivan of Rila”', 'BG'), 
('Bachkovo Monastery “Virgin Mary”', 'BG'),
('Troyan Monastery “Holy Mother''s Assumption”', 'BG'),
('Kopan Monastery', 'NP'),
('Thrangu Tashi Yangtse Monastery', 'NP'),
('Shechen Tennyi Dargyeling Monastery', 'NP'),
('Benchen Monastery', 'NP'),
('Southern Shaolin Monastery', 'CN'),
('Dabei Monastery', 'CN'),
('Wa Sau Toi', 'CN'),
('Lhunshigyia Monastery', 'CN'),
('Rakya Monastery', 'CN'),
('Monasteries of Meteora', 'GR'),
('The Holy Monastery of Stavronikita', 'GR'),
('Taung Kalat Monastery', 'MM'),
('Pa-Auk Forest Monastery', 'MM'),
('Taktsang Palphug Monastery', 'BT'),
('S?mela Monastery', 'TR')


--ALTER TABLE Countries
--ADD IsDeleted BIT

--UPDATE Countries
--SET IsDeleted = 0


UPDATE Countries
SET IsDeleted = 1
WHERE CountryCode IN (
						SELECT 
							c.CountryCode
						FROM Countries AS c
						LEFT JOIN CountriesRivers AS cr ON c.CountryCode = cr.CountryCode
						LEFT JOIN Rivers AS r ON r.Id = cr.RiverId
						GROUP BY c.CountryCode
						HAVING COUNT(r.Id) > 3
						)

SELECT
	m.Name AS Monastery,
	c.CountryName AS Country
FROM Monasteries AS m
JOIN Countries AS c ON m.CountryCode = c.CountryCode
WHERE c.IsDeleted = 0
ORDER BY m.Name


--14

UPDATE Countries
SET CountryName = 'Burma'
WHERE CountryName  = 'Myanmar'

INSERT INTO Monasteries
(Name, CountryCode)
VALUES
('Hanga Abbey',(SELECT 
				CountryCode
				FROM Countries
				WHERE CountryName = 'Tanzania'))

INSERT INTO Monasteries
(Name, CountryCode)
VALUES
('Myin-Tin-Daik',(SELECT 
				CountryCode
				FROM Countries
				WHERE CountryName = 'Myanmar'))



SELECT 
	ContinentName,
	CountryName,
	COUNT(m.Name) AS MonasteriesCount
FROM Continents AS con
JOIN Countries AS c ON c.ContinentCode = con.ContinentCode
LEFT JOIN Monasteries AS m ON m.CountryCode = c.CountryCode
WHERE c.IsDeleted = 0
GROUP BY con.ContinentName, c.CountryName
ORDER BY MonasteriesCount DESC, CountryName

