-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.

-- MASTER TABLE = PEOPLE
SELECT * 
FROM people

SELECT * 
FROM TEAMS

-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 
-- Answer: According to the readme, 1871 to 2016/2017 season. The code to back that up is: 
SELECT MIN(debut), MAX(finalgame)
FROM people

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT namefirst, namelast, MIN(height) AS height, G_all, t.name AS team
FROM people AS p
INNER JOIN appearances AS a
ON p.playerid = a.playerid
INNER JOIN teams AS t
ON a.teamid = t.teamid
GROUP BY height, namelast, namefirst, G_all, team
ORDER BY height
LIMIT 1;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT DISTINCT p.playerid AS id, namefirst, namelast, COALESCE(SUM(salary), 0) AS salary
FROM people AS p
INNER JOIN salaries AS ss
ON p.playerid = ss.playerid
WHERE p.playerid IN 
(
SELECT playerid
	FROM collegeplaying as c
	JOIN schools
	USING (schoolid)
	WHERE schoolname LIKE 'Vanderbilt University'
)
GROUP BY id, namefirst, namelast
ORDER BY salary DESC 

-- David Price earned $81,851,296

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
select * from fielding

SELECT 
CASE WHEN pos ='OF' THEN 'Outfield'
		WHEN pos = 'SS' THEN 'Infield'
		WHEN pos = '1B' THEN 'Infield'
		WHEN pos = '2B' THEN 'Infield'
		WHEN pos = '3B' THEN 'Infield'
		WHEN pos = 'P' THEN 'Battery'
		WHEN pos = 'C' THEN 'Battery'
		ELSE 'None' END AS position, SUM(PO) AS putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT 
   CASE WHEN yearid  BETWEEN 1920 and 1929 THEN '1920s'
		WHEN yearid  BETWEEN 1930 and 1939 THEN '1930s'
		WHEN yearid  BETWEEN 1940 and 1949 THEN '1940s'
		WHEN yearid  BETWEEN 1950 and 1959 THEN '1950s'
		WHEN yearid  BETWEEN 1960 and 1969 THEN '1960s'
		WHEN yearid  BETWEEN 1970 and 1979 THEN '1970s'
		WHEN yearid  BETWEEN 1980 and 1989 THEN '1980s'
		WHEN yearid  BETWEEN 1990 and 1999 THEN '1990s'
		WHEN yearid  BETWEEN 2000 and 2009 THEN '2000s'
		WHEN yearid  BETWEEN 2010 and 2019 THEN '2010s'
		ELSE 'not needed' END AS decade, 
		ROUND(AVG(so), 2) AS strikeout_average, ROUND(AVG(hr), 2) AS homerun_average
FROM batting
GROUP BY decade

select avg(so)
from batting
where yearid BETWEEN 1990 and 1999

-- The trend I see is 1. The more home runs, the more strikeouts and 2. the homerun average has gone up because of (presumed) steroid use.

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

WITH edit AS
	(
		SELECT DISTINCT playerid, COALESCE(SUM(sb), 0) AS stolen, COALESCE(SUM(cs), 0) AS failed, COALESCE(SUM(sb), 0) + COALESCE(SUM(cs), 0) AS total_attempt
		FROM batting
		GROUP BY playerid
		ORDER BY playerid
	)
SELECT batting.playerid, ROUND(((CAST(stolen AS numeric) / CAST(total_attempt AS numeric))*100), 2) AS percent_success
FROM batting
INNER JOIN edit
ON batting.playerid = edit.playerid
WHERE total_attempt > 19
	AND yearid = 2016
GROUP BY batting.playerid, stolen, total_attempt
ORDER BY percent_success DESC

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
select teamid, w from teams
group by teamid, w

SELECT name, max(w)
FROM teams
WHERE WSWin LIKE 'N'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name, w
ORDER BY w DESC
-- Largest Number of Wins with no WS: 116
SELECT name, min(w)
FROM teams
WHERE WSWin LIKE 'Y'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name, w
ORDER BY w
--Smallest Number of Wins with WS: 63
SELECT name, min(w)
FROM teams
WHERE WSWin LIKE 'Y'
	AND yearid BETWEEN 1970 AND 2016
	AND yearid <> 1981
GROUP BY name, w
ORDER BY w
--Excluded 1981 due to strike. Smallest Number 83

--Find Percent of WS Wins that are also the max wins

-- WITH maxwins AS (
-- 	SELECT yearid, MAX(w) AS mostwins
-- 	FROM teams
-- 	GROUP BY yearid),
-- 	totalwins AS(
-- 	SELECT t.yearid, t.name, mostwins, t.wswin, SUM(CASE WHEN wswin='Y' THEN 1 ELSE 0 END) AS wins
-- 	FROM teams AS t
-- 		LEFT JOIN maxwins AS m
-- 		ON t.yearid = m.yearid AND t.w = m.mostwins
-- 	WHERE t.yearid > 1969
-- 		AND m.mostwins IS NOT NULL
-- 		AND wswin IS NOT NULL
-- 	GROUP BY t.yearid, t.name, mostwins, t.wswin
-- 	ORDER BY t.yearid
-- 	)
-- SELECT (
-- 	((SELECT CAST(COUNT(wswin) AS numeric)
-- 	 FROM teams
-- 	 WHERE wswin LIKE 'Y') / CAST(COUNT(yearid) AS numeric)*100)) AS answer
-- FROM teams

with maxwins AS (
	SELECT yearid, MAX(w) AS mostwins
	FROM teams
	GROUP BY yearid
	),
cte AS (
	SELECT t.yearid, t.name, mostwins, t.wswin, SUM(CASE WHEN wswin ='Y' THEN 1 ELSE 0 END) :: numeric AS wins
FROM teams AS t
LEFT JOIN maxwins AS m
ON t.yearid = m.yearid AND t.w = m.mostwins
WHERE t.yearid > 1969
AND m.mostwins IS NOT NULL
AND wswin IS NOT NULL
GROUP BY t.yearid, t.name, mostwins, t.wswin
ORDER BY t.yearid
	)
SELECT SUM(wins) OVER () / COUNT(yearid) OVER () *100 AS percent_winners
FROM cte
LIMIT 1;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


WITH hometeam AS (
	SELECT h.team, t.name AS teamname, h.park
	FROM homegames AS h
		LEFT JOIN teams AS t
	ON h.year = t.yearid AND h.team = t.teamid
	WHERE h.year = 2016),
ballpark AS (
	SELECT p.park_name, p.park,(h.attendance/h.games) AS avg_attendance
FROM homegames AS h
LEFT JOIN parks AS p
ON h.park = p.park
WHERE year = 2016
AND h.games > 10)
				

SELECT teamname, ballpark.park_name, avg_attendance
FROM homegames
INNER JOIN ballpark
ON homegames.park = ballpark.park
ORDER BY avg_attendance DESC
LIMIT 5


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT DISTINCT a.yearid, a.playerid, p.namefirst, p.namelast,  t.name, a.lgid
FROM people AS p
LEFT JOIN awardsmanagers AS a
USING (playerid)
LEFT JOIN managers AS m
ON m.yearid = a.yearid
AND m.playerid = a.playerid
LEFT JOIN teams AS t
ON m.teamid = t.teamid
AND m.yearid = t.yearid
WHERE a.playerid IN 
		(SELECT playerid
		FROM awardsmanagers
		WHERE awardid = 'TSN Manager of the Year'
		AND lgid =  'AL'
		INTERSECT
		SELECT playerid
		FROM awardsmanagers
		WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'NL')




-- select * FROM awardsmanagers
-- WHERE awardid LIKE 'TSN Manager of the Year'

-- SELECT a.playerid, p.namefirst, p.namelast, a.yearid, t.name
-- FROM people AS p
-- LEFT JOIN awardsmanagers as a
-- USING (playerid)
-- LEFT JOIN managershalf AS m
-- ON m.yearid =
-- LEFT JOIN teams AS t
-- ON m.teamid = t.teamid
-- AND m.yearid = t.yearid
-- WHERE playerid IN 
-- 			(SELECT playerid 
-- 			FROM awardsmanagers
-- 			)




-- WITH 
-- 	alwinners AS (
-- 	SELECT p.namefirst, p.namelast, t.name
-- 	FROM awardsmanagers AS a
-- 		LEFT JOIN people AS p
-- 			ON a.playerid = p.playerid
-- 		LEFT JOIN teams AS t
-- 			ON t.yearid = a.yearid
-- 	WHERE a.lgid LIKE 'AL'), 
-- nlwinners AS(
-- 	SELECT p.namefirst, p.namelast, t.name, 
-- 	FROM awardsmanagers AS a
-- 		LEFT JOIN people AS p
-- 			USING (playerid)
-- 		LEFT JOIN teams AS t
-- 			USING (yearid)
-- 	WHERE a.lgid LIKE 'NL')

-- SELECT *
-- FROM alwinners
-- LEFT JOIN nlwinners
-- USING (yearid)



-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


with maxhr AS (
SELECT playerid, yearid, MAX(hr) AS max
FROM batting
GROUP BY playerid, yearid
HAVING MAX(hr) > 0
ORDER BY yearid)

SELECT namefirst, namelast, yearid, maxhr.max AS homeruns
FROM people
JOIN maxhr
USING (playerid)
WHERE yearid = 2016
AND people.debut :: date < '2006-01-01'
ORDER BY homeruns DESC

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?




