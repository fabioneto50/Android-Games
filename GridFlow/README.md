# GRIDFLOW

GRIDFLOW é um protótipo jogável de estratégia e gestão de tráfego urbano, desenvolvido em **Godot 4** para evoluir para iOS e Android.

## Estado atual

O MVP já contém:

- mapa 2D procedural/minimalista;
- grelha de construção;
- estradas desenhadas por clique/arrasto ou toque/arrasto;
- remoção de estradas com reembolso de segmentos;
- edifícios residenciais, escritórios, comércio e hospital;
- crescimento automático da cidade;
- geração contínua de viagens;
- pathfinding A* através do grafo rodoviário;
- veículos autónomos;
- densidade por célula e redução dinâmica da velocidade;
- semáforos em cruzamentos de 3/4 vias;
- Flow Score e estado crítico de congestionamento;
- semanas, pontuação e orçamento de estrada;
- pausa e velocidades 1x/2x/3x;
- suporte de input por rato e touch.

## Abrir o projeto

1. Instalar Godot 4.x.
2. Abrir o Godot Project Manager.
3. Importar `GridFlow/project.godot`.
4. Executar a cena principal.

Resolução base: **1280x720 landscape**.

## Controlos

- `ROAD`: arrastar para construir.
- `ERASE`: arrastar para apagar.
- `SIGNALS`: tocar num cruzamento de 3 ou 4 vias.
- `PAUSE`: pausa tática.
- `1x / 2x / 3x`: velocidade da simulação.

## Objetivo

Manter o **FLOW** acima do nível crítico. Novos edifícios aparecem ao longo do tempo e geram procura. Edifícios sem acesso rodoviário aumentam a procura pendente. Filas e sobrecarga diminuem o Flow Score. Se o Flow permanecer abaixo de 20% durante 45 segundos, ocorre `CITY GRIDLOCK`.

## Arquitetura

```text
GridFlow/
├── project.godot
├── scenes/
│   └── Main.tscn
├── scripts/
│   ├── main.gd
│   ├── city_simulation.gd
│   ├── road_graph.gd
│   ├── vehicle_agent.gd
│   └── city_building.gd
└── data/
    ├── vehicles.json
    └── cities/lisbon.json
```

O jogo foi estruturado para as futuras cidades, veículos e upgrades serem definidos em dados e não hardcoded sempre que possível.

## Próximas prioridades

1. Câmara com pan/zoom e mapas maiores.
2. Faixas e sentidos únicos.
3. Rotundas e prioridades.
4. Pontes e rio Tejo no mapa Lisboa.
5. Ambulâncias e Green Corridor.
6. Obras, acidentes e eventos.
7. Sistema de upgrade semanal com escolha entre duas opções.
8. Daily Challenge por seed.
9. Game Center / achievements.
10. Export iOS, TestFlight e Android.

## Princípio de design

GRIDFLOW não pretende reproduzir Mini Motorways. O núcleo é a gestão ativa da circulação: estradas + cruzamentos + faixas + prioridades + emergências + transporte público.
