import express from 'express';
import { leerQuizzes, guardarQuizzes } from './db.js';

const router = express.Router();

// GET todos los quizzes
router.get('/', async (req, res) => {
  const quizzes = await leerQuizzes();
  res.json(quizzes);
});

// POST nuevo quiz
router.post('/', async (req, res) => {
  const quizzes = await leerQuizzes();
  quizzes.push(req.body);
  await guardarQuizzes(quizzes);
  res.status(201).json({ message: 'Quiz agregado con éxito' });
});

export default router;
