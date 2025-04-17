const fs = require('fs');
const path = require('path');
const chokidar = require('chokidar');
const { Pool } = require('pg');
const express = require('express');

// Create Express app for status endpoint
const app = express();
const port = process.env.PROCESSOR_PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Directory to watch for new files
const watchDirectory = process.env.WATCH_DIRECTORY || '/app/uploads';
console.log(`Watching directory: ${watchDirectory}`);

// Set up file watcher
const watcher = chokidar.watch(watchDirectory, {
  persistent: true,
  ignoreInitial: false,
  awaitWriteFinish: {
    stabilityThreshold: 2000,
    pollInterval: 100
  }
});

// Process a file when detected
async function processFile(filePath) {
  const fileName = path.basename(filePath);
  console.log(`Processing file: ${fileName}`);

  try {
    // Read file content
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Process file content according to your needs
    // This is a placeholder for your actual processing logic
    console.log(`File ${fileName} content length: ${content.length}`);
    
    // Example: Store file info in database
    await pool.query(
      'INSERT INTO file_processing (filename, processed_at, status) VALUES ($1, NOW(), $2) ON CONFLICT (filename) DO UPDATE SET processed_at = NOW(), status = $2',
      [fileName, 'processed']
    );
    
    console.log(`File ${fileName} processed successfully`);
  } catch (error) {
    console.error(`Error processing file ${fileName}:`, error);
  }
}

// File watcher events
watcher
  .on('add', filePath => {
    console.log(`New file detected: ${filePath}`);
    processFile(filePath);
  })
  .on('change', filePath => {
    console.log(`File changed: ${filePath}`);
    processFile(filePath);
  })
  .on('error', error => {
    console.error(`Watcher error: ${error}`);
  });

// Health check endpoint
app.get('/status', (req, res) => {
  res.status(200).send({ status: 'ok' });
});

// Start the server
app.listen(port, () => {
  console.log(`Health check server listening at http://localhost:${port}`);
});

console.log('File processor service started');
