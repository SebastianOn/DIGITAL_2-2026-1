# 📂 Estructura del Proyecto

A continuación se describe la función de cada archivo que compone el proyecto.

## 📄 Documentación

### README.md
Contiene la documentación principal del proyecto, incluyendo la descripción general, la estructura de los módulos, instrucciones de simulación, síntesis y programación de la FPGA.

---

## 📁 Módulos RTL (Verilog)

### top.v
Módulo principal del diseño. Se encarga de integrar todos los componentes del sistema y establecer la comunicación con la FPGA Colorlight i9.

### ws2812_matrix8x8.v
Implementa el controlador de la matriz de LEDs 8×8. Administra la lectura de la memoria de imagen y envía los datos correspondientes a cada píxel.

### ws2812_led.v
Implementa el serializador encargado de transmitir los 24 bits (formato GRB) requeridos por cada LED WS2812.

### ws2812_timer.v
Genera las señales de temporización del protocolo WS2812, asegurando que los tiempos de transmisión cumplan con las especificaciones del dispositivo.

---

## 📁 Archivos de Imagen

### image.hex
Archivo que almacena la imagen en formato hexadecimal. Sus datos son cargados en memoria para ser mostrados en la matriz de LEDs.

---

## 📁 Testbench

### tb_timer
Banco de pruebas utilizado para verificar que el temporizador genere correctamente los tiempos del protocolo WS2812.

### tb_led
Permite comprobar que el módulo serializador transmite correctamente los 24 bits correspondientes a cada LED.

### tb_matrix
Banco de pruebas del sistema completo. Verifica el funcionamiento del controlador de la matriz y la correcta transmisión de la información almacenada en la memoria.

---

## 📁 Archivos de Simulación

### tb_ws2812_timer.vcd
Archivo de formas de onda generado durante la simulación del temporizador. Se utiliza para analizar visualmente el comportamiento de las señales.

### tb_ws2812_led.vcd
Contiene las formas de onda obtenidas durante la simulación del módulo del LED, facilitando la verificación de la transmisión serial.

### tb_ws2812_matrix8x8.vcd
Registra las señales generadas durante la simulación del sistema completo, permitiendo comprobar el funcionamiento de toda la arquitectura.

---

## 📁 Archivos de Síntesis

### top.bit
Bitstream generado después de la síntesis e implementación. Es el archivo utilizado para programar la FPGA.

### top_out.config
Archivo de configuración generado durante el flujo de implementación y programación del dispositivo.

---

## 📁 Automatización

### Makefile
Contiene los comandos necesarios para automatizar la simulación, síntesis, implementación y programación de la FPGA, facilitando el desarrollo y las pruebas del proyecto.
