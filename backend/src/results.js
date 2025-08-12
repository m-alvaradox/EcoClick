import { Router } from 'express';
import { addCategoryResult, getResponsesStats } from './db.js';

const router = Router();

// POST /results/category  (WRITE)  
router.post('/results/category', (req, res) => {
  const { userId, category, score } = req.body || {};
  if (userId === undefined || !category || score === undefined) {
    return res.status(400).json({ ok: false, error: 'Faltan userId, category o score' });
  }
  const parsedScore = Number(score);
  if (Number.isNaN(parsedScore) || parsedScore < 0) {
    return res.status(400).json({ ok: false, error: 'score debe ser número >= 0' });
  }

  const item = addCategoryResult({ userId, category, score: parsedScore });
  return res.status(201).json({ ok: true, item }); // <-- solo userId, category, score
});

// GET /stats/responses?userId=  (READ)
router.get('/stats/responses', (req, res) => {
  const { userId } = req.query;
  const { summary, categories } = getResponsesStats(userId);
  return res.status(200).json({ ok: true, summary, categories });
});

export default router;
