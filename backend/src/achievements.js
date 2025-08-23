import express from 'express';
import { leerAchievements, guardarAchievements } from './db.js';

const router = express.Router();

router.get('/', (req, res) => {
  const achievements = leerAchievements();
  res.json(achievements);
});

router.post('/', (req, res) => {
  const { name, description, points } = req.body;
  if (!name || !description || typeof points !== 'number') {
    return res.status(400).json({ error: 'Faltan datos o formato incorrecto' });
  }

  const achievements = leerAchievements();
  const newId = achievements.length > 0 ? Math.max(...achievements.map(a => a.id)) + 1 : 1;

  const newAchievement = { id: newId, name, description, points };
  achievements.push(newAchievement);
  guardarAchievements(achievements);

  res.status(201).json(newAchievement);
});

export default router;
