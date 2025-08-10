import { Router } from 'express';
import { answers, ecoFeedback } from './db.js';

const r = Router();

// Guardar respuestas del juego (sesión)
r.post('/games/:gameId/answers', (req, res) => {
  const { userId, answers: ans, score, timeSec } = req.body || {};
  if (!userId || !Array.isArray(ans)) {
    return res.status(400).json({ ok: false, error: 'userId y answers (array) son requeridos' });
  }
  const item = {
    id: answers.length + 1,
    gameId: req.params.gameId,
    userId,
    answers: ans,
    score: Number(score ?? 0),
    timeSec: Number(timeSec ?? 0),
    createdAt: new Date().toISOString()
  };
  answers.push(item);
  res.status(201).json({ ok: true, item });
});

// Retroalimentación ecológica por tema (o todo si no pasas topic)
r.get('/feedback', (req, res) => {
  const { topic } = req.query;
  const items = topic ? ecoFeedback.filter(f => f.topic === String(topic)) : ecoFeedback;
  res.json({ ok: true, items });
});

export default r;