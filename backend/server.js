import app from './src/app.js';
import { env } from './src/config/env.js';
import { logger } from './src/utils/logger.js';

const PORT = env.PORT;

app.listen(PORT, () => {
  logger.info(`🚀 Quiver Lux Backend running in [${env.NODE_ENV}] mode on port ${PORT}`);
});