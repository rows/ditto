#include <exception>
#include <iostream>
#include <ostream>
#include <stdexcept>
#include <string>
#include <windows.h>

/**
 * @brief RAII pattern implementation for Clipboard management.
 * 
 * Once we take ownership of the system's clipboard, we have to make sure
 * to close it once we are done. 
 * 
 * @see https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-openclipboard
 */
class RaiiClipboard
{
public:
    RaiiClipboard()
    {
        if (!OpenClipboard(nullptr))
        {
            throw std::runtime_error("Can't open clipboard.");
        }
    }

    ~RaiiClipboard()
    {
        CloseClipboard();
    }

private:
    RaiiClipboard(const RaiiClipboard &);
    RaiiClipboard &operator=(const RaiiClipboard &);
};

/**
 * @brief RAII pattern implementation to aquire a lock to a HANDLE.
 * 
 */
template<class T>
class RaiiGlobalLock
{
public:
    explicit RaiiGlobalLock(HANDLE data_handle)
        : m_data_handle(data_handle)
    {
        m_plock = static_cast<T*>(GlobalLock(m_data_handle));
        if (!m_plock)
        {
            throw std::runtime_error("Can't acquire lock on clipboard data.");
        }
    }

    ~RaiiGlobalLock()
    {
        GlobalUnlock(m_data_handle);
    }

    /**
     * @brief Gets the content of the locked handle.
     * 
     * @return const char* 
     */
    T* Get()
    {
        return m_plock;
    }

private:
    HANDLE m_data_handle;
    T* m_plock;

    RaiiGlobalLock(const RaiiGlobalLock &);
    RaiiGlobalLock &operator=(const RaiiGlobalLock &);
};
