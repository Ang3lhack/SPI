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

## Plan de Pruebas (Testbench)

Para garantizar la fiabilidad del sistema, se ha implementado un banco de pruebas a nivel de sistema (`tb_spi_system.v`) que instancia tanto al Master como al Slave, conectándolos mediante un bus físico simulado. 

Las pruebas automatizadas validan los siguientes escenarios clave:

### 🧪 Caso de Prueba 1: Verificación de Estado Inicial y Reset
* **Objetivo:** Confirmar que al iniciar el sistema y mantener el reset (`rst_n = 0`), los buses se mantienen en estados seguros y conocidos.
* **Acción:** Aplicar un reset asíncrono activo en bajo durante 2 ciclos de reloj y luego liberarlo.
* **Criterio de Éxito:** Las señales deben inicializarse correctamente:
  * `CS_N` se mantiene en `1` (ALTO / Inactivo).
  * `SCLK` se mantiene en `0` (BAJO).
  * `MOSI` se inicializa en `0`.
  * `MISO` se mantiene en `Z` (Alta impedancia, evitando colisiones en el bus).

### 🔄 Caso de Prueba 2: Comunicación Bidireccional Cruzada (Full-Duplex)
* **Objetivo:** Validar que el protocolo Full-Duplex funciona correctamente, transmitiendo y recibiendo datos desde ambos extremos de manera simultánea.
* **Acción:** * Cargar el valor `8'hA5` (10100101 en binario) en el registro del Master.
  * Cargar el valor `8'h3C` (00111100 en binario) en el registro del Slave.
  * Enviar un pulso a la señal `start` del Master.
* **Criterio de Éxito:** Al levantarse la señal `done`, la salida `master_data_out` debe ser exactamente `0x3C` y la salida `slave_data_out` debe ser `0xA5`. El Testbench imprimirá automáticamente un mensaje de "PASÓ".

### ⏱️ Caso de Prueba 3: Continuidad y Sincronización de Reloj
* **Objetivo:** Comprobar que el Master puede iniciar una segunda transacción independiente después de finalizar la primera, liberando el bus correctamente entre ambas.
* **Acción:** Esperar 5 ciclos de reloj en estado `IDLE` tras el Caso 2. Cargar nuevos datos (`8'h55` para el Master y `8'hAA` para el Slave) e iniciar una nueva transmisión con la señal `start`.
* **Criterio de Éxito:** * `CS_N` debe bajar nuevamente a `0`.
  * Se deben generar **exactamente 8 ciclos de reloj completos** en la línea `SCLK`.
  * Los datos deben cruzarse exitosamente de nuevo.
  * Al finalizar, `CS_N` debe regresar de inmediato a `1`.

Autores:
Angel Gael Garcia Ramos
Andrea Valeria Torres Figueroa
Estefania Navarro Mendoza
