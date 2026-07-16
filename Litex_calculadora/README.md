# Calculadora en LiteX

## Descripción

En este proyecto se desarrolló una calculadora digital utilizando LiteX y módulos escritos en Verilog. El objetivo fue integrar diferentes operaciones aritméticas dentro de un mismo sistema y comprobar su funcionamiento mediante simulaciones antes de implementarlo en la FPGA.

El proyecto está dividido en varios módulos, donde cada uno cumple una función específica dentro de la calculadora.

---

# Organización del proyecto

La estructura del proyecto está organizada en varias carpetas, cada una con una función diferente.

### Carpeta *Main*

En esta carpeta se encuentra el archivo principal del proyecto. Aquí se conectan todos los módulos de la calculadora para que trabajen juntos y se pueda controlar el funcionamiento general del sistema.

### Carpeta *addsub_16*

Esta carpeta contiene el módulo encargado de realizar las operaciones de suma y resta de 16 bits. También incluye los archivos necesarios para realizar las pruebas y verificar que los resultados sean correctos.

### Carpeta *divisor*

Aquí se encuentra el módulo que realiza la operación de división. Además del código principal, contiene archivos utilizados para comprobar el funcionamiento del diseño mediante simulaciones.

---

# Funcionamiento

La calculadora recibe los datos de entrada y, dependiendo de la operación seleccionada, envía la información al módulo correspondiente. Cada módulo procesa la operación y devuelve el resultado para que pueda ser utilizado por el sistema.

Al trabajar cada operación por separado, es más fácil revisar el funcionamiento del proyecto y realizar modificaciones cuando sea necesario.

---

# Simulación

Antes de implementar el diseño en la FPGA, se realizaron simulaciones para comprobar que cada módulo funcionara correctamente.

Durante estas pruebas se verificó que las operaciones entregaran los resultados esperados y que no existieran errores en la comunicación entre los módulos.
![Sim_Div](jhohan/imágenes/Simulacion_div.png)
---

# Módulos principales

## Main

Es el módulo principal del proyecto. Desde aquí se controla el funcionamiento de toda la calculadora y se conectan los demás bloques.

## addsub_16

Este módulo realiza las operaciones de suma y resta utilizando números de 16 bits. También incluye archivos para realizar pruebas del funcionamiento.

## divisor

Este módulo se encarga de calcular la división entre dos datos de entrada y entregar el resultado correspondiente.

---

# Pruebas realizadas

Se realizaron diferentes pruebas para verificar que cada operación funcionara correctamente.

En cada simulación se comparó el resultado obtenido con el resultado esperado para asegurar que el diseño respondiera de forma correcta antes de implementarlo.

---

# Conclusión

Con este proyecto fue posible desarrollar una calculadora digital utilizando LiteX y Verilog. La organización por módulos permitió trabajar cada operación de forma independiente, facilitando las pruebas y la corrección de errores. Además, las simulaciones ayudaron a comprobar que el sistema funcionara correctamente antes de llevarlo a la FPGA.
