import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import path from 'path';
import { fileURLToPath } from 'url';

import usersRoutes from './users.js';
import achievementsRoutes from './achievements.js';
import progressRoutes from './progress.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/api/users', usersRoutes);
app.use('/api/achievements', achievementsRoutes);
app.use('/api/progress', progressRoutes);

app.use(express.static(path.join(__dirname, '../public')));

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'EcoClick API' });
});



app.get('/', (req, res) => {
  res.json({ ok: true, service: 'EcoClick API funcionando' });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`✅ EcoClick backend en http://localhost:${PORT}`);
});
