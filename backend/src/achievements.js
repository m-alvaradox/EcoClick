import { Router } from 'express';
import { leerAchievements, guardarAchievements } from './db.js';
const router = Router();

router.get('/', (_req, res) => {
  res.json(leerAchievements()); // array llano
});

router.post('/', (req, res) => {
  const { name, description, points } = req.body || {};
  if (!name || !description || typeof points !== 'number') {
    return res.status(400).json({ error: 'Faltan datos o formato incorrecto' });
  }
  const list = leerAchievements();
  const newId = list.length ? Math.max(...list.map(a => a.id)) + 1 : 1;
  const item = { id: newId, name, description, points };
  list.push(item);
  guardarAchievements(list);
  res.status(201).json(item);
});

export default router;

