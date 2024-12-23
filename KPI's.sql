-- Top average batsman 
with player_runs as (select p.player_id,p.player_name,sum(bs.runs_scored) total_runs 
								from player p join player_match pm on p.player_id=pm.player_id 
								join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.striker 
								join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
													   and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
								group by p.player_id,p.player_name
								order by total_runs desc),
			player_out as (select p.player_id,p.player_name,count(wt.player_out) as number_of_times_out
							from player p join wicket_taken wt on p.player_id=wt.player_out
							group by p.player_id,p.player_name)
			select pr.*,
				   po.number_of_times_out,
				   round(pr.total_runs/coalesce(po.number_of_times_out,1),1) as average_runs
			from player_runs pr left join player_out po on pr.player_id=po.player_id
            where pr.total_runs>3000
			order by average_runs desc limit 10;
            
            
            
-- bowler total_runs_conceeded per over
with rs as (select bb.bowler,p.player_name,sum(bs.runs_scored) as total_runs_conceeded,
                  count(distinct bb.match_id,bb.over_id)total_over_bowled
			from ball_by_ball bb join batsman_scored bs on bb.match_id=bs.match_id 
                                 and bb.over_id=bs.over_id
								 and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
			join matches m on bs.match_id=m.match_id
			join player p on bb.bowler=p.player_id
			group by bb.bowler,p.player_name)
select distinct rs.*, total_runs_conceeded/total_over_bowled as economy
from rs join player_match pm on rs.bowler=pm.player_id
where total_over_bowled>50
order by economy desc;


-- last 3 seasons most man_of_the_match award ***
		with rs1 as (select m.man_of_the_match,count(m.man_of_the_match)manofthe_match_count
					from matches m join player p on m.man_of_the_match=p.player_id
					where m.season_id in(9,8,7)
					group by man_of_the_match),
		rs2 as (select p.player_id,p.player_name,t.team_id,t.team_name from player p 
				join player_match pm on p.player_id=pm.player_id
				join team t on pm.team_id=t.team_id)
		select distinct rs2.player_id,
						rs1.manofthe_match_count,
						rs2.player_name
		from rs1 join rs2 on rs1.man_of_the_match=rs2.player_id
		order by manofthe_match_count desc;
        
        
        
        
        
	
 -- Total Number of Boundaries hit in each venues( 4's And 6's)   
    WITH match_scores AS (
    SELECT 
        m.match_id,
        v.venue_name,
        SUM(bs.runs_scored) AS total_runs,
        COUNT(CASE WHEN bs.runs_scored = 4 THEN 1 END) AS total_fours,
        COUNT(CASE WHEN bs.runs_scored = 6 THEN 1 END) AS total_sixes
    FROM 
        matches m
        JOIN ball_by_ball bb 
            ON m.match_id = bb.match_id
        JOIN batsman_scored bs 
            ON bb.match_id = bs.match_id
            AND bb.over_id = bs.over_id
            AND bb.ball_id = bs.ball_id
            AND bb.innings_no = bs.innings_no
        JOIN venue v 
            ON m.venue_id = v.venue_id
    GROUP BY 
        m.match_id, v.venue_name
),
venue_analysis AS (
    SELECT 
        venue_name,
        COUNT(match_id) AS total_matches,
        AVG(total_runs) AS avg_runs_per_match,
        SUM(total_fours) AS total_fours_hit,
        SUM(total_sixes) AS total_sixes_hit
    FROM 
        match_scores
    GROUP BY 
        venue_name
)
SELECT 
    venue_name,
    total_matches,
    avg_runs_per_match,
    total_fours_hit,
    total_sixes_hit
FROM 
    venue_analysis
ORDER BY 
    avg_runs_per_match DESC
LIMIT 10;





-- ***  RCB success percentage in Each Venue
with total_win_venue as (select m.venue_id,v.venue_name,count(*) as total_win
						  from matches m join venue v on m.venue_id=v.venue_id
                          join team t on t.team_id=m.match_winner
						  where t.team_name='Royal Challengers Bangalore'
						  group by m.venue_id,v.venue_name),
total_played_venue as (select venue_id,count(*) total_played_matches from matches 
					   where (team_1='2' or team_2='2')
					   group by venue_id)
select twv.*,
       tpv.total_played_matches,
       (twv.total_win/tpv.total_played_matches)*100 as win_percentage
from total_win_venue twv join total_played_venue tpv on twv.venue_id=tpv.venue_id
order by total_played_matches desc;



select m.match_winner as team_id,t.team_name,count(m.match_winner) match_win_count 
from matches m join venue v on m.venue_id=v.venue_id 
join team t on m.match_winner=t.team_id
where v.venue_name='M Chinnaswamy Stadium'
and (team_1='2' or team_2='2')
group by m.match_winner,t.team_name
order by match_win_count desc;



-- 1. Win Percentage for RCB in Each Season
WITH rcb_performance AS (
    SELECT 
        m.Season_Id,
        COUNT(*) AS total_matches,
        SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) AS total_wins  -- Assuming Team_Id '2' is RCB
    FROM 
        matches m
    WHERE 
        m.Team_1 = 2 OR m.Team_2 = 2  -- Matches involving RCB
    GROUP BY 
        m.Season_Id
)
SELECT 
    s.Season_Year,
    rp.total_matches,
    rp.total_wins,
    ROUND((rp.total_wins / rp.total_matches) * 100, 2) AS win_percentage
FROM 
    rcb_performance rp
JOIN 
    season s ON rp.Season_Id = s.Season_Id
ORDER BY 
    s.Season_Year;




-- 2) average runs conceeded in death over of each team from last 5 years
with total_deathover_runs as (select t.team_name,sum(runs_scored) as deathover_runs
							from  ball_by_ball bb join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
												  and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							join team t on t.team_id=bb.team_bowling
                            join matches m on m.match_id=bb.match_id
                            join season s on m.season_id=s.season_id
							where bb.over_id>=16
							group by t.team_name),
total_matches as (select t.team_name,count(distinct m.match_id) as total_matches  
				 from matches m join team t on m.team_1=t.team_id or m.team_2=t.team_id
                 join season s on m.season_id=s.season_id
				 group by t.team_name)
select  tdr.*,tm.total_matches,(tdr.deathover_runs/tm.total_matches) as avg_deathover_runs_conceeded,
         dense_rank() over(order by (tdr.deathover_runs/tm.total_matches) ) as 'rank' 
from total_deathover_runs tdr join total_matches tm on tdr.team_name=tm.team_name  
order by 'rank'; 







-- 3. RCB’s Performance While Batting First vs Chasing
WITH rcb_batting_stats AS (
    SELECT 
        m.Season_Id,
        SUM(CASE WHEN m.Team_1 = 2 THEN 1 ELSE 0 END) AS matches_batting_first,
        SUM(CASE WHEN m.Team_2 = 2 THEN 1 ELSE 0 END) AS matches_chasing
    FROM 
        matches m
    WHERE 
        m.Team_1 = 2 OR m.Team_2 = 2  -- Matches involving RCB
    GROUP BY 
        m.Season_Id
)
SELECT 
    s.Season_Year,
    rbs.matches_batting_first,
    rbs.matches_chasing
FROM 
    rcb_batting_stats rbs
JOIN 
    season s ON rbs.Season_Id = s.Season_Id
ORDER BY 
    s.Season_Year;




-- 4. Comparison of RCB's Team Performance Across Seasons
WITH rcb_bowling AS (
    SELECT 
        p.Player_Name,
        COUNT(*) AS total_wickets,
        m.Season_Id
    FROM 
        wicket_taken wt
    JOIN 
        ball_by_ball bb ON wt.Match_Id = bb.Match_Id AND wt.Over_Id = bb.Over_Id AND wt.Ball_Id = bb.Ball_Id  -- Join with ball_by_ball to get the bowler
    JOIN 
        player p ON bb.Bowler = p.Player_Id  -- Get the bowler from ball_by_ball
    JOIN 
        matches m ON wt.Match_Id = m.Match_Id
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id
    WHERE 
        pm.Team_Id = 2  -- RCB team
    GROUP BY 
        p.Player_Name, m.Season_Id
)
SELECT 
    s.Season_Year,
    SUM(rb.total_wickets) AS total_wickets_taken
FROM 
    rcb_bowling rb
JOIN 
    season s ON rb.Season_Id = s.Season_Id
GROUP BY 
    s.Season_Year
ORDER BY 
    s.Season_Year;




-- 5. Key Factors for Losing (Losses in Narrow Margins)
WITH narrow_losses AS (
    SELECT 
        m.Season_Id,
        COUNT(*) AS narrow_losses
    FROM 
        matches m
    WHERE 
        (m.Team_1 = 2 OR m.Team_2 = 2)  -- Matches involving RCB
        AND m.Match_Winner != 2  -- RCB lost
        AND m.Win_Margin < 20  -- Narrow margin loss (example: < 20 runs or wickets)
    GROUP BY 
        m.Season_Id
)
SELECT 
    s.Season_Year,
    nl.narrow_losses
FROM 
    narrow_losses nl
JOIN 
    season s ON nl.Season_Id = s.Season_Id
ORDER BY 
    s.Season_Year;





-- 1- Top 10 player's in batting score
SELECT 
    p.Player_Name AS Batsman,
    SUM(bs.Runs_Scored) AS Total_Runs
FROM 
    batsman_scored bs
JOIN 
    ball_by_ball bb ON bs.Match_Id = bb.Match_Id 
                     AND bs.Over_Id = bb.Over_Id 
                     AND bs.Ball_Id = bb.Ball_Id 
                     AND bs.Innings_No = bb.Innings_No
JOIN 
    player p ON bb.Striker = p.Player_Id
GROUP BY 
    p.Player_Name
ORDER BY 
    Total_Runs DESC
LIMIT 10;






-- Top 10 player bating average
SELECT 
    p.Player_Name AS Batsman,
    SUM(bs.Runs_Scored) AS Total_Runs,
    COUNT(DISTINCT CONCAT(bs.Match_Id, '-', bs.Innings_No)) AS Innings_Played,
    (SUM(bs.Runs_Scored) * 1.0 / COUNT(DISTINCT CONCAT(bs.Match_Id, '-', bs.Innings_No))) AS Batting_Average
FROM 
    batsman_scored bs
JOIN 
    ball_by_ball bb ON bs.Match_Id = bb.Match_Id 
                     AND bs.Over_Id = bb.Over_Id 
                     AND bs.Ball_Id = bb.Ball_Id 
                     AND bs.Innings_No = bb.Innings_No
JOIN 
    player p ON bb.Striker = p.Player_Id
LEFT JOIN 
    out_type ot ON bb.Striker = ot.Out_Id -- Assuming 'Out_Id' is linked to the striker when out
GROUP BY 
    p.Player_Name
HAVING 
    COUNT(DISTINCT CONCAT(bs.Match_Id, '-', bs.Innings_No)) > 0
ORDER BY 
    Batting_Average DESC
LIMIT 10;






-- 3. Consistant players (with most man of the match award)
SELECT 
    p.Player_Name AS Player,
    COUNT(m.Man_of_the_Match) AS Man_of_the_Match_Count
FROM 
    matches m
JOIN 
    player p ON m.Man_of_the_Match = p.Player_Id
GROUP BY 
    p.Player_Name
ORDER BY 
    Man_of_the_Match_Count DESC
LIMIT 10;





-- Top 10 Average Player in Death Over
WITH death_over_scores AS (
    SELECT 
        bb.Striker AS Player_Id,
        p.Player_Name AS Player_Name,
        COUNT(DISTINCT bb.Match_Id) AS Matches_Played,
        SUM(bs.Runs_Scored) AS Total_Runs_Death_Overs
    FROM 
        ball_by_ball bb
    JOIN 
        batsman_scored bs ON bb.Match_Id = bs.Match_Id 
                          AND bb.Over_Id = bs.Over_Id 
                          AND bb.Ball_Id = bs.Ball_Id
    JOIN 
        player p ON bb.Striker = p.Player_Id
    WHERE 
        bb.Over_Id BETWEEN 17 AND 20 -- Death overs
    GROUP BY 
        bb.Striker, p.Player_Name
),
qualified_players AS (
    SELECT 
        Player_Id,
        Player_Name,
        Matches_Played,
        Total_Runs_Death_Overs,
        (Total_Runs_Death_Overs * 1.0 / Matches_Played) AS Avg_Runs_Death_Overs
    FROM 
        death_over_scores
    WHERE 
        Matches_Played >= 20 -- Minimum 20 matches played
)
SELECT 
    Player_Name,
    Matches_Played,
    Total_Runs_Death_Overs,
    ROUND(Avg_Runs_Death_Overs, 2) AS Avg_Runs_Death_Overs
FROM 
    qualified_players
ORDER BY 
    Avg_Runs_Death_Overs DESC
LIMIT 10;





-- Top Player with no. of boundaries(4 & 6)
WITH boundary_counts AS (
    SELECT 
        bb.Striker AS Player_Id,
        p.Player_Name AS Player_Name,
        SUM(CASE WHEN bs.Runs_Scored = 4 THEN 1 ELSE 0 END) AS Fours,
        SUM(CASE WHEN bs.Runs_Scored = 6 THEN 1 ELSE 0 END) AS Sixes,
        COUNT(CASE WHEN bs.Runs_Scored IN (4, 6) THEN 1 ELSE NULL END) AS Total_Boundaries
    FROM 
        ball_by_ball bb
    JOIN 
        batsman_scored bs ON bb.Match_Id = bs.Match_Id 
                          AND bb.Over_Id = bs.Over_Id 
                          AND bb.Ball_Id = bs.Ball_Id
    JOIN 
        player p ON bb.Striker = p.Player_Id
    GROUP BY 
        bb.Striker, p.Player_Name
)
SELECT 
    Player_Name,
    Fours,
    Sixes,
    Total_Boundaries
FROM 
    boundary_counts
ORDER BY 
    Total_Boundaries DESC
LIMIT 10;




-- RCB home ground win vs loss against opposite Team 
with rs1 as (select m.*,
                    case when team_1='2' then team_1 else team_2 end as team_rcb,
					case when team_1='2' then team_2 else team_1 end as opposite_team,
                    v.venue_name
			from matches m join venue v on m.venue_id=v.venue_id
			join team t on m.match_winner=t.team_id
			where v.venue_name='M Chinnaswamy Stadium'
			and (team_1='2' or team_2='2')),
loss_count as (select rs1.opposite_team,t.team_name,count(rs1.match_winner)loss_count
from rs1 join team t on rs1.opposite_team=t.team_id
where match_winner<>'2'
group by rs1.opposite_team,t.team_name
order by loss_count desc),
win_count as (select rs1.opposite_team,count(rs1.match_winner) as win_count
from rs1 
group by rs1.opposite_team)
select lc.*,wc.win_count 
from loss_count lc join win_count wc on lc.opposite_team=wc.opposite_team;




    
    
    
-- RCB's Win & loss percentage on toss dicision(bat & field)
 WITH toss_decision_analysis AS (
    SELECT
        m.Match_Id,
        m.Toss_Winner,
        m.Toss_Decide,
        m.Match_Winner,
        CASE 
            WHEN m.Toss_Winner = m.Match_Winner THEN 'Win'
            ELSE 'Loss'
        END AS Toss_Outcome
    FROM
        matches m
),
toss_stats AS (
    SELECT
        td.Toss_Decide AS Toss_Decision,
        td.Toss_Outcome,
        COUNT(*) AS Match_Count
    FROM
        toss_decision_analysis td
    GROUP BY
        td.Toss_Decide, td.Toss_Outcome
),
toss_outcome_ratios AS (
    SELECT
        Toss_Decision,
        SUM(CASE WHEN Toss_Outcome = 'Win' THEN Match_Count ELSE 0 END) AS Wins,
        SUM(CASE WHEN Toss_Outcome = 'Loss' THEN Match_Count ELSE 0 END) AS Losses,
        ROUND(SUM(CASE WHEN Toss_Outcome = 'Win' THEN Match_Count ELSE 0 END) * 100.0 / 
              SUM(Match_Count), 2) AS Win_Percentage,
        ROUND(SUM(CASE WHEN Toss_Outcome = 'Loss' THEN Match_Count ELSE 0 END) * 100.0 / 
              SUM(Match_Count), 2) AS Loss_Percentage
    FROM
        toss_stats
    GROUP BY
        Toss_Decision
)
SELECT
    Toss_Decision,
    Wins,
    Losses,
    Win_Percentage,
    Loss_Percentage
FROM
    toss_outcome_ratios;





-- Top Bowler with highest wicket in Death Over.

SELECT 
    p.Player_Name AS Bowler,
    COUNT(bb.Match_Id) AS Total_Wickets_Death_Overs
FROM 
    ball_by_ball bb
JOIN 
    player p ON bb.Bowler = p.Player_Id
JOIN 
    matches m ON bb.Match_Id = m.Match_Id
WHERE 
    bb.Innings_No = 1  -- Optional: Restrict to a particular innings if needed
    AND bb.Over_Id BETWEEN 16 AND 20  -- Restrict to death overs (16-20)
    AND bb.Striker IS NOT NULL  -- Exclude records where the striker is null (not a valid delivery)
GROUP BY 
    p.Player_Name
ORDER BY 
    Total_Wickets_Death_Overs DESC
LIMIT 10;






-- best economy bowlers
SELECT 
    p.Player_Name AS Bowler,
    SUM(bs.Runs_Scored) / COUNT(DISTINCT bb.Over_Id) AS Economy_Rate
FROM 
    ball_by_ball bb
JOIN 
    player p ON bb.Bowler = p.Player_Id
JOIN 
    batsman_scored bs ON bb.Match_Id = bs.Match_Id 
    AND bb.Over_Id = bs.Over_Id 
    AND bb.Ball_Id = bs.Ball_Id
WHERE 
    bb.Innings_No = 1  -- Optional: restrict to the first innings if needed
GROUP BY 
    p.Player_Name
ORDER BY 
    Economy_Rate ASC
LIMIT 10;






