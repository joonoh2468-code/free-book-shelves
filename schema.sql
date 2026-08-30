-- ============================================================
-- Free Book Shelf Network — Supabase schema
-- Run this once in Supabase: SQL Editor → New Query → paste → Run
-- ============================================================

-- ---------- TABLES ----------

create table if not exists shelves (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location_notes text,
  created_at timestamptz not null default now()
);

create table if not exists books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text,
  isbn text,
  category text,        -- e.g. Board Book, Picture Book, Early Reader, Chapter Book, Middle Grade
  age_range text,        -- e.g. 0-2, 3-5, 6-8, 9-11
  shelf_id uuid references shelves(id) on delete set null,
  status text not null default 'available' check (status in ('available', 'taken')),
  added_at timestamptz not null default now(),
  taken_at timestamptz
);

create index if not exists idx_books_shelf on books(shelf_id);
create index if not exists idx_books_status on books(status);

-- ---------- ROW LEVEL SECURITY ----------

alter table shelves enable row level security;
alter table books enable row level security;

-- Anyone (including anonymous visitors) can see shelf names/locations —
-- needed so the checkout page can show which shelf you're at.
drop policy if exists "Public can view shelves" on shelves;
create policy "Public can view shelves"
  on shelves for select
  to anon
  using (true);

-- Anonymous visitors can only see AVAILABLE books — this is what powers
-- the "is this book still here?" search and the shelf checkout list.
drop policy if exists "Anyone can view available books" on books;
create policy "Anyone can view available books"
  on books for select
  to anon
  using (status = 'available');

-- Logged-in staff can see every book, including ones already taken
-- (useful for the add-book page and future reporting).
drop policy if exists "Staff can view all books" on books;
create policy "Staff can view all books"
  on books for select
  to authenticated
  using (true);

-- Only logged-in staff can create/edit shelves or books directly.
-- Anonymous visitors never get insert/update/delete access — the only
-- thing they can change is a book's status, and only through the
-- narrow mark_book_taken() function below.
drop policy if exists "Staff can insert shelves" on shelves;
create policy "Staff can insert shelves"
  on shelves for insert
  to authenticated
  with check (true);

drop policy if exists "Staff can update shelves" on shelves;
create policy "Staff can update shelves"
  on shelves for update
  to authenticated
  using (true) with check (true);

drop policy if exists "Staff can insert books" on books;
create policy "Staff can insert books"
  on books for insert
  to authenticated
  with check (true);

drop policy if exists "Staff can update books" on books;
create policy "Staff can update books"
  on books for update
  to authenticated
  using (true) with check (true);

drop policy if exists "Staff can delete books" on books;
create policy "Staff can delete books"
  on books for delete
  to authenticated
  using (true);

-- ---------- CHECKOUT FUNCTION ----------
-- Public visitors call this (via supabase.rpc) instead of ever touching
-- the books table directly. It only ever flips one row from
-- 'available' to 'taken', and only if it's still available — so two
-- people tapping the same book at once can't both "win", and nobody
-- can use this path to edit a title or author.

create or replace function mark_book_taken(book_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_row books%rowtype;
begin
  update books
  set status = 'taken', taken_at = now()
  where id = book_id and status = 'available'
  returning * into updated_row;

  if not found then
    return json_build_object(
      'success', false,
      'message', 'Someone may have just taken this one — please pick another.'
    );
  end if;

  return json_build_object('success', true, 'book', row_to_json(updated_row));
end;
$$;

grant execute on function mark_book_taken(uuid) to anon, authenticated;
