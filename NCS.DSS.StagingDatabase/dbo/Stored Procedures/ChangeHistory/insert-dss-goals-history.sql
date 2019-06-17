CREATE PROCEDURE [dbo].[insert-dss-goals-history] (@Json NVARCHAR(MAX))
AS
BEGIN
	INSERT INTO [dss-goals-history]
		SELECT DATEADD(MINUTE, _ts/60, DATEADD(SECOND, _ts%60, '19700101')) as CosmosTimeStamp, id, CustomerId, ActionPlanId, SubcontractorId, DateGoalCaptured, DateGoalShouldBeCompletedBy,
		       DateGoalAchieved, GoalSummary, GoalType, GoalStatus, LastModifiedDate, LastModifiedBy, CreatedBy
			FROM OPENJSON(@Json) WITH (
				_ts BIGINT
				,id UNIQUEIDENTIFIER
				,CustomerId UNIQUEIDENTIFIER
				,ActionPlanId UNIQUEIDENTIFIER
				,SubcontractorId VARCHAR(50)
				,DateGoalCaptured DATETIME2
				,DateGoalShouldBeCompletedBy DATETIME2
				,DateGoalAchieved DATETIME2
				,GoalSummary VARCHAR(max)
				,GoalType VARCHAR(max)
				,GoalStatus INT
				,LastModifiedDate DATETIME2
				,LastModifiedBy VARCHAR(max)
				,CreatedBy VARCHAR(MAX)
				)
END