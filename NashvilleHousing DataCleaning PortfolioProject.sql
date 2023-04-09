/*
Cleaning Data in SQL Queries
*/

SELECT * FROM project..NashvilleHousing$

-- Standardize Date Format


-- Shows Old Date Format 
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing$


ALTER TABLE NashvilleHousing$
ADD ConvertedSaleDate Date

UPDATE NashvilleHousing$
SET ConvertedSaleDate = CONVERT(Date, SaleDate)

-- Shows new Date Format
SELECT ConvertedSaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing$



-- Populate Property Address

SELECT *
FROM project..NashvilleHousing$
ORDER BY ParcelID


-- Some PropertyAddress had null Values even though they had same ParcelID
SELECT Address1.ParcelID, Address1.PropertyAddress, Address2.ParcelID, Address2.PropertyAddress, ISNULL(Address1.PropertyAddress,Address2.PropertyAddress)
FROM project..NashvilleHousing$ Address1
JOIN project..NashvilleHousing$ Address2
	on Address1.ParcelID = Address2.ParcelID
	AND Address1.[UniqueID ] <> Address2.[UniqueID ]
WHERE Address1.PropertyAddress is NULL OR Address2.PropertyAddress is NULL


UPDATE Address1
SET PropertyAddress = ISNULL(Address1.PropertyAddress,Address2.PropertyAddress)
FROM project..NashvilleHousing$ Address1
JOIN project..NashvilleHousing$ Address2
	on Address1.ParcelID = Address2.ParcelID
	AND Address1.[UniqueID ] <> Address2.[UniqueID ]
WHERE Address1.PropertyAddress is NULL OR Address2.PropertyAddress is NULL



-- Breaking out Address into Individual Columns (Address, City, State)

-- Splitting Property Address 

SELECT
SUBSTRING(PropertyAddress, 0, CHARINDEX(',',PropertyAddress)) as Address,
CHARINDEX(',',PropertyAddress),
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, Len(PropertyAddress)) as City
FROM project..NashvilleHousing$


ALTER TABLE NashvilleHousing$
ADD PropertySplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing$
ADD PropertySplitCityTown nvarchar(255)

UPDATE NashvilleHousing$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 0, CHARINDEX(',',PropertyAddress))

UPDATE NashvilleHousing$
SET PropertySplitCityTown = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, Len(PropertyAddress))

SELECT PropertyAddress 
FROM project..NashvilleHousing$


--Splitting Owner Address

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
FROM project..NashvilleHousing$

ALTER TABLE NashvilleHousing$
ADD OwnerSplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing$
ADD OwnerSplitCityTown nvarchar(255)

ALTER TABLE NashvilleHousing$
ADD OwnerSplitState nvarchar(255)

UPDATE NashvilleHousing$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

UPDATE NashvilleHousing$
SET OwnerSplitCityTown = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

UPDATE NashvilleHousing$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

SELECT *
FROM project..NashvilleHousing$


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT distinct(SoldAsVacant), count(SoldAsVacant)
FROM project..NashvilleHousing$
Group By SoldAsVacant
Order By 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From project..NashvilleHousing$

Update NashvilleHousing$
SET SoldAsVacant = CASE 
	When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END



-- Remove Duplicates

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

From project..NashvilleHousing$
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress



-- Delete Unused Columns

-- Already created new tables for these. 
ALTER TABLE project..NashvilleHousing$
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate