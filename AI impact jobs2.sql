CREATE DATABASE IF NOT EXISTS ai_powered_job;
Use ai_powered_job;

-- industry
CREATE TABLE industry (
    industry_id INT AUTO_INCREMENT PRIMARY KEY,
    industry_name VARCHAR(255) UNIQUE
)AUTO_INCREMENT = 5; 

-- nsert into the table of industry 
INSERT INTO industry (industry_name)
SELECT DISTINCT 
    CONCAT(
        UPPER(LEFT(TRIM(`Industry`), 1)),
        LOWER(SUBSTRING(TRIM(`Industry`), 2))
    )
FROM ai_job_trends_dataset;


-- location
CREATE TABLE location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(255) UNIQUE
) AUTO_INCREMENT = 10;
INSERT INTO location (location_name)
SELECT DISTINCT 
    CONCAT(
        UPPER(LEFT(TRIM(`Location`), 1)),
        LOWER(SUBSTRING(TRIM(`Location`), 2))
    )
FROM ai_job_trends_dataset;

-- Job 
CREATE TABLE job (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    job_title VARCHAR(255),
    job_status VARCHAR(50),
    required_education VARCHAR(100),
    experience_required_years INT,
    experience_category VARCHAR(50)
)AUTO_INCREMENT = 20;

-- updated the data for diffrent type of text--
UPDATE job
SET required_education = REPLACE(REPLACE(REPLACE(required_education,
    'â€™', ''''),
    'â€œ', '"'),
    'â€', '"');
    
-- make sure about the output --
SELECT DISTINCT required_education FROM job;

    
-- insert in to the table jobs and make the expeince categories--
INSERT INTO job (
    job_title, 
    job_status, 
    required_education, 
    experience_required_years, 
    experience_category
)
SELECT DISTINCT 
    CONCAT(
        UPPER(LEFT(TRIM(`Job Title`), 1)),
        LOWER(SUBSTRING(TRIM(`Job Title`), 2))
    ) AS job_title,
    
    CONCAT(
        UPPER(LEFT(TRIM(`Job Status`), 1)),
        LOWER(SUBSTRING(TRIM(`Job Status`), 2))
    ) AS job_status,
    
    CONCAT(
        UPPER(LEFT(TRIM(`Required Education`), 1)),
        LOWER(SUBSTRING(TRIM(`Required Education`), 2))
    ) AS required_education,
    
    `Experience Required (Years)` AS experience_required_years,
    
    CASE 
        WHEN `Experience Required (Years)` < 2 THEN 'Entry-Level'
        WHEN `Experience Required (Years)` BETWEEN 2 AND 5 THEN 'Junior'
        WHEN `Experience Required (Years)` BETWEEN 6 AND 8 THEN 'Senior'
        WHEN `Experience Required (Years)` BETWEEN 9 AND 12 THEN 'Supervisor'
        ELSE 'Expert'
    END AS experience_category
FROM ai_job_trends_dataset;

-- Fact table
CREATE TABLE fact_ai_impact_jobs (
    fact_id SERIAL PRIMARY KEY,
    location_id INT REFERENCES location(location_id),
    industry_id INT REFERENCES industry(industry_id),
    job_id INT REFERENCES job(job_id),
    ai_impact_level VARCHAR(50),
    median_salary_usd Decimal(10,2),
    job_openings_2024 INT,
    projected_openings_2030 INT,
    remote_work_ratio FLOAT,
    automation_risk FLOAT,
    gender_diversity FLOAT
);

INSERT INTO fact_ai_impact_jobs (
    location_id, industry_id, job_id,
    ai_impact_level, median_salary_usd,
    job_openings_2024, projected_openings_2030,
    remote_work_ratio, automation_risk, gender_diversity
)
SELECT 
    l.location_id,
    i.industry_id,
    j.job_id,
    d.`AI Impact Level`,
    d.`Median Salary (USD)`,
    d.`Job Openings (2024)`,
    d.`Projected Openings (2030)`,
    d.`Remote Work Ratio (%)`,
    d.`Automation Risk (%)`,
    d.`Gender Diversity (%)`
    -- refered every tabel here by it's alias
FROM ai_job_trends_dataset d
JOIN location l ON TRIM(LOWER(d.`Location`)) = l.location_name
JOIN industry i ON TRIM(LOWER(d.`Industry`)) = i.industry_name
JOIN job j
    ON TRIM(LOWER(d.`Job Title`)) = j.job_title
   AND TRIM(LOWER(d.`Job Status`)) = j.job_status
   AND TRIM(LOWER(d.`Required Education`)) = j.required_education
   AND CAST(d.`Experience Required (Years)` AS UNSIGNED) = j.experience_required_years;

--  validation --
SELECT COUNT(*) AS total_facts FROM fact_ai_impact_jobs;
SELECT * from job;

-- male & others
SELECT * from fact_ai_impact_jobs;
SELECT * from industry;
SELECT * from location;

-- insights--
-- Total number of industries, locations, and job titles
SELECT 
    COUNT(DISTINCT industry_id) AS total_industries,
    COUNT(DISTINCT location_id) AS total_locations,
    COUNT(DISTINCT job_id) AS total_jobs
FROM fact_ai_impact_jobs;
-- =====================================
-- 1) Average salary, total openings 2024, and projected 2030
-- =====================================
-- remove avergae --
SELECT 
    ROUND(AVG(median_salary_usd), 1) AS avg_salary_usd,
    ROUND(SUM(job_openings_2024) / 1000000, 1) AS total_openings_2024_millions,
    ROUND(SUM(projected_openings_2030) / 1000000, 1) AS total_projected_openings_2030_millions
FROM fact_ai_impact_jobs;

-- =====================================
-- 2) AI Automation Risk by Industry
-- =====================================

SELECT 
    i.industry_name AS industry,
    ROUND(AVG(automation_risk), 2) AS avg_automation_risk
FROM fact_ai_impact_jobs f
JOIN industry i ON f.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY avg_automation_risk DESC;

-- =====================================
-- 3️)Forecast: Job Market Shifts by 2030
-- =====================================

SELECT 
    i.industry_name AS industry,
    ROUND(SUM(job_openings_2024)/1000000, 2) AS openings_2024_million,
    ROUND(SUM(projected_openings_2030)/1000000, 2) AS projected_2030_million,
    ROUND((SUM(projected_openings_2030) - SUM(job_openings_2024)) / SUM(job_openings_2024) * 100, 2) AS growth_percent
FROM fact_ai_impact_jobs f
JOIN industry i ON f.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY growth_percent DESC;

-- =====================================
-- 4️) Top 10 Jobs with Highest Automation Risk
-- =====================================

SELECT 
    j.job_title,
    ROUND(AVG(automation_risk), 2) AS avg_automation_risk
FROM fact_ai_impact_jobs f
JOIN job j ON f.job_id = j.job_id
GROUP BY j.job_title
ORDER BY avg_automation_risk DESC
LIMIT 10;

-- =====================================
-- 5️) Top 10 Jobs with Lowest Automation Risk
-- =====================================

SELECT 
    j.job_title,
    ROUND(AVG(automation_risk), 2) AS avg_automation_risk
FROM fact_ai_impact_jobs f
JOIN job j ON f.job_id = j.job_id
GROUP BY j.job_title
ORDER BY avg_automation_risk ASC
LIMIT 10;

-- =====================================
-- 6️) Jobs Decreasing by 2030
-- =====================================

SELECT 
    j.job_title,
    SUM(job_openings_2024) AS openings_2024,
    SUM(projected_openings_2030) AS openings_2030,
    (SUM(projected_openings_2030) - SUM(job_openings_2024)) AS net_change
FROM fact_ai_impact_jobs f
JOIN job j ON f.job_id = j.job_id
GROUP BY j.job_title
-- الجزء ده بيجيب الوظيفة الي قلت فقط
HAVING net_change < 0
ORDER BY net_change ASC
LIMIT 10;

-- =====================================
-- 7️) Average Automation Risk by Location
-- =====================================

SELECT 
    l.location_name AS location,
    ROUND(AVG(automation_risk), 2) AS avg_automation_risk
FROM fact_ai_impact_jobs f
JOIN location l ON f.location_id = l.location_id
GROUP BY l.location_name
ORDER BY avg_automation_risk DESC;

-- =====================================
-- 8️) Average Automation Risk by Education Level
-- =====================================

SELECT 
    j.required_education AS education_level,
    ROUND(AVG(automation_risk), 2) AS avg_automation_risk
FROM fact_ai_impact_jobs f
JOIN job j ON f.job_id = j.job_id
GROUP BY j.required_education
ORDER BY avg_automation_risk DESC;

-- =====================================
-- 9️) Remote Work Ratio by Industry and Location
-- =====================================

-- Remote ratio by industry
SELECT 
    i.industry_name AS industry,
    ROUND(AVG(remote_work_ratio), 2) AS avg_remote_ratio
FROM fact_ai_impact_jobs f
JOIN industry i ON f.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY avg_remote_ratio DESC;

-- =====================================
-- Remote ratio by location
-- =====================================

SELECT 
    l.location_name AS location,
    ROUND(AVG(remote_work_ratio), 2) AS avg_remote_ratio
FROM fact_ai_impact_jobs f
JOIN location l ON f.location_id = l.location_id
GROUP BY l.location_name
ORDER BY avg_remote_ratio DESC;
-- =====================================
-- job openings between 2024 & 2030
-- =====================================
ALTER TABLE fact_ai_impact_jobs
ADD COLUMN job_openings_between_2024_and_2030 FLOAT;

UPDATE fact_ai_impact_jobs
SET job_openings_between_2024_and_2030 = projected_openings_2030 - job_openings_2024;


-- =====================================
-- Average Gender Diversity by Industry
-- =====================================

SELECT 
    i.industry_name AS industry,
    ROUND(AVG(f.gender_diversity), 2) AS avg_female_percentage,
    ROUND(100 - AVG(f.gender_diversity), 2) AS avg_male_percentage
FROM fact_ai_impact_jobs f
JOIN industry i ON f.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY avg_female_percentage DESC;

-- =====================================
-- Gender female and male 
-- =====================================
ALTER TABLE fact_ai_impact_jobs
ADD COLUMN gender_diversity_male FLOAT;

UPDATE fact_ai_impact_jobs
SET gender_diversity_male = 100 - gender_diversity;

-- =====================================
-- Gender Diversity by Location
-- =====================================

SELECT 
    l.location_name AS location,
    ROUND(AVG(f.gender_diversity), 2) AS avg_female_percentage,
    ROUND(100 - AVG(f.gender_diversity), 2) AS avg_male_percentage
FROM fact_ai_impact_jobs f
JOIN location l ON f.location_id = l.location_id
GROUP BY l.location_name
ORDER BY avg_female_percentage DESC;


SELECT 
    ROUND(AVG(gender_diversity), 2) AS avg_female_percentage,
    ROUND(100 - AVG(gender_diversity), 2) AS avg_male_percentage
FROM fact_ai_impact_jobs;


SET SQL_SAFE_UPDATES=0;