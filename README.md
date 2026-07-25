# horus-shell

Shell de escritorio para niri, construida sobre quickshell.

No es una reescritura de Noctalia: es una canibalizacion incremental. Ambas
corren en paralelo como instancias separadas de quickshell, y cada modulo que
llega aqui apaga el equivalente de alla. El objetivo de fondo es dejar de
depender de un fork pinneado de noctalia-qs.

## Estado

Implementado:

- **OSD unificado.** Una sola capsula multiplexa brillo del teclado, brillo de
  pantalla, volumen de salida y microfono. El OSD de Noctalia esta apagado por
  completo. Un solo componente y no varios porque todos ocupan el mismo punto
  de la pantalla: dos capsulas simultaneas se encimarian.

Fuentes de datos: sysfs con sondeo de 120ms para los brillos (no emite
inotify) y Quickshell.Services.Pipewire con eventos reales para el audio.

Parked:

- **Perfil de energia.** Noctalia lo anuncia con `ToastService.showNotice` sin
  gate de configuracion, asi que no es apagable. Vuelve cuando la barra migre.

## Tema

Los colores salen de `~/.config/horus/palette.json`, que genera `horus-theme`
en cada cambio de tema. El QML lo relee cada 2s y conserva la paleta anterior
si el JSON se lee a medio escribir.

## Desarrollo

Corre como servicio de usuario (`Restart=always`, definido en horus-nix):

    systemctl --user restart horus-shell
    journalctl --user -u horus-shell -f

El servicio ejecuta `qs -p` sobre este directorio, asi que el hot reload sigue
funcionando: guardar el archivo basta. Para iterar fuera del servicio:

    systemctl --user stop horus-shell
    qs -p ~/horus-shell/shell.qml

## Notas de compatibilidad

La version de quickshell en uso no tiene `blockLoadingUntilLoaded` ni
`printErrors` en `FileView`.
