/*1)	Gross intake ratio in first grade of primary education, female (% of relevant age group)*/
create temp table Gross_intake_1grade_female
as
select 	distinct i.countryname
,		i."Year" 
,		i.value
,		round(lag(i.value) over (partition by i.countryname order by i."Year")::numeric,2) previous_year
,		round(((i.value - lag(i.value) over (partition by i.countryname order by i."Year"))/
		lag(i.value) over (partition by i.countryname order by i."Year"))::numeric,2) YoY_value
from indicators i
join country c on i.countrycode = c.countrycode 
where c.region is not null and c.region <> '' and indicatorcode = 'SE.PRM.GINT.FE.ZS'
group by i.countryname, i."Year", i.value;

select * from Gross_intake_1grade_female;

/*2)	Gross intake ratio in first grade of primary education, male (% of relevant age group)*/
create temp table Gross_intake_1grade_male
as
select 	distinct i.countryname
,		i."Year" 
,		i.value
,		round(lag(i.value) over (partition by i.countryname order by i."Year")::numeric,2) previous_year
,		round(((i.value - lag(i.value) over (partition by i.countryname order by i."Year"))/
lag(i.value) over (partition by i.countryname order by i."Year"))::numeric,2) YoY_value
from indicators i
join country c on i.countrycode = c.countrycode 
where c.region is not null and c.region <> '' and indicatorcode = 'SE.PRM.GINT.MA.ZS'
group by i.countryname, i."Year", i.value;

select * from Gross_intake_1grade_male;

/*3)	Gross intake ratio in first grade of primary education, total (% of relevant age group)
 * Por�wnanie warto�ci dla kobiet, m�czyzn oraz dla kobiet i m�czyzn ��cznie.
 * Wska�nik reprezentuje stosunek os�b przyj�tych do pierwszej klasy szko�y podstawowej do grupy dzieci w wieku szkolnym, 
 * kt�re powinny rozpocz�� edukacj� w danym roku.
 */ 
create temp table Gross_intake_1grade_total
as
select 	distinct i.countryname
,		i."Year" 
,		i.value
,		round(lag(i.value) over (partition by i.countryname order by i."Year")::numeric,2) previous_year
,		round(((i.value - lag(i.value) over (partition by i.countryname order by i."Year"))/
lag(i.value) over (partition by i.countryname order by i."Year"))::numeric,2) YoY_value
from indicators i
join country c on i.countrycode = c.countrycode 
where c.region is not null and c.region <> '' and indicatorcode = 'SE.PRM.GINT.ZS'
group by i.countryname, i."Year", i.value;


select * from Gross_intake_1grade_female;
select * from Gross_intake_1grade_male;
select * from Gross_intake_1grade_total;

select 
		f.countryname 
,		f."Year"
,		round(f.value::numeric,2) as female
,		round(m.value::numeric,2) as male
,		round(t.value::numeric,2) as total_f_m
from Gross_intake_1grade_female f
join Gross_intake_1grade_male m on f.countryname = m.countryname and f."Year" = m."Year"
join Gross_intake_1grade_total t on f.countryname = t.countryname and f."Year" = t."Year";



/* Dekady
 * Poniewa� dla niekt�rych lat i kraj�w posiadane dane s� niekompletne, postanowiono dokona� analizy w dekadach
 */

create table decades
as
select distinct i."Year"
,		concat((i."Year"/10),'0') as decade_start_date
,		concat((i."Year"/10)::varchar,'0')::numeric + 9 as decade_end_date
,		substring(cast(i."Year" as varchar),3,1) as decade
,		substring(cast(i."Year" as varchar),1,2)::numeric + 1 as century
from indicators i
order by i."Year";

select * from decades;

/* Gender gaps per dekada
 * Pokazuje r�nic� mi�dzy przyj�ciem do szko�y podstawowej kobiet i m�czyzn per rok i dekada.*/

create temp table Gender_gaps
as
select 
		c.region
,		f.countryname 
,		d.century
,		d.decade
,		f."Year"
,		f.value as female
,		m.value as male
,		m.value - f.value as gender_gap
from Gross_intake_1grade_female f
join Gross_intake_1grade_male m on f.countryname = m.countryname and f."Year" = m."Year"
join Gross_intake_1grade_total t on f.countryname = t.countryname and f."Year" = t."Year"
join country c on f.countryname = c.tablename
join decades d on f."Year" = d."Year"
group by c.region
,		f.countryname 
,		d.century 
,		d.decade 
,		f."Year"
,		f.value
,		m.value
order by f.countryname, d.century, d.decade;


select * from gender_gaps gp;
/*where gp.gender_gap = gp.min_gender_gap or gp.gender_gap = gp.max_gender_gap*/

-----------------------
/*Podzia� w dekadach*/
/*select distinct
		gp.region
,		gp.countryname
,		gp.century
,		gp.decade
,		min(gp.gender_gap) over (partition by gp.decade, gp.countryname)
,		max(gp.gender_gap) over (partition by gp.decade, gp.countryname)
from gender_gaps gp
order by gp.countryname, gp.century, gp.decade;

select * from gender_gaps;*/

-----------------------------
/*Pokazuje �redni�, min oraz max gender gap per kraj oraz dekad�*/

create temp table gender_gaps_basic_measures
as
select distinct
		gp.region
,		gp.countryname
,		gp.century
,		gp.decade
,		avg(gp.gender_gap) over (partition by gp.decade, gp.countryname) as avg_gap_country_and_decade
,		min(gp.gender_gap) over (partition by gp.decade, gp.countryname) as min_gap_country_and_decade
,		max(gp.gender_gap) over (partition by gp.decade, gp.countryname) as max_gap_country_and_decade
from gender_gaps gp
order by gp.region, gp.century, gp.decade;

select * from gender_gaps_basic_measures

select 
		gpm.region
,		gpm.countryname
,		gpm.century
,		gpm.decade
,		gpm.avg_gap_country_and_decade
,		(select min(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm)
,		(select max(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm)
from gender_gaps_basic_measures gpm
where gpm.avg_gap_country_and_decade = (select min(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm)
		or gpm.avg_gap_country_and_decade = (select max(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm);

/* Na przestrzeni lat, najwi�ksza dysproporcja ze wzgl�du na p�e� wyst�pi�a w Bhutanie oraz Lesotho w latach 70tych ubieg�ego wieku.
 * W Buthanie przyj�to do pierwszej klasy o 64 pkt procentowe wi�cej ch�opc�w ni� dziewczynech, 
 * podczas gdy w Lesotho o 20 pkt procentowych wi�cej dziewczynek ni� ch�opc�w.
 */


/*Pokazuje �redni� gender gap per kraj oraz wiek*/

create temp table gender_gaps_basic_measures2
as
select distinct
		gp.region
,		gp.countryname
,		gp.century
,		gp.decade
,		avg(gp.gender_gap) over (partition by gp.decade, gp.countryname) as avg_gap_country_and_decade
from gender_gaps gp
order by gp.region, gp.century, gp.decade;

select * from gender_gaps_basic_measures2;

/*ranking per century i decade - top 3
 * Pokazuje ranking per kraj i dekada w obr�bie regionu - warto�� bezwzgl�dna - im bli�ej zera tym kraj bardziej rozwini�ty */
create temp table ranking_top_3
as
select gpm2.region, gpm2.countryname, gpm2.century, gpm2.decade, abs(gpm2.avg_gap_country_and_decade) as wartosc_bezwzgledna
,	dense_rank() over(partition by gpm2.region, gpm2.century, gpm2.decade order by abs(gpm2.avg_gap_country_and_decade))  as ranking
,	count(*) over (partition by gpm2.countryname) liczba_wystapien
from gender_gaps_basic_measures2 gpm2;

select * from ranking_top_3;

select *
from ranking_top_3 r3
where r3.ranking <= 3;

-----------------------------------
/*sytuacja kraj�w dla kt�rych mamy dane conajmniej dla 3 dekad*/

select 
		r3.region
,		r3.countryname
,		r3.countryname
,		r3.century
,		r3.decade
,		r3.wartosc_bezwzgledna
,		r3.ranking
from ranking_top_3 r3
where r3.liczba_wystapien >= '3'
group by r3.region, r3.countryname, r3.century, r3.decade, r3.wartosc_bezwzgledna, r3.ranking, r3.liczba_wystapien
order by r3.region, r3.countryname, r3.century, r3.decade;

--Punkty
/*select 
		r3.region
,		r3.countryname
,		r3.century
,		r3.decade
,		r3.wartosc_bezwzgledna
,		r3.ranking
,		avg(r3.ranking) over (partition by r3.countryname, r3.century)
from ranking_top_3 r3
where r3.liczba_wystapien >= '3'
group by r3.region, r3.countryname, r3.century, r3.decade, r3.wartosc_bezwzgledna, r3.ranking, r3.liczba_wystapien
order by r3.region, r3.countryname, r3.century, r3.decade;*/


/* Analiza poni�ej pokazuje ruchy w rankingu na przestrzeni dw�ch ostatnich wiek�w - wielko�� gender gap. 
 * Pokazuje wzmocnienie lub os�abienie danego kraju w obr�bie regionu.
 * Ranking nie bie�e pod uwag� r�nic w wielko�ci populacji w poszczeg�lnych krajach*/
 /* Tabela Punkty_20 pokazuje �rednie miejsce w rankinu w 20 wieku per kraj w regionie - dla wykazania tendencji*/

create temp table Punkty_20
as
select distinct
		r3.region
,		r3.countryname
,		r3.century
,		avg(r3.ranking) over (partition by r3.countryname, r3.century) as avg_ranking_20_century
from ranking_top_3 r3
where r3.liczba_wystapien >= '3' and r3.century = 20
group by r3.region, r3.countryname, r3.century, r3.ranking
order by r3.region, r3.countryname, r3.century;

select * from Punkty_20;

/*Tabela Punkty_21 pokazuje �rednie miejsce w rankinu w 21 wieku per kraj w regionie - dla wykazania tendencji*/
create temp table Punkty_21
as
select distinct
		r3.region
,		r3.countryname
,		r3.century
,		avg(r3.ranking) over (partition by r3.countryname, r3.century) as avg_ranking_21_century
from ranking_top_3 r3
where r3.liczba_wystapien >= '3' and r3.century = 21
group by r3.region, r3.countryname, r3.century, r3.ranking
order by r3.region, r3.countryname, r3.century;

select 
	p20.region
,	p20.countryname
,	round(p20.avg_ranking_20_century,2) as century_20
,	round(p21.avg_ranking_21_century,2) as century_21
,	round((p20.avg_ranking_20_century - p21.avg_ranking_21_century),2) as progress
from Punkty_20 p20
join punkty_21 p21 on p20.countryname = p21.countryname
order by p20.region, round((p20.avg_ranking_20_century - p21.avg_ranking_21_century),2);

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