# Implementación de Sistema SPI (Master/Slave) en Verilog

Este repositorio contiene la implementación completa en Verilog de un bus de comunicación **SPI (Serial Peripheral Interface)** configurado en **Modo 0** (CPOL = 0, CPHA = 0). Incluye tanto el módulo controlador (Master) como el periférico (Slave), junto con un entorno de validación a nivel de sistema (Testbench).

## Características del Proyecto
* **Arquitectura Full-Duplex:** Transmisión y recepción de datos simultánea.
* **Parametrizable:** El ancho de los datos (`DATA_WIDTH`) es fácilmente modificable (por defecto, 8 bits).
* **Modo SPI 0:** Reloj en reposo en nivel BAJO (CPOL=0) y muestreo de datos en el primer flanco de subida (CPHA=0).
* **Testbench Automatizado:** Pruebas integradas que se auto-verifican y reportan resultados en consola.

## Estructura de Archivos
* `spi_master.v`: Módulo principal que genera la señal de reloj (`SCLK`), controla el Chip Select (`CS_N`) y gestiona la máquina de estados de la transmisión.
* `spi_slave.v`: Módulo periférico pasivo que reacciona a los estímulos del Master. Incluye lógica para mantener la línea `MISO` en alta impedancia (Z) cuando no está seleccionado.
* `tb_spi_system.v`: Entorno de simulación (Testbench) que instancia ambos módulos, los conecta a través de un bus físico simulado y ejecuta los casos de prueba.

---

## Arquitectura del Controlador (Máquina de Estados)

El núcleo del Master SPI está regido por una Máquina de Estados Finitos (FSM) de 4 estados que garantiza la correcta sincronización de la señal `CS_N`, la generación del reloj `SCLK` y el desplazamiento de los datos.

```mermaid
stateDiagram-v2
    direction LR
    [*] --> IDLE : Reset (rst_n = 0)
    
    IDLE --> SETUP : start = 1\n(Baja CS_N)
    
    SETUP --> TRANSFER : Automático\n(Prepara MOSI)
    
    TRANSFER --> SETUP : bit_cnt > 0\n(Siguiente bit)
    TRANSFER --> DONE : bit_cnt == 0\n(Byte completado)
    
    DONE --> IDLE : Automático\n(Sube CS_N, done = 1)

    note right of TRANSFER
        SCLK Toggle (Toggle Reloj)
        Flanco Subida: Muestrea MISO
        Flanco Bajada: Actualiza MOSI
    end note
