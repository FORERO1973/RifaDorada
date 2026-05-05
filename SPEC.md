# RifaDorada - Especificaciones del Proyecto

## 1. Project Overview

**Nombre del Proyecto:** RifaDorada
**Tipo de Aplicación:** Aplicación móvil multiplataforma (iOS/Android)
**Funcionalidad Principal:** Sistema completo de gestión de rifas con venta de números, registro de participantes, integración con WhatsApp y panel de administración.

## 2. Technology Stack & Choices

- **Framework:** Flutter 3.x
- **Lenguaje:** Dart 3.x
- **Backend:** Firebase (Firestore, Auth, Storage)
- **State Management:** Provider + ChangeNotifier
- **Arquitectura:** Clean Architecture (Presentation → Domain → Data)

### Dependencias Principales
- `firebase_core` - Inicialización Firebase
- `cloud_firestore` - Base de datos en tiempo real
- `firebase_auth` - Autenticación admin
- `provider` - Gestión de estado
- `url_launcher` - Apertura de URLs (WhatsApp)
- `screenshot` - Captura de imágenes
- `share_plus` - Compartir imágenes
- `path_provider` - Rutas de archivos
- `intl` - Formato de fecha y moneda COP
- `csv` - Exportación Excel/CSV
- `fl_chart` - Gráficos de estadísticas
- `google_fonts` - Tipografía moderna

## 3. Feature List

### Funcionalidades Core
1. **Gestión de Rifas**
   - Crear rifas (nombre, descripción, precio, cantidad números, tipo)
   - Editar y eliminar rifas
   - Rifas múltiples simultáneas

2. **Selector de Números**
   - Grid visual de números (00-99 o 000-999)
   - Colores diferenciados (disponible/ocupado/seleccionado)
   - Selección múltiple
   - Bloqueo automático al asignar

3. **Registro de Participantes**
   - Formulario completo (nombre, WhatsApp, ciudad, documento)
   - Selección de números
   - Estado de pago (pendiente/pagado)

4. **Integración WhatsApp**
   - Mensaje automático de confirmación
   - Compartir imagen del estado

5. **Imagen Dinámica**
   - Tablero visual de todos los números
   - Colores: disponible (verde), ocupado (dorado), seleccionado (azul)
   - Descargar imagen
   - Compartir a WhatsApp

6. **Panel de Administración**
   - CRUD completo de rifas
   - Lista de participantes
   - Marcación de pagos
   - Estadísticas: total vendido, disponibles, ganancias

7. **Configuración Colombia**
   - Moneda COP ($)
   - Separador de miles
   - Zona horaria Colombia (UTC-5)

### Funcionalidades Extra
- Exportar datos (CSV)
- Modo oscuro
- Login de administrador
- Backup automático (Firestore)

## 4. UI/UX Design Direction

### Estilo Visual
- **Tema:** Moderno, minimalista, premium (estilo fintech)
- **Enfoque:** Fondo oscuro con acentos dorados

### Color Scheme
- **Primario:** Negro (#121212)
- **Secundario:** Dorado (#D4AF37)
- **Acento:** Verde success (#4CAF50)
- **Superficie:** Gris oscuro (#1E1E1E)
- **Texto:** Blanco (#FFFFFF) / Gris claro (#B0B0B0)
- **Errores:** Rojo (#FF5252)

### Layout
- Navegación inferior (Bottom Navigation Bar)
- 4 secciones: Inicio, Rifas, Admin, Configuración
- Tarjetas con bordes redondeados
- Espaciado generoso
- Tipografía: Poppins (Google Fonts)

### Elementos UI
- Botones grandes con gradientes dorados
- Iconos Material Design
- Animaciones suaves (300ms)
- Loading states con shimmer
- Snackbar para feedback

## 5. Data Models

### Rifa
- id, nombre, descripcion, precioNumero, cantidadNumeros, tipoRifa (2/3 cifras), activa, fechaCreacion

### Participante
- id, rifaId, nombre, whatsapp, ciudad, documento, numeros[], estadoPago, fechaRegistro

### Numero
- numero, estado (disponible/ocupado), participanteId

## 6. Firebase Structure

```
/rifas/{rifaId}
  - datos de la rifa
  /participantes/{participanteId}
    - datos del participante
  /numeros/{numero}
    - estado del número
```