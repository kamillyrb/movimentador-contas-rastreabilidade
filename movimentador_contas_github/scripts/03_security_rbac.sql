-- 03_security_rbac.sql
-- RBAC, menor privilégio e proteção de dados.

REVOKE ALL ON SCHEMA workflow FROM PUBLIC;
REVOKE ALL ON SCHEMA audit FROM PUBLIC;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_operacional') THEN
        CREATE ROLE role_operacional NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_gestao') THEN
        CREATE ROLE role_gestao NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_admin_workflow') THEN
        CREATE ROLE role_admin_workflow NOLOGIN;
    END IF;
END $$;

GRANT USAGE ON SCHEMA workflow TO role_operacional;
GRANT USAGE ON SCHEMA workflow TO role_gestao;
GRANT USAGE ON SCHEMA workflow TO role_admin_workflow;

-- Operacional: consulta dados de fluxo e pode registrar movimentações/comentários.
GRANT SELECT ON workflow.setores TO role_operacional;
GRANT SELECT ON workflow.contas_workflow TO role_operacional;
GRANT SELECT (id, login, nome_completo, setor_id, perfil)
    ON workflow.usuarios TO role_operacional;
GRANT SELECT ON workflow.movimentacoes TO role_operacional;
GRANT INSERT ON workflow.movimentacoes TO role_operacional;
GRANT SELECT ON workflow.comentarios TO role_operacional;
GRANT INSERT ON workflow.comentarios TO role_operacional;

-- Permissões de sequences necessárias para INSERT.
GRANT USAGE, SELECT ON SEQUENCE workflow.movimentacoes_id_seq TO role_operacional;
GRANT USAGE, SELECT ON SEQUENCE workflow.comentarios_id_seq TO role_operacional;

-- Gestão: acesso somente à view segura.
CREATE OR REPLACE VIEW workflow.vw_gestao_sla AS
SELECT
    s.nome AS setor,
    COUNT(DISTINCT c.id) AS total_contas,
    COUNT(m.id) AS total_movimentacoes
FROM workflow.setores s
LEFT JOIN workflow.contas_workflow c
    ON c.setor_atual_id = s.id
LEFT JOIN workflow.movimentacoes m
    ON m.setor_destino_id = s.id
GROUP BY s.id, s.nome;

GRANT SELECT ON workflow.vw_gestao_sla TO role_gestao;

-- Administrador do workflow.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA workflow TO role_admin_workflow;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA workflow TO role_admin_workflow;

-- Usuários de teste.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_auditor_op') THEN
        CREATE ROLE usr_auditor_op LOGIN PASSWORD 'SenhaOp@2026';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_coordenador_gestao') THEN
        CREATE ROLE usr_coordenador_gestao LOGIN PASSWORD 'SenhaGestao@2026';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_dba_admin') THEN
        CREATE ROLE usr_dba_admin LOGIN PASSWORD 'SenhaAdmin@2026';
    END IF;
END $$;

GRANT role_operacional TO usr_auditor_op;
GRANT role_gestao TO usr_coordenador_gestao;
GRANT role_admin_workflow TO usr_dba_admin;

-- Garantia de menor privilégio.
REVOKE ALL ON workflow.usuarios FROM role_gestao;
REVOKE ALL ON workflow.usuarios FROM role_operacional;
GRANT SELECT (id, login, nome_completo, setor_id, perfil)
    ON workflow.usuarios TO role_operacional;
