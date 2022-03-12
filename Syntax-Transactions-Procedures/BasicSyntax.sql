-- 3.
USE [SoftUni]

GO
CREATE OR ALTER PROCEDURE usp_GetEmployeesSalaryAbove35000
AS
BEGIN
    SELECT
        [FirstName] AS [First Name],
        [LastName] AS [Last Name]
    FROM [Employees]
    WHERE [Salary] > 35000
END
GO

EXEC usp_GetEmployeesSalaryAbove35000;

-- 4.
GO
CREATE OR ALTER PROCEDURE usp_GetEmployeesSalaryAboveNumber
    (@MinSalary DECIMAL(18, 4))
AS
BEGIN
    SELECT [FirstName],
        [LastName]
    FROM [Employees]
    WHERE [Salary] >= @MinSalary
END
GO

EXEC usp_GetEmployeesSalaryAboveNumber 48100;

SELECT @@VERSION

-- 5.
GO
CREATE OR ALTER PROCEDURE usp_GetTownsStartingWith
    (@Town VARCHAR(MAX))
AS
BEGIN
    SELECT
        [Name]
    FROM [Towns]
    WHERE [Name] LIKE CONCAT(@Town, '%')
END
GO

EXEC usp_GetTownsStartingWith 'Se';

-- 6.
GO
CREATE OR ALTER PROCEDURE usp_GetEmployeesFromTown
    -- Test with Charindex, not actual solution
    (@TownName VARCHAR(50))
-- Check Table Design in order to see what Data Type to use !!!
AS
BEGIN
    SELECT
        [FirstName] AS [First Name],
        [LastName] AS [Last Name]
        -- [T].[Name] not required for jduge !!!
    FROM [Employees] AS [E]
        INNER JOIN [Addresses] AS [A]
        ON [A].[AddressID] = [E].AddressID
        INNER JOIN [Towns] AS [T]
        ON [T].[TownID] = [A].[TownID]
    WHERE CHARINDEX(@TownName, [T].[Name]) > 0
END
GO

-- SELECT CHARINDEX('t', 'Customer') AS MatchPosition;

EXEC usp_GetEmployeesFromTown2 'F';

-- 7.
GO
-- CREATE OR ALTER FUNCTION ufn_GetSalaryLevel2(@salary DECIMAL(18,4)) JUDGE
CREATE OR ALTER FUNCTION ufn_GetSalaryLevel(@salary DECIMAL(18,4))
RETURNS VARCHAR(7) -- Take charValue as low as possible to optimize resouce usage
AS
BEGIN
    DECLARE @result VARCHAR(7);

    IF (@salary > 50000)
    BEGIN
        SET @result = 'High';
    END
    ELSE IF (@salary >= 30000)
    BEGIN
        SET @result = 'Average';
    END
    ELSE
    BEGIN
        SET @result = 'Low';
    END

    RETURN @result;
END
GO

-- Check function
SELECT dbo.ufn_GetSalaryLevel2(40000);

SELECT dbo.ufn_GetSalaryLevel2([Salary])
FROM [Employees]

SELECT
    dbo.ufn_GetSalaryLevel2([Salary]) AS [SalaryLevel],
    CONCAT([FirstName], ' ', [LastName]) AS [FullName],
    [JobTitle]
FROM [Employees];

-- 8.
-- JUDGE
-- CREATE PROCEDURE usp_EmployeesBySalaryLevel
--     (@SalaryLevel VARCHAR(7))
-- AS
-- BEGIN
--     SELECT
--         [FirstName],
--         [LastName]
--     FROM [Employees] AS [E1]
--     WHERE dbo.ufn_GetSalaryLevel([Salary]) = @SalaryLevel
-- END

GO
CREATE OR ALTER PROCEDURE usp_EmployeesBySalaryLevel2
    (@SalaryLevel VARCHAR(7))
AS
BEGIN
    SELECT
        [FirstName] AS [First Name],
        [LastName] AS [Last Name]
    FROM [Employees] AS [E1]
    WHERE dbo.ufn_GetSalaryLevel2([Salary]) = @SalaryLevel
-- WHERE (SELECT dbo.ufn_GetSalaryLevel2([Salary])
-- FROM [Employees] AS [E2]
-- WHERE [E2].[EmployeeID] = [E1].[EmployeeID]) IN (@SalaryLevel)
END
GO

EXEC usp_EmployeesBySalaryLevel2 'High';

-- 10.
GO
CREATE OR ALTER PROCEDURE usp_DeleteEmployeesFromDepartment
    (@departmentId INT)
AS
BEGIN
    -- 1. Final all EmplpoyeeId of EMployees with given DepartmentID
    -- SELECT
    --     [EmployeeID]
    -- FROM [Employees]
    -- WHERE [DepartmentID] = @departmentId
    -- WHERE [DepartmentID] = 1

    -- 2. Delete all employees from EmployessProjects with given EmployeeID
    DELETE FROM [EmployeesProjects]
    WHERE [EmployeeID] IN (SELECT
        [EmployeeID]
    FROM [Employees]
    WHERE [DepartmentID] = @departmentId)

    -- 3. Set ManagerID to null where given employee begind ManagerID is going
    -- to be deleted, Employees Table
    UPDATE [Employees]
    SET [ManagerID] = NULL
    WHERE [ManagerID] IN (SELECT
        [EmployeeID]
    FROM [Employees]
    WHERE [DepartmentID] = @departmentId)

    -- 4. Alter ManagerID cloumn in Departments to nullable, and set ManagerID of given department to null
    -- Forum variant
    -- ALTER TABLE Departments
    -- ALTER COLUMN ManagerID int NULL
    -- UPDATE Departments
    -- SET ManagerID = NULL

    ALTER TABLE [Departments]
    ALTER COLUMN [ManagerID] INT
    -- ALTER COLUMN [ManagerID] INT NULL, NULL can be left out

    UPDATE [Departments]
    SET [ManagerID] = NULL
    -- WHERE DepartmentID = @departmentId
    WHERE [ManagerID] IN (SELECT
        [EmployeeID]
    FROM [Employees]
    WHERE [DepartmentID] = @departmentId)
    -- change ManagerID to null for all Managers that are going to be deleted

    -- 5. Delete all employees from given Department
    DELETE FROM [Employees]
    WHERE [DepartmentID] = @departmentId

    -- 6. Delete all department from Departments
    -- first delete records in employees, then in departemnt since departments is dependent on Employees
    DELETE FROM [Departments]
    WHERE [DepartmentID] = @departmentId

    -- 7. Select count of employees of target Departmnet, should return 0
    SELECT COUNT(*)
    FROM [Employees]
    WHERE [DepartmentID] = @departmentId

END
GO

-- EXEC usp_DeleteEmployeesFromDepartment 1;

-- + + + + + + + + DEMO CODE

SELECT COUNT(*)
FROM [Employees]
WHERE [DepartmentID] = 1

SELECT *
FROM [Departments]
ORDER BY [ManagerID] ASC
-- WHERE [DepartmentID] = 1

SELECT [ManagerID]
FROM [Departments]
WHERE [DepartmentID] = 1

SELECT *
FROM [Employees]
-- WHERE [EmployeeID] IN (SELECT
WHERE [ManagerID] IN (SELECT
    [EmployeeID]
FROM [Employees]
WHERE [DepartmentID] = 1)

-- 3, 9, 11, 12, 267, 270

-- SELECT d.DepartmentID, d.Name AS Department, d.ManagerID as DeptManager,
--     e.EmployeeID, e.FirstName, e.LastName, e.ManagerID as EmplManager, E.JobTitle
-- FROM Departments AS d
--     JOIN Employees AS e ON d.DepartmentID = e.DepartmentID
-- WHERE d.Name IN ('Production', 'Production Control')

-- SELECT DepartmentID, Name AS Department
-- FROM Departments
-- WHERE Name IN ('Production', 'Production Control')

-- + + + + + + END

-- 13.
USE [Bank]
GO
CREATE OR ALTER PROCEDURE usp_GetHoldersWithBalanceHigherThan
    (@TargetSum DECIMAL(24, 4))
-- (@MinBalance DECIMAL(18 , 4)) as in Demo used
AS
BEGIN

    SELECT
        [FirstName] AS [First Name],
        [LastName] AS [Last Name]
    FROM [AccountHolders] AS [AH]
    WHERE @TargetSum < (
    SELECT
        -- [AccountHolderId],
        -- COUNT(*) AS [Counts],
        SUM([Balance]) AS [TotalMoney]
    FROM
        [Accounts] AS [A]
    -- INNER JOIN [Accounts] AS [A]
    -- ON [A].[AccountHolderId] = [AC].[Id]
    WHERE [A].[AccountHolderId] = [AH].[Id]
    GROUP BY [AccountHolderId])
    ORDER BY [FirstName] ASC, [Last Name] ASC
END
GO

GO
CREATE OR ALTER PROCEDURE usp_GetHoldersWithBalanceHigherThan2
    (@MinBalance DECIMAL(18 , 4))
-- as in Demo used
AS
BEGIN
    -- SELECT DISTINCT
    SELECT
        [FirstName],
        [LastName]
    FROM [Accounts] AS [A]
        INNER JOIN [AccountHolders] AS [AH]
        ON [AH].[Id] = [A].[AccountHolderId]
    GROUP BY [FirstName], [LastName]
    -- Grouping by two criteria guarantess uniqness for this case only !!, otherwise DISTINCT
    -- GROUP BY [AH].[Id] ,[FirstName], [LastName] -- With additional ID, guarantess Uniquness
    -- Still need FirstName, LastName in groupBY to access names for query
    HAVING SUM([Balance]) > @MinBalance
    ORDER BY [FirstName] ASC, [LastName] ASC
END
GO

EXEC usp_GetHoldersWithBalanceHigherThan2 5423456;
EXEC usp_GetHoldersWithBalanceHigherThan2 25000;

SELECT *
FROM [AccountHolders]

-- 14.
GO
-- CREATE OR ALTER FUNCTION ufn_CalculateFutureValue
CREATE OR ALTER FUNCTION ufn_CalculateFutureValue2
(@Sum DECIMAL(18, 4), @Interest FLOAT, @YearsCount INT)
RETURNS DECIMAL(18, 4)
AS
BEGIN
    DECLARE @futureValue DECIMAL(18, 4);
    SET @futureValue = @Sum * (POWER((1 + @Interest), @YearsCount));
    -- Forumula : Initial SUm times Interest rate plus one to the power of years/intervals !!!
    -- result = I * ((1 + R)T)
    RETURN @futureValue;
END
GO

SELECT dbo.ufn_CalculateFutureValue2(15000, 0.1, 5);
SELECT dbo.ufn_CalculateFutureValue2(1000, 0.1, 5);

-- 17.
USE [Diablo]
-- TVF function must be returned
GO
CREATE OR ALTER FUNCTION ufn_CashInUsersGames -- JUDGE Games !!! with 's'
(@GameName NVARCHAR(50))
RETURNS TABLE
AS
    RETURN  SELECT (
    (SELECT
    SUM([Cash]) AS [SumCash]
FROM
    (SELECT
        [G].[Name],
        [UG].[Cash],
        ROW_NUMBER() OVER (PARTITION BY [G].[Name] ORDER BY [UG].[Cash] DESC) AS [RowNum]
    FROM [Games] AS [G]
        INNER JOIN [UsersGames] AS [UG]
        ON [UG].[GameId] = [G].[Id]
    -- WHERE [G].[Name] = 'Love in a mist') AS [RowNumQuery]
    WHERE [G].[Name] = @GameName) AS [RowNumQuery]
WHERE [RowNum] % 2 <> 0) ) AS [SumCash]
GO

SELECT *
FROM dbo.ufn_CashInUsersGame('Love in a mist');

SELECT
    SUM([Cash]) AS [SumCash]
FROM
    (SELECT
        [G].[Name],
        [UG].[Cash],
        ROW_NUMBER() OVER (PARTITION BY [G].[Name] ORDER BY [UG].[Cash] DESC) AS [RowNum]
    FROM [Games] AS [G]
        INNER JOIN [UsersGames] AS [UG]
        ON [UG].[GameId] = [G].[Id]
    WHERE [G].[Name] = 'Love in a mist') AS [RowNumQuery]
WHERE [RowNum] % 2 <> 0

SELECT SUM([Cash])
FROM
    (SELECT
        ROW_NUMBER() OVER (ORDER BY [GameID] ASC) AS [Rank],
        [Cash]
    FROM [UsersGames] AS [UG]
        JOIN [Games] AS [G]
        ON [G].[Id] = [UG].[GameId]
    WHERE [G].[Name] = 'Love in a mist') AS [Temp]
WHERE [Rank] % 2 <> 0