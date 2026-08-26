# GRIDFLOW

GRIDFLOW é um protótipo jogável de estratégia e gestão de tráfego urbano, desenvolvido em **Godot 4** para evoluir para iOS e Android.

## Estado atual — Phase 2

O jogo já contém:

- mapa 2D procedural/minimalista;
- grelha de construção;
- estradas desenhadas por clique/arrasto ou toque/arrasto;
- remoção de estradas com reembolso de segmentos e upgrades instalados;
- edifícios residenciais, escritórios, comércio e hospital;
- crescimento automático da cidade;
- geração contínua de viagens;
- pathfinding A* próprio sobre o grafo rodoviário;
- **routing direcional com sentidos únicos reais**;
- veículos autónomos;
- densidade por célula e redução dinâmica da velocidade;
- **estradas de 1, 2 e 3 faixas, com capacidade progressiva**;
- semáforos limitados por recursos;
- **rotundas com aumento de capacidade de cruzamento**;
- recursos independentes para estradas, semáforos, rotundas e alargamentos;
- **upgrade semanal com escolha entre duas opções**;
- Flow Score e estado crítico de congestionamento;
- semanas, pontuação e crescimento da cidade;
- pausa e velocidades 1x/2x/3x;
- **pan e zoom do mapa**, incluindo botões mobile, roda do rato e gesto de magnificação;
- suporte de input por rato e touch;
- CI dedicado em GitHub Actions para parsing do Godot;
- smoke test de execução headless para detetar erros de runtime.

## Abrir o projeto

1. Instalar Godot 4.x.
2. Abrir o Godot Project Manager.
3. Importar `GridFlow/project.godot`.
4. Executar a cena principal.

Resolução base: **1280x720 landscape**.

## Controlos

- `ROAD`: arrastar para construir.
- `ERASE`: arrastar para apagar e recuperar recursos.
- `LIGHT`: instalar/remover semáforos em cruzamentos de 3/4 vias.
- `ROUND`: instalar/remover rotundas.
- `LANES`: aumentar a estrada para 2 ou 3 faixas.
- `1-WAY`: tocar repetidamente para escolher a direção permitida ou voltar a duplo sentido.
- `PAN`: arrastar o mapa.
- `+ / −`: zoom.
- `FIT`: repor a vista inicial.
- `PAUSE`: pausa tática.
- `1x / 2x / 3x`: velocidade da simulação.

## Sistema semanal

A cada semana de simulação o jogo pausa e apresenta duas melhorias aleatórias entre:

- +30 segmentos de estrada;
- +2 semáforos;
- +1 rotunda;
- +2 melhorias de faixa.

A escolha é permanente para essa partida e força o jogador a adaptar a estratégia aos recursos disponíveis.

## Objetivo

Manter o **FLOW** acima do nível crítico. Novos edifícios aparecem ao longo do tempo e geram procura. Edifícios sem acesso rodoviário aumentam a procura pendente. Filas e sobrecarga diminuem o Flow Score. Estradas mais largas e rotundas aumentam a capacidade. Se o Flow permanecer abaixo de 20% durante 45 segundos, ocorre `CITY GRIDLOCK`.

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

O jogo foi estruturado para futuras cidades, veículos e upgrades serem definidos em dados e não hardcoded sempre que possível.

## Próximas prioridades — Phase 3

1. Tejo como obstáculo físico no mapa de Lisboa.
2. Recurso `Bridge` e construção de travessias.
3. Ambulâncias e missões de emergência.
4. `Green Corridor` para prioridade semafórica temporária.
5. Acidentes, obras e veículos avariados.
6. Hora de ponta e procura variável por período do dia.
7. Heatmap de congestionamento.
8. Daily Challenge por seed.
9. Save local + Game Center / achievements.
10. Export iOS, TestFlight e Android.

## Princípio de design

GRIDFLOW não pretende reproduzir Mini Motorways. O núcleo é a gestão ativa da circulação: **estradas + cruzamentos + faixas + sentidos + prioridades + emergências + transportes públicos**.
