-- 02_seed_data.sql
-- Carga inicial de teste.

INSERT INTO workflow.setores (nome, status) VALUES
('Auditoria', 'ATIVO'),
('Central de Guias', 'ATIVO'),
('Faturamento', 'ATIVO'),
('Recurso de Glosa', 'ATIVO')
ON CONFLICT (nome) DO NOTHING;

INSERT INTO workflow.usuarios
    (login, nome_completo, setor_id, credencial_hash, perfil)
SELECT 'usr_auditor_op', 'Ana Oliveira',
       id, '$2a$12$hash_teste_auditor', 'OPERACIONAL'
FROM workflow.setores WHERE nome = 'Auditoria'
ON CONFLICT (login) DO NOTHING;

INSERT INTO workflow.usuarios
    (login, nome_completo, setor_id, credencial_hash, perfil)
SELECT 'usr_coordenador_gestao', 'Carlos Mendes',
       id, '$2a$12$hash_teste_gestao', 'GESTAO'
FROM workflow.setores WHERE nome = 'Faturamento'
ON CONFLICT (login) DO NOTHING;

INSERT INTO workflow.usuarios
    (login, nome_completo, setor_id, credencial_hash, perfil)
SELECT 'usr_dba_admin', 'Marina Souza',
       id, '$2a$12$hash_teste_admin', 'ADMIN'
FROM workflow.setores WHERE nome = 'Auditoria'
ON CONFLICT (login) DO NOTHING;

INSERT INTO workflow.usuarios
    (login, nome_completo, setor_id, credencial_hash, perfil)
SELECT 'usr_operador_2', 'Joao Silva',
       id, '$2a$12$hash_teste_operador', 'OPERACIONAL'
FROM workflow.setores WHERE nome = 'Central de Guias'
ON CONFLICT (login) DO NOTHING;

INSERT INTO workflow.contas_workflow
    (codigo_conta, convenio, valor_aproximado, setor_atual_id)
SELECT 'CTA-0001', 'Convenio A', 1250.50, id
FROM workflow.setores WHERE nome = 'Auditoria'
ON CONFLICT (codigo_conta) DO NOTHING;

INSERT INTO workflow.contas_workflow
    (codigo_conta, convenio, valor_aproximado, setor_atual_id)
SELECT 'CTA-0002', 'Convenio B', 2380.00, id
FROM workflow.setores WHERE nome = 'Central de Guias'
ON CONFLICT (codigo_conta) DO NOTHING;

INSERT INTO workflow.contas_workflow
    (codigo_conta, convenio, valor_aproximado, setor_atual_id)
SELECT 'CTA-0003', 'Convenio C', 890.75, id
FROM workflow.setores WHERE nome = 'Faturamento'
ON CONFLICT (codigo_conta) DO NOTHING;

INSERT INTO workflow.movimentacoes
    (conta_id, setor_origem_id, setor_destino_id, usuario_id, observacoes)
SELECT c.id, so.id, sd.id, u.id, 'Conta encaminhada para conferência de guia'
FROM workflow.contas_workflow c
JOIN workflow.setores so ON so.nome = 'Auditoria'
JOIN workflow.setores sd ON sd.nome = 'Central de Guias'
JOIN workflow.usuarios u ON u.login = 'usr_auditor_op'
WHERE c.codigo_conta = 'CTA-0001'
  AND NOT EXISTS (
      SELECT 1 FROM workflow.movimentacoes m WHERE m.conta_id = c.id
  );

INSERT INTO workflow.movimentacoes
    (conta_id, setor_origem_id, setor_destino_id, usuario_id, observacoes)
SELECT c.id, so.id, sd.id, u.id, 'Conta encaminhada para faturamento'
FROM workflow.contas_workflow c
JOIN workflow.setores so ON so.nome = 'Central de Guias'
JOIN workflow.setores sd ON sd.nome = 'Faturamento'
JOIN workflow.usuarios u ON u.login = 'usr_operador_2'
WHERE c.codigo_conta = 'CTA-0002'
  AND NOT EXISTS (
      SELECT 1 FROM workflow.movimentacoes m WHERE m.conta_id = c.id
  );

INSERT INTO workflow.movimentacoes
    (conta_id, setor_origem_id, setor_destino_id, usuario_id, observacoes)
SELECT c.id, so.id, sd.id, u.id, 'Conta encaminhada para análise de glosa'
FROM workflow.contas_workflow c
JOIN workflow.setores so ON so.nome = 'Faturamento'
JOIN workflow.setores sd ON sd.nome = 'Recurso de Glosa'
JOIN workflow.usuarios u ON u.login = 'usr_coordenador_gestao'
WHERE c.codigo_conta = 'CTA-0003'
  AND NOT EXISTS (
      SELECT 1 FROM workflow.movimentacoes m WHERE m.conta_id = c.id
  );

INSERT INTO workflow.comentarios (conta_id, usuario_id, descricao)
SELECT c.id, u.id, 'Aguardando guia'
FROM workflow.contas_workflow c
JOIN workflow.usuarios u ON u.login = 'usr_auditor_op'
WHERE c.codigo_conta = 'CTA-0001'
  AND NOT EXISTS (
      SELECT 1 FROM workflow.comentarios cm
      WHERE cm.conta_id = c.id AND cm.descricao = 'Aguardando guia'
  );

INSERT INTO workflow.comentarios (conta_id, usuario_id, descricao)
SELECT c.id, u.id, 'Erro de MAT/MED em conferência'
FROM workflow.contas_workflow c
JOIN workflow.usuarios u ON u.login = 'usr_operador_2'
WHERE c.codigo_conta = 'CTA-0002'
  AND NOT EXISTS (
      SELECT 1 FROM workflow.comentarios cm
      WHERE cm.conta_id = c.id AND cm.descricao = 'Erro de MAT/MED em conferência'
  );

INSERT INTO workflow.comentarios (conta_id, usuario_id, descricao)
SELECT c.id, u.id, 'Conta aguardando análise'
FROM workflow.contas_workflow c
JOIN workflow.usuarios u ON u.login = 'usr_coordenador_gestao'
WHERE c.codigo_conta = 'CTA-0003'
  AND NOT EXISTS (
      SELECT 1 FROM workflow.comentarios cm
      WHERE cm.conta_id = c.id AND cm.descricao = 'Conta aguardando análise'
  );
