const paydunya = require('paydunya');

const PAYDUNYA_CHANNELS = ['card', 'wave-senegal', 'orange-money-senegal'];

function requirePayDunyaConfig() {
  const missing = [
    'PAYDUNYA_MASTER_KEY',
    'PAYDUNYA_PRIVATE_KEY',
    'PAYDUNYA_TOKEN',
  ].filter((name) => !process.env[name]);

  if (missing.length > 0) {
    const error = new Error(`Configuration PayDunya manquante: ${missing.join(', ')}`);
    error.statusCode = 503;
    throw error;
  }
}

function createSetup() {
  requirePayDunyaConfig();

  return new paydunya.Setup({
    masterKey: process.env.PAYDUNYA_MASTER_KEY,
    privateKey: process.env.PAYDUNYA_PRIVATE_KEY,
    publicKey: process.env.PAYDUNYA_PUBLIC_KEY,
    token: process.env.PAYDUNYA_TOKEN,
    mode: process.env.PAYDUNYA_MODE || 'test',
  });
}

function createStore() {
  return new paydunya.Store({
    name: process.env.PAYDUNYA_STORE_NAME || 'ImmoAgence Senegal',
    tagline: process.env.PAYDUNYA_STORE_TAGLINE || 'Immobilier premium au Senegal',
    phoneNumber: process.env.PAYDUNYA_STORE_PHONE || '',
    websiteURL: process.env.PAYDUNYA_STORE_WEBSITE_URL || 'http://localhost:4000',
    cancelURL:
      process.env.PAYDUNYA_CANCEL_URL ||
      'http://localhost:4000/payments/paydunya/cancel',
    returnURL:
      process.env.PAYDUNYA_RETURN_URL ||
      'http://localhost:4000/payments/paydunya/return',
    callbackURL:
      process.env.PAYDUNYA_IPN_URL ||
      'http://localhost:4000/payments/paydunya/ipn',
  });
}

async function createCheckoutInvoice({
  paymentId,
  reference,
  propertyTitle,
  propertyLocation,
  amount,
  clientEmail,
  clientName,
  purpose,
}) {
  const invoice = new paydunya.CheckoutInvoice(createSetup(), createStore());
  const description = `Paiement ${purpose} - ${propertyTitle}`;

  invoice.addItem(propertyTitle, 1, amount, amount, propertyLocation);
  invoice.description = description;
  invoice.totalAmount = amount;
  invoice.addChannels(PAYDUNYA_CHANNELS);
  invoice.addCustomData('payment_id', paymentId);
  invoice.addCustomData('reference', reference);
  invoice.addCustomData('client_email', clientEmail || 'client@immoagence.sn');
  invoice.addCustomData('client_name', clientName || 'Client ImmoAgence');

  await invoice.create();

  return {
    token: invoice.token,
    url: invoice.url,
    status: invoice.status,
    responseText: invoice.responseText,
  };
}

async function confirmCheckoutInvoice(token) {
  const invoice = new paydunya.CheckoutInvoice(createSetup(), createStore());
  await invoice.confirm(token);

  return {
    status: invoice.status,
    responseText: invoice.responseText,
    receiptUrl: invoice.receiptURL,
    customer: invoice.customer,
    customData: invoice.customData || {},
    totalAmount: invoice.totalAmount,
  };
}

module.exports = {
  PAYDUNYA_CHANNELS,
  confirmCheckoutInvoice,
  createCheckoutInvoice,
};
