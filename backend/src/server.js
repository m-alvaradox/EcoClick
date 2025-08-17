import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import quizzesRouter from './quizzes.js';
import gameplayRouter from './gameplay.js';
import path from 'path';
import { fileURLToPath } from 'url';

import usersRoutes from './users.js';
import achievementsRoutes from './achievements.js';
import userAchievementsRoutes from './userAchievements.js';
import progressRoutes from './progress.js';
import resultsRouter from './results.js'; 

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.set('json spaces', 2);
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Rutas de tu aplicación (sin /api)
app.use('/', resultsRouter);

app.use('/api/users', usersRoutes);
app.use('/api/achievements', achievementsRoutes);
app.use('/api/userAchievements', userAchievementsRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/quizzes', quizzesRouter);
app.use('/api/games', gameplayRouter);


app.use(express.static(path.join(__dirname, '../public')));



// Endpoint de prueba
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'EcoClick API' });
});

app.get('/', (req, res) => {
  res.json({ ok: true, service: 'EcoClick API funcionando' });
});

// Manejo de rutas no encontradas
app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`✅ EcoClick backend en http://localhost:${PORT}`);
});
