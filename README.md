# Inventory Management System

Una aplicación web progresiva (PWA) para gestión de inventario desarrollada con Node.js, Express, PostgreSQL y React.

## 📋 Descripción

Sistema de gestión de inventario que permite crear, leer, actualizar y eliminar productos. La aplicación incluye funcionalidades para administrar el inventario con categorías, cantidades, precios y descripciones de productos.

## 🚀 Características

- **CRUD completo**: Crear, leer, actualizar y eliminar productos
- **Dashboard con estadísticas**: Total de productos, items, categorías y valor del inventario
- **Interfaz responsiva**: Diseño optimizado para dispositivos móviles y escritorio
- **PWA**: Funciona offline y se puede instalar como aplicación nativa
- **API RESTful**: Backend con endpoints bien estructurados
- **Base de datos PostgreSQL**: Base de datos robusta y escalable

## 🛠️ Tecnologías Utilizadas

### Backend
- Node.js
- Express.js
- PostgreSQL
- CORS

### Frontend
- React 18
- Tailwind CSS
- Font Awesome
- Service Worker (PWA)

## � Instalación

### Prerrequisitos
- Node.js (v14 o superior)
- PostgreSQL (v12 o superior) **- Solo para producción**
- npm o yarn

### Pasos de instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/inventory-ing-de-sw.git
   cd inventory-ing-de-sw
   ```

2. **Instalar dependencias**
   ```bash
   npm install
   ```

### 🔧 Opciones de Ejecución

#### **Opción A: Desarrollo Local (Sin PostgreSQL)**

Para pruebas rápidas sin configurar PostgreSQL:

```bash
# Usar el servidor de desarrollo con base de datos en memoria
npm run dev-local
```

La aplicación estará disponible en `http://localhost:3000`

#### **Opción B: Producción (Con PostgreSQL)**

3. **Configurar la base de datos PostgreSQL**
   
   Crear una base de datos PostgreSQL:
   ```sql
   CREATE DATABASE inventory_db;
   ```

4. **Configurar variables de entorno**
   
   Crear un archivo `.env` en la raíz del proyecto:
   ```
   PORT=80
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=inventory_db
   DB_USER=tu_usuario
   DB_PASSWORD=tu_password
   ```

5. **Ejecutar la aplicación**
   ```bash
   npm start
   ```

   La aplicación estará disponible en `http://localhost:80`

### 🔄 Cambiar entre Versiones

El archivo `server.js` incluye ambas configuraciones:

- **PostgreSQL (Activa)**: Para producción y despliegue
- **En Memoria (Comentada)**: Para desarrollo local sin PostgreSQL

Para usar la versión en memoria:
1. Comenta la sección "POSTGRESQL VERSION" 
2. Descomenta la sección "IN-MEMORY VERSION"
3. Reinicia el servidor

## 🔧 Configuración para Desarrollo

Para desarrollo local, puedes usar:

```bash
npm run dev
```

Esto iniciará la aplicación con nodemon para reinicio automático.

## 📚 API Endpoints

### Productos

| Método | Endpoint | Descripción |
|---------|----------|-------------|
| GET | `/api/products` | Obtener todos los productos |
| GET | `/api/products/:id` | Obtener un producto específico |
| POST | `/api/products` | Crear un nuevo producto |
| PUT | `/api/products/:id` | Actualizar un producto |
| DELETE | `/api/products/:id` | Eliminar un producto |

### Estadísticas

| Método | Endpoint | Descripción |
|---------|----------|-------------|
| GET | `/api/stats` | Obtener estadísticas del inventario |

### Ejemplo de estructura de producto

```json
{
  "name": "Laptop Pro",
  "category": "Electronics",
  "quantity": 15,
  "price": 1299.99,
  "description": "High-performance laptop"
}
```

## 🌐 Despliegue en la Nube

Este proyecto está preparado para ser desplegado en AWS mediante diferentes métodos:

### 1. Despliegue Manual en EC2
- Configuración manual de instancia EC2
- Instalación de dependencias paso a paso
- Configuración de PostgreSQL
- Configuración de puertos y seguridad

### 2. Despliegue con AWS CLI
- Automatización mediante scripts de AWS CLI
- Configuración de instancias desde línea de comandos
- Despliegue automatizado de la aplicación

### 3. Despliegue con Elastic Beanstalk
- Despliegue simplificado con manejo automático de infraestructura
- Escalado automático
- Monitoreo integrado

### Variables de entorno para producción

Para despliegue en producción, asegúrate de configurar las siguientes variables:

```
NODE_ENV=production
PORT=80
DB_HOST=tu-rds-endpoint
DB_PORT=5432
DB_NAME=inventory_db
DB_USER=tu_usuario_prod
DB_PASSWORD=tu_password_prod
```

## 📁 Estructura del Proyecto

```
inventory-ing-de-sw/
├── public/
│   ├── app.js          # Aplicación React
│   ├── index.html      # Página principal
│   ├── manifest.json   # Configuración PWA
│   └── sw.js          # Service Worker
├── server.js          # Servidor Express
├── package.json       # Dependencias y scripts
├── README.md         # Documentación
└── LICENSE           # Licencia del proyecto
```

## 🔒 Seguridad

- Validación de datos en el backend
- Sanitización de inputs
- CORS configurado
- Variables de entorno para información sensible

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia ISC. Ver el archivo `LICENSE` para más detalles.

## 👥 Autores

- **Equipo de Desarrollo** - Consultora de Software

## 🆘 Soporte

Si tienes problemas o preguntas:

1. Revisa la documentación
2. Verifica que PostgreSQL esté ejecutándose
3. Asegúrate de que las variables de entorno estén configuradas correctamente
4. Revisa los logs del servidor para errores específicos

## 📋 Notas de Desarrollo

### Cambios Realizados

1. **Puerto de ejecución**: Cambiado de 3001 a 80 para compatibilidad con despliegues web estándar
2. **Base de datos**: Migrado de SQLite a PostgreSQL para mayor robustez en producción
3. **Configuración de entorno**: Agregado soporte para variables de entorno
4. **Documentación**: README completo con instrucciones de instalación y despliegue

### Próximas Mejoras

- [ ] Autenticación y autorización de usuarios
- [ ] Paginación en listado de productos
- [ ] Filtros y búsqueda avanzada
- [ ] Exportación de datos a CSV/PDF
- [ ] Notificaciones push
- [ ] Modo offline mejorado