-------------------------------------------------------------------------------
-- Authors:      Kevin Brandon
-- Created:      25/09/2019
-- Purpose:      Demographics National Careers Helpline data for Ipsos-Mori.
--  
-------------------------------------------------------------------------------
-- Initial Creation
-- Copyright © 2019, ESFA, All Rights Reserved
-------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[udf_DemographicsNCHReport]()
RETURNS @demographics_nch TABLE 
( 
		group_name VARCHAR(50), 
		group_value VARCHAR(50),	
		touchpoint1 VARCHAR(50),
		touchpoint2 VARCHAR(50),
		touchpoint3 VARCHAR(50),
		touchpoint4 VARCHAR(50),
		touchpoint5 VARCHAR(50),
		touchpoint6 VARCHAR(50),
		touchpoint7 VARCHAR(50),
		touchpoint8 VARCHAR(50),
		touchpoint9 VARCHAR(50),
		touchpoint10 VARCHAR(50) 
)
AS
BEGIN
	DECLARE @startDate DATE;	   																								  
	DECLARE @endDate DATE;
	DECLARE @nch_group_name varchar(100);
	DECLARE @iag_group_name varchar(100);

	SET @startDate = DATEADD(MONTH,datediff(MONTH,0,GETDATE())-1,0);
	SET @endDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1);
	SET @nch_group_name = 'National Careers Helpline';
	SET @iag_group_name = 'IAG';

	with DemographicData AS
	(
		SELECT 
			i.TouchpointId AS NCH
			, COALESCE(ap.CreatedBy, ap.LastModifiedTouchpointId, i.LastModifiedTouchPointId) AS touchpointId
			, ap.id as ap_id
			, (select count(1) from [dss-interactions] i2 where i2.CustomerId = i.CustomerId and i2.DateAndTimeOfInteraction < @startDate )  as prev_interactions
			, (select count(1) from [dss-actionplans] ap2 where ap2.CustomerId = i.CustomerId and ap2.DateActionPlanCreated < @startDate  ) as prev_actionplans
			, rank () over ( partition by c.id order by iif(ap.id is null,2,1), i.DateandTimeOfInteraction, i.LastModifiedDate, i.id ) ro   

		FROM [dbo].[dss-customers] c
			inner join [dss-interactions] i on c.id = i.CustomerId
			left join  [dbo].[dss-actionplans] ap on  c.id = ap.CustomerId 
		WHERE 
		(
				cast(ap.DateActionPlanCreated AS DATE) BETWEEN @startDate AND @endDate
				OR CAST(i.DateandTimeOfInteraction AS DATE) BETWEEN @startDate AND @endDate AND i.TouchpointId = '0000000999'
		)
	)
	, nch_group_base AS
	(
		SELECT @iag_group_name AS group_name, 'Information Given' AS group_value
		UNION
		SELECT @iag_group_name AS group_name, 'Information, Advice and Guidance Given' AS group_value
	)
	, nch_grouping AS
		(   
			SELECT 
				@iag_group_name AS group_name, 
				IIF (ap_id  IS NULL, 'Information Given', 'Information, Advice and Guidance Given') AS group_value,
				touchpointId
			FROM DemographicData
			WHERE ro = 1 -- exclude duplicate rows within the reporting period
					and (
								-- if an action plan is present check no actions plans exist from before the reporting period
							( ap_id is not null  AND prev_actionplans = 0 )
							OR
								-- if an action plan does not exists check no interactions exist from before the reporting period
							( ap_id is null AND prev_interactions = 0 )
						) 
		)
	, nch_groups AS
		(
			SELECT group_name, group_value, touchpointId, count(1) AS count
			FROM nch_grouping
			group BY group_name, group_value, touchpointId
		)
		
	INSERT @demographics_nch 
	SELECT a.group_name,
			a.group_value,
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			IsNull(cast(g10.count as varchar(10)),'0') as 'touchpoint10'
	FROM nch_group_base a
		left join nch_groups g10 on a.group_value = g10.group_value and g10.touchpointId = '0000000999' 

		RETURN
END;