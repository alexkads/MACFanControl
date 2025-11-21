# Guia de Testes - MAC Fan Control

Este documento descreve a estrutura de testes da aplicação MAC Fan Control.

## 📋 Visão Geral

A suite de testes é dividida em várias categorias:

- **Testes Unitários**: Testam componentes isolados
- **Testes de Integração**: Testam interação entre componentes
- **Testes de Hardware**: Testam com SMC real (quando disponível)
- **Testes Mock**: Simulam hardware para testes determinísticos

## 🗂️ Estrutura de Testes

```
Tests/
├── SMCKitTests/
│   ├── SMCTests.swift              # Testes unitários do SMC
│   └── SMCIntegrationTests.swift   # Testes de integração com hardware
│
└── MACFanControlTests/
    ├── FanControlManagerTests.swift      # Testes do gerenciador
    ├── FanControlIntegrationTests.swift  # Testes de integração
    ├── MockSMCTests.swift                # Testes do mock
    ├── TestHelpersTests.swift            # Testes dos helpers
    ├── Mocks/
    │   └── MockSMC.swift                 # Mock do SMC
    └── Helpers/
        └── TestHelpers.swift             # Utilitários de teste
```

## 🧪 Tipos de Testes

### 1. SMCTests.swift

Testa funcionalidades de baixo nível do SMC:

- ✅ Decodificação de temperaturas (formato sp78)
- ✅ Encoding/Decoding FPE2 (RPM)
- ✅ Estruturas de dados SMC
- ✅ Geração de keys
- ✅ Validação de limites
- ✅ Testes de performance

**Exemplo:**
```swift
func testTemperatureDecoding() {
    let highByte: UInt8 = 0x32
    let lowByte: UInt8 = 0x40
    let intValue = (Int(highByte) << 8) | Int(lowByte)
    let temperature = Double(intValue) / 256.0
    XCTAssertEqual(temperature, 50.25, accuracy: 0.01)
}
```

### 2. SMCIntegrationTests.swift

Testa com hardware SMC real:

- ✅ Conexão ao SMC
- ✅ Leitura de ventiladores
- ✅ Leitura de temperaturas
- ✅ Controle de ventiladores
- ✅ Tratamento de erros
- ✅ Performance

**Nota:** Usa `XCTSkip` quando SMC não está disponível (VMs, CI/CD)

**Exemplo:**
```swift
func testReadCPUTemperature() {
    guard let smc = smc else {
        XCTSkip("SMC not available")
    }
    let temp = smc.readTemperature(key: "TC0P")
    if let temperature = temp {
        XCTAssertGreaterThan(temperature, 0)
        XCTAssertLessThan(temperature, 110)
    }
}
```

### 3. FanControlManagerTests.swift

Testa lógica de negócio:

- ✅ Inicialização do manager
- ✅ Modo automático/manual
- ✅ Temperatura alvo
- ✅ Controle de ventiladores
- ✅ Algoritmo de controle proporcional
- ✅ Reset para padrões
- ✅ Casos extremos

**Exemplo:**
```swift
func testAutoControlAlgorithmProportional() {
    let fan = FanInfo(id: 0, name: "Test", currentRPM: 2000, 
                      minRPM: 1000, maxRPM: 6000)
    let targetTemp = 60.0
    let currentTemp = 70.0
    let tempDiff = currentTemp - targetTemp
    let range = Double(fan.maxRPM - fan.minRPM)
    let ratio = tempDiff / 20.0
    let expectedRPM = fan.minRPM + Int(range * ratio)
    XCTAssertEqual(expectedRPM, 3500)
}
```

### 4. FanControlIntegrationTests.swift

Testa ciclo completo da aplicação:

- ✅ Lifecycle completo
- ✅ Detecção de hardware real
- ✅ Leitura de dados reais
- ✅ Mudanças rápidas de modo
- ✅ Testes de longa duração
- ✅ Recuperação de erros
- ✅ Memory leaks

**Exemplo:**
```swift
@MainActor
func testFullLifecycle() async {
    manager.startMonitoring()
    try? await Task.sleep(nanoseconds: 5_000_000_000)
    
    if manager.isConnected {
        manager.setAutoMode(enabled: true)
        manager.setFanSpeed(fanIndex: 0, rpm: 2000)
        manager.resetToDefault()
    }
    
    manager.stopMonitoring()
}
```

### 5. MockSMC.swift

Simulador de hardware para testes determinísticos:

- ✅ Simula ventiladores
- ✅ Simula sensores de temperatura
- ✅ Permite controle programático
- ✅ Métodos auxiliares de teste

**Exemplo:**
```swift
let mockSMC = MockSMC()
mockSMC.simulateTemperatureIncrease(amount: 10.0)
let temp = mockSMC.readTemperature(key: "TC0P")
// temp agora é 65.0 (55.0 + 10.0)
```

### 6. TestHelpers.swift

Utilitários para criação de dados de teste:

- ✅ Factories para objetos de teste
- ✅ Cálculos de controle automático
- ✅ Validadores
- ✅ Simuladores de temperatura
- ✅ Assertions customizadas

**Exemplo:**
```swift
let fans = TestHelpers.createMockFans(count: 3)
let rpm = TestHelpers.calculateExpectedRPM(
    currentTemp: 70.0, targetTemp: 60.0,
    minRPM: 1000, maxRPM: 6000
)
XCTAssertTemperatureValid(50.0)
XCTAssertRPMInRange(2000, min: 1000, max: 6000)
```

## 🚀 Executando os Testes

### Todos os testes

```bash
swift test
```

### Testes específicos

```bash
# Apenas testes SMC
swift test --filter SMCTests

# Apenas testes de integração
swift test --filter IntegrationTests

# Teste específico
swift test --filter testTemperatureDecoding
```

### Com verbosidade

```bash
swift test --verbose
```

### Com cobertura

```bash
swift test --enable-code-coverage
```

## 📊 Cobertura de Testes

### SMCKit

- **SMC.swift**: 
  - Lógica de encoding/decoding: ✅ 100%
  - Comunicação IOKit: ⚠️ Parcial (depende de hardware)
  
### MACFanControl

- **FanControlManager.swift**: ✅ ~90%
  - Lógica de controle: ✅ 100%
  - Integração com SMC: ⚠️ Parcial

## ⚙️ Configuração CI/CD

Os testes são projetados para funcionar em ambientes sem SMC:

```yaml
# GitHub Actions exemplo
- name: Run tests
  run: swift test --parallel
```

Testes que requerem hardware usam `XCTSkip`:

```swift
guard let smc = smc else {
    XCTSkip("SMC not available - skipping hardware test")
}
```

## 🎯 Assertions Customizadas

### XCTAssertTemperatureValid

Valida que temperatura está em faixa razoável:

```swift
XCTAssertTemperatureValid(65.0)
// Verifica: 0 < temp < 120
```

### XCTAssertRPMValid

Valida que RPM é válido:

```swift
XCTAssertRPMValid(2000, min: 1000, max: 6000)
// Verifica: 0 <= rpm <= max*2
```

### XCTAssertRPMInRange

Valida que RPM está dentro dos limites:

```swift
XCTAssertRPMInRange(2000, min: 1000, max: 6000)
// Verifica: min <= rpm <= max
```

## 🔍 Debugging de Testes

### Verbose Output

Use `print()` nos testes:

```swift
func testExample() {
    print("Current fans: \(manager.fans)")
    // teste...
}
```

### Breakpoints

Coloque breakpoints nos testes para debug interativo.

### XCTestExpectation

Para testes assíncronos:

```swift
let expectation = XCTestExpectation(description: "Wait for update")
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    expectation.fulfill()
}
wait(for: [expectation], timeout: 3.0)
```

## 📈 Benchmarks de Performance

Os testes incluem medições de performance:

```swift
func testTemperatureDecodingPerformance() {
    measure {
        for _ in 0..<1000 {
            // código a medir
        }
    }
}
```

## ✅ Checklist de Testes

Antes de fazer commit:

- [ ] Todos os testes unitários passam
- [ ] Testes de integração passam (se SMC disponível)
- [ ] Novos recursos têm testes
- [ ] Cobertura mantida ou melhorada
- [ ] Sem memory leaks
- [ ] Performance aceitável

## 🐛 Testes Conhecidos que Podem Falhar

### Em VMs ou CI/CD

- `SMCIntegrationTests` - Requer hardware Mac real
- `testRealHardwareDetection` - Será skipped

### Em Macs sem ventiladores expostos

- Alguns Macs não expõem ventiladores via SMC
- Testes usam `XCTSkip` nestes casos

## 📚 Recursos Adicionais

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://swift.org/documentation/articles/testing.html)
- [Apple SMC Keys](https://github.com/acidanthera/VirtualSMC)

## 🔄 Manutenção

Ao adicionar novos recursos:

1. Adicione testes unitários primeiro (TDD)
2. Crie mocks se necessário
3. Adicione testes de integração
4. Atualize este documento
5. Verifique cobertura

---

**Última atualização:** Novembro 2025
