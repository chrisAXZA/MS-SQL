USE [SoftUni]

-- Join Demo

SELECT *
FROM [Employees] AS [E]
    INNER JOIN [EmployeesProjects] AS [EP]
    ON [E].[EmployeeID] = [EP].[EmployeeID]

SELECT *
FROM [Employees] AS [E]
    LEFT OUTER JOIN [EmployeesProjects] AS [EP]
    ON [E].[EmployeeID] = [EP].[EmployeeID]

SELECT *
FROM [Projects] AS [P]
    LEFT OUTER JOIN [EmployeesProjects] AS [EP]
    ON [P].[ProjectID] = [EP].[ProjectID]

-- 2.
SELECT TOP(5)
    [E].[EmployeeID],
    [E].[JobTitle],
    [E].[AddressID],
    [A].[AddressText]
FROM [Employees] AS [E]
    INNER JOIN [Addresses] AS [A]
    ON [E].[AddressID] = [A].[AddressID]
ORDER BY [A].[AddressID] ASC

-- 3.
SELECT TOP(50)
    [E].[FirstName],
    [E].[LastName],
    [T].[Name] AS [Town],
    [A].[AddressText]
FROM [Addresses] AS [A]
    INNER JOIN [Towns] AS [T]
    ON [T].[TownID] = [A].[TownID]
    INNER JOIN [Employees] AS [E]
    ON [E].[AddressID] = [A].[AddressID]
ORDER BY [E].[FirstName] ASC, [E].[LastName] ASC

-- 6. 
SELECT TOP(3)
    [E].[EmployeeID],
    [E].[FirstName]
FROM [Employees] AS [E]
    LEFT OUTER JOIN [EmployeesProjects] AS [EP]
    ON [EP].[EmployeeID] = [E].[EmployeeID]
WHERE [EP].[ProjectID] IS NULL
ORDER BY [E].[EmployeeID]
-- WHERE [EP].[EmployeeID] IS NULL

SELECT TOP(3)
    [E].[EmployeeID],
    [EP].[EmployeeID],
    [E].[FirstName]
FROM [EmployeesProjects] AS [EP]
    RIGHT OUTER JOIN [Employees] AS [E]
    ON [E].[EmployeeID] = [EP].[EmployeeID]
WHERE [EP].[ProjectID] IS NULL
ORDER BY [E].[EmployeeID]

-- 8.
SELECT TOP(5)
    [E].[EmployeeID],
    [E].[FirstName],
    [P].[Name] AS [ProjectName]
FROM [Employees] AS [E]
    INNER JOIN [EmployeesProjects] AS [EP]
    ON [EP].[EmployeeID] = [E].[EmployeeID]
    INNER JOIN [Projects] AS [P]
    ON [P].[ProjectID] = [EP].[ProjectID]
WHERE [P].[StartDate] > '08.13.2002'
    AND [P].[EndDate] IS  NULL
ORDER BY [E].[EmployeeID] ASC

-- Alternative with left join and additional where-filter
SELECT
    [E].[EmployeeID],
    [E].[FirstName],
    [P].[Name] AS [ProjectName]
FROM [Employees] AS [E]
    LEFT OUTER JOIN [EmployeesProjects] AS [EP]
    ON [EP].[EmployeeID] = [E].[EmployeeID]
    INNER JOIN [Projects] AS [P]
    ON [P].[ProjectID] = [EP].[ProjectID]
WHERE [EP].[EmployeeID] IS NOT NULL
    AND [P].[StartDate] > '08.13.2002'
    AND [P].[EndDate] IS  NULL
ORDER BY [E].[EmployeeID] ASC

-- 9.
SELECT
    [E].[EmployeeID],
    [E].[FirstName],
    CASE 
        WHEN DATEPART(YEAR, [P].[StartDate]) >= 2005 THEN NULL
        ELSE [P].[Name]
    END AS [ProjectName]
FROM [Employees] AS [E]
    INNER JOIN [EmployeesProjects] AS [EP]
    ON [EP].[EmployeeID] = [E].[EmployeeID]
    INNER JOIN [Projects] AS [P]
    ON [P].[ProjectID] = [EP].[ProjectID]
WHERE [E].[EmployeeID] = 24

SELECT
    [EP].[EmployeeID],
    [E].[FirstName],
    CASE
     WHEN YEAR([P].[StartDate]) >= 2005 THEN NULL
     ELSE [P].[Name]
     END AS [ProjectName]
FROM [EmployeesProjects] AS [EP]
    JOIN [Employees] AS [E]
    ON [E].[EmployeeID] = [EP].[EmployeeID]
    JOIN [Projects] AS [P]
    ON [P].[ProjectID] = [EP].[ProjectID]
WHERE [EP].[EmployeeID] = 24

-- 11.

-- IMOPORTANT DIFFERENCE, CONCAT creates whitespace however
-- concatinating individual string will produce NULL in missing 
-- column element
SELECT TOP(50)
    [E1].[EmployeeID],
    CONCAT([E1].[FirstName], ' ', [E1].[LastName]) AS [EmployeeName],
    CONCAT([E2].[FirstName], ' ', [E2].[LastName]) AS [ManagerName],
    [D].[Name] AS [DepartmentName]
FROM [Employees] AS [E1]
    LEFT OUTER JOIN [Employees] AS [E2]
    ON [E2].[EmployeeID] = [E1].[ManagerID]
    INNER JOIN [Departments] AS [D]
    ON [D].[DepartmentID] = [E1].[DepartmentID]
ORDER BY [E1].[EmployeeID]

SELECT TOP(50)
    [E].[EmployeeID],
    ([E].[FirstName] + ' ' + [E].[LastName]) AS [EmployeeName],
    ([E2].[FirstName] + ' ' + [E2].[LastName]) AS [ManagerName],
    [E].[ManagerID],
    [E2].[EmployeeID],
    [D].[Name] AS [DepartmentName]
FROM [Employees] AS [E]
    LEFT OUTER JOIN [Employees] AS [E2]
    ON [E2].[EmployeeID] = [E].[ManagerID]
    LEFT OUTER JOIN [Departments] AS [D]
    ON [D].[DepartmentID] = [E].[DepartmentID]
-- ORDER BY [E].[EmployeeID]
WHERE [E].[EmployeeID] = 109

--TEST
SELECT *
FROM [Employees] AS [E]
    INNER JOIN [Employees] AS [E2]
    ON [E2].[ManagerID] = [E].[EmployeeID]

SELECT *
FROM [Employees] AS [E]
    INNER JOIN [Employees] AS [E2]
    ON [E2].[EmployeeID] = [E].[ManagerID]

-- 12.
SELECT [DepartmentID]
FROM [Employees]
GROUP BY [DepartmentID]

SELECT
    [DepartmentID],
    [FirstName],
    COUNT(*) AS [Count]
FROM [Employees]
GROUP BY [DepartmentID], [FirstName]
ORDER BY [DepartmentID]

SELECT MIN([AverageSalary]) AS [MinAverageSalary]
FROM (SELECT
        [DepartmentID],
        AVG([Salary]) AS [AverageSalary]
    FROM [Employees]
    GROUP BY [DepartmentID]
) AS [AverageSalaryQuery]

SELECT TOP(1)
    AVG([Salary]) AS [MinAverageSalary]
FROM [Employees]
GROUP BY [DepartmentID]
ORDER BY AVG([Salary]) ASC

-- Demo 12.
SELECT
    [E].[DepartmentID],
    COUNT(*),
    AVG([Salary]) AS [AvgSalary],
    SUM([Salary]) AS [TotalSalary]
FROM [Employees] AS [E]
GROUP BY [E].[DepartmentID]
ORDER BY [AvgSalary] ASC

SELECT *,
    (SELECT SUM([E].[Salary])
    FROM [Employees] AS [E]
    WHERE [E].[DepartmentID] = [D].[DepartmentID])
AS [Sum],
    (SELECT
        COUNT(*) AS [EmployeeCount]
    FROM [Employees] AS [E]
    WHERE [E].[DepartmentID] = [D].[DepartmentID]) AS [Count]
FROM [Departments] AS [D]
WHERE (SELECT COUNT(*)
FROM [Employees]
WHERE [Employees].[DepartmentID] = [D].[DepartmentID]) > 8

SELECT *,
    (SELECT
        COUNT(*) AS [EmployeeCount]
    FROM [Employees] AS [E]
    WHERE [E].[DepartmentID] = [D].[DepartmentID])
AS [Temp]
FROM [Departments] AS [D]
ORDER BY [Temp] ASC

SELECT TOP(1)
    *,
    (SELECT AVG([Salary])
    FROM [Employees]
    WHERE [Employees].[DepartmentID] = [Departments].[DepartmentID]) AS [AverageSalary]
FROM [Departments]
ORDER BY [AverageSalary] ASC

SELECT MIN([AvgSalary])
FROM
    (SELECT
        COUNT(*) AS [DepartmentCount],
        AVG([Salary]) AS [AvgSalary]
    FROM [Employees]
    GROUP BY [DepartmentID]) AS [DepOverview]

-- 13.
USE [Geography]

SELECT
    [C].[CountryCode],
    [M].[MountainRange],
    [P].[PeakName],
    [P].[Elevation],
    [M].[Id],
    [MC].[MountainId],
    [P].[MountainId]
-- Id and MountainId always the same
FROM [MountainsCountries] AS [MC]
    INNER JOIN [Peaks] AS [P]
    ON [P].[MountainId] = [MC].[MountainId]
    INNER JOIN [Mountains] AS [M]
    ON [M].[Id] = [MC].[MountainId]
    INNER JOIN [Countries] AS [C]
    ON [C].[CountryCode] = [MC].[CountryCode]
WHERE [C].[CountryCode] = 'BG'
    AND [P].[Elevation] > 2835
ORDER BY [P].[Elevation] DESC

SELECT
    [C].[CountryCode],
    [M].[MountainRange],
    [P].[PeakName],
    [P].[Elevation]
FROM [Countries] AS [C]
    INNER JOIN [MountainsCountries] AS [MC]
    ON [MC].[CountryCode] = [C].[CountryCode]
    INNER JOIN [Mountains] AS [M]
    ON [M].[Id] = [MC].[MountainId]
    INNER JOIN [Peaks] AS [P]
    -- ON [P].[MountainId] = [M].[Id]
    ON [P].[MountainId] = [MC].[MountainId]
-- WHERE [C].[CountryCode] = 'BG'
WHERE [C].[CountryName] = 'Bulgaria'
    AND [P].[Elevation] > 2835
ORDER BY [P].[Elevation]

-- 14.
SELECT [CountryCode],
    COUNT([MountainId]) AS [MountainRanges]
FROM [MountainsCountries]
WHERE [CountryCode] IN ('US', 'RU', 'BG')
GROUP BY [CountryCode]

-- Having Demo
SELECT [CountryCode],
    COUNT([MountainId]) AS [MountainRanges]
FROM [MountainsCountries]
-- WHERE [MountainRanges] > 2
-- Where is called before Group By and aggregated column can not be used
GROUP BY [CountryCode]
HAVING COUNT([MountainId]) > 1
-- Having allows filtering of Group By function

-- Having is used for filtering/validating aggregate functions created
-- by group by

SELECT
    [CountryCode],
    (SELECT COUNT(*)
    FROM [MountainsCountries] AS [MC2]
    WHERE [MC2].[CountryCode] = [MC].[CountryCode]
    GROUP BY [MC2].[CountryCode]) AS [MountainRanges]
FROM [MountainsCountries] AS [MC]
WHERE [MC].[CountryCode] IN
(SELECT [CountryCode]
FROM [Countries]
WHERE [CountryName] IN ('United States', 'Russia', 'Bulgaria'))
GROUP BY [CountryCode]

-- 16.
SELECT
    [ContinentCode],
    [CurrencyCode],
    COUNT(*) AS [CurrencyCount],
    DENSE_RANK() OVER (PARTITION BY [ContinentCode] ORDER BY COUNT(*) DESC)
-- Counts how any times this combination exists, in this case
FROM [Countries] AS [C1]
GROUP BY [ContinentCode], [CurrencyCode]

SELECT
    [ContinentCode],
    [CurrencyCode],
    [CurrencyCount] AS [CurrencyUsage]
FROM (SELECT
        [ContinentCode],
        [CurrencyCode],
        [CurrencyCount],
        DENSE_RANK() OVER 
    (PARTITION BY [ContinentCode] ORDER BY [CurrencyCount] DESC) AS [CurrencyRank]
    FROM
        (SELECT
            [ContinentCode],
            [CurrencyCode],
            COUNT(*) AS [CurrencyCount]
        FROM [Countries]
        GROUP BY [ContinentCode], [CurrencyCode]
    ) AS [CurrencyCountQuery]
    WHERE [CurrencyCount] > 1
    ) AS [CurrencyFinal]
WHERE [CurrencyRank] = 1
ORDER BY [ContinentCode]

-- 18.
SELECT TOP(5)
    [CountryName],
    MAX([P].[Elevation]) AS [HighestPeakElevation],
    MAX([R].[Length]) AS [LongestRiverLength]
FROM [Countries] AS [C]
    LEFT OUTER JOIN [CountriesRivers] AS [CR]
    ON [CR].[CountryCode] = [C].[CountryCode]
    LEFT OUTER JOIN [Rivers] AS [R]
    ON [R].[Id] = [CR].[RiverId]
    LEFT OUTER JOIN [MountainsCountries] AS [MC]
    ON [MC].[CountryCode] = [C].[CountryCode]
    LEFT OUTER JOIN [Mountains] AS [M]
    ON [M].[Id] = [MC].[MountainId]
    LEFT OUTER JOIN [Peaks] AS [P]
    ON [P].[MountainId] = [M].[Id]
GROUP BY [C].[CountryName]
ORDER BY [HighestPeakElevation] DESC, [LongestRiverLength] DESC, [CountryName] ASC


SELECT TOP(5)
    [CountryName],
    MAX([P].[Elevation]) AS [HighestPeakElevation],
    MAX([R].[Length]) AS [LongestRiverLength]
FROM [Countries] AS [C]
    LEFT OUTER JOIN [CountriesRivers] AS [CR]
    ON [CR].[CountryCode] = [C].[CountryCode]
    LEFT OUTER JOIN [Rivers] AS [R]
    ON [R].[Id] = [CR].[RiverId]
    LEFT OUTER JOIN [MountainsCountries] AS [MC]
    ON [MC].[CountryCode] = [C].[CountryCode]
    LEFT OUTER JOIN [Peaks] AS [P]
    ON [P].[MountainId] = [MC].[MountainId]
GROUP BY [C].[CountryName]
ORDER BY [HighestPeakElevation] DESC, [LongestRiverLength] DESC, [CountryName] ASC
-- ORDER BY MAX([P].[Elevation]) DESC, MAX([R].[Length]) DESC, [CountryName] ASC

-- 19.
SELECT TOP(5)
    -- [Country],
    -- [PeakName],
    -- [Elevation],
    -- [MountainRange] AS [Mountain]
    [Country],
    CASE
        WHEN [PeakName] IS NULL THEN '(no highest peak)'
        ELSE [PeakName]
    END AS [Highest Peak Name],
    CASE
        WHEN [Elevation] IS NULL THEN 0
        ELSE [Elevation]
    END AS [Highest Peak Elevation],
    CASE
        WHEN [MountainRange] IS NULL THEN '(no mountain)'
        ELSE [MountainRange]
    END AS [Mountain]
FROM
    (SELECT
        *,
        DENSE_RANK() OVER 
    (PARTITION BY [Country] ORDER BY [Elevation] DESC) AS [PeakRank]
    FROM
        (SELECT
            [C].[CountryName] AS [Country],
            [P].[PeakName],
            [P].[Elevation],
            [M].[MountainRange]
        FROM [Countries] AS [C]
            LEFT OUTER JOIN [MountainsCountries] AS [MC]
            ON [MC].[CountryCode] = [C].[CountryCode]
            LEFT OUTER JOIN [Mountains] AS [M]
            ON [M].[Id] = [MC].[MountainId]
            LEFT OUTER JOIN [Peaks] AS [P]
            ON [P].[MountainId] = [M].[Id]) AS [FullInfoQuery]
)AS [PeakRankingsQuery]
WHERE [PeakRank] = 1
ORDER BY [Country] ASC, [Highest Peak Name] ASC

SELECT *
FROM
    (SELECT
        *,
        DENSE_RANK() OVER 
    (PARTITION BY [Country] ORDER BY [Elevation] DESC) AS [Rank]
    FROM
        (SELECT
            [C].[CountryName] AS [Country],
            [P].[PeakName],
            [P].[Elevation],
            [M].[MountainRange]
        FROM [Countries] AS [C]
            LEFT OUTER JOIN [MountainsCountries] AS [MC]
            ON [MC].[CountryCode] = [C].[CountryCode]
            LEFT OUTER JOIN [Mountains] AS [M]
            ON [M].[Id] = [MC].[MountainId]
            LEFT OUTER JOIN [Peaks] AS [P]
            ON [P].[MountainId] = [M].[Id]) AS [FullInfoQuery]) AS [Temp1]
WHERE [Rank] = 1

-- Second variant
SELECT TOP(5)
    [temp].Country,
    ISNULL([temp].[Highest Peak Name], '(no highest peak)') AS [Highest Peak Name],
    ISNULL([temp].[Highest Peak Elevation], 0) AS [Highest Peak Elevation],
    ISNULL([temp].Mountain, '(no mountain)') AS [Mountain]
FROM
    (SELECT c.CountryName AS [Country],
        p.PeakName AS [Highest Peak Name],
        p.Elevation AS [Highest Peak Elevation],
        m.MountainRange AS [Mountain],
        DENSE_RANK() OVER (PARTITION BY c.CountryName ORDER BY p.Elevation DESC) AS [Rank]
    FROM Countries AS c
        LEFT JOIN MountainsCountries AS mc
        ON c.CountryCode = mc.CountryCode
        LEFT JOIN Mountains AS m
        ON mc.MountainId = m.Id
        LEFT JOIN Peaks AS p
        ON m.Id = p.MountainId) AS [temp]
WHERE [temp].[Rank] = 1
ORDER BY [temp].Country ASC, [Highest Peak Name] ASC;