-- ============================================================================
-- fn_criar_agendamento — criação ATÔMICA do agendamento.
-- Fecha a janela de corrida (overbooking) com:
--   pg_advisory_xact_lock(profissional|data|unidade)  -> serializa só o mesmo
--   profissional/dia/unidade (o resto segue concorrente); auto-libera no commit.
--   + re-check de SOBREPOSIÇÃO (OVERLAPS) na MESMA transação, sob o lock.
-- Chamada exclusivamente pelo backend via service role.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_criar_agendamento(
  p_unidade_id   uuid,
  p_data         date,
  p_hora         varchar,
  p_profissional varchar,
  p_servico      varchar,
  p_duracao      int,
  p_valor        numeric,
  p_cliente      varchar,
  p_telefone     varchar,
  p_email        varchar,
  p_obs          text
) RETURNS public.agendamentos
LANGUAGE plpgsql
AS $$
DECLARE
  v_row public.agendamentos;
BEGIN
  -- serializa apenas o mesmo profissional/dia/unidade
  PERFORM pg_advisory_xact_lock(
    hashtext(p_profissional || '|' || p_data::text || '|' || COALESCE(p_unidade_id::text, ''))
  );

  -- re-check de sobreposição sob o lock (status que ocupam o slot)
  IF EXISTS (
    SELECT 1
    FROM public.agendamentos a
    WHERE a.data_agendamento = p_data
      AND a.profissional = p_profissional
      AND (p_unidade_id IS NULL OR a.unidade_id = p_unidade_id)
      AND a.status NOT IN ('Cancelado', 'Cliente não compareceu')
      AND a.hora IS NOT NULL AND a.hora <> ''
      AND (p_hora::time, p_hora::time + make_interval(mins => COALESCE(p_duracao, 0)))
          OVERLAPS
          (a.hora::time, a.hora::time + make_interval(mins => COALESCE(a.duracao_minutos, 0)))
  ) THEN
    -- distinto da unique constraint pela MENSAGEM 'SLOT_TAKEN' (ambos são 23505)
    RAISE EXCEPTION 'SLOT_TAKEN' USING ERRCODE = '23505';
  END IF;

  INSERT INTO public.agendamentos (
    data_agendamento, hora, profissional, servico, duracao_minutos, valor,
    cliente, telefone, email, observacoes, status, unidade_id, source_occurrence
  ) VALUES (
    p_data, p_hora, p_profissional, p_servico, p_duracao, p_valor,
    p_cliente, p_telefone, p_email, COALESCE(p_obs, ''), 'Agendado', p_unidade_id, 1
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

-- somente o backend (service role) executa
REVOKE ALL ON FUNCTION public.fn_criar_agendamento(uuid,date,varchar,varchar,varchar,int,numeric,varchar,varchar,varchar,text) FROM anon, authenticated, public;
GRANT EXECUTE ON FUNCTION public.fn_criar_agendamento(uuid,date,varchar,varchar,varchar,int,numeric,varchar,varchar,varchar,text) TO service_role;
