CREATE TABLE [dbo].[dss-goals-history](
	[HistoryId] [int] IDENTITY(1,1) NOT NULL,
	[CosmosTimeStamp] [datetime2](7) NOT NULL,
	[id] [uniqueidentifier] NOT NULL,
	[CustomerId] [uniqueidentifier] NULL,
	[ActionPlanId] [uniqueidentifier] NULL,
	[SubcontractorId] [varchar](50) NULL,
	[DateGoalCaptured] [datetime2](7) NULL,
	[DateGoalShouldBeCompletedBy] [datetime2](7) NULL,
	[DateGoalAchieved] [datetime2](7) NULL,
	[GoalSummary] [varchar](max) NULL,
	[GoalType] [int] NULL,
	[GoalStatus] [int] NULL,
	[LastModifiedDate] [datetime2](7) NULL,
	[LastModifiedBy] [varchar](max) NULL,
	[CreatedBy]	[varchar](max) NULL,
 CONSTRAINT [PK_dss-goals-history] PRIMARY KEY CLUSTERED 
(
	[HistoryId] ASC,
	[CosmosTimeStamp] ASC,
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

