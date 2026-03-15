# GATETE-PROJECT 
![Godot](https://img.shields.io/badge/Engine-Godot_4.5.1-blue)
![Status](https://img.shields.io/badge/Status-Pre--Alpha-red)
![Genre](https://img.shields.io/badge/Genre-Action_Combat-darkred)
![Platform](https://img.shields.io/badge/Platform-PC-lightgrey)

**Juego de acción 2.5D / 3D estilizado — tierno, feroz y narrado desde la mente  
y los instintos de un gato negro adorable… pero letal.**

Motor: **Godot Engine 4.5.1**

---

## Visión General

**Gatete-Project** es un juego de combate donde el jugador controla a un gato negro  
ágil y letal que se abre paso entre enemigos usando velocidad, reflejos y puro  
instinto depredador.

La experiencia comienza en escenarios relativamente cotidianos: calles, patios,  
techos y rincones urbanos donde pequeños animales se convierten en rivales.

A medida que se avanza, el mundo empieza a cambiar sutilmente.

Los escenarios se vuelven más extraños.  
Las criaturas se comportan de formas inusuales.  
Algunos enemigos parecen… distintos.

---

## Identidad del Juego

### Estética

- Protagonista: **gato negro estilo cartoon**, adorable pero intimidante  
- Escenarios **3D con presentación 2.5D**  
- Ambientes nocturnos, urbanos y progresivamente más surrealistas  

### Tono

- Humor felino y comportamiento juguetón  
- Violencia estilizada, nunca realista  
- Narrativa ambiental **sugerida más que explicada**

---

## Mecánicas Principales

### Movimiento

El jugador se mueve como un gato: rápido, flexible y reactivo.

- Movimiento en **cuatro patas**
- **Salto**
- **Sprint**
- **Dash**
- **Recompostura felina** al caer

---

### Combate

El combate está centrado en presión constante y control del enemigo.

- Sistema de **combo básico** (1-2-3, con golpe crítico en el tercer hit)
- **Daño por impacto** con fases `startup / active / recovery`
- **Ruptura de postura enemiga**
- **Captura de enemigos debilitados**
- **Ejecución tras captura**

---

### Sistema de Postura/Compostura

Los enemigos poseen una barra de **postura**.

Cuando la postura se rompe:

- el enemigo queda vulnerable  
- el jugador puede **capturarlo** o **ejecutarlo directamente**

---

### Sistema de Captura

Cuando un enemigo está debilitado (postura rota o vida ≤ 15%):

- el gato puede **atraparlo como presa** (hold botón derecho del mouse)
- ocurre un **forcejeo** — duelo de estados
- si el jugador gana, puede **ejecutarlo** con gran recompensa
- si el enemigo resiste, el gato recibe penalización

---

## Sistema de "9 Vidas"

Las vidas no funcionan como en juegos tradicionales.

Representan la **suerte del gato**.

Mientras el gato conserve corazones:

- el daño recibido se **reduce drásticamente** (el corazón absorbe el impacto)
- se consume **1 corazón** por golpe recibido

Cuando los corazones se agotan, el daño comienza a ser **real y casi letal**.

---

## Diseño del MVP

El objetivo actual es consolidar un **MVP jugable** que demuestre  
el núcleo del sistema de combate.

Duración estimada de la experiencia: **5 – 10 minutos de gameplay**

### Estructura del nivel

1. 1 enemigo individual  
2. 2 enemigos simultáneos  
3. Grupo pequeño de enemigos  
4. Mini-boss final

Durante esta demo el jugador debería experimentar:

- combate básico  
- ruptura de postura  
- captura de enemigos  
- ejecución  
- combate contra pequeños grupos  

---

## Estado Actual del Proyecto

**PRE-ALPHA — Desarrollo activo**

---

## Sistemas Implementados

### Arquitectura Core (Bloque 0 — Fundación)

Pipeline de combate completo basado en el patrón **Resolver**:

- **EventBus** — sistema global de eventos desacoplado; todos los sistemas se comunican mediante `emit_event()` sin referencias directas
- **SnapshotFactory** — captura el estado inmutable de una entidad antes de que el daño sea aplicado; garantiza que el `DamageResolver` opere sobre datos congelados
- **DamageResolver** — cerebro del combate; resuelve todo el daño según la fuente (`JUGADOR` / `ENEMIGO`), aplica modificadores críticos, lógica de 9 Vidas y genera el `DamageVerdict`
- **CombatMediator** — orquestador; conecta el ataque del jugador con el `DamageResolver` y aplica el veredicto a los componentes reales del enemigo

> Todo el daño del juego fluye por: `CombatMediator → SnapshotFactory → DamageResolver → EventBus`  
> Los métodos directos como `take_damage()` están marcados como **deprecated**.

---

### Jugador (Don Gato)

**Movimiento completo**

- caminar  
- correr  
- agacharse  
- saltar  
- dash  

**Sistema de stamina**

- consumo en acciones  
- regeneración  
- agotamiento progresivo  

**Sistema de combate**

- fases de ataque: `startup / active / recovery`
- combo básico **1-2-3** con escala de daño (`LIGHT → MEDIUM → HEAVY`)
- el tercer hit del combo tiene probabilidad de golpe crítico (crit_chance, base 15% en producción, escalable por stats, buffs y habilidades)
- detección de golpe por `Area3D` — un solo hit por fase activa (`already_hit`)
- daño delegado al `CombatMediator`, no aplicado directamente

**Sistema de 9 Vidas (implementado en DamageResolver)**

- mientras quedan corazones: cada golpe recibido consume 1 corazón y aplica solo el 15% del daño base a la vida
- sin corazones: daño real completo

**Componentes del jugador**

- `HealthComponent` (DonGatoHealth)
- `PostureComponent`
- `LivesSystem` (corazones)
- `CombatSystem` (DonGatoCombat)
- `MovementSystem`
- `PlayerStats`
- `StateMachine` del jugador

**Sistema de Target Lock**

- selección del enemigo más cercano  
- cambio manual de objetivo  
- rotación del jugador hacia el target  
- cambio automático al morir el enemigo  

---

### Enemigos

**EnemyBase — estructura modular**

- `HealthComponent`  
- `PostureComponent`  
- `StunComponent`  
- `EnemyMovementComponent`  
- `EnemyCombatComponent`  

**EnemyStateMachine — estados físicos**

- `NORMAL`  
- `STUNNED`  
- `POSTURE_BROKEN` — detiene movimiento, habilita ventana de captura  
- `CAPTURED`  
- `DEAD` — emite `EVT_ENEMIGO_MUERTO` y llama `queue_free()`  

La máquina de estados escucha el `EventBus` y filtra eventos por `target_id`  
para evitar reacciones cruzadas entre enemigos.

**Eventos implementados**

- `EVT_RECIBIR_GOLPE`  
- `EVT_POSTURA_ROTA`  
- `EVT_GOLPE_CRITICO_RECIBIDO`  
- `EVT_ENEMIGO_MUERTO`  
- `EVT_GOLPE_FUERTE_RECIBIDO` (para activar TIME STOP en el jugador)  
- `EVT_CORAZON_PERDIDO`  

---

### UI

- barras flotantes de **vida y postura** por enemigo (se instancian dinámicamente en `_ready`)
- UI base del jugador  

---

## En Desarrollo

- **CaptureResolver** — sistema completo de captura y forcejeo (Bloque 2 del MVP)
- **Ejecución** de enemigos tras captura
- **Parry** y esquiva perfecta
- **AIR_RECOVERY** — ventana de recuperación ante golpes fuertes (TIME STOP)
- **Dash** con ventana de invulnerabilidad
- **Comportamiento básico de enemigos** (AI: patrulla, persecución, ataque)
- **PsychologyComponent** — impulsos de IRA y PÁNICO según eventos recibidos (Bloque 4 del MVP)
- **ADN_Handler** — inyección de `RazaResource` + `IndividuoResource` + `PerfilPsicologico` en runtime
- Animaciones de combate y feedback visual (POSTURE_BROKEN, stun, ejecución)
- Mejoras en la UI del jugador

---

## Tecnologías

**Motor**

Godot Engine **4.5.1**

**Lenguaje**

GDScript — tipado estático

**Arte**

Assets **2D / 2.5D / 3D estilizados**

---

## Estructura del Proyecto

```
Actors/
  Player/
	don_gatoController.gd
	Components/
	  don_gatoCombat.gd
	  don_gatoHealth.gd
	  ...
  Enemies/
	EnemyBase/
	  enemy_base.gd / .tscn
	  enemy_state_machine.gd
	  Components/
		health_component.gd
		posture_component.gd
		stun_component.gd
		enemy_movement_component.gd
		enemy_combat_component.gd

Systems/
  event_bus.gd            ← Autoload global
  damage_resolver.gd      ← Cerebro del daño
  snapshot_factory.gd     ← Congelado de estado
  combat_mediator.gd      ← Orquestador

UI/
  EnemyUI/
	floating_health_bar.tscn

Resources/              ← (pendiente: ADN data-driven)
  RazaResource
  IndividuoResource
  PerfilPsicologico
```

El código sigue el patrón **Componente + Resolver + EventBus**.  
Los actores no se comunican directamente entre sí — todo pasa por el bus de eventos.  
Esta arquitectura permite añadir nuevas mecánicas sin romper los sistemas existentes.

---

## 💬 Sobre el Repositorio

Este repositorio funciona también como un espacio de **aprendizaje y exploración**  
dentro del desarrollo de videojuegos.

Si encuentras errores, comportamientos extraños o tienes alguna sugerencia,  
puedes abrir un **issue**.

El proyecto está abierto a ideas y observaciones externas, siempre que  
respeten la dirección general del juego.

---

## Licencia

Por definir según avance del proyecto.

---

## Nota del Autor

Gatete-Project es un proyecto personal en evolución.

Nació como una idea sencilla: explorar cómo se sentiría un juego de combate  
desde la perspectiva de un gato.

Y se convirtió en algo mucho más interesante.
