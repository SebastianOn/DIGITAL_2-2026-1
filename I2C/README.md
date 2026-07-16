## Estructura del Repositorio

### /Codigo
Contiene las descripciones de hardware en Verilog que conforman los bloques fundamentales del bus de comunicación:

* *i2c_master.v*: Módulo principal encargado de controlar el bus. Genera la señal de reloj SCL y coordina los tiempos para las condiciones de Inicio (Start), Parada (Stop), direccionamiento de 7 bits y transferencia de datos a través de la línea SDA. Implementado mediante una máquina de estados finitos (FSM).
* *i2c_slave.v*: Módulo periférico que monitorea constantemente el bus. Responde con un bit de reconocimiento (ACK) únicamente cuando detecta su dirección asignada, permitiendo operaciones de lectura o escritura según las órdenes del maestro.
* *tb_i2c.v*: Banco de pruebas (Testbench) utilizado para interconectar los módulos maestro y esclavo en un entorno de simulación controlado. Genera los estímulos de reloj del sistema y los vectores de prueba para verificar el correcto flujo de datos.

### Archivos de Simulación y Documentación

* *i2c_sim.vcd*: Archivo de volcado de cambios de variables (Value Change Dump) generado tras ejecutar la simulación del testbench. Permite la visualización de los cronogramas y diagramas de tiempos de las señales SCL y SDA en herramientas externas como GTKWave.
* *Diagrama I2C actu.drawio.png*: Diagrama de bloques que ilustra la arquitectura de la conexión física y lógica entre los dispositivos, detallando la configuración de las líneas de colector abierto y las resistencias de pull-up indispensables para el protocolo.
* *12-Febrero_apuntes.pdf*: Documentación teórica de soporte que detalla las especificaciones de temporización, estados del protocolo y requerimientos de diseño establecidos durante las sesiones de desarrollo.
