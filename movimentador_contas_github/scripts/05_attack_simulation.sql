-- 05_attack_simulation.sql
-- Testes de segurança.
-- Execute cada bloco conectado como o usuário indicado.

-- ==========================================================
-- CENÁRIO A - tentativa de adulterar histórico
-- Conectado como usr_auditor_op:
-- ==========================================================

-- Deve retornar "permission denied":
-- DELETE FROM workflow.movimentacoes WHERE id = 1;

-- Deve retornar "permission denied":
-- UPDATE workflow.movimentacoes
-- SET observacoes = 'Tentativa de alteração'
-- WHERE id = 1;


-- ==========================================================
-- CENÁRIO B - tentativa de acessar credencial restrita
-- Conectado como usr_auditor_op:
-- ==========================================================

-- Deve retornar "permission denied":
-- SELECT credencial_hash FROM workflow.usuarios;


-- ==========================================================
-- CENÁRIO C - operação operacional válida
-- Conectado como usr_auditor_op:
-- ==========================================================

-- Descobrir uma conta:
-- SELECT id, codigo_conta FROM workflow.contas_workflow;

-- Descobrir os setores:
-- SELECT id, nome FROM workflow.setores;

-- Registrar uma movimentação:
-- INSERT INTO workflow.movimentacoes
--     (conta_id, setor_origem_id, setor_destino_id, usuario_id, observacoes)
-- VALUES
--     (1, 1, 2, 1, 'Transferência operacional de teste');

-- Registrar comentário:
-- INSERT INTO workflow.comentarios
--     (conta_id, usuario_id, descricao)
-- VALUES
--     (1, 1, 'Movimentação realizada durante teste de segurança');

-- As operações acima devem funcionar.
-- A movimentação deve aparecer na tabela audit.logged_actions.
