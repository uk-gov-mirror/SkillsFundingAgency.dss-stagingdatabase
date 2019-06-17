CREATE PROCEDURE [dbo].[insert-dss-customers-history] (@Json NVARCHAR(MAX))
AS
BEGIN
	INSERT INTO [dss-customers-history]
		SELECT DATEADD(MINUTE, _ts/60, DATEADD(SECOND, _ts%60, '19700101')) as CosmosTimeStamp, id, SubcontractorId, DateOfRegistration, Title, GivenName, FamilyName,
		       DateofBirth, Gender, UniqueLearnerNumber, OptInMarketResearch, OptInUserResearch, DateOfTermination, ReasonForTermination, IntroducedBy,
			   IntroducedByAdditionalInfo, LastModifiedDate, LastModifiedTouchpointId, CreatedBy
			FROM OPENJSON(@Json) WITH (
				_ts BIGINT
				,id UNIQUEIDENTIFIER
				,SubcontractorId VARCHAR(Max)
				,DateOfRegistration DATETIME2
				,Title INT
				,GivenName VARCHAR(max)
				,FamilyName VARCHAR(max)
				,DateofBirth DATETIME2
				,Gender INT
				,UniqueLearnerNumber VARCHAR(Max)
				,OptInMarketResearch BIT
				,OptInUserResearch BIT
				,DateOfTermination DATETIME2
				,ReasonForTermination INT
				,IntroducedBy INT
				,IntroducedByAdditionalInfo VARCHAR(Max)
				,LastModifiedDate DATETIME2
				,LastModifiedTouchpointId VARCHAR(max)
				,CreatedBy VARCHAR(MAX)
				)
END