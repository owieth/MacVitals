import Foundation
import Network
import os.log

final class WebServer: @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "WebServer")
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.macvitals.webserver")
    private(set) var isRunning = false
    private var port: UInt16 = 8765

    func start(port: UInt16) {
        stop()
        self.port = port
        do {
            let params = NWParameters.tcp
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            Self.logger.error("Failed to create listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                Self.logger.info("Web server listening on port \(port)")
            case .failed(let error):
                Self.logger.error("Web server failed: \(error)")
            default:
                break
            }
        }

        listener?.start(queue: queue)
        isRunning = true
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            self?.routeRequest(request, connection: connection)
        }
    }

    private func routeRequest(_ request: String, connection: NWConnection) {
        let firstLine = request.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.split(separator: " ")
        let path = parts.count >= 2 ? String(parts[1]) : "/"

        switch path {
        case "/api/status":
            respondJSON(connection: connection)
        default:
            respondHTML(connection: connection)
        }
    }

    private func respondJSON(connection: NWConnection) {
        DispatchQueue.main.async { [weak self] in
            let json = self?.buildJSON() ?? "{}"
            self?.queue.async {
                let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n\(json)"
                self?.sendAndClose(response, connection: connection)
            }
        }
    }

    private func respondHTML(connection: NWConnection) {
        let html = Self.dashboardHTML(port: port)
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\n\r\n\(html)"
        sendAndClose(response, connection: connection)
    }

    private func sendAndClose(_ response: String, connection: NWConnection) {
        let data = Data(response.utf8)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    @MainActor
    private func buildJSON() -> String {
        guard let snap = SystemMonitor.shared.snapshot else { return "{}" }

        var dict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: snap.timestamp),
            "uptime": snap.uptime,
            "cpu": [
                "total": round(snap.cpu.totalUsage * 10) / 10,
                "user": round(snap.cpu.userUsage * 10) / 10,
                "system": round(snap.cpu.systemUsage * 10) / 10,
                "cores": snap.cpu.coreUsages.map { round($0 * 10) / 10 },
            ],
            "memory": [
                "total": snap.memory.total,
                "used": snap.memory.used,
                "active": snap.memory.active,
                "wired": snap.memory.wired,
                "compressed": snap.memory.compressed,
                "pressure": snap.memory.pressure.rawValue,
                "percentage": round(snap.memory.usagePercentage * 10) / 10,
            ],
            "storage": [
                "total": snap.storage.total,
                "used": snap.storage.used,
                "readBytesPerSec": snap.storage.readBytesPerSec,
                "writeBytesPerSec": snap.storage.writeBytesPerSec,
                "percentage": round(snap.storage.usagePercentage * 10) / 10,
            ],
            "network": [
                "downloadBytesPerSec": snap.network.downloadBytesPerSec,
                "uploadBytesPerSec": snap.network.uploadBytesPerSec,
                "interface": snap.network.interfaceName,
                "ip": snap.network.ipAddress,
                "gateway": snap.network.gatewayIP,
            ],
            "thermal": [
                "cpuTemp": snap.thermal.cpuTemperature as Any,
                "gpuTemp": snap.thermal.gpuTemperature as Any,
                "sensors": snap.thermal.allSensors.map { ["key": $0.id, "label": $0.label, "value": round($0.value * 10) / 10, "category": $0.category.rawValue] },
                "fans": snap.thermal.fans.map { ["id": $0.id, "rpm": $0.currentRPM, "min": $0.minRPM, "max": $0.maxRPM] },
            ],
        ]

        if let battery = snap.battery {
            dict["battery"] = [
                "level": battery.level,
                "health": battery.health,
                "cycles": battery.cycleCount,
                "charging": battery.isCharging,
                "pluggedIn": battery.isPluggedIn,
            ]
        }

        if let gpu = snap.gpu {
            dict["gpu"] = [
                "name": gpu.name,
                "utilization": gpu.utilizationPercentage,
                "vramTotal": gpu.vramTotal as Any,
                "vramUsed": gpu.vramUsed as Any,
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return "{}" }
        return jsonString
    }

    private static func dashboardHTML(port: UInt16) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>MacVitals Dashboard</title>
        <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:radial-gradient(ellipse at center,#0f1124,#050510);color:#fff;min-height:100vh;padding:24px}
        h1{font-size:18px;font-weight:600;margin-bottom:20px;color:#00cce6}
        .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px}
        .card{background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.08);border-radius:12px;padding:14px}
        .card h2{font-size:12px;color:rgba(255,255,255,0.35);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px}
        .val{font-size:24px;font-weight:600;font-variant-numeric:tabular-nums}
        .sub{font-size:11px;color:rgba(255,255,255,0.5);margin-top:4px}
        .bar-bg{height:6px;background:rgba(255,255,255,0.08);border-radius:3px;margin-top:8px;overflow:hidden}
        .bar-fg{height:100%;border-radius:3px;transition:width 0.3s}
        .cyan{color:#00cce6}.green{color:#34c759}.orange{color:#ff9f0a}.red{color:#ff453a}.purple{color:#bf5af2}
        .status-bar{height:3px;background:linear-gradient(to right,#00cce6,#8033cc,#e6334a);border-radius:1.5px;margin-top:20px}
        #error{color:#ff453a;font-size:12px;margin-bottom:12px;display:none}
        </style>
        </head>
        <body>
        <h1>MacVitals</h1>
        <div id="error"></div>
        <div class="grid" id="grid"></div>
        <div class="status-bar"></div>
        <script>
        function fmt(b){if(b>1073741824)return(b/1073741824).toFixed(1)+' GB';if(b>1048576)return(b/1048576).toFixed(1)+' MB';if(b>1024)return(b/1024).toFixed(0)+' KB';return b+' B'}
        function fmtSpeed(b){return fmt(b)+'/s'}
        function barColor(p){return p>90?'#ff453a':p>70?'#ff9f0a':'#00cce6'}
        function card(title,val,sub,pct){let bar=typeof pct==='number'?`<div class="bar-bg"><div class="bar-fg" style="width:${Math.min(pct,100)}%;background:${barColor(pct)}"></div></div>`:'';return`<div class="card"><h2>${title}</h2><div class="val">${val}</div>${sub?`<div class="sub">${sub}</div>`:''}${bar}</div>`}
        async function poll(){
          try{
            const r=await fetch('/api/status');
            const d=await r.json();
            document.getElementById('error').style.display='none';
            let h='';
            h+=card('CPU',d.cpu.total.toFixed(1)+'%',d.cpu.cores.length+' cores',d.cpu.total);
            h+=card('Memory',d.memory.percentage.toFixed(1)+'%',fmt(d.memory.used)+' / '+fmt(d.memory.total),d.memory.percentage);
            h+=card('Storage',d.storage.percentage.toFixed(1)+'%','R: '+fmtSpeed(d.storage.readBytesPerSec)+' W: '+fmtSpeed(d.storage.writeBytesPerSec),d.storage.percentage);
            h+=card('Network ↓',fmtSpeed(d.network.downloadBytesPerSec),'↑ '+fmtSpeed(d.network.uploadBytesPerSec));
            if(d.gpu)h+=card('GPU',d.gpu.utilization.toFixed(1)+'%',d.gpu.name,d.gpu.utilization);
            if(d.battery)h+=card('Battery',d.battery.level.toFixed(0)+'%',d.battery.charging?'Charging':'Health: '+d.battery.health.toFixed(0)+'%',d.battery.level);
            if(d.thermal.cpuTemp!=null)h+=card('CPU Temp',d.thermal.cpuTemp.toFixed(1)+'°C',d.thermal.gpuTemp!=null?'GPU: '+d.thermal.gpuTemp.toFixed(1)+'°C':'');
            document.getElementById('grid').innerHTML=h;
          }catch(e){
            document.getElementById('error').textContent='Connection lost — retrying...';
            document.getElementById('error').style.display='block';
          }
        }
        poll();setInterval(poll,2000);
        </script>
        </body>
        </html>
        """
    }
}
