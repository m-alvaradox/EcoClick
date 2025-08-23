import { Router } from 'express';
import { leerUsers } from './db.js';
const router = Router();

router.get('/', (_req, res) => {
  res.json(leerUsers());
});

export default router;
