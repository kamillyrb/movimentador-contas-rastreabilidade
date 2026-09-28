-- 01_setup_database.sql
-- Movimentador de Contas e Rastreabilidade
-- Criação dos schemas e tabelas principais.

-- Execute a criação do banco conectado ao banco padrão (postgres), se necessário:
-- CREATE DATABASE movimentador_contas;

-- Depois conecte no banco movimentador_contas e execute o restante.

CREATE SCHEMA IF NOT EXISTS workflow;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS workflow.setores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ATIVO'
        CHECK (status IN ('ATIVO', 'INATIVO'))
);

CREATE TABLE IF NOT EXISTS workflow.usuarios (
    id SERIAL PRIMARY KEY,
    login VARCHAR(80) NOT NULL UNIQUE,
    nome_completo VARCHAR(150) NOT NULL,
    setor_id INTEGER NOT NULL REFERENCES workflow.setores(id),
    credencial_hash TEXT NOT NULL,
    perfil VARCHAR(30) NOT NULL
        CHECK (perfil IN ('OPERACIONAL', 'GESTAO', 'ADMIN'))
);

CREATE TABLE IF NOT EXISTS workflow.contas_workflow (
    id SERIAL PRIMARY KEY,
    codigo_conta VARCHAR(50) NOT NULL UNIQUE,
    convenio VARCHAR(100) NOT NULL,
    valor_aproximado NUMERIC(12,2) NOT NULL CHECK (valor_aproximado >= 0),
    setor_atual_id INTEGER NOT NULL REFERENCES workflow.setores(id),
    data_entrada TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workflow.movimentacoes (
    id SERIAL PRIMARY KEY,
    conta_id INTEGER NOT NULL REFERENCES workflow.contas_workflow(id),
    setor_origem_id INTEGER NOT NULL REFERENCES workflow.setores(id),
    setor_destino_id INTEGER NOT NULL REFERENCES workflow.setores(id),
    usuario_id INTEGER NOT NULL REFERENCES workflow.usuarios(id),
    data_movimentacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT
);

CREATE TABLE IF NOT EXISTS workflow.comentarios (
    id SERIAL PRIMARY KEY,
    conta_id INTEGER NOT NULL REFERENCES workflow.contas_workflow(id),
    usuario_id INTEGER NOT NULL REFERENCES workflow.usuarios(id),
    data_comentario TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descricao TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_movimentacoes_conta
    ON workflow.movimentacoes(conta_id);

CREATE INDEX IF NOT EXISTS idx_comentarios_conta
    ON workflow.comentarios(conta_id);

CREATE INDEX IF NOT EXISTS idx_contas_setor
    ON workflow.contas_workflow(setor_atual_id);
