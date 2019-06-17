CREATE PROCEDURE [dbo].[Import_Cosmos_adviserdetails]

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
					as Adviserdetails)'
	
	SET @ParmDef = N'@retvalOUT NVARCHAR(MAX) OUTPUT';
 
	EXEC sp_executesql @ORowSet, @ParmDef, @retvalOUT=@retvalue OUTPUT;

    IF OBJECT_ID('#adviserdetails', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE #adviserdetails
		END
	ELSE
		BEGIN
			CREATE TABLE [#adviserdetails](
						 [id] [varchar](max) NULL,
						 [SubcontractorId] [VARCHAR](MAX),
						 [AdviserName] [VARCHAR](MAX) NULL,
						 [AdviserEmailAddress] [VARCHAR](MAX) NULL,
						 [AdviserContactNumber] [VARCHAR](MAX) NULL,
						 [LastModifiedDate] [VARCHAR](MAX) NULL,
						 [LastModifiedTouchpointId] [VARCHAR](MAX) NULL,
						 [CreatedBy] [varchar](max) NULL
			) ON [PRIMARY]									
		END

	INSERT INTO [#adviserdetails]
	SELECT *
	FROM OPENJSON(@retvalue)
		WITH (
			id VARCHAR(MAX) '$.id', 
			SubcontractorId VARCHAR(50) '$.SubcontractorId',
			AdviserName VARCHAR(MAX) '$.AdviserName',
			AdviserEmailAddress VARCHAR(MAX) '$.AdviserEmailAddress',
			AdviserContactNumber VARCHAR(MAX) '$.AdviserContactNumber',
			LastModifiedDate VARCHAR(MAX) '$.LastModifiedDate',
			LastModifiedTouchpointId VARCHAR(MAX) '$.LastModifiedTouchpointId',
			CreatedBy VARCHAR(MAX) '$.CreatedBy'
			) AS Coll

	
	IF OBJECT_ID('[dss-adviserdetails]', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [dss-adviserdetails]
		END
	ELSE
		BEGIN
			CREATE TABLE [dss-adviserdetails](
						 [id] UNIQUEIDENTIFIER NOT NULL,
						 [SubcontractorId] [VARCHAR](50) NULL,
						 [AdviserName] [VARCHAR](MAX) NULL,
						 [AdviserEmailAddress] [VARCHAR](MAX) NULL,
						 [AdviserContactNumber] [VARCHAR](MAX) NULL,
						 [LastModifiedDate] DATETIME2 NULL,
						 [LastModifiedTouchpointId] [VARCHAR](MAX) NULL,
						 [CreatedBy] [VARCHAR](MAX) NULL,
						 CONSTRAINT [PK_dss-adviserdetails] PRIMARY KEY ([id])) 
						 ON [PRIMARY]
		END

		INSERT INTO [dss-adviserdetails] 
				SELECT
				CONVERT(UNIQUEIDENTIFIER, [id]) AS [id],
				[SubcontractorId],
				[AdviserName],
				[AdviserEmailAddress],
				[AdviserContactNumber],
				CONVERT(datetime2, [LastModifiedDate]) as [LastModifiedDate],
				[LastModifiedTouchpointId],
				[CreatedBy]
				FROM #adviserdetails
		
		DROP TABLE #adviserdetails

END
