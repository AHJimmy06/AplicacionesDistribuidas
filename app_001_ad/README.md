# Aplicación de productos

Aplicación Flutter que consume el CRUD de productos de la API ASP.NET Core.

## Ejecución en la misma PC

Con la API activa en el puerto `5050`, ejecutar desde `app_001_ad`:

```powershell
flutter pub get
flutter run
```

Flutter usa `http://localhost:5050` en Windows, web y escritorio, y `http://10.0.2.2:5050` en el emulador Android. No se necesita indicar `API_BASE_URL` en estos casos.

## Prueba en red local

Los dos equipos deben estar conectados a la misma red Wi-Fi.

### Equipo servidor

1. Obtener la IPv4 del adaptador Wi-Fi:

   ```powershell
   ipconfig
   ```

2. Permitir el puerto de la API en el Firewall de Windows. Ejecutar PowerShell como administrador:

   ```powershell
   New-NetFirewallRule -DisplayName "API Productos 5050" -Direction Inbound -Protocol TCP -LocalPort 5050 -RemoteAddress LocalSubnet -Action Allow
   ```

3. Iniciar la API desde `ProgramacionDisrtibuidaC`:

   ```powershell
   dotnet run --urls "http://0.0.0.0:5050"
   ```

La API escucha en `http://0.0.0.0:5050`. En este equipo la IPv4 actual es `192.168.100.132`, pero puede cambiar al conectarse a otra red.

### Equipo cliente

1. Verificar desde el navegador que responde `http://IP_DEL_SERVIDOR:5050/swagger`.
2. Ejecutar Flutter indicando la dirección del servidor:

   ```powershell
   flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5050
   ```

Ejemplo con la IP actual:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.100.132:5050
```

Para un celular físico u otro equipo siempre se debe indicar la IP del servidor mediante `API_BASE_URL`.

## Verificación funcional

1. Listar los productos existentes.
2. Crear un producto válido y comprobar el mensaje de éxito.
3. Intentar crear datos vacíos, precio no positivo o stock negativo y comprobar las validaciones.
4. Editar un producto y comprobar que la lista se actualiza.
5. Cancelar una eliminación y comprobar que el producto permanece.
6. Confirmar una eliminación y comprobar el mensaje y la lista actualizada.
7. Detener la API e intentar una operación para comprobar el mensaje de error.

No se requiere modificar la base de datos para ejecutar estos cambios. La API valida que `Name` tenga entre 2 y 200 caracteres, `Price` sea mayor que cero y compatible con `decimal(10,2)`, y `Stock` no sea negativo.
