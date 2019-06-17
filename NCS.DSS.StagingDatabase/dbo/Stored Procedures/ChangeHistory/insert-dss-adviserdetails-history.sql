CREATE PROCEDURE [dbo].[insert-dss-adviserdetails-history] (@Json NVARCHAR(MAX))
AS
BEGIN
	INSERT INTO [dss-adviserdetails-history]
		SELECT DATEADD(MINUTE, _ts/60, DATEADD(SECOND, _ts%60, '19700101')) as CosmosTimeStamp, id, SubcontractorId, AdviserName, AdviserEmailAddress, AdviserContactNumber,
		       LastModifiedDate, LastModifiedTouchpointId, CreatedBy
			FROM OPENJSON(@Json) WITH (
				_ts BIGINT
				,id UNIQUEIDENTIFIER
				,SubcontractorId VARCHAR(max)
				,AdviserName VARCHAR(Max)
				,AdviserEmailAddress VARCHAR(Max)
				,AdviserContactNumber VARCHAR(max)
				,LastModifiedDate DATETIME2
				,LastModifiedTouchpointId VARCHAR(max)
				,CreatedBy VARCHAR(MAX)
				)
END		