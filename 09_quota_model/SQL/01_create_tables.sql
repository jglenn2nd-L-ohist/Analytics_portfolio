---------------------------------------------------------
-- Project: Quota and Commission Model (09_quota_model)
-- File name: 01_create_tables.sql
-- Table: regions; reps; calendar; sales
-- Business question:  Does the flat-tier commission 
--                     structure overpay, and if so, 
--                     where and by how much?
-- Purpose:   Build the quota_model schema (types, keys, 
--            status check) that the Python loader fills
-- Author: J.Glenn
-- Date: October 2026
---------------------------------------------------------
-- Create schema for quota_model database
USE quota_model;
GO

DROP TABLE IF EXISTS dbo.sales;
DROP TABLE IF EXISTS dbo.calendar;
DROP TABLE IF EXISTS dbo.reps;
DROP TABLE IF EXISTS dbo.regions;
GO

-- Create regions table
CREATE TABLE dbo.regions (
	region_id            INT		    NOT NULL PRIMARY KEY
,	region_name          VARCHAR(50)    NOT NULL
,	target_headcount     INT            NOT NULL
,	year1_monthly_seed   DECIMAL(12,2)  NOT NULL
);
GO

-- Create reps table
CREATE TABLE dbo.reps   (
	rep_id		        VARCHAR(10)		NOT NULL PRIMARY KEY
,	region_id			INT				NOT NULL FOREIGN KEY REFERENCES dbo.regions(region_id)
,	hire_date			DATE			NOT NULL
,	term_date			DATE	
);
GO

-- Create calendar table
CREATE TABLE dbo.calendar	(
	month_start			DATE			NOT NULL PRIMARY KEY
,	month_end			DATE			NOT NULL
,	payout_date			DATE			NOT NULL
);
GO

-- Create sales table
CREATE TABLE dbo.sales	(
	sale_id				VARCHAR(20)		NOT NULL PRIMARY KEY
,	sale_date			DATE			NOT NULL
,	rep_id				VARCHAR(10)		NOT NULL FOREIGN KEY REFERENCES dbo.reps(rep_id)
,	region_id			INT				NOT NULL FOREIGN KEY REFERENCES dbo.regions(region_id)
,	amount				DECIMAL(12,2)	NOT NULL
,	status				VARCHAR(20)		NOT NULL			
,	status_date			DATE
,	CONSTRAINT ck_sales_status CHECK (status IN ('completed','returned','canceled'))
);
GO