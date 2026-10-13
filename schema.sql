
-- شفرة الكنز: مخطط قاعدة بيانات Supabase (نسخة أولية)
-- نفّذ هذا الملف في Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.contest_settings (
  id integer primary key default 1 check (id = 1),
  title text not null default 'شفرة الكنز',
  intro text not null default 'حلوا الألغاز واتبعوا التلميحات للوصول إلى الكنز.',
  is_open boolean not null default false,
  updated_at timestamptz not null default now()
);
insert into public.contest_settings (id)
values (1)
on conflict (id) do nothing;

create table if not exists public.stages (
  id uuid primary key default gen_random_uuid(),
  stage_order integer not null unique check (stage_order > 0),
  title text not null,
  question text not null,
  hint text not null default '',
  paper_location text not null default '',
  scrambled_words text not null default '',
  success_message text not null default '',
  treasure_location text not null default '',
  created_at timestamptz not null default now()
);

-- معلومات سرية لا تُعرض على واجهة المشاركين.
create table if not exists public.stage_secrets (
  stage_id uuid primary key
    references public.stages(id) on delete cascade,
  answer_key text not null default '',
  correct_phrase text not null default ''
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  team_name text not null unique,
  current_stage integer not null default 1,
  status text not null default 'registered'
    check (status in (
      'registered',
      'playing',
      'waiting_approval',
      'approved',
      'finished'
    )),
  hint_revealed text,
  treasure_revealed text,
  created_at timestamptz not null default now(),
  last_seen timestamptz,
  finished_at timestamptz
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null
    references public.teams(id) on delete cascade,
  stage_order integer not null,
  answer_text text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index if not exists submissions_team_created_idx
  on public.submissions(team_id, created_at desc);

alter table public.contest_settings enable row level security;
alter table public.stages enable row level security;
alter table public.stage_secrets enable row level security;
alter table public.teams enable row level security;
alter table public.submissions enable row level security;

-- إعدادات المسابقة
drop policy if exists "public can read contest settings"
  on public.contest_settings;
create policy "public can read contest settings"
  on public.contest_settings
  for select to anon, authenticated
  using (true);

drop policy if exists "admins manage contest settings"
  on public.contest_settings;
create policy "admins manage contest settings"
  on public.contest_settings
  for all to authenticated
  using (true) with check (true);

-- المراحل
drop policy if exists "public can read stages" on public.stages;
create policy "public can read stages"
  on public.stages
  for select to anon, authenticated
  using (true);

drop policy if exists "admins manage stages" on public.stages;
create policy "admins manage stages"
  on public.stages
  for all to authenticated
  using (true) with check (true);

-- أسرار المراحل
drop policy if exists "admins manage stage secrets"
  on public.stage_secrets;
create policy "admins manage stage secrets"
  on public.stage_secrets
  for all to authenticated
  using (true) with check (true);

-- سياسات تجريبية فقط لتسهيل اختبار النسخة الأولية.
-- لا تعتبر هذه الصلاحيات آمنة للنشر العام.
drop policy if exists "public can register and read teams"
  on public.teams;
create policy "public can register and read teams"
  on public.teams
  for select to anon, authenticated
  using (true);

drop policy if exists "public can register teams" on public.teams;
create policy "public can register teams"
  on public.teams
  for insert to anon, authenticated
  with check (true);

drop policy if exists "public can update teams" on public.teams;
create policy "public can update teams"
  on public.teams
  for update to anon, authenticated
  using (true) with check (true);

drop policy if exists "public can submit answers"
  on public.submissions;
create policy "public can submit answers"
  on public.submissions
  for insert to anon, authenticated
  with check (true);

drop policy if exists "public can read submissions"
  on public.submissions;
create policy "public can read submissions"
  on public.submissions
  for select to anon, authenticated
  using (true);

drop policy if exists "admins can update submissions"
  on public.submissions;
create policy "admins can update submissions"
  on public.submissions
  for update to authenticated
  using (true) with check (true);

drop policy if exists "admins can delete submissions"
  on public.submissions;
create policy "admins can delete submissions"
  on public.submissions
  for delete to authenticated
  using (true);

-- تنبيه:
-- هذه نسخة أولية وتحتاج تقوية صلاحيات teams و submissions
-- قبل نشر رابط المسابقة للمشاركين.
