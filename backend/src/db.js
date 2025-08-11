import fs from 'fs';
import path from 'path';

const dataDir = path.join(process.cwd(), 'data');

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
