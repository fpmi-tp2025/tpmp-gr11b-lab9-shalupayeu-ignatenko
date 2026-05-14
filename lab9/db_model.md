# 4.3 Физическая модель БД (SQLite)

## users
- id PK
- login TEXT
- password TEXT

## accounts
- id PK
- user_id FK
- name TEXT
- balance REAL
- type TEXT
- is_active INTEGER
- is_blocked INTEGER
- is_closed INTEGER

## card_accounts
- account_id PK/FK
- card_type TEXT
- overdraft_limit REAL

## branches
- id PK
- name TEXT
- latitude REAL
- longitude REAL
- address TEXT

## currency_rates
- id PK
- currency TEXT
- value REAL
- updated_at DATETIME
