-- ============================================================
-- ЛАБОРАТОРНАЯ РАБОТА №5. ЧАСТЬ 2. ЗАПРОСЫ
-- ============================================================

-- 1. Неявное соединение с WHERE и ORDER BY
-- Выручка компаний за 2023 год больше 10 000, сортировка по убыванию
SELECT c.company_name, f.revenue 
FROM companies c, financial_indicators f
WHERE c.company_id = f.company_id 
  AND f.report_year = 2023 
  AND f.revenue > 10000
ORDER BY f.revenue DESC;

-- 2. Явное соединение (JOIN)
-- Компании и их отрасли
SELECT c.company_name, c.legal_form, i.industry_name
FROM companies c
JOIN industries i ON c.industry_id = i.industry_id
ORDER BY c.company_name;

-- 3. Агрегирующие операции
-- Сводные показатели по всем компаниям за 2023 год
SELECT 
    SUM(revenue) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue,
    COUNT(company_id) AS companies_count,
    MAX(revenue) AS max_revenue,
    MIN(revenue) AS min_revenue
FROM financial_indicators
WHERE report_year = 2023;

-- 4. GROUP BY и HAVING
-- Отрасли, где средняя выручка компаний > 20 000
SELECT i.industry_name, ROUND(AVG(f.revenue), 2) AS avg_revenue
FROM industries i
JOIN companies c ON i.industry_id = c.industry_id
JOIN financial_indicators f ON c.company_id = f.company_id
WHERE f.report_year = 2023
GROUP BY i.industry_name
HAVING AVG(f.revenue) > 20000;

-- 5. Вложенные подзапросы (с IN)
-- Компании, у которых DMI выше среднего по всем компаниям за 2023 год
SELECT c.company_name, ii.dmi
FROM companies c
JOIN integral_indicator ii ON c.company_id = ii.company_id
WHERE ii.report_year = 2023
  AND ii.dmi > (
      SELECT AVG(dmi)
      FROM integral_indicator
      WHERE report_year = 2023
  );

-- Компании, которые имеют хотя бы одну оценку по критерию 'K1'
SELECT company_name
FROM companies
WHERE company_id IN (
    SELECT company_id
    FROM digital_maturity
    WHERE criterion_id = 'K1'
);

-- 6. Вложенный подзапрос с ALL
-- Компании, у которых выручка больше, чем у ВСЕХ компаний из отрасли 72
SELECT c.company_name, f.revenue
FROM companies c
JOIN financial_indicators f ON c.company_id = f.company_id
WHERE f.report_year = 2023
  AND f.revenue > ALL (
      SELECT f2.revenue
      FROM financial_indicators f2
      JOIN companies c2 ON f2.company_id = c2.company_id
      WHERE c2.industry_id = '72' AND f2.report_year = 2023
  );

-- 7. Функции управления потоком: IF и CASE
-- Вывести компанию и признак: "прибыльная" или "убыточная"
SELECT
    c.company_name,
    f.net_profit,
    IF(f.net_profit > 0, 'Прибыльная', 'Убыточная') AS profit_status
FROM companies c
JOIN financial_indicators f ON c.company_id = f.company_id
WHERE f.report_year = 2023;

-- Категория компании по уровню DMI
SELECT
    c.company_name,
    ii.dmi,
    CASE
        WHEN ii.dmi >= 80 THEN 'Высокая зрелость'
        WHEN ii.dmi >= 50 THEN 'Средняя зрелость'
        ELSE 'Низкая зрелость'
    END AS maturity_level
FROM companies c
JOIN integral_indicator ii ON c.company_id = ii.company_id
WHERE ii.report_year = 2023
ORDER BY ii.dmi DESC;

-- 8. Создание представления (CREATE VIEW)
-- Представление: сводный отчёт по компаниям (финансы + DMI + отрасль)
CREATE OR REPLACE VIEW v_company_summary AS
SELECT
    c.company_id,
    c.company_name,
    i.industry_name,
    f.revenue,
    f.net_profit,
    f.ros,
    f.roa,
    ii.dmi
FROM companies c
LEFT JOIN industries i ON c.industry_id = i.industry_id
LEFT JOIN financial_indicators f ON c.company_id = f.company_id AND f.report_year = 2023
LEFT JOIN integral_indicator ii ON c.company_id = ii.company_id AND ii.report_year = 2023;

-- Использование представления
SELECT * FROM v_company_summary ORDER BY dmi DESC;

-- 9. Временное представление — оператор WITH (CTE)
-- С помощью WITH: компании с DMI выше среднего
WITH avg_dmi AS (
    SELECT AVG(dmi) AS avg_value
    FROM integral_indicator
    WHERE report_year = 2023
)
SELECT c.company_name, ii.dmi, a.avg_value
FROM companies c
JOIN integral_indicator ii ON c.company_id = ii.company_id
CROSS JOIN avg_dmi a
WHERE ii.report_year = 2023
  AND ii.dmi > a.avg_value;

-- 10. Анализ и оптимизация (EXPLAIN + CREATE INDEX)
EXPLAIN
SELECT c.company_name, f.revenue
FROM companies c
JOIN financial_indicators f ON c.company_id = f.company_id
WHERE f.report_year = 2023 AND f.revenue > 10000;

-- Индекс по году отчёта (часто используется в WHERE)
CREATE INDEX idx_fin_year ON financial_indicators(report_year);

-- Индекс по отрасли (для JOIN с industries)
CREATE INDEX idx_companies_industry ON companies(industry_id);

EXPLAIN
SELECT c.company_name, f.revenue
FROM companies c
JOIN financial_indicators f ON c.company_id = f.company_id
WHERE f.report_year = 2023 AND f.revenue > 10000;

-- 11. Транзакция (START TRANSACTION)
-- Пример: вставка новой компании и её финансовых показателей атомарно
START TRANSACTION;

INSERT INTO companies (company_id, company_name, legal_form, foundation_year, employees_count, industry_id)
VALUES ('00000099', 'Тестовая фарм', 'ООО', 2020, 100, '21');

INSERT INTO financial_indicators (company_id, report_year, revenue, net_profit, assets, ros, roa)
VALUES ('00000099', 2023, 10000.00, 1000.00, 5000.00, 10.00, 20.00);

-- Если всё прошло без ошибок — фиксируем:
COMMIT;

-- Если была ошибка — откатываем:
-- ROLLBACK;

-- Проверка результата
SELECT * FROM companies WHERE company_id = '00000099';

START TRANSACTION;
UPDATE companies SET status = 'test' WHERE company_id = '00000001';
ROLLBACK; -- изменения отменяются
SELECT status FROM companies WHERE company_id = '00000001'; -- всё ещё 'active'

-- 12. Динамический SQL: PREPARE, EXECUTE, DEALLOCATE
-- Подготовка запроса с параметром (год отчёта)
PREPARE stmt FROM
  'SELECT c.company_name, f.revenue
   FROM companies c
   JOIN financial_indicators f ON c.company_id = f.company_id
   WHERE f.report_year = ? AND f.revenue > ?';

-- Установка параметров (2023 и 10000)
SET @year = 2023;
SET @min_revenue = 10000;

-- Выполнение
EXECUTE stmt USING @year, @min_revenue;

-- Освобождение ресурсов
DEALLOCATE PREPARE stmt;
