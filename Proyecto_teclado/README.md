# PROYECTO TECLADO PARA CALCULADORA FISICA
<img width="949" height="1961" alt="Diagrama de flujo teclado drawio" src="https://github.com/user-attachments/assets/0b8f51a1-964a-48eb-815a-8b6ed5821c98" />

| Parámetro | Valor | Tiempo | Función |
| :--- | :--- | :--- | :--- |
| cnt | 5 → 0 | ≈ 30 µs | Asentamiento por fila antes de decidir avanzar. |
| N (Antirebote) | 4000 | ≈ 20 ms | Ciclos de estabilidad exigidos → end_flag. |
| unique_flag | N = 4000 | ≈ 20 ms | Tecla soltada y estable en 0 antes de aceptar otra. |
| Barrido sin tecla | 4 × ~7 ciclos | ≈ 140 µs | Vuelta completa Row0→Row3 cuando nada está presionado. |
