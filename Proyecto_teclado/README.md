# PROYECTO TECLADO PARA CALCULADORA FISICA
| Parámetro | Valor | Tiempo | Función |
| :--- | :--- | :--- | :--- |
| cnt | 5 → 0 | ≈ 30 µs | Asentamiento por fila antes de decidir avanzar. |
| N (Antirebote) | 4000 | ≈ 20 ms | Ciclos de estabilidad exigidos → end_flag. |
| unique_flag | N = 4000 | ≈ 20 ms | Tecla soltada y estable en 0 antes de aceptar otra. |
| Barrido sin tecla | 4 × ~7 ciclos | ≈ 140 µs | Vuelta completa Row0→Row3 cuando nada está presionado. |
