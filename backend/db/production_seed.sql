insert into users (full_name, email, phone, password_hash, role)
values (
  'Administrateur ImmoAgence',
  'admin@immoagence.sn',
  '+221 70 000 00 00',
  '$2b$12$0XRLHMCYlab/vWCt2co01.79NpbyjONEP4zTAU2neJzV7wKGGqLQW',
  'admin'
)
on conflict (email) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  password_hash = excluded.password_hash,
  role = excluded.role,
  is_blocked = false,
  updated_at = now();
