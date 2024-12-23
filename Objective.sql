
-- OBJECTIVE
-- Question 1

SELECT 
    COLUMN_NAME, 
    DATA_TYPE 
FROM 
    INFORMATION_SCHEMA.COLUMNS 
WHERE 
    TABLE_NAME = 'ball_by_ball';



show tables in ipl;


-- Question 2

SELECT 
    SUM(COALESCE(bs.Runs_Scored, 0)) + SUM(COALESCE(er.Extra_Runs, 0)) AS Total_Runs
FROM matches m
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
LEFT JOIN batsman_scored bs ON bb.Match_Id = bs.Match_Id 
    AND bb.Over_Id = bs.Over_Id 
    AND bb.Ball_Id = bs.Ball_Id 
    AND bb.Innings_No = bs.Innings_No
LEFT JOIN extra_runs er ON bb.Match_Id = er.Match_Id 
    AND bb.Over_Id = er.Over_Id 
    AND bb.Ball_Id = er.Ball_Id 
    AND bb.Innings_No = er.Innings_No
JOIN team t ON bb.Team_Batting = t.Team_Id
WHERE t.Team_Name = 'RCB' 
  AND m.Season_Id = 1;






-- Question 3

SELECT COUNT(DISTINCT pm.Player_Id) AS Players_Over_25
FROM player_match pm
JOIN matches m ON pm.Match_Id = m.Match_Id
JOIN player p ON pm.Player_Id = p.Player_Id
WHERE m.Season_Id = 2
  AND TIMESTAMPDIFF(YEAR, p.DOB, m.Match_Date) > 25;






-- QUESTION 4



SELECT COUNT(*) AS RCB_Wins
FROM season s join matches m
on s.season_id = m.season_id
JOIN team t on m.match_winner= t.team_id
where s.season_id=1
and t.team_name ='Royal Challengers Bangalore';



-- QUESTION 5




select P.Player_Id,P.Player_Name,Total_Runs,Balls_Faced,
					   round(Total_Runs / Balls_Faced * 100, 2) AS Strike_Rate
from(select PM.Player_Id,
	sum(BS.Runs_Scored) as Total_Runs,
	count(BB.Ball_Id) as Balls_Faced
	from Player_Match PM join Matches M on PM.Match_Id = M.Match_Id
	join Batsman_Scored BS on M.Match_Id = BS.Match_Id
	join Ball_by_Ball BB on M.Match_Id = BB.Match_Id
			and BS.Over_Id = BB.Over_Id
			and BS.Ball_Id = BB.Ball_Id
	where M.Season_Id >= (select max(Season_Id) from Season)-4
	group by PM.Player_Id) as PlayerStats
	join Player P on PlayerStats.Player_Id = P.Player_Id
	order by Strike_Rate desc
	limit 10;






-- QUESTION 6

SELECT 
    p.Player_Name, 
    SUM(bs.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT CONCAT(bs.Match_Id, bs.Innings_No)) AS Innings_Played,
    ROUND(SUM(bs.Runs_Scored) / COUNT(DISTINCT CONCAT(bs.Match_Id, bs.Innings_No)), 2) AS Average_Runs
FROM batsman_scored bs
JOIN ball_by_ball bb ON bs.Match_Id = bb.Match_Id 
    AND bs.Over_Id = bb.Over_Id 
    AND bs.Ball_Id = bb.Ball_Id 
    AND bs.Innings_No = bb.Innings_No
JOIN player p ON bb.Striker = p.Player_Id
GROUP BY p.Player_Name
ORDER BY Average_Runs DESC;






-- QUESTION 7

SELECT 
    p.Player_Name,
    COUNT(bb.Bowler) AS Wickets,
    COUNT(bb.Bowler) / NULLIF(COUNT(DISTINCT bb.Match_Id), 0) AS Average_Wickets
FROM 
    ball_by_ball bb
JOIN 
    player p ON bb.Bowler = p.Player_Id
LEFT JOIN 
    batsman_scored bs ON bb.Match_Id = bs.Match_Id 
                      AND bb.Over_Id = bs.Over_Id 
                      AND bb.Ball_Id = bs.Ball_Id
WHERE 
    bs.Runs_Scored = 0  -- Assuming this means the batsman was out
GROUP BY 
    p.Player_Name
ORDER BY 
    Average_Wickets DESC;
    
    






-- QUESTION 8


WITH PlayerAverageRuns AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        AVG(bs.Runs_Scored) AS Avg_Runs_Scored
    FROM 
        player p
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id  -- Linking players to matches
    LEFT JOIN 
        batsman_scored bs ON pm.Match_Id = bs.Match_Id 
                         AND pm.Role_Id = 1  -- Assuming Role_Id 1 represents batsmen
    GROUP BY 
        p.Player_Id, p.Player_Name
),
PlayerWickets AS (
    SELECT 
        p.Player_Id,
        COUNT(bb.Bowler) AS Wickets
    FROM 
        player p
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id
    JOIN 
        ball_by_ball bb ON bb.Bowler = p.Player_Id
    LEFT JOIN 
        batsman_scored bs ON bb.Match_Id = bs.Match_Id 
                      AND bb.Over_Id = bs.Over_Id 
                      AND bb.Ball_Id = bs.Ball_Id
    WHERE 
        bs.Runs_Scored = 0  -- Assuming a runs scored of 0 indicates a wicket
    GROUP BY 
        p.Player_Id
),
OverallAverages AS (
    SELECT 
        AVG(Avg_Runs_Scored) AS Overall_Avg_Runs
    FROM 
        PlayerAverageRuns
),
OverallWickets AS (
    SELECT 
        AVG(Wickets) AS Overall_Avg_Wickets
    FROM 
        PlayerWickets
)
SELECT 
    ar.Player_Name,
    ar.Avg_Runs_Scored,
    pw.Wickets
FROM 
    PlayerAverageRuns ar
JOIN 
    PlayerWickets pw ON ar.Player_Id = pw.Player_Id
CROSS JOIN 
    OverallAverages oa
CROSS JOIN 
    OverallWickets ow
WHERE 
    ar.Avg_Runs_Scored > oa.Overall_Avg_Runs 
    AND pw.Wickets > ow.Overall_Avg_Wickets
ORDER BY 
    ar.Player_Name;









-- QUESTION 9


create table rcb_record 
		(venue_name varchar(100),
		 wins int,
		 losses int);
        insert into rcb_record (venue_name,wins,losses)
               (select v.venue_name,
			   count(case when m.match_winner=t.team_id then 1 end) as wins,
               count(case when m.match_winner<>t.team_id then 1 end) as losses
		from venue v join matches m on v.venue_id=m.venue_id 
		join team t on m.team_1=t.team_id or m.team_2=t.team_id 
		where t.team_name='Royal Challengers Bangalore'
		group by v.venue_name);
    select * from rcb_record;
    





-- QUESTION 10

SELECT 
    bs.Bowling_skill AS Bowling_Style,
    COUNT(bb.Bowler) AS Total_Wickets,
    AVG(wickets_per_bowler) AS Average_Wickets
FROM 
    ball_by_ball bb
JOIN 
    player p ON bb.Bowler = p.Player_Id
JOIN 
    bowling_style bs ON p.Bowling_skill = bs.Bowling_Id
LEFT JOIN (
    SELECT 
        bb.Bowler,
        COUNT(*) AS wickets_per_bowler
    FROM 
        ball_by_ball bb
    LEFT JOIN 
        batsman_scored bs ON bb.Match_Id = bs.Match_Id 
                          AND bb.Over_Id = bs.Over_Id 
                          AND bb.Ball_Id = bs.Ball_Id
    WHERE 
        bs.Runs_Scored = 0  -- Assuming runs scored of 0 indicates a wicket
    GROUP BY 
        bb.Bowler
) AS Wickets ON bb.Bowler = Wickets.Bowler
GROUP BY 
    bs.Bowling_skill
ORDER BY 
    Total_Wickets DESC;
    
    
    
    
    
    
    
-- QUESTION 11


WITH TeamPerformance AS (
    SELECT 
        s.Season_Year,
        SUM(bs.Runs_Scored) AS Total_Runs,
        COUNT(bb.Bowler) AS Total_Wickets
    FROM 
        season s
    JOIN 
        matches m ON s.Season_Id = m.Season_Id
    LEFT JOIN 
        batsman_scored bs ON m.Match_Id = bs.Match_Id
    LEFT JOIN 
        ball_by_ball bb ON m.Match_Id = bb.Match_Id
    WHERE 
        m.Team_1 = 1 OR m.Team_2 = 1  -- Assuming Team_Id 1 represents the team in question
    GROUP BY 
        s.Season_Year
),
PerformanceComparison AS (
    SELECT 
        curr.Season_Year AS Current_Year,
        curr.Total_Runs AS Current_Runs,
        curr.Total_Wickets AS Current_Wickets,
        prev.Total_Runs AS Previous_Runs,
        prev.Total_Wickets AS Previous_Wickets
    FROM 
        TeamPerformance curr
    LEFT JOIN 
        TeamPerformance prev ON curr.Season_Year = prev.Season_Year + 1
)
SELECT 
    Current_Year,
    Current_Runs,
    Current_Wickets,
    Previous_Runs,
    Previous_Wickets,
    CASE 
        WHEN Current_Runs > Previous_Runs AND Current_Wickets > Previous_Wickets THEN 'Better'
        WHEN Current_Runs < Previous_Runs AND Current_Wickets < Previous_Wickets THEN 'Worse'
        ELSE 'Same or Mixed'
    END AS Performance_Status
FROM 
    PerformanceComparison
ORDER BY 
    Current_Year DESC;
    
    
    
    
    
    
    
-- QUESTION 12

-- (1) Batting KPIs:
-- Average Runs per Match:

SELECT 
    Season_Year, 
    AVG(Total_Runs) AS Average_Runs_Per_Match
FROM (
    SELECT 
        s.Season_Year, 
        m.Match_Id, 
        SUM(bs.Runs_Scored) AS Total_Runs
    FROM 
        season s
    JOIN 
        matches m ON s.Season_Id = m.Season_Id
    LEFT JOIN 
        batsman_scored bs ON m.Match_Id = bs.Match_Id
    WHERE 
        m.Team_1 = 1 OR m.Team_2 = 1  -- Replace with actual Team_Id
    GROUP BY 
        s.Season_Year, m.Match_Id
) AS SeasonPerformance
GROUP BY Season_Year;



-- STRIKE RATE

SELECT 
    p.Player_Name, 
    SUM(bs.Runs_Scored) AS Total_Runs,
    COUNT(bb.Ball_Id) AS Balls_Faced,
    (SUM(bs.Runs_Scored) / COUNT(bb.Ball_Id)) * 100 AS Strike_Rate
FROM 
    player p
JOIN 
    ball_by_ball bb ON p.Player_Id = bb.Striker  -- Assuming Striker column links to player
LEFT JOIN 
    batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
LEFT JOIN 
    extra_runs er ON bb.Match_Id = er.Match_Id AND bb.Over_Id = er.Over_Id AND bb.Ball_Id = er.Ball_Id
JOIN 
    player_match pm ON p.Player_Id = pm.Player_Id
WHERE 
    pm.Team_Id = 1  -- Replace with actual Team_Id
    AND er.Extra_Type_Id IS NULL  -- Exclude extra deliveries like wides and no-balls
GROUP BY 
    p.Player_Name;



-- BOUNDARY PERCENTAGE

SELECT 
    Season_Year,
    SUM(CASE WHEN bs.Runs_Scored = 4 OR bs.Runs_Scored = 6 THEN bs.Runs_Scored ELSE 0 END) / SUM(bs.Runs_Scored) * 100 AS Boundary_Percentage
FROM 
    season s
JOIN 
    matches m ON s.Season_Id = m.Season_Id
LEFT JOIN 
    batsman_scored bs ON m.Match_Id = bs.Match_Id
WHERE 
    m.Team_1 = 1 OR m.Team_2 = 1  -- Replace with actual Team_Id
GROUP BY Season_Year;




-- (2) Bowling KPIs
--  Bowling Economy


SELECT 
    p.Player_Name, 
    SUM(bs.Runs_Scored + COALESCE(er.Extra_Runs, 0)) / (COUNT(DISTINCT bb.Over_Id) / 6) AS Economy_Rate
FROM 
    player p
LEFT JOIN 
    ball_by_ball bb ON p.Player_Id = bb.Bowler
LEFT JOIN 
    batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
LEFT JOIN 
    extra_runs er ON bb.Match_Id = er.Match_Id AND bb.Over_Id = er.Over_Id AND bb.Ball_Id = er.Ball_Id
WHERE 
    bb.Bowler IS NOT NULL 
    AND p.Player_Id IN (
        SELECT pm.Player_Id 
        FROM player_match pm
        WHERE pm.Team_Id = 1  -- Replace with the actual Team_Id
    )
GROUP BY 
    p.Player_Name;




-- Average Wickets per Match: 

SELECT 
    Season_Year, 
    AVG(Total_Wickets) AS Average_Wickets_Per_Match
FROM (
    SELECT 
        s.Season_Year, 
        m.Match_Id, 
        COUNT(bb.Bowler) AS Total_Wickets
    FROM 
        season s
    JOIN 
        matches m ON s.Season_Id = m.Season_Id
    LEFT JOIN 
        ball_by_ball bb ON m.Match_Id = bb.Match_Id
    WHERE 
        m.Team_1 = 1 OR m.Team_2 = 1  -- Replace with actual Team_Id
    GROUP BY 
        s.Season_Year, m.Match_Id
) AS SeasonPerformance
GROUP BY Season_Year;




-- Dot Ball Percentage

SELECT 
    s.Season_Year, 
    (SUM(CASE WHEN bs.Runs_Scored = 0 AND COALESCE(er.Extra_Runs, 0) = 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Dot_Ball_Percentage
FROM 
    season s
JOIN 
    matches m ON s.Season_Id = m.Season_Id
LEFT JOIN 
    ball_by_ball bb ON m.Match_Id = bb.Match_Id
LEFT JOIN 
    batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
LEFT JOIN 
    extra_runs er ON bb.Match_Id = er.Match_Id AND bb.Over_Id = er.Over_Id AND bb.Ball_Id = er.Ball_Id
WHERE 
    m.Team_1 = 1 OR m.Team_2 = 1  -- Replace with the actual Team_Id
GROUP BY 
    s.Season_Year;



-- (3) Fielding KPIs:
-- Catch Success Rate:


SELECT 
    p.Player_Name, 
    (SUM(CASE WHEN ot.Out_Name = 'Caught' THEN 1 ELSE 0 END) / COUNT(CASE WHEN bb.Ball_Id IS NOT NULL THEN 1 ELSE NULL END)) * 100 AS Catch_Success_Rate
FROM 
    player p
JOIN 
    player_match pm ON p.Player_Id = pm.Player_Id  -- Links players to their team and matches
LEFT JOIN 
    ball_by_ball bb ON pm.Match_Id = bb.Match_Id
LEFT JOIN 
    out_type ot ON bb.Match_Id = pm.Match_Id AND ot.Out_Name = 'Caught'
WHERE 
    pm.Team_Id = 1  -- Replace with the actual team ID
GROUP BY 
    p.Player_Name;



-- Run-Out Contribution: 

SELECT 
    p.Player_Name, 
    COUNT(*) AS Run_Outs
FROM 
    player p
JOIN 
    player_match pm ON p.Player_Id = pm.Player_Id  -- Link players to their teams via matches
JOIN 
    ball_by_ball bb ON bb.Match_Id = pm.Match_Id  -- Ensure the player participated in the match
JOIN 
    out_type ot ON bb.Ball_Id = ot.Out_Id  -- Assuming this connects run-outs to a type of out
WHERE 
    pm.Team_Id = 1  -- Replace with the actual Team_Id
    AND ot.Out_Name = 'Run Out'
GROUP BY 
    p.Player_Name;




-- (4) Team Strategy KPIs:
   -- Win Percentage by Batting First or Chasing:

SELECT 
    CASE 
        WHEN m.Toss_Decide = 1 AND m.Toss_Winner = m.Match_Winner THEN 'Batting First' 
        ELSE 'Chasing' 
    END AS Strategy,
    COUNT(*) AS Total_Matches,
    SUM(CASE 
        WHEN (m.Toss_Decide = 1 AND m.Toss_Winner = m.Match_Winner AND m.Match_Winner = 1) OR 
             (m.Toss_Decide = 2 AND m.Toss_Winner != m.Match_Winner AND m.Match_Winner = 1)
        THEN 1 ELSE 0 
    END) AS Matches_Won,
    (SUM(CASE 
        WHEN (m.Toss_Decide = 1 AND m.Toss_Winner = m.Match_Winner AND m.Match_Winner = 1) OR 
             (m.Toss_Decide = 2 AND m.Toss_Winner != m.Match_Winner AND m.Match_Winner = 1)
        THEN 1 ELSE 0 
    END) / COUNT(*)) * 100 AS Win_Percentage
FROM 
    matches m
WHERE 
    m.Team_1 = 1 OR m.Team_2 = 1  -- Replace with actual Team_Id
GROUP BY Strategy;









-- QUESTION 13


WITH each_venue_BowlerWickets AS (
    SELECT 
        bb.Bowler, 
        p.Player_Name,
        v.venue_name,
        COUNT(DISTINCT bb.Match_Id, bb.Over_Id, bb.Ball_Id, bb.Innings_No) AS Total_Wickets,
        COUNT(DISTINCT bb.Match_Id, bb.Innings_No) AS Matches_Played
    FROM 
        player p 
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id 
    JOIN 
        matches m ON pm.Match_Id = m.Match_Id
    JOIN 
        ball_by_ball bb ON m.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Bowler
    JOIN 
        wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id 
                          AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
    JOIN 
        venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY 
        bb.Bowler, p.Player_Name, v.Venue_Name
)
SELECT 
    Bowler AS Player_Id,
    Player_Name,
    Venue_Name,
    ROUND(Total_Wickets / Matches_Played, 1) AS Average_Wickets,
    DENSE_RANK() OVER (ORDER BY ROUND(Total_Wickets / Matches_Played, 1) DESC) AS 'Rank'
FROM 
    each_venue_BowlerWickets
ORDER BY 
    Average_Wickets DESC, 'Rank' DESC;





-- Question 14

SELECT 
    p.Player_Id,
    p.Player_Name,
    s.Season_Year,
    SUM(bs.Runs_Scored) AS Total_Runs
FROM 
    player p
JOIN 
    player_match pm ON p.Player_Id = pm.Player_Id
JOIN 
    matches m ON pm.Match_Id = m.Match_Id
JOIN 
    batsman_scored bs ON m.Match_Id = bs.Match_Id
JOIN 
    season s ON m.Season_Id = s.Season_Id  -- Join with season table
WHERE 
    pm.Role_Id = 1  -- Assuming Role_Id for batsmen is 1; adjust if necessary
GROUP BY 
    p.Player_Id, p.Player_Name, s.Season_Year
ORDER BY 
    p.Player_Name, s.Season_Year;



-- QUESTION 15


-- top 3 players in each venue scored highest_runs
WITH result AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        v.Venue_Name,
        SUM(bs.Runs_Scored) AS Total_Runs
    FROM 
        player p 
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id
    JOIN 
        ball_by_ball bb ON pm.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Striker
    JOIN 
        batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id
                           AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
    JOIN 
        matches m ON bs.Match_Id = m.Match_Id
    JOIN 
        venue v ON m.Venue_Id = v.Venue_Id
    JOIN 
        season s ON m.Season_Id = s.Season_Id
    JOIN 
        city c ON v.City_Id = c.City_Id
    JOIN 
        country cc ON c.Country_Id = cc.Country_Id
    WHERE 
        cc.Country_Name = 'India'
    GROUP BY 
        p.Player_Id, p.Player_Name, v.Venue_Name
    ORDER BY 
        Total_Runs DESC
),
rank_player AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY Venue_Name ORDER BY Total_Runs DESC) AS Top_Rank
    FROM 
        result
)
SELECT 
    * 
FROM 
    rank_player
WHERE 
    Top_Rank BETWEEN 1 AND 3
ORDER BY 
    Top_Rank, Total_Runs DESC;


-- top 3 players in each venue  taken highest_wicket
WITH result AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        v.Venue_Name,
        COUNT(DISTINCT wt.Match_Id, wt.Innings_No, wt.Over_Id, wt.Ball_Id) AS Total_Wickets
    FROM 
        player p
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id
    JOIN 
        ball_by_ball bb ON pm.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Bowler
    JOIN 
        wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id
                         AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
    JOIN 
        matches m ON wt.Match_Id = m.Match_Id
    JOIN 
        venue v ON m.Venue_Id = v.Venue_Id
    JOIN 
        season s ON m.Season_Id = s.Season_Id
    JOIN 
        city c ON v.City_Id = c.City_Id
    JOIN 
        country cc ON c.Country_Id = cc.Country_Id
    WHERE 
        cc.Country_Name = 'India'
    GROUP BY 
        p.Player_Id, p.Player_Name, v.Venue_Name
    ORDER BY 
        Total_Wickets DESC
),
rank_player AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY Venue_Name ORDER BY Total_Wickets DESC) AS Top_Rank
    FROM 
        result
)
SELECT 
    * 
FROM 
    rank_player
WHERE 
    Top_Rank BETWEEN 1 AND 3
ORDER BY 
    Top_Rank, Total_Wickets DESC;




