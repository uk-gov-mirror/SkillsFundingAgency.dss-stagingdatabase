CREATE FUNCTION [dbo].[dcc-collections](@touchpointId VARCHAR(10), @startDate DATE, @endDate DATE)

RETURNS @Result TABLE(CustomerID UNIQUEIDENTIFIER, DateOfBirth DATE, HomePostCode VARCHAR(10), 
                                        ActionPlanId UNIQUEIDENTIFIER, SessionDate DATE, SubContractorId VARCHAR(50), 
                                        AdviserName VARCHAR(100), OutcomeId UNIQUEIDENTIFIER,
                                        OutcomeType INT, OutcomeEffectiveDate DATE, OutcomePriorityCustomer INT)

AS

BEGIN  

DECLARE @endDateTime DATETIME2		-- date and time the period ends.

-- used to get latest address
DECLARE	@today DATE;
SET		@today = GETDATE()

--This is to ensure that any outcomes claimed or effice on the last day of the period gets included.
SET		@endDateTime = DATEADD(MS, -1, DATEADD(D, 1, CONVERT(DATETIME2,@endDate)));  


with sessionData	-- select ALL relevant records in to a temp table var.
AS
(
	SELECT			 s.id AS 'SessionID'
					,o.id AS 'OutcomeID'
					,s.CustomerId AS 'CustomerID'
					,ap.id AS 'ActionPlanID'
					,ap.InteractionId as 'InteractionId'
					,o.OutcomeClaimedDate AS 'OutcomeClaimedDate'
					,o.OutcomeEffectiveDate AS 'OutcomeEffectiveDate'
					,Convert(DATE,s.DateandTimeOfSession ) AS 'DateandTimeOfSession'
					,o.SubcontractorId AS 'SubcontractorID'
					,o.OutcomeType AS 'OutcomeType'
					,o.ClaimedPriorityGroup AS 'ClaimedPriorityGroup'
					,o.TouchpointId AS 'TouchpointID'
	FROM				[dss-sessions] s
	INNER JOIN			[dss-actionplans] ap ON ap.SessionId = s.id
	INNER JOIN			[dss-outcomes] o ON o.ActionPlanId = ap.id
	WHERE				o.OutcomeClaimedDate IS NOT NULL
	AND					o.OutcomeEffectiveDate IS NOT NULL
)
INSERT INTO @Result
	SELECT			
		 CustomerID
		,DateOfBirth
		,HomePostCode
		,ActionPlanId
		,SessionDate
		,SubContractorId
		,AdviserName
		,OutcomeID
		,OutcomeType
		,OutcomeEffectiveDate
		,OutcomePriorityCustomer
	FROM
	(
		SELECT				s.CustomerID									AS 'CustomerID'
							,s.SessionID									AS 'SessionID'
							,c.DateofBirth									AS 'DateOfBirth'
							,a.PostCode										AS 'HomePostCode'
							,s.ActionPlanId  								AS 'ActionPlanId' 
							,s.DateandTimeOfSession							AS 'SessionDate'
							,s.SubcontractorID								AS 'SubContractorId' 
							,adv.AdviserName								AS 'AdviserName'
							,s.OutcomeID									AS 'OutcomeID'
							,s.OutcomeType									AS 'OutcomeType'
							,s.OutcomeEffectiveDate							AS 'OutcomeEffectiveDate'
							,IIF(s.ClaimedPriorityGroup < 99, 1, 0)			AS 'OutcomePriorityCustomer'
							,s.OutcomeClaimedDate							AS 'OutcomeClaimedDate'
							,SessionClosureDate = 
								CASE s.OutcomeType
									WHEN 3 THEN	DATEADD(mm, 13, s.DateandTimeOfSession) 
									ELSE DATEADD(mm, 12, s.DateandTimeOfSession) 
								END
							,DATEADD(mm, -12, s.DateandTimeOfSession) AS 'PriorSessionDate'		
							,RANK() OVER(PARTITION BY s.CustomerID, IIF (s.OutcomeType < 3, s.OutcomeType, 3) ORDER BY s.OutcomeEffectiveDate, s.OutcomeID) AS 'Rank'  -- we rank to remove duplicates
			FROM			SessionData s
		INNER JOIN			[dss-customers] c								ON c.id = s.CustomerId
		--INNER JOIN			[dss-actionplans] ap							ON ap.id = s.ActionPlanId
		INNER JOIN			[dss-interactions] i							ON i.id = s.InteractionId
		OUTER APPLY			(	SELECT TOP 1	PostCode
								FROM			[dss-addresses] a
								WHERE			a.CustomerId = s.CustomerId											-- Get the latest address for the customer record
								AND				@today BETWEEN ISNULL(a.EffectiveFrom, DATEADD(dd,-1,@today)) AND ISNULL(a.EffectiveTo, DATEADD(dd,1,@today))
							) AS a
		LEFT JOIN			[dss-adviserdetails] adv ON adv.id = i.AdviserDetailsId									-- join to get adviser details
		WHERE				s.OutcomeEffectiveDate	BETWEEN @startDate AND @endDateTime								-- effective between period start and end date and time
		AND					s.OutcomeClaimedDate	BETWEEN @startDate AND @endDateTime								-- claimed between period start and end date and time
		AND					s.TouchpointID = @touchpointId															-- for the touchpoint requesting the collection
	) o
	WHERE					o.Rank = 1																				-- only send through 1 of each type of outcome	
	AND						Convert(DATE,o.OutcomeEffectiveDate) <= o.SessionClosureDate											-- within 12 or 13 months of the session date date
	AND						NOT EXISTS (
									SELECT			priorO.id
									FROM			SessionData priorS
									INNER JOIN		[dss-outcomes] priorO ON priorS.OutcomeID = priorO.id
									WHERE			priorO.OutcomeEffectiveDate < o.OutcomeEffectiveDate
									AND				priorO.id <> o.OutcomeID
									AND				priorO.OutcomeEffectiveDate IS NOT NULL		-- ensure the previous outcomes are effective
									AND				priorO.OutcomeClaimedDate IS NOT NULL		-- and claimed
									AND				priorO.CustomerId = o.CustomerId			-- and they belong to the same customer
									AND				priorO.TouchpointId <> '0000000999'			-- and touchpoint is not helpline
									AND				priorS.DateandTimeOfSession >= Convert(DATE,o.PriorSessionDate)	-- and the prior session date is more then 12/13 months
									AND				(											-- check validity of the previous outcomes we are considering
														( 
															priorO.OutcomeType = 3							-- the previous outcome should have been claimed within 13 months of the previous session date for Outcome Type 3
															AND
															DATEADD(mm, 13, priorS.DateandTimeOfSession)  >= priorO.OutcomeEffectiveDate 
														)
														OR											-- the previous outcome should have been claimed within 12 months of the previous session date for Outcome Types 1,2,4,5
														(
															priorO.OutcomeType IN ( 1,2,4,5 )			
															AND
															DATEADD(mm, 12, priorS.DateandTimeOfSession)  >= priorO.OutcomeEffectiveDate 
														)
													)
									AND				(
														(							-- Check there are no Outcomes of the same type (CSO and CMO)
															o.OutcomeType IN (1,2)
															AND	
															o.OutcomeType = priorO.OutcomeType
														)
														OR
														(							-- check there are no outcomes of the same type (JLO)
															o.OutcomeType IN (3,4,5)
															AND
															priorO.OutcomeType IN (3,4,5)
														)
													)
								)
  RETURN 
  
  END