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

// --- CONFIG DE NIVELES ---
// L1=0, L2=500, L3=1500, y luego +1000 por nivel hasta L10
const LEVEL_THRESHOLDS = [0, 500, 1500, 2500, 3500, 4500, 5500, 6500, 7500, 8500]; // 10 niveles.

function getTotalProgressPoints(results) {
  return results
    .filter(r => Number(r.score) === 100)   // solo intentos con score == 100
    .reduce((acc, r) => acc + Number(r.score), 0); 
}

// Calcula nivel y progreso dentro del nivel con base en los thresholds
function computeLevel(points) {
  const maxIdx = LEVEL_THRESHOLDS.length - 1; // idx 0..9 (niveles 1..10)
  // Encuentra el mayor threshold <= points
  let idx = 0;
  for (let i = maxIdx; i >= 0; i--) {
    if (points >= LEVEL_THRESHOLDS[i]) { idx = i; break; }
  }

  const level = idx + 1; // 1..10
  const currentThreshold = LEVEL_THRESHOLDS[idx];
  const nextThreshold = idx < maxIdx ? LEVEL_THRESHOLDS[idx + 1] : null;

  // Progreso 0..1 entre current y next; si estás en el último nivel, 1
  const progress = nextThreshold
    ? Math.max(0, Math.min(1, (points - currentThreshold) / (nextThreshold - currentThreshold)))
    : 1;

  return { level, currentThreshold, nextThreshold, progress };
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

  const totalProgressPoints = getTotalProgressPoints(results); 
  const { level, currentThreshold, nextThreshold, progress } = computeLevel(totalProgressPoints);

  return { summary: { totalSessions, totalAnswers, avgScore, totalProgressPoints, level,
    levelProgress: Number(progress.toFixed(2)), currentThreshold, nextThreshold }, categories };
}