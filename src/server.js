const express = require('express');
const fs = require('fs');
const path = require('path');

const submissionsFile = path.join(__dirname, '..', 'data', 'submissions.json');
function loadSubmissions() {
  try { const raw = fs.readFileSync(submissionsFile, 'utf8'); const v = JSON.parse(raw); return Array.isArray(v) ? v : []; } catch { return []; }
}
function saveSubmission(entry) {
  const dir = path.dirname(submissionsFile);
  fs.mkdirSync(dir, { recursive: true });
  const all = loadSubmissions(); all.push(entry);
  fs.writeFileSync(submissionsFile, JSON.stringify(all, null, 2) + '\n', 'utf8');
}

const app = express();
app.use(express.urlencoded({ extended: false }));
const PORT = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

const pageMeta = {
  home: {
    title: 'Home',
    activePage: 'home',
    metaDescription:
      'The AI Guy helps businesses solve real problems with practical technology — starting with your challenge, not a product pitch.',
  },
  about: {
    title: 'About',
    activePage: 'about',
    metaDescription:
      'Learn about The AI Guy (TAIG) — our philosophy, principles, and how we use technology as a business enabler.',
  },
  services: {
    title: 'Services',
    activePage: 'services',
    metaDescription:
      'TAIG services — IT support, technology consulting, operational assessments, problem discovery, and business advisory.',
  },
  contact: {
    title: 'Contact',
    activePage: 'contact',
    metaDescription:
      'Contact The AI Guy (TAIG) — reach out to discuss your technology and business challenges.',
  },
};

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/', (_req, res) => {
  res.render('home', pageMeta.home);
});

app.get('/about', (_req, res) => {
  res.render('about', pageMeta.about);
});

app.get('/services', (_req, res) => {
  res.render('services', pageMeta.services);
});

app.get('/contact', (_req, res) => {
  res.render('contact', { ...pageMeta.contact, success: false, error: null, form: {} });
});

app.post('/contact', (req, res) => {
  const form = {
    name: (req.body.name || '').trim(),
    email: (req.body.email || '').trim(),
    phone: (req.body.phone || '').trim(),
    company: (req.body.company || '').trim(),
    subject: (req.body.subject || '').trim(),
    message: (req.body.message || '').trim(),
    timeline: (req.body.timeline || '').trim(),
    budget: (req.body.budget || '').trim(),
    smsConsent: req.body.smsConsent === 'on',
  };
  if (!form.name || !form.email || !form.phone) {
    return res.status(400).render('contact', { ...pageMeta.contact, success: false, error: 'Please fill in your full name, email, and phone.', form });
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    return res.status(400).render('contact', { ...pageMeta.contact, success: false, error: 'That email address does not look right — please check it and try again.', form });
  }
  try {
    saveSubmission({ submittedAt: new Date().toISOString(), ...form });
  } catch (err) {
    return res.status(500).render('contact', { ...pageMeta.contact, success: false, error: 'Your message could not be saved right now — please email taig2k@outlook.com directly.', form });
  }
  return res.render('contact', { ...pageMeta.contact, success: true, error: null, form: {} });
});

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
  console.log(`TSP listening on port ${PORT}`);
});
