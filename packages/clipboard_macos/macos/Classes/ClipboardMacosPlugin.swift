import Cocoa
import FlutterMacOS

public class ClipboardMacosPlugin: NSObject, FlutterPlugin {

    var pasteboard : NSPasteboard {
        get {
            return NSPasteboard.general;
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clipboard_macos", binaryMessenger: registrar.messenger)
        let instance = ClipboardMacosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getClipboardData":
            return getClipboardData(call, result: result)
        case "hasDataType":
            return hasDataType(call, result: result)
        case "setClipboardData":
            return setClipboardData(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func getClipboardData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let dataType: NSPasteboard.PasteboardType = call.getDataTypeArgument() else {
            return result(FlutterError(code: "ERROR", message: "Invalid or missing data type argument", details: nil))
        }
        let pasteboardData = pasteboard.string(forType: dataType)
        result(pasteboardData);
    }

    func hasDataType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let dataType: NSPasteboard.PasteboardType = call.getDataTypeArgument() else {
            return result(FlutterError(code: "ERROR", message: "Invalid or missing data type argument", details: nil))
        }
        let canRead = pasteboard.string(forType: dataType);
        result(canRead)
    }

    func setClipboardData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let dataMap: [Int: String] = call.getArgument(label: "dataMap") else {
            return result(FlutterError(code: "ERROR", message: "Invalid or missing dataMap argument", details: nil))
        }
        if #available(macOS 10.12, *) {
            pasteboard.prepareForNewContents(with: [])
        } else {
            pasteboard.clearContents()
        }
        for (dataTypeIndex, content) in dataMap {
            guard let dataType: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType.fromIndex(index: dataTypeIndex) else {
                return result(FlutterError(code: "ERROR", message: "Invalid data type key", details: nil))
            }
            pasteboard.setString(content, forType: dataType)
        }
        result(true)
    }

}

/**
 Helper methods to get arguments from a method call
 */
extension FlutterMethodCall {
    
    /**
     Gets an argument with a specific label, Returns nil if argument not found,
     */
    func getArgument<T>(label: String) -> T? {
        guard let argumentValue: T = (self.arguments as? [String: Any])?[label] as? T else {
            return nil;
        }
        return argumentValue
    }
    
    /**
     Specifically gets the data type argument and tries to parse it into a PasteboardType
     */
    func getDataTypeArgument() -> NSPasteboard.PasteboardType? {
        guard let dataTypeIndex: Int = getArgument(label: "dataType") else {
            return nil
        }
        guard let dataType: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType.fromIndex(index: dataTypeIndex) else {
            return nil
        }

        return dataType;
    }

}



extension NSPasteboard.PasteboardType {
    static func fromIndex(index: Int) -> NSPasteboard.PasteboardType? {
        switch index {
        case 0:
            return .string;
        case 1:
            return .html;
        default:
            return nil;
        }
    }
}
