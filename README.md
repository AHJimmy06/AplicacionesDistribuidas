# CRUD distribuido de productos

Repositorio compartido que contiene una API ASP.NET Core, una aplicación Flutter y un script para crear la base de datos en SQL Server. Cada integrante puede ejecutar cualquiera de los dos proyectos para intercambiar los roles de servidor y cliente.

## Proyectos

- `ProgramacionDisrtibuidaC`: API REST conectada a SQL Server.
- `app_001_ad`: aplicación Flutter que consume la API.
- `SQLQuery1.sql`: creación de la base de datos `AppDistribuidas_2026_DB` y la tabla `dbo.Product` en SQL Server.

No se guardan dependencias ni resultados de compilación en GitHub. .NET restaura los paquetes desde el archivo `.csproj` y Flutter desde `pubspec.yaml`.

## Preparar la API

1. Ejecutar `SQLQuery1.sql` en SQL Server Management Studio o Azure Data Studio.
2. Copiar `ProgramacionDisrtibuidaC/appsettings.Development.example.json` como `appsettings.Development.json`.
3. Configurar en el archivo copiado el nombre de la instancia y las credenciales locales.
4. Ejecutar:

   ```powershell
   dotnet restore
   dotnet run --urls "http://0.0.0.0:5050"
   ```

Los comandos deben ejecutarse dentro de `ProgramacionDisrtibuidaC`.

## Preparar Flutter

Dentro de `app_001_ad`, ejecutar:

```powershell
flutter pub get
flutter run
```

Los dos equipos deben estar conectados a la misma red. La guía de firewall y comprobación de conectividad se encuentra en `app_001_ad/README.md`.

## Intercambiar roles

Para cambiar quién actúa como servidor:

1. Detener la API del primer equipo.
2. Preparar SQL Server y ejecutar la API en el segundo equipo.
3. Consultar la nueva IPv4 con `ipconfig`.
4. Reiniciar Flutter en el primer equipo con `flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5050`.

Cada SQL Server mantiene su propia copia de los datos. El script crea la estructura de la tabla, no sincroniza registros entre los equipos.
