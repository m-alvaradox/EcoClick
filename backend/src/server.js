import express from 'express';
import cors from 'cors';
import morgan from 'morgan';

const app = express();
app.use(cors());              // Permitir peticiones del front
app.use(express.json());      // Leer JSON del body
app.use(morgan('dev'));       // Logs bonitos en consola

// Endpoint de prueba
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'EcoClick API' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`✅ EcoClick backend en http://localhost:${PORT}`);
});
