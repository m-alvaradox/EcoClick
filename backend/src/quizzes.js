// Visualización de quizzes (Mario Alvarado)
import { Router } from 'express';
import { quizzes } from './db.js';

const r = Router();

// Lista de quizzes (filtro opcional por categoría)
r.get('/', (req, res) => {
  const { category } = req.query;
  const items = category ? quizzes.filter(q => q.category === String(category)) : quizzes;
  res.json({ ok: true, items });
});

// Detalle de un quiz por id
r.get('/:id', (req, res) => {
  const item = quizzes.find(q => q.id === req.params.id);
  if (!item) return res.status(404).json({ ok: false, error: 'Quiz no encontrado' });
  res.json({ ok: true, item });
});

export default r;