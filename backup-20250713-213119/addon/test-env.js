require('dotenv').config({ 
    path: process.env.NODE_ENV === 'development' ? '.env.development' : '.env' 
});

console.log('Environment variables:');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('TODOIST_API_TOKEN:', process.env.TODOIST_API_TOKEN ? 'Present (' + process.env.TODOIST_API_TOKEN.length + ' chars)' : 'Missing');
console.log('LOG_LEVEL:', process.env.LOG_LEVEL);
