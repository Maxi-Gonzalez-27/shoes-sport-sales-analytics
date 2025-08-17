/* ============================
   CLIENTES
============================ */

--Distribución de edad por deporte--
Select P.Sport, RangeAge = 
	Case
		When Age < 25 then 'Under 25'
		When Age > 24 and Age < 35 then 'Between 25 and 34'
		When Age > 34 and Age < 45 then 'Between 35 and 44'
		When Age > 44 and Age < 55 then 'Between 45 and 54'
		Else 'Over 55'
	End , Count(*) as QuantitySales
from Sales S
join Products P on S.ProductID = P.ProductID
Join Clients C on C.ClientID = S.ClientID
Group By P.Sport,
	Case
		When Age < 25 then 'Under 25'
		When Age > 24 and Age < 35 then 'Between 25 and 34'
		When Age > 34 and Age < 45 then 'Between 35 and 44'
		When Age > 44 and Age < 55 then 'Between 45 and 54'
		Else 'Over 55'
	End
Order By P.Sport, QuantitySales Desc

--Clasificación de ticket promedio bajo, medio, alto--
select SaleID,ClientID,ProductID,SaleDate,Quantity,Channel,TotalPrice, SalesQualification = 
	case
		when TotalPrice < 90 then 'Low sale'
		when TotalPrice > 89 and TotalPrice < 180 then 'Average sale'
		when TotalPrice > 179 then 'High sale'
	end
from Sales

--Gasto promedio por compra por cliente--
Select S.ClientID, AverageCustomerPurchase = Avg(S.TotalPrice),C.Country
From Sales S
Left Join Clients C on S.ClientID = C.ClientID
group by S.ClientID,c.Country
Order By AverageCustomerPurchase Desc

--Top 10 clientes por facturación total--
Select Top 10 S.ClientID, TotalPurchaseCustomer = SUM(S.TotalPrice)
From Sales S
Left Join Clients C on S.ClientID = C.ClientID
group by S.ClientID
Order by TotalPurchaseCustomer Desc

--Cantidad de compras promedio por cliente por Pais (Historico)--
Select Country, AverageCustomerPurchase = AVG(PurchaseQuantity)
From(
	select c.ClientID, PurchaseQuantity = COUNT(*), c.Country
	From Sales S
	Join Clients C on C.ClientID = S.ClientID
	group by c.ClientID, c.Country) as ClientsCountry
group by Country
Order by Country

--Clientes nuevos por año--
CREATE VIEW NewClientsperYear AS
select Year(RegistrationDate)as Year, COUNT(*) as NewClients
from Clients
group by YEAR(RegistrationDate)

--Lealtad de clientes--
CREATE VIEW CustomerLoyalty AS
select s.clientID, COUNT(*) as TotalPurchases, MAX(s.SaleDate) as LastPurchase, DATEDIFF(DAY,min(s.SaleDate),GETDATE()) as  Antique,
Case	
	WHEN COUNT(*) > 1 THEN
		DATEDIFF(DAY,MIN(s.SaleDate),MAX(s.SaleDate)) / (COUNT(*) - 1)
	Else Null
End As AvgDaysBetweenPurchases
from Sales S
group by s.ClientID
--order by AvgDaysBetweenPurchases Desc

/* ============================
   MARCAS & PRODUCTOS
============================ */

--Top 10 modelos vendidos en 2025--
Select Top 10 P.ProductID, P.Brand, P.Model, P.Sport, P.LaunchYear, Models.UnitsSold
From Products P
Join (Select P.ProductID, P.Model, Sum(S.Quantity) as UnitsSold
From Products P
Join Sales S on P.ProductID = S.ProductID
Where Year(S.SaleDate) = 2025
group by P.ProductID, P.Model) as Models on P.ProductID = Models.ProductID
Order by UnitsSold Desc

--Ticket promedio por pais y deporte--
select C.Country, P.Sport, Count(*) as QuantitySold, AVG(S.TotalPrice) as AverageTicket
from Sales S
join Clients C on C.ClientID = S.ClientID
join Products P on P.ProductID = S.ProductID
group by C.Country, P.Sport
having count(*) > 100
order by C.Country, P.Sport

--Top marcas por facturación total--
Select YEAR(SaleDate) as Year, P.Brand, HistoricalBilling = Sum(S.TotalPrice)
From Sales S
Join Products P on S.ProductID = P.ProductID
group by P.Brand, YEAR(SaleDate)
Order BY Year, HistoricalBilling Desc

--Cantidad vendida por año por marca--
Select YEAR(SaleDate) as Year, P.Brand, QuantitySold = Sum(S.Quantity)
From Sales S
Join Products P on S.ProductID = P.ProductID
group by P.Brand, YEAR(SaleDate)
Order by YEAR, QuantitySold Desc

--Ticket promedio por marca y deporte--
Select P.Brand, P.Sport, TicketAverage = AVG(TotalPrice)
From Sales S
Join Products P on S.ProductID = P.ProductID
group by P.Brand, P.Sport
Order by P.Brand, P.Sport


/* ============================
   EVOLUCIÓN & MERCADO
============================ */

--Ranking de países por facturación total segun su canal de venta--
select C.Country, S.Channel, Sum(S.TotalPrice) as TotalSale
From Sales S
Join Clients C on C.ClientID = S.ClientID
group by C.Country, S.Channel
Order by TotalSale Desc, C.Country

--Tasa de crecimiento anual de facturación--
Select Year, TotalSales,Crecimiento = 
	Case 
		When Year = 2019 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
		When Year = 2020 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
		When Year = 2021 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
		When Year = 2022 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
		When Year = 2023 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
		When Year = 2024 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
		When Year = 2025 Then ROUND(-100*(1-(TotalSales/LAG(TotalSales, 1, TotalSales) OVER (ORDER BY Year))),2)
	End
from (Select YEAR(SaleDate) Year, Sum(TotalPrice) TotalSales
	From Sales
	group by YEAR(SaleDate)
	) Billing
Order by Year

--Porcentaje de ventas de zapatillas lanzadas ese año por deporte--
CREATE VIEW SalesReleasesSameYear AS
Select Sport, YearSale, TotalSales, SalesLaunches, PercentageOfSalesLaunched = Round(((SalesLaunches/TotalSales) * 100),2)
from 
	(select 
	Sport,Year(S.SaleDate) as YearSale,Sum(S.TotalPrice) as TotalSales, SalesLaunches = 
		case 
			when YEAR(S.SaleDate) = 2019 Then Sum(Case When P.LaunchYear = 2019 Then S.TotalPrice End)
			when YEAR(S.SaleDate) = 2020 Then Sum(Case When P.LaunchYear = 2020 Then S.TotalPrice End)
			when YEAR(S.SaleDate) = 2021 Then Sum(Case When P.LaunchYear = 2021 Then S.TotalPrice End)
			when YEAR(S.SaleDate) = 2022 Then Sum(Case When P.LaunchYear = 2022 Then S.TotalPrice End)
			when YEAR(S.SaleDate) = 2023 Then Sum(Case When P.LaunchYear = 2023 Then S.TotalPrice End)
			when YEAR(S.SaleDate) = 2024 Then Sum(Case When P.LaunchYear = 2024 Then S.TotalPrice End)
			when YEAR(S.SaleDate) = 2025 Then Sum(Case When P.LaunchYear = 2025 Then S.TotalPrice End)
			End
	from Sales S
	Join Products P on P.ProductID = S.ProductID
	group by Sport, Year(S.SaleDate)
	) as SalePerYear
--order by YearSale

--Evolución anual de ventas por canal (retail vs online)--
Select Year = YEAR(SaleDate), Channel, SalesQuantity = count(*)
From Sales 
Group by YEAR(SaleDate), Channel
Order by Year, SalesQuantity Desc

--Ventas acumuladas año a año (YTD)--
Select Year, YTD = 
	Case
		When Year = 2019 Then AnnualBilling 
		When Year = 2020 Then SUM(AnnualBilling) OVER (ORDER BY Year Asc ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
		When Year = 2021 Then SUM(AnnualBilling) OVER (ORDER BY Year Asc ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
		When Year = 2022 Then SUM(AnnualBilling) OVER (ORDER BY Year Asc ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)
		When Year = 2023 Then SUM(AnnualBilling) OVER (ORDER BY Year Asc ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)
		When Year = 2024 Then SUM(AnnualBilling) OVER (ORDER BY Year Asc ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)
		When Year = 2025 Then SUM(AnnualBilling) OVER (ORDER BY Year Asc ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
	End
From(
	Select Year = YEAR(SaleDate), AnnualBilling = 
		Case	
			When YEAR(SaleDate) = 2019 Then Sum(Case When YEAR(SaleDate) = 2019 Then TotalPrice End) 
			When YEAR(SaleDate) = 2020 Then Sum(Case When YEAR(SaleDate) = 2020 Then TotalPrice End) 
			When YEAR(SaleDate) = 2021 Then Sum(Case When YEAR(SaleDate) = 2021 Then TotalPrice End) 
			When YEAR(SaleDate) = 2022 Then Sum(Case When YEAR(SaleDate) = 2022 Then TotalPrice End) 
			When YEAR(SaleDate) = 2023 Then Sum(Case When YEAR(SaleDate) = 2023 Then TotalPrice End) 
			When YEAR(SaleDate) = 2024 Then Sum(Case When YEAR(SaleDate) = 2024 Then TotalPrice End) 
			When YEAR(SaleDate) = 2025 Then Sum(Case When YEAR(SaleDate) = 2025 Then TotalPrice End) 
		End
	From Sales 
	Group by YEAR(SaleDate)) AnnualBilling
Order By Year

--Participación de deportes sobre la facturación total en todos los años--
select SportBilling.Year, SportBilling.Sport, SportBilling.HistoricBilling, AnnualBillingPercentage = HistoricBilling/AnnualBilling
From(
	select Year = Year(S.SaleDate), P.Sport, HistoricBilling = Sum(S.TotalPrice)
	from Sales S
	Join Products P on S.ProductID = P.ProductID
	Group by Year(S.SaleDate), P.Sport) as SportBilling
Join (Select Year = YEAR(SaleDate), AnnualBilling = 
		Case	
			When YEAR(SaleDate) = 2019 Then Sum(Case When YEAR(SaleDate) = 2019 Then TotalPrice End) 
			When YEAR(SaleDate) = 2020 Then Sum(Case When YEAR(SaleDate) = 2020 Then TotalPrice End) 
			When YEAR(SaleDate) = 2021 Then Sum(Case When YEAR(SaleDate) = 2021 Then TotalPrice End) 
			When YEAR(SaleDate) = 2022 Then Sum(Case When YEAR(SaleDate) = 2022 Then TotalPrice End) 
			When YEAR(SaleDate) = 2023 Then Sum(Case When YEAR(SaleDate) = 2023 Then TotalPrice End) 
			When YEAR(SaleDate) = 2024 Then Sum(Case When YEAR(SaleDate) = 2024 Then TotalPrice End) 
			When YEAR(SaleDate) = 2025 Then Sum(Case When YEAR(SaleDate) = 2025 Then TotalPrice End) 
		End
	From Sales 
	Group by YEAR(SaleDate)) as Billing on Billing.Year = SportBilling.Year
order by SportBilling.Year
