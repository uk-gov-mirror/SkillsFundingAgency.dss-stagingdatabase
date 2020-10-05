

CREATE PROCEDURE [dbo].[usp_GetSatisfactionDataForIpsosMoriIntegration]
AS							   
BEGIN
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME
SET @startDate = DATEADD(MONTH,datediff(MONTH,0,GETDATE())-1,0)
SET @endDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) + '23:59:59'

-- used to get latest address
DECLARE @today DATE;
SET     @today = GETDATE();

--PRINT N'Start date: ' + CAST(@startDate AS nvarchar(30));
--PRINT N'End date: ' + CAST(@endDate AS nvarchar(30));

		WITH OriginalTable AS
		(	
		SELECT   rk.id                                  AS 'Customer ID'
		, rk.GivenName                                  AS 'Given Name'
		, rk.FamilyName                                 AS 'Family Name'
		, 'Primary Phone Number' = 
			CASE COALESCE(rk.PreferredContactMethod, 0)
				WHEN 3 THEN COALESCE(rk.HomeNumber,'')
				ELSE COALESCE(rk.MobileNumber, '')
			END
		, COALESCE(rk.AlternativeNumber, '')            AS 'Alternative Phone Number'
		, COALESCE(rk.PostCode, '')                     AS 'Postcode'
		, COALESCE(rk.EmailAddress, '')             AS 'Contact Email'              
		, CONVERT(VARCHAR(10), rk.DateofBirth, 23)                  AS 'Date of Birth'
		, 'Disability Type' = dbo.udf_GetReferenceDataValue('DiversityDetails','PrimaryLearningDifficultyOrDisability',rk.PrimaryLearningDifficultyOrDisability,'Not provided')
		, 'Learning Difficulty' =  dbo.udf_GetReferenceDataValue('DiversityDetails','SecondaryLearningDifficultyOrDisability',rk.SecondaryLearningDifficultyOrDisability,'Not provided')
		, 'Ethnicity' =  dbo.udf_GetReferenceDataValue('DiversityDetails','Ethnicity',rk.Ethnicity,'Not provided')                  
		, 'Gender' = dbo.udf_GetReferenceDataValue('Customers','Gender',rk.Gender,'')
		, IIF( LEFT(COALESCE(rk.CreatedBy, rk.LastModifiedTouchpointId), 1) = '0',
				dbo.udf_GetReferenceDataValue('Touchpoints','Touchpoint', CAST(COALESCE(rk.CreatedBy, rk.LastModifiedTouchpointId) AS BIGINT),''), '' )  
		  AS 'Contracting Area' 
		, CASE COALESCE(rk.CreatedBy, rk.LastModifiedTouchpointId)
			WHEN '0000000101' then 'Futures Advice'
			WHEN '0000000102' then 'Futures Advice'
			WHEN '0000000103' then 'Prospects'
			WHEN '0000000104' then 'Prospects'
		    WHEN '0000000105' then 'Growth Company'
			WHEN '0000000106' then 'Education Development Trust'
		    WHEN '0000000107' then 'CXK'
			WHEN '0000000108' then 'Adviza'
		    WHEN '0000000109' then 'Education Development Trust'
			WHEN '0000000999' then 'National Careers Helpline'
			else ''
		 END as 'Subcontractor Name'
		, iif(rk.ActionPlanId is not null,'Yes','No')               AS 'Action Plan'    
		, 'Current Employment Status' = dbo.udf_GetReferenceDataValue('EmploymentProgressions','CurrentEmploymentStatus',rk.CurrentEmploymentStatus,'Not provided')
		, 'Length Of Unemployment' = dbo.udf_GetReferenceDataValue('EmploymentProgressions','LengthOfUnemployment',rk.LengthOfUnemployment,'Not provided')
		, 'Current Learning Status' = dbo.udf_GetReferenceDataValue('LearningProgressions','CurrentLearningStatus',rk.CurrentLearningStatus,'Not provided')
		, 'Current Qualification Level' = dbo.udf_GetReferenceDataValue('LearningProgressions','QualificationLevel',rk.CurrentQualificationLevel,'Not provided')                
		, 'Channel' = dbo.udf_GetReferenceDataValue('Interactions','Channel',rk.Channel,'')
		, CONVERT(VARCHAR(10), rk.DateandTimeOfSession, 23)             AS 'Session Date'
		, 'Yes'                                         AS 'Participate Research Evaluation'
		, 'Priority Group' = COALESCE((SELECT STRING_AGG (rd.description, ',') FROM [dss-customers] c
INNER JOIN [dss-prioritygroups] pg on c.id = pg.CustomerId
CROSS JOIN [dss-reference-data] rd
where c.id = rk.id
AND rd.name = 'PriorityCustomer' 
AND rd.value = pg.PriorityGroup
), dbo.udf_GetReferenceDataValue('ActionPlans','PriorityCustomer', rk.PriorityCustomer, ''))
--, DupeRowCount
--'Priority Group' = dbo.udf_GetReferenceDataValue('ActionPlans','PriorityCustomer', rk.PriorityCustomer, '')
--, prev_actionplans
, rk.DateandTimeOfInteraction
, rk.DateActionPlanCreated
	from 
	(
			SELECT
				  c.id
				, c.GivenName                                   
				, c.FamilyName                                  
				,con.PreferredContactMethod
				,con.HomeNumber
				,con.MobileNumber
				,con.AlternativeNumber
				,a.PostCode
				,con.EmailAddress
				,c.DateofBirth
				,d.PrimaryLearningDifficultyOrDisability
				,d.SecondaryLearningDifficultyOrDisability
				,d.Ethnicity
				,c.Gender
				,ap.id as ActionPlanId
				,ap.CreatedBy
				,COALESCE(ap.LastModifiedTouchpointId,i.LastModifiedTouchpointId) as LastModifiedTouchpointId
				,ap.SubcontractorId
				,ep.CurrentEmploymentStatus
				,ep.LengthOfUnemployment
				,lp.CurrentLearningStatus
				,lp.CurrentQualificationLevel
				,i.Channel
				,i.DateandTimeOfInteraction
				,s.DateandTimeOfSession
				,ap.PriorityCustomer
				,ap.DateActionPlanCreated
				, (select count(1) from [dss-interactions] i2 where i2.CustomerId = i.CustomerId and i2.DateAndTimeOfInteraction > DATEADD(month, -3,  @startDate) AND i2.DateAndTimeOfInteraction < @startDate ) as prev_interactions -- Only report on a customer every 3 months
				--, (select count(1) from [dss-actionplans] ap2 where ap2.CustomerId = i.CustomerId and ap2.DateActionPlanCreated > DATEADD(month, -3,  @startDate) AND  ap2.DateActionPlanCreated < @startDate  ) as prev_actionplans
				--, rank () over (partition by c.id, i.id order by iif(ap.id is not null, 1,2 ), i.DateandTimeOfInteraction, i.LastModifiedDate, i.id ) ro  --make sure action plans are considered first and duplcates are excluded
				--, rank () over (partition by ap.id order by ap.DateActionPlanCreated asc) ro  --make sure action plans are considered first and duplcates are excluded
				--, ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY c.id, i.DateAndTimeOfInteraction,  ap.DateActionPlanCreated) AS DupeRowCount
			FROM        [dss-customers] c
			LEFT JOIN	[dss-prioritygroups] pg on c.id = pg.CustomerId
			LEFT JOIN   [dss-contacts] con ON con.CustomerId = c.id
			LEFT JOIN   [dss-addresses] a ON a.CustomerId = c.Id
			LEFT JOIN   [dss-diversitydetails] d ON d.CustomerId = c.Id
			LEFT JOIN   [dss-employmentprogressions] ep on ep.CustomerId = c.id
			LEFT JOIN   [dss-learningprogressions] lp on lp.CustomerId = c.id
			LEFT JOIN   [dss-actionplans] ap ON ap.CustomerId = c.id
			INNER JOIN  [dss-interactions] i ON i.CustomerId = c.id

			LEFT JOIN   [dss-sessions] s ON s.id = ap.SessionId --OR i.id = s.InteractionId
			WHERE       c.OptInMarketResearch = 1 -- true
			AND         COALESCE(c.ReasonForTermination, 0) NOT IN (1,2)
			AND         (ap.DateActionPlanCreated BETWEEN @startDate AND @endDate
			OR         i.DateandTimeOfInteraction BETWEEN @startDate AND @endDate)
UNION 
			SELECT
				  c.id
				, c.GivenName                                   
				, c.FamilyName                                  
				,con.PreferredContactMethod
				,con.HomeNumber
				,con.MobileNumber
				,con.AlternativeNumber
				,a.PostCode
				,con.EmailAddress
				,c.DateofBirth
				,d.PrimaryLearningDifficultyOrDisability
				,d.SecondaryLearningDifficultyOrDisability
				,d.Ethnicity
				,c.Gender
				,ap.id as ActionPlanId
				,ap.CreatedBy
				,COALESCE(ap.LastModifiedTouchpointId,i.LastModifiedTouchpointId) as LastModifiedTouchpointId
				,ap.SubcontractorId
				,ep.CurrentEmploymentStatus
				,ep.LengthOfUnemployment
				,lp.CurrentLearningStatus
				,lp.CurrentQualificationLevel
				,i.Channel
				,i.DateandTimeOfInteraction
				,s.DateandTimeOfSession
				,ap.PriorityCustomer
				,ap.DateActionPlanCreated
				, (select count(1) from [dss-interactions] i2 where i2.CustomerId = i.CustomerId and i2.DateAndTimeOfInteraction > DATEADD(month, -3,  @startDate) AND i2.DateAndTimeOfInteraction < @startDate ) as prev_interactions -- Only report on a customer every 3 months
				--, (select count(1) from [dss-actionplans] ap2 where ap2.CustomerId = i.CustomerId and ap2.DateActionPlanCreated > DATEADD(month, -3,  @startDate) AND  ap2.DateActionPlanCreated < @startDate  ) as prev_actionplans
				--, rank () over (partition by c.id, i.id order by iif(ap.id is not null, 1,2 ), i.DateandTimeOfInteraction, i.LastModifiedDate, i.id ) ro  --make sure action plans are considered first and duplcates are excluded
				--, rank () over (partition by ap.id order by ap.DateActionPlanCreated asc) ro  --make sure action plans are considered first and duplcates are excluded
				--, ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY c.id, i.DateAndTimeOfInteraction,  ap.DateActionPlanCreated) AS DupeRowCount
			FROM        [dss-customers] c
			LEFT JOIN	[dss-prioritygroups] pg on c.id = pg.CustomerId
			LEFT JOIN   [dss-contacts] con ON con.CustomerId = c.id
			LEFT JOIN   [dss-addresses] a ON a.CustomerId = c.Id
			LEFT JOIN   [dss-diversitydetails] d ON d.CustomerId = c.Id
			LEFT JOIN   [dss-employmentprogressions] ep on ep.CustomerId = c.id
			LEFT JOIN   [dss-learningprogressions] lp on lp.CustomerId = c.id
			LEFT JOIN   [dss-actionplans] ap ON ap.CustomerId = c.id
			INNER JOIN  [dss-interactions] i ON i.CustomerId = c.id

			LEFT JOIN   [dss-sessions] s ON  i.id = s.InteractionId
			WHERE       c.OptInMarketResearch = 1 -- true
			AND         COALESCE(c.ReasonForTermination, 0) NOT IN (1,2)
			AND         (ap.DateActionPlanCreated BETWEEN @startDate AND @endDate
			OR         i.DateandTimeOfInteraction BETWEEN @startDate AND @endDate)



	) rk
	where
		--rk.ro = 1 -- exclude duplicate rows within the reporting period
		--AND 
		(
						(  prev_interactions = 0 ) -- if an action plan does not exists check no interactions exist from before the reporting period
						--OR
				--( rk.ActionPlanId is not null  AND prev_actionplans = 0 ) -- if an action plan is detected check no actions plans exist from before the reporting period
		)

		)
		, FilterTable AS
		(
			SELECT *,  ROW_NUMBER() OVER (PARTITION BY [Customer ID] ORDER BY [Customer ID], DateAndTimeOfInteraction,  DateActionPlanCreated) 
			AS DupeRowCount FROM OriginalTable
		)
		, TempTable AS
		(
			SELECT *  FROM FilterTable WHERE DupeRowCount = 1 -- exclude dupes
		)

		SELECT [Customer ID], [Given Name], [Family Name], [Primary Phone Number], [Alternative Phone Number], Postcode, [Contact Email],
				[Date of Birth], [Disability Type], [Learning Difficulty], Ethnicity, Gender, [Contracting Area], [Subcontractor Name], 
				[Action Plan], [Current Employment Status], [Length Of Unemployment], [Current Learning Status], [Current Qualification Level],
				Channel, [Session Date], [Participate Research Evaluation], [Priority Group]
		FROM TempTable
		WHERE  ([Contact Email] <> null OR [Contact Email] <> '')
			OR ([Primary Phone Number] <> null OR [Primary Phone Number] <> '')
			OR ([Alternative Phone Number] <> null OR [Alternative Phone Number] <> '')
END;