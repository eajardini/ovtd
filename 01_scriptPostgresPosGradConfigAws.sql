-- Rodar esses script para configura a AWS.
-- Ele deve ser executado pelo professor após executar o script 01_scriptPostgresPosGrad.sql
-- Caso não for usar a AWS, desconsiderar esse script.


-- ============================================================
-- Banco: ovtd1_dw
-- Criação dos usuários aluno01 até aluno20
-- Cada aluno possui seu próprio schema
-- ============================================================

\c ovtd1_dw postgres


-- ------------------------------------------------------------
-- Impede que usuários comuns criem objetos no schema public
-- ------------------------------------------------------------

REVOKE CREATE ON SCHEMA public FROM PUBLIC;


-- ------------------------------------------------------------
-- Criação dos usuários e schemas
-- ------------------------------------------------------------

DO $$
DECLARE
    i        INTEGER;
    usuario  TEXT;
    senha    TEXT;
BEGIN

    FOR i IN 1..20 LOOP

        usuario := 'aluno' || LPAD(i::TEXT, 2, '0');

        -- Exemplo:
        -- aluno01 -> Aluno01@2026
        -- aluno02 -> Aluno02@2026
        senha := 'postdba';


        -- Cria o usuário caso ainda não exista
        IF NOT EXISTS (
            SELECT 1
            FROM pg_roles
            WHERE rolname = usuario
        ) THEN

            EXECUTE format(
                'CREATE ROLE %I
                 LOGIN
                 PASSWORD %L
                 NOSUPERUSER
                 NOCREATEDB
                 NOCREATEROLE
                 NOREPLICATION',
                usuario,
                senha
            );

        END IF;


        -- Permissão para conectar no banco
        EXECUTE format(
            'GRANT CONNECT ON DATABASE ovtd1_dw TO %I',
            usuario
        );


        -- Cria um schema exclusivo para o aluno
        EXECUTE format(
            'CREATE SCHEMA IF NOT EXISTS %I AUTHORIZATION %I',
            usuario,
            usuario
        );


        -- Garante que o usuário tenha controle sobre seu schema
        EXECUTE format(
            'GRANT USAGE, CREATE ON SCHEMA %I TO %I',
            usuario,
            usuario
        );


        -- Ao conectar ao banco, procura primeiro no schema
        -- correspondente ao próprio usuário
        EXECUTE format(
            'ALTER ROLE %I IN DATABASE ovtd1_dw
             SET search_path TO %I, public',
            usuario,
            usuario
        );

    END LOOP;

END
$$;
