
-- UI Login
USE MASTER
CREATE LOGIN LeaderBoardApp WITH PASSWORD = <YOUR PASSWORD HERE>;
GO
USE leaderboard
CREATE USER LeaderBoardApp FOR LOGIN LeaderBoardApp;
GO

-- Run Objects
DROP TABLE IF EXISTS runHistory
GO

CREATE TABLE runHistory (
    runGUID CHAR(36) PRIMARY KEY,
    startDate DATETIME,
    endDate DATETIME,
    successful BIT
)
GO

DROP PROC IF EXISTS insertNewRun001 
GO

CREATE PROC insertNewRun001 (@runGUID CHAR(36)) AS
    INSERT INTO runHistory (
        runGUID,
        startDate
    ) VALUES (
        @runGUID,
        GETDATE()
    )
GO

GRANT EXEC ON insertNewRun001 TO [adf-ne-techdebtleague]

DROP PROC IF EXISTS updateRun001 
GO

CREATE PROC updateRun001 (@runGUID CHAR(36), @success BIT) AS
    UPDATE runHistory SET endDate = GETDATE(), successful = @success WHERE runGUID = @runGUID
GO

GRANT EXEC ON updateRun001 TO [adf-ne-techdebtleague]
GO

CREATE FUNCTION lastRunGUID() 
RETURNS CHAR(36)
AS
BEGIN
	RETURN (SELECT TOP 1 runGUID FROM runHistory WHERE successful = 1 ORDER BY endDate DESC)
END
GO

-- Configuration Objects
DROP TABLE IF EXISTS config
GO

CREATE TABLE config (
    id INT IDENTITY(1,1) PRIMARY KEY,
    groupLevel1TagName VARCHAR(255),
    groupLevel2TagName VARCHAR(255),
    groupLevel3TagName VARCHAR(255),
    EnvironmentTagName VARCHAR(255),
    EnvironmentProduction VARCHAR(255),
    EnvironmentProductionMultiplier TINYINT,
    EnvironmentNonProduction VARCHAR(255),
    EnvironmentNonProductionMultiplier TINYINT,
    EnvironmentDev VARCHAR(255),
    EnvironmentDevMultiplier TINYINT,
    CriticalityTagName VARCHAR(255),
    CriticalityTier0 VARCHAR(255),
    CriticalityTier0Multiplier TINYINT,
    CriticalityTier1 VARCHAR(255),
    CriticalityTier1Multiplier TINYINT,
    CriticalityTier2 VARCHAR(255),
    Criticalitytier2Multiplier TINYINT,
    ClassificationTagName VARCHAR(255),
    ClassificationHigh VARCHAR(255),
    ClassificationHighMultiplier TINYINT,
    ClassificationMedium VARCHAR(255),
    ClassificationMediumMultiplier TINYINT,
    ClassificationLow VARCHAR(255),
    ClassificationLowMultiplier TINYINT,
    activeFrom DATETIME,
    activeTo DATETIME,
    isCurrent BIT
)
GO

INSERT INTO config (
    groupLevel1TagName,
    groupLevel2TagName,
    groupLevel3TagName,
    EnvironmentTagName,
    EnvironmentProduction,
    EnvironmentProductionMultiplier,
    EnvironmentNonProduction,
    EnvironmentNonProductionMultiplier,
    EnvironmentDev,
    EnvironmentDevMultiplier,
    CriticalityTagName,
    CriticalityTier0,
    CriticalityTier0Multiplier,
    CriticalityTier1,
    CriticalityTier1Multiplier,
    CriticalityTier2,
    Criticalitytier2Multiplier,
    ClassificationTagName,
    ClassificationHigh,
    ClassificationHighMultiplier,
    ClassificationMedium,
    ClassificationMediumMultiplier,
    ClassificationLow,
    ClassificationLowMultiplier,
    activeFrom,
    isCurrent
) VALUES (
    'BusinessUnit',
    'Product',
    'Component',
    'Environment',
    'Production',
    3,
    'NonProduction',
    2,
    'Dev',
    1,
    'Criticality',
    'MissionCritical',
    3,
    'Tier1',
    2,
    'Tier2',
    1,
    'DataClassification',
    'HighlyConfidential',
    3,
    'Confidential',
    2,
    'Public',
    1,
    GETDATE(),
    1
)
GO

DROP PROC IF EXISTS getConfig001
GO

CREATE PROC getConfig001 AS 
    SELECT TOP 1 
        groupLevel1TagName,
        groupLevel2TagName,
        groupLevel3TagName,
        EnvironmentTagName,
        EnvironmentProduction,
        EnvironmentProductionMultiplier,
        EnvironmentNonProduction,
        EnvironmentNonProductionMultiplier,
        EnvironmentDev,
        EnvironmentDevMultiplier,
        CriticalityTagName,
        CriticalityTier0,
        CriticalityTier0Multiplier,
        CriticalityTier1,
        CriticalityTier1Multiplier,
        CriticalityTier2,
        Criticalitytier2Multiplier,
        ClassificationTagName,
        ClassificationHigh,
        ClassificationHighMultiplier,
        ClassificationMedium,
        ClassificationMediumMultiplier,
        ClassificationLow,
        ClassificationLowMultiplier
    FROM 
        config
    WHERE 
        isCurrent = 1
GO

GRANT EXEC ON getConfig001 TO [adf-ne-techdebtleague]
GO

-- Policy objects
DROP TABLE IF EXISTS staging_policyRecords
GO

CREATE TABLE staging_policyRecords(
    resourceId VARCHAR(8000),
    subscriptionId CHAR(36),
    isCompliant BIT,
    resourceGroup VARCHAR(90),
    policyDefinitionId VARCHAR(8000),
    resourceType VARCHAR(500),
    policyAssignmentName VARCHAR(500)
)
GO

GRANT SELECT, INSERT ON staging_policyRecords TO [adf-ne-techdebtleague]
GO

DROP PROC IF EXISTS clearStagingPolicyRecords001
GO

CREATE PROCEDURE clearStagingPolicyRecords001 AS
    DELETE FROM staging_policyRecords
GO

GRANT EXEC ON clearStagingPolicyRecords001 TO [adf-ne-techdebtleague]
GO


DROP PROC IF EXISTS mergePolicyRecords001
GO

CREATE PROCEDURE mergePolicyRecords001 @runGUID CHAR(36) AS
SET NOCOUNT ON;  
  
MERGE policyRecords AS target
	USING (SELECT * FROM staging_policyRecords) AS source
	ON (target.resourceId = source.resourceId AND target.policyDefinitionId = source.policyDefinitionId)
	WHEN MATCHED THEN
		UPDATE SET lastUpdated = GETDATE(), lastRunGUID = @runGUID
	WHEN NOT MATCHED THEN
		INSERT (resourceId, subscriptionId, isCompliant, resourceGroup, policyDefinitionId, resourceType, policyAssignmentName, dateAdded, lastUpdated, lastRunGUID)
		VALUES (source.resourceId, source.subscriptionId, source.isCompliant, source.resourceGroup, source.policyDefinitionId, source.resourceType, source.policyAssignmentName, GETDATE(), GETDATE(), @runGUID);

GO

GRANT EXEC ON mergePolicyRecords001 TO [adf-ne-techdebtleague]
GO

-- Budget Objects
DROP TABLE IF EXISTS budgets
GO

CREATE TABLE budgets (
    id VARCHAR(2000) PRIMARY KEY,
    [name] VARCHAR(255),
    subscriptionId CHAR(36),
    resourceGroup VARCHAR(90),
    amount SMALLMONEY,
    timeGrain VARCHAR(50),
    startDate DATETIME,
    endDate DATETIME,
    currentSpend SMALLMONEY,
    currency VARCHAR(10),
    budgetFilter VARCHAR(8000),
    dateAdded DATETIME,
    lastUpdated DATETIME,
    lastrunGUID CHAR(36),
)
GO

DROP PROC IF EXISTS getBudgets001
GO

CREATE PROC getBudgets001 (@runGUID CHAR(36)) AS 
    SELECT 
        id, 
        [name],
        [subscriptionId],
        resourceGroup,
        amount,
        timeGrain,
        startDate,
        endDate,
        currentSpend,
        currency,
        budgetFilter,
        dateAdded,
        lastUpdated,
        lastrunGUID
    FROM
        budgets
    WHERE  
        lastrunGUID = @runGUID
GO

GRANT EXEC ON getBudgets001 TO [adf-ne-techdebtleague]

DROP TABLE IF EXISTS staging_budgets
GO

CREATE TABLE staging_budgets  (
    id VARCHAR(2000) PRIMARY KEY,
    [name] VARCHAR(255),
    subscriptionId CHAR(36),
    resourceGroup VARCHAR(90),
    amount SMALLMONEY,
    timeGrain VARCHAR(50),
    startDate DATETIME,
    endDate DATETIME,
    currentSpend SMALLMONEY,
    currency VARCHAR(10),
    budgetFilter VARCHAR(8000)
)
GO

GRANT SELECT, INSERT, DELETE ON  staging_budgets TO [adf-ne-techdebtleague]
GO

DROP PROC IF EXISTS mergeBudgets001
GO

CREATE PROCEDURE mergeBudgets001 @runGUID CHAR(36) AS
SET NOCOUNT ON;  
  
MERGE budgets AS target
	USING (SELECT * FROM staging_budgets) AS source
	ON (target.id = source.id)
	WHEN MATCHED THEN
		UPDATE SET lastUpdated = GETDATE(), lastRunGUID = @runGUID
	WHEN NOT MATCHED THEN
		INSERT (id, [name], subscriptionId, resourceGroup, amount, timeGrain, startDate, endDate, currentSpend, currency, budgetFilter, dateAdded, lastUpdated, lastrunGUID)
		VALUES (source.id, source.name, source.subscriptionId, source.resourceGroup, source.amount, source.timeGrain, source.startDate, source.endDate, source.currentSpend, source.currency, source.budgetFilter, GETDATE(), GETDATE(), @runGUID);

GO

GRANT EXEC ON mergeBudgets001 TO [adf-ne-techdebtleague]
GO

DROP TABLE IF EXISTS budgetHistory
GO

CREATE TABLE budgetHistory (
    id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    budgetId VARCHAR(2000),
    budgetMonth TINYINT,
    budgetYear SMALLINT,
    spend SMALLMONEY,
    variance SMALLMONEY
)
GO

DROP PROCEDURE IF EXISTS insertBudgetHistory001
GO

CREATE PROC insertBudgetHistory001 (
    @budgetId VARCHAR(2000),
    @budgetMonth TINYINT,
    @budgetYear SMALLINT,
    @spend SMALLMONEY,
    @variance SMALLMONEY) AS


	--Assuming that bulk of the operations on the table will be update as lifecycle of recommendations means they hang around
    UPDATE budgetHistory SET spend = @spend, variance = @variance WHERE budgetId = @budgetId AND budgetMonth = @budgetMonth AND budgetYear = @budgetYear

    IF @@ROWCOUNT = 0
		BEGIN
			INSERT INTO budgetHistory (budgetId, budgetMonth, budgetYear, spend, variance) 
				VALUES (@budgetId, @budgetMonth, @budgetYear, @spend, @variance)
		END
GO

GRANT EXEC ON insertBudgetHistory001 TO [adf-ne-techdebtleague]

-- Advisor Objects
DROP TABLE IF EXISTS AdvisorRecommendations
GO

CREATE TABLE AdvisorRecommendations (
    id VARCHAR(256) NOT NULL PRIMARY KEY,
    resourceId VARCHAR(8000),
    subscriptionId CHAR(36),
    resourceGroup VARCHAR(90),
    dateAdded DATETIME,
    category VARCHAR(256),
    assessmentKey VARCHAR(256),
    score INT,
    impact VARCHAR(50),
    impactedField VARCHAR(255),
    impactedValue VARCHAR(255),
    lastUpdated DATETIME,
    recommendationTypeId VARCHAR(255),
    problem VARCHAR(255),
    solution VARCHAR(255),
    lastRunGUID CHAR(36)
)

GO

DROP TABLE IF EXISTS staging_recommendations
GO

CREATE TABLE staging_recommendations(
    id VARCHAR(8000),
    resourceId VARCHAR(8000),
    subscriptionId CHAR(36),
    resourceGroup VARCHAR(90),
    category VARCHAR(256),
    assessmentKey VARCHAR(256),
    score INT,
    impact VARCHAR(50),
    impactedField VARCHAR(255),
    impactedValue VARCHAR(255),
    lastUpdated DATETIME,
    recommendationTypeId VARCHAR(255),
    problem VARCHAR(255),
    solution VARCHAR(255)
)
GO

GRANT SELECT, INSERT ON staging_recommendations TO [adf-ne-techdebtleague]
GO


DROP PROC IF EXISTS clearStagingRecommendations001
GO

CREATE PROCEDURE clearStagingRecommendations001 AS
    DELETE FROM staging_recommendations
GO

GRANT EXEC ON clearStagingRecommendations001 TO [adf-ne-techdebtleague]
GO

DROP PROC IF EXISTS mergeAdvisorRecommendations001
GO

CREATE PROCEDURE mergeAdvisorRecommendations001 @runGUID CHAR(36) AS
SET NOCOUNT ON;  
  
MERGE AdvisorRecommendations AS target
	USING (SELECT * FROM staging_recommendations) AS source
	ON (target.id = source.id)
	WHEN MATCHED THEN
		UPDATE SET lastUpdated = GETDATE(), lastRunGUID = @runGUID
	WHEN NOT MATCHED THEN
		INSERT (id, resourceId, subscriptionId, resourceGroup, dateAdded, category, assessmentKey, score, impact, impactedField, impactedValue, lastUpdated, recommendationTypeId, problem, solution, lastRunGUID)
		VALUES (id, resourceId, SUBSTRING(resourceId, 16, 36), IIF(PATINDEX('%/resourceGroups/%', resourceId) > 0,SUBSTRING(resourceId, 68, (PATINDEX('%/providers/%', resourceId) - 68)),null),GETDATE(), category, assessmentKey, score, impact, impactedField, impactedValue, GETDATE(), recommendationTypeId, problem, solution, @runGUID);
GO

GRANT EXEC ON mergeAdvisorRecommendations001 TO [adf-ne-techdebtleague]
GO

-- Resource Group Objects
DROP TABLE IF EXISTS runResourceGroupValues
GO

CREATE TABLE runResourceGroupValues (
    id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    runGUID CHAR(36) NOT NULL,
    subscriptionId CHAR(36) NOT NULL,
    resourceGroup VARCHAR(90) NOT NULL,
    level1TagValue VARCHAR(256),
    level2TagValue VARCHAR(256),
    level3TagValue VARCHAR(256),
    environmentTagValue VARCHAR(256),
    criticalityTagValue VARCHAR(256),
    classificationTagValue VARCHAR(256),
    compliantResourceCount INT,
    nonCompliantResourceCount INT,
    nonCompliantPolicyCount INT
)
GO


DROP PROC IF EXISTS insertRunResourceGroupValues001
GO

CREATE PROCEDURE insertRunResourceGroupValues001 (
    @runGUID CHAR(36), 
    @subscriptionId CHAR(36),
    @resourceGroup CHAR(90),
    @level1TagValue VARCHAR(256) = NULL, 
    @level2TagValue VARCHAR(256) = NULL, 
    @level3TagValue VARCHAR(256) = NULL, 
    @environmentTagValue VARCHAR(256) = NULL, 
    @criticalityTagValue VARCHAR(256) = NULL,
    @compliantResourceCount INT = NULL,
    @nonCompliantResourceCount INT = NULL,
    @nonCompliantPolicyCount INT = NULL,
    @classificationTagValue VARCHAR(256) = NULL
    ) AS

    INSERT INTO runResourceGroupValues (
        runGUID, 
        subscriptionId, 
        resourceGroup, 
        level1TagValue, 
        level2TagValue, 
        level3TagValue, 
        environmentTagValue, 
        criticalityTagValue,
        compliantResourceCount,
        nonCompliantResourceCount,
        nonCompliantPolicyCount,
        classificationTagValue
    ) VALUES (
        @runGUID, 
        @subscriptionId, 
        @resourceGroup, 
        @level1TagValue, 
        @level2TagValue, 
        @level3TagValue, 
        @environmentTagValue, 
        @criticalityTagValue,
        @compliantResourceCount,
        @nonCompliantResourceCount,
        @nonCompliantPolicyCount,
        @classificationTagValue
    )
GO

GRANT EXEC ON insertRunResourceGroupValues001 TO [adf-ne-techdebtleague]
GO

-- Leaderboard scores
DROP TABLE IF EXISTS runTechDebtPointsScores
GO

CREATE TABLE runTechDebtPointsScores (
    id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    runGUID CHAR(36) NOT NULL,
    groupingLevel1 VARCHAR(256),
    groupingLevel2 VARCHAR(256),
    groupingLevel3 VARCHAR(256),
    environmentValue VARCHAR(256),
    criticalityValue VARCHAR(256),
    classificationValue VARCHAR(256),
    impact VARCHAR(256),
    category VARCHAR(256),
    technicalDebtPoints INT
)

GO

DROP PROC IF EXISTS generateLatestLeaderboard001
GO

CREATE PROC generateLatestLeaderboard001 (@runGUID CHAR(36)) AS
SET NOCOUNT ON
--Declare the many variables we need...
DECLARE @runDateTime DATETIME, @GroupingLevel1 VARCHAR(255)
DECLARE @GroupingLevel2 VARCHAR(255), @GroupingLevel3 VARCHAR(255), @EnvironmentProduction VARCHAR(255)
DECLARE @EnvironmentProductionMultiplier INT, @EnvironmentNonProduction VARCHAR(255), @EnvironmentNonProductionMultiplier INT
DECLARE @EnvironmentDev VARCHAR(255), @EnvironmentDevMultiplier INT, @CriticalityTier0 VARCHAR(255)
DECLARE @CriticalityTier0Multiplier INT, @CriticalityTier1 VARCHAR(255), @CriticalityTier1Multiplier INT
DECLARE @CriticalityTier2 VARCHAR(255), @CriticalityTier2Multiplier INT
DECLARE @ClassificationHigh VARCHAR(255), @ClassificationMedium VARCHAR(255), @ClassificationLow VARCHAR(255)
DECLARE @ClassificationHighMultiplier INT, @ClassificationMediumMultiplier INT, @ClassificationLowMultiplier INT
DECLARE @HighImpactBaseScore INT, @MediumImpactBaseScore INT, @LowImpactBaseScore INT

--Get runGUID we will use for the queries
--SET @runGUID = dbo.lastrunGUID()

--Alter these values to determine how much the Recommendation's impact drives the score
SET @HighImpactBaseScore = 3
SET @MediumImpactBaseScore = 2
SET @LowImpactBaseScore = 1

--Load the latest run's configuration
SELECT TOP 1
    @GroupingLevel1 = groupLevel1TagName,
    @GroupingLevel2 = groupLevel2TagName,
    @GroupingLevel3 = groupLevel3TagName,
    @EnvironmentProduction = EnvironmentProduction,
    @EnvironmentProductionMultiplier = EnvironmentProductionMultiplier,
    @EnvironmentNonProduction = EnvironmentNonProduction,
    @EnvironmentNonProductionMultiplier = EnvironmentNonProductionMultiplier,
    @EnvironmentDev = EnvironmentDev,
    @EnvironmentDevMultiplier = EnvironmentDevMultiplier,
    @CriticalityTier0 = CriticalityTier0,
    @CriticalityTier0Multiplier = CriticalityTier0Multiplier,
    @CriticalityTier1 = CriticalityTier1,
    @CriticalityTier1Multiplier = CriticalityTier1Multiplier,
    @CriticalityTier2 = CriticalityTier2,
    @CriticalityTier2Multiplier = CriticalityTier2Multiplier,
	@ClassificationHigh = ClassificationHigh,
	@ClassificationHighMultiplier = ClassificationHighMultiplier,
	@ClassificationMedium = ClassificationMedium,
	@ClassificationMediumMultiplier = ClassificationMediumMultiplier,
	@ClassificationLow = ClassificationLow,
	@ClassificationLowMultiplier = ClassificationLowMultiplier
FROM
    config
WHERE
	isCurrent = 1

-- In case this proc is run multiple times for the same run clear exisiting entries
DELETE FROM runTechDebtPointsScores WHERE runGUID = @runGUID

-- Load Recommendation Base Scores
INSERT INTO 
    runTechDebtPointsScores ( 
        runGUID,
        groupingLevel1,
        groupingLevel2,
        groupingLevel3,
        environmentValue,
        criticalityValue,
		classificationValue,
        impact,
        category,
		technicalDebtPoints
    )
SELECT 
	rgv.runGUID,
	rgv.level1TagValue,
	rgv.level2TagValue,
	rgv.level3TagValue,
	rgv.environmentTagValue,
	rgv.criticalityTagValue,
	rgv.classificationTagValue,
	ar.impact,
	ar.category,
	SUM(ar.TechDebtPoints) [TechDebtPoints]
FROM
(SELECT
	id,
	runGUID,
	subscriptionId,
	resourceGroup,
	level1TagValue,
	level2TagValue,
	level3TagValue,
	environmentTagValue,
	criticalityTagValue,
	classificationTagValue
FROM
	runResourceGroupValues
WHERE
	runGUID = @runGUID) rgv LEFT JOIN
(SELECT
	subscriptionId,
	resourceGroup,
	category,
	impact,
	[TechDebtPoints] = 
	 	CASE
		 	WHEN impact = 'High' THEN (count(id) * @HighImpactBaseScore)
			WHEN impact = 'Medium' THEN (count(id) * @MediumImpactBaseScore)
			WHEN impact = 'Low' THEN (count(id) * @LowImpactBaseScore)
			ELSE -1
		END
FROM
	[dbo].[AdvisorRecommendations]
WHERE
	lastRunGUID = @runGUID
GROUP BY
	subscriptionId,
	resourceGroup,
	category,
	impact) ar ON rgv.subscriptionId = ar.subscriptionId AND rgv.resourceGroup = ar.resourceGroup
GROUP BY
	rgv.runGUID,
	rgv.level1TagValue,
	rgv.level2TagValue,
	rgv.level3TagValue,
	rgv.environmentTagValue,
	rgv.criticalityTagValue,
	rgv.classificationTagValue,
	ar.impact,
	ar.category

-- Load Policy Base scores
INSERT INTO 
    runTechDebtPointsScores ( 
        runGUID,
        groupingLevel1,
        groupingLevel2,
        groupingLevel3,
        environmentValue,
        criticalityValue,
		classificationValue,
        impact,
        category,
		technicalDebtPoints
    )
SELECT
	@runGUID,
	level1TagValue,
	level2TagValue,
	level3TagValue,
	environmentTagValue,
	criticalityTagValue,
	classificationTagValue,
	'N/A',
	'Policy',
	SUM([TechDebtPoints]) [TechDebtPoints]
FROM (
	SELECT 
		level1TagValue,
		level2TagValue,
		level3TagValue,
		environmentTagValue,
		criticalityTagValue,
		classificationTagValue,
		[TechDebtPoints] =
			CASE
				WHEN
					(compliantResourceCount + nonCompliantResourceCount) > 0 THEN ((100 / (compliantResourceCount + nonCompliantResourceCount)) * compliantResourceCount)
				ELSE
					100
			END
	FROM
		runResourceGroupValues where runGUID = @runGUID
) polPercentage
	GROUP BY
		level1TagValue,
		level2TagValue,
		level3TagValue,
		environmentTagValue,
		criticalityTagValue,
		classificationTagValue

-- Pass 2 apply compounding factors to the base scores
-- Policy is % noncompliant as base score then compoinding factors

--Generate Tier0, Production Scores
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier0
-- Tier1, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier1
-- Tier2, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier2
-- Tier0, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier0
-- Tier1, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier1
-- Tier2, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier2
-- Tier0, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier0
-- Tier1, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier1
-- Tier2, Production
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentProduction AND criticalityValue =  @CriticalityTier2
--Generate Tier0, NonProduction Scores
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier0
-- Tier1, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier1
-- Tier2, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier2
-- Tier0, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier0
-- Tier1, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier1
-- Tier2, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier2
-- Tier0, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier0
-- Tier1, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier1
-- Tier2, NonProduction
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentNonProductionMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentNonProduction AND criticalityValue =  @CriticalityTier2
--Generate Tier0, Dev Scores
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier0
-- Tier1, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier1
-- Tier2, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier2
-- Tier0, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier0
-- Tier1, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier1
-- Tier2, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier2
-- Tier0, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier0Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier0
-- Tier1, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier1Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier1
-- Tier2, Dev
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @EnvironmentDevMultiplier * @CriticalityTier2Multiplier) WHERE runGUID = @runGUID AND environmentValue = @EnvironmentDev AND criticalityValue =  @CriticalityTier2
-- Apply Data Classification multiplier
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @ClassificationLowMultiplier) WHERE runGUID = @runGUID AND ClassificationValue = @ClassificationLow
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @ClassificationMediumMultiplier) WHERE runGUID = @runGUID AND ClassificationValue = @ClassificationMedium
UPDATE runTechDebtPointsScores SET technicalDebtPoints = (technicalDebtPoints * @ClassificationHighMultiplier) WHERE runGUID = @runGUID AND ClassificationValue = @ClassificationHigh

--Decorate Unknown and assume worse compounding factor representing unknown risk
UPDATE runTechDebtPointsScores SET groupingLevel1 = 'Unknown' WHERE ISNULL(groupingLevel1,'') = '' AND runGUID = @runGUID
UPDATE runTechDebtPointsScores SET groupingLevel2 = 'Unknown' WHERE ISNULL(groupingLevel2,'') = '' AND runGUID = @runGUID
UPDATE runTechDebtPointsScores SET groupingLevel3 = 'Unknown' WHERE ISNULL(groupingLevel3,'') = '' AND runGUID = @runGUID
UPDATE runTechDebtPointsScores SET environmentValue = 'Unknown', technicalDebtPoints = (technicalDebtPoints * @EnvironmentProductionMultiplier) WHERE ISNULL(environmentValue,'') = '' AND runGUID = @runGUID
UPDATE runTechDebtPointsScores SET criticalityValue = 'Unknown', technicalDebtPoints = (technicalDebtPoints * @CriticalityTier0Multiplier) WHERE ISNULL(criticalityValue,'') = '' AND runGUID = @runGUID
UPDATE runTechDebtPointsScores SET classificationValue = 'Unknown', technicalDebtPoints = (technicalDebtPoints * @ClassificationHighMultiplier) WHERE ISNULL(classificationValue,'') = '' AND runGUID = @runGUID

-- Pass 3 add budgets - these aren't affected by compounding factors.  Do these last so we save having to filter them out of the global updates above
/*
*** WE NEED TO BREAK THE FILTER OUT FOR EACH GROUPING

INSERT INTO 
    runTechDebtPointsScores ( 
		runGUID,
        groupingLevel1,
        groupingLevel2,
        groupingLevel3,
        environmentValue,
        criticalityValue,
		classificationValue,
        impact,
        category,
		technicalDebtPoints
	)
SELECT 
	*
FROM
(SELECT
	*
FROM
	budgets
) b LEFT JOIN
(SELECT 
	* 
FROM
	budgetHistory 
WHERE 
	budgetMonth > month(dateadd(month,-4,getdate())) and budgetYear > year(dateadd(month,-4,getdate()))) bh ON b.id = bh.budgetId
*/
GO

GRANT EXECUTE ON generateLatestLeaderboard001 TO [adf-ne-techdebtleague]
GO

DROP PROC IF EXISTS getNestedSummaryTable001
GO

CREATE PROC getNestedSummaryTable001 AS

SELECT DISTINCT
	gl1.GroupingLevel1 [gl1.name], gl1.technicalDebtPoints [gl1.points], gl2.groupingLevel2 [gl1.gl2.name], 
	gl2.technicalDebtPoints [gl1.gl2.points], gl3.groupingLevel3 [gl1.gl2.gl3.name], gl3.technicalDebtPoints [gl1.gl2.gl3.points],
	env.environmentValue [gl1.gl2.gl3.environment.name], env.technicalDebtPoints [gl1.gl2.gl3.environment.points],
	crit.criticalityValue [gl1.gl2.gl3.environment.criticality.name], crit.technicalDebtPoints [gl1.gl2.gl3.environment.criticality.points],
	clas.classificationValue [gl1.gl2.gl3.environment.criticality.classification.name], clas.technicalDebtPoints [gl1.gl2.gl3.environment.criticality.classification.points]
FROM 
(SELECT DISTINCT groupingLevel1, SUM(technicalDebtPoints) [technicalDebtPoints] FROM runTechDebtPointsScores WHERE runguid = dbo.lastrunguid() GROUP BY groupingLevel1) gl1
	JOIN 
		(SELECT DISTINCT groupingLevel1, groupinglevel2, SUM(technicalDebtPoints) [technicalDebtPoints] FROM runTechDebtPointsScores WHERE runguid = dbo.lastrunguid() GROUP BY groupingLevel1, groupingLevel2) gl2 on gl1.groupingLevel1 = gl2.groupingLevel1
	JOIN
		(SELECT DISTINCT groupingLevel1, groupingLevel2, groupingLevel3, SUM(technicalDebtPoints) [technicalDebtPoints] FROM runTechDebtPointsScores WHERE runguid = dbo.lastrunguid() GROUP BY groupingLevel1, groupingLevel2, groupingLevel3) gl3 on gl2.groupingLevel1 = gl3.groupingLevel1 AND gl2.groupingLevel2 = gl3.groupingLevel2
	JOIN
		(SELECT DISTINCT groupingLevel1, groupingLevel2, groupingLevel3, environmentValue, SUM(technicalDebtPoints) [technicalDebtPoints] FROM runTechDebtPointsScores WHERE runguid = dbo.lastrunguid() GROUP BY groupingLevel1, groupingLevel2, groupingLevel3, environmentValue) env on gl3.groupingLevel1 = env.groupingLevel1 AND gl3.groupingLevel2 = env.groupingLevel2 AND gl3.groupingLevel3 = env.groupingLevel3
	JOIN
		(SELECT DISTINCT groupingLevel1, groupingLevel2, groupingLevel3, environmentValue, criticalityValue, SUM(technicalDebtPoints) [technicalDebtPoints] FROM runTechDebtPointsScores WHERE runguid = dbo.lastrunguid() GROUP BY groupingLevel1, groupingLevel2, groupingLevel3, environmentValue, criticalityValue) crit on gl3.groupingLevel1 = crit.groupingLevel1 AND env.groupingLevel2 = gl3.groupingLevel2 AND env.groupingLevel3 = gl3.groupingLevel3
	JOIN
		(SELECT DISTINCT groupingLevel1, groupingLevel2, groupingLevel3, environmentValue, criticalityValue, classificationValue, SUM(technicalDebtPoints) [technicalDebtPoints] FROM runTechDebtPointsScores WHERE runguid = dbo.lastrunguid() GROUP BY groupingLevel1, groupingLevel2, groupingLevel3, environmentValue, criticalityValue, classificationValue) clas on crit.groupingLevel1 = clas.groupingLevel1 AND crit.groupingLevel2 = clas.groupingLevel2 AND crit.groupingLevel3 = gl3.groupingLevel3 AND crit.environmentValue = clas.environmentValue
FOR JSON PATH, ROOT('LeagueTable')
GO

GRANT EXECUTE ON getNestedSummaryTable001 TO [adf-ne-techdebtleague]
GO

/*
INSERT INTO 
    runTechDebtPointsScores ( 
		runGUID,
        groupingLevel1,
        groupingLevel2,
        groupingLevel3,
        environmentValue,
        criticalityValue,
		classificationValue,
        impact,
        category,
		technicalDebtPoints
	)
*/
/*
SET DATEFORMAT DMY

SELECT 
	*
FROM
(SELECT
	*
FROM
	budgets
) b LEFT JOIN
(SELECT 
	* 
FROM
	budgetHistory 
WHERE
	CAST(('01/' + CAST(budgetMonth AS CHAR(2)) + '/' + CAST(budgetYear AS CHAR(4))) AS DATETIME)  > DATEADD(month,-4, CAST(('01/' + CAST(budgetMonth AS CHAR(2)) + '/' + CAST(budgetYear AS CHAR(4))) AS DATETIME))
) bh on b.id = bh.budgetId
*/

DROP PROC IF EXISTS getTechDebtPointScores002
GO

CREATE PROC getTechDebtPointScores002 AS

DECLARE @runGUID CHAR(36) = dbo.LastRunGUID()
DECLARE @lastRunGUID CHAR(36) = (SELECT runGUID FROM (SELECT TOP 2 ROW_NUMBER() OVER(ORDER BY runDateTime DESC) AS RowNumber, runGUID FROM runSettings ORDER BY runDateTime DESC) a WHERE RowNumber = 2) 

SELECT 
    groupingLevel1,
	groupingLevel2,
	environmentValue,
	criticalityValue,
    category, 
    impact,
    COUNT(id) AS RecommendationCount, 
    SUM(technicaldebtpoints) AS TechDebtPoints 
FROM 
    runTechDebtPointsScores 
WHERE 
    runguid = @runGUID
GROUP BY 
    groupingLevel1, 
	groupingLevel2,
	environmentValue,
	criticalityValue,
    category, 
    impact 
ORDER BY 
    groupingLevel1 ASC,
	groupingLevel2 ASC,
	environmentValue ASC,
	criticalityValue ASC
FOR JSON AUTO
GO

GRANT EXECUTE ON getTechDebtPointScores002 TO [LeaderBoardApp]
GO