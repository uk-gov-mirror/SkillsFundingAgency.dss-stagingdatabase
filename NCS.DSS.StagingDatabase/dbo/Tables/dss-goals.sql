CREATE TABLE [dbo].[dss-goals] (
    [id]                          UNIQUEIDENTIFIER NOT NULL,
    [CustomerId]                  UNIQUEIDENTIFIER NULL,
    [ActionPlanId]                UNIQUEIDENTIFIER NULL,
	[SubcontractorId]			  VARCHAR(50)	   NULL,
    [DateGoalCaptured]            datetime2         NULL,
    [DateGoalShouldBeCompletedBy] datetime2         NULL,
    [DateGoalAchieved]            datetime2         NULL,
    [GoalSummary]                 VARCHAR (max)     NULL,
    [GoalType]                    INT               NULL,
    [GoalStatus]                  INT               NULL,
    [LastModifiedDate]            datetime2         NULL,
    [LastModifiedBy]			  VARCHAR (max)     NULL, 
	[CreatedBy]					  VARCHAR (max)     NULL, 
    CONSTRAINT [PK_dss-goals] PRIMARY KEY ([id])
);

