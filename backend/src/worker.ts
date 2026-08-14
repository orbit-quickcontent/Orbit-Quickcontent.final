import { initWorkers } from './services/queue.service';
import { logger } from './lib/logger';

// Standalone worker process (can be run separately for scaling)
logger.info('🚀 Starting ORBIT BullMQ Workers...');
initWorkers();
logger.info('✅ Workers running. Waiting for jobs...');

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received — shutting down workers gracefully');
  process.exit(0);
});
