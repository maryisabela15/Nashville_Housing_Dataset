/*
  Project 1: Data Cleaning
  Data: Nashville Housing Data for Data Cleaning
  Language: SQL
*/

/* Step 1: Create a table using PostgreSQL with the column names and the data type of the .csv file 
           Nashville Housing Data for Data Cleaning */
/* Step 2: Import the data into the table */

DROP TABLE housing;

CREATE TABLE housing (
UniqueID INT PRIMARY KEY,
ParcelID TEXT,
LandUse VARCHAR(50),
PropertyAddress TEXT,
SaleDate TIMESTAMP,
SalePrice INT,
LegalReference TEXT,
SoldAsVacant VARCHAR(10),
OwnerName VARCHAR(60),
OwnerAddress TEXT,
Acreage NUMERIC(5,2),
TaxtDistrict TEXT,
LandValue INT,
BuildingValue INT,
TotalValue INT,
YearBuilt INT,
Bedrooms INT,
FullBath INT,
HalfBath INT
);

/* Step 3: Transforming and cleaning data */

-- Explore dataset

SELECT * FROM housing;

--1) Create a new column with only the date

ALTER TABLE housing
ADD SaleDateConvert DATE;

UPDATE housing
SET SaleDateConvert = DATE(saledate);
    
-- --------------------------------------------------

-- 2) Populated Property Address Data
-- There are some NULL values in Property Address

SELECT * FROM housing;

-- Self Join to see where are the NULL Values

SELECT tb1.parcelID, tb1.propertyaddress,
       tb2.parcelID, tb2.propertyaddress
FROM housing as tb1
JOIN housing as tb2
  ON tb1.parcelid = tb2.parcelid
  AND tb1.uniqueid <> tb2.uniqueid
WHERE tb1.propertyaddress IS NULL ; 

-- Update the NULL values with the real values
-- Using the COALESCE function to update those NULL values

UPDATE housing
SET propertyaddress = COALESCE(tb1.propertyaddress, tb2.propertyaddress)
FROM housing as tb1
JOIN housing as tb2
  ON tb1.parcelid = tb2.parcelid
  AND tb1.uniqueid <> tb2.uniqueid
WHERE tb1.propertyaddress IS NULL;

-- -----------------------------------------------------------------------

-- 3) Separate Property Address into different columns
-- I use SUBSTRING, POSITION, and RIGHT functions to separate substrings

SELECT * FROM housing;

SELECT 
    SUBSTRING(propertyaddress,1, POSITION(',' IN propertyaddress)-1) as Address,
	RIGHT(propertyaddress,POSITION(',' IN propertyaddress)-2) as City	
FROM housing;

-- Create two new columns to add Address and City

ALTER TABLE housing
ADD Address VARCHAR(60);

UPDATE housing
SET Address = SUBSTRING(propertyaddress,1, POSITION(',' IN propertyaddress)-1);

ALTER TABLE housing
ADD City VARCHAR(50);

UPDATE housing
SET City = RIGHT(propertyaddress,POSITION(',' IN propertyaddress)-2);
  
SELECT propertyaddress, address, city
FROM housing;


-- ----------------------------------------------
-- 4) Separate Owners Address into different columns
-- I use SUSTRING, RIGTH, and SPLIT_PART Function

SELECT owneraddress
FROM housing;
		  
SELECT owneraddress,
    SUBSTRING(owneraddress,1, POSITION(',' IN owneraddress)-1) as o_address,
	SPLIT_PART(owneraddress,',',2) as o_city,
	RIGHT(owneraddress, LENGTH(SPLIT_PART(owneraddress,',',3))) as o_state
FROM housing;

 -- Create three new columns to add Address, City, and State
 
ALTER TABLE housing
ADD o_address VARCHAR(60),
ADD o_city VARCHAR(60),
ADD o_state VARCHAR(60);

UPDATE housing
SET o_address = SUBSTRING(owneraddress,1, POSITION(',' IN owneraddress)-1);

UPDATE housing
SET o_city = SPLIT_PART(owneraddress,',',2);

UPDATE housing
SET o_state = RIGHT(owneraddress, LENGTH(SPLIT_PART(owneraddress,',',3)));


SELECT owneraddress,
       o_address,
	   o_city,
	   o_state
FROM housing;	  


-- ---------------------------------------------------------------------

-- 5) We wanna change Y and N to Yes and No in "Sold as vacant" field

SELECT soldasvacant FROM housing;

SELECT DISTINCT soldasvacant, COUNT(soldasvacant)
FROM housing
GROUP BY soldasvacant
ORDER BY 2;

-- Update column with the new values

UPDATE housing
SET soldasvacant = CASE
                      WHEN soldasvacant = 'N' THEN 'No'
					  WHEN soldasvacant = 'Y' THEN 'Yes'
					  ELSE soldasvacant
				   END;	  

-- -----------------------------------------------------------      
                  
 -- 6) Remove Duplicate values   

SELECT * FROM housing;

 -- I use the ROW_NUMBER Function to search the duplicate values
 
SELECT *
FROM (SELECT *,
	         ROW_NUMBER() OVER (PARTITION BY parcelid, 
								             propertyaddress,
							                 saleprice,
							                 saledate,
							                 legalreference
							   ORDER BY uniqueid) as rownumber
	  FROM housing  
	 ) as tb1
WHERE rownumber > 1;

-- Delete duplicate values

DELETE FROM housing
WHERE 
	uniqueid IN ( SELECT UniqueID 
	              FROM ( SELECT *,
		                 ROW_NUMBER() OVER (PARTITION BY parcelid, 
							                             propertyaddress, 
                                                         saleprice, 
                                                         saledate, 
                                                         legalreference
                        ORDER BY uniqueid) as rownumber
                        FROM housing
					   ) as tb1
                    WHERE rownumber > 1
				);


-- ------------------------------------------------------------------------------

-- 7) Remove unwanted columns

SELECT *
FROM housing;

ALTER TABLE  housing
DROP COLUMN propertyaddress;

ALTER TABLE housing
DROP COLUMN owneraddress;
	   