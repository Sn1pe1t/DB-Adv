USE Front;
GO

DECLARE @StartDate DATE = '2015-01-01';
DECLARE @EndDate   DATE = '2035-12-01';

;WITH MonthSeries AS (
    SELECT @StartDate AS m_start
    UNION ALL
    SELECT DATEADD(MONTH, 1, m_start)
    FROM MonthSeries
    WHERE m_start < @EndDate
)
MERGE olap_analytics.ref_calendar_months AS target
USING (
    SELECT
        CAST(YEAR(m_start) AS BIGINT) * 100 + MONTH(m_start) AS period_code,
        m_start                                              AS date_start,
        EOMONTH(m_start)                                     AS date_end,
        CHOOSE(MONTH(m_start),
            N'Январь', N'Февраль', N'Март', N'Апрель', N'Май', N'Июнь',
            N'Июль', N'Август', N'Сентябрь', N'Октябрь', N'Ноябрь', N'Декабрь'
        )                                                    AS month_name,
        YEAR(m_start)                                        AS [year],
        DATEPART(QUARTER, m_start)                           AS quarter_num,
        CAST(DATEPART(QUARTER, m_start) AS NVARCHAR(10)) + N' квартал' AS quarter_name
    FROM MonthSeries
) AS src
ON target.period_code = src.period_code
WHEN NOT MATCHED THEN
    INSERT (period_code, date_start, date_end, month_name, [year], quarter_num, quarter_name)
    VALUES (src.period_code, src.date_start, src.date_end, src.month_name, src.[year], src.quarter_num, src.quarter_name)
OPTION (MAXRECURSION 1000);
GO

-- Проверка результата по требуемым колонкам ТЗ
SELECT
    period_key   AS [Код],
    date_start   AS [Дата начала месяца],
    date_end     AS [Дата окончания месяца],
    month_name   AS [Название месяца],
    [year]       AS [Год],
    quarter_num  AS [Номер квартала],
    quarter_name AS [Название квартала]
FROM olap_analytics.ref_calendar_months
ORDER BY period_code;
GO