import SwiftUI

struct ContentView: View {
    @StateObject private var manager = FanControlManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(manager: manager)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Temperature Section
                    TemperatureSection(temperatures: manager.temperatures)
                    
                    // Fans Section
                    FansSection(manager: manager)
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct HeaderView: View {
    @ObservedObject var manager: FanControlManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "fan")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                Text("MAC Fan Control")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Circle()
                    .fill(manager.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(manager.isConnected ? "Conectado" : "Desconectado")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Toggle("Modo Automático", isOn: Binding(
                    get: { manager.autoMode },
                    set: { manager.setAutoMode(enabled: $0) }
                ))
                .toggleStyle(.switch)
                
                Spacer()
                
                if manager.autoMode {
                    HStack {
                        Text("Temp. Alvo:")
                            .font(.caption)
                        Slider(value: $manager.targetTemperature, in: 40...80, step: 5)
                            .frame(width: 120)
                        Text("\(Int(manager.targetTemperature))°C")
                            .font(.caption)
                            .frame(width: 40)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
}

struct TemperatureSection: View {
    let temperatures: [TemperatureSensor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.orange)
                Text("Temperaturas")
                    .font(.headline)
            }
            
            if temperatures.isEmpty {
                Text("Nenhum sensor detectado")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(temperatures.prefix(6)) { sensor in
                        TemperatureCard(sensor: sensor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct TemperatureCard: View {
    let sensor: TemperatureSensor
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sensor.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(sensor.temperature, specifier: "%.1f")°C")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(temperatureColor)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
    }
    
    private var temperatureColor: Color {
        switch sensor.temperature {
        case ..<50: return .blue
        case 50..<70: return .green
        case 70..<85: return .orange
        default: return .red
        }
    }
}

struct FansSection: View {
    @ObservedObject var manager: FanControlManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fan.fill")
                    .foregroundColor(.blue)
                Text("Ventiladores")
                    .font(.headline)
            }
            
            if let errorMessage = manager.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Erro de Detecção")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else if manager.fans.isEmpty {
                Text("Nenhum ventilador detectado")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(manager.fans) { fan in
                    FanControl(fan: fan, manager: manager)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct FanControl: View {
    let fan: FanInfo
    @ObservedObject var manager: FanControlManager
    @State private var sliderValue: Double
    
    init(fan: FanInfo, manager: FanControlManager) {
        self.fan = fan
        self.manager = manager
        _sliderValue = State(initialValue: Double(fan.targetRPM ?? fan.currentRPM))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(fan.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 15) {
                    VStack(alignment: .trailing) {
                        Text("Atual")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(fan.currentRPM) RPM")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    if let target = fan.targetRPM {
                        VStack(alignment: .trailing) {
                            Text("Alvo")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(target) RPM")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            HStack {
                Text("\(fan.minRPM)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
                
                Slider(
                    value: $sliderValue,
                    in: Double(fan.minRPM)...Double(fan.maxRPM),
                    step: 100,
                    onEditingChanged: { editing in
                        if !editing {
                            manager.setFanSpeed(fanIndex: fan.id, rpm: Int(sliderValue))
                        }
                    }
                )
                .disabled(manager.autoMode)
                
                Text("\(fan.maxRPM)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
                
                Text("\(Int(sliderValue))")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 50)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(speedColor)
                        .frame(width: geometry.size.width * speedPercentage)
                }
            }
            .frame(height: 4)
            .cornerRadius(2)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .onChange(of: fan.targetRPM) { newValue in
            if let newValue = newValue {
                sliderValue = Double(newValue)
            }
        }
    }
    
    private var speedPercentage: Double {
        let range = Double(fan.maxRPM - fan.minRPM)
        let current = Double(fan.currentRPM - fan.minRPM)
        return min(max(current / range, 0), 1)
    }
    
    private var speedColor: Color {
        switch speedPercentage {
        case ..<0.3: return .blue
        case 0.3..<0.6: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

#Preview {
    ContentView()
}
