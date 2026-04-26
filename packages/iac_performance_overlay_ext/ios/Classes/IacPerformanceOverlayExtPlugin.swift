import Flutter
import UIKit
import Darwin.Mach

public class IacPerformanceOverlayExtPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "iac_performance_overlay_ext",
            binaryMessenger: registrar.messenger()
        )
        let instance = IacPerformanceOverlayExtPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCpuUsage":
            result(getCpuUsage())
        case "getMemoryInfo":
            result(getMemoryInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // -------------------------------------------------------------------------
    // CPU — app process threads vs total CPU capacity
    //
    // Iterates all threads of this process via task_threads and sums each
    // thread's cpu_usage (0…TH_USAGE_SCALE=1000, per-core fraction).
    // Dividing by (numCores * TH_USAGE_SCALE) normalises to 0–100 % of the
    // total machine CPU, matching the Android /proc/self/stat approach.
    // -------------------------------------------------------------------------

    private func getCpuUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        guard task_threads(mach_task_self_, &threadList, &threadCount) == KERN_SUCCESS,
              let threadList = threadList else { return 0 }

        defer {
            let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), size)
        }

        var totalUsage: Double = 0

        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size)
            let kr = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(threadList[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            guard kr == KERN_SUCCESS else { continue }
            // Skip idle threads
            if info.flags & TH_FLAGS_IDLE != 0 { continue }
            // cpu_usage is 0…TH_USAGE_SCALE (1000) per core
            totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE)
        }

        // Normalise: divide by number of cores → 0–100 % of total machine CPU
        let numCores = Double(ProcessInfo.processInfo.processorCount)
        return min(totalUsage / numCores * 100.0, 100.0)
    }

    // -------------------------------------------------------------------------
    // Memory
    // -------------------------------------------------------------------------

    private func getMemoryInfo() -> [String: Int64] {
        let totalMem = Int64(ProcessInfo.processInfo.physicalMemory)

        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        let usedMem = kr == KERN_SUCCESS ? Int64(info.phys_footprint) : 0
        return ["usedMem": usedMem, "totalMem": totalMem]
    }
}
