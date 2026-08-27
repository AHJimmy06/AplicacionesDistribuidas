# CRUD distribuido de productos

Repositorio compartido que contiene la API ASP.NET Core y la aplicación Flutter. Cada integrante puede ejecutar cualquiera de los dos proyectos para intercambiar los roles de servidor y cliente.

## Proyectos

- `ProgramacionDisrtibuidaC`: API REST conectada a SQL Server.
- `app_001_ad`: aplicación Flutter que consume la API.

No se guardan dependencias ni resultados de compilación en GitHub. .NET restaura los paquetes desde el archivo `.csproj` y Flutter desde `pubspec.yaml`.

## Preparar la API

1. Ejecutar `ProgramacionDisrtibuidaC/SQLQuery1.sql` en SQL Server.
2. Copiar `ProgramacionDisrtibuidaC/appsettings.Development.example.json` como `appsettings.Development.json`.
3. Configurar en el archivo copiado el nombre de la instancia y las credenciales locales.
4. Ejecutar:

   ```powershell
   dotnet restore
   dotnet run --launch-profile http
   ```

Los comandos deben ejecutarse dentro de `ProgramacionDisrtibuidaC`.

## Preparar Flutter

Dentro de `app_001_ad`, ejecutar:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5156
```

Los dos equipos deben estar conectados a la misma red. La guía de firewall y comprobación de conectividad se encuentra en `app_001_ad/README.md`.

## Intercambiar roles

Para cambiar quién actúa como servidor:

1. Detener la API del primer equipo.
2. Preparar SQL Server y ejecutar la API en el segundo equipo.
3. Consultar la nueva IPv4 con `ipconfig`.
4. Reiniciar Flutter en el primer equipo utilizando la nueva dirección en `API_BASE_URL`.

Cada SQL Server mantiene su propia copia de los datos. El script crea la estructura de la tabla, no sincroniza registros entre los equipos.
