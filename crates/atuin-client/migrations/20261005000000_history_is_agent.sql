-- Whether an agent ran the command, mirroring `History::is_agent`. Interactive search filters on
-- it every keystroke, and most history can be agent-run, so the partial indexes below let it skip
-- the other side instead of evaluating this expression per row. The kind values and agent names
-- are frozen here: adding an `AuthorKind` variant or a `KNOWN_AGENTS` name needs a migration that
-- recreates this column.
alter table history add column is_agent integer not null generated always as (
	case
		when author_kind in (1, 2) then author_kind = 2
		when author is null or trim(author) = '' then 0
		else author in ('claude-code', 'codex', 'copilot', 'opencode', 'pi')
			and author <> case
				when instr(hostname, ':') = 0 then hostname
				when substr(hostname, instr(hostname, ':') + 1) = 'unknown-user'
					then substr(hostname, 1, instr(hostname, ':') - 1)
				else substr(hostname, instr(hostname, ':') + 1)
			end
	end
) virtual;

create index if not exists idx_history_user_timestamp on history(timestamp)
where deleted_at is null and is_agent = 0;

create index if not exists idx_history_agent_timestamp on history(timestamp)
where deleted_at is null and is_agent = 1;
