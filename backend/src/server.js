require('dotenv').config();

const cors = require('cors');
const express = require('express');
const fs = require('fs/promises');
const path = require('path');

const { query } = require('./db');
const {
  hashPassword,
  normalizeRole,
  requireAuth,
  signToken,
  verifyPassword,
} = require('./auth');
const {
  canDeleteAdminResource,
  canReadAdminResource,
  canRequestClientAction,
  canWriteAdminResource,
} = require('./permissions');
const {
  confirmCheckoutInvoice,
  createCheckoutInvoice,
} = require('./paydunya');

const app = express();
const port = process.env.PORT || 4000;
const uploadDir = path.join(__dirname, '..', 'uploads');
const publicRegisterRoles = new Set(['visitor', 'tenant']);
const adminCreatableRoles = new Set(['visitor', 'tenant', 'owner', 'admin', 'agent']);
const paymentPurposes = new Set(['reservation', 'deposit', 'rent', 'sale_advance', 'full_purchase']);

app.use(
  cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  }),
);
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(uploadDir));

app.get('/health', async (_req, res) => {
  const result = await query('select now() as now');
  res.json({ status: 'ok', databaseTime: result.rows[0].now });
});

app.post('/auth/register', async (req, res) => {
  const { fullName, email, phone, password, role } = req.body;
  const requestedRole = normalizeRole(role);

  if (!fullName || !email || !password || password.length < 6) {
    return res.status(400).json({
      message: 'Nom, email et mot de passe de 6 caracteres minimum requis.',
    });
  }

  if (!publicRegisterRoles.has(requestedRole)) {
    return res.status(403).json({
      message: 'Ce profil doit etre cree ou valide par l agence.',
    });
  }

  const passwordHash = await hashPassword(password);
  const result = await query(
    `insert into users (full_name, email, phone, password_hash, role)
     values ($1, lower($2), $3, $4, $5)
     returning id, full_name, email, phone, role, is_blocked, created_at`,
    [fullName, email, phone || null, passwordHash, requestedRole],
  );

  const user = result.rows[0];
  res.status(201).json({ user, token: signToken(user) });
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email et mot de passe requis.' });
  }

  const result = await query(
    'select * from users where email = lower($1)',
    [email],
  );

  if (result.rowCount === 0) {
    return res.status(401).json({ message: 'Identifiants invalides.' });
  }

  const user = result.rows[0];
  if (user.is_blocked) {
    return res.status(403).json({ message: 'Ce compte est bloque par l agence.' });
  }

  const validPassword = await verifyPassword(password, user.password_hash);

  if (!validPassword) {
    return res.status(401).json({ message: 'Identifiants invalides.' });
  }

  delete user.password_hash;
  res.json({ user, token: signToken(user) });
});

app.get('/auth/me', requireAuth, (req, res) => {
  res.json({ user: req.user });
});

app.get('/properties', async (_req, res) => {
  const result = await query('select * from properties order by created_at desc');
  res.json({ data: result.rows });
});

app.get('/dashboard', requireAuth, async (req, res) => {
  const role = req.user.role;
  const userId = req.user.id;
  const agency = isAgencyUser(req.user);

  const propertyFilter = agency
    ? ''
    : role === 'owner'
      ? 'where owner_id = $1'
      : role === 'tenant'
        ? 'where tenant_id = $1'
        : '';
  const propertyValues = propertyFilter ? [userId] : [];

  const [properties, visits, contracts, payments, receipts, issues, messages, events] =
    await Promise.all([
      query(`select * from properties ${propertyFilter} order by created_at desc`, propertyValues),
      query(
        `select visits.*, properties.title as property_title
         from visits
         join properties on properties.id = visits.property_id
         where visits.client_id = $1 or $2::boolean
         order by visits.scheduled_at desc`,
        [userId, agency],
      ),
      query(
        `select contracts.*, properties.title as property_title
         from contracts
         join properties on properties.id = contracts.property_id
         where contracts.client_id = $1 or $2::boolean
         order by contracts.created_at desc`,
        [userId, agency],
      ),
      query(
        `select payments.*, properties.title as property_title
         from payments
         join properties on properties.id = payments.property_id
         where payments.client_id = $1 or $2::boolean
         order by payments.created_at desc`,
        [userId, agency],
      ),
      query(
        `select receipts.*, properties.title as property_title
         from receipts
         join properties on properties.id = receipts.property_id
         where receipts.client_id = $1 or $2::boolean
         order by receipts.created_at desc`,
        [userId, agency],
      ),
      query(
        `select issue_reports.*, properties.title as property_title
         from issue_reports
         join properties on properties.id = issue_reports.property_id
         where issue_reports.client_id = $1 or $2::boolean
         order by issue_reports.created_at desc`,
        [userId, agency],
      ),
      query(
        `select messages.*, sender.full_name as sender_name, recipient.full_name as recipient_name
         from messages
         left join users sender on sender.id = messages.sender_id
         left join users recipient on recipient.id = messages.recipient_id
         where messages.sender_id = $1 or messages.recipient_id = $1 or $2::boolean
         order by messages.created_at desc`,
        [userId, agency],
      ),
      query(
        `select calendar_events.*, properties.title as property_title
         from calendar_events
         left join properties on properties.id = calendar_events.property_id
         where calendar_events.client_id = $1 or calendar_events.agent_id = $1 or $2::boolean
         order by calendar_events.starts_at asc`,
        [userId, agency],
      ),
    ]);

  return res.json({
    data: {
      properties: properties.rows,
      visits: visits.rows,
      contracts: contracts.rows,
      payments: payments.rows,
      receipts: receipts.rows,
      issues: issues.rows,
      messages: messages.rows,
      calendarEvents: events.rows,
    },
  });
});

app.post('/auth/fcm-token', requireAuth, async (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({ message: 'Token FCM requis.' });
  }

  const result = await query(
    `update users set fcm_token = $1, updated_at = now()
     where id = $2
     returning id, full_name, email, phone, role, is_blocked, created_at, updated_at`,
    [token, req.user.id],
  );

  return res.json({ user: result.rows[0] });
});

function requireClientAction(req, res, next) {
  if (!canRequestClientAction(req.user?.role)) {
    return res.status(403).json({ message: 'Action reservee aux comptes valides par l agence.' });
  }
  return next();
}

function requireAdminRead(req, res, next) {
  if (!canReadAdminResource(req.user?.role, req.params.resource)) {
    return res.status(403).json({ message: 'Acces non autorise pour cette ressource.' });
  }
  return next();
}

function requireAdminWrite(req, res, next) {
  if (!canWriteAdminResource(req.user?.role, req.params.resource)) {
    return res.status(403).json({ message: 'Modification non autorisee pour cette ressource.' });
  }
  return next();
}

function requireAdminDelete(req, res, next) {
  if (!canDeleteAdminResource(req.user?.role, req.params.resource)) {
    return res.status(403).json({ message: 'Suppression non autorisee pour cette ressource.' });
  }
  return next();
}

function requireAdminOnly(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ message: 'Action reservee aux administrateurs.' });
  }
  return next();
}

function isAgencyUser(user) {
  return user?.role === 'admin' || user?.role === 'agent';
}

async function createReceiptForPayment(payment) {
  if (payment.status !== 'successful') return null;

  const reference = `REC-${payment.reference}`;
  const result = await query(
    `insert into receipts (reference, payment_id, client_id, property_id, amount, label)
     values ($1, $2, $3, $4, $5, $6)
     on conflict (reference) do update
       set amount = excluded.amount, updated_at = now()
     returning *`,
    [
      reference,
      payment.id,
      payment.client_id,
      payment.property_id,
      payment.amount,
      `Recu officiel ${payment.purpose}`,
    ],
  );

  return result.rows[0];
}

async function auditAdminAction(req, action, resource, resourceId, details = {}) {
  if (!isAgencyUser(req.user)) return;
  await query(
    `insert into admin_audit_logs (actor_id, action, resource, resource_id, details)
     values ($1, $2, $3, $4, $5)`,
    [req.user.id, action, resource, resourceId || null, details],
  );
}

async function syncSuccessfulPayment(token, confirmation) {
  const status = normalizePayDunyaStatus(confirmation.status);
  const paymentId = confirmation.customData.payment_id;

  const result = await query(
    `update payments
     set status = $1, receipt_url = $2, updated_at = now()
     where provider_token = $3 and ($4::uuid is null or id = $4::uuid)
     returning *`,
    [status, confirmation.receiptUrl || null, token, paymentId || null],
  );

  if (result.rowCount === 0) {
    return { payment: null, receipt: null };
  }

  const payment = result.rows[0];
  const receipt = await createReceiptForPayment(payment);
  return { payment, receipt };
}

app.post('/visits', requireAuth, requireClientAction, async (req, res) => {
  const { propertyId, scheduledAt, message } = req.body;

  if (!propertyId || !scheduledAt) {
    return res.status(400).json({ message: 'Bien et creneau requis.' });
  }

  const result = await query(
    `insert into visits (property_id, client_id, scheduled_at, status, message)
     values ($1, $2, $3, 'pending', $4)
     returning *`,
    [propertyId, req.user.id, scheduledAt, message || null],
  );

  return res.status(201).json({ data: result.rows[0] });
});

app.get('/visits', requireAuth, async (req, res) => {
  const result = await query(
    `select visits.*, properties.title as property_title
     from visits
     join properties on properties.id = visits.property_id
     where visits.client_id = $1 or $2 in ('admin', 'agent')
     order by visits.scheduled_at desc`,
    [req.user.id, req.user.role],
  );

  return res.json({ data: result.rows });
});

app.get('/calendar/events', requireAuth, async (req, res) => {
  const agency = isAgencyUser(req.user);
  const result = await query(
    `select calendar_events.*, properties.title as property_title
     from calendar_events
     left join properties on properties.id = calendar_events.property_id
     where calendar_events.client_id = $1 or calendar_events.agent_id = $1 or $2::boolean
     order by calendar_events.starts_at asc`,
    [req.user.id, agency],
  );

  return res.json({ data: result.rows });
});

app.post('/messages', requireAuth, requireClientAction, async (req, res) => {
  const { recipientId, propertyId, subject, body } = req.body;

  if (!subject || !body || body.length < 2) {
    return res.status(400).json({ message: 'Sujet et message requis.' });
  }

  const result = await query(
    `insert into messages (sender_id, recipient_id, property_id, subject, body)
     values ($1, $2, $3, $4, $5)
     returning *`,
    [req.user.id, recipientId || null, propertyId || null, subject, body],
  );

  return res.status(201).json({ data: result.rows[0] });
});

app.get('/messages', requireAuth, async (req, res) => {
  const agency = isAgencyUser(req.user);
  const result = await query(
    `select messages.*, sender.full_name as sender_name, recipient.full_name as recipient_name
     from messages
     left join users sender on sender.id = messages.sender_id
     left join users recipient on recipient.id = messages.recipient_id
     where messages.sender_id = $1 or messages.recipient_id = $1 or $2::boolean
     order by messages.created_at desc`,
    [req.user.id, agency],
  );

  return res.json({ data: result.rows });
});

app.post('/contracts/request', requireAuth, requireClientAction, async (req, res) => {
  const { propertyId, type, amount, terms, startDate, endDate } = req.body;

  if (!propertyId || !type || !amount) {
    return res.status(400).json({ message: 'Bien, type et montant requis.' });
  }

  const reference = `CTR-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  const result = await query(
    `insert into contracts (reference, type, status, property_id, client_id, start_date, end_date, amount, terms)
     values ($1, $2, 'pending_signature', $3, $4, $5, $6, $7, $8)
     returning *`,
    [
      reference,
      type,
      propertyId,
      req.user.id,
      startDate || new Date().toISOString().slice(0, 10),
      endDate || null,
      amount,
      terms || [],
    ],
  );

  return res.status(201).json({ data: result.rows[0] });
});

app.post('/contracts/:id/sign', requireAuth, requireClientAction, async (req, res) => {
  const { signatureText, signerName } = req.body;

  if (!signatureText || signatureText.trim().length < 3) {
    return res.status(400).json({ message: 'Signature numerique requise.' });
  }

  const contractResult = await query('select * from contracts where id = $1', [req.params.id]);

  if (contractResult.rowCount === 0) {
    return res.status(404).json({ message: 'Contrat introuvable.' });
  }

  const contract = contractResult.rows[0];
  if (!isAgencyUser(req.user) && contract.client_id !== req.user.id) {
    return res.status(403).json({ message: 'Signature non autorisee pour ce contrat.' });
  }

  await query(
    `insert into contract_signatures (contract_id, signer_id, signer_name, signature_text, ip_address)
     values ($1, $2, $3, $4, $5)`,
    [
      contract.id,
      req.user.id,
      signerName || req.user.full_name,
      signatureText.trim(),
      req.ip,
    ],
  );

  const result = await query(
    `update contracts
     set status = 'signed', signed_at = now(), signature_name = $1, signature_ip = $2, updated_at = now()
     where id = $3
     returning *`,
    [signerName || req.user.full_name, req.ip, contract.id],
  );

  return res.json({ data: result.rows[0] });
});

app.get('/contracts', requireAuth, async (req, res) => {
  const result = await query(
    `select contracts.*, properties.title as property_title
     from contracts
     join properties on properties.id = contracts.property_id
     where contracts.client_id = $1 or $2 in ('admin', 'agent')
     order by contracts.created_at desc`,
    [req.user.id, req.user.role],
  );

  return res.json({ data: result.rows });
});

app.post('/tenant/issues', requireAuth, requireClientAction, async (req, res) => {
  const { propertyId, category, priority, description, photoUrl } = req.body;

  if (!propertyId || !category || !description || description.length < 12) {
    return res.status(400).json({ message: 'Bien, categorie et description valide requis.' });
  }

  const result = await query(
    `insert into issue_reports (property_id, client_id, category, priority, status, description, photo_url)
     values ($1, $2, $3, $4, 'new_report', $5, $6)
     returning *`,
    [propertyId, req.user.id, category, priority || 'normal', description, photoUrl || null],
  );

  res.status(201).json({ data: result.rows[0] });
});

app.get('/tenant/issues', requireAuth, async (req, res) => {
  const result = await query(
    `select issue_reports.*, properties.title as property_title
     from issue_reports
     join properties on properties.id = issue_reports.property_id
     where issue_reports.client_id = $1 or $2 in ('admin', 'agent')
     order by issue_reports.created_at desc`,
    [req.user.id, req.user.role],
  );

  res.json({ data: result.rows });
});

function normalizePayDunyaStatus(status) {
  if (status === 'completed') return 'successful';
  if (status === 'cancelled' || status === 'canceled') return 'cancelled';
  if (status === 'failed' || status === 'fail') return 'failed';
  return 'pending';
}

app.post('/payments/paydunya/create', requireAuth, requireClientAction, async (req, res, next) => {
  try {
    const { propertyId, amount, phone, purpose } = req.body;
    const paymentPurpose = purpose || 'reservation';
    const parsedAmount = Number(amount);

    if (!propertyId || !phone || !Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ message: 'Bien, numero et montant valide requis.' });
    }

    if (!paymentPurposes.has(paymentPurpose)) {
      return res.status(400).json({ message: 'Objet de paiement invalide.' });
    }

    const propertyResult = await query(
      'select id, title, location from properties where id = $1',
      [propertyId],
    );

    if (propertyResult.rowCount === 0) {
      return res.status(404).json({ message: 'Bien introuvable.' });
    }

    const property = propertyResult.rows[0];
    const reference = `PD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const paymentResult = await query(
      `insert into payments (reference, client_id, property_id, amount, phone, purpose, status, provider)
       values ($1, $2, $3, $4, $5, $6, 'pending', 'paydunya')
       returning *`,
      [reference, req.user.id, propertyId, Math.round(parsedAmount), phone, paymentPurpose],
    );
    const payment = paymentResult.rows[0];

    const checkout = await createCheckoutInvoice({
      paymentId: payment.id,
      reference,
      propertyTitle: property.title,
      propertyLocation: property.location,
      amount: payment.amount,
      clientEmail: req.user.email,
      clientName: req.user.full_name,
      purpose: paymentPurpose,
    });

    const updatedPayment = await query(
      `update payments
       set provider_token = $1, checkout_url = $2, updated_at = now()
       where id = $3
       returning *`,
      [checkout.token, checkout.url, payment.id],
    );

    return res.status(201).json({
      data: {
        payment: updatedPayment.rows[0],
        checkoutUrl: checkout.url,
        token: checkout.token,
        channels: ['card', 'wave-senegal', 'orange-money-senegal'],
      },
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/payments/paydunya/confirm', requireAuth, requireClientAction, async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ message: 'Token PayDunya requis.' });
    }

    const confirmation = await confirmCheckoutInvoice(token);

    const { payment, receipt } = await syncSuccessfulPayment(token, confirmation);

    if (!payment) {
      return res.status(404).json({ message: 'Paiement introuvable.' });
    }

    return res.json({ data: { payment, receipt, confirmation } });
  } catch (error) {
    return next(error);
  }
});

app.post('/payments/paydunya/ipn', async (req, res) => {
  const token =
    req.body?.token ||
    req.body?.invoice?.token ||
    req.body?.data?.token ||
    req.body?.data?.invoice?.token ||
    req.query?.token;

  if (!token) {
    return res.status(202).json({ status: 'ignored', message: 'Token absent.' });
  }

  try {
    const confirmation = await confirmCheckoutInvoice(token);

    await syncSuccessfulPayment(token, confirmation);

    return res.json({ status: 'ok' });
  } catch (error) {
    console.error('PayDunya IPN error', error);
    return res.status(202).json({ status: 'pending_verification' });
  }
});

app.get('/payments/paydunya/return', (_req, res) => {
  res.send('Paiement PayDunya retourne. Vous pouvez revenir dans ImmoAgence.');
});

app.get('/payments/paydunya/cancel', (_req, res) => {
  res.send('Paiement PayDunya annule. Vous pouvez revenir dans ImmoAgence.');
});

app.post('/admin/accounts', requireAuth, requireAdminOnly, async (req, res) => {
  const { fullName, email, phone, password, role } = req.body;
  const requestedRole = normalizeRole(role);

  if (!fullName || !email || !password || password.length < 8) {
    return res.status(400).json({
      message: 'Nom, email et mot de passe de 8 caracteres minimum requis.',
    });
  }

  if (!adminCreatableRoles.has(requestedRole)) {
    return res.status(400).json({ message: 'Role de compte invalide.' });
  }

  const passwordHash = await hashPassword(password);
  const result = await query(
    `insert into users (full_name, email, phone, password_hash, role)
     values ($1, lower($2), $3, $4, $5)
     returning id, full_name, email, phone, role, is_blocked, created_at`,
    [fullName, email, phone || null, passwordHash, requestedRole],
  );

  return res.status(201).json({ user: result.rows[0] });
});

app.post('/admin/uploads/images', requireAuth, async (req, res, next) => {
  try {
    const { fileName, dataUrl } = req.body;

    if (!dataUrl || !dataUrl.startsWith('data:image/')) {
      return res.status(400).json({ message: 'Image base64 requise.' });
    }

    const match = dataUrl.match(/^data:image\/(png|jpeg|jpg|webp);base64,(.+)$/);
    if (!match) {
      return res.status(400).json({ message: 'Format image non supporte.' });
    }

    const extension = match[1] === 'jpeg' ? 'jpg' : match[1];
    const safeName = String(fileName || `property-${Date.now()}`)
      .toLowerCase()
      .replace(/[^a-z0-9-]/g, '-')
      .replace(/-+/g, '-')
      .slice(0, 60);
    const outputName = `${Date.now()}-${safeName}.${extension}`;
    await fs.mkdir(uploadDir, { recursive: true });
    await fs.writeFile(path.join(uploadDir, outputName), Buffer.from(match[2], 'base64'));

    return res.status(201).json({ url: `/uploads/${outputName}` });
  } catch (error) {
    return next(error);
  }
});

app.get('/admin/audit-logs', requireAuth, requireAdminRead, async (_req, res) => {
  const result = await query(
    `select admin_audit_logs.*, users.full_name as actor_name
     from admin_audit_logs
     left join users on users.id = admin_audit_logs.actor_id
     order by admin_audit_logs.created_at desc
     limit 100`,
  );

  return res.json({ data: result.rows });
});

const adminTables = {
  users: ['full_name', 'email', 'phone', 'role', 'is_blocked'],
  properties: [
    'title',
    'type',
    'offer_type',
    'status',
    'price',
    'location',
    'description',
    'image_url',
    'features',
    'rooms',
    'bathrooms',
    'surface_area',
    'is_furnished',
    'owner_id',
    'tenant_id',
  ],
  visits: ['property_id', 'client_id', 'agent_id', 'scheduled_at', 'status', 'message'],
  payments: ['reference', 'client_id', 'property_id', 'amount', 'phone', 'purpose', 'status', 'provider', 'provider_token', 'checkout_url', 'receipt_url'],
  contracts: ['reference', 'type', 'status', 'property_id', 'client_id', 'start_date', 'end_date', 'amount', 'terms', 'signed_at', 'signature_name', 'signature_ip'],
  receipts: ['reference', 'payment_id', 'client_id', 'property_id', 'amount', 'label'],
  issue_reports: ['property_id', 'client_id', 'category', 'priority', 'status', 'description', 'agency_comment'],
  messages: ['sender_id', 'recipient_id', 'property_id', 'subject', 'body', 'status'],
  calendar_events: ['title', 'event_type', 'property_id', 'client_id', 'agent_id', 'starts_at', 'ends_at', 'status', 'notes'],
};

app.get('/admin/:resource', requireAuth, requireAdminRead, async (req, res) => {
  const table = adminTables[req.params.resource];

  if (!table) {
    return res.status(404).json({ message: 'Ressource inconnue.' });
  }

  const result = await query(`select * from ${req.params.resource} order by created_at desc`);
  return res.json({ data: result.rows });
});

app.post('/admin/:resource', requireAuth, requireAdminWrite, async (req, res) => {
  const fields = adminTables[req.params.resource];

  if (!fields) {
    return res.status(404).json({ message: 'Ressource inconnue.' });
  }

  const selectedFields = fields.filter((field) => req.body[field] !== undefined);

  if (selectedFields.length === 0) {
    return res.status(400).json({ message: 'Aucune donnee a creer.' });
  }

  const placeholders = selectedFields.map((_, index) => `$${index + 1}`);
  const values = selectedFields.map((field) => req.body[field]);
  const result = await query(
    `insert into ${req.params.resource} (${selectedFields.join(', ')})
     values (${placeholders.join(', ')})
     returning *`,
    values,
  );

  await auditAdminAction(req, 'create', req.params.resource, result.rows[0].id, req.body);
  return res.status(201).json({ data: result.rows[0] });
});

app.patch('/admin/:resource/:id', requireAuth, requireAdminWrite, async (req, res) => {
  const fields = adminTables[req.params.resource];

  if (!fields) {
    return res.status(404).json({ message: 'Ressource inconnue.' });
  }

  const selectedFields = fields.filter((field) => req.body[field] !== undefined);

  if (selectedFields.length === 0) {
    return res.status(400).json({ message: 'Aucune donnee a modifier.' });
  }

  const setClause = selectedFields
    .map((field, index) => `${field} = $${index + 1}`)
    .join(', ');
  const values = selectedFields.map((field) => req.body[field]);
  values.push(req.params.id);

  const result = await query(
    `update ${req.params.resource}
     set ${setClause}, updated_at = now()
     where id = $${values.length}
     returning *`,
    values,
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ message: 'Element introuvable.' });
  }

  await auditAdminAction(req, 'update', req.params.resource, req.params.id, req.body);
  return res.json({ data: result.rows[0] });
});

app.delete('/admin/:resource/:id', requireAuth, requireAdminDelete, async (req, res) => {
  if (!adminTables[req.params.resource]) {
    return res.status(404).json({ message: 'Ressource inconnue.' });
  }

  const result = await query(
    `delete from ${req.params.resource} where id = $1 returning id`,
    [req.params.id],
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ message: 'Element introuvable.' });
  }

  await auditAdminAction(req, 'delete', req.params.resource, req.params.id);
  return res.json({ deleted: result.rows[0].id });
});

app.patch('/admin/users/:id/password', requireAuth, requireAdminOnly, async (req, res) => {
  const { password } = req.body;

  if (!password || password.length < 8) {
    return res.status(400).json({ message: 'Mot de passe de 8 caracteres minimum requis.' });
  }

  const passwordHash = await hashPassword(password);
  const result = await query(
    `update users set password_hash = $1, updated_at = now()
     where id = $2
     returning id, full_name, email, phone, role, is_blocked, created_at, updated_at`,
    [passwordHash, req.params.id],
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ message: 'Utilisateur introuvable.' });
  }

  return res.json({ user: result.rows[0] });
});

app.use((error, _req, res, _next) => {
  if (error.code === '23505') {
    return res.status(409).json({ message: 'Cette donnee existe deja.' });
  }

  console.error(error);
  return res.status(error.statusCode || 500).json({
    message: error.statusCode ? error.message : 'Erreur serveur.',
  });
});

async function start() {
  await fs.mkdir(uploadDir, { recursive: true });
  await query('alter table users add column if not exists is_blocked boolean not null default false');
  await query('alter table users add column if not exists fcm_token text');
  await query('alter table properties add column if not exists image_url text');
  await query('alter table properties add column if not exists tenant_id uuid references users(id) on delete set null');
  await query("alter table payments add column if not exists provider text not null default 'paydunya'");
  await query('alter table payments add column if not exists provider_token text');
  await query('alter table payments add column if not exists checkout_url text');
  await query('alter table payments add column if not exists receipt_url text');
  await query('alter table issue_reports add column if not exists photo_url text');
  await query('alter table contracts add column if not exists signed_at timestamptz');
  await query('alter table contracts add column if not exists signature_name text');
  await query('alter table contracts add column if not exists signature_ip text');
  await query(`create table if not exists messages (
    id uuid primary key default gen_random_uuid(),
    sender_id uuid references users(id) on delete set null,
    recipient_id uuid references users(id) on delete set null,
    property_id uuid references properties(id) on delete set null,
    subject text not null,
    body text not null,
    status text not null default 'unread',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  )`);
  await query(`create table if not exists calendar_events (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    event_type text not null default 'visit',
    property_id uuid references properties(id) on delete set null,
    client_id uuid references users(id) on delete set null,
    agent_id uuid references users(id) on delete set null,
    starts_at timestamptz not null,
    ends_at timestamptz,
    status text not null default 'scheduled',
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  )`);
  await query(`create table if not exists contract_signatures (
    id uuid primary key default gen_random_uuid(),
    contract_id uuid not null references contracts(id) on delete cascade,
    signer_id uuid references users(id) on delete set null,
    signer_name text not null,
    signature_text text not null,
    signed_at timestamptz not null default now(),
    ip_address text,
    created_at timestamptz not null default now()
  )`);
  await query(`create table if not exists admin_audit_logs (
    id uuid primary key default gen_random_uuid(),
    actor_id uuid references users(id) on delete set null,
    action text not null,
    resource text not null,
    resource_id text,
    details jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
  )`);

  app.listen(port, () => {
    console.log(`ImmoAgence API running on port ${port}`);
  });
}

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
