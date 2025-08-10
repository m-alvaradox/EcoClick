import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import quizzesRouter from './quizzes.js';
import gameplayRouter from './gameplay.js';

const app = express();
app.use(cors());              // Permitir peticiones del front
app.use(express.json());      // Leer JSON del body
app.use(morgan('dev'));       // Logs bonitos en consola

app.use('/quizzes', quizzesRouter); // /quizzes y /quizzes/:id
app.use('/', gameplayRouter);       // /games/:gameId/answers y /feedback

// Endpoint de prueba
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'EcoClick API' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`✅ EcoClick backend en http://localhost:${PORT}`);
});
