# CRUD distribuido de productos

Repositorio compartido que contiene una API ASP.NET Core, una aplicación Flutter y un script para crear la base de datos en SQL Server. Cada integrante puede ejecutar cualquiera de los dos proyectos para intercambiar los roles de servidor y cliente.

La aplicación no utiliza roles de usuario. Cada producto incluye nombre, precio, existencias, descripción, URL de imagen y estado activo. Flutter presenta estos datos en una tabla y permite activar o desactivar cada producto.

## Proyectos

- `ProgramacionDisrtibuidaC`: API REST conectada a SQL Server.
- `app_001_ad`: aplicación Flutter que consume la API.
- `SQLQuery1.sql`: creación de la base de datos `AppDistribuidas_2026_DB` y la tabla `dbo.Product` en SQL Server.

No se guardan dependencias ni resultados de compilación en GitHub. .NET restaura los paquetes desde el archivo `.csproj` y Flutter desde `pubspec.yaml`.

## Requisitos

- Git
- .NET SDK 10
- SQL Server
- SQL Server Management Studio o Azure Data Studio
- Flutter con un destino configurado, como Windows o un emulador Android

## Instalación después de clonar

Clonar el repositorio y entrar en su carpeta:

```powershell
git clone https://github.com/AHJimmy06/AplicacionesDistribuidas.git
cd AplicacionesDistribuidas
```

### 1. Preparar SQL Server

1. Abrir `SQLQuery1.sql` en SQL Server Management Studio o Azure Data Studio.
2. Conectarse a la instancia local de SQL Server.
3. Ejecutar el script completo.

El script crea la base de datos `AppDistribuidas_2026_DB` y la tabla `dbo.Product`.

El script también actualiza instalaciones existentes sin eliminar productos: agrega `Description`, `ImageUrl` e `IsActive`, y conserva el contador de concurrencia `Version INT`. Debe ejecutarse nuevamente después de obtener esta versión del repositorio.

### 2. Crear la configuración local de la API

Ejecutar una sola vez desde la raíz del repositorio:

```powershell
Copy-Item .\ProgramacionDisrtibuidaC\appsettings.Development.example.json .\ProgramacionDisrtibuidaC\appsettings.Development.json
```

El archivo no se genera automáticamente. Editar `ProgramacionDisrtibuidaC/appsettings.Development.json` y reemplazar `YOUR_SQL_SERVER` por la instancia local, por ejemplo `localhost`, `.\SQLEXPRESS` o `(localdb)\MSSQLLocalDB`.

`appsettings.Development.json` contiene configuración local y está excluido de Git. No debe subirse a GitHub.

### 3. Instalar y ejecutar el backend

Abrir una terminal dentro de `ProgramacionDisrtibuidaC`:

```powershell
dotnet restore
dotnet run --urls "http://0.0.0.0:5050"
```

`dotnet restore` instala automáticamente las dependencias NuGet declaradas en `ProgramacionDisrtibuidaC.csproj`. Con la API activa, Swagger queda disponible en `http://localhost:5050/swagger`.

### 4. Instalar y ejecutar el frontend

Sin cerrar la API, abrir otra terminal dentro de `app_001_ad`:

```powershell
flutter pub get
flutter run
```

`flutter pub get` instala automáticamente las dependencias declaradas en `pubspec.yaml`.

Las operaciones de creación, edición, activación, desactivación y eliminación se guardan mediante la API en SQL Server. La API comprueba `Version` al actualizar o eliminar y lo incrementa con cada modificación para impedir que un cliente sobrescriba cambios de otro.

Cada cliente Flutter vuelve a consultar la API automáticamente cada 3 segundos. De esta manera, los cambios persistidos en SQL Server aparecen en las demás pantallas sin una recarga manual. En móviles se muestran tarjetas y en pantallas amplias se utiliza la tabla completa.

Las confirmaciones y avisos modales se cierran automáticamente después de cuatro segundos. Los mensajes de éxito o error también se muestran durante cuatro segundos.

Sin definir `API_BASE_URL`, Flutter selecciona automáticamente la dirección correcta cuando la API se ejecuta en la misma PC:

| Destino de Flutter | Dirección de la API |
| --- | --- |
| Windows, web o escritorio | `http://localhost:5050` |
| Emulador Android | `http://10.0.2.2:5050` |

Un celular físico u otro equipo necesita la IP del servidor:

```powershell
flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5050
```

## Conexión desde otro equipo

Esta sección no es necesaria cuando la API y Flutter se ejecutan en la misma PC.

1. Conectar ambos equipos a la misma red.
2. Obtener la IPv4 del servidor con `ipconfig`.
3. Abrir PowerShell como administrador en el servidor y permitir el puerto para la red local:

```powershell
New-NetFirewallRule -DisplayName "API Productos 5050" -Direction Inbound -Protocol TCP -LocalPort 5050 -RemoteAddress LocalSubnet -Action Allow
```

4. Verificar desde el cliente que responde `http://IP_DEL_SERVIDOR:5050/swagger`.
5. Iniciar Flutter con la dirección del servidor:

```powershell
flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5050
```

La guía ampliada de red se encuentra en `app_001_ad/README.md`.

## Intercambiar roles

Para cambiar quién actúa como servidor:

1. Detener la API del primer equipo.
2. Preparar SQL Server y ejecutar la API en el segundo equipo.
3. Consultar la nueva IPv4 con `ipconfig`.
4. Reiniciar Flutter en el primer equipo con `flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5050`.

Cada SQL Server mantiene su propia copia de los datos. El script crea la estructura de la tabla, no sincroniza registros entre los equipos.
