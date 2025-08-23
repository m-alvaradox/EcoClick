import { readJson, writeJson } from './utils.js';

export const answers = []; //respuestas de juego (sesiones)

// Users
export const leerUsers = () => readJson('users.json');
export const guardarUsers = (data) => writeJson('users.json', data);

// Quizzes
export const leerQuizzes = () => readJson('quizzes.json');
export const guardarQuizzes = (data) => writeJson('quizzes.json', data);

// EcoFeedback
export const ecoFeedback = () => readJson('ecoFeedback.json');
export const guardarEcoFeedback = (data) => writeJson('ecoFeedback.json', data);

// Achievements
export const leerAchievements = () => readJson('achievements.json');
export const guardarAchievements = (data) => writeJson('achievements.json', data);

// UserAchievements
export const leerUserAchievements = () => readJson('userAchievements.json');
export const guardarUserAchievements = (data) => writeJson('userAchievements.json', data);

// Progress
export const leerProgress = () => readJson('progress.json');  
export const guardarProgress = (data) => writeJson('progress.json', data);



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