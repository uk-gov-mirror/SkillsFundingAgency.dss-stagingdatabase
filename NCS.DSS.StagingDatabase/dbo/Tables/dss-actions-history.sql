CREATE TABLE [dbo].[dss-actions-history](
	[HistoryId] [int] IDENTITY(1,1) NOT NULL,
	[CosmosTimeStamp] [datetime2](7) NOT NULL,
	[id] [uniqueidentifier] NOT NULL,
	[CustomerId] [uniqueidentifier] NULL,
	[ActionPlanId] [uniqueidentifier] NULL,
	[SubcontractorId] [varchar](50) NULL,
	[DateActionAgreed] [datetime2](7) NULL,
	[DateActionAimsToBeCompletedBy] [datetime2](7) NULL,
	[DateActionActuallyCompleted] [datetime2](7) NULL,
	[ActionSummary] [varchar](max) NULL,
	[SignpostedTo] [varchar](max) NULL,
	[ActionType] [int] NULL,
	[ActionStatus] [int] NULL,
	[PersonResponsible] [int] NULL,
	[LastModifiedDate] [varchar](max) NULL,
	[LastModifiedTouchpointId] [varchar](max) NULL,
	[CreatedBy]	[varchar](max) NULL,
 CONSTRAINT [PK_dss-actions-history] PRIMARY KEY CLUSTERED 
(
	[HistoryId] ASC,
	[CosmosTimeStamp] ASC,
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

