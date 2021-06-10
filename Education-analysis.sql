/*1)	Gross intake ratio in first grade of primary education, female (% of relevant age group)*/
CREATE TEMP TABLE Gross_intake_1grade_female AS
SELECT DISTINCT i.countryname,
  i."Year",
  i.value,
  round(LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year")::NUMERIC, 2) previous_year,
  round(((i.value - LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))/ LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))::NUMERIC, 2) YoY_value
FROM
  indicators i
JOIN country c ON 
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.GINT.FE.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;

SELECT
  *
FROM Gross_intake_1grade_female;

/*2)	Gross intake ratio in first grade of primary education, male (% of relevant age group)*/
CREATE TEMP TABLE Gross_intake_1grade_male AS
SELECT
  DISTINCT i.countryname,
  i."Year",
  i.value,
  round(LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year")::NUMERIC, 2) previous_year,
  round(((i.value - LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))/ LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))::NUMERIC, 2) YoY_value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.GINT.MA.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;

SELECT
  *
FROM
  Gross_intake_1grade_male;

/*3)	Gross intake ratio in first grade of primary education, total (% of relevant age group)
 * Por�wnanie warto�ci dla kobiet, m�czyzn oraz dla kobiet i m�czyzn ��cznie.
 * Wska�nik reprezentuje stosunek os�b przyj�tych do pierwszej klasy szko�y podstawowej do grupy dzieci w wieku szkolnym, 
 * kt�re powinny rozpocz�� edukacj� w danym roku.
 */ 
CREATE TEMP TABLE Gross_intake_1grade_total AS
SELECT
  DISTINCT i.countryname,
  i."Year",
  i.value,
  round(LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year")::NUMERIC, 2) previous_year,
  round(((i.value - LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))/ LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))::NUMERIC, 2) YoY_value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.GINT.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;


SELECT
  *
FROM
  Gross_intake_1grade_female;

SELECT
  *
FROM
  Gross_intake_1grade_male;

SELECT
  *
FROM
  Gross_intake_1grade_total;

SELECT
  f.countryname,
  f."Year",
  round(f.value::NUMERIC, 2) AS female,
  round(m.value::NUMERIC, 2) AS male,
  round(t.value::NUMERIC, 2) AS total_f_m
FROM
  Gross_intake_1grade_female f
JOIN Gross_intake_1grade_male m ON
  f.countryname = m.countryname
  AND f."Year" = m."Year"
JOIN Gross_intake_1grade_total t ON
  f.countryname = t.countryname
  AND f."Year" = t."Year";



/* Dekady
 * Poniewa� dla niekt�rych lat i kraj�w posiadane dane s� niekompletne, postanowiono dokona� analizy w dekadach
 */

CREATE TABLE decades AS
SELECT
  DISTINCT i."Year",
  concat((i."Year" / 10), '0') AS decade_start_date,
  concat((i."Year" / 10)::varchar, '0')::NUMERIC + 9 AS decade_end_date,
  substring(CAST(i."Year" AS varchar), 3, 1) AS decade,
  substring(CAST(i."Year" AS varchar), 1, 2)::NUMERIC + 1 AS century
FROM
  indicators i
ORDER BY
  i."Year";

SELECT
  *
FROM
  decades;

/* Gender gaps per dekada
 * Pokazuje r�nic� mi�dzy przyj�ciem do szko�y podstawowej kobiet i m�czyzn per rok i dekada.*/

CREATE TEMP TABLE Gender_gaps AS
SELECT
  c.region,
  f.countryname,
  d.century,
  d.decade,
  f."Year",
  f.value AS female,
  m.value AS male,
  m.value - f.value AS gender_gap
FROM
  Gross_intake_1grade_female f
JOIN Gross_intake_1grade_male m ON
  f.countryname = m.countryname
  AND f."Year" = m."Year"
JOIN Gross_intake_1grade_total t ON
  f.countryname = t.countryname
  AND f."Year" = t."Year"
JOIN country c ON
  f.countryname = c.tablename
JOIN decades d ON
  f."Year" = d."Year"
GROUP BY
  c.region,
  f.countryname,
  d.century,
  d.decade,
  f."Year",
  f.value,
  m.value
ORDER BY
  f.countryname,
  d.century,
  d.decade;


SELECT
  *
FROM
  gender_gaps gp;
/*where gp.gender_gap = gp.min_gender_gap or gp.gender_gap = gp.max_gender_gap*/


/*Pokazuje �redni�, min oraz max gender gap per kraj oraz dekad�*/

CREATE TEMP TABLE gender_gaps_basic_measures AS
SELECT
  DISTINCT gp.region,
  gp.countryname,
  gp.century,
  gp.decade,
  avg(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS avg_gap_country_and_decade,
  min(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS min_gap_country_and_decade,
  max(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS max_gap_country_and_decade
FROM
  gender_gaps gp
ORDER BY
  gp.region,
  gp.century,
  gp.decade;

SELECT
  *
FROM
  gender_gaps_basic_measures;

SELECT
  gpm.region,
  gpm.countryname,
  gpm.century,
  gpm.decade,
  gpm.avg_gap_country_and_decade,
  (
    SELECT
      min(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  ) ,
  (
    SELECT
      max(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  )
FROM
  gender_gaps_basic_measures gpm
WHERE
  gpm.avg_gap_country_and_decade = (
    SELECT
      min(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  )
  OR gpm.avg_gap_country_and_decade = (
    SELECT
      max(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  );

/* Na przestrzeni lat, najwi�ksza dysproporcja ze wzgl�du na p�e� wyst�pi�a w Bhutanie oraz Lesotho w latach 70tych ubieg�ego wieku.
 * W Buthanie przyj�to do pierwszej klasy o 64 pkt procentowe wi�cej ch�opc�w ni� dziewczynech, 
 * podczas gdy w Lesotho o 20 pkt procentowych wi�cej dziewczynek ni� ch�opc�w.
 */


/*Pokazuje �redni� gender gap per kraj oraz wiek*/

CREATE TEMP TABLE gender_gaps_basic_measures2 AS
SELECT
  DISTINCT gp.region,
  gp.countryname,
  gp.century,
  gp.decade,
  avg(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS avg_gap_country_and_decade
FROM
  gender_gaps gp
ORDER BY
  gp.region,
  gp.century,
  gp.decade;

SELECT
  *
FROM
  gender_gaps_basic_measures2;

/*ranking per century i decade - top 3
 * Pokazuje ranking per kraj i dekada w obr�bie regionu - warto�� bezwzgl�dna - im bli�ej zera tym kraj bardziej rozwini�ty */
CREATE TEMP TABLE ranking_top_3 AS
SELECT
  gpm2.region,
  gpm2.countryname,
  gpm2.century,
  gpm2.decade,
  abs(gpm2.avg_gap_country_and_decade) AS wartosc_bezwzgledna,
  DENSE_RANK() OVER(
    PARTITION BY gpm2.region,
    gpm2.century,
    gpm2.decade
  ORDER BY
    abs(gpm2.avg_gap_country_and_decade)
  ) AS ranking,
  count(*) OVER (
    PARTITION BY gpm2.countryname
  ) liczba_wystapien
FROM
  gender_gaps_basic_measures2 gpm2;

SELECT
  *
FROM
  ranking_top_3;

SELECT
  *
FROM
  ranking_top_3 r3
WHERE
  r3.ranking <= 3;

-----------------------------------
/*sytuacja kraj�w dla kt�rych mamy dane conajmniej dla 3 dekad*/

SELECT
  r3.region,
  r3.countryname,
  r3.countryname,
  r3.century,
  r3.decade,
  r3.wartosc_bezwzgledna,
  r3.ranking
FROM
  ranking_top_3 r3
WHERE
  r3.liczba_wystapien >= '3'
GROUP BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.decade,
  r3.wartosc_bezwzgledna,
  r3.ranking,
  r3.liczba_wystapien
ORDER BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.decade;

/* Analiza poni�ej pokazuje ruchy w rankingu na przestrzeni dw�ch ostatnich wiek�w - wielko�� gender gap. 
 * Pokazuje wzmocnienie lub os�abienie danego kraju w obr�bie regionu.
 * Ranking nie bie�e pod uwag� r�nic w wielko�ci populacji w poszczeg�lnych krajach*/
 /* Tabela Punkty_20 pokazuje �rednie miejsce w rankinu w 20 wieku per kraj w regionie - dla wykazania tendencji*/

CREATE TEMP TABLE Punkty_20 AS
SELECT
  DISTINCT r3.region,
  r3.countryname,
  r3.century,
  avg(r3.ranking) OVER (
    PARTITION BY r3.countryname,
    r3.century
  ) AS avg_ranking_20_century
FROM
  ranking_top_3 r3
WHERE
  r3.liczba_wystapien >= '3'
  AND r3.century = 20
GROUP BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.ranking
ORDER BY
  r3.region,
  r3.countryname,
  r3.century;

SELECT
  *
FROM
  Punkty_20;

/*Tabela Punkty_21 pokazuje �rednie miejsce w rankinu w 21 wieku per kraj w regionie - dla wykazania tendencji*/
CREATE TEMP TABLE Punkty_21 AS
SELECT
  DISTINCT r3.region,
  r3.countryname,
  r3.century,
  avg(r3.ranking) OVER (
    PARTITION BY r3.countryname,
    r3.century
  ) AS avg_ranking_21_century
FROM
  ranking_top_3 r3
WHERE
  r3.liczba_wystapien >= '3'
  AND r3.century = 21
GROUP BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.ranking
ORDER BY
  r3.region,
  r3.countryname,
  r3.century;

SELECT
  p20.region,
  p20.countryname,
  round(p20.avg_ranking_20_century, 2) AS century_20,
  round(p21.avg_ranking_21_century, 2) AS century_21,
  round((p20.avg_ranking_20_century - p21.avg_ranking_21_century), 2) AS progress
FROM
  Punkty_20 p20
JOIN punkty_21 p21 ON
  p20.countryname = p21.countryname
ORDER BY
  p20.region,
  round((p20.avg_ranking_20_century - p21.avg_ranking_21_century), 2);

/* East Asia & Pacific: najwi�kszy spadek wyst�pi� w Malezji, 
 * w miar� podobne tempo rozmowu maj� Tajlandia, Tonga, Mongolia, Myanmar oraz Filipiny.
 * Japonia zar�wno w 20 wieku jak i w 21 sta�a na czele rankingu.
 * Najwi�kszy skok w prz�d natomiast wyst�pi� na Wyspach Marshalla.
 * 
 * Europe & Central Asia: najwi�kszy spadek wyst�pi� w Gruzji, W�oszech oraz na Cyprze.
 * Najwi�kszy wzrost natomiast na Bia�orusi i w Irlandii.
 * Nale�y jednak zauwa�y�, �e w Europie r�nice pomi�dzy dost�pem do edukacji w�r�d kobie i m�czyzn s� nieznaczne.
 * 
 * Latin America & Caribbean: Najwi�kszy spadek wyst�pi� w Kolumbii, z pierwszej dziesi�tki w 20 wieku spad�a w okolice 29 pozycji.
 * Podobny spadek odnotowano w Nikaragui, nieco mniejszu na Dominikania, St.Lucia, Trinidad i Tobago.
 * Najwi�kszy wzrost wyst�pi� na Dominice, w Arubii i Meksyku.
 * 
 * Middle East & North Africa: Najwi�kszy spadek wyst�pi� w Katarze, z okolic 5 miejsca spad� w okolice 13.
 * Spadek w rankingu odnotowano r�wnie� na Malcie i w Libanie.
 * Najwi�kszy progres odnotowano w Iranie, Maroku oraz Tunezji.
 * 
 * North America: Trudno m�wi� o wzrostach i spadkach. Na przestrzeni wiek�w sytuacja nie zmienila si� zbytnio.
 * 
 * South Asia: Najwi�kszy spadek wyst�pi� w Afganistanie, z �rednio czwartego miejsca spad� w okolice 7-8. Butan natomiast z okolic 4 wskoczy� na 2.
 * 
 * Sub-Saharan Africa: Najwi�kszy spadek odnotowano w Suazi, Nigerze i Kamerunie. Najwi�kszy wzrost z Gambii, Ugandzie i Ghanie. 
*/
----------------------------------------------------------