USE NEW_SCHEMA;
SELECT 
    *
FROM
    POPULATION;
SELECT 
    *
FROM
    CENSUS;
ALTER TABLE CENSUS_INDIA RENAME CENSUS;
ALTER TABLE POPULATION_INDIA RENAME POPULATION;
DESC CENSUS;
DESC POPULATION;
-- TOTAL POPULATION IN IDIA
SELECT 
    SUM(POPULATION) AS 'INDIA POPULATION'
FROM
    POPULATION;
-- AVERAGE GROWTH OF POPULATION
SELECT 
    ROUND(AVG(GROWTH), 2) * 100 AS AVERAGE_GROWTH_PERCENTAGE
FROM
    CENSUS;
-- AVERAGE GROWTH BY STATE
SELECT 
    ROUND(AVG(GROWTH), 2) * 100 AS AVERAGE_GROWTH_PERCENTAGE,
    STATE
FROM
    CENSUS
GROUP BY STATE
ORDER BY ROUND(AVG(GROWTH), 1) * 100 DESC;
-- AVERAGE SEX RATIO
SELECT 
    AVG(SEX_RATIO) AS AVERAGE_SEX_RATIO
FROM
    CENSUS;
-- AVERAGE SEX RATIO BY STATE
SELECT 
    ROUND(AVG(SEX_RATIO), 2) AS AVERAGE_SEX_RATIO, STATE
FROM
    CENSUS
GROUP BY STATE
ORDER BY ROUND(AVG(SEX_RATIO), 2) DESC;
CREATE VIEW TOP_3_LITERACY_STATE AS
    SELECT 
        LITERACY, STATE
    FROM
        CENSUS
    ORDER BY LITERACY DESC
    LIMIT 3;
SELECT 
    *
FROM
    TOP_3_LITERACY_STATE;
-- RANKING STATES USING WINDOWS FUNCTIONS
SELECT DISTRICT , POPULATION ,RANK() OVER(ORDER BY POPULATION DESC) AS POPULATION_RANK
FROM POPULATION;
-- POPULATION DENSITY
SELECT STATE, POPULATION, AREA_KM2, POPULATION/AREA_KM2 AS POPULATION_DENSITY,
RANK() OVER(PARTITION BY STATE ORDER BY POPULATION/AREA_KM2 DESC) AS DENSITY_RANK
FROM POPULATION;
-- SUBQUERIES
-- Question 1: Find the districts with a population greater than the average population of their respective states.
SELECT 
    P.DISTRICT, P.STATE, P.POPULATION
FROM
    POPULATION P
        JOIN
    (SELECT 
        STATE, AVG(POPULATION) AS AVERAGE_POPULATION
    FROM
        POPULATION
    GROUP BY STATE) AVERAGE_POPULATION_STATE ON P.STATE = AVERAGE_POPULATION_STATE.STATE
WHERE
    P.POPULATION > AVERAGE_POPULATION_STATE.AVERAGE_POPULATION;
-- 2. Retrieve the states with the highest population density, where the density is
--  calculated as the total population divided by the sum of the areas of all districts in that state.
SELECT 
    STATE, POPULATION / AREA_KM2 AS DENSITY
FROM
    POPULATION
WHERE
    POPULATION / AREA_KM2 = (SELECT 
            MAX(POPULATION / AREA_KM2)
        FROM
            POPULATION);
--  3.Find the districts that have a population greater than the 
-- average population of all districts within the state 
SELECT 
    P.DISTRICT, P.POPULATION
FROM
    POPULATION P
        JOIN
    (SELECT 
        AVG(POPULATION) AS AVG_POPULATION, DISTRICT
    FROM
        POPULATION AP
    GROUP BY DISTRICT) AP ON AP.DISTRICT = P.DISTRICT
WHERE
    P.POPULATION > AP.AVG_POPULATION;
-- JOINS
-- Question 1: List the districts along with their state names and the Literacy for each district, 
-- combining data from the "Population" and "Census" tables.
SELECT 
    P.DISTRICT, P.STATE, C.LITERACY
FROM
    POPULATION P
        JOIN
    CENSUS C ON P.DISTRICT = C.DISTRICT;
-- 2, Find the top three states with the highest average population density and sex ratio 
-- , considering both "Population" and "Census" data.
SELECT DISTINCT
    (P.STATE), P.POPULATION / P.AREA_KM2 AS POPULATION_DENSITY
FROM
    POPULATION P
        JOIN
    CENSUS C ON P.STATE = C.STATE
ORDER BY P.POPULATION / P.AREA_KM2 DESC
LIMIT 3;

-- WINDOWS FUNCTIONS
-- Rank the districts within each state based on their population, and display the 
-- top three districts with the highest populations in each state.
WITH RANKEDDISTRICTS AS
(SELECT STATE,DISTRICT,POPULATION,
RANK() OVER(PARTITION BY STATE ORDER BY POPULATION DESC) AS POPULATION_RANK
FROM POPULATION)
SELECT STATE , DISTRICT, POPULATION,POPULATION_RANK
FROM RANKEDDISTRICTS
WHERE POPULATION_RANK <=3
ORDER BY STATE ,POPULATION DESC;
-- Common Table Expressions
-- Create a CTE that contains the states with a total population above a 4500000
--  and then retrieve the districts within those states.
WITH POPULATIONDIST AS
(SELECT STATE,DISTRICT FROM POPULATION 
WHERE POPULATION >=4500000)
SELECT STATE,DISTRICT FROM POPULATIONDIST
ORDER BY STATE,DISTRICT;
-- Recursive query
-- 1: 1: Generate a hierarchical report of states and their respective districts, where states are parent nodes and districts are child nodes.
WITH RECURSIVE StateDistrictHierarchy AS (
  -- Anchor query: Select the root nodes (states) that have no parent
  SELECT State, District, 0 AS Level
  FROM POPULATION
  WHERE State NOT IN (SELECT District FROM POPULATION)
  
  UNION ALL
  
  -- Recursive query: Join child nodes (districts) with their respective parent states
  SELECT s.State, s.District, Level + 1
  FROM POPULATION s
  INNER JOIN StateDistrictHierarchy h ON s.State = h.District
)
SELECT State, District, Level
FROM StateDistrictHierarchy
ORDER BY State, District;
