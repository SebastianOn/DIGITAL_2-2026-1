# Matriz WS2812 8x8 con Colorlight i9 (Verilog)

Controlador en Verilog para una matriz de 64 LEDs WS2812 usando la FPGA
Lattice ECP5 de la Colorlight i9 (reloj de 25 MHz). La imagen se carga
desde un archivo `.hex` con `$readmemh`.

## Estructura

```
rtl/ws2812_timer.v       Base de tiempos del protocolo (T0H, T1H, periodo, latch)
rtl/ws2812_led.v         Serializador de 24 bits GRB (un LED)
rtl/ws2812_matrix8x8.v   Arreglo 8x8: memoria .hex + barrido de 64 pixeles
rtl/top.v                Top-level para la Colorlight i9
tb/tb_ws2812_timer.v     TB: mide anchos de pulso de bit 0/1 y del latch
tb/tb_ws2812_led.v       TB: decodifica la trama y compara los 24 bits
tb/tb_ws2812_matrix8x8.v TB: decodifica 2 cuadros completos (64 px) vs. el .hex
img/image.hex            Imagen de ejemplo (corazon rojo)
img/png2hex.py           Conversor de PNG/JPG 8x8 a .hex (GRB)
colorlight_i9.lpf        Asignacion de pines
Makefile                 Simulacion y flujo yosys/nextpnr/ecppack
```

## Jerarquia

```
top
 └── ws2812_matrix8x8   (FSM de barrido + BRAM con la imagen)
      └── ws2812_led    (serializador de 24 bits, MSB primero)
           └── ws2812_timer (contadores de T0H/T1H/periodo/reset)
```

## Formato del .hex

64 lineas, una por LED (LED 0 = primer LED de la cadena). Cada linea es
un valor de 24 bits en hexadecimal con formato **GRB**: `GGRRBB`.
Ejemplo: verde puro = `ff0000`, rojo puro = `00ff00`, azul puro = `0000ff`.

Para generar el .hex desde una imagen:
```
python3 img/png2hex.py mi_imagen.png img/image.hex            # filas normales
python3 img/png2hex.py mi_imagen.png img/image.hex --serpentine  # zig-zag
```

## Tiempos (25 MHz -> 40 ns/ciclo)

| Simbolo | Especificacion | Implementado |
|---------|----------------|--------------|
| T0H     | 0.40 us        | 10 ciclos = 0.40 us |
| T1H     | 0.80 us        | 20 ciclos = 0.80 us |
| Periodo | ~1.25 us       | 31 ciclos = 1.24 us |
| Latch   | > 50 us        | 2500 ciclos = 100 us |

## Simulacion (Icarus Verilog)

```
make sim          # los 3 testbenches
make waves        # gtkwave del TB de la matriz
```

Cada TB imprime `TODAS LAS PRUEBAS PASARON` si todo esta bien y genera
su `.vcd` en `sim/` para inspeccionar las formas de onda.

## Sintesis 
```
make bit     # genera top.bit
make flash   # carga a la Colorlight i9
```

