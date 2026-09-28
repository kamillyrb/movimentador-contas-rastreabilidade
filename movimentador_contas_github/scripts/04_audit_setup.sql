-- 04_audit_setup.sql
-- Trilha de auditoria para contas e movimentações.

CREATE TABLE IF NOT EXISTS audit.logged_actions (
    id BIGSERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    session_user_name TEXT NOT NULL,
    action_tstamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action CHAR(1) NOT NULL CHECK (action IN ('I','U','D')),
    old_data JSONB,
    new_data JSONB
);

CREATE OR REPLACE FUNCTION audit.fn_log_workflow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = audit, pg_catalog
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit.logged_actions
            (schema_name, table_name, session_user_name, action, old_data, new_data)
        VALUES
            (TG_TABLE_SCHEMA, TG_TABLE_NAME, session_user, 'I',
             NULL, to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit.logged_actions
            (schema_name, table_name, session_user_name, action, old_data, new_data)
        VALUES
            (TG_TABLE_SCHEMA, TG_TABLE_NAME, session_user, 'U',
             to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit.logged_actions
            (schema_name, table_name, session_user_name, action, old_data, new_data)
        VALUES
            (TG_TABLE_SCHEMA, TG_TABLE_NAME, session_user, 'D',
             to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_contas ON workflow.contas_workflow;
CREATE TRIGGER trg_audit_contas
AFTER INSERT OR UPDATE OR DELETE ON workflow.contas_workflow
FOR EACH ROW EXECUTE FUNCTION audit.fn_log_workflow();

DROP TRIGGER IF EXISTS trg_audit_movimentacoes ON workflow.movimentacoes;
CREATE TRIGGER trg_audit_movimentacoes
AFTER INSERT OR UPDATE OR DELETE ON workflow.movimentacoes
FOR EACH ROW EXECUTE FUNCTION audit.fn_log_workflow();

REVOKE ALL ON SCHEMA audit FROM PUBLIC;
REVOKE ALL ON audit.logged_actions FROM PUBLIC;

GRANT USAGE ON SCHEMA audit TO role_admin_workflow;
GRANT SELECT ON audit.logged_actions TO role_admin_workflow;
