const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000; // Usar puerto 3000 para desarrollo local

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Base de datos en memoria para desarrollo local
let products = [
  {
    id: 1,
    name: 'Laptop Pro',
    category: 'Electronics',
    quantity: 15,
    price: 1299.99,
    description: 'High-performance laptop',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  },
  {
    id: 2,
    name: 'Wireless Mouse',
    category: 'Electronics',
    quantity: 45,
    price: 29.99,
    description: 'Ergonomic wireless mouse',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  },
  {
    id: 3,
    name: 'Office Chair',
    category: 'Furniture',
    quantity: 8,
    price: 199.99,
    description: 'Comfortable office chair',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  },
  {
    id: 4,
    name: 'Coffee Beans',
    category: 'Food',
    quantity: 120,
    price: 12.99,
    description: 'Premium coffee beans',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  },
  {
    id: 5,
    name: 'Notebook Set',
    category: 'Office Supplies',
    quantity: 200,
    price: 8.99,
    description: 'Pack of 3 notebooks',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }
];

let nextId = 6;

// API Routes
app.get('/api/products', (req, res) => {
  // Ordenar por fecha de creación (más recientes primero)
  const sortedProducts = products.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  res.json(sortedProducts);
});

app.get('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const product = products.find(p => p.id === id);
  
  if (!product) {
    res.status(404).json({ error: 'Product not found' });
    return;
  }
  
  res.json(product);
});

app.post('/api/products', (req, res) => {
  const { name, category, quantity, price, description } = req.body;
  
  if (!name || !category || quantity === undefined || price === undefined) {
    res.status(400).json({ error: 'Missing required fields' });
    return;
  }

  const newProduct = {
    id: nextId++,
    name,
    category,
    quantity: parseInt(quantity),
    price: parseFloat(price),
    description: description || '',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  products.push(newProduct);
  res.json({ id: newProduct.id, message: 'Product created successfully' });
});

app.put('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const { name, category, quantity, price, description } = req.body;
  
  const productIndex = products.findIndex(p => p.id === id);
  
  if (productIndex === -1) {
    res.status(404).json({ error: 'Product not found' });
    return;
  }

  products[productIndex] = {
    ...products[productIndex],
    name,
    category,
    quantity: parseInt(quantity),
    price: parseFloat(price),
    description: description || '',
    updated_at: new Date().toISOString()
  };

  res.json({ message: 'Product updated successfully' });
});

app.delete('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const productIndex = products.findIndex(p => p.id === id);
  
  if (productIndex === -1) {
    res.status(404).json({ error: 'Product not found' });
    return;
  }

  products.splice(productIndex, 1);
  res.json({ message: 'Product deleted successfully' });
});

// Dashboard stats
app.get('/api/stats', (req, res) => {
  const stats = {
    total_products: products.length,
    total_items: products.reduce((sum, p) => sum + p.quantity, 0),
    categories: new Set(products.map(p => p.category)).size,
    total_value: products.reduce((sum, p) => sum + (p.quantity * p.price), 0)
  };
  
  res.json(stats);
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    database: 'in-memory',
    message: 'Development mode - using in-memory storage',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 Open your browser at: http://localhost:${PORT}`);
  console.log(`🔧 Development mode - using in-memory database`);
  console.log(`📊 API Health check: http://localhost:${PORT}/api/health`);
});