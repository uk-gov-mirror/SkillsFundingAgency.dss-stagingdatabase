 
-------------------------------------------------------------------------------
-- Authors:      Kevin Brandon
-- Created:      14/08/2019
-- Purpose:      Produce Satisfaction data for Ipsos-Mori integration.
--  
-------------------------------------------------------------------------------
-- Modification History
-- Initial creation.
-- 
--            
-- Copyright © 2019, ESFA, All Rights Reserved
-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[usp_GetSatisfactionDataForIpsosMoriIntegration]
AS							   
BEGIN
DECLARE @startDate DATE
	DECLARE @endDate DATE

	SET @startDate = DATEADD(MONTH,datediff(MONTH,0,GETDATE())-1,0)
	SET @endDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)

	-- used to get latest address
	DECLARE	@today DATE;
	SET		@today = GETDATE()

	SELECT 		c.id											AS 'Customer ID'
				, c.GivenName									AS 'Given Name'
				, c.FamilyName									AS 'Family Name'
				, 'Primary Phone Number' = 
					CASE COALESCE(con.PreferredContactMethod, 0)
						WHEN 3 THEN COALESCE(con.HomeNumber,'')
						ELSE COALESCE(con.MobileNumber, '')
					END
				, COALESCE(con.AlternativeNumber, '')			AS 'Alternative Phone Number'
				, COALESCE(a.PostCode, '')						AS 'Postcode'
				, COALESCE(con.EmailAddress, '')				AS 'Contact Email'				
				, CONVERT(VARCHAR(10), c.DateofBirth, 23)					AS 'Date of Birth'
				, 'Disability Type' = dbo.udf_GetReferenceDataValue('DiversityDetails','PrimaryLearningDifficultyOrDisability',d.PrimaryLearningDifficultyOrDisability,'Not provided')
				, 'Learning Difficulty' =  dbo.udf_GetReferenceDataValue('DiversityDetails','SecondaryLearningDifficultyOrDisability',d.SecondaryLearningDifficultyOrDisability,'Not provided')
				, 'Ethnicity' =  dbo.udf_GetReferenceDataValue('DiversityDetails','Ethnicity',d.Ethnicity,'Not provided')					
				, 'Gender' = dbo.udf_GetReferenceDataValue('Customers','Gender',c.Gender,'')
				, 'Contracting Area' = dbo.udf_GetReferenceDataValue('Touchpoints','Touchpoint', CAST(COALESCE(ap.CreatedBy, ap.LastModifiedTouchpointId) AS INT),'') 
				, COALESCE(ap.SubcontractorId, '')						AS 'Subcontractor Name'
				, 'Yes'													AS 'Action Plan'	
				, 'Current Employment Status' = dbo.udf_GetReferenceDataValue('EmploymentProgressions','CurrentEmploymentStatus',ep.CurrentEmploymentStatus,'')
				, 'Length Of Unemployment' = dbo.udf_GetReferenceDataValue('EmploymentProgressions','LengthOfUnemployment',ep.LengthOfUnemployment,'')
				, 'Current Learning Status' = dbo.udf_GetReferenceDataValue('LearningProgressions','CurrentLearningStatus',lp.CurrentLearningStatus,'')
				, 'Current Qualification Level' = dbo.udf_GetReferenceDataValue('LearningProgressions','CurrentQualificationLevel',lp.CurrentQualificationLevel,'')				
				, 'Channel' = dbo.udf_GetReferenceDataValue('Interactions','Channel',i.Channel,'')
				, CONVERT(VARCHAR(10), s.DateandTimeOfSession, 23)				AS 'Session Date'
				, 'Yes'											AS 'Participate Research Evaluation'
				, 'Priority Group' = dbo.udf_GetReferenceDataValue('ActionPlans','PriorityCustomer', pg.PriorityGroup, '')
	
	FROM		[dss-customers] c
	LEFT JOIN	[dss-contacts] con ON con.CustomerId = c.id
	LEFT JOIN	[dss-addresses] a ON a.CustomerId = c.Id
	LEFT JOIN	[dss-diversitydetails] d ON d.CustomerId = c.Id
	LEFT JOIN   [dss-employmentprogressions] ep on ep.CustomerId = c.id
	LEFT JOIN   [dss-learningprogressions] lp on lp.CustomerId = c.id
	LEFT JOIN   [dss-prioritygroups] pg on pg.CustomerId = c.id
	INNER JOIN	[dss-actionplans] ap ON ap.CustomerId = c.id
	INNER JOIN	[dss-interactions] i ON i.id = ap.InteractionId
	INNER JOIN	[dss-sessions] s ON s.id = ap.SessionId
	WHERE		c.OptInMarketResearch = 1 -- true
	AND			COALESCE(c.ReasonForTermination, 0) NOT IN (1,2)
	AND			ap.DateActionPlanCreated BETWEEN @startDate AND @endDate
END