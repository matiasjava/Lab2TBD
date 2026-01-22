Mapa Colaborativo de Sitios Turísticos

Laboratorio 1 Taller de Base de Datos
Universidad de Santiago de Chile
Grupo 5


Descripción

Red social interactiva donde los usuarios pueden descubrir, compartir y calificar sitios de interés turístico. La plataforma integra funcionalidades geoespaciales para búsquedas por ubicación, permitiendo a la comunidad colaborar en la creación de un recurso de viaje dinámico y actualizado.

Instalación y Configuración

Requisitos Previos

- Java 17 o superior (https://www.oracle.com/java/technologies/downloads/)
- PostgreSQL 14+ (https://www.postgresql.org/download/)
- Node.js 20+ (https://nodejs.org/)
- Maven 3.6+ (incluido con Spring Boot)
- Git

Clonar repositorio:

1. Abrir la Terminal (o CMD)
2. Copiar la URL del Repositorio
3. Navegar a la Carpeta donde Quieres Clonar el Repositorio
   cd /ruta/a/tu/carpeta
4. Clonar el repositorio 
   git clone https://github.com/usuario/nombre-del-repositorio.git


Configurar Base de Datos

Crear base de datos

 Conectar a PostgreSQL
psql -U postgres

Crear base de datos
CREATE DATABASE lab2tbd;

Habilitar PostGIS
\c lab2tbd
CREATE EXTENSION IF NOT EXISTS postgis;

Salir
\q

Ejecutar scripts de creación


Crear esquema completo (tablas, triggers, vistas, índices)
psql -U postgres -d lab2tbd -f SQL/tablitas.sql

Cargar datos de prueba
psql -U postgres -d lab2tbd -f SQL/CARGAR_DATOS.sql


Otra forma de hacerlo:

- iniciar pgAdmin
- En database dar click derecho, seleccionar create -> database
- Ingresar como nombre de la base de datos lab2tbd
- En lab2tbd click derecho y seleccionamos Query tool
- Una vez aqui copiamos y pegamos el contenido de tablitas.sql
- Luego copiamos y pegamos en query tool tambien el contenido de CARGAR_DATOS.sql

Verificar instalación

Verificar tablas creadas
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';

Verificar datos cargados
SELECT COUNT(*) FROM usuarios;      -- Debe retornar 10
SELECT COUNT(*) FROM sitios_turisticos; -- Debe retornar 25

Configurar Backend

Configurar application.properties

Editar Backend/src/main/resources/application.properties:

properties
Configuración de base de datos
spring.datasource.url=jdbc:postgresql://localhost:5432/lab2tbd
spring.datasource.username=postgres
spring.datasource.password=admin

JWT Configuration
jwt.secret=clave_del_backend
jwt.expiration=86400000

Puerto del servidor
server.port=8090

Compilar y ejecutar

El backend estará disponible en: `http://localhost:8090`

Configurar Frontend

cd FrontEnd
 Instalar dependencias
npm install

Ejecutar servidor de desarrollo
npm run dev

La aplicación estará disponible en: `http://localhost:5173`

---
Usuarios de Prueba

correo ana@tbd.cl
correo bruno@tbd.cl

Los datos de prueba incluyen 10 usuarios con contraseña `password123`:

Contraseña para todos:password123

---

Uso de la Aplicación

Flujo de Usuario

1. Registro/Login
   - Acceder a http://localhost:5173
   - Crear cuenta o iniciar sesión con usuarios de prueba

2. Explorar Sitios
   - Ver catálogo de sitios turísticos
   - Filtrar por tipo (Parque, Museo, Restaurante, Teatro)
   - Ver detalles, fotos y reseñas

3. Contribuir
   - Escribir reseñas con calificaciones
   - Subir fotografías
   - Crear listas personalizadas

4. Interacción Social
   - Seguir a otros usuarios
   - Ver perfiles con estadísticas
   - Explorar contribuciones de la comunidad

5. Búsqueda Geoespacial (desde backend)
   SELECT * FROM buscar_sitios_cercanos(-70.6483, -33.4372, 1000);
   Busca sitios a menos de 1km de Plaza de Armas, Santiago

---


---

Solución de Problemas

Error: "Connection refused" al backend
Causa: Backend no está ejecutándose.

Solución:
cd Backend


---

Error: "relation does not exist" en PostgreSQL
Causa: Tablas no creadas.

Solución:

psql -U postgres -d lab2tbd -f SQL/tablitas.sql

---

Error: "Cannot find module 'axios'"

Causa: Dependencias no instaladas.

Solución:

cd FrontEnd
npm install


---

Error: "JWT token missing or invalid"

Causa: Token expirado o no enviado.

Solución:
1. Hacer login nuevamente
2. Copiar el token del response
3. Incluir en header: Authorization: Bearer <token>

---

Error: "Password incorrect" con usuarios de prueba

Causa: Datos de prueba no cargados.

Solución:

psql -U postgres -d lab2tbd -f SQL/CARGAR_DATOS.sql


Grupo 5

Integrantes:
-Cristopher Torres
-Maximiliano Ojeda
-German Peralta Huaiquiñir
-Matías Véjar
-Vladimir Vidal


Curso: Taller de Base de Datos  2-2025
Profesor: Matías Calderón
Ayudantes: Pablo Macuada, Fernando Solis

Licencia

Este proyecto es parte de un trabajo académico para la Universidad de Santiago de Chile.