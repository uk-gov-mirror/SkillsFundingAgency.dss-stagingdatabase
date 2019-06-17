CREATE PROCEDURE [dbo].[Change_Feed_Insert_Update_dss-actions] (@Json NVARCHAR(MAX))
AS
BEGIN
	MERGE INTO [dss-actions] AS actions
	USING (
		SELECT *
		FROM OPENJSON(@Json) WITH (
				id UNIQUEIDENTIFIER
				,CustomerId UNIQUEIDENTIFIER
				,ActionPlanId UNIQUEIDENTIFIER
				,SubcontractorId VARCHAR(50)
				,DateActionAgreed DATETIME2
				,DateActionAimsToBeCompletedBy DATETIME2
				,DateActionActuallyCompleted DATETIME2
				,ActionSummary VARCHAR(max)
				,SignpostedTo VARCHAR(max)
				,ActionType INT
				,ActionStatus INT
				,PersonResponsible INT
				,LastModifiedDate DATETIME2
				,LastModifiedTouchpointId VARCHAR(max)
				,CreatedBy VARCHAR(MAX)
				)
		) AS InputJSON
		ON (actions.id = InputJSON.id)
	WHEN MATCHED
		THEN
			UPDATE
			SET actions.id = InputJSON.id 
				,actions.CustomerId = InputJSON.CustomerId
				,actions.ActionPlanId = InputJSON.ActionPlanId
				,actions.SubcontractorId = InputJSON.SubcontractorId
				,actions.DateActionAgreed = InputJSON.DateActionAgreed
				,actions.DateActionAimsToBeCompletedBy = InputJSON.DateActionAimsToBeCompletedBy
				,actions.DateActionActuallyCompleted = InputJSON.DateActionActuallyCompleted
				,actions.ActionSummary = InputJSON.ActionSummary
				,actions.SignpostedTo = InputJSON.SignpostedTo
				,actions.ActionType = InputJSON.ActionType
				,actions.ActionStatus = InputJSON.ActionStatus
				,actions.PersonResponsible = InputJSON.PersonResponsible
				,actions.LastModifiedDate = InputJSON.LastModifiedDate
				,actions.LastModifiedTouchpointId = InputJSON.LastModifiedTouchpointId
				,actions.CreatedBy = InputJSON.CreatedBy
	WHEN NOT MATCHED
		THEN
			INSERT (
				id
				,CustomerId
				,ActionPlanId
				,SubcontractorId
				,DateActionAgreed
				,DateActionAimsToBeCompletedBy
				,DateActionActuallyCompleted
				,ActionSummary
				,SignpostedTo
				,ActionType
				,ActionStatus
				,PersonResponsible
				,LastModifiedDate
				,LastModifiedTouchpointId
				,CreatedBy
				)
			VALUES (
				InputJSON.id
				,InputJSON.CustomerId
				,InputJSON.ActionPlanId
				,InputJSON.SubcontractorId
				,InputJSON.DateActionAgreed
				,InputJSON.DateActionAimsToBeCompletedBy
				,InputJSON.DateActionActuallyCompleted
				,InputJSON.ActionSummary
				,InputJSON.SignpostedTo
				,InputJSON.ActionType
				,InputJSON.ActionStatus
				,InputJSON.PersonResponsible
				,InputJSON.LastModifiedDate
				,InputJSON.LastModifiedTouchpointId
				,InputJSON.CreatedBy
				);

	exec [insert-dss-actions-history] @Json
END