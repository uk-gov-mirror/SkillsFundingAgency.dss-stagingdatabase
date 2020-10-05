-------------------------------------------------------------------------------
-- Authors:      Kevin Brandon
-- Created:      14/08/2019
-- Purpose:      Produce demographics data for Ipsos-Mori integration.
--  
-------------------------------------------------------------------------------
-- Modification History
-- Initial creation.
-- 
--            
-- Copyright © 2019, ESFA, All Rights Reserved
-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[usp_GetDemographicsDataForIpsosMoriIntegration]
AS							   
BEGIN		

	DECLARE @startDate DATE;
	DECLARE @endDate DATE;
	DECLARE @age_group_name  varchar(100);
	DECLARE @employment_group_name varchar(100);
	DECLARE @gender_group_name varchar(100);
	DECLARE @nch_group_name varchar(100);
	DECLARE @iag_group_name varchar(100);

	SET @startDate = DATEADD(MONTH,datediff(MONTH,0,GETDATE())-1,0)
	SET @endDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) + '23:59:59'
	SET @age_group_name = 'Age';
	SET @employment_group_name = 'Employment Status adult - By employment category';
	SET @gender_group_name = 'Gender - By gender category';
	SET @nch_group_name = '';
	SET @iag_group_name = 'IAG';

	with TempData AS
	(
		SELECT CASE WHEN dateadd(year, datediff (year, DateOfBirth, getdate()), DateOfBirth) > getdate()
            THEN datediff(year, DateOfBirth, getdate()) - 1
            ELSE datediff(year, DateOfBirth, getdate())
		END  AS Age
			--DATEDIFF(hour,DateOfBirth,GETDATE())/8766 AS Age
			, COALESCE(ap.CreatedBy, ap.LastModifiedTouchpointId, i.LastModifiedTouchPointId) AS touchpointId
			, ap.id as ap_id
			, c.Gender, ep.CurrentEmploymentStatus AS EpStatus
			, (select count(1) from [dss-interactions] i2 where i2.CustomerId = i.CustomerId and i2.DateAndTimeOfInteraction > DATEADD(month, -3,  @startDate) AND i2.DateAndTimeOfInteraction < @startDate ) as prev_interactions
			, (select count(1) from [dss-actionplans] ap2 where ap2.CustomerId = i.CustomerId and ap2.DateActionPlanCreated > DATEADD(month, -3,  @startDate) AND  ap2.DateActionPlanCreated < @startDate  ) as prev_actionplans
			--,rank () over ( partition by c.id order by iif(ap.id is null,2,1), i.DateandTimeOfInteraction, i.LastModifiedDate, i.id ) ro 
			, ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY c.id, i.DateAndTimeOfInteraction,  ap.DateActionPlanCreated) AS DupeRowCount
		FROM [dbo].[dss-customers] c
				left join [dss-interactions] i on c.id = i.CustomerId
				left join  [dbo].[dss-actionplans] ap on  c.id = ap.CustomerId
				left join [dbo].[dss-diversitydetails] dd on dd.CustomerId = c.id 
				left join [dbo].[dss-employmentprogressions] ep ON ep.CustomerId = c.id 
		WHERE c.OptInMarketResearch = 1 -- true
			AND         COALESCE(c.ReasonForTermination, 0) NOT IN (1,2)
			AND         (ap.DateActionPlanCreated BETWEEN @startDate AND @endDate
			OR         i.DateandTimeOfInteraction BETWEEN @startDate AND @endDate)
			--(
			--	cast(ap.DateActionPlanCreated AS DATE) BETWEEN @startDate AND @endDate-- AND ap.CreatedBy <> '0000000999'
			--	OR CAST(i.DateandTimeOfInteraction AS DATE) BETWEEN @startDate AND @endDate AND i.TouchpointId = '0000000999'
			--)
	) , DemographicData AS
		(
			SELECT * FROM TempData WHERE DupeRowCount = 1 -- exclude dupes
				AND				(
						-- if an action plan is present check no actions plans exist from before the reporting period
						--( ap_id is not null  AND prev_actionplans = 0 )
						--OR
						-- if an action plan does not exists check no interactions exist from before the reporting period
						--( ap_id is null AND prev_interactions = 0 )
						--)
						(  prev_interactions = 0 )
						)
		)

	, age_group_base AS
	(
		select @age_group_name AS group_name, '18-19' as group_value
		UNION
		select @age_group_name AS group_name, '20-24' as group_value
		UNION
		select @age_group_name AS group_name, '25-49' as group_value
		UNION
		select @age_group_name AS group_name, '50+' as group_value
	)
	, age_grouping AS
		(   
			SELECT 
				@age_group_name AS group_name,
				CASE 
					WHEN age between 18 and 19 THEN '18-19'
					WHEN age between 20 and 24 THEN '20-24'
					WHEN age between 25 and 49 THEN '25-49'
					WHEN age >= 50 THEN '50+'
					WHEN age < 18 THEN '<18'
					ELSE 'other'
				END AS group_value,
				age,
				touchpointId
			FROM DemographicData
			--where --ro = 1 -- exclude duplicate rows within the reporting period
			--		--and 
			--		(
			--			-- if an action plan is present check no actions plans exist from before the reporting period
			--			( ap_id is not null  AND prev_actionplans = 0 )
			--			OR
			--			-- if an action plan does not exists check no interactions exist from before the reporting period
			--			( ap_id is null AND prev_interactions = 0 )
			--			) 
			--	and DupeRowCount = 1
		)
	, age_groups AS
				(
					SELECT group_name, group_value, touchpointId, count(1) AS count
					FROM age_grouping
					group BY group_name, group_value, touchpointId
				)
	, age_report AS
	(
			SELECT a.group_name,
					a.group_value,
					IsNull(cast(g1.count as varchar(10)),'0') as 'touchpoint1',
					IsNull(cast(g2.count as varchar(10)),'0') as 'touchpoint2',
					IsNull(cast(g3.count as varchar(10)),'0') as 'touchpoint3',
					IsNull(cast(g4.count as varchar(10)),'0') as 'touchpoint4',
					IsNull(cast(g5.count as varchar(10)),'0') as 'touchpoint5',
					IsNull(cast(g6.count as varchar(10)),'0') as 'touchpoint6',
					IsNull(cast(g7.count as varchar(10)),'0') as 'touchpoint7',
					IsNull(cast(g8.count as varchar(10)),'0') as 'touchpoint8',
					IsNull(cast(g9.count as varchar(10)),'0') as 'touchpoint9',
					IsNull(cast(g10.count as varchar(10)),'0') as 'touchpoint10'
			FROM age_group_base a
				left join age_groups g1 on a.group_value = g1.group_value and g1.touchpointId = '0000000101'
				left join age_groups g2 on a.group_value = g2.group_value and g2.touchpointId = '0000000102'
				left join age_groups g3 on a.group_value = g3.group_value and g3.touchpointId = '0000000103'
				left join age_groups g4 on a.group_value = g4.group_value and g4.touchpointId = '0000000104'
				left join age_groups g5 on a.group_value = g5.group_value and g5.touchpointId = '0000000105'
				left join age_groups g6 on a.group_value = g6.group_value and g6.touchpointId = '0000000106'
				left join age_groups g7 on a.group_value = g7.group_value and g7.touchpointId = '0000000107'
				left join age_groups g8 on a.group_value = g8.group_value and g8.touchpointId = '0000000108'
				left join age_groups g9 on a.group_value = g9.group_value and g9.touchpointId = '0000000109'
				left join age_groups g10 on a.group_value = g10.group_value and g10.touchpointId = '0000000999' 
	)
	, gender_group_base AS
	(
		select @gender_group_name AS group_name, 'Female' as group_value
		UNION
		select @gender_group_name AS group_name, 'Male' as group_value
		UNION
		select @gender_group_name AS group_name, 'Not applicable' as group_value
		UNION
		select @gender_group_name AS group_name, 'Not provided' as group_value
	)
	, gender_gouping AS
		( 
			SELECT 
				@gender_group_name AS group_name,
				CASE 
					WHEN gender = 1 THEN 'Female'	   
					WHEN gender = 2 THEN 'Male'
					WHEN gender = 3 THEN 'Not applicable'
					WHEN gender = 99 THEN 'Not provided'
					ELSE 'other'
				END AS group_value
				, gender
				, touchpointId
			FROM DemographicData
			--WHERE --ro = 1 -- exclude duplicate rows within the reporting period
			--	  -- and 
			--		(
			--					-- if an action plan is present check no actions plans exist from before the reporting period
			--				( ap_id is not null  AND prev_actionplans = 0 )
			--				OR
			--					-- if an action plan does not exists check no interactions exist from before the reporting period
			--				( ap_id is null AND prev_interactions = 0 )
			--			)
			--		and DupeRowCount = 1
		)
	, gender_groups AS
		(
			SELECT group_name, group_value, touchpointId, count(1) AS count
			FROM gender_gouping
			group BY group_name, group_value, touchpointId
		)

	, gender_report AS
	(
	select a.group_name,
			   a.group_value,
			IsNull(cast(g1.count as varchar(10)),'0') as 'touchpoint1',
			IsNull(cast(g2.count as varchar(10)),'0') as 'touchpoint2',
			IsNull(cast(g3.count as varchar(10)),'0') as 'touchpoint3',
			IsNull(cast(g4.count as varchar(10)),'0') as 'touchpoint4',
			IsNull(cast(g5.count as varchar(10)),'0') as 'touchpoint5',
			IsNull(cast(g6.count as varchar(10)),'0') as 'touchpoint6',
			IsNull(cast(g7.count as varchar(10)),'0') as 'touchpoint7',
			IsNull(cast(g8.count as varchar(10)),'0') as 'touchpoint8',
			IsNull(cast(g9.count as varchar(10)),'0') as 'touchpoint9',
			IsNull(cast(g10.count as varchar(10)),'0') as 'touchpoint10'

		FROM gender_group_base a  
			left join gender_groups g1 on a.group_value = g1.group_value and g1.touchpointId = '0000000101'
			left join gender_groups g2 on a.group_value = g2.group_value and g2.touchpointId = '0000000102'
			left join gender_groups g3 on a.group_value = g3.group_value and g3.touchpointId = '0000000103'
			left join gender_groups g4 on a.group_value = g4.group_value and g4.touchpointId = '0000000104'
			left join gender_groups g5 on a.group_value = g5.group_value and g5.touchpointId = '0000000105'
			left join gender_groups g6 on a.group_value = g6.group_value and g6.touchpointId = '0000000106'
			left join gender_groups g7 on a.group_value = g7.group_value and g7.touchpointId = '0000000107'
			left join gender_groups g8 on a.group_value = g8.group_value and g8.touchpointId = '0000000108'
			left join gender_groups g9 on a.group_value = g9.group_value and g9.touchpointId = '0000000109'
			left join gender_groups g10 on a.group_value = g10.group_value and g10.touchpointId = '0000000999'
	 )
	, employment_group_base AS
	(
		select @employment_group_name AS group_name, 'Economically inactive (Inc with voluntary work)' as group_value
		UNION
		select @employment_group_name AS group_name, 'Employed (inc with voluntary work)' as group_value
		UNION
		select @employment_group_name AS group_name, 'Not known / not provided' as group_value
		UNION
		select @employment_group_name AS group_name, 'Retired (Inc with voluntary work)' as group_value
		UNION
		select @employment_group_name AS group_name, 'Self Employed (Inc with voluntary work)' as group_value
		UNION
		select @employment_group_name AS group_name, 'Unemployed (Inc with voluntary work)' as group_value

	)
	, employment_grouping AS
		(	
			SELECT 
				@employment_group_name AS group_name,
				CASE 
					WHEN EpStatus between 2 and 3 THEN 'Economically inactive (Inc with voluntary work)'
					WHEN EpStatus between 4 and 5 THEN 'Employed (inc with voluntary work)'
					WHEN EpStatus between 98 and 99 THEN 'Not known / not provided'
					WHEN EpStatus between 7 and 8 THEN 'Retired (Inc with voluntary work)'
					WHEN EpStatus between 9 and 10 THEN	'Self Employed (Inc with voluntary work)'
					WHEN EpStatus between 11 and 12 THEN 'Unemployed (Inc with voluntary work)'
					ELSE 'other'
				END AS group_value,
				EpStatus,
				touchpointId
			FROM DemographicData
						--where --ro = 1 -- exclude duplicate rows within the reporting period
						--	  --and 
						--	  (
						--			-- if an action plan is present check no actions plans exist from before the reporting period
						--			( ap_id is not null  AND prev_actionplans = 0 )
						--			OR
						--			-- if an action plan does not exists check no interactions exist from before the reporting period
						--			( ap_id is null AND prev_interactions = 0 )
						--		  ) 
						--	and DupeRowCount = 1
		)
		, employment_groups AS
		(
			SELECT group_name, group_value, touchpointId, count(1) AS count
			FROM employment_grouping
			group BY group_name, group_value, touchpointId
		)
		, employment_report AS
		(
		select a.group_name,
			   a.group_value,
				IsNull(cast(g1.count as varchar(10)),'0') as 'touchpoint1',
				IsNull(cast(g2.count as varchar(10)),'0')  as'touchpoint2',
				IsNull(cast(g3.count as varchar(10)),'0') as 'touchpoint3',
				IsNull(cast(g4.count as varchar(10)),'0') as 'touchpoint4',
				IsNull(cast(g5.count as varchar(10)),'0') as 'touchpoint5',
				IsNull(cast(g6.count as varchar(10)),'0') as 'touchpoint6',
				IsNull(cast(g7.count as varchar(10)),'0') as 'touchpoint7',
				IsNull(cast(g8.count as varchar(10)),'0') as 'touchpoint8',
				IsNull(cast(g9.count as varchar(10)),'0') as 'touchpoint9',
				IsNull(cast(g10.count as varchar(10)),'0') as 'touchpoint10'
		from employment_group_base a
			left join employment_groups g1 on a.group_value = g1.group_value and g1.touchpointId = '0000000101'
			left join employment_groups g2 on a.group_value = g2.group_value and g2.touchpointId = '0000000102'
			left join employment_groups g3 on a.group_value = g3.group_value and g3.touchpointId = '0000000103'
			left join employment_groups g4 on a.group_value = g4.group_value and g4.touchpointId = '0000000104'
			left join employment_groups g5 on a.group_value = g5.group_value and g5.touchpointId = '0000000105'
			left join employment_groups g6 on a.group_value = g6.group_value and g6.touchpointId = '0000000106'
			left join employment_groups g7 on a.group_value = g7.group_value and g7.touchpointId = '0000000107'
			left join employment_groups g8 on a.group_value = g8.group_value and g8.touchpointId = '0000000108'
			left join employment_groups g9 on a.group_value = g9.group_value and g9.touchpointId = '0000000109'
			left join employment_groups g10 on a.group_value = g10.group_value and g10.touchpointId = '0000000999'
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
			--WHERE --ro = 1 -- exclude duplicate rows within the reporting period
			--		--and 
			--		(
			--					-- if an action plan is present check no actions plans exist from before the reporting period
			--				( ap_id is not null  AND prev_actionplans = 0 )
			--				OR
			--					-- if an action plan does not exists check no interactions exist from before the reporting period
			--				( ap_id is null AND prev_interactions = 0 )
			--			) 
			--		and DupeRowCount = 1
		)
	, nch_groups AS
		(
			SELECT group_name, group_value, touchpointId, count(1) AS count
			FROM nch_grouping
			group BY group_name, group_value, touchpointId
		), nch_report AS
		(
	SELECT a.group_name,
			a.group_value,
				IsNull(cast(g1.count as varchar(10)),'0') as 'touchpoint1',
				IsNull(cast(g2.count as varchar(10)),'0')  as'touchpoint2',
				IsNull(cast(g3.count as varchar(10)),'0') as 'touchpoint3',
				IsNull(cast(g4.count as varchar(10)),'0') as 'touchpoint4',
				IsNull(cast(g5.count as varchar(10)),'0') as 'touchpoint5',
				IsNull(cast(g6.count as varchar(10)),'0') as 'touchpoint6',
				IsNull(cast(g7.count as varchar(10)),'0') as 'touchpoint7',
				IsNull(cast(g8.count as varchar(10)),'0') as 'touchpoint8',
				IsNull(cast(g9.count as varchar(10)),'0') as 'touchpoint9',
			IsNull(cast(g10.count as varchar(10)),'0') as 'touchpoint10'
	FROM nch_group_base a
		left join nch_groups g1 on a.group_value = g1.group_value and g1.touchpointId = '0000000101'
		left join nch_groups g2 on a.group_value = g2.group_value and g2.touchpointId = '0000000102'
		left join nch_groups g3 on a.group_value = g3.group_value and g3.touchpointId = '0000000103'
		left join nch_groups g4 on a.group_value = g4.group_value and g4.touchpointId = '0000000104'
		left join nch_groups g5 on a.group_value = g5.group_value and g5.touchpointId = '0000000105'
		left join nch_groups g6 on a.group_value = g6.group_value and g6.touchpointId = '0000000106'
		left join nch_groups g7 on a.group_value = g7.group_value and g7.touchpointId = '0000000107'
		left join nch_groups g8 on a.group_value = g8.group_value and g8.touchpointId = '0000000108'
		left join nch_groups g9 on a.group_value = g9.group_value and g9.touchpointId = '0000000109'
		left join nch_groups g10 on a.group_value = g10.group_value and g10.touchpointId = '0000000999' 
		)

	SELECT 
		 a.group_name
		,a.group_value AS 'group_value'
		,a.touchpoint1 AS 'East of England and Buckinghamshire'
		,a.touchpoint2 AS 'East Midlands and Northamptonshire'	
		,a.touchpoint3 AS 'London'	
		,a.touchpoint4 AS 'West Midlands and Staffordshire'	
		,a.touchpoint5 AS 'North West'	
		,a.touchpoint6 AS 'North East and Cumbria'	
		,a.touchpoint7 AS 'South East'	
		,a.touchpoint8 AS 'South West'	
		,a.touchpoint9 AS 'Yorkshire and Humber'
		,a.touchpoint10 AS 'National Careers Helpline'
	FROM age_report AS a	
	
	UNION ALL	
	SELECT
	 ''
	,''
	,'' AS 'East of England and Buckinghamshire'
	,'' AS 'East Midlands and Northamptonshire'	
	,'' AS 'London'	
	,'' AS 'West Midlands and Staffordshire'	
	,'' AS 'North West'	
	,'' AS 'North East and Cumbria'	
	,'' AS 'South East'	
	,'' AS 'South West'	
	,'' AS 'Yorkshire and Humber'
	,''  AS 'National Careers Helpline'

	UNION ALL
	SELECT 
	 es.group_name
	,es.group_value AS 'group_value'
	,es.touchpoint1 AS 'East of England and Buckinghamshire'
	,es.touchpoint2 AS 'East Midlands and Northamptonshire'	
	,es.touchpoint3 AS 'London'	
	,es.touchpoint4 AS 'West Midlands and Staffordshire'	
	,es.touchpoint5 AS 'North West'	
	,es.touchpoint6 AS 'North East and Cumbria'	
	,es.touchpoint7 AS 'South East'	
	,es.touchpoint8 AS 'South West'	
	,es.touchpoint9 AS 'Yorkshire and Humber'
	,es.touchpoint10 AS 'National Careers Helpline'
	FROM employment_report AS es

UNION ALL	
	SELECT
	 ''
	,''
	,'' AS 'East of England and Buckinghamshire'
	,'' AS 'East Midlands and Northamptonshire'	
	,'' AS 'London'	
	,'' AS 'West Midlands and Staffordshire'	
	,'' AS 'North West'	
	,'' AS 'North East and Cumbria'	
	,'' AS 'South East'	
	,'' AS 'South West'	
	,'' AS 'Yorkshire and Humber'
	,''  AS 'National Careers Helpline'
		
	UNION ALL
	SELECT
	 g.group_name
	,g.group_value AS 'group_value'
	,g.touchpoint1 AS 'East of England and Buckinghamshire'
	,g.touchpoint2 AS 'East Midlands and Northamptonshire'	
	,g.touchpoint3 AS 'London'	
	,g.touchpoint4 AS 'West Midlands and Staffordshire'	
	,g.touchpoint5 AS 'North West'	
	,g.touchpoint6 AS 'North East and Cumbria'	
	,g.touchpoint7 AS 'South East'	
	,g.touchpoint8 AS 'South West'	
	,g.touchpoint9 AS 'Yorkshire and Humber'
	,g.touchpoint10 AS 'National Careers Helpline'
	FROM gender_report  AS g

	UNION ALL	
	SELECT
	 ''
	,''
	,'' AS 'East of England and Buckinghamshire'
	,'' AS 'East Midlands and Northamptonshire'	
	,'' AS 'London'	
	,'' AS 'West Midlands and Staffordshire'	
	,'' AS 'North West'	
	,'' AS 'North East and Cumbria'	
	,'' AS 'South East'	
	,'' AS 'South West'	
	,'' AS 'Yorkshire and Humber'
	,''  AS 'National Careers Helpline'

	UNION ALL
	SELECT
	 nch.group_name
	,nch.group_value AS 'group_value'
	,nch.touchpoint1 AS 'East of England and Buckinghamshire' -- East of England and Buckinghamshire
	,nch.touchpoint2 AS 'East Midlands and Northamptonshire'-- East Midlands and Northamptonshire
	,nch.touchpoint3 AS 'London' -- London
	,nch.touchpoint4 AS 'West Midlands and Staffordshire' -- West Midlands
	,nch.touchpoint5 AS 'North West' -- North West
	,nch.touchpoint6 AS 'North East and Cumbria'	-- North East and Cumbria
	,nch.touchpoint7 AS 'South East' -- South East
	,nch.touchpoint8 AS 'South West' -- South West	
	,nch.touchpoint9 AS 'Yorkshire and Humber' -- Yorkshire and Humber
	,nch.touchpoint10 AS 'National Careers Helpline'
	FROM nch_report  AS nch

END;