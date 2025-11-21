# MAC Fan Control

Uma aplicação nativa para macOS que permite monitorar e controlar os ventiladores do seu Mac, similar ao Mac Fan Control.

## 🌟 Funcionalidades

- ✅ **Monitoramento em Tempo Real**: Visualize RPM atual de todos os ventiladores
- ✅ **Sensores de Temperatura**: Monitore temperaturas de CPU, GPU, memória e outros componentes
- ✅ **Controle Manual**: Ajuste manualmente a velocidade de cada ventilador
- ✅ **Modo Automático**: Controle inteligente baseado em temperatura
- ✅ **Menu Bar App**: Interface compacta acessível direto da barra de menu
- ✅ **Interface Moderna**: Desenvolvida com SwiftUI para macOS

## 📋 Requisitos

- macOS 13.0 (Ventura) ou superior
- Xcode 15.0+ ou Swift 5.9+
- Mac com sensores SMC (System Management Controller)

## 🚀 Como Usar

### Compilação

```bash
# Clone o repositório
cd MACFanControl

# Compile o projeto
swift build -c release

# Execute a aplicação
swift run
```

### Instalação

```bash
# Build para produção
swift build -c release

# O executável estará em:
# .build/release/MACFanControl
```

## 🎮 Funcionalidades da Interface

### Painel Principal

- **Seção de Temperaturas**: Mostra as principais temperaturas do sistema
  - CPU Die, CPU Proximity
  - GPU Die, GPU Proximity
  - Memória, Northbridge, etc.

- **Seção de Ventiladores**: Controle individual de cada ventilador
  - Visualização de RPM atual e alvo
  - Slider para ajuste manual de velocidade
  - Barra de progresso visual com código de cores

### Modos de Operação

#### Modo Automático
- Ajusta automaticamente a velocidade dos ventiladores baseado na temperatura
- Temperatura alvo configurável (40-80°C)
- Algoritmo de controle proporcional

#### Modo Manual
- Controle preciso de cada ventilador individualmente
- Ajuste por slider com intervalos de 100 RPM
- Respeita os limites mínimo e máximo de cada ventilador

## 🔧 Arquitetura Técnica

### Módulos

1. **SMCKit**: Biblioteca de baixo nível para comunicação com SMC
   - Leitura de sensores de temperatura
   - Leitura de velocidade de ventiladores
   - Controle de velocidade de ventiladores
   - Detecção automática de número de ventiladores

2. **FanControlManager**: Lógica de negócio
   - Gerenciamento de estado dos ventiladores
   - Algoritmo de controle automático
   - Timer para atualização periódica (2 segundos)

3. **Interface SwiftUI**: UI moderna e responsiva
   - ContentView: Layout principal
   - TemperatureSection: Cards de temperatura
   - FansSection: Controles de ventilador
   - AppDelegate: Menu bar integration

### Comunicação SMC

A aplicação usa IOKit para comunicação direta com o System Management Controller:

- **Leitura de Temperaturas**: Keys como `TC0P`, `TC0D`, `TG0D`
- **Controle de Ventiladores**: 
  - `F0Ac`, `F1Ac`: RPM atual
  - `F0Mn`, `F1Mn`: RPM mínimo
  - `F0Mx`, `F1Mx`: RPM máximo
  - `F0Md`, `F1Md`: Modo (0=auto, 1=manual)
  - `F0Tg`, `F1Tg`: RPM alvo

## ⚠️ Avisos Importantes

1. **Permissões**: A aplicação requer acesso ao SMC (normalmente disponível sem permissões especiais)

2. **Uso Responsável**: 
   - Não configure ventiladores muito lentos por períodos prolongados
   - Monitore as temperaturas ao usar modo manual
   - O sistema tem proteções contra superaquecimento, mas use com cuidado

3. **Compatibilidade**:
   - Testado em Macs Intel e Apple Silicon
   - Alguns sensores podem não estar disponíveis em todos os modelos
   - Números e nomes de ventiladores variam por modelo

## 🐛 Troubleshooting

### "Desconectado" na Interface
- Verifique se está executando em um Mac real (não funciona em VM)
- Alguns modelos podem ter SMC com acesso restrito

### Ventiladores Não Respondem
- Verifique se o modo manual está ativado
- Aguarde alguns segundos para o SMC processar o comando
- Reinicie a aplicação se necessário

### Temperaturas Não Aparecem
- Normal - sensores variam por modelo de Mac
- A aplicação tenta ler os sensores mais comuns

## 📝 Licença

Este projeto é fornecido como exemplo educacional. Use por sua conta e risco.

## 🤝 Contribuições

Melhorias são bem-vindas! Áreas de interesse:
- Suporte para mais modelos de Mac
- Perfis de controle customizáveis
- Gráficos de histórico de temperatura
- Notificações de temperatura alta
- Exportação de logs

## 📚 Referências

- [Apple IOKit Framework](https://developer.apple.com/documentation/iokit)
- [SMC Keys Database](https://github.com/acidanthera/VirtualSMC)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

**Nota**: Esta aplicação acessa hardware de baixo nível. Use com responsabilidade e sempre monitore as temperaturas do seu Mac.
