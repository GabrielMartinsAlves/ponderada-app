-- ============================================================================
-- Lumma Agendamentos — schema do banco de dados.
-- Tabelas, índices, constraints, RLS por role e views de catálogo.
-- Rodar no projeto Supabase do app.
-- ============================================================================

-- 1) UNIDADES
CREATE TABLE IF NOT EXISTS public.unidades (
  id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(100) NOT NULL UNIQUE
);

-- 2) AGENDAMENTOS
CREATE TABLE IF NOT EXISTS public.agendamentos (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data_agendamento       DATE NOT NULL,
  hora                   VARCHAR(10),
  profissional           VARCHAR(150),
  servico                VARCHAR(200),
  duracao_minutos        INTEGER,
  cliente                VARCHAR(200),
  telefone               VARCHAR(30),
  email                  VARCHAR(254),
  valor                  DECIMAL(10,2),
  status                 VARCHAR(50),
  observacoes            TEXT,
  row_hash               TEXT,
  source_occurrence      INTEGER NOT NULL DEFAULT 1,
  categoria_atendimento  TEXT    NOT NULL DEFAULT 'normal',
  unidade_id             UUID REFERENCES public.unidades(id),
  created_at             TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_agend_data        ON public.agendamentos (data_agendamento);
CREATE INDEX IF NOT EXISTS idx_agend_unid_data   ON public.agendamentos (unidade_id, data_agendamento);
CREATE INDEX IF NOT EXISTS idx_agend_status_data ON public.agendamentos (status, data_agendamento);
CREATE INDEX IF NOT EXISTS idx_agend_unid_st_dt  ON public.agendamentos (unidade_id, status, data_agendamento);
CREATE INDEX IF NOT EXISTS idx_agend_categoria   ON public.agendamentos (categoria_atendimento);
CREATE INDEX IF NOT EXISTS idx_agend_row_hash    ON public.agendamentos (row_hash);
CREATE INDEX IF NOT EXISTS idx_agend_email       ON public.agendamentos (email);
CREATE INDEX IF NOT EXISTS idx_agend_telefone    ON public.agendamentos (telefone);

-- Unique constraint de deduplicação de registros
ALTER TABLE public.agendamentos DROP CONSTRAINT IF EXISTS agendamentos_unique_business_slot;
ALTER TABLE public.agendamentos ADD CONSTRAINT agendamentos_unique_business_slot
  UNIQUE NULLS NOT DISTINCT (unidade_id, data_agendamento, hora, profissional, cliente, servico, source_occurrence);

-- 3) FOLLOWUPS
CREATE TABLE IF NOT EXISTS public.followups (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  telefone   VARCHAR(30) NOT NULL UNIQUE,
  cliente    VARCHAR(200),
  anotacao   TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4) RLS por role (admin/comercial) + view comercial
CREATE OR REPLACE FUNCTION public.jwt_role() RETURNS text LANGUAGE sql STABLE AS $$
  SELECT COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', '');
$$;

ALTER TABLE public.agendamentos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS agendamentos_admin_all ON public.agendamentos;
CREATE POLICY agendamentos_admin_all ON public.agendamentos FOR ALL TO authenticated
  USING (public.jwt_role() = 'admin') WITH CHECK (public.jwt_role() = 'admin');

CREATE OR REPLACE VIEW public.agendamentos_comercial AS
  SELECT id, data_agendamento, hora, profissional, servico, duracao_minutos,
         cliente, telefone, email, status, observacoes, categoria_atendimento, unidade_id
  FROM public.agendamentos;
REVOKE ALL ON public.agendamentos_comercial FROM anon, public;
GRANT SELECT ON public.agendamentos_comercial TO authenticated;

ALTER TABLE public.unidades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS unidades_select_roles ON public.unidades;
CREATE POLICY unidades_select_roles ON public.unidades FOR SELECT TO authenticated
  USING (public.jwt_role() IN ('admin','comercial'));
DROP POLICY IF EXISTS unidades_admin_write ON public.unidades;
CREATE POLICY unidades_admin_write ON public.unidades FOR ALL TO authenticated
  USING (public.jwt_role() = 'admin') WITH CHECK (public.jwt_role() = 'admin');

ALTER TABLE public.followups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS followups_roles_all ON public.followups;
CREATE POLICY followups_roles_all ON public.followups FOR ALL TO authenticated
  USING (public.jwt_role() IN ('admin','comercial')) WITH CHECK (public.jwt_role() IN ('admin','comercial'));

-- anon (sem login) não lê nada
REVOKE ALL ON public.agendamentos FROM anon;
REVOKE ALL ON public.unidades     FROM anon;
REVOKE ALL ON public.followups    FROM anon;

-- service_role (backend) — leitura/escrita completas; grants explícitos
GRANT ALL    ON public.agendamentos           TO service_role;
GRANT ALL    ON public.unidades               TO service_role;
GRANT ALL    ON public.followups              TO service_role;
GRANT SELECT ON public.agendamentos_comercial TO service_role;

-- 5) VIEWS de catálogo a partir de agendamentos
CREATE OR REPLACE VIEW public.booking_servicos AS
  SELECT servico,
         mode() WITHIN GROUP (ORDER BY duracao_minutos)        AS duracao_minutos,
         percentile_disc(0.5) WITHIN GROUP (ORDER BY valor)    AS valor,
         count(*)                                              AS total
  FROM public.agendamentos
  WHERE servico IS NOT NULL AND servico <> ''
  GROUP BY servico;

CREATE OR REPLACE VIEW public.booking_profissionais AS
  SELECT DISTINCT profissional, unidade_id, servico
  FROM public.agendamentos
  WHERE profissional IS NOT NULL AND profissional <> '';

REVOKE ALL ON public.booking_servicos      FROM anon, public;
REVOKE ALL ON public.booking_profissionais FROM anon, public;
GRANT SELECT ON public.booking_servicos      TO service_role;
GRANT SELECT ON public.booking_profissionais TO service_role;
