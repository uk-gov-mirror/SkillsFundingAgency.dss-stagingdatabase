CREATE PROCEDURE [dbo].[Change_Feed_Insert_Update_dss-customers] (@Json NVARCHAR(MAX))
AS
BEGIN
	MERGE INTO [dss-customers] AS customers
	USING (
		SELECT *
		FROM OPENJSON(@Json) WITH (
				id UNIQUEIDENTIFIER
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
		) AS InputJSON
		ON (customers.id = InputJSON.id)
	WHEN MATCHED
		THEN
			UPDATE
			SET customers.id = InputJSON.id
				,customers.SubcontractorId = InputJSON.SubcontractorId
				,customers.DateOfRegistration = InputJSON.DateOfRegistration
				,customers.Title = InputJSON.Title
				,customers.GivenName = InputJSON.GivenName
				,customers.FamilyName = InputJSON.FamilyName
				,customers.DateofBirth = InputJSON.DateofBirth
				,customers.Gender = InputJSON.Gender
				,customers.UniqueLearnerNumber = InputJSON.UniqueLearnerNumber
				,customers.OptInMarketResearch = InputJSON.OptInMarketResearch
				,customers.OptInUserResearch = InputJSON.OptInUserResearch
				,customers.DateOfTermination = InputJSON.DateOfTermination
				,customers.ReasonForTermination = InputJSON.ReasonForTermination
				,customers.IntroducedBy = InputJSON.IntroducedBy
				,customers.IntroducedByAdditionalInfo = InputJSON.IntroducedByAdditionalInfo
				,customers.LastModifiedDate = InputJSON.LastModifiedDate
				,customers.LastModifiedTouchpointId = InputJSON.LastModifiedTouchpointId
				,customers.CreatedBy = InputJSON.CreatedBy
	WHEN NOT MATCHED
		THEN
			INSERT (
				id
				,SubcontractorId
				,DateOfRegistration
				,Title
				,GivenName
				,FamilyName
				,DateofBirth
				,Gender
				,UniqueLearnerNumber
				,OptInMarketResearch
				,OptInUserResearch
				,DateOfTermination
				,ReasonForTermination
				,IntroducedBy
				,IntroducedByAdditionalInfo
				,LastModifiedDate
				,LastModifiedTouchpointId
				,CreatedBy
				)
			VALUES (
				InputJSON.id
				,InputJSON.SubcontractorId
				,InputJSON.DateOfRegistration
				,InputJSON.Title
				,InputJSON.GivenName
				,InputJSON.FamilyName
				,InputJSON.DateofBirth
				,InputJSON.Gender
				,InputJSON.UniqueLearnerNumber
				,InputJSON.OptInMarketResearch
				,InputJSON.OptInUserResearch
				,InputJSON.DateOfTermination
				,InputJSON.ReasonForTermination
				,InputJSON.IntroducedBy
				,InputJSON.IntroducedByAdditionalInfo
				,InputJSON.LastModifiedDate
				,InputJSON.LastModifiedTouchpointId
				,InputJSON.CreatedBy
				);

	exec [dbo].[insert-dss-customers-history] @Json
END