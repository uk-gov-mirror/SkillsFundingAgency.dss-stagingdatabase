CREATE PROCEDURE [dbo].[Import_Cosmos_actions]

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
					as Actions)'

	SET @ParmDef = N'@retvalOUT NVARCHAR(MAX) OUTPUT';
 
	EXEC sp_executesql @ORowSet, @ParmDef, @retvalOUT=@retvalue OUTPUT;

    IF OBJECT_ID('#actions', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE #actions
		END
	ELSE
		BEGIN
			CREATE TABLE [#actions](
						 [id] [varchar](max) NULL,
						 [CustomerId] [varchar](max) NULL,						 
						 [ActionPlanId] [varchar](max) NULL,
						 [SubContractorId] [varchar](max) NULL,
						 [DateActionAgreed] [varchar](max) NULL,
						 [DateActionAimsToBeCompletedBy] [varchar](max) NULL,
						 [DateActionActuallyCompleted] [varchar](max) NULL,
						 [ActionSummary] [varchar](max) NULL,
						 [SignpostedTo] [varchar](max) NULL,
						 [ActionType] [varchar](max) NULL,
						 [ActionStatus] [varchar](max) NULL,
						 [PersonResponsible] [varchar](max) NULL,
						 [LastModifiedDate] [varchar](max) NULL,
						 [LastModifiedTouchpointId] [varchar](max) NULL,
						 [CreatedBy] [varchar](max) NULL
			) ON [PRIMARY]									
		END

	INSERT INTO [#actions]
	SELECT *
	FROM OPENJSON(@retvalue)
		WITH (
			id VARCHAR(MAX) '$.id', 
			CustomerId VARCHAR(MAX) '$.CustomerId',			
			ActionPlanId VARCHAR(MAX) '$.ActionPlanId',
			SubcontractorId VARCHAR(MAX) '$.SubcontractorId',
			DateActionAgreed VARCHAR(MAX) '$.DateActionAgreed',
			DateActionAimsToBeCompletedBy VARCHAR(MAX) '$.DateActionAimsToBeCompletedBy',
			DateActionActuallyCompleted VARCHAR(MAX) '$.DateActionActuallyCompleted',
			ActionSummary VARCHAR(MAX) '$.ActionSummary',
			SignpostedTo VARCHAR(MAX) '$.SignpostedTo',
			ActionType VARCHAR(MAX) '$.ActionType',
			ActionStatus VARCHAR(MAX) '$.ActionStatus',
			PersonResponsible VARCHAR(MAX) '$.PersonResponsible',
			LastModifiedDate VARCHAR(MAX) '$.LastModifiedDate',
			LastModifiedTouchpointId VARCHAR(MAX) '$.LastModifiedTouchpointId',
			CreatedBy VARCHAR(MAX) '$.CreatedBy'
			) as Coll

	
	IF OBJECT_ID('[dss-actions]', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [dss-actions]
		END
	ELSE
		BEGIN
			CREATE TABLE [dss-actions](
						 [id] uniqueidentifier NOT NULL,
						 [CustomerId] uniqueidentifier NULL,						 
						 [ActionPlanId] uniqueidentifier NULL,
						 [SubcontractorId] varchar(50) NULL,
						 [DateActionAgreed] datetime2 NULL,
						 [DateActionAimsToBeCompletedBy] datetime2 NULL,
						 [DateActionActuallyCompleted] datetime2 NULL,
						 [ActionSummary] [varchar](max) NULL,
						 [SignpostedTo] [varchar](max) NULL,
						 [ActionType] int NULL,
						 [ActionStatus] int NULL,
						 [PersonResponsible] int NULL,
						 [LastModifiedDate] [varchar](max) NULL,
						 [LastModifiedTouchpointId] [varchar](max) NULL,
						 [CreatedBy] [VARCHAR](MAX) NULL,
						 CONSTRAINT [PK_dss-actions] PRIMARY KEY ([id])) 
						 ON [PRIMARY]					
		END

		INSERT INTO [dss-actions] 
				SELECT
				CONVERT(uniqueidentifier, [id]) as [id],
				CONVERT(uniqueidentifier, [CustomerId]) as [CustomerId],				
				CONVERT(uniqueidentifier, [ActionPlanId]) as [ActionPlanId],
				[SubcontractorId],
				CONVERT(datetime2, [DateActionAgreed]) as [DateActionAgreed],
				CONVERT(datetime2, [DateActionAimsToBeCompletedBy]) as [DateActionAimsToBeCompletedBy],
				CONVERT(datetime2, [DateActionActuallyCompleted]) as [DateActionActuallyCompleted],
				[ActionSummary],
				[SignpostedTo],
				CONVERT(int, [ActionType]) as [ActionType],
				CONVERT(int, [ActionStatus]) as [ActionStatus],
				CONVERT(int, [PersonResponsible]) as [PersonResponsible],
				CONVERT(datetime2, [LastModifiedDate]) as [LastModifiedDate],
				[LastModifiedTouchpointId],
				[CreatedBy]
				FROM #actions


		DROP TABLE #actions

END
