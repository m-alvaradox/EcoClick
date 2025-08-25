import express from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// sube un nivel desde src hasta backend
const COMMENTS_PATH = path.join(__dirname, '..', 'data', 'comments.json');
const USERS_PATH = path.join(__dirname, '..', 'data', 'users.json');

const router = express.Router();

// Obtener todos los comentarios
router.get('/', (req, res) => {
  fs.readFile(COMMENTS_PATH, 'utf8', (err, data) => {
    if (err) return res.status(500).json({ error: 'No se pudo leer comentarios' });
    const comments = JSON.parse(data);
    res.json(comments);
  });
});

// Agregar un comentario
router.post('/', (req, res) => {
  const { userId, userName, comment } = req.body;
  if (!userId || !userName || !comment) {
    return res.status(400).json({ error: 'Faltan userId, userName o comentario' });
  }

  fs.readFile(COMMENTS_PATH, 'utf8', (err, commentsData) => {
    if (err) return res.status(500).json({ error: 'No se pudo leer comentarios' });
    const comments = commentsData ? JSON.parse(commentsData) : [];
    const newComment = {
      userId,
      userName,
      comment
    };
    comments.push(newComment);
    fs.writeFile(COMMENTS_PATH, JSON.stringify(comments, null, 2), err => {
      if (err) return res.status(500).json({ error: 'No se pudo guardar comentario' });
      res.status(201).json(newComment);
    });
  });
});

export default router;