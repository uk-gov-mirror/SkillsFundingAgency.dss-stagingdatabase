CREATE FUNCTION [dbo].[dcc-collections](@touchpointId VARCHAR(10), @startDate DATE, @endDate DATE)

RETURNS @Result TABLE(CustomerID UNIQUEIDENTIFIER, DateOfBirth DATE, HomePostCode VARCHAR(10), 
                                        ActionPlanId UNIQUEIDENTIFIER, SessionDate DATE, SubContractorId VARCHAR(50), 
                                        AdviserName VARCHAR(100), OutcomeId UNIQUEIDENTIFIER,
                                        OutcomeType INT, OutcomeEffectiveDate DATE, OutcomePriorityCustomer INT)

AS

BEGIN  

DECLARE @endDateTime DATETIME2		-- date and time the period ends.
SET		@endDateTime = DATEADD(MS, -1, DATEADD(D, 1, CONVERT(DATETIME2,@endDate)));  --This is to ensure that any outcomes claimed or effice on the last day of the period gets included.

-- used to get latest address
DECLARE	@today DATE;
SET		@today = GETDATE()

INSERT INTO @Result
	SELECT
	  CustomerId,
	  DateOfBirth,
	  HomePostCode,
	  ActionPlanId,
	  SessionDate,
      SubContractorId,
	  AdviserName,
	  OutcomeId,
	  OutcomeType,
	  OutcomeEffectiveDate,
	  OutcomePriorityCustomer
	FROM
	  (
		SELECT
			  o.CustomerId AS 'CustomerID',
			  c.DateofBirth AS 'DateOfBirth',
			  a.PostCode AS 'HomePostCode',
			  o.ActionPlanId AS 'ActionPlanId',
			  CONVERT(DATE, s.DateandTimeOfSession) AS 'SessionDate',
			  o.SubcontractorId AS 'SubContractorId',
			  adv.AdviserName AS 'AdviserName',
			  o.id AS 'OutcomeID',
			  o.OutcomeType AS 'OutcomeType',
			  o.OutcomeEffectiveDate AS 'OutcomeEffectiveDate',
			  IIF (o.ClaimedPriorityGroup < 99, 1, 0) AS 'OutcomePriorityCustomer',
			  o.OutcomeClaimedDate,
			  RANK() OVER(PARTITION BY o.CustomerId, IIF (o.OutcomeType < 3, o.OutcomeType, 3) ORDER BY o.OutcomeEffectiveDate, o.LastModifiedDate, o.id) AS 'Rank'
		FROM
			  [dss-outcomes] o
			  INNER JOIN [dss-customers] c ON c.id = o.CustomerId
			  INNER JOIN [dss-actionplans] ap ON ap.id = o.ActionPlanId
			  INNER JOIN [dss-sessions] s ON s.id = ap.SessionId
			  INNER JOIN [dss-interactions] i ON i.id = ap.InteractionId
			  OUTER APPLY (
			SELECT
				TOP 1 PostCode
			FROM
				[dss-addresses] a
			WHERE
				a.CustomerId = o.CustomerId -- Get the latest address for the customer record
				AND @today BETWEEN ISNULL(a.EffectiveFrom, DATEADD(dd, -1, @today))
				AND ISNULL(a.EffectiveTo, DATEADD(dd, 1, @today))
			) AS a
			  LEFT JOIN [dss-adviserdetails] adv ON adv.id = i.AdviserDetailsId -- join to get adviser details
			WHERE
			  o.OutcomeEffectiveDate BETWEEN @startDate
			  AND @endDateTime -- effective between period start and end date and time
			  AND o.OutcomeClaimedDate BETWEEN @startDate
			  AND @endDateTime -- claimed between period start and end date and time
			  AND o.touchpointId = @touchpointId -- for the touchpoint requesting the collection
			  --AND					o.CustomerId = '73D7FF48-BD2B-4BF4-BAA3-94068E90F41F'
		  ) o
	WHERE
	  o.Rank = 1
	  AND NOT EXISTS (
		SELECT
		  priorO.id
		FROM
		  [dss-outcomes] priorO
		WHERE
		  (
			(
			  -- if sustained employment check that there are no other outcomes of the same type in the last 13 months
			  o.OutcomeType = 3 -- sustained employment
			  AND priorO.OutcomeEffectiveDate >= DATEADD(mm, -13, o.OutcomeEffectiveDate)
			  AND priorO.OutcomeEffectiveDate < o.OutcomeEffectiveDate
			)
			OR (
			  -- if NOT sustained employment check that there are no other outcomes of the same type in the last 12 months
			  o.OutcomeType <> 3
			  AND priorO.OutcomeEffectiveDate >= DATEADD(mm, -12, o.OutcomeEffectiveDate)
			  AND priorO.OutcomeEffectiveDate < o.OutcomeEffectiveDate
			)
		  )
		  AND (
			(
			  -- Check there are no Outcomes of the same type (CSO and CMO)
			  o.OutcomeType IN (1, 2)
			  AND o.OutcomeType = priorO.OutcomeType
			)
			OR (
			  -- check there are no outcomes of the same type (JLO)
			  o.OutcomeType IN (3, 4, 5)
			  AND priorO.OutcomeType IN (3, 4, 5)
			)
		  )
		  AND priorO.OutcomeEffectiveDate IS NOT NULL -- ensure the previous outcomes are effective
		  AND priorO.OutcomeClaimedDate IS NOT NULL -- and claimed
		  AND priorO.CustomerId = o.CustomerId -- and they belong to the same customer
		  AND priorO.id <> o.OutcomeID -- and are not the same ID
		 -- AND priorO.TouchpointId <> '0000000999' -- and touchpoint is not helpline
	  ) 

  RETURN 
  
  END