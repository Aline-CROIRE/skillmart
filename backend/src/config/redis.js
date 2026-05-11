const Redis = require('ioredis');

const redisConfig = {
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  password: process.env.REDIS_PASSWORD,
  tls: {}, 
  maxRetriesPerRequest: null,
};

const connection = new Redis(redisConfig);

connection.on('connect', () => {
  console.log('Backend connected to Upstash Redis');
});

connection.on('error', (err) => {
  console.error('Redis Connection Error:', err);
});

module.exports = connection;