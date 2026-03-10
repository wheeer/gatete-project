
  ________        __          __                   
 /  _____/_____ _/  |_  _____/  |_  ____           
/   \  ___\__  \\   __\/ __ \   __\/ __ \          
\    \_\  \/ __ \|  | \  ___/|  | \  ___/          
 \______  (____  /__|  \___  >__|  \___  >         
        \/     \/          \/          \/          
__________                   __               __   
\______   \_______  ____    |__| ____   _____/  |_ 
 |     ___/\_  __ \/  _ \   |  |/ __ \_/ ___\   __\
 |    |     |  | \(  <_> )  |  \  ___/\  \___|  |  
 |____|     |__|   \____/\__|  |\___  >\___  >__|  
                        \______|    \/     \/      

![Godot](https://img.shields.io/badge/Engine-Godot_4.5.1-blue)
![Status](https://img.shields.io/badge/Status-Pre--Alpha-red)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-PC-lightgrey)

**Juego de acción 2.5D / 3D estilizado — tierno, feroz y narrado desde la mente  
y los instintos de un gato negro adorable… pero peligrosamente depredador.**

Motor: **Godot Engine 4.5.x**

---

# Visión General

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

# Identidad del Juego

## Estética

- Protagonista: **gato negro estilo cartoon**, adorable pero intimidante  
- Escenarios **3D con presentación 2.5D**  
- Ambientes nocturnos, urbanos y progresivamente más surrealistas  

## Tono

- Humor felino y comportamiento juguetón  
- Violencia estilizada, nunca realista  
- Narrativa ambiental **sugerida más que explicada**

---

# Mecánicas Principales

## Movimiento

El jugador se mueve como un gato: rápido, flexible y reactivo.

- Movimiento en **cuatro patas**
- **Salto**
- **Sprint**
- **Dash**
- **Recompostura felina** al caer

---

## Combate

El combate está centrado en presión constante y control del enemigo.

- Sistema de **combo básico**
- **Daño por impacto**
- **Ruptura de postura enemiga**
- **Captura de enemigos debilitados**
- **Ejecución tras captura**

---

## Sistema de Postura/Compostura

Los enemigos poseen una barra de **postura**.

Cuando la postura se rompe:

- el enemigo queda vulnerable  
- el jugador puede **capturarlo**

---

## Sistema de Captura

Cuando un enemigo está debilitado:

- el gato puede **atraparlo como presa**
- ocurre un **forcejeo**
- si el jugador gana, puede **ejecutarlo**

---

# Sistema de “9 Vidas”

Las vidas no funcionan como en juegos tradicionales.

Representan la **suerte del gato**.

Mientras el gato conserve suerte:

- el daño puede **reducirse**
- algunas situaciones peligrosas pueden **evitarse**

Cuando la suerte se agota, el daño comienza a ser **real**.

---

# Diseño del MVP

El objetivo actual del proyecto es consolidar un **MVP jugable** que demuestre  
el núcleo del sistema de combate.

Duración estimada de la experiencia:

**5 – 10 minutos de gameplay**

El MVP consiste en **un único nivel** diseñado para introducir progresivamente  
las mecánicas del juego.

### Estructura del nivel

1 enemigo individual  
2 enemigos simultáneos  
grupo pequeño de enemigos  
mini-boss final

Durante esta demo el jugador debería experimentar:

- combate básico  
- ruptura de postura  
- captura de enemigos  
- ejecución  
- combate contra pequeños grupos  

---

# Estado Actual del Proyecto

**PRE-ALPHA — Desarrollo activo**

---

## Sistemas Implementados

### Jugador

Movimiento completo

- caminar  
- correr  
- agacharse  
- saltar  
- dash  

Sistema de stamina

- consumo en acciones  
- regeneración  
- agotamiento progresivo  

Sistema de combate base

- fases de ataque  
  - startup  
  - active  
  - recovery  

Combo básico **1-2-3**

Máquina de estados del jugador.

Sistema de **Target Lock**

- selección del enemigo más cercano  
- cambio manual de objetivo  
- rotación del jugador hacia el target  
- cambio automático al morir el enemigo  

---

### Enemigos

- estructura base modular  
- sistema de salud  
- sistema de postura  
- estados de stun  

---

### UI

- barras flotantes de vida y postura  
- UI base del jugador  

---

# En Desarrollo

- sistema completo de **captura**
- **ejecución** de enemigos
- **parry** y esquiva perfecta
- dash con ventana de **invulnerabilidad**
- comportamiento básico de enemigos
- mejoras en la UI del jugador

---

# Tecnologías

**Motor**

Godot Engine **4.5.1**

**Lenguaje**

GDScript

**Arte**

Assets **2D / 2.5D / 3D estilizados**

---

# Estructura del Proyecto

El código está organizado de forma **modular** para que los sistemas principales  
(movimiento, combate, enemigos, UI) puedan evolucionar sin romper el resto  
del proyecto.

La idea es mantener una base clara que permita añadir nuevas mecánicas  
a medida que el juego crece.

---

# 💬 Sobre el Repositorio

Este repositorio funciona también como un espacio de **aprendizaje y exploración**  
dentro del desarrollo de videojuegos.

Si encuentras errores, comportamientos extraños o tienes alguna sugerencia,  
puedes abrir un **issue**.

El proyecto está abierto a ideas y observaciones externas, siempre que  
respeten la dirección general del juego.

---

# Licencia

Por definir según avance del proyecto.

---

# Nota del Autor

Gatete-Project es un proyecto personal en evolución.

Nació como una idea sencilla: explorar cómo se sentiría un juego de combate  
desde la perspectiva de un gato.

Con el tiempo fue creciendo hasta convertirse en un pequeño mundo propio  
que mezcla instinto, humor felino y algo de misterio.

Si llegaste hasta aquí, gracias por tomarte el tiempo de mirar el proyecto.

~ Wheeer

Última actualización: **Marzo 2026**
