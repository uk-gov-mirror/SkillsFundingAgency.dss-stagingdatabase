CREATE TABLE [dbo].[dss-adviserdetails] (
    [id]                       UNIQUEIDENTIFIER NOT NULL,
	[SubcontractorId]		   VARCHAR(50) NULL,
    [AdviserName]              VARCHAR (max)     NULL,
    [AdviserEmailAddress]      VARCHAR (max)     NULL,
    [AdviserContactNumber]     VARCHAR (max)     NULL,
    [LastModifiedDate]         datetime2         NULL,
    [LastModifiedTouchpointId] VARCHAR (max)     NULL, 
	[CreatedBy]				   VARCHAR (max)     NULL, 
    CONSTRAINT [PK_dss-adviserdetails] PRIMARY KEY ([id])
);

