# Llavero de Contraseñas Offline (Flutter)

MiniPráctica de Flutter: **llavero de contraseñas 100% offline**, pensado para prácticas de Ingeniería en Tecnologías de Cómputo y Telecomunicaciones. La app implementa un **vault cifrado local**, sin backend, donde el usuario almacena contraseñas de forma segura.

---

## Objetivo de la mini práctica

- Practicar Flutter con un proyecto más completo que las apps básicas.
- Construir una aplicación con estructura realista: UI, dominio, datos y cifrado.
- Implementar un flujo seguro:
    - Configurar *Master Password (MPW)*.
    - Desbloquear el vault.
    - Crear, editar y borrar entradas.
- Introducir conceptos de cifrado y persistencia local.

> Nota: Este proyecto es con fines educativos. No debe usarse como gestor de contraseñas en producción.

---

## Funcionalidad principal

- **Master Password**
    - Se crea la primera vez.
    - Sirve para derivar la clave que cifra el archivo.
- **Vault local (`vault.vault`)**
    - Se guarda en el directorio de documentos de la app.
    - Contiene todas las entradas cifradas.
- **CRUD de contraseñas**
    - Crear, ver, editar, eliminar.
    - Campos: servicio, usuario/correo, contraseña, notas.
- **100% Offline**
    - No usa red, servidores ni sincronización.

---

## Arquitectura del proyecto

```text
lib/
 ├─ crypto/
 │   └─ crypto_service.dart
 ├─ data/
 │   └─ vault_repository.dart
 ├─ domain/
 │   └─ models.dart
 ├─ ui/
 │   ├─ setup_screen.dart
 │   ├─ unlock_screen.dart
 │   └─ home_screen.dart
 └─ main.dart
```

## Tecnologías
 - Flutter & Dart
 - Android Studio / VS Code
 - Soporte posible para Android, iOS, Web y Desktop

## Como Ejecutar

Clonar: 

    git clone https://github.com/FlowersLoop/llavero_pass.git 
    cd llavero_pass

Instalar dependencias:

    flutter pub get

Ejecutar:

    flutter run || directo en el IDE

## Autores

Fernando Flores López (@FlowersLoop)

Santiago Tapia Reducindo