const { Queue } = require('bullmq');
const connection = require('../config/redis');

const projectQueue = new Queue('project-analysis', {
  connection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 5000,
    },
    removeOnComplete: true,
    removeOnFail: false,
  },
});

const addProjectToQueue = async (projectData) => {
  await projectQueue.add('analyze-project', projectData);
};

module.exports = { projectQueue, addProjectToQueue };