# Moto Traffic Reborn

Reconstrução Android nativa do Moto Traffic, criada para máxima compatibilidade e arranque seguro.

## Base técnica

- Java + Android Canvas
- Sem bibliotecas externas de runtime
- Android 6.0+ (`minSdk 23`)
- Portrait
- Save local com SharedPreferences e validação de dados
- Som e haptics opcionais, protegidos contra falhas
- Ecrã de diagnóstico se existir uma falha durante o arranque

## Gameplay

- Corrida rápida infinita
- 7 motos
- Garagem e 4 tipos de upgrades por moto
- 12 etapas de carreira / 36 estrelas
- 4 mapas
- Nitro e wheelie
- Tráfego, near misses, dano e Heat
- Polícia e BLACK VIPER
- Eventos aleatórios e clima
- Season Points, níveis, desafios diários e ranking local
- Premium de desenvolvimento ativo (+25% moedas e CAFÉ 650 desbloqueada)

## Build

```bash
gradle :app:assembleDebug
```

APK: `app/build/outputs/apk/debug/app-debug.apk`
