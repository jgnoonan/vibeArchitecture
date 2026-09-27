// Fixtures for crypto.yaml.
const crypto = require("crypto");
const https = require("https");
const serialize = require("node-serialize");
const libxmljs = require("libxmljs");

function ciphers(key, iv, data) {
  // ruleid: va-weak-cipher-js
  crypto.createCipher("aes-256-cbc", key);
  // ruleid: va-weak-cipher-js
  crypto.createCipheriv("aes-128-ecb", key, null);
  // ruleid: va-weak-cipher-js
  crypto.createCipheriv("des-ede3-cbc", key, iv);
  // ok: va-weak-cipher-js
  crypto.createCipheriv("aes-256-gcm", key, iv);
}

function tls() {
  // ruleid: va-tls-verification-disabled-js
  const agent = new https.Agent({ rejectUnauthorized: false });
  // ruleid: va-tls-verification-disabled-js
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
  // ok: va-tls-verification-disabled-js
  const agent2 = new https.Agent({ rejectUnauthorized: true, ca: devCa });
}

function deser(body) {
  // ruleid: va-unsafe-deserialization-js
  const obj = serialize.unserialize(body);
  // ok: va-unsafe-deserialization-js
  const obj2 = JSON.parse(body);
}

function xml(body) {
  // ruleid: va-xxe-parser-js
  libxmljs.parseXml(body, { noent: true });
  // ok: va-xxe-parser-js
  libxmljs.parseXml(body, { noblanks: true });
}
