-- The live vacancy table had a nullable status column despite its pending default.
-- No current vacancy rows were present; require an explicit moderation state.
alter table public.job_vacancies alter column status set not null;
