# Aplicación de productos

Aplicación Flutter que consume el CRUD de productos de la API ASP.NET Core.

La pantalla principal usa un selector `Todos/Activos/Inactivos`. Al cambiar la selección, Flutter vuelve a consultar la API y muestra en la tabla los productos del estado elegido. La tabla ocupa todo el ancho disponible y conserva desplazamiento horizontal cuando las columnas necesitan más espacio.

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

La API escucha en `http://0.0.0.0:5050`. La IPv4 del servidor puede cambiar al conectarse a otra red, por lo que debe consultarse con `ipconfig`.

### Equipo cliente

1. Verificar desde el navegador que responde `http://IP_DEL_SERVIDOR:5050/swagger`.
2. Ejecutar Flutter indicando la dirección del servidor:

   ```powershell
   flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:5050
   ```

Para un celular físico u otro equipo siempre se debe indicar la IP del servidor mediante `API_BASE_URL`.

## Verificación funcional

1. Listar los productos existentes.
2. Crear un producto válido y comprobar el mensaje de éxito.
3. Intentar crear datos vacíos, precio no positivo o stock negativo y comprobar las validaciones.
4. Editar un producto y comprobar que la lista se actualiza.
5. Activar y desactivar un producto desde la tabla y comprobar el cambio en SQL Server.
6. Cancelar una eliminación y comprobar que el producto permanece.
7. Confirmar una eliminación y comprobar el mensaje y la lista actualizada.
8. Abrir el mismo producto en dos clientes, guardar en el primero e intentar guardar en el segundo para comprobar el control mediante `Version`.
9. Detener la API e intentar una operación para comprobar el mensaje de error.

El formulario bloquea los caracteres inválidos mientras se escribe o pega y muestra las validaciones en español durante la interacción:

- Nombre: obligatorio, entre 2 y 200 letras, sin números, espacios, emojis ni símbolos.
- Precio: obligatorio, mayor que cero, máximo `99999999,99` y hasta 2 decimales.
- Stock: obligatorio, entero y no negativo.
- Descripción: obligatoria y de máximo 500 caracteres.
- URL de imagen: obligatoria, de máximo 2048 caracteres y con esquema `http://` o `https://`; no se cargan archivos.
- Activo: se selecciona con un interruptor y también puede cambiarse directamente desde la tabla.

La API repite estas validaciones como segunda barrera.

Los diálogos de confirmación y concurrencia se cierran automáticamente después de cuatro segundos. Si otro cliente modificó o eliminó un producto, Flutter informa el conflicto, cierra el formulario y recarga la tabla con los datos actuales.
