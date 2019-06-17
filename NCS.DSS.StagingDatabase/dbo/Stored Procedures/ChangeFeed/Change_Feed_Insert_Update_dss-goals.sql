CREATE PROCEDURE [dbo].[Change_Feed_Insert_Update_dss-goals] (@Json NVARCHAR(MAX))
AS
BEGIN
	MERGE INTO [dss-goals] AS goals
	USING (
		SELECT *
		FROM OPENJSON(@Json) WITH (
				id UNIQUEIDENTIFIER
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
		) AS InputJSON
		ON (goals.id = InputJSON.id)
	WHEN MATCHED
		THEN
			UPDATE
			SET goals.id = InputJSON.id
			    ,goals.CustomerId = InputJSON.CustomerId
				,goals.ActionPlanId = InputJSON.ActionPlanId
				,goals.SubcontractorId = InputJSON.SubcontractorId
				,goals.DateGoalCaptured = InputJSON.DateGoalCaptured
				,goals.DateGoalShouldBeCompletedBy = InputJSON.DateGoalShouldBeCompletedBy
				,goals.DateGoalAchieved = InputJSON.DateGoalAchieved
				,goals.GoalSummary = InputJSON.GoalSummary
				,goals.GoalType = InputJSON.GoalType
				,goals.GoalStatus = InputJSON.GoalStatus
				,goals.LastModifiedDate = InputJSON.LastModifiedDate
				,goals.LastModifiedBy = InputJSON.LastModifiedBy
				,goals.CreatedBy = InputJSON.CreatedBy
	WHEN NOT MATCHED
		THEN
			INSERT (
				id
				,CustomerId
				,ActionPlanId
				,SubcontractorId
				,DateGoalCaptured
				,DateGoalShouldBeCompletedBy
				,DateGoalAchieved
				,GoalSummary
				,GoalType
				,GoalStatus
				,LastModifiedDate
				,LastModifiedBy
				,CreatedBy
				)
			VALUES (
				InputJSON.id
				,InputJSON.CustomerId
				,InputJSON.ActionPlanId
				,InputJSON.SubcontractorId
				,InputJSON.DateGoalCaptured
				,InputJSON.DateGoalShouldBeCompletedBy
				,InputJSON.DateGoalAchieved
				,InputJSON.GoalSummary
				,InputJSON.GoalType
				,InputJSON.GoalStatus
				,InputJSON.LastModifiedDate
				,InputJSON.LastModifiedBy
				,InputJSON.CreatedBy
				);

	exec [dbo].[insert-dss-goals-history] @Json
END