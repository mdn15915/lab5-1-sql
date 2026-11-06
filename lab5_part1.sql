-- ============================================================
-- ЛАБОРАТОРНАЯ РАБОТА №5. ЧАСТЬ 1.
-- ============================================================

-- 1. Создание базы данных (CREATE DATABASE)
DROP DATABASE IF EXISTS bf;
CREATE DATABASE bf CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE bf;

-- 2. Создание таблиц и связей (CREATE TABLE)
-- Справочники
CREATE TABLE industries (
    industry_id VARCHAR(2) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    PRIMARY KEY (industry_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE criteria (
    criterion_id VARCHAR(2) NOT NULL,
    criterion_name VARCHAR(255) NOT NULL,
    PRIMARY KEY (criterion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sources (
    source_id VARCHAR(3) NOT NULL,
    source_name VARCHAR(255) NOT NULL,
    PRIMARY KEY (source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Основные таблицы
CREATE TABLE companies (
    company_id VARCHAR(8) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    legal_form VARCHAR(20) NOT NULL,
    foundation_year INT NOT NULL CHECK (foundation_year >= 1900 AND foundation_year <= 2026),
    employees_count INT NOT NULL CHECK (employees_count >= 0),
    industry_id VARCHAR(2),
    PRIMARY KEY (company_id),
    CONSTRAINT fk_company_industry FOREIGN KEY (industry_id) 
        REFERENCES industries(industry_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE financial_indicators (
    company_id VARCHAR(8) NOT NULL,
    report_year INT NOT NULL,
    revenue DECIMAL(15,2) NOT NULL CHECK (revenue >= 0),
    net_profit DECIMAL(15,2) NOT NULL,
    assets DECIMAL(15,2) NOT NULL CHECK (assets >= 0),
    ros DECIMAL(7,2) NOT NULL,
    roa DECIMAL(7,2) NOT NULL,
    PRIMARY KEY (company_id, report_year),
    CONSTRAINT fk_fin_company FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE digital_maturity (
    company_id VARCHAR(8) NOT NULL,
    report_year INT NOT NULL,
    criterion_id VARCHAR(2) NOT NULL,
    score INT NOT NULL CHECK (score BETWEEN 1 AND 3),
    PRIMARY KEY (company_id, report_year, criterion_id),
    CONSTRAINT fk_dm_company FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_dm_criterion FOREIGN KEY (criterion_id) 
        REFERENCES criteria(criterion_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE integral_indicator (
    company_id VARCHAR(8) NOT NULL,
    report_year INT NOT NULL,
    dmi DECIMAL(5,2) NOT NULL CHECK (dmi BETWEEN 0 AND 100),
    PRIMARY KEY (company_id, report_year),
    CONSTRAINT fk_dmi_company FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE data_sources (
    company_id VARCHAR(8) NOT NULL,
    report_year INT NOT NULL,
    source_id VARCHAR(3) NOT NULL,
    access_date DATE NOT NULL,
    PRIMARY KEY (company_id, report_year, source_id),
    CONSTRAINT fk_ds_company FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_ds_source FOREIGN KEY (source_id) 
        REFERENCES sources(source_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Изменение структуры таблиц (ALTER TABLE)
ALTER TABLE companies ADD COLUMN notes TEXT;
ALTER TABLE companies ADD COLUMN status VARCHAR(20) DEFAULT 'active';

-- 4. Вставка записей (INSERT INTO)
INSERT INTO industries (industry_id, industry_name) VALUES
('21', 'Производство лекарственных препаратов'),
('72', 'Научные исследования и разработки');

INSERT INTO criteria (criterion_id, criterion_name) VALUES
('K1', 'Интеграция данных'), ('K2', 'Автоматизация и контроль'),
('K3', 'Управление качеством'), ('K4', 'Цифровые инструменты в R&D'),
('K5', 'ИТ-инфраструктура'), ('K6', 'Цепочка поставок'), ('K7', 'Культура цифровизации');

INSERT INTO sources (source_id, source_name) VALUES
('S01', 'Rusprofile'), ('S02', 'Checko'), ('S03', 'Официальный сайт');

INSERT INTO companies (company_id, company_name, legal_form, foundation_year, employees_count, industry_id) VALUES
('00000001', 'Биокад', 'ПАО', 2001, 2500, '21'),
('00000002', 'Р-Фарм', 'АО', 2001, 3000, '21'),
('00000003', 'Артген биотех', 'ООО', 2010, 150, '72');

INSERT INTO financial_indicators (company_id, report_year, revenue, net_profit, assets, ros, roa) VALUES
('00000001', 2023, 45000.00, 12000.00, 60000.00, 26.67, 20.00),
('00000002', 2023, 75000.00, 8000.00, 90000.00, 10.67, 8.89),
('00000003', 2023, 5000.00, -500.00, 10000.00, -10.00, -5.00);

INSERT INTO digital_maturity (company_id, report_year, criterion_id, score) VALUES
('00000001', 2023, 'K1', 3), ('00000001', 2023, 'K2', 3), ('00000001', 2023, 'K3', 3),
('00000002', 2023, 'K1', 2), ('00000002', 2023, 'K2', 2), ('00000002', 2023, 'K3', 2),
('00000003', 2023, 'K1', 1), ('00000003', 2023, 'K2', 1), ('00000003', 2023, 'K3', 1);

INSERT INTO integral_indicator (company_id, report_year, dmi) VALUES
('00000001', 2023, 90.48),
('00000002', 2023, 62.50),
('00000003', 2023, 33.33);

INSERT INTO data_sources (company_id, report_year, source_id, access_date) VALUES
('00000001', 2023, 'S01', '2024-03-01'),
('00000002', 2023, 'S02', '2024-03-02');

-- 5. Обновление записей (UPDATE)
UPDATE companies SET notes = 'Лидер рынка', status = 'active' WHERE company_id = '00000001';
UPDATE companies SET status = 'startup' WHERE company_id = '00000003';

-- 6. Удаление записей (DELETE FROM)
DELETE FROM data_sources WHERE company_id = '00000003';
INSERT INTO data_sources (company_id, report_year, source_id, access_date) VALUES ('00000003', 2023, 'S03', '2024-03-03');

-- 7. Создание пользователей и наделение их правами (CREATE USER, GRANT)
CREATE USER IF NOT EXISTS 'analyst_user'@'localhost' IDENTIFIED BY 'analyst_pass';
GRANT SELECT, INSERT, UPDATE ON bf.* TO 'analyst_user'@'localhost';

CREATE USER IF NOT EXISTS 'manager_user'@'localhost' IDENTIFIED BY 'manager_pass';
GRANT SELECT, UPDATE ON bf.* TO 'manager_user'@'localhost';

CREATE USER IF NOT EXISTS 'investor_user'@'localhost' IDENTIFIED BY 'investor_pass';
GRANT SELECT ON bf.* TO 'investor_user'@'localhost';

CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'admin_pass';
GRANT ALL PRIVILEGES ON bf.* TO 'admin_user'@'localhost';

FLUSH PRIVILEGES;

-- 8. Выгрузка метаданных (DESCRIBE)
DESCRIBE industries;
DESCRIBE criteria;
DESCRIBE sources;
DESCRIBE companies;
DESCRIBE financial_indicators;
DESCRIBE digital_maturity;
DESCRIBE integral_indicator;
DESCRIBE data_sources;
