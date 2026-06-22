const express = require('express');
const path = require('path');

const app = express();
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
  res.render('contact', pageMeta.contact);
});

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
  console.log(`TSP listening on port ${PORT}`);
});
