import express from 'express';
import { leerProgress, guardarProgress, leerAchievements, leerUsers, leerUserAchievements, guardarUserAchievements } from './db.js';

const router = express.Router();

// GET /progress?userId=1
router.get('/', (req, res) => {
  const userId = parseInt(req.query.userId);
  const progress = Array.isArray(leerProgress()) ? leerProgress() : []; // asegurar arreglo
  const achievements = Array.isArray(leerAchievements()) ? leerAchievements() : [];

  let items;
  if (userId) {
    items = progress
      .filter(p => p.userId === userId)
      .map(p => {
        const a = achievements.find(a => a.id === p.achievementId);
        return a ? { id: a.id, name: a.name, icon: a.icon, date: p.date } : null;
      })
      .filter(a => a);
  } else {
    items = progress
      .map(p => {
        const a = achievements.find(a => a.id === p.achievementId);
        return a ? { id: a.id, name: a.name, icon: a.icon, date: p.date } : null;
      })
      .filter(a => a);
  }

  res.json({ items });
});

// POST /progress
router.post('/', (req, res) => {
  const { userId, achievementId, date } = req.body;
  if (!userId || !achievementId) return res.status(400).json({ error: 'Faltan datos' });

  const users = Array.isArray(leerUsers()) ? leerUsers() : [];
  const achievements = Array.isArray(leerAchievements()) ? leerAchievements() : [];
  const progress = Array.isArray(leerProgress()) ? leerProgress() : [];
  const userAchievements = Array.isArray(leerUserAchievements()) ? leerUserAchievements() : [];

  if (!users.find(u => u.id === userId)) return res.status(404).json({ error: 'Usuario no encontrado' });
  if (!achievements.find(a => a.id === achievementId)) return res.status(404).json({ error: 'Logro no encontrado' });
  if (progress.some(p => p.userId === userId && p.achievementId === achievementId))
    return res.status(409).json({ error: 'Progreso ya registrado' });

  const now = date || new Date().toISOString();

  // Guardar en progress.json
  const newProgress = { userId, achievementId, date: now };
  progress.push(newProgress);
  guardarProgress(progress);

  // Guardar en userAchievements.json
  if (!userAchievements.some(p => p.userId === userId && p.achievementId === achievementId)) {
    userAchievements.push({ userId, achievementId, date: now });
    guardarUserAchievements(userAchievements);
  }

  res.status(201).json({ item: newProgress });
});

export default router;
