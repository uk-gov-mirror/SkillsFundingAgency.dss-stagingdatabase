CREATE PROCEDURE [dbo].[Change_Feed_Insert_Update_dss-addresses] (@Json NVARCHAR(MAX))
AS
BEGIN
	MERGE INTO [dss-addresses] AS addresses
	USING (
		SELECT *
		FROM OPENJSON(@Json) WITH (
				id UNIQUEIDENTIFIER
				,CustomerId UNIQUEIDENTIFIER
				,SubcontractorId VARCHAR(Max)
				,Address1 VARCHAR(Max)
				,Address2 VARCHAR(Max)
				,Address3 VARCHAR(Max)
				,Address4 VARCHAR(Max)
				,Address5 VARCHAR(Max)
				,PostCode VARCHAR(Max)
				,AlternativePostCode VARCHAR(Max)
				,Longitude FLOAT
				,Latitude FLOAT
				,EffectiveFrom DATETIME2
				,EffectiveTo DATETIME2
				,LastModifiedDate DATETIME2
				,LastModifiedTouchpointId VARCHAR(max)
				,CreatedBy VARCHAR(MAX)
				)
		) AS InputJSON
		ON (addresses.id = InputJSON.id)
	WHEN MATCHED
		THEN
			UPDATE
			SET addresses.id = InputJSON.id
				,addresses.CustomerId = InputJSON.CustomerId
				,addresses.SubcontractorId = InputJSON.SubcontractorId
				,addresses.Address1 = InputJSON.Address1
				,addresses.Address2 = InputJSON.Address2
				,addresses.Address3 = InputJSON.Address3
				,addresses.Address4 = InputJSON.Address4
				,addresses.Address5 = InputJSON.Address5
				,addresses.PostCode = InputJSON.PostCode
				,addresses.AlternativePostCode = InputJSON.AlternativePostCode
				,addresses.Longitude = InputJSON.Longitude
				,addresses.Latitude = InputJSON.Latitude
				,addresses.EffectiveFrom = InputJSON.EffectiveFrom
				,addresses.EffectiveTo = InputJSON.EffectiveTo
				,addresses.LastModifiedDate = InputJSON.LastModifiedDate
				,addresses.LastModifiedTouchpointId = InputJSON.LastModifiedTouchpointId
				,addresses.CreatedBy = InputJSON.CreatedBy
	WHEN NOT MATCHED
		THEN
			INSERT (
				id
				,CustomerId
				,SubcontractorId
				,Address1
				,Address2
				,Address3
				,Address4
				,Address5
				,PostCode
				,AlternativePostCode
				,Longitude
				,Latitude
				,EffectiveFrom
				,EffectiveTo
				,LastModifiedDate
				,LastModifiedTouchpointId
				,CreatedBy
				)
			VALUES (
				InputJSON.id
				,InputJSON.CustomerId
				,InputJSON.SubcontractorId
				,InputJSON.Address1
				,InputJSON.Address2
				,InputJSON.Address3
				,InputJSON.Address4
				,InputJSON.Address5
				,InputJSON.PostCode
				,InputJSON.AlternativePostCode
				,InputJSON.Longitude
				,InputJSON.Latitude
				,InputJSON.EffectiveFrom
				,InputJSON.EffectiveTo
				,InputJSON.LastModifiedDate
				,InputJSON.LastModifiedTouchpointId
				,InputJSON.CreatedBy
				);

	exec [insert-dss-addresses-history] @Json
END