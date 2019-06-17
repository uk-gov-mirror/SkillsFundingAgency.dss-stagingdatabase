CREATE PROCEDURE [dbo].[insert-dss-actions-history] (@Json NVARCHAR(MAX))
AS
BEGIN
	INSERT INTO [dss-actions-history]
	SELECT DATEADD(MINUTE, _ts/60, DATEADD(SECOND, _ts%60, '19700101')) as CosmosTimeStamp, id, CustomerId, ActionPlanId, SubcontractorId, DateActionAgreed, DateActionAimsToBeCompletedBy,
		   DateActionActuallyCompleted, ActionSummary, SignpostedTo, ActionType, ActionStatus, PersonResponsible, LastModifiedDate, LastModifiedTouchpointId, CreatedBy
		FROM OPENJSON(@Json) WITH (
		        _ts BIGINT
				,id UNIQUEIDENTIFIER
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
END