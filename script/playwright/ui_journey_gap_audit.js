const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const PROJECT_A_URL = process.env.PROJECT_A_URL || 'http://127.0.0.1:3000';
const PROJECT_B_URL = process.env.PROJECT_B_URL || 'http://127.0.0.1:4173';
const REPORT_DIR = process.env.REPORT_DIR || '/tmp/ui-journey-audit';
const UPLOAD_FILE = process.env.UPLOAD_FILE || '/Users/peter/Project/Project_A/test/fixtures/files/sample_upload.txt';

const ensureDir = (dir) => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
};

const saveShot = async (page, name) => {
  const file = path.join(REPORT_DIR, `${name}.png`);
  await page.screenshot({ path: file, fullPage: true });
  return file;
};

const textList = async (page, selector) => {
  const loc = page.locator(selector);
  const count = await loc.count();
  const out = [];
  for (let i = 0; i < count; i += 1) {
    const text = (await loc.nth(i).innerText()).trim();
    if (text) out.push(text);
  }
  return out;
};

const findAndClick = async (page, patterns) => {
  for (const p of patterns) {
    const link = page.getByRole('link', { name: p, exact: false });
    if (await link.count()) {
      await link.first().click();
      return true;
    }

    const button = page.getByRole('button', { name: p, exact: false });
    if (await button.count()) {
      await button.first().click();
      return true;
    }

    const fallback = page.locator(`text=${p}`);
    if (await fallback.count()) {
      await fallback.first().click();
      return true;
    }
  }
  return false;
};

const collectProjectAFlow = async (browser) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const data = {
    url: PROJECT_A_URL,
    steps: [],
    gaps: [],
    externalGates: [],
    checks: {}
  };

  const step = async (name, fn) => {
    try {
      await fn();
      data.steps.push({ name, status: 'ok', url: page.url() });
    } catch (error) {
      data.steps.push({ name, status: 'failed', error: error.message, url: page.url() });
      data.gaps.push(`${name} failed: ${error.message}`);
    }
  };

  await step('A1_guest_home', async () => {
    await page.goto(PROJECT_A_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(800);
    await saveShot(page, 'a1_guest_home');

    const hasGoogleCta = (await page.locator('text=/Continue with Google|Google로 계속/').count()) > 0;
    data.checks.homeHasGoogleCta = hasGoogleCta;
    if (!hasGoogleCta) data.gaps.push('Guest home does not show Google sign-in CTA.');

    const hasProjectBLogoAsset = (await page.locator('img[src="/brand/soletalk-logo-v2.png"]').count()) > 0;
    data.checks.hasProjectBLogoAsset = hasProjectBLogoAsset;
    if (!hasProjectBLogoAsset) data.gaps.push('Top navigation is missing Project_B logo asset.');

    const hasProjectBFeatureGraphic = (await page.locator('img[src="/brand/projectb-feature-graphic.png"]').count()) > 0;
    data.checks.hasProjectBFeatureGraphic = hasProjectBFeatureGraphic;
    if (!hasProjectBFeatureGraphic) data.gaps.push('Home is missing Project_B feature graphic asset panel.');
  });

  await step('A2_google_oauth_redirect', async () => {
    const clicked = await findAndClick(page, ['Continue with Google', 'Google로 계속', 'Sign In']);
    if (!clicked) throw new Error('OAuth entry CTA not found');

    await page.waitForTimeout(2000);
    const url = page.url();
    data.checks.oauthRedirectUrl = url;
    await saveShot(page, 'a2_oauth_redirect');

    if (!/accounts\.google\.com|\/auth\/google_oauth2/.test(url)) {
      data.gaps.push(`OAuth redirect not detected. current url=${url}`);
    }

    if (url.includes('/signin/oauth/error')) {
      data.externalGates.push(
        'Google OAuth consent did not complete in-browser. Verify localhost callback URI registration in Google Cloud Console.'
      );
    }
  });

  await step('A3_back_and_dev_sign_in', async () => {
    await page.goto(PROJECT_A_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(800);

    const signedIn = await page.locator('text=/Welcome|환영/').count();
    if (signedIn > 0) {
      data.checks.devSignInUsed = false;
      await saveShot(page, 'a3_signed_in_already');
      return;
    }

    const clicked = await findAndClick(page, ['Quick Dev Sign In', 'Dev Sign In']);
    if (!clicked) {
      data.gaps.push('Dev sign-in button unavailable (cannot run full local journey without OAuth callback).');
      await saveShot(page, 'a3_no_dev_signin');
      return;
    }

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(800);
    await saveShot(page, 'a3_after_dev_signin');
    data.checks.devSignInUsed = true;
  });

  await step('A4_session_create_and_enter', async () => {
    const movedToNew = await findAndClick(page, ['Start New Session', 'New Session', '새 세션']);
    if (!movedToNew) throw new Error('new session entry not found');

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(500);

    const started = await findAndClick(page, ['Start Session', '세션 시작']);
    if (!started) throw new Error('start session button not found');

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(700);
    await saveShot(page, 'a4_session_show');

    const hasDepth = (await page.locator('text=/DEPTH Snapshot|Depth Snapshot|DEPTH 스냅샷/').count()) > 0;
    data.checks.sessionHasDepth = hasDepth;
    if (!hasDepth) data.gaps.push('Session page missing DEPTH Snapshot section.');

    const hasOverlayLayout = (await page.locator('.session-stage .session-overlay-top').count()) > 0
      && (await page.locator('.session-stage .session-overlay-bottom').count()) > 0;
    data.checks.sessionUsesOverlayLayout = hasOverlayLayout;
    if (!hasOverlayLayout) data.gaps.push('Session page does not use Project_B-style overlay layout.');
  });

  await step('A5_debug_tools_actions', async () => {
    const details = page.locator('details');
    if (await details.count()) {
      const open = await details.first().getAttribute('open');
      if (open === null) {
        await details.first().locator('summary').click();
        await page.waitForTimeout(300);
      }
    }

    const transcription = page.locator('[data-native-bridge-target="transcription"], textarea[name="transcript"], input[name="transcript"], #transcript');
    if (await transcription.count()) {
      await transcription.first().fill('Sample transcript from Playwright journey audit');
      await findAndClick(page, ['Send Transcription', '전송']);
      await page.waitForTimeout(400);
    } else {
      data.gaps.push('Debug transcription input not found.');
    }

    await saveShot(page, 'a5_debug_tools');
  });

  await step('A6_settings_upload_flow', async () => {
    const moved = await findAndClick(page, ['Settings', '설정']);
    if (!moved) throw new Error('settings nav not found');

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(500);

    const input = page.locator('input[type="file"]');
    if ((await input.count()) === 0) {
      data.gaps.push('Settings page missing file upload input.');
      await saveShot(page, 'a6_settings_no_file_input');
      return;
    }

    await input.first().setInputFiles(UPLOAD_FILE);
    await findAndClick(page, ['Save Settings', '저장', 'Save']);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(700);
    await saveShot(page, 'a6_settings_uploaded');

    const hasUploadedName = (await page.locator('text=sample_upload.txt').count()) > 0;
    data.checks.fileUploadVisible = hasUploadedName;
    if (!hasUploadedName) data.gaps.push('Uploaded file is not visible after settings save.');
  });

  await step('A7_subscription_validate_guard', async () => {
    const moved = await findAndClick(page, ['Settings', '설정']);
    if (!moved) throw new Error('settings nav not found for subscription section');

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(500);
    const hasSubscriptionSection = (await page.locator('#subscription').count()) > 0;
    if (!hasSubscriptionSection) {
      data.gaps.push('Settings page does not contain subscription section.');
    }
    await findAndClick(page, ['Restore Subscription', 'Validate Subscription', '구독 복원', '검증']);
    await page.waitForTimeout(700);
    await saveShot(page, 'a7_subscription_validate');

    const validationAlert = await page.locator('text=/required|필수|입력/').count();
    data.checks.subscriptionValidationMessage = validationAlert > 0;
    if (validationAlert === 0) {
      data.gaps.push('No validation feedback after empty subscription restore/validate submit.');
    }
  });

  data.navLinks = await textList(page, 'a, button');
  await page.close();
  return data;
};

const collectProjectBBaseline = async (browser) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const data = {
    url: PROJECT_B_URL,
    steps: [],
    checks: {},
    baseline: {}
  };

  const step = async (name, fn) => {
    try {
      await fn();
      data.steps.push({ name, status: 'ok', url: page.url() });
    } catch (error) {
      data.steps.push({ name, status: 'failed', error: error.message, url: page.url() });
    }
  };

  await step('B1_home', async () => {
    await page.goto(PROJECT_B_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1200);
    await saveShot(page, 'b1_home');

    data.baseline.title = await page.title();
    data.baseline.links = await textList(page, 'a, button');
    data.checks.hasVoiceSphere = (await page.locator('canvas, .sphere, .orb, [data-testid*="sphere"]').count()) > 0;
  });

  await step('B2_try_click_primary_actions', async () => {
    const candidates = ['Start', 'Session', 'Upload', 'Settings', 'Continue', 'Get Started'];
    for (const label of candidates) {
      await findAndClick(page, [label]);
      await page.waitForTimeout(250);
    }

    await saveShot(page, 'b2_after_clicks');
    data.baseline.linksAfter = await textList(page, 'a, button');
    data.baseline.urlAfter = page.url();
  });

  await page.close();
  return data;
};

(async () => {
  ensureDir(REPORT_DIR);
  const browser = await chromium.launch({ headless: false, slowMo: 60 });

  try {
    const projectA = await collectProjectAFlow(browser);
    const projectB = await collectProjectBBaseline(browser);

    const summary = {
      generatedAt: new Date().toISOString(),
      reportDir: REPORT_DIR,
      projectA,
      projectB,
      gapCount: projectA.gaps.length,
      gaps: projectA.gaps
    };

    const outputPath = path.join(REPORT_DIR, 'journey_report.json');
    fs.writeFileSync(outputPath, JSON.stringify(summary, null, 2));

    console.log(`REPORT_PATH=${outputPath}`);
    console.log(`GAP_COUNT=${summary.gapCount}`);
    for (const gap of summary.gaps) console.log(`GAP=${gap}`);
  } finally {
    await browser.close();
  }
})();
