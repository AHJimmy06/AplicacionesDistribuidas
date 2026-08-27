# API de productos

API ASP.NET Core con SQL Server para listar, crear, actualizar y eliminar productos.

## Requisitos

- .NET SDK 10
- SQL Server
- SQL Server Management Studio o Azure Data Studio

Las dependencias NuGet no se guardan en GitHub. El SDK las descarga desde las referencias declaradas en `ProgramacionDisrtibuidaC.csproj` al ejecutar `dotnet restore` o `dotnet run`.

## Base de datos

1. Abrir `SQLQuery1.sql` en SQL Server Management Studio.
2. Conectarse a la instancia local de SQL Server.
3. Ejecutar el script completo.

El script crea `AppDistribuidas_2026_DB` y `dbo.Product` si no existen. También actualiza una tabla existente para que `Version` sea `NOT NULL` y tenga `DEFAULT (0)`.

## Conexión local

1. Copiar `appsettings.Development.example.json` como `appsettings.Development.json`.
2. Reemplazar `YOUR_SQL_SERVER` por el nombre de la instancia local, por ejemplo `localhost`, `EQUIPO\\SQLEXPRESS` o `(localdb)\\MSSQLLocalDB`.
3. Si se usa autenticación SQL Server, reemplazar `Trusted_Connection=True` por `User Id=USUARIO;Password=CONTRASENA`.

`appsettings.Development.json` está excluido por `.gitignore`, por lo que las credenciales locales no se publican.

## Ejecución

```powershell
dotnet restore
dotnet run --launch-profile http
```

La documentación Swagger queda disponible en `http://localhost:5156/swagger` y, desde otro equipo de la misma red, en `http://IP_DEL_SERVIDOR:5156/swagger`.

Para permitir el acceso desde la red, ejecutar PowerShell como administrador:

```powershell
New-NetFirewallRule -DisplayName "API Productos 5156" -Direction Inbound -Protocol TCP -LocalPort 5156 -Action Allow
```

## Control de concurrencia

SQL Server asigna `Version = 0` al crear un registro. La API incrementa el valor después de cada actualización y devuelve HTTP 409 si el cliente intenta guardar una versión antigua.
