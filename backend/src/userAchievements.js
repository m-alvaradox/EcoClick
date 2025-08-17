import express from 'express';
import { leerUserAchievements, guardarUserAchievements,leerAchievements } from './db.js';

const router = express.Router();


// GET /api/userAchievements?userId=1
router.get('/', (req, res) => {
  const userId = parseInt(req.query.userId);
  if (!userId) return res.status(400).json({ error: 'Falta userId' });

  const userAch = leerUserAchievements();
  const achievements = leerAchievements();

  // Filtrar los logros del usuario y agregar info del logro
  const items = userAch
    .filter(p => p.userId === userId)
    .map(p => {
      const ach = achievements.find(a => a.id === p.achievementId);
      return {
        userId: p.userId,
        achievementId: p.achievementId,
        date: p.date,
        name: ach?.name ?? 'Desconocido',
        description: ach?.description ?? '',
        points: ach?.points ?? 0
      };
    });

  res.json({ items });
});

// POST /api/userAchievements
router.post('/', (req, res) => {
  const { userId, achievementId, date } = req.body;

  if (!userId || !achievementId || !date)
    return res.status(400).json({ error: 'Faltan datos' });

  const achievements = leerUserAchievements();

  // evitar duplicados
  if (achievements.some(p => p.userId === Number(userId) && p.achievementId === achievementId))
    return res.status(409).json({ error: 'Progreso ya registrado' });

  const newProgress = { userId: Number(userId), achievementId, date };
  achievements.push(newProgress);
  guardarUserAchievements(achievements);

  res.status(201).json({ item: newProgress });
});

export default router;
