--1. Who is the senior most employee based on job title?
SELECT
	EMPLOYEE_ID,
	LAST_NAME,
	FIRST_NAME,
	TITLE
FROM
	EMPLOYEE
ORDER BY
	LEVELS DESC
LIMIT
	1;

--2. Which countries have the most Invoices?
SELECT
	BILLING_COUNTRY,
	COUNT(BILLING_COUNTRY) AS MOST_INVOICE
FROM
	INVOICE
GROUP BY
	BILLING_COUNTRY
ORDER BY
	MOST_INVOICE DESC
LIMIT
	1;

--3. What are top 3 values of total invoice?
SELECT
	TOTAL
FROM
	INVOICE
ORDER BY
	TOTAL DESC
LIMIT
	3;

--4. Which city has the best customers? We would like to throw a promotional Music 
--Festival in the city we made the most money. Write a query that returns one city that 
--has the highest sum of invoice totals. Return both the city name & sum of all invoice 
--totals.
SELECT
	BILLING_CITY,
	ROUND(SUM(TOTAL)::DECIMAL, 2) AS INVOICE_TOTAL
FROM
	INVOICE
GROUP BY
	BILLING_CITY
ORDER BY
	INVOICE_TOTAL DESC;

--5. Who is the best customer? The customer who has spent the most money will be 
--declared the best customer. Write a query that returns the person who has spent the 
--most money.
SELECT
	C.CUSTOMER_ID,
	C.LAST_NAME,
	C.FIRST_NAME,
	ROUND(SUM(I.TOTAL)::DECIMAL, 2) AS TOTAL_INVOICE
FROM
	CUSTOMER C
	JOIN INVOICE I ON C.CUSTOMER_ID = I.CUSTOMER_ID
GROUP BY
	C.CUSTOMER_ID
ORDER BY
	TOTAL_INVOICE DESC
LIMIT
	1;

--6. Write query to return the email, first name, last name, & Genre of all Rock Music 
--listeners. Return your list ordered alphabetically by email starting with A
SELECT
	C.EMAIL,
	C.FIRST_NAME,
	C.LAST_NAME
FROM
	CUSTOMER C
	JOIN INVOICE I ON C.CUSTOMER_ID = I.CUSTOMER_ID
	JOIN INVOICE_LINE IL ON I.INVOICE_ID = IL.INVOICE_ID
WHERE
	IL.TRACK_ID IN (
		SELECT
			T.TRACK_ID
		FROM
			TRACK T
			JOIN GENRE G ON T.GENRE_ID = G.GENRE_ID
		WHERE
			G.NAME LIKE 'Rock'
	)
ORDER BY
	C.EMAIL;

--7. Let's invite the artists who have written the most rock music in our dataset. Write a 
--query that returns the Artist name and total track count of the top 10 rock bands.
WITH
	CTE AS (
		SELECT
			T.ALBUM_ID
		FROM
			TRACK T
			JOIN GENRE G ON T.GENRE_ID = G.GENRE_ID
		WHERE
			G.NAME LIKE 'Rock'
	)
SELECT
	A.ARTIST_ID,
	A.NAME AS ARTIST_NAME,
	COUNT(A.ARTIST_ID) AS NUMBER_OF_SONGS
FROM
	CTE C
	JOIN ALBUM AL ON C.ALBUM_ID = AL.ALBUM_ID
	JOIN ARTIST A ON AL.ARTIST_ID = A.ARTIST_ID
GROUP BY
	A.ARTIST_ID
ORDER BY
	NUMBER_OF_SONGS DESC
LIMIT
	10;

--8. Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the 
--longest songs listed first
SELECT
	NAME AS TRACK_NAME,
	MILLISECONDS AS SONG_LENGTH
FROM
	TRACK
WHERE
	MILLISECONDS > (
		SELECT
			AVG(MILLISECONDS)
		FROM
			TRACK
	)
ORDER BY
	MILLISECONDS DESC;

--9. Find how much amount spent by each customer on artists? Write a query to return
--customer name, artist name and total spent.
SELECT
	C.CUSTOMER_ID,
	CONCAT(RTRIM(C.FIRST_NAME), ' ', RTRIM(C.LAST_NAME)),
	A.NAME,
	SUM(IL.UNIT_PRICE * IL.QUANTITY) AS TOTAL_SPENDS
FROM
	CUSTOMER C
	JOIN INVOICE I ON C.CUSTOMER_ID = I.CUSTOMER_ID
	JOIN INVOICE_LINE IL ON I.INVOICE_ID = IL.INVOICE_ID
	JOIN TRACK T ON IL.TRACK_ID = T.TRACK_ID
	JOIN ALBUM AL ON T.ALBUM_ID = AL.ALBUM_ID
	JOIN ARTIST A ON AL.ARTIST_ID = A.ARTIST_ID
GROUP BY
	1,
	2,
	3
ORDER BY
	TOTAL_SPENDS DESC;

--10. We want to find out the most popular music Genre for each country. We determine the 
--most popular genre as the genre with the highest amount of purchases. Write a query 
--that returns each country along with the top Genre. For countries where the maximum 
--number of purchases is shared return all Genres.
WITH
	POPULAR_GENRE AS (
		SELECT
			COUNT(IL.QUANTITY) AS PURCHASES,
			C.COUNTRY,
			G.NAME,
			G.GENRE_ID,
			ROW_NUMBER() OVER (
				PARTITION BY
					C.COUNTRY
				ORDER BY
					COUNT(IL.QUANTITY) DESC
			) AS ROW_NUMBER
		FROM
			INVOICE_LINE IL
			JOIN INVOICE I ON I.INVOICE_ID = IL.INVOICE_ID
			JOIN CUSTOMER C ON C.CUSTOMER_ID = I.CUSTOMER_ID
			JOIN TRACK T ON T.TRACK_ID = IL.TRACK_ID
			JOIN GENRE G ON G.GENRE_ID = T.GENRE_ID
		GROUP BY
			2,
			3,
			4
		ORDER BY
			2 ASC,
			1 DESC
	)
SELECT
	*
FROM
	POPULAR_GENRE
WHERE
	ROW_NUMBER <= 1;

--11.Write a query that determines the customer that has spent the most on music for each 
--country. Write a query that returns the country along with the top customer and how
--much they spent. For countries where the top amount spent is shared, provide all 
--customers who spent this amount.
WITH
	COUNTRY_CUSTOMER AS (
		SELECT
			C.CUSTOMER_ID,
			CONCAT(RTRIM(C.FIRST_NAME), ' ', RTRIM(C.LAST_NAME)),
			I.BILLING_COUNTRY,
			SUM(I.TOTAL) AS TOTAL_SPENDS,
			ROW_NUMBER() OVER (
				PARTITION BY
					I.BILLING_COUNTRY
				ORDER BY
					SUM(I.TOTAL) DESC
			) AS ROW_NUMBER
		FROM
			INVOICE I
			JOIN CUSTOMER C ON I.CUSTOMER_ID = C.CUSTOMER_ID
		GROUP BY
			1,
			2,
			3
		ORDER BY
			3 ASC,
			4 DESC
	)
SELECT
	*
FROM
	COUNTRY_CUSTOMER
WHERE
	ROW_NUMBER <= 1