# Movimentador de Contas e Rastreabilidade

## 1. Identificação

**Projeto:** Movimentador de Contas e Rastreabilidade  
**Instituição:** Hospital Universitário  
**Disciplina:** Administração de Banco de Dados (DBA)  
**SGBD:** PostgreSQL 16  

**Integrante:**
- KAMILLY RIBEIRO DE OLIVEIRA

---

## 2. Objetivo

O projeto simula uma base de dados própria para controlar o trânsito de contas dentro do hospital.

A ideia principal é registrar em qual setor a conta está, as movimentações realizadas e os comentários relacionados ao processo. Também foram aplicadas regras de acesso e uma trilha de auditoria para identificar alterações realizadas no banco.

---

## 3. Estrutura do projeto

```text
README.md
scripts/
├── 01_setup_database.sql
├── 02_seed_data.sql
├── 03_security_rbac.sql
├── 04_audit_setup.sql
├── 05_attack_simulation.sql
└── 06_forensic_queries.sql
```

---

## 4. Arquitetura

Foram utilizados dois schemas:

- `workflow`: contém as tabelas relacionadas ao funcionamento do sistema.
- `audit`: contém a tabela responsável pela trilha de auditoria.

A separação foi feita para deixar os dados de negócio separados dos registros de auditoria. Como este trabalho foi desenvolvido individualmente, a implementação e os testes foram realizados por um único responsável.

### Tabelas do workflow

- `setores`
- `usuarios`
- `contas_workflow`
- `movimentacoes`
- `comentarios`

A modelagem utiliza chaves primárias e estrangeiras para manter os relacionamentos entre as tabelas.

---

## 5. Controle de acesso

Foram criadas três roles funcionais:

### role_operacional

Pode consultar dados necessários para o trabalho operacional e inserir movimentações e comentários.

Não possui permissão para apagar ou alterar o histórico.

### role_gestao

Possui acesso somente à view `workflow.vw_gestao_sla`, utilizada para consultas gerenciais.

### role_admin_workflow

Possui controle administrativo sobre as tabelas e sequences do schema `workflow`.

Também foi removido o acesso padrão da role `PUBLIC`.

---

## 6. Usuários de teste

Foram criados:

| Usuário | Role |
|---|---|
| usr_auditor_op | role_operacional |
| usr_coordenador_gestao | role_gestao |
| usr_dba_admin | role_admin_workflow |

Senhas utilizadas somente no ambiente de teste:

- `usr_auditor_op` → `SenhaOp@2026`
- `usr_coordenador_gestao` → `SenhaGestao@2026`
- `usr_dba_admin` → `SenhaAdmin@2026`

---

## 7. Proteção de dados

O acesso à tabela `workflow.usuarios` foi limitado para o perfil operacional.

O operador consegue consultar dados necessários para o fluxo, mas não consegue consultar a coluna `credencial_hash`.

Também foi criada a view `workflow.vw_gestao_sla`, que apresenta informações consolidadas para gestão sem expor dados pessoais desnecessários.

---

## 8. Auditoria

A tabela `audit.logged_actions` registra:

- schema;
- tabela;
- usuário da sessão;
- data e hora;
- operação realizada;
- estado anterior;
- estado posterior.

Foram criados triggers nas tabelas `contas_workflow` e `movimentacoes`.

As operações `INSERT`, `UPDATE` e `DELETE` são registradas automaticamente.

---

## 9. Como executar

### Passo 1 - Criar o banco

No PostgreSQL, conectado ao banco `postgres`:

```sql
CREATE DATABASE movimentador_contas;
```

Depois conecte no banco `movimentador_contas`.

### Passo 2 - Executar os scripts

Execute nesta ordem:

```text
01_setup_database.sql
02_seed_data.sql
03_security_rbac.sql
04_audit_setup.sql
05_attack_simulation.sql
06_forensic_queries.sql
```

A ordem é importante porque os scripts seguintes dependem das tabelas, dados, roles e triggers criados anteriormente.

---

## 10. Testes de segurança

### Cenário A - Adulteração de histórico

Conectado como `usr_auditor_op`:

```sql
DELETE FROM workflow.movimentacoes WHERE id = 1;
```

Resultado esperado:

```text
ERROR: permission denied for table movimentacoes
```

Também foi testado:

```sql
UPDATE workflow.movimentacoes
SET observacoes = 'Tentativa de alteração'
WHERE id = 1;
```

Resultado esperado:

```text
ERROR: permission denied for table movimentacoes
```

Isso demonstra que o usuário operacional não possui permissão para apagar ou alterar o histórico.

---

### Cenário B - Coluna restrita

Conectado como `usr_auditor_op`:

```sql
SELECT credencial_hash FROM workflow.usuarios;
```

Resultado esperado:

```text
ERROR: permission denied for table usuarios
```

O usuário operacional possui acesso somente às colunas liberadas.

---

### Cenário C - Operação válida

Conectado como `usr_auditor_op`:

```sql
INSERT INTO workflow.movimentacoes
    (conta_id, setor_origem_id, setor_destino_id, usuario_id, observacoes)
VALUES
    (1, 1, 2, 1, 'Transferência operacional de teste');
```

Essa operação deve ser permitida.

Também pode ser inserido um comentário:

```sql
INSERT INTO workflow.comentarios
    (conta_id, usuario_id, descricao)
VALUES
    (1, 1, 'Movimentação realizada durante teste de segurança');
```

---

## 11. Análise forense

Depois dos testes, a consulta abaixo mostra os registros criados pela auditoria:

```sql
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
```

Com isso é possível identificar o usuário que realizou uma operação, a data e hora, a tabela afetada e os dados antes e depois da alteração.

---

## 12. Evidências

Os prints da execução dos testes devem ser adicionados nesta seção.

### Evidência 1 - Bloqueio de DELETE

Cole aqui o print mostrando a mensagem de `permission denied`.

### Evidência 2 - Bloqueio de UPDATE

Cole aqui o print mostrando a mensagem de `permission denied`.

### Evidência 3 - Bloqueio da coluna restrita

Cole aqui o print mostrando a tentativa de acesso ao `credencial_hash`.

### Evidência 4 - Operação válida

Cole aqui o print mostrando o `INSERT` de uma movimentação realizado com sucesso.

### Evidência 5 - Auditoria

Cole aqui o print da consulta:

```sql
SELECT * FROM audit.logged_actions ORDER BY action_tstamp;
```

---

## 13. Conclusão

O banco foi estruturado separando os dados do sistema e os registros de auditoria. Também foram aplicadas regras de menor privilégio para evitar que usuários operacionais tenham acesso a operações administrativas ou dados restritos.

Os testes mostram a diferença entre uma operação que o usuário pode realizar e operações que devem ser bloqueadas. A trilha de auditoria permite consultar posteriormente quem realizou as alterações, quando elas ocorreram e quais dados foram modificados.
