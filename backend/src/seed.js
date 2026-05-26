require('dotenv').config();

const { hashPassword } = require('./auth');
const { pool, query } = require('./db');

async function seed() {
  const passwordHash = await hashPassword('demo1234');

  const users = await query(
    `insert into users (full_name, email, phone, password_hash, role)
     values
       ('Aminata Diop', 'aminata.diop@example.com', '+221 77 123 45 67', $1, 'tenant'),
       ('Fatou Sarr', 'fatou.sarr@example.com', '+221 76 555 11 22', $1, 'owner'),
       ('Khady Ndiaye', 'admin@immoagence.sn', '+221 70 111 22 33', $1, 'admin')
     on conflict (email) do update set full_name = excluded.full_name
     returning id, email, role`,
    [passwordHash],
  );

  const tenant = users.rows.find((user) => user.role === 'tenant');
  const owner = users.rows.find((user) => user.role === 'owner');

  const properties = await query(
    `insert into properties
      (title, type, offer_type, status, price, location, description, features, rooms, bathrooms, surface_area, is_furnished, owner_id)
     values
      ('Appartement lumineux a Dakar Plateau', 'apartment', 'rent', 'available', 450000, 'Dakar Plateau', 'Appartement proche des services.', array['3 chambres','Salon','Cuisine equipee'], 3, 2, 118, true, $1),
      ('Maison familiale aux Almadies', 'house', 'sale', 'available', 85000000, 'Almadies', 'Maison spacieuse avec cour.', array['4 chambres','Cour','Parking'], 4, 3, 260, false, $1),
      ('Chambre en colocation a Ouakam', 'shared_room', 'colocation', 'available', 125000, 'Ouakam', 'Chambre meublee dans appartement partage.', array['Internet','Cuisine partagee','Eau incluse'], 1, 1, 18, true, $1)
     on conflict do nothing
     returning id, title, offer_type`,
    [owner.id],
  );

  const room = properties.rows.find((property) => property.offer_type === 'colocation');

  if (room) {
    await query(
      `insert into issue_reports (property_id, client_id, category, priority, status, description, agency_comment)
       values ($1, $2, 'plumbing', 'normal', 'in_progress', 'Fuite legere sous le lavabo.', 'Plombier programme demain matin.')
       on conflict do nothing`,
      [room.id, tenant.id],
    );
  }

  console.log('Seed termine. Comptes demo:');
  console.log('admin@immoagence.sn / demo1234');
  console.log('aminata.diop@example.com / demo1234');
}

seed()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
