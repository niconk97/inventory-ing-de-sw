const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 80;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// ============================================================================
// CONFIGURACIÓN DE BASE DE DATOS - POSTGRESQL (PRODUCCIÓN)
// ============================================================================

// PostgreSQL connection configuration
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'inventory_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

// Initialize PostgreSQL database
const initializeDatabase = async () => {
  try {
    // Create tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        category VARCHAR(255) NOT NULL,
        quantity INTEGER NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Check if we have any products, if not, insert sample data
    const { rows } = await pool.query('SELECT COUNT(*) FROM products');
    const productCount = parseInt(rows[0].count);

    if (productCount === 0) {
      // Insert sample data
      const sampleProducts = [
        ['Laptop Pro', 'Electronics', 15, 1299.99, 'High-performance laptop'],
        ['Wireless Mouse', 'Electronics', 45, 29.99, 'Ergonomic wireless mouse'],
        ['Office Chair', 'Furniture', 8, 199.99, 'Comfortable office chair'],
        ['Coffee Beans', 'Food', 120, 12.99, 'Premium coffee beans'],
        ['Notebook Set', 'Office Supplies', 200, 8.99, 'Pack of 3 notebooks']
      ];

      for (const product of sampleProducts) {
        await pool.query(
          'INSERT INTO products (name, category, quantity, price, description) VALUES ($1, $2, $3, $4, $5)',
          product
        );
      }
      console.log('Sample data inserted successfully');
    }

    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
  }
};

// Initialize database on startup
initializeDatabase();

// ============================================================================
// CONFIGURACIÓN ALTERNATIVA - BASE DE DATOS EN MEMORIA (DESARROLLO)
// ============================================================================
// 
// // Descomenta esta sección si quieres usar base de datos en memoria para desarrollo local
// // Comenta la sección de PostgreSQL arriba si usas esta opción
// 
// let products = [
//   {
//     id: 1,
//     name: 'Laptop Pro',
//     category: 'Electronics',
//     quantity: 15,
//     price: 1299.99,
//     description: 'High-performance laptop',
//     created_at: new Date().toISOString(),
//     updated_at: new Date().toISOString()
//   },
//   {
//     id: 2,
//     name: 'Wireless Mouse',
//     category: 'Electronics',
//     quantity: 45,
//     price: 29.99,
//     description: 'Ergonomic wireless mouse',
//     created_at: new Date().toISOString(),
//     updated_at: new Date().toISOString()
//   },
//   {
//     id: 3,
//     name: 'Office Chair',
//     category: 'Furniture',
//     quantity: 8,
//     price: 199.99,
//     description: 'Comfortable office chair',
//     created_at: new Date().toISOString(),
//     updated_at: new Date().toISOString()
//   },
//   {
//     id: 4,
//     name: 'Coffee Beans',
//     category: 'Food',
//     quantity: 120,
//     price: 12.99,
//     description: 'Premium coffee beans',
//     created_at: new Date().toISOString(),
//     updated_at: new Date().toISOString()
//   },
//   {
//     id: 5,
//     name: 'Notebook Set',
//     category: 'Office Supplies',
//     quantity: 200,
//     price: 8.99,
//     description: 'Pack of 3 notebooks',
//     created_at: new Date().toISOString(),
//     updated_at: new Date().toISOString()
//   }
// ];
// 
// let nextId = 6;

// ============================================================================
// API ROUTES - POSTGRESQL VERSION
// ============================================================================

// API Routes
app.get('/api/products', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM products ORDER BY created_at DESC');
    res.json(rows);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const { rows } = await pool.query('SELECT * FROM products WHERE id = $1', [id]);
    if (rows.length === 0) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    res.json(rows[0]);
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/products', async (req, res) => {
  const { name, category, quantity, price, description } = req.body;
  
  if (!name || !category || quantity === undefined || price === undefined) {
    res.status(400).json({ error: 'Missing required fields' });
    return;
  }

  try {
    const { rows } = await pool.query(
      'INSERT INTO products (name, category, quantity, price, description) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [name, category, quantity, price, description]
    );
    res.json({ id: rows[0].id, message: 'Product created successfully' });
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/products/:id', async (req, res) => {
  const { id } = req.params;
  const { name, category, quantity, price, description } = req.body;
  
  try {
    const { rowCount } = await pool.query(
      'UPDATE products SET name = $1, category = $2, quantity = $3, price = $4, description = $5, updated_at = CURRENT_TIMESTAMP WHERE id = $6',
      [name, category, quantity, price, description, id]
    );
    
    if (rowCount === 0) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    res.json({ message: 'Product updated successfully' });
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/products/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    const { rowCount } = await pool.query('DELETE FROM products WHERE id = $1', [id]);
    if (rowCount === 0) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ error: error.message });
  }
});

// Dashboard stats
app.get('/api/stats', async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT 
        COUNT(*) as total_products,
        COALESCE(SUM(quantity), 0) as total_items,
        COUNT(DISTINCT category) as categories,
        COALESCE(SUM(quantity * price), 0) as total_value
      FROM products
    `);
    res.json(rows[0]);
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// API ROUTES - IN-MEMORY VERSION (COMENTADAS)
// ============================================================================
// 
// // Descomenta estas rutas si usas la versión en memoria
// // Comenta las rutas de PostgreSQL arriba si usas esta opción
// 
// app.get('/api/products', (req, res) => {
//   const sortedProducts = products.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
//   res.json(sortedProducts);
// });
// 
// app.get('/api/products/:id', (req, res) => {
//   const id = parseInt(req.params.id);
//   const product = products.find(p => p.id === id);
//   
//   if (!product) {
//     res.status(404).json({ error: 'Product not found' });
//     return;
//   }
//   
//   res.json(product);
// });
// 
// app.post('/api/products', (req, res) => {
//   const { name, category, quantity, price, description } = req.body;
//   
//   if (!name || !category || quantity === undefined || price === undefined) {
//     res.status(400).json({ error: 'Missing required fields' });
//     return;
//   }
// 
//   const newProduct = {
//     id: nextId++,
//     name,
//     category,
//     quantity: parseInt(quantity),
//     price: parseFloat(price),
//     description: description || '',
//     created_at: new Date().toISOString(),
//     updated_at: new Date().toISOString()
//   };
// 
//   products.push(newProduct);
//   res.json({ id: newProduct.id, message: 'Product created successfully' });
// });
// 
// app.put('/api/products/:id', (req, res) => {
//   const id = parseInt(req.params.id);
//   const { name, category, quantity, price, description } = req.body;
//   
//   const productIndex = products.findIndex(p => p.id === id);
//   
//   if (productIndex === -1) {
//     res.status(404).json({ error: 'Product not found' });
//     return;
//   }
// 
//   products[productIndex] = {
//     ...products[productIndex],
//     name,
//     category,
//     quantity: parseInt(quantity),
//     price: parseFloat(price),
//     description: description || '',
//     updated_at: new Date().toISOString()
//   };
// 
//   res.json({ message: 'Product updated successfully' });
// });
// 
// app.delete('/api/products/:id', (req, res) => {
//   const id = parseInt(req.params.id);
//   const productIndex = products.findIndex(p => p.id === id);
//   
//   if (productIndex === -1) {
//     res.status(404).json({ error: 'Product not found' });
//     return;
//   }
// 
//   products.splice(productIndex, 1);
//   res.json({ message: 'Product deleted successfully' });
// });
// 
// // Dashboard stats (in-memory version)
// app.get('/api/stats', (req, res) => {
//   const stats = {
//     total_products: products.length,
//     total_items: products.reduce((sum, p) => sum + p.quantity, 0),
//     categories: new Set(products.map(p => p.category)).size,
//     total_value: products.reduce((sum, p) => sum + (p.quantity * p.price), 0)
//   };
//   
//   res.json(stats);
// });

// ============================================================================
// HEALTH CHECK Y CONFIGURACIÓN DEL SERVIDOR
// ============================================================================

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'healthy', 
      database: 'postgresql-connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'unhealthy', 
      database: 'postgresql-disconnected', 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🗄️ Database: PostgreSQL`);
  console.log(`🌐 Health check: http://localhost:${PORT}/api/health`);
  console.log(`📊 Database: ${process.env.DB_NAME || 'inventory_db'} on ${process.env.DB_HOST || 'localhost'}`);
});
