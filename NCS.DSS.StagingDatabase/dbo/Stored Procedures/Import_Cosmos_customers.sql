CREATE PROCEDURE [dbo].[Import_Cosmos_customers]

	@JsonFile NVarchar(Max),
	@DataSource NVarchar(max)
AS
BEGIN
	SET CONCAT_NULL_YIELDS_NULL OFF
	SET NOCOUNT ON
	
	DECLARE @ORowSet AS NVarchar(max)
	DECLARE @retvalue NVarchar(max)  
	DECLARE @ParmDef NVARCHAR(MAX);
	
	SET @ORowSet = '(SELECT @retvalOUT = [BulkColumn] FROM 
					OPENROWSET (BULK ''' + @JsonFile + ''', 
					DATA_SOURCE = ''' + @DataSource + ''', 
					SINGLE_CLOB) 
					as Customers)'
	
	SET @ParmDef = N'@retvalOUT NVARCHAR(MAX) OUTPUT';
 
	EXEC sp_executesql @ORowSet, @ParmDef, @retvalOUT=@retvalue OUTPUT;

    IF OBJECT_ID('#customers', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [#customers]
		END
	ELSE
		BEGIN
			CREATE TABLE [#customers](
						 [id] [varchar](max) NULL,
						 [SubcontractorId] [VARCHAR](MAX) NULL,
						 [DateOfRegistration] [VARCHAR](MAX) NULL,
						 [Title] [VARCHAR](MAX) NULL,
						 [GivenName] [VARCHAR](MAX) NULL,
						 [FamilyName] [VARCHAR](MAX) NULL,
						 [DateofBirth] [VARCHAR](MAX) NULL,
						 [Gender] [VARCHAR](MAX) NULL,
						 [UniqueLearnerNumber] [VARCHAR](MAX) NULL,
						 [OptInUserResearch] [VARCHAR](MAX) NULL,
						 [OptInMarketResearch] [VARCHAR](MAX) NULL,
						 [DateOfTermination] [VARCHAR](MAX) NULL,
						 [ReasonForTermination] [VARCHAR](MAX) NULL,
						 [IntroducedBy] [VARCHAR](MAX) NULL,
						 [IntroducedByAdditionalInfo] [VARCHAR](MAX) NULL,
						 [LastModifiedDate] [VARCHAR](MAX) NULL,
						 [LastModifiedTouchpointId] [VARCHAR](MAX) NULL,
						 [CreatedBy] [varchar](max) NULL
			) ON [PRIMARY]									
		END

	INSERT INTO [#customers]
	SELECT *
	FROM OPENJSON(@retvalue)
		WITH (
			id VARCHAR(MAX) '$.id', 
			SubcontractorId VARCHAR(MAX) '$.SubcontractorId',
			DateOfRegistration VARCHAR(MAX) '$.DateOfRegistration',
			Title VARCHAR(MAX) '$.Title',
			GivenName VARCHAR(MAX) '$.GivenName',
			FamilyName VARCHAR(MAX) '$.FamilyName',
			DateofBirth VARCHAR(MAX) '$.DateofBirth',
			Gender VARCHAR(MAX) '$.Gender',
			UniqueLearnerNumber VARCHAR(MAX) '$.UniqueLearnerNumber',
			OptInMarketResearch VARCHAR(MAX) '$.OptInMarketResearch',
			OptInUserResearch VARCHAR(MAX) '$.OptInUserResearch',
			DateOfTermination VARCHAR(MAX) '$.DateOfTermination',
			ReasonForTermination VARCHAR(MAX) '$.ReasonForTermination',
			IntroducedBy VARCHAR(MAX) '$.IntroducedBy',
			IntroducedByAdditionalInfo VARCHAR(MAX) '$.IntroducedByAdditionalInfo',
			LastModifiedDate VARCHAR(MAX) '$.LastModifiedDate',
			LastModifiedTouchpointId VARCHAR(MAX) '$.LastModifiedTouchpointId',
			CreatedBy VARCHAR(MAX) '$.CreatedBy'
			) AS Coll

	IF OBJECT_ID('[dss-customers]', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [dss-customers]
		END
	ELSE
		BEGIN
			CREATE TABLE [dss-customers](
						 [id] UNIQUEIDENTIFIER NOT NULL,
						 [SubcontractorId] VARCHAR(50) NULL,
						 [DateOfRegistration] DATETIME2 NULL,
						 [Title] INT NULL,
						 [GivenName] [VARCHAR](MAX) NULL,
						 [FamilyName] [VARCHAR](MAX) NULL,
						 [DateofBirth] DATETIME2 NULL,
						 [Gender] INT NULL,
						 [UniqueLearnerNumber] [VARCHAR](15) NULL,
						 [OptInMarketResearch] BIT NULL,
						 [OptInUserResearch] BIT NULL,
						 [DateOfTermination] DATETIME2 NULL,
						 [ReasonForTermination] INT NULL,
						 [IntroducedBy] INT NULL,
						 [IntroducedByAdditionalInfo] [VARCHAR](MAX) NULL,
						 [LastModifiedDate] DATETIME2 NULL,
						 [LastModifiedTouchpointId] [VARCHAR](MAX) NULL,
						 [CreatedBy] [VARCHAR](MAX) NULL,
						 CONSTRAINT [PK_dss-customers] PRIMARY KEY ([id])) 
						 ON [PRIMARY]	
		END

		INSERT INTO [dss-customers] 
				SELECT
				CONVERT(UNIQUEIDENTIFIER, [id]) AS [id],
				[SubcontractorId],
				CONVERT(datetime2, [DateOfRegistration]) as [DateOfRegistration],
				CONVERT(int, [Title]) as [Title],
				[GivenName],
				[FamilyName],
				CONVERT(datetime2, [DateOfBirth]) as [DateOfBirth],
				CONVERT(int, [Gender]) as [Gender],
				[UniqueLearnerNumber],
				CONVERT(bit, [OptInMarketResearch]) as [OptInMarketResearch],
				CONVERT(bit, [OptInUserResearch]) as [OptInUserResearch],
				CONVERT(datetime2, [DateOfTermination]) as [DateOfTermination],
				CONVERT(int, [ReasonForTermination]) as [ReasonForTermination],
				CONVERT(int, [IntroducedBy]) as [IntroducedBy],
				[IntroducedByAdditionalInfo],
				CONVERT(datetime2, [LastModifiedDate]) as [LastModifiedDate],
				[LastModifiedTouchpointId],
				[CreatedBy]
				FROM #customers

		DROP TABLE #customers

END
