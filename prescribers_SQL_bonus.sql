-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT
	COUNT(*) AS num_not_in_prescript_table
FROM prescriber
LEFT JOIN prescription
USING (npi)
WHERE prescription.npi IS NULL;

-- 2. a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT drug.generic_name,
	COUNT(*) AS total_scripts
FROM prescription
	INNER JOIN prescriber USING (npi)
	INNER JOIN drug USING (drug_name)
WHERE prescriber.specialty_description = 'Family Practice'
GROUP BY drug.generic_name
ORDER BY total_scripts DESC
LIMIT 5;

-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT drug.generic_name,
	COUNT(*) AS total_scripts
FROM prescription
	INNER JOIN prescriber USING (npi)
	INNER JOIN drug USING (drug_name)
WHERE prescriber.specialty_description = 'Cardiology'
GROUP BY drug.generic_name
ORDER BY total_scripts DESC
LIMIT 5;

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT drug.generic_name,
	COUNT(*) AS total_scripts
FROM prescription
	INNER JOIN prescriber USING (npi)
	INNER JOIN drug USING (drug_name)
WHERE prescriber.specialty_description = 'Family Practice'
	OR prescriber.specialty_description = 'Cardiology'
GROUP BY drug.generic_name
ORDER BY total_scripts DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
-- a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT 
	prescriber.npi,
	SUM(prescription.total_claim_count) AS total_claims,
	prescriber.nppes_provider_city AS city
FROM prescriber 
	INNER JOIN prescription USING (npi)
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- b. Now, report the same for Memphis.

SELECT 
	prescriber.npi,
	SUM(prescription.total_claim_count) AS total_claims,
	prescriber.nppes_provider_city AS city
FROM prescriber 
	INNER JOIN prescription USING (npi)
WHERE prescriber.nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT 
	prescriber.npi,
	SUM(prescription.total_claim_count) AS total_claims,
	prescriber.nppes_provider_city AS city
FROM prescriber 
	INNER JOIN prescription USING (npi)
WHERE prescriber.nppes_provider_city = 'MEMPHIS'
	OR prescriber.nppes_provider_city = 'NASHVILLE'
	OR prescriber.nppes_provider_city = 'KNOXVILLE'
	OR prescriber.nppes_provider_city = 'CHATTANOOGA'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC;

SELECT 
  npi,
  total_claims,
  city
FROM (
  SELECT 
    prescriber.npi,
    SUM(prescription.total_claim_count) AS total_claims,
    prescriber.nppes_provider_city AS city,
    ROW_NUMBER() OVER (PARTITION BY prescriber.nppes_provider_city ORDER BY SUM(prescription.total_claim_count) DESC) AS city_rank
  FROM prescriber
  INNER JOIN prescription USING (npi)
  WHERE prescriber.nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
  GROUP BY prescriber.npi, prescriber.nppes_provider_city
) ranked
WHERE city_rank <= 5
ORDER BY city, total_claims DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT
	AVG(overdose_deaths) AS avg_deaths
FROM overdose_deaths;

SELECT *
FROM fips_county;

SELECT *
FROM overdose_deaths;

SELECT 
	fc.county,
	od.overdose_deaths
FROM overdose_deaths AS od
	INNER JOIN fips_county AS fc
	ON (od.fipscounty::TEXT = fc.fipscounty)
WHERE od.overdose_deaths > (
	SELECT AVG(overdose_deaths)
	FROM overdose_deaths);

-- 5. a. Write a query that finds the total population of Tennessee.

-- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.