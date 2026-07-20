# PROYECTO TECLADO PARA CALCULADORA FISICA
<img width="949" height="1961" alt="Diagrama de flujo teclado drawio" src="https://github.com/user-attachments/assets/0b8f51a1-964a-48eb-815a-8b6ed5821c98" />


## 2. Explicación paso a paso

1. **Reset — estado seguro**
   Con `reset = 1` las dos mitades vuelven a su condición inicial. La FSM queda en `START` con las cuatro filas apagadas (`r = 0000`) y `done = 1`; el datapath limpia `Antirebote`, pone `Prev_tecla = 16` (valor imposible, para que ninguna tecla real "coincida" por accidente en el primer ciclo) y `unique_flag = 0`. El módulo no barre nada todavía: espera órdenes.

2. **Espera de init**
   Mientras `init = 0`, la FSM se queda ciclando en `START`. Este es el mecanismo de arranque controlado por software: el periférico no consume actividad de barrido hasta que la CPU escribe el registro `init`. Como `done = 1` en este estado, desde afuera se lee "hay resultado disponible / módulo en reposo".

3. **Arranque del barrido**
   Cuando llega `init = 1`, pasan dos cosas en paralelo. En la FSM: transición `START` → `Row0`, y `done` cae a 0. En `data_tcl`: se carga `unique_flag = N` (4000). Ese bloqueo inicial obliga a que el teclado esté suelto y estable durante 20 ms antes de aceptar la primera pulsación — así, si el usuario todavía tiene el dedo sobre la tecla del ciclo anterior, no se relee la misma tecla dos veces.

4. **Energizar una fila**
   Cada estado `RowN` dura exactamente un ciclo: activa su fila (`R0..R3` en one-hot), memoriza cuál fila quedó activa en `prev_row` y carga el contador de asentamiento `cnt = 5`. Inmediatamente salta a `READ`. La fila sigue activa dentro de `READ` porque la lógica de salida Moore usa `prev_row` para mantenerla.

5. **Asentamiento de la fila**
   En `READ`, la FSM descuenta `cnt` de 5 a 0: seis ciclos (~30 µs a 200 kHz) con la fila energizada antes de tomar cualquier decisión. Este tiempo deja que la señal se propague por las pistas y el conector del teclado, ademas que las columnas reflejen un valor eléctrico estable.

6. **Decodificación combinacional**
   En paralelo, en cada flanco de subida, `data_tcl` evalúa el decodificador: mira qué fila está activa y qué columna llegó en alto, y produce `next_tecla` con el código de la intersección (ASCII: '1'…'9', '0', '*', '#', '/'; la tecla C da `0x13`; A y B no están mapeadas y caen al default 0). Si ninguna columna está activa, `next_tecla = 0`, que el resto del flujo interpreta como "no hay tecla".

7. **Decisión: ¿hay tecla en esta fila?**
   Terminado el asentamiento (`cnt = 0`), la FSM consulta `rd_flag_sync`, la versión sincronizada al flanco de bajada de `rd_flag`. Como `rd_flag = (Antirebote ≠ 0)`, en la práctica pregunta: "¿el datapath empezó a contar una tecla en esta fila?".

8. **Sin tecla → avanzar fila**
   Si no hay actividad, la FSM pasa al siguiente estado `Row` en secuencia circular `0` → `1` → `2` → `3` → `0` y repite los pasos del 4 al 7. Un barrido completo sin teclas toma unos 140 µs, así que el teclado se muestrea unas 7000 veces por segundo: imposible perder una pulsación humana.

9. **Filtro de relectura (unique_flag)**
   Si sí hay tecla, primero se verifica el candado. `unique_flag ≠ 0` significa "la pulsación anterior aún no se ha liberado del todo": la nueva lectura se ignora.

10. **Descarga del candado**
    El candado solo se descarga mientras `next_tecla = 0` (tecla suelta): decrementa de `N` hacia 0, exigiendo 20 ms continuos de reposo. Si en cualquier momento vuelve a detectarse una tecla, `unique_flag` se recarga a `N`. Es un antirrebote "de soltado": garantiza un evento por pulsación física, sin autorepetición.

11. **Comparación con el ciclo anterior**
    Con el candado libre, se compara `next_tecla` contra `Prev_tecla` (el valor del posedge anterior). Solo si son iguales y distintos de cero la lectura se considera "consistente" y puede acumular confianza.

12. **Rebote → reiniciar cuenta**
    Si el valor cambió entre ciclos —el contacto mecánico está rebotando— `Antirebote` vuelve a 0 y la cuenta empieza de nuevo. Los rebotes típicos de este teclado duran ~20 ms, y este mecanismo descarta todas esas transiciones espurias.

13. **Acumulación y retención de fila**
    Cada ciclo consecutivo con el mismo valor incrementa `Antirebote`. Apenas la cuenta arranca, `rd_flag = 1`, y vía `rd_flag_sync` la FSM se queda clavada en `READ` con la misma fila energizada: el barrido se congela para no interrumpir la medición de la tecla que se está validando. Este es el acople clave entre datapath y control.

14. **Umbral de estabilidad**
    Se exige `Antirebote > N`: 4000 ciclos × 5 µs = 20 ms del mismo valor ininterrumpido, calzado con la duración del rebote mecánico. Mientras no se alcance, el flujo sigue acumulando (o se reinicia si aparece un rebote, paso 12).

15. **Tecla válida — end_flag y done**
    Superado el umbral, `end_flag = 1` y la FSM salta `READ` → `START`. En `START`, `done = 1` anuncia hacia el periférico que `tecla[5:0]` contiene un código validado y estable, listo para que la CPU lo lea por el registro `0x08`.

16. **Limpieza y nuevo ciclo**
    Mientras `done = 1`, `data_tcl` limpia `Antirebote`, restaura `Prev_tecla = 16` y guarda el código en `last_tcl`. El módulo queda otra vez en el paso 2, esperando que el firmware escriba `init = 1` (y luego 0) para lanzar el siguiente barrido.

    
| Parámetro | Valor | Tiempo | Función |
| :--- | :--- | :--- | :--- |
| cnt | 5 → 0 | ≈ 30 µs | Asentamiento por fila antes de decidir avanzar. |
| N (Antirebote) | 4000 | ≈ 20 ms | Ciclos de estabilidad exigidos → end_flag. |
| unique_flag | N = 4000 | ≈ 20 ms | Tecla soltada y estable en 0 antes de aceptar otra. |
| Barrido sin tecla | 4 × ~7 ciclos | ≈ 140 µs | Vuelta completa Row0→Row3 cuando nada está presionado. |
