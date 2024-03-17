use imdb_project;
select * from genre;
select * from data_mapping; 
select * from movies; 
select * from names;
select * from ratings;
select * from role_mapping; 
-- ################################## Segment 1 #####################
-- 1) -	Find the total number of rows in each table of the schema.
select count(*) as tot_rows from data_mapping;
select count(*) as tot_rows from genre;
select count(*) as tot_rows from movies;
select count(*) as tot_rows from ratings;
select count(*) as tot_rows from role_mapping;

-- 2) -	Identify which columns in the movie table have null values.
select * from movies;
select country,languages,worlwide_gross_income,production_company 
	from movies 
		where country = ''
        or languages = '' 
        or worlwide_gross_income = ''
        or production_company = '';
-- or 
select 
	count(country) as country_null, 
    (select count(languages) from movies where languages = '') as lan_null,
    (select count(worlwide_gross_income) from movies where worlwide_gross_income = '') as income_null,
    (select count(production_company) from movies where production_company = '') as production_company_null
from movies 
where country = '';

-- ################################# Segment 2: Movie Release Trends ################################
-- 1) Determine the total number of movies released each year and analyse the month-wise trend.
select * from movies;
select count(title) as movies_released, substr(date_published,4,2) as month,year
from movies 
group by year, substr(date_published,4,2)
order by year;

use imdb_project;

-- 2) Calculate the number of movies produced in the USA or India in the year 2019.
select * from movies;
select count(id)as total_movies
from movies 
	where (country = 'USA' or country = 'INDIA') and year = 2019;


-- ########################### Segment 3: Production Statistics and Genre Analysis #########################
-- 1) Retrieve the unique list of genres present in the dataset.
select * from genre;
select distinct(genre) from genre;

-- 2) Identify the genre with the highest number of movies produced overall 

select * from genre;

select count(movie_id) as total_movies, genre 
from genre 
	group by genre 
    order by total_movies desc 
    limit 1;

-- 3) Determine the count of movies that belong to only one genre.
with cte_1 as 
	(select movie_id,count(genre) as total_genres from genre group by movie_id)
		select count(movie_id),total_genres from cte_1 where total_genres = 1;
-- or 
WITH cte_1 AS (
    SELECT movie_id, COUNT(genre) AS total_genres 
    FROM genre 
    GROUP BY movie_id
)
SELECT COUNT(DISTINCT cte_1.movie_id)
FROM cte_1
WHERE total_genres = 1;

-- 4) Calculate the average duration of movies in each genre.
select * from movies;
select * from genre;

with cte_2 as (select m.duration, m.id,g.genre from movies m inner join genre g on g.movie_id = m.id)
		select avg(duration) as avg_duration, genre from cte_2 group by genre order by avg_duration desc;

-- 5) Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
use imdb_project;
select * from movies;
select * from genre;
with cte_3 as 
	(select count(m.id) as movies_produced,g.genre from movies m 
			inner join genre g on g.movie_id = m.id group by g.genre order by movies_produced)
			select *, rank() over(order by movies_produced desc) as rnk from cte_3;
 
########################################### Segment 4: Ratings Analysis and Crew Members #########################

-- 1) Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
select * from ratings;
select min(avg_rating) as min_avg_rating,
max(avg_rating) as max_avg_rating, 
min(total_votes) as min_votes,
max(total_votes) as max_votes, 
min(median_rating) as min_mediam_rating, 
max(median_rating) as max_median_rating
from ratings;

-- 2) Identify the top 10 movies based on average rating.
select movie_id from ratings order by avg_rating desc limit 10;

-- or 
select m.id, m.title, r.avg_rating from movies m 
	left join 
		ratings r  on m.id = r.movie_id 
		order by r.avg_rating desc limit 10;

-- 3) Summarise the ratings table based on movie counts by median ratings.
select median_rating,count(movie_id)as Num_of_Movies from ratings
group by median_rating
order by median_rating desc;

-- 4) Identify the production house that has produced the most number of hit movies (average rating > 8).
select * from movies;
select * from ratings;
with cte_4 as (
				select m.title, m.production_company,m.id, r.avg_rating 
                from movies m 
                inner join ratings r 
				on m.id = r.movie_id
)
select production_company, count(id) as total_movies 
from cte_4 
	where avg_rating > 8 
    group by production_company
	order by total_movies desc 
    limit 1;

-- 5) Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.
select * from movies;
select * from genre;
select * from ratings;
 
 select count(m.id) as 'number of movies',g.genre, m.country
 from movies m 
 inner join 
 ratings r on m.id = r.movie_id
 inner join 
 genre g on m.id = g.movie_id 
 where year(str_to_date(m.date_published,'%d-%m-%Y'))= 2017
 and month(str_to_date(m.date_published,'%d-%m-%Y'))= 3
 and r.total_votes > 1000
 and m.country = 'USA' 
 group by g.genre
 order by 1 desc;

-- 6) Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.

select m.title, g.genre,r.avg_rating 
from movies m 
inner join ratings r on m.id = r.movie_id 
inner join genre g on m.id = g.movie_id 
where m.title like 'The%'
and r.avg_rating > 8
;

####################################################Segment 5: Crew Analysis#####################################

-- 1) Identify the columns in the names table that have null values.
select 
   sum(case when id='' then 1 else 0 end) as Null_for_id,
    sum(case when name='' then 1 else 0 end) as Null_for_Name,
   sum(case when date_of_birth='' then 1 else 0 end) as Null_for_DOB,
   sum(case when known_for_movies='' then 1 else 0 end) as known_for_movies,
   sum(case when height='' then 1 else 0 end) as Null_for_height
from names;

-- 2) Determine the top three directors in the top three genres with movies having an average rating > 8.

WITH cte AS (
    SELECT  d.name_id, g.genre, n.name,COUNT(*) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY g.genre ORDER BY COUNT(*) DESC) AS director_rank
    FROM data_mapping d
    LEFT JOIN names n ON d.name_id = n.id
    LEFT JOIN movies m ON d.movie_id = m.id
    LEFT JOIN genre g ON m.id = g.movie_id
    LEFT JOIN ratings r ON m.id = r.movie_id
    WHERE  r.avg_rating > 8
    GROUP BY d.name_id, g.genre, n.name order by movie_count desc)
SELECT genre, name,SUM(movie_count) AS total_movie_count, director_rank FROM cte 
WHERE  director_rank <= 3
GROUP BY genre, name, director_rank;

-- 3) Find the top two actors whose movies have a median rating >= 8.

select n.id,n.name,m.title, r.median_rating,rm.category
from movies m 
	left join ratings r on m.id = r.movie_id
	left join data_mapping dm on r.movie_id = dm.movie_id 
	left join names n on n.id = dm.name_id 
	left join role_mapping rm on n.id = rm.name_id 
		where rm.category = 'actor'
		and r.median_rating >= 8 
			order by median_rating desc limit 2;

-- 4) Identify the top three production houses based on the number of votes received by their movies.

select distinct(m.production_company) as 'production house', sum(r.total_votes) as votes
from movies m 
left join ratings r on m.id = r.movie_id 
group by m.production_company
order by votes desc limit 3;

-- 5) Rank actors based on their average ratings in Indian movies released in India.
with cte_6 as (select rm.name_id ,m.country, avg(r.avg_rating) as average, rm.category 
				from movies m 
                left join ratings r on m.id = r.movie_id 
                left join data_mapping dm on r.movie_id = dm.movie_id 
                left join role_mapping rm on m.id =  rm.movie_id
                where m.country = 'India'
                and category = 'actor'
                group by rm.name_id 
                
)
select *,row_number() over(order by average desc) as Rank_of_actors from cte_6;

-- 6) Identify the top five actresses in Hindi movies released in India based on their average ratings.

with cte_7 as (select rm.name_id ,m.country, avg(r.avg_rating) as average, rm.category 
				from movies m 
                left join ratings r on m.id = r.movie_id 
                left join data_mapping dm on r.movie_id = dm.movie_id 
                left join role_mapping rm on m.id =  rm.movie_id
                where m.country = 'India'
                and category = 'actress'
                and m.languages = 'Hindi'
                group by rm.name_id 
                
)
select *,row_number() over(order by average desc) as Rank_of_actors from cte_7;

##########################################Segment 6: Broader Understanding of Data####################################

-- 1) Classify thriller movies based on average ratings into different categories.
select m.id, r.avg_rating,m.title,g.genre,
case 
	when r.avg_rating >= 9.0 then 'Blockbuster'
    when r.avg_rating >= 8.0 then 'Superhit'
    when r.avg_rating >= 7.0 then 'Hit'
    when r.avg_rating >= 5.5 then 'Average'
    else 'Flop' 
    end as Movie_category
from movies m 
inner join genre g on m.id = g.movie_id 
inner join ratings r on m.id = r.movie_id 
where g.genre = 'thriller';

-- 2) analyse the genre-wise running total and moving average of the average movie duration.

SELECT id ,genre,duration,
sum(duration) over (partition by genre  order by id) Running_total, 
avg(duration) over (partition by genre  order by id) moving_Average
from movies
left join genre on (movies.id=genre.movie_id);

-- 3) Identify the five highest-grossing movies of each year that belong to the top three genres. 

WITH CTE AS (SELECT m.id, g.genre, m.title, m.worlwide_gross_income,m.year,
        RANK() OVER (PARTITION BY m.year, g.genre ORDER BY m.worlwide_gross_income DESC) AS ranking
    FROM movies m
    LEFT JOIN genre g ON m.id = g.movie_id
),
CTE_GenreRank AS (SELECT DISTINCT genre,
        RANK() OVER (ORDER BY movies DESC) AS genre_rank
    FROM (
        SELECT  genre,COUNT(id) AS movies
        FROM CTE
        GROUP BY genre LIMIT 3
    ) genre_count
    LIMIT 3
)
SELECT cte.title, cte.worlwide_gross_income, cte.year, cte.genre
FROM CTE cte
JOIN CTE_GenreRank genre_rank ON cte.genre = genre_rank.genre
WHERE cte.ranking <= 5
ORDER BY cte.year, genre_rank.genre_rank, cte.ranking;

-- 4) Determine the top two production houses that have produced the highest number of hits among multilingual movies.

SELECT m.production_company,m.languages, COUNT(m.id) AS number_of_hits
FROM movies m 
left JOIN ratings r ON m.id = r.movie_id 
WHERE m.languages like '%,%'
AND r.avg_rating > 8
GROUP BY m.production_company,languages
ORDER BY number_of_hits DESC
limit 2;

-- 5) Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.
select * from names;
use imdb_project;

SELECT id,g.genre,count( m.id) as movie_produced
FROM movies m
left join ratings r on m.id=r.movie_id
left join role_mapping ro on m.id=ro.movie_id
left join genre g on m.id=g.movie_id
where ro.category='actress' and r.avg_rating>8 and g.genre='Drama'
group by id,g.genre order by movie_produced desc  limit 3;

-- 6) Retrieve details for the top nine directors based on the number of movies, 
--       	including average inter-movie duration, ratings, and more.
##############
-- assuming the movie_id in the known_for_movies column is the work done by the director. 
select n.id,n.name as Director_name, m.id, m.title 
from movies m 
inner join names n on m.id = n.known_for_movies;
-- data_mapping,movies,names,ratings
select 
 d.name_id as director_id,
 n.name as director_name,
 count(m.id)as num_Movies_produced,
 avg(m.duration)as average_duration,
 avg(r.avg_rating) from movies m
 left join genre g on m.id=g.movie_id
left join data_mapping d on m.id=d.movie_id
left join ratings r on m.id=r.movie_id
LEFT join names n on d.name_id=n.id
where d.name_id is not null
group by d.name_id,n.name order by num_Movies_produced desc limit 9;

######################################################### END ######################################################
