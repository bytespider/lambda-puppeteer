'use strict';

const puppeteer = require('puppeteer');

exports.handler = async (event, context) => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--use-gl=swiftshader', '--disable-dev-shm-usage', '--single-process'],
  });
  const page = await browser.newPage();
  await page.goto('https://example.com');
  const img = await page.screenshot();

  await browser.close();

  return {
    statusCode: 201,
    isBase64Encoded: true,
    body: img.toString('base64'),
  };
};
