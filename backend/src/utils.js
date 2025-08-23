import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Para resolver rutas absolutas
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, '../data');

// Función para leer un archivo JSON
export function readJson(filename) {
  const filePath = path.join(dataDir, filename);
  if (!fs.existsSync(filePath)) {
    console.warn(`⚠️ Archivo ${filename} no encontrado en /data, creando vacío.`);
    return [];
  }
  const content = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(content);
}

// Función para escribir datos en un archivo JSON
export function writeJson(filename, data) {
  const filePath = path.join(dataDir, filename);
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}
