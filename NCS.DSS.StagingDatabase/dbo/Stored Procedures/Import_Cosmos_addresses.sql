CREATE PROCEDURE [dbo].[Import_Cosmos_addresses]

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
					as Addresses)'
	
	SET @ParmDef = N'@retvalOUT NVARCHAR(MAX) OUTPUT';
 
	EXEC sp_executesql @ORowSet, @ParmDef, @retvalOUT=@retvalue OUTPUT;

    IF OBJECT_ID('#addresses', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE #addresses
		END
	ELSE
		BEGIN
			CREATE TABLE [#addresses](
						 [id] [varchar](max),
						 [CustomerId] [varchar](max) NULL,
						 [SubcontractorId] [varchar](MAX) NULL,
						 [Address1] [VARCHAR](MAX) NULL,
						 [Address2] [VARCHAR](MAX) NULL,
						 [Address3] [VARCHAR](MAX) NULL,
						 [Address4] [VARCHAR](MAX) NULL,
						 [Address5] [VARCHAR](MAX) NULL,
						 [PostCode] [VARCHAR](MAX) NULL,
						 [AlternativePostCode] [VARCHAR](MAX) NULL,
						 [Longitude] [VARCHAR](MAX) NULL,
						 [Latitude] [VARCHAR](MAX) NULL,
						 [EffectiveFrom] [VARCHAR](MAX) NULL,
						 [EffectiveTo] [VARCHAR](MAX) NULL,
						 [LastModifiedDate] [VARCHAR](MAX) NULL,
						 [LastModifiedTouchpointId] [VARCHAR](MAX) NULL,
						 [CreatedBy] [varchar](max) NULL
			) ON [PRIMARY]									
		END

	INSERT INTO [#addresses]
	SELECT *
	FROM OPENJSON(@retvalue)
		WITH (
			id VARCHAR(MAX) '$.id', 
			CustomerId VARCHAR(MAX) '$.CustomerId',
			SubContractorId VARCHAR(MAX) '$.SubcontractorId',
			Address1 VARCHAR(MAX) '$.Address1',
			Address2 VARCHAR(MAX) '$.Address2',
			Address3 VARCHAR(MAX) '$.Address3',
			Address4 VARCHAR(MAX) '$.Address4',
			Address5 VARCHAR(MAX) '$.Address5',
			PostCode VARCHAR(MAX) '$.PostCode',
			AlternativePostCode VARCHAR(MAX) '$.AlternativePostCode',
			Longitude VARCHAR(MAX) '$.Longitude',
			Latitude VARCHAR(MAX) '$.Latitude',
			EffectiveFrom VARCHAR(MAX) '$.EffectiveFrom',
			EffectiveTo VARCHAR(MAX) '$.EffectiveTo',
			LastModifiedDate VARCHAR(MAX) '$.LastModifiedDate',
			LastModifiedTouchpointId VARCHAR(MAX) '$.LastModifiedTouchpointId',
			CreatedBy VARCHAR(MAX) '$.CreatedBy'
			) AS Coll




	IF OBJECT_ID('[dss-addresses]', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [dss-addresses]
		END
	ELSE
		BEGIN
			CREATE TABLE [dss-addresses](
						 [id] UNIQUEIDENTIFIER NOT NULL,
						 [CustomerId] UNIQUEIDENTIFIER NULL,
						 [SubcontractorId] [VARCHAR](50) NULL,
						 [Address1] [VARCHAR](MAX) NULL,
						 [Address2] [VARCHAR](MAX) NULL,
						 [Address3] [VARCHAR](MAX) NULL,
						 [Address4] [VARCHAR](MAX) NULL,
						 [Address5] [VARCHAR](MAX) NULL,
						 [PostCode] [VARCHAR](MAX) NULL,
						 [AlternativePostCode] [VARCHAR](20) NULL,
						 [Longitude] FLOAT NULL,
						 [Latitude] FLOAT NULL,
						 [EffectiveFrom] DATETIME2 NULL,
						 [EffectiveTo] DATETIME2 NULL,
						 [LastModifiedDate] DATETIME2 NULL,
						 [LastModifiedTouchpointId] [VARCHAR](MAX),
						 [CreatedBy] [VARCHAR](MAX) NULL,
						 CONSTRAINT [PK_dss-addresses] PRIMARY KEY ([id])) 
						 ON [PRIMARY]							
		END

		INSERT INTO [dss-addresses] 
				SELECT
				CONVERT(UNIQUEIDENTIFIER, [id]) AS [id],
				CONVERT(UNIQUEIDENTIFIER, [CustomerId]) AS [CustomerId],
				[SubcontractorId],
				[Address1],
				[Address2],
				[Address3],
				[Address4],
				[Address5], 
				[PostCode],
				[AlternativePostCode],
				CONVERT(float, [Longitude]) as [Longitude],
				CONVERT(float, [Latitude]) as [Latitude],
				CONVERT(datetime2, [EffectiveFrom]) as [EffectiveFrom],
				CONVERT(datetime2, [EffectiveTo]) as [EffectiveTo],
				CONVERT(datetime2, [LastModifiedDate]) as [LastModifiedDate],
				[LastModifiedTouchpointId],
				[CreatedBy]
				FROM #addresses

		DROP TABLE #addresses

END
