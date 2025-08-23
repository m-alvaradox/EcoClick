// Mario Alvarado
import fs from 'fs';
import path from 'path';

export const answers = []; //respuestas de juego (sesiones)

const dataDir = path.join(process.cwd(), 'data');

export const quizzes = readJson('quizzes.json');
export const ecoFeedback = readJson('ecoFeedback.json')

function ensureDataDir() {
  if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir);
}

// Función genérica para leer JSON
function readJson(fileName) {
  ensureDataDir();
  const filePath = path.join(dataDir, fileName);
  if (!fs.existsSync(filePath)) return [];
  try {
    const data = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(data);
  } catch (e) {
    console.error(`Error leyendo ${fileName}:`, e);
    return [];
  }
}

// Función genérica para guardar JSON
function writeJson(fileName, data) {
  ensureDataDir();
  const filePath = path.join(dataDir, fileName);
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
  } catch (e) {
    console.error(`Error escribiendo ${fileName}:`, e);
  }
}

// Usuarios
export function leerUsers() {
  return readJson('users.json');
}
export function guardarUsers(users) {
  writeJson('users.json', users);
}

// Logros
export function leerAchievements() {
  return readJson('achievements.json');
}
export function guardarAchievements(achievements) {
  writeJson('achievements.json', achievements);
}

// Progreso
export function leerProgress() {
  return readJson('progress.json');
}
export function guardarProgress(progress) {
  writeJson('progress.json', progress);
}



// Andrés Layedra

// --- Helpers para resultados por categoría y estadísticas ---

function _readSafeProgress() {
  const p = leerProgress() || {};
  return {
    answers: Array.isArray(p.answers) ? p.answers : [],
    categoryResults: Array.isArray(p.categoryResults) ? p.categoryResults : [],
  };
}

function _uid() {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

export function addCategoryResult({ userId, category, score }) {
  const db = leerProgress();
  db.answers = Array.isArray(db.answers) ? db.answers : [];
  db.categoryResults = Array.isArray(db.categoryResults) ? db.categoryResults : [];

  const item = {
    userId,
    category: String(category || '').trim(),
    score: Number(score)
  };

  db.categoryResults.push(item);
  guardarProgress(db);
  return item;
}

export function getResponsesStats(userId) {
  const db = _readSafeProgress();

  const results = userId
    ? db.categoryResults.filter(r => String(r.userId) === String(userId))
    : db.categoryResults;

  const answers = userId
    ? db.answers.filter(a => String(a.userId) === String(userId))
    : db.answers;

  const totalSessions = results.length;
  const totalAnswers = answers.length;

  const avgScore = results.length
    ? Number(
        (
          results.reduce((s, r) => s + Number(r.score || 0), 0) / results.length
        ).toFixed(1)
      )
    : 0;

  const map = new Map();
  for (const r of results) {
    const key = r.category || 'unknown';
    if (!map.has(key)) map.set(key, { sum: 0, attempts: 0 });
    const e = map.get(key);
    e.sum += Number(r.score || 0);
    e.attempts += 1;
  }

  const categories = Array.from(map.entries()).map(([category, e]) => ({
    category,
    avgScore: Number((e.sum / e.attempts).toFixed(1)),
    attempts: e.attempts,
  }));

  return { summary: { totalSessions, totalAnswers, avgScore }, categories };
}