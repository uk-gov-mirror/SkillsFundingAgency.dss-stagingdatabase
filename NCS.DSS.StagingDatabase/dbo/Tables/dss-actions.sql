CREATE TABLE [dbo].[dss-actions] (
    [id]                            UNIQUEIDENTIFIER NOT NULL,
    [CustomerId]                    UNIQUEIDENTIFIER NULL,	
    [ActionPlanId]                  UNIQUEIDENTIFIER NULL,
	[SubcontractorId]				VARCHAR(50) NULL,
    [DateActionAgreed]              datetime2         NULL,
    [DateActionAimsToBeCompletedBy] datetime2         NULL,
    [DateActionActuallyCompleted]   datetime2         NULL,
    [ActionSummary]                 VARCHAR (max)     NULL,
    [SignpostedTo]                  VARCHAR (max)     NULL,
    [ActionType]                    INT              NULL,
    [ActionStatus]                  INT              NULL,
    [PersonResponsible]             INT              NULL,
    [LastModifiedDate]              VARCHAR (max)     NULL,
    [LastModifiedTouchpointId]      VARCHAR (max)     NULL, 
	[CreatedBy]					    VARCHAR (max)     NULL, 
    CONSTRAINT [PK_dss-actions] PRIMARY KEY ([id])
);

