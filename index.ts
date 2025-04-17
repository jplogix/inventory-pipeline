import fs from 'node:fs/promises';
import path from 'node:path';
import { watch } from 'chokidar';
import pg from 'pg';
import { z } from 'zod';
import { Hono } from 'hono';

// Define schema for inventory items based on FinaleInventory format
// You'll need to adjust this schema based on your actual data structure
const InventoryItemSchema = z.object({
  id: z.string(),
  sku: z.string(),
  name: z.string(),
  quantity: z.number(),
  price: z.number().optional(),
  location: z.string().optional(),
  // Add other fields as needed
});

type InventoryItem = z.infer<typeof InventoryItemSchema>;

// Connection to PostgreSQL
const pool = new pg.Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Initialize Hono for a simple status API
const app = new Hono();
app.get('/', (c) => {
  return c.json({ status: 'running' });
});

app.get('/status', async (c) => {
  try {
    const client = await pool.connect();
    client.release();
    return c.json({ 
      status: 'ok',
      database: 'connected',
      watching: process.env.WATCH_DIRECTORY
    });
  } catch (err) {
    return c.json({ 
      status: 'error',
      message: err instanceof Error ? err.message : 'Unknown error'
    }, 500);
  }
});

// Function to process JSON file
async function processFile(filePath: string): Promise<void> {
  console.log(`Processing file: ${filePath}`);
  
  try {
    // Read file content
    const content = await fs.readFile(filePath, 'utf-8');
    const data = JSON.parse(content);
    
    // Begin transaction
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Process items based on your data structure
      if (Array.isArray(data)) {
        for (const item of data) {
          try {
            // Validate with zod
            const validItem = InventoryItemSchema.parse(item);
            
            // Insert or update in the database
            await client.query(
              `INSERT INTO inventory_items 
               (id, sku, name, quantity, price, location, updated_at) 
               VALUES ($1, $2, $3, $4, $5, $6, NOW())
               ON CONFLICT (id) DO UPDATE 
               SET sku = $2, name = $3, quantity = $4, price = $5, location = $6, updated_at = NOW()`,
              [
                validItem.id,
                validItem.sku,
                validItem.name,
                validItem.quantity,
                validItem.price || 0,
                validItem.location || '',
              ]
            );
          } catch (itemError) {
            console.error('Invalid item data:', item, itemError);
            // Continue with other items even if one fails
          }
        }
      }
      
      await client.query('COMMIT');
      console.log(`Successfully processed ${filePath}`);
      
      // Move file to processed directory
      const processedDir = path.join(path.dirname(filePath), 'processed');
      await fs.mkdir(processedDir, { recursive: true });
      
      const fileName = path.basename(filePath);
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const newPath = path.join(processedDir, `${timestamp}_${fileName}`);
      
      await fs.rename(filePath, newPath);
      
    } catch (transactionError) {
      await client.query('ROLLBACK');
      console.error('Transaction failed:', transactionError);
    } finally {
      client.release();
    }
    
  } catch (error) {
    console.error(`Error processing file ${filePath}:`, error);
  }
}

// Initialize database
async function initDb(): Promise<void> {
  const client = await pool.connect();
  
  try {
    // Create tables if they don't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS inventory_items (
        id TEXT PRIMARY KEY,
        sku TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        price NUMERIC(10, 2),
        location TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_inventory_items_sku ON inventory_items(sku);
    `);
    
    console.log('Database initialized');
  } catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  } finally {
    client.release();
  }
}

// Setup file watcher
function setupWatcher(): void {
  const watchDir = process.env.WATCH_DIRECTORY || '/app/uploads';
  console.log(`Watching directory: ${watchDir}`);
  
  // Ignore processed directory and any temporary files
  const watcher = watch(watchDir, {
    ignored: [
      /(^|[/\\])\../, // dotfiles
      /processed/,    // processed directory
      /.*\.tmp$/      // temporary files
    ],
    persistent: true,
    awaitWriteFinish: {
      stabilityThreshold: 2000,
      pollInterval: 100
    }
  });
  
  watcher.on('add', async (filePath) => {
    if (filePath.endsWith('.json')) {
      await processFile(filePath);
    }
  });
  
  watcher.on('error', (error) => {
    console.error('Watcher error:', error);
  });
  
  console.log('File watcher initialized');
}

// Start server and initialize
async function start(): Promise<void> {
  try {
    await initDb();
    setupWatcher();

    // Start API server
    console.log(`Starting API server`);
    app.fire();
  } catch (error) {
    console.error('Error starting application:', error);
    process.exit(1);
  }
}

start();