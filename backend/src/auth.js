const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const { query } = require('./db');

const allowedRoles = new Set(['visitor', 'tenant', 'owner', 'admin', 'agent']);

function normalizeRole(role) {
  return allowedRoles.has(role) ? role : 'visitor';
}

async function hashPassword(password) {
  return bcrypt.hash(password, 12);
}

async function verifyPassword(password, passwordHash) {
  return bcrypt.compare(password, passwordHash);
}

function signToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      role: user.role,
      email: user.email,
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
  );
}

async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ message: 'Authentification requise.' });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const result = await query(
      'select id, full_name, email, phone, role, is_blocked, created_at from users where id = $1',
      [payload.sub],
    );

    if (result.rowCount === 0) {
      return res.status(401).json({ message: 'Utilisateur introuvable.' });
    }

    if (result.rows[0].is_blocked) {
      return res.status(403).json({ message: 'Ce compte est bloque par l agence.' });
    }

    req.user = result.rows[0];
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Session invalide ou expiree.' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Acces non autorise.' });
    }

    return next();
  };
}

module.exports = {
  hashPassword,
  normalizeRole,
  requireAuth,
  requireRole,
  signToken,
  verifyPassword,
};
