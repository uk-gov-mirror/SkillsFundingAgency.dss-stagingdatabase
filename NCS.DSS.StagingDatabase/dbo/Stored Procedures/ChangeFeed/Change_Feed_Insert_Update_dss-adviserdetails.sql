CREATE PROCEDURE [dbo].[Change_Feed_Insert_Update_dss-adviserdetails] (@Json NVARCHAR(MAX))
AS
BEGIN
	MERGE INTO [dss-adviserdetails] AS adviserdetails
	USING (
		SELECT *
		FROM OPENJSON(@Json) WITH (
				id UNIQUEIDENTIFIER
				,SubcontractorId VARCHAR(max)
				,AdviserName VARCHAR(Max)
				,AdviserEmailAddress VARCHAR(Max)
				,AdviserContactNumber VARCHAR(max)
				,LastModifiedDate DATETIME2
				,LastModifiedTouchpointId VARCHAR(max)
				,CreatedBy VARCHAR(MAX)
				)
		) AS InputJSON
		ON (adviserdetails.id = InputJSON.id)
	WHEN MATCHED
		THEN
			UPDATE
			SET adviserdetails.id = InputJSON.id
				,adviserdetails.SubcontractorId = InputJSON.SubcontractorId
				,adviserdetails.AdviserName = InputJSON.AdviserName
				,adviserdetails.AdviserEmailAddress = InputJSON.AdviserEmailAddress
				,adviserdetails.AdviserContactNumber = InputJSON.AdviserContactNumber
				,adviserdetails.LastModifiedDate = InputJSON.LastModifiedDate
				,adviserdetails.LastModifiedTouchpointId = InputJSON.LastModifiedTouchpointId
				,adviserdetails.CreatedBy = InputJSON.CreatedBy
	WHEN NOT MATCHED
		THEN
			INSERT (
				id
				,SubcontractorId
				,AdviserName
				,AdviserEmailAddress
				,AdviserContactNumber
				,LastModifiedDate
				,LastModifiedTouchpointId
				,CreatedBy
				)
			VALUES (
				InputJSON.id
				,InputJSON.SubcontractorId
				,InputJSON.AdviserName
				,InputJSON.AdviserEmailAddress
				,InputJSON.AdviserContactNumber
				,InputJSON.LastModifiedDate
				,InputJSON.LastModifiedTouchpointId
				,InputJSON.CreatedBy
				);

	exec [insert-dss-adviserdetails-history] @Json
END