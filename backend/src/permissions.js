const adminOnlyResources = new Set(['users', 'audit-logs']);
const adminWriteOnlyResources = new Set(['payments', 'receipts']);
const agencyResources = new Set([
  'properties',
  'visits',
  'contracts',
  'issue_reports',
  'messages',
  'calendar_events',
]);

function isAgencyRole(role) {
  return role === 'admin' || role === 'agent';
}

function canReadAdminResource(role, resource) {
  if (role === 'admin') return true;
  if (role === 'agent') return !adminOnlyResources.has(resource);
  return false;
}

function canWriteAdminResource(role, resource) {
  if (role === 'admin') return true;
  if (role !== 'agent') return false;
  return agencyResources.has(resource) && !adminWriteOnlyResources.has(resource);
}

function canDeleteAdminResource(role, resource) {
  return role === 'admin' && resource !== 'users';
}

function canRequestClientAction(role) {
  return ['tenant', 'owner', 'admin', 'agent'].includes(role);
}

module.exports = {
  canDeleteAdminResource,
  canReadAdminResource,
  canRequestClientAction,
  canWriteAdminResource,
  isAgencyRole,
};
