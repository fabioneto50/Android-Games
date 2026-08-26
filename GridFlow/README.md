# GRIDFLOW

GRIDFLOW é um jogo de estratégia e gestão de tráfego urbano em **Godot 4**, concebido para evoluir para iOS e Android. A cidade cresce continuamente e o jogador gere a infraestrutura, capacidade e prioridades da rede antes de o sistema entrar em gridlock.

## Estado atual — Lisbon Prototype

### Rede rodoviária

- construção de estradas por toque/arrasto ou rato;
- remoção com reembolso de recursos;
- pathfinding A* próprio sobre um grafo rodoviário dinâmico;
- sentidos únicos que alteram efetivamente as rotas calculadas;
- estradas de 1, 2 e 3 faixas com capacidade progressiva;
- semáforos em cruzamentos de 3/4 vias;
- rotundas com aumento de capacidade;
- pan e zoom do mapa;
- pausa tática e velocidades 1x/2x/3x.

### Lisboa e Tejo

- mapa protótipo inspirado em Lisboa;
- rio Tejo como obstáculo físico que impede estradas normais;
- recurso `Bridge` limitado;
- travessias construídas pelo jogador;
- remoção de uma ponte devolve os recursos utilizados.

### Cidade dinâmica

- edifícios residenciais, escritórios, comércio e hospital;
- crescimento urbano automático;
- geração contínua de viagens;
- relógio urbano simulado;
- hora de ponta entre 07:00–10:00 e 16:00–20:00;
- procura reduzida durante a noite;
- densidade por célula e redução dinâmica da velocidade;
- Flow Score 0–100%;
- `CITY GRIDLOCK` se o Flow permanecer criticamente baixo.

### Emergências

A partir da semana 2 surgem chamadas de emergência:

- ambulâncias são criadas numa zona da cidade e calculam uma rota até ao hospital;
- têm velocidade e comportamento próprios;
- existe um limite de tempo para concluir a resposta;
- sucesso atribui +500 pontos;
- falha penaliza o score e o Flow;
- o botão `GREEN` ativa um **Green Corridor** durante 12 segundos;
- enquanto ativo, a ambulância ignora os ciclos vermelhos dos semáforos ao longo do seu percurso;
- o trajeto prioritário é destacado visualmente no mapa;
- Green Corridors são um recurso limitado e também podem aparecer como upgrade semanal.

### Recursos e upgrades

Recursos independentes:

- segmentos de estrada;
- semáforos;
- rotundas;
- melhorias de faixa;
- pontes;
- Green Corridors.

A cada semana a simulação pausa e apresenta duas opções aleatórias, por exemplo:

- +30 segmentos de estrada;
- +2 semáforos;
- +1 rotunda;
- +2 melhorias de faixa;
- +1 ponte;
- +1 Green Corridor.

## Interface

### Barra inferior

- `ROAD` — construir estrada;
- `ERASE` — apagar e recuperar recursos;
- `LIGHT` — semáforo;
- `ROUND` — rotunda;
- `LANES` — aumentar capacidade;
- `1-WAY` — configurar sentido único;
- `BRIDGE` — criar travessia sobre o Tejo;
- `PAN` — deslocar o mapa.

### Barra superior

Mostra hora, rush hour, Flow, semana, recursos, população e emergências ativas, além de:

- `GREEN` — corredor prioritário;
- `PAUSE`;
- velocidade;
- zoom;
- `FIT` para repor a vista.

## Executar no Godot

1. Instalar Godot 4.x.
2. Abrir o Godot Project Manager.
3. Importar `GridFlow/project.godot`.
4. Executar `Main.tscn`.

Resolução base: **1280 × 720 landscape**.

## Build automática

O GitHub Actions executa a cada alteração do GRIDFLOW:

1. import/parsing do projeto com Godot 4.4.1;
2. deteção explícita de erros GDScript;
3. smoke test de execução headless;
4. export Web release;
5. upload do build como artifact `gridflow-web`.

O preset de export está em `GridFlow/export_presets.cfg`.

## Arquitetura

```text
GridFlow/
├── project.godot
├── export_presets.cfg
├── scenes/
│   └── Main.tscn
├── scripts/
│   ├── main.gd
│   ├── city_simulation.gd
│   ├── road_graph.gd
│   ├── vehicle_agent.gd
│   ├── city_building.gd
│   └── emergency_manager.gd
└── data/
    ├── vehicles.json
    └── cities/lisbon.json
```

## Próximas prioridades

1. acidentes, obras e veículos avariados;
2. heatmap de congestionamento;
3. comportamento de trânsito diferenciado por zona e hora;
4. bombeiros e polícia;
5. objetivos e desafios por cidade;
6. Daily Challenge por seed;
7. save local, achievements e leaderboards;
8. novas cidades;
9. export Android;
10. export iOS / TestFlight.

## Princípio de design

GRIDFLOW não pretende reproduzir Mini Motorways. A identidade do jogo assenta na gestão ativa da circulação: **estradas + cruzamentos + faixas + sentidos + pontes + prioridades + emergências + transportes públicos**.
