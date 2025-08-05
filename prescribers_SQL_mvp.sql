-- Prescribers Database
-- For this exericse, you'll be working with a database derived from the Medicare Part D Prescriber Public Use File. More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, drug_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, drug_name
ORDER BY total_claims DESC;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, total_claim_count
FROM prescriber
	INNER JOIN prescription
	USING(npi);

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC;

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_claims DESC;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT specialty_description, nppes_provider_last_org_name
FROM prescriber
	LEFT JOIN prescription
	USING (npi)
	WHERE prescription.npi IS NULL;

-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?



-- 3. a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name,
	SUM(total_drug_cost) AS highest_cost
FROM drug d
	INNER JOIN prescription p
	ON d.drug_name = p.drug_name
GROUP BY generic_name
ORDER BY highest_cost DESC;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name,
	ROUND(SUM(total_drug_cost / 365), 2) AS cost_per_day
FROM drug d
	INNER JOIN prescription p
	ON d.drug_name = p.drug_name
GROUP BY generic_name
ORDER BY cost_per_day DESC;

SELECT generic_name,
	ROUND(SUM(total_drug_cost) / NULLIF(SUM(total_day_supply), 0), 2) AS cost_per_day
FROM drug d
	INNER JOIN prescription p
	ON d.drug_name = p.drug_name
GROUP BY generic_name
ORDER BY cost_per_day DESC;

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this.

SELECT drug_name,
	CASE
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
	END AS drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
	CASE
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
	END AS drug_type,
	SUM(total_drug_cost::MONEY) AS money_spent
FROM drug d
	INNER JOIN prescription p
	ON d.drug_name = p.drug_name
WHERE opioid_drug_flag = 'Y' OR antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY money_spent DESC;

SELECT
  drug_type,
  SUM(total_drug_cost::MONEY) AS money_spent
FROM (
  SELECT
    CASE
      WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
      WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
      ELSE 'neither'
    END AS drug_type,
    p.total_drug_cost
  FROM drug d
    INNER JOIN prescription p
    ON d.drug_name = p.drug_name
  WHERE d.opioid_drug_flag = 'Y' OR d.antibiotic_drug_flag = 'Y'
) AS drug_summary
GROUP BY drug_type
ORDER BY money_spent DESC;


-- 5. a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT *
FROM cbsa;

SELECT 
	COUNT(DISTINCT cbsaname) AS county
	FROM cbsa
	ORDER BY county;

SELECT cbsaname,
COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN%'
GROUP BY cbsaname;

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname,
	SUM(population) AS total_pop
	FROM cbsa
	INNER JOIN population
	USING(fipscounty)
	GROUP BY cbsaname
	ORDER BY total_pop DESC;

SELECT cbsaname,
	SUM(population) AS total_pop
	FROM cbsa
	INNER JOIN population
	USING(fipscounty)
	GROUP BY cbsaname
	ORDER BY total_pop;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT cbsaname, population
	FROM population
	LEFT JOIN cbsa
	USING(fipscounty)
	WHERE cbsaname IS NULL
	ORDER BY population DESC;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count,
	CASE
	WHEN opioid_drug_flag = 'Y' THEN 'Yes'
	ELSE 'No'
	END AS is_an_opioid
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count,
	CASE
	WHEN opioid_drug_flag = 'Y' THEN 'Yes'
	ELSE 'No'
	END AS is_an_opioid
FROM prescription
INNER JOIN drug USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.
-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT *
FROM prescriber;

SELECT npi, drug_name
FROM prescriber p
	CROSS JOIN drug d
WHERE d.opioid_drug_flag = 'Y'
	AND p.specialty_description ILIKE 'Pain Management'
	AND p.nppes_provider_city ILIKE 'Nashville';


-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT combos.npi, combos.drug_name,
	COALESCE(prescription.total_claim_count, 0) AS total_claim_count
FROM (
	SELECT npi, drug_name
	FROM prescriber p
	CROSS JOIN drug d
WHERE p.specialty_description ILIKE 'Pain Management'
	AND p.nppes_provider_city ILIKE 'Nashville'
	AND d.opioid_drug_flag = 'Y'
) AS combos
LEFT JOIN prescription ON combos.npi = prescription.npi
	AND combos.drug_name = prescription.drug_name;