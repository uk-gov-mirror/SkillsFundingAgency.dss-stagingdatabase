CREATE PROCEDURE [dbo].[insert-dss-addresses-history] (@Json NVARCHAR(MAX))
AS
BEGIN
	INSERT INTO [dss-addresses-history]
		SELECT DATEADD(MINUTE, _ts/60, DATEADD(SECOND, _ts%60, '19700101')) as CosmosTimeStamp, id, CustomerId, SubcontractorId, Address1, Address2, Address3, Address4,
			   Address5, PostCode, AlternativePostCode, Longitude, Latitude, EffectiveFrom, EffectiveTo, LastModifiedDate, LastModifiedTouchpointId, CreatedBy	
			FROM OPENJSON(@Json) WITH (
				_ts BIGINT
				,id UNIQUEIDENTIFIER
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
END