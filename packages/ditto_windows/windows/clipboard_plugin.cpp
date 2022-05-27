#include "include/ditto_windows/clipboard_plugin.h"
#include "include/ditto_windows/raii_clipboard.h"
#include "include/ditto_windows/encoding.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

namespace
{
    class ClipboardPlugin : public flutter::Plugin
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
        ClipboardPlugin();
        virtual ~ClipboardPlugin();

    private:
        enum DataType
        {
            text = 0,
            html,
        };

        unsigned int m_html_format;

        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        /**
         * @brief Gets the current clipboard data in the given formatId.
         *
         * If the current data is not available for formatId, and empty string is
         * going to be returned.
         *
         * @param formatId
         * @return std::string
         */
        std::string GetClipboardData(unsigned int formatId);

        /**
         * @brief Sets the current clipboard data using the specifyed formatId.
         *
         * @param formatId
         * @param data
         */
        void SetClipboardData(unsigned int formatId, std::string data);

        /**
         * @brief Checks if the given format is available for the current clipboard content.
         * 
         * @param dataType 
         * @return true 
         * @return false 
         */
        bool IsFormatAvailable(DataType dataType);

        /**
         * @brief Converts the plugin DataType to the respective Windows Clipboard Format.
         *
         * @param dataType
         * @return unsigned int
         */
        unsigned int ToClipboardFormat(DataType dataType);

        /**
         * @brief Gets a list of all custom formats currently available.
         * 
         * @return std::vector<std::string> 
         */
        std::vector<std::string> GetCustomClipboardFormats();

        /**
         * @brief Gets all supported format ids.
         * 
         * @return std::vector<unsigned int> 
         */
        std::vector<unsigned int> GetClipboardFormatIds();

        /**
         * @brief Gets the error message from the last error thrown in the current
         * system thread. Uses the GetLastError call.
         */
        std::string GetSystemLastErrorMessage();
    };

    // static
    void ClipboardPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarWindows *registrar)
    {
        auto channel =
            std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "clipboard_plugin",
                &flutter::StandardMethodCodec::GetInstance());

        auto plugin = std::make_unique<ClipboardPlugin>();

        channel->SetMethodCallHandler(
            [plugin_pointer = plugin.get()](const auto &call, auto result)
            {
                plugin_pointer->HandleMethodCall(call, std::move(result));
            });

        registrar->AddPlugin(std::move(plugin));
    }

    ClipboardPlugin::ClipboardPlugin()
    {
        m_html_format = RegisterClipboardFormatA("HTML Format");
    }

    ClipboardPlugin::~ClipboardPlugin() {}

    void ClipboardPlugin::HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        try
        {
            if (method_call.method_name().compare("getClipboardData") == 0)
            {
                const auto* data_type = std::get_if<int>(method_call.arguments());
                if (!data_type)
                {
                    result->Error("Missing required type parameter", "Expected int");
                    return;
                }
                auto data =  GetClipboardData(ToClipboardFormat(static_cast<DataType>(*data_type)));
                result->Success(flutter::EncodableValue(data));
            }
            else if (method_call.method_name().compare("setClipboardData") == 0)
            {
                const auto* clipboardContent = std::get_if<flutter::EncodableMap>(method_call.arguments());
                if (!clipboardContent) {
                    result->Error("Bad arguments", "Expected a map of <int, std::string>");
                    return;
                }
                
                RaiiClipboard clipboard;
                EmptyClipboard();
                for (auto data : *clipboardContent)
                {
                    auto data_type = static_cast<DataType>(std::get<int>(data.first));
                    auto content = std::get<std::string>(data.second);
                    SetClipboardData(ToClipboardFormat(data_type), content);
                }
                result->Success();
            } 
            else if (method_call.method_name().compare("hasDataType") == 0)
            {
                const auto* data_type = std::get_if<int>(method_call.arguments());
                if (!data_type)
                {
                    result->Error("Missing required type parameter", "Expected int");
                    return;
                }
                result->Success(flutter::EncodableValue(IsFormatAvailable(static_cast<DataType>(*data_type))));
            }
            else
            {
                result->NotImplemented();
            }
        }
        catch (const std::exception &e)
        {
            auto error_message = GetSystemLastErrorMessage();
            std::cerr << e.what() << std::endl
                      << error_message << std::endl;
            result->Error(e.what(), error_message);
        }
    }

    std::string ClipboardPlugin::GetClipboardData(unsigned int format_id)
    {
        RaiiClipboard clipboard;
        if (!IsClipboardFormatAvailable(format_id))
        {
            return "";
        }

        auto data = ::GetClipboardData(format_id);
        if (nullptr == data)
        {
            throw std::runtime_error("Can't get clipboard data.");
        }

        // Always use unicode when we are working with the text format.
        if (CF_UNICODETEXT == format_id)
        {
            RaiiGlobalLock<const wchar_t> lock(data);
            return Encoding::WideToUtf8(std::wstring(lock.Get()));
        }
        RaiiGlobalLock<const char> lock(data);
        return std::string(lock.Get());
    }

    void ClipboardPlugin::SetClipboardData(unsigned int formatId, std::string data)
    {
        HGLOBAL handle = nullptr;

        // When working with Unicode, we must use a wchar_t buffer.
        if (CF_UNICODETEXT == formatId)
        {
            const auto wide_str = Encoding::Utf8ToWide(data);
            handle = GlobalAlloc(GMEM_MOVEABLE, wide_str.size() * sizeof(wchar_t) + 2);
            if (nullptr == handle)
            {
                throw std::runtime_error("Failed to GlobalAlloc");
            }
            RaiiGlobalLock<wchar_t> globalLock(handle);
            wcscpy_s(globalLock.Get(), wide_str.size() + 1, wide_str.c_str());
        }
        else 
        {
            auto buffer_size = data.size() + 1;
            handle = GlobalAlloc(GMEM_MOVEABLE, buffer_size);
            if (nullptr == handle)
            {
                throw std::runtime_error("Failed to GlobalAlloc");
            }

            RaiiGlobalLock<char> globalLock(handle);
            strcpy_s(globalLock.Get(), buffer_size, data.c_str());
        }
        
        if (!::SetClipboardData(formatId, handle))
        {
            throw std::runtime_error("Failed to SetClipboardData");
        }
    }

    bool ClipboardPlugin::IsFormatAvailable(DataType dataType)
    {
        return IsClipboardFormatAvailable(ToClipboardFormat(dataType));
    }

    unsigned int ClipboardPlugin::ToClipboardFormat(DataType dataType)
    {
        switch (dataType)
        {
        case DataType::text:
            return CF_UNICODETEXT;
        case DataType::html:
            return m_html_format;
        default:
            return 0;
        }
    }

    std::vector<std::string> ClipboardPlugin::GetCustomClipboardFormats()
    {
        auto formatIds = GetClipboardFormatIds();
        auto formatNames = std::vector<std::string>();
        for (auto id : formatIds)
        {
            char name[256];
            if (GetClipboardFormatNameA(id, &name[0], 256) != 0)
            {
                formatNames.push_back(std::string(name));
            }
        }
        return formatNames;
    }

    std::vector<unsigned int> ClipboardPlugin::GetClipboardFormatIds()
    {
        unsigned int formatsCount = CountClipboardFormats();
        if (0 == formatsCount)
        {
            throw std::runtime_error("Failed to get clipoard formats.");
        }

        auto formats = std::vector<unsigned int>(formatsCount);
        if (GetUpdatedClipboardFormats(&formats.front(), formatsCount, &formatsCount))
        {
            return formats;
        }

        throw std::runtime_error("Failed to get clipoard formats.");
    }

    std::string ClipboardPlugin::GetSystemLastErrorMessage()
    {
        std::ostringstream stream;
        auto error = GetLastError();
        LPSTR errorText = nullptr;
        FormatMessageA(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS,
            nullptr,
            error,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPSTR)&errorText,
            0,
            nullptr);
        if (nullptr != errorText)
        {
            stream << "System error code: " << error << std::endl
                   << "Error description: " << errorText;
            LocalFree(errorText);
        }
        return stream.str();
    }
}

void ClipboardPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    ClipboardPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
