# 🚀 Guía Paso a Paso para Ejecutar RifaDorada

## Requisitos Previos

### 1. Instalar Node.js (necesario para Flutter)
1. Ve a: https://nodejs.org/
2. Descarga la versión "LTS" (Recomendada)
3. Ejecuta el archivo descargado
4. En la instalación, marca ✓ "Add to PATH"
5. Finaliza la instalación

### 2. Instalar Git
1. Ve a: https://git-scm.com/
2. Descarga la versión para tu sistema
3. Instala con opciones por defecto

---

## Paso 1: Instalar Flutter

### Windows:
1. Ve a: https://docs.flutter.dev/get-started/install/windows
2. Descarga el archivo "flutter_windows_3.x.x_stable.zip"
3. Crea una carpeta en `C:\src\flutter` (debes crear la carpeta "src" primero)
4. Extrae el contenido del ZIP dentro de `C:\src\flutter`
5. **Agregar Flutter al PATH:**
   - Presiona `Windows + R`, escribe `sysdm.cpl`, Enter
   - Ve a "Opciones avanzadas" → "Variables de entorno"
   - En "Variables del sistema", busca "Path", selecciónalo y click en "Editar"
   - Click en "Nuevo" y agrega: `C:\src\flutter\bin`
   - Aceptar todo

### Verificar instalación:
Abre una **nueva** terminal (PowerShell o CMD) y escribe:
```
flutter --version
```
Debería mostrar algo como "Flutter 3.x.x"

---

## Paso 2: Preparar el Proyecto

### Opción A: Descargar el código (recomendado)
1. Ve a la carpeta donde tienes el proyecto RifaDorada
2. Asegúrate de tener todos los archivos creados
3. Abre una terminal en esa carpeta

### Opción B: Si tienes el código en Git
```bash
git clone <URL-del-repositorio>
cd Rifa
```

---

## Paso 3: Obtener Dependencias

En la terminal, dentro de la carpeta del proyecto, ejecuta:

```bash
flutter pub get
```

Esto descargará todas las librerías necesarias.

---

## Paso 4: Ejecutar la Aplicación

### Para ejecutar en celular Android:
1. Conecta tu celular al PC mediante USB
2. En el celular, habilita "Depuración USB" (en opciones de desarrollador)
3. En la terminal ejecuta:
   ```bash
   flutter run
   ```

### Para ejecutar en emulador Android:
1. Descarga Android Studio: https://developer.android.com/studio
2. Instálalo y abre "Device Manager"
3. Crea un emulador (celular virtual)
4. En terminal ejecuta:
   ```bash
   flutter run -d <nombre-emulador>
   ```

### Para ejecutar en navegador (más fácil):
```bash
flutter run -d chrome
```

---

## 🔧 Solución de Problemas

### "Flutter no se reconoce como comando"
- Cierra la terminal y ábrela de nuevo
- Verifica que agregaste la ruta correctamente al PATH

### "Error de permisos"
- En Windows, ejecuta la terminal como Administrador

### "No encuentra el SDK"
- Ejecuta: `flutter doctor`
- Te mostrará qué falta instalar

---

## 📱 Primera vez que uses la app

1. La app iniciara en la pantalla de INICIO
2. Verás rifas de ejemplo (puedes crear nuevas)
3. Toca una rifa para ver los números
4. Selecciona números disponibles (verde)
5. Toca "Continuar" para registrar un participante
6. Completa el formulario y confirma

---

## 📞 Ayuda Adicional

Si tienes errores, copia el mensaje de error y busca en:
- https://stackoverflow.com/
- https://github.com/flutter/flutter/issues

¡Listo! 🎉