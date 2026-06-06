insert into users (full_name, email, phone, password_hash, role)
values (
  'Administrateur ImmoAgence',
  'admin@example.com',
  '+221 00 000 00 00',
  'REMPLACER_PAR_UN_HASH_BCRYPT',
  'admin'
)
on conflict (email) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  password_hash = excluded.password_hash,
  role = excluded.role,
  is_blocked = false,
  updated_at = now();
