# Deploy Web — RifaDorada

## Build

```powershell
flutter build web --release
```

Los archivos se generan en `build/web/`.

## Deploy a Firebase Hosting

### 1. Instalar Firebase CLI

```powershell
npm install -g firebase-tools
```

### 2. Login

```powershell
firebase login
```

### 3. Deploy

```powershell
firebase deploy --only hosting
```

### URL resultante

```
https://rifadorada-92112.web.app
```

## URLs públicas

| URL | Descripción |
|---|---|
| `https://rifadorada-92112.web.app` | Landing page pública |
| `https://rifadorada-92112.web.app/rifa/{rifaId}` | Landing con rifa específica |
| `https://rifadorada-92112.web.app/app` | Panel de administración (requiere login) |

## Compartir con organizadores

Los organizadores pueden compartir enlaces directos:

```
https://rifadorada-92112.web.app/rifa/ABC123
```

Los clientes que abran este enlace verán directamente la rifa seleccionada con el formulario de registro.

## Deploy local (pruebas)

```powershell
# Con Python
python -m http.server 8080 --directory build\web

# Con Node.js
npx serve build\web -p 8080
```

Luego abrir: `http://localhost:8080`
