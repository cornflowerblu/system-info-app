use libloading::{Library, Symbol};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Mutex;
use tauri::State;

// Define the function signatures matching the C++ library exports
type GetComputerNameStringFn = unsafe extern "C" fn(*mut c_char, i32) -> bool;
type GetTotalPhysicalMemoryFn = unsafe extern "C" fn() -> u64;
type GetCurrentProcessIDFn = unsafe extern "C" fn() -> u32;
type CalculateFactorialFn = unsafe extern "C" fn(i32) -> u64;

// Global library state
struct CppLibrary {
    lib: Mutex<Option<Library>>,
}

// Tauri commands
#[tauri::command]
fn get_computer_name(lib_state: State<CppLibrary>) -> Result<String, String> {
    let lib_guard = lib_state.lib.lock().unwrap();
    let lib = lib_guard.as_ref().ok_or("Library not loaded")?;

    unsafe {
        let get_name: Symbol<GetComputerNameStringFn> = lib
            .get(b"GetComputerNameString")
            .map_err(|e| e.to_string())?;

        let mut buffer = vec![0u8; 256];
        if get_name(buffer.as_mut_ptr() as *mut c_char, buffer.len() as i32) {
            let name = CStr::from_ptr(buffer.as_ptr() as *const c_char)
                .to_string_lossy()
                .into_owned();
            Ok(name)
        } else {
            Err("Failed to get computer name".to_string())
        }
    }
}

#[tauri::command]
fn get_total_memory(lib_state: State<CppLibrary>) -> Result<u64, String> {
    let lib_guard = lib_state.lib.lock().unwrap();
    let lib = lib_guard.as_ref().ok_or("Library not loaded")?;

    unsafe {
        let get_memory: Symbol<GetTotalPhysicalMemoryFn> = lib
            .get(b"GetTotalPhysicalMemory")
            .map_err(|e| e.to_string())?;

        Ok(get_memory())
    }
}

#[tauri::command]
fn get_process_id(lib_state: State<CppLibrary>) -> Result<u32, String> {
    let lib_guard = lib_state.lib.lock().unwrap();
    let lib = lib_guard.as_ref().ok_or("Library not loaded")?;

    unsafe {
        let get_pid: Symbol<GetCurrentProcessIDFn> = lib
            .get(b"GetCurrentProcessID")
            .map_err(|e| e.to_string())?;

        Ok(get_pid())
    }
}

#[tauri::command]
fn calculate_factorial(n: i32, lib_state: State<CppLibrary>) -> Result<u64, String> {
    let lib_guard = lib_state.lib.lock().unwrap();
    let lib = lib_guard.as_ref().ok_or("Library not loaded")?;

    unsafe {
        let calc_factorial: Symbol<CalculateFactorialFn> = lib
            .get(b"CalculateFactorial")
            .map_err(|e| e.to_string())?;

        Ok(calc_factorial(n))
    }
}

#[tauri::command]
fn get_platform() -> String {
    std::env::consts::OS.to_string()
}

// Load the C++ library
fn load_cpp_library() -> Result<Library, String> {
    // Get the path to the executable directory
    let exe_dir = std::env::current_exe()
        .ok()
        .and_then(|path| path.parent().map(|p| p.to_path_buf()));

    let lib_name = if cfg!(target_os = "windows") {
        "systemapi.dll"
    } else if cfg!(target_os = "macos") {
        "libsystemapi.dylib"
    } else {
        "libsystemapi.so"
    };

    // Try multiple paths in order of preference
    let paths_to_try = vec![
        // 1. Same directory as executable
        exe_dir.as_ref().map(|dir| dir.join(lib_name)),
        // 2. Windows: resources folder next to exe
        exe_dir.as_ref().map(|dir| dir.join("resources").join(lib_name)),
        // 3. macOS app bundle Resources directory
        exe_dir.as_ref().map(|dir| dir.join("../Resources").join(lib_name)),
        // 4. Development path
        Some(std::path::PathBuf::from(if cfg!(target_os = "windows") {
            "../cpp_cross_platform/build/bin/systemapi.dll"
        } else if cfg!(target_os = "macos") {
            "../cpp_cross_platform/build/lib/libsystemapi.dylib"
        } else {
            "../cpp_cross_platform/build/lib/libsystemapi.so"
        })),
    ];

    for path_option in paths_to_try {
        if let Some(path) = path_option {
            if path.exists() {
                unsafe {
                    match Library::new(&path) {
                        Ok(lib) => {
                            println!("✓ Loaded C++ library from: {}", path.display());
                            return Ok(lib);
                        }
                        Err(e) => {
                            eprintln!("Failed to load from {}: {}", path.display(), e);
                        }
                    }
                }
            }
        }
    }

    Err(format!(
        "Failed to load library '{}' from any location.\n\n\
        For development, make sure to build the C++ library first:\n\
        cd cpp_cross_platform && mkdir build && cd build && cmake .. && cmake --build .",
        lib_name
    ))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Load the C++ library
    let library = match load_cpp_library() {
        Ok(lib) => {
            println!("✓ C++ library loaded successfully!");
            Some(lib)
        }
        Err(e) => {
            eprintln!("⚠ Warning: {}", e);
            eprintln!("The app will run but system info features will be unavailable.");
            None
        }
    };

    let cpp_lib_state = CppLibrary {
        lib: Mutex::new(library),
    };

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .manage(cpp_lib_state)
        .invoke_handler(tauri::generate_handler![
            get_computer_name,
            get_total_memory,
            get_process_id,
            calculate_factorial,
            get_platform
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
