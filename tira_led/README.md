# Estructura del Proyecto

A continuación se describe la función de cada archivo que compone el proyecto.
---

## Módulos RTL (Verilog)

### top.v
Módulo principal del diseño. Se encarga de integrar todos los componentes del sistema y establecer la comunicación con la FPGA Colorlight i9.

### ws2812_matrix8x8.v
Implementa el controlador de la matriz de LEDs 8×8. Administra la lectura de la memoria de imagen y envía los datos correspondientes a cada píxel.

### ws2812_led.v
Implementa el serializador encargado de transmitir los 24 bits (formato GRB) requeridos por cada LED WS2812.

### ws2812_timer.v
Genera las señales de temporización del protocolo WS2812, asegurando que los tiempos de transmisión cumplan con las especificaciones del dispositivo.

---

## Archivos de Imagen

### image.hex
Archivo que almacena la imagen en formato hexadecimal. Sus datos son cargados en memoria para ser mostrados en la matriz de LEDs.

---

## Testbench

### tb_timer
Banco de pruebas utilizado para verificar que el temporizador genere correctamente los tiempos del protocolo WS2812.

### tb_led
Permite comprobar que el módulo serializador transmite correctamente los 24 bits correspondientes a cada LED.

### tb_matrix
Banco de pruebas del sistema completo. Verifica el funcionamiento del controlador de la matriz y la correcta transmisión de la información almacenada en la memoria.
<img width="1919" height="1157" alt="simulacion_timmer" src="https://github.com/user-attachments/assets/552d886d-aac2-4213-ae9f-95e8a4be7dbf" />

---

## Archivos de Síntesis

### top.bit
Bitstream generado después de la síntesis e implementación. Es el archivo utilizado para programar la FPGA.

### top_out.config
Archivo de configuración generado durante el flujo de implementación y programación del dispositivo.

---

## Automatización

### Makefile
Contiene los comandos necesarios para automatizar la simulación, síntesis, implementación y programación de la FPGA, facilitando el desarrollo y las pruebas del proyecto.
<img width="1536" height="1536" alt="Prueba_ws2812" src="https://github.com/user-attachments/assets/5c913a4e-368b-4057-9d86-3dd34bad96c3" />

