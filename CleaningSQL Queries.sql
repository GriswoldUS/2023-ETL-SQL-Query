Select *
FROM CleaningSQL..Sheet1$

-- Standardized Sale Date, Converting this into a readable format that does not include "Time"

Select SaleDate, CONVERT(Date,SaleDate)
From CleaningSQL..Sheet1$

-- Updating the Sheet, reads as completed but does not show on the table

Update Sheet1$
SET SaleDate = CONVERT(Date,SaleDate)

-- Alternative method is to add a separate column, that inputs converted data used previously

ALTER TABLE Sheet1$
Add SaleDateConv Date; 

Update Sheet1$
SET SaleDateConv = CONVERT(Date, SaleDate) 

-- Now data appears 
-------------------------------------------------------------------------------
-- Populating Property Address Data, 
Select *
From [CleaningSQL]..Sheet1$
-- Where PropertyAddress is NULL
-- There are unpopulated addresses marked as "NULL"
Order By ParcelID
-- There are duplicate Parcel IDs

-- Showing that by filtering through ParcelID, we can see the addresses though they are unpopulated
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From CleaningSQL..Sheet1$ a
JOIN CleaningSQL..Sheet1$ b
	on a.ParcelID = b.ParcelID -- These are the same 
	AND a.[UniqueID ] <> b.[UniqueID ] -- Unique IDs are not equal to one another, basically inverse polarity
Where a.PropertyAddress is NULL

-- Where the Parcel IDs are the same, I want different UniqueIDs, since they do not appear twice
--

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) 
From CleaningSQL..Sheet1$ a
JOIN CleaningSQL..Sheet1$ b
	on a.ParcelID = b.ParcelID -- These are the same 
	AND a.[UniqueID ] <> b.[UniqueID ] -- Unique IDs are not equal to one another, basically inverse polarity
Where a.PropertyAddress is NULL

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
From CleaningSQL..Sheet1$ a
JOIN CleaningSQL..Sheet1$ b
	on a.ParcelID = b.ParcelID -- These are the same 
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


-- Breaking out Address into Individual Columns (Address, City, State) 
-- Addresses include the city separated by a delimiter
-- I use charindex to target the delimiter. 

Select PropertyAddress
From CleaningSQL..Sheet1$

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address -- Remove comma, "1" in substring designates starting position
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) as City

FROM CleaningSQL..Sheet1$

-- I will now create two separate columns for this data

ALTER TABLE Sheet1$
Add PropertySplitAddress Nvarchar(255);

Update Sheet1$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE Sheet1$
Add PropertySplitCity Nvarchar(255);

Update Sheet1$
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

-- 

Select OwnerAddress
From CleaningSQL..Sheet1$

-- Alternative, quicker method of separating these

Select
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3) as OwnerStreetAddress
, PARSENAME(REPLACE(OwnerAddress, ',','.'), 2) as OwnerCity
, PARSENAME(REPLACE(OwnerAddress, ',','.'), 1) as OwnerState
From CleaningSQL..Sheet1$


ALTER TABLE Sheet1$
Add OwnerSplitAddress Nvarchar(255);

Update Sheet1$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE Sheet1$
Add OwnerSplitCity Nvarchar(255);

Update Sheet1$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE Sheet1$
Add OwnerSplitState Nvarchar(255);

Update Sheet1$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)

-- Columns added
-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant) 
From CleaningSQL..Sheet1$
Group by SoldAsVacant


Select SoldAsVacant 
, CASE When SoldAsVacant = 'Y' Then 'YES' 
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
From CleaningSQL..Sheet1$

Update CleaningSQL..Sheet1$
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'YES' 
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END


-- Removing Duplicates, 
	-- Create a CTE 
WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference 
				 ORDER BY 
					UniqueID
					) row_num

FROM CleaningSQL..Sheet1$
)


Select * --DELETE
FROM RowNumCTE
Where row_num > 1 


-- Deleting Unused Columns

Select * 
From CleaningSQL..Sheet1$

ALTER TABLE CleaningSQL..Sheet1$
DROP Column OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE CleaningSQL..Sheet1$ 
Drop Column SaleDate -- Already altered


