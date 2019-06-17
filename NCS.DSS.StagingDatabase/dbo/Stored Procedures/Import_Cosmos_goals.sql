CREATE PROCEDURE [dbo].[Import_Cosmos_goals]

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
					as Goals)'
	
	SET @ParmDef = N'@retvalOUT NVARCHAR(MAX) OUTPUT';
 
	EXEC sp_executesql @ORowSet, @ParmDef, @retvalOUT=@retvalue OUTPUT;

    IF OBJECT_ID('#goals', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE #goals
		END
	ELSE
		BEGIN
			CREATE TABLE [#goals](
						 [id] [varchar](max) NULL,
						 [CustomerId] [varchar](max) NULL,
						 [ActionPlanId] [varchar](max) NULL,
						 [SubcontractorId] [VARCHAR](MAX) NULL,
						 [DateGoalCaptured] [VARCHAR](MAX) NULL,
						 [DateGoalShouldBeCompletedBy] [VARCHAR](MAX) NULL,
						 [DateGoalAchieved] [VARCHAR](MAX) NULL,
						 [GoalSummary] [VARCHAR](MAX) NULL,
						 [GoalType] [VARCHAR](MAX) NULL,
						 [GoalStatus] [VARCHAR](MAX) NULL,						 
						 [LastModifiedDate] [VARCHAR](MAX) NULL,
						 [LastModifiedBy] [VARCHAR](MAX) NULL,
						 [CreatedBy] [varchar](max) NULL
			) ON [PRIMARY]									
		END

	INSERT INTO [#goals]
	SELECT *
	FROM OPENJSON(@retvalue)
		WITH (
			id VARCHAR(MAX) '$.id', 
			CustomerId VARCHAR(MAX) '$.CustomerId',
			ActionPlanId VARCHAR(MAX) '$.ActionPlanId',
			SubcontractorId VARCHAR(MAX) '$.SubcontractorId',
			DateGoalCaptured VARCHAR(MAX) '$.DateGoalCaptured',
			DateGoalShouldBeCompletedBy VARCHAR(MAX) '$.DateGoalShouldBeCompletedBy',
			DateGoalAchieved VARCHAR(MAX) '$.DateGoalAchieved',
			GoalSummary VARCHAR(MAX) '$.GoalSummary',
			GoalType VARCHAR(MAX) '$.GoalType',
			GoalStatus VARCHAR(MAX) '$.GoalStatus',
			LastModifiedDate VARCHAR(MAX) '$.LastModifiedDate',
			LastModifiedBy VARCHAR(MAX) '$.LastModifiedTouchpointId',
			CreatedBy VARCHAR(MAX) '$.CreatedBy'
			) AS Coll

	IF OBJECT_ID('[dss-goals]', 'U') IS NOT NULL 
		BEGIN
			TRUNCATE TABLE [dss-goals]
		END
	ELSE
		BEGIN
			CREATE TABLE [dss-goals](
						 [id] UNIQUEIDENTIFIER NOT NULL,
						 [CustomerId] UNIQUEIDENTIFIER NULL,						 
						 [ActionPlanId] UNIQUEIDENTIFIER NULL,
						 [SubcontractorId] VARCHAR(50) NULL,
						 [DateGoalCaptured] DATETIME2 NULL,
						 [DateGoalShouldBeCompletedBy] DATETIME2 NULL,
						 [DateGoalAchieved] DATETIME2 NULL,
						 [GoalSummary] [VARCHAR](MAX) NULL,
						 [GoalType] INT NULL,
						 [GoalStatus] INT NULL,						 
						 [LastModifiedDate] DATETIME2 NULL,
						 [LastModifiedBy] [VARCHAR](MAX) NULL,
						 [CreatedBy] [VARCHAR](MAX) NULL,
						 CONSTRAINT [PK_dss-goals] PRIMARY KEY ([id])) 
						 ON [PRIMARY]
		END

		INSERT INTO [dss-goals] 
				SELECT
				CONVERT(UNIQUEIDENTIFIER, [id]) AS [id],
				CONVERT(UNIQUEIDENTIFIER, [CustomerId]) AS [CustomerId],				
				CONVERT(UNIQUEIDENTIFIER, [ActionPlanId]) AS [ActionPlanId],
				[SubContractorId],
				CONVERT(datetime2, [DateGoalCaptured]) as [DateGoalCaptured],
				CONVERT(datetime2, [DateGoalShouldBeCompletedBy]) as [DateGoalShouldBeCompletedBy],
				CONVERT(datetime2, [DateGoalAchieved]) as [DateGoalAchieved],
				[GoalSummary],
				CONVERT(int, [GoalType]) as [GoalType],
				CONVERT(int, [GoalStatus]) as [GoalStatus],
				CONVERT(datetime2, [LastModifiedDate]) as [LastModifiedDate],
				[LastModifiedBy],
				[CreatedBy]
				FROM #goals

		DROP TABLE #goals

END
