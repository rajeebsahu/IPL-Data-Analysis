-- SUBJECTIVE
-- Question 1

-- toss win match_win vs toss win match loss of all team
with union_table_1 as (select 1 as number,count(case when team_1=toss_winner and toss_winner=match_winner then 1 end) as toss_win_match_win
					  from matches 
					  union all 
					  select 1 as number,count(case when team_2=toss_winner and toss_winner=match_winner then 1 end) as toss_win_match_win
					  from matches ),
rs1 as (select number,sum(toss_win_match_win) toss_win_match_win from union_table_1
        group by number) ,                
union_table_2 as (select 1 as number,count(case when team_1=toss_winner and toss_winner<>match_winner then 1 end) as toss_win_match_loss
			      from matches 
				  union all 
				  select 1 as number, count(case when team_2=toss_winner and toss_winner<>match_winner then 1 end) as toss_win_match_loss
				  from matches ),
rs2 as (select number,sum(toss_win_match_loss) as toss_win_match_loss from union_table_2
       group by number)
select rs1.*,rs2.toss_win_match_loss
from rs1 join rs2 on rs1.number=rs2.number;



-- match win percentage  after won toss in each venue 
WITH Toss_Win_Stats AS (
    SELECT v.Venue_Name, td.Toss_Name AS Toss_Decision, COUNT(*) AS Total_Matches,
           SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) AS Matches_Won_After_Toss,
           (SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY v.Venue_Name, td.Toss_Name
)
SELECT Venue_Name, Toss_Decision, Total_Matches, Matches_Won_After_Toss, Win_Percentage
FROM Toss_Win_Stats
WHERE Total_Matches >= 10;



-- team win percentage after winning toss
with match_winner_count as (select toss_winner,count(*) as match_win_count from matches
							where toss_winner=match_winner
							group by toss_winner order by match_win_count desc),
toss_winner_count as (select toss_winner,count(*)total_toss_win_count
					  from matches group by toss_winner)
select t.team_name,
       mwc.match_win_count,
	   twc.total_toss_win_count,
       round((mwc.match_win_count/twc.total_toss_win_count)*100,1) as toss_win_match_win_percentage
from match_winner_count mwc join toss_winner_count twc on mwc.toss_winner=twc.toss_winner
join team t on mwc.toss_winner=t.team_id order by toss_win_match_win_percentage desc;



-- each venue bat 1st field 1st winning percentage after toss
WITH Toss_Win_Stats AS (
    SELECT v.Venue_Name, td.Toss_Name AS Toss_Decision, COUNT(*) AS Total_Matches,
           SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) AS Matches_Won_After_Toss,
           (SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY v.Venue_Name, td.Toss_Name)
SELECT Venue_Name, Toss_Decision, Total_Matches, Matches_Won_After_Toss, Win_Percentage
FROM Toss_Win_Stats
WHERE Total_Matches >= 5
ORDER BY venue_name, Win_Percentage DESC; 





-- Question 2
-- top 5 score rank in each season--players and number of times they are in top 5 in last 3 seasons 
	with player_match_runs as (select bb.match_id,bb.striker,sum(runs_scored) as total_runs
					      from ball_by_ball bb join batsman_scored bs on bb.Match_Id=bs.Match_Id and bb.Innings_No=bs.Innings_No
																and bb.Over_Id=bs.Over_Id and bb.Ball_Id=bs.Ball_Id 
							group by bb.match_id,bb.striker),
result as (select pmr.striker as player_id,s.season_year,
                                 sum(pmr.total_runs) runs_scored,
                                 dense_rank() over(partition by season_year order by sum(pmr.total_runs) desc) season_runs_rank
			from player_match_runs pmr join matches m on pmr.match_id=m.match_id
			join season s on m.season_id=s.season_id
			group by pmr.striker,s.season_year),
top_run_rank_player as (select * from result
						where season_runs_rank between 1 and 5
						and season_year between 2014 and 2016
		                order by season_year,season_runs_rank)
select trp.player_id,p.player_name,count(trp.player_id) as no_of_times_in_top5 
from top_run_rank_player trp join player p on trp.player_id=p.player_id
group by trp.player_id,p.player_name
order by count(trp.player_id) desc
limit 10; 
 
 
 
 
-- top 10 player with highest strike rate and minimun 2000 runs scored
with runs_scored as (select bb.striker,p.player_name,sum(bs.runs_scored) as total_runs
					from player p join player_match pm on p.player_id=pm.player_id
					join ball_by_ball bb on pm.player_id=bb.striker and pm.match_id=bb.match_id
					join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
										  and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
					group by bb.striker,p.player_name having(sum(bs.runs_scored))>2000
                    order by total_runs desc),
balls_faced as (select bb.striker,p.player_name,count(bs.runs_scored)total_ball_faced
					from player p join player_match pm on p.player_id=pm.player_id
					join ball_by_ball bb on pm.player_id=bb.striker and pm.match_id=bb.match_id
					join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
										  and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
					group by bb.striker,p.player_name order by total_ball_faced desc)
select rs.striker as player_id,rs.player_name,rs.total_runs,
       bf.total_ball_faced,(rs.total_runs/bf.total_ball_faced)*100 as strike_rate
from runs_scored rs join balls_faced bf on rs.striker=bf.striker
order by strike_rate desc
limit 10;
   
   
   
   
-- top 10 bowlers taken highest wicket
select bb.bowler,p.player_name,count(wt.player_out) as number_of_wickets
from player p join player_match pm on p.player_id=pm.player_id
join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id
join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
						and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
group by bb.bowler,p.player_name order by number_of_wickets desc
limit 10;



-- to 10 bowlers with best economy, minimum 100 overs bowled
with total_runs_conceeded as (select bb.bowler as player_id,p.player_name,sum(bs.runs_scored) as runs_conceeded 
							from player p join player_match pm on p.player_id=pm.player_id 
							join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id 
							join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
														and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							group by bb.bowler,p.player_name order by runs_conceeded desc),
total_overs_bowled as (select bb.bowler as player_id,count(distinct bs.match_id,bs.innings_no,bs.over_id) as total_overs
						from player p join player_match pm on p.player_id=pm.player_id 
						join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id 
						join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
													and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
						group by bb.bowler order by total_overs desc)
select trc.*,tob.total_overs,(trc.runs_conceeded/tob.total_overs) as economy
from total_runs_conceeded  trc join total_overs_bowled tob on trc.player_id=tob.player_id
where total_overs>100
order by economy limit 10;





-- 4) Which players offer versatility in their skills and can contribute effectively
--    with both bat and ball? (can you visualize the data for the same)

-- top all rounder ..score>1000 and wickets>50 
with top_bowler as (select bb.bowler,p.player_name,count(wt.player_out) as number_of_wickets
					from player p join player_match pm on p.player_id=pm.player_id
					join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id
					join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
											and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
					group by bb.bowler,p.player_name order by number_of_wickets desc),
top_batsman as (select bb.striker,p.player_name,sum(bs.runs_scored) as total_runs
				from player p join player_match pm on p.player_id=pm.player_id
				join ball_by_ball bb on pm.player_id=bb.striker and pm.match_id=bb.match_id
				join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
										and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
				group by bb.striker,p.player_name order by total_runs desc)                    
                        
select tb.bowler as player_id,tb.player_name,tb.number_of_wickets,tbs.total_runs
from top_bowler tb join top_batsman tbs on tb.bowler=tbs.striker
where tb.number_of_wickets>50 and tbs.total_runs>1000;


-- 5) Are there players whose presence positively influences the morale and performance of the team? 
--    (justify your answer using visualisation)

-- win rate with player presence
SELECT pm.Player_Id, p.player_name,COUNT(DISTINCT m.Match_Id) AS Matches_Played,
       SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) AS Wins,
       (SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) / COUNT(DISTINCT m.Match_Id)) * 100 AS Win_Rate
FROM player_match pm
JOIN matches m ON pm.Match_Id = m.Match_Id
join player p on p.player_id=pm.player_id
GROUP BY pm.Player_Id,p.player_name
HAVING Matches_Played > 80
order by win_rate desc;  

 -- most man of the match award
SELECT pm.Player_Id,p.player_name,COUNT(m.Man_of_the_Match) AS Man_of_the_Match_Awards
FROM player_match pm
JOIN matches m ON pm.Match_Id = m.Match_Id
join player p on p.player_id=pm.player_id
WHERE pm.Player_Id = m.Man_of_the_Match
GROUP BY pm.Player_Id,p.player_name order by Man_of_the_Match_Awards desc;



-- 6) What would you suggest to RCB before going to mega auction ?

-- refer KPI File



-- 7) What do you think could be the factors contributing to the high-scoring matches 
--    and the impact on viewership and team strategies


select 
    t4.Season_Year,
    sum(case when t1.Over_Id between 1 and 6 or t1.Over_Id between 17 and 20 then t2.Runs_Scored else 0 end) as Runs_in_PowerPlay_DeathOvers,
    sum(case when t1.Over_Id between 7 and 16 then t2.Runs_Scored else 0 end) as Runs_in_MiddleOvers
from 
    ball_by_ball t1
join 
    batsman_scored t2
    on t1.Match_Id = t2.Match_Id and t1.Over_Id = t2.Over_Id and t1.Ball_Id = t2.Ball_Id and t1.Innings_No = t2.Innings_No
join 
    matches t3
    on t1.Match_Id = t3.Match_Id
join 
    season t4
    on t3.Season_Id = t4.Season_Id
where 
    t4.Season_Year between 2012 and 2016
group by 
    t4.Season_Year
order by 
    t4.Season_Year;
    
    
    
    
    
-- ii) Analyzing High-Scoring IPL Matches: Venue Performance and Contributing Factors

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



-- 8)Analyze the impact of home ground advantage on team performance and 
--   identify strategies to maximize this advantage for RCB.



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






-- 9)Come up with a visual and analytical analysis with the RCB past seasons performance 
--   and potential reasons for them not winning a trophy.

-- refer KPI

-- 10)How would you approach this problem, if the objective and subjective questions weren't given?



-- 11)In the "Match" table, some entries in the "Opponent_Team" column are incorrectly spelled as "Delhi_Capitals" 
-- instead of "Delhi_Daredevils". Write an SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".


SET SQL_SAFE_UPDATES = 0;
UPDATE team
SET Team_Name = 'Delhi Capitals'
WHERE Team_Name = 'Delhi Daredevils';
SET SQL_SAFE_UPDATES = 1; -- Re-enable safe updates if desired

select * from team;