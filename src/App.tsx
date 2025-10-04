import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";

interface SystemInfo {
  computerName: string;
  totalMemory: number;
  processId: number;
  platform: string;
}

function App() {
  const [systemInfo, setSystemInfo] = useState<SystemInfo>({
    computerName: "Loading...",
    totalMemory: 0,
    processId: 0,
    platform: "unknown"
  });
  const [factorialInput, setFactorialInput] = useState(10);
  const [factorialResult, setFactorialResult] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSystemInfo = async () => {
    setLoading(true);
    setError(null);

    try {
      const [computerName, totalMemory, processId, platform] = await Promise.all([
        invoke<string>("get_computer_name"),
        invoke<number>("get_total_memory"),
        invoke<number>("get_process_id"),
        invoke<string>("get_platform")
      ]);

      setSystemInfo({
        computerName,
        totalMemory,
        processId,
        platform
      });

      // Also calculate factorial on load
      const factorial = await invoke<number>("calculate_factorial", { n: factorialInput });
      setFactorialResult(factorial);
    } catch (err) {
      setError(err as string);
      console.error("Error fetching system info:", err);
    } finally {
      setLoading(false);
    }
  };

  const calculateFactorial = async (n: number) => {
    try {
      const result = await invoke<number>("calculate_factorial", { n });
      setFactorialResult(result);
    } catch (err) {
      console.error("Error calculating factorial:", err);
    }
  };

  useEffect(() => {
    fetchSystemInfo();
  }, []);

  useEffect(() => {
    calculateFactorial(factorialInput);
  }, [factorialInput]);

  const formatBytes = (bytes: number): string => {
    const gb = bytes / (1024 * 1024 * 1024);
    return gb.toFixed(2);
  };

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-50 to-red-100 dark:from-gray-900 dark:to-gray-800 p-8">
        <div className="max-w-2xl mx-auto">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 border-l-4 border-red-500">
            <h2 className="text-2xl font-bold text-red-600 dark:text-red-400 mb-4">
              ❌ Error Loading C++ Library
            </h2>
            <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap mb-4">
              {error}
            </p>
            <button
              onClick={fetchSystemInfo}
              className="bg-red-500 hover:bg-red-600 text-white font-semibold py-2 px-4 rounded-lg transition-colors"
            >
              🔄 Retry
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 p-8">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-800 dark:text-white mb-2">
            🖥️ System Information Dashboard
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Platform: <span className="font-semibold">{systemInfo.platform}</span>
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
            React Frontend → Tauri (Rust) → C++ FFI
          </p>
        </div>

        {loading ? (
          <div className="flex justify-center items-center py-20">
            <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-500"></div>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Computer Name Card */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 transform transition-all hover:scale-105">
              <div className="flex items-center mb-2">
                <span className="text-3xl mr-3">💻</span>
                <h2 className="text-xl font-semibold text-gray-700 dark:text-gray-300">
                  Computer Name
                </h2>
              </div>
              <p className="text-3xl font-bold text-blue-600 dark:text-blue-400 ml-12">
                {systemInfo.computerName}
              </p>
            </div>

            {/* Memory Card */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 transform transition-all hover:scale-105">
              <div className="flex items-center mb-2">
                <span className="text-3xl mr-3">🧠</span>
                <h2 className="text-xl font-semibold text-gray-700 dark:text-gray-300">
                  System Memory
                </h2>
              </div>
              <p className="text-3xl font-bold text-green-600 dark:text-green-400 ml-12">
                {formatBytes(systemInfo.totalMemory)} GB
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400 ml-12 mt-1">
                ({systemInfo.totalMemory.toLocaleString()} bytes)
              </p>
            </div>

            {/* Process ID Card */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 transform transition-all hover:scale-105">
              <div className="flex items-center mb-2">
                <span className="text-3xl mr-3">⚙️</span>
                <h2 className="text-xl font-semibold text-gray-700 dark:text-gray-300">
                  Current Process ID
                </h2>
              </div>
              <p className="text-3xl font-bold text-purple-600 dark:text-purple-400 ml-12">
                {systemInfo.processId}
              </p>
            </div>

            {/* Factorial Calculator Card */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
              <div className="flex items-center mb-4">
                <span className="text-3xl mr-3">🔢</span>
                <h2 className="text-xl font-semibold text-gray-700 dark:text-gray-300">
                  C++ Template Factorial Calculator
                </h2>
              </div>
              <div className="ml-12">
                <div className="mb-4">
                  <label className="block text-gray-600 dark:text-gray-400 mb-2">
                    Input (n): {factorialInput}
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="20"
                    value={factorialInput}
                    onChange={(e) => setFactorialInput(parseInt(e.target.value))}
                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 accent-orange-500"
                  />
                </div>
                <p className="text-2xl font-bold text-orange-600 dark:text-orange-400">
                  {factorialInput}! = {factorialResult?.toLocaleString() || "..."}
                </p>
              </div>
            </div>

            {/* Refresh Button */}
            <div className="flex justify-center pt-4">
              <button
                onClick={fetchSystemInfo}
                className="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-3 px-8 rounded-lg shadow-md transition-all transform hover:scale-105 flex items-center gap-2"
              >
                <span>🔄</span>
                <span>Refresh All Data</span>
              </button>
            </div>

            {/* Footer */}
            <div className="text-center pt-8 pb-4">
              <p className="text-gray-500 dark:text-gray-400 italic text-sm">
                This data is fetched from cross-platform C++ code!
              </p>
              <p className="text-gray-500 dark:text-gray-400 italic text-sm">
                React ❤️ Tauri ❤️ Rust ❤️ C++
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
