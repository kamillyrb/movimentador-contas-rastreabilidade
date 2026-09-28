-- 06_forensic_queries.sql
-- Consultas para análise forense da trilha de auditoria.

-- 1. Todas as ações auditadas.
SELECT
    id,
    schema_name,
    table_name,
    session_user_name,
    action_tstamp,
    action,
    old_data,
    new_data
FROM audit.logged_actions
ORDER BY action_tstamp;

-- 2. Quem realizou cada alteração.
SELECT
    id,
    table_name,
    session_user_name AS usuario,
    action,
    action_tstamp AS data_hora
FROM audit.logged_actions
ORDER BY action_tstamp;

-- 3. Alterações realizadas na tabela de movimentações.
SELECT
    id,
    session_user_name AS usuario,
    action,
    action_tstamp,
    old_data,
    new_data
FROM audit.logged_actions
WHERE table_name = 'movimentacoes'
ORDER BY action_tstamp;

-- 4. Alterações realizadas nas contas.
SELECT
    id,
    session_user_name AS usuario,
    action,
    action_tstamp,
    old_data,
    new_data
FROM audit.logged_actions
WHERE table_name = 'contas_workflow'
ORDER BY action_tstamp;

-- 5. Resumo por usuário.
SELECT
    session_user_name AS usuario,
    COUNT(*) AS quantidade_acoes
FROM audit.logged_actions
GROUP BY session_user_name
ORDER BY quantidade_acoes DESC;

-- 6. Resumo por tipo de operação.
SELECT
    action,
    COUNT(*) AS quantidade
FROM audit.logged_actions
GROUP BY action
ORDER BY action;
