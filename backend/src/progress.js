import express from 'express';
import { leerUsers, leerAchievements, leerProgress, guardarProgress } from './db.js';

const router = express.Router();

router.get('/', (req, res) => {
  const userId = Number(req.query.userId);

  const users = leerUsers();
  const achievements = leerAchievements();
  const progress = leerProgress();

  if (userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });

    const userAchievements = progress
      .filter(p => p.userId === userId)
      .map(p => achievements.find(a => a.id === p.achievementId))
      .filter(a => a !== undefined);

    return res.json({
      user: user.name,
      achievements: userAchievements,
    });
  } else {
    // Opcional: devolver todo el progreso
    const allData = users.map(user => ({
      user: user.name,
      achievements: progress
        .filter(p => p.userId === user.id)
        .map(p => achievements.find(a => a.id === p.achievementId))
        .filter(a => a !== undefined),
    }));
    return res.json(allData);
  }
});

router.post('/', (req, res) => {
  const { userId, achievementId } = req.body;

  if (!userId || !achievementId) {
    return res.status(400).json({ ok: false, error: 'Faltan userId o achievementId' });
  }

  const users = leerUsers();
  const achievements = leerAchievements();
  const progress = leerProgress();

  if (!users.find(u => u.id === userId)) {
    return res.status(404).json({ ok: false, error: 'Usuario no encontrado' });
  }

  if (!achievements.find(a => a.id === achievementId)) {
    return res.status(404).json({ ok: false, error: 'Logro no encontrado' });
  }

  const exists = progress.some(p => p.userId === userId && p.achievementId === achievementId);
  if (exists) {
    return res.status(409).json({ ok: false, error: 'Progreso ya registrado' });
  }

  const newProgress = { userId, achievementId };
  progress.push(newProgress);
  guardarProgress(progress);

  return res.status(201).json({ ok: true, item: newProgress });
});

export default router;
