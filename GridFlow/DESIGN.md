# GRIDFLOW — Product & Game Design

## Pillars

1. **Readable chaos** — o jogador deve perceber rapidamente onde a rede está a falhar.
2. **Build, observe, redesign** — construir é apenas metade do jogo; reconstruir faz parte da estratégia.
3. **Traffic management, not car control** — o jogador controla a cidade, nunca cada automóvel.
4. **Short input, deep consequences** — gestos simples devem produzir decisões estratégicas.
5. **Mobile-first** — interfaces grandes, pausa tática, touch e sessões curtas.

## Core loop

Cidade cresce → procura aumenta → jogador cria/adapta rede → veículos calculam rotas → surgem gargalos → jogador otimiza → cidade cresce novamente.

## Roadmap funcional

### Milestone A — Core traffic
- roads
- graph
- pathfinding
- autonomous vehicles
- congestion
- traffic lights
- flow score

### Milestone B — Network engineering
- one-way roads
- lane counts
- roundabouts
- junction priority
- road upgrades
- expressways
- reversible lanes

### Milestone C — Lisbon identity
- Tagus river
- bridge resource
- terrain/hills
- historic center
- commuting waves
- hospital emergency routes

### Milestone D — Dynamic city
- accidents
- road works
- weather
- stadium events
- broken-down vehicles
- emergency services

### Milestone E — Mobility
- buses
- bus lanes
- tram
- cycle lanes
- park-and-ride
- metro abstraction

### Milestone F — Meta game
- cities
- unlocks
- achievements
- daily challenge
- weekly challenge
- leaderboards
- cloud save

## Candidate cities

- Lisbon — river crossings and bridge dependency.
- Porto — hills and Douro crossings.
- Amsterdam — canals and cycling pressure.
- London — dense historic network.
- New York — island capacity and bridges/tunnels.
- Tokyo — extreme density and multimodal demand.

## Scoring

Primary metrics:
- completed trips;
- average waiting;
- congestion exposure;
- emergency response;
- Flow Score;
- population sustained.

Target formula for later balancing:

`score = completedTrips × efficiencyMultiplier + emergencyBonus + longevityBonus`

## Failure

A single traffic jam should never instantly end a run. A city enters a critical state first. Only sustained system-wide failure causes Gridlock. This gives the player time to diagnose and redesign.

## Visual direction

Minimal architectural-maquette style rather than copying another game's visual language. Roads use clear neutral geometry; buildings use functional zone colors; congestion is communicated via overlays rather than visual noise.

## Monetization direction

Preferred: premium purchase or free demo + full-game unlock. Avoid interstitial advertising during a live simulation.

## Release target

- iPhone/iPad landscape first.
- Android second or simultaneous if export quality is stable.
- Game Center leaderboards after core gameplay is proven fun.
