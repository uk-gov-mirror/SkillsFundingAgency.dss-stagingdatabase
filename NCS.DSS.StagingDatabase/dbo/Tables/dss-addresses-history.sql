CREATE TABLE [dbo].[dss-addresses-history](
	[HistoryId] [int] IDENTITY(1,1) NOT NULL,
	[CosmosTimeStamp] [datetime2](7) NOT NULL,
	[id] [uniqueidentifier] NOT NULL,
	[CustomerId] [uniqueidentifier] NULL,
	[SubcontractorId] [varchar](50) NULL,
	[Address1] [varchar](max) NULL,
	[Address2] [varchar](max) NULL,
	[Address3] [varchar](max) NULL,
	[Address4] [varchar](max) NULL,
	[Address5] [varchar](max) NULL,
	[PostCode] [varchar](max) NULL,
	[AlternativePostCode] [varchar](max) NULL,
	[Longitude] [float] NULL,
	[Latitude] [float] NULL,
	[EffectiveFrom] [datetime2](7) NULL,
	[EffectiveTo] [datetime2](7) NULL,
	[LastModifiedDate] [datetime2](7) NULL,
	[LastModifiedTouchpointId] [varchar](max) NULL,
	[CreatedBy]	[varchar](max) NULL,
 CONSTRAINT [PK_dss-addresses-history] PRIMARY KEY CLUSTERED 
(
	[HistoryId] ASC,
	[CosmosTimeStamp] ASC,
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

