CREATE TABLE [dbo].[dss-adviserdetails-history](
	[HistoryId] [int] IDENTITY(1,1) NOT NULL,
	[CosmosTimeStamp] [datetime2](7) NOT NULL,
	[id] [uniqueidentifier] NOT NULL,
	[SubcontractorId] [varchar](50) NULL,
	[AdviserName] [varchar](max) NULL,
	[AdviserEmailAddress] [varchar](max) NULL,
	[AdviserContactNumber] [varchar](max) NULL,
	[LastModifiedDate] [datetime2](7) NULL,
	[LastModifiedTouchpointId] [varchar](max) NULL,
	[CreatedBy]	[varchar](max) NULL,
 CONSTRAINT [PK_dss-adviserdetails-history] PRIMARY KEY CLUSTERED 
(
	[HistoryId] ASC,
	[CosmosTimeStamp] ASC,
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

