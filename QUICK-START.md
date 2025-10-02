# Guía Rápida de Ejecución - Inventory Management System

## 🎯 **OPCIONES DISPONIBLES**

### **📱 1. DESARROLLO RÁPIDO (Recomendado para pruebas)**
```bash
npm run dev-local
```
- ✅ **Sin PostgreSQL** necesario
- ✅ **Puerto 3000**
- ✅ **Base de datos en memoria**
- ✅ **Hot reload** con nodemon
- ✅ **Datos de ejemplo** incluidos

### **🚀 2. PRODUCCIÓN (Para despliegue real)**
```bash
# Configurar PostgreSQL y variables de entorno (.env)
npm start
```
- ✅ **PostgreSQL** requerido
- ✅ **Puerto 80**
- ✅ **Base de datos persistente**
- ✅ **Configuración de producción**

## 🔧 **CONFIGURACIÓN ACTUAL**

### **Archivos Principales:**
- `server.js` - **Versión PostgreSQL ACTIVA** (producción)
- `server-dev.js` - **Versión en memoria** (desarrollo)

### **Scripts NPM:**
- `npm start` - Servidor con PostgreSQL (puerto 80)
- `npm run dev` - Servidor con PostgreSQL + nodemon
- `npm run dev-local` - Servidor en memoria (puerto 3000)

## ⚡ **CAMBIO RÁPIDO ENTRE VERSIONES**

### **Para usar Base de Datos en Memoria en server.js:**

1. **Comentar sección PostgreSQL** (líneas ~15-60):
```javascript
// ============================================================================
// CONFIGURACIÓN DE BASE DE DATOS - POSTGRESQL (PRODUCCIÓN)
// ============================================================================
// 
// const pool = new Pool({...});
// const initializeDatabase = async () => {...};
// initializeDatabase();
```

2. **Descomentar sección En Memoria** (líneas ~65-95):
```javascript
// ============================================================================
// CONFIGURACIÓN ALTERNATIVA - BASE DE DATOS EN MEMORIA (DESARROLLO)
// ============================================================================

let products = [...];
let nextId = 6;
```

3. **Comentar rutas PostgreSQL** (líneas ~100-180)
4. **Descomentar rutas En Memoria** (líneas ~185-280)

## 🌐 **ENDPOINTS DISPONIBLES**

| Endpoint | Descripción |
|----------|-------------|
| `GET /` | Aplicación principal |
| `GET /api/health` | Health check |
| `GET /api/products` | Lista de productos |
| `POST /api/products` | Crear producto |
| `PUT /api/products/:id` | Actualizar producto |
| `DELETE /api/products/:id` | Eliminar producto |
| `GET /api/stats` | Estadísticas |

## 🔍 **VERIFICACIÓN RÁPIDA**

```bash
# Verificar que funciona
curl http://localhost:3000/api/health    # Versión desarrollo
curl http://localhost:80/api/health      # Versión producción
```

## 📋 **PRÓXIMOS PASOS PARA DESPLIEGUE**

1. **Verificar funcionamiento local** ✅
2. **Configurar PostgreSQL** para producción
3. **Elegir método de despliegue AWS**:
   - Manual en EC2
   - AWS CLI automatizado
   - Elastic Beanstalk
4. **Ejecutar scripts de despliegue** en `deployment-scripts/`

---

**¡La aplicación está lista para desarrollo y producción!** 🎉