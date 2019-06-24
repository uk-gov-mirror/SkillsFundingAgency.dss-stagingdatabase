/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/


IF COL_LENGTH(N'dss-goals-history',  N'LastModifiedTouchpointId') IS NOT NULL
BEGIN
	EXEC sp_rename 'dss-goals-history.LastModifiedTouchpointId', 'LastModifiedBy', 'COLUMN';  
END;