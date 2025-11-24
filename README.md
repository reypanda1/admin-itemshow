# Visualizador de Items

Recurso de FiveM para QBCore que permite a los administradores visualizar y recibir items del servidor.

## Créditos

**Autor:** Rey Panda

## Dependencias

- `qb-core` (versión moderna)

## Instalación

1. Copia la carpeta `Visualisador de items` a `resources/`
2. Agrega al `server.cfg`:
```
ensure [Nombre de la carpeta donde tienes el recurso usualmente admin-itemshow]
```
Nota: Si lo metes en una carpeta declarada no es necesario añadir esto

3. Configura permisos ACE en `server.cfg`:
```
add_ace group.admin itemshow.use allow
```

O para un jugador específico:
```
add_ace identifier.steam:110000112345678 itemshow.use allow
```

4. Reinicia el servidor

## Uso

1. Ingresa al servidor como administrador
2. Escribe en el chat: `/showitems`
3. Busca el item que quieras recibir
4. Haz click en el item
5. Si el item no es único, selecciona la cantidad
6. Confirma para recibir el item

## Configuración

Edita `config.lua` para ajustar:
- Permisos ACE
- Tiempo de cooldown entre recogidas
- Modo debug

