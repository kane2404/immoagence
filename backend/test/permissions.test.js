const test = require('node:test');
const assert = require('node:assert/strict');

const {
  canDeleteAdminResource,
  canReadAdminResource,
  canRequestClientAction,
  canWriteAdminResource,
} = require('../src/permissions');

test('admin can manage all admin resources except deleting users', () => {
  assert.equal(canReadAdminResource('admin', 'users'), true);
  assert.equal(canWriteAdminResource('admin', 'users'), true);
  assert.equal(canDeleteAdminResource('admin', 'properties'), true);
  assert.equal(canDeleteAdminResource('admin', 'users'), false);
});

test('agent can operate agency resources but cannot manage users or payments', () => {
  assert.equal(canReadAdminResource('agent', 'properties'), true);
  assert.equal(canWriteAdminResource('agent', 'properties'), true);
  assert.equal(canReadAdminResource('agent', 'users'), false);
  assert.equal(canWriteAdminResource('agent', 'users'), false);
  assert.equal(canWriteAdminResource('agent', 'payments'), false);
  assert.equal(canDeleteAdminResource('agent', 'properties'), false);
});

test('visitor cannot request protected client actions', () => {
  assert.equal(canRequestClientAction('visitor'), false);
  assert.equal(canRequestClientAction('tenant'), true);
  assert.equal(canRequestClientAction('owner'), true);
});
