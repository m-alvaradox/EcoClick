import express from 'express';
import { leerUsers, guardarUsers } from './db.js';

const router = express.Router();

router.get('/', (req, res) => {
  const users = leerUsers();
  res.json(users);
});

router.post('/', (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Falta nombre' });

  const users = leerUsers();
  const newId = users.length > 0 ? Math.max(...users.map(u => u.id)) + 1 : 1;

  const newUser = { id: newId, name };
  users.push(newUser);
  guardarUsers(users);

  res.status(201).json(newUser);
});

export default router;
