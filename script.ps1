# PowerShell скрипт для стрима с vMix через ffmpeg с NVIDIA NVENC
# Чтение конфига
$config = @{}
Get-Content "config.env" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $config[$matches[1]] = $matches[2]
    }
}

# Функция для получения списка устройств
function Get-DirectShowDevices {
    Write-Host "Получение списка DirectShow устройств..."
    Start-Process -FilePath "ffmpeg" -ArgumentList "-f dshow -list_devices 1 -i dummy" -NoNewWindow -Wait -RedirectStandardOutput "devices.txt" -RedirectStandardError "devices_error.txt"
    if (Test-Path "devices.txt") {
        Get-Content "devices.txt"
    }
    if (Test-Path "devices_error.txt") {
        Get-Content "devices_error.txt"
    }
}

# Если LIST_DEVICES=1, вывести список и выйти
if ($config["LIST_DEVICES"] -eq "1") {
    Get-DirectShowDevices
    exit
}

# Проверка наличия ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ffmpeg не найден. Установите ffmpeg и добавьте в PATH."
    exit 1
}

# Сборка аргументов ffmpeg
$ffmpegArgs = @(
    "-f", "dshow",
    "-i", "video=`"$($config["VIDEO_DEV"])`":audio=`"$($config["AUDIO_DEV"])`"",
    "-c:v", $config["VIDEO_CODEC"],
    "-preset", $config["VIDEO_PRESET"],
    "-b:v", $config["VIDEO_BITRATE"],
    "-maxrate", $config["VIDEO_MAXRATE"],
    "-bufsize", $config["VIDEO_BUFSIZE"],
    "-g", $config["VIDEO_GOP"],
    "-rc", $config["VIDEO_RC"],
    "-c:a", $config["AUDIO_CODEC"],
    "-b:a", $config["AUDIO_BITRATE"],
    "-ar", $config["AUDIO_SAMPLE_RATE"],
    "-ac", $config["AUDIO_CHANNELS"],
    "-f", "flv",
    $config["RTMP_URL"]
)

Write-Host "Запуск ffmpeg с аргументами: $($ffmpegArgs -join ' ')"
Write-Host "Логи будут записаны в $($config["LOG_FILE"])"

# Цикл для перезапуска при падении
$restartCount = 0
while ($true) {
    $restartCount++
    Write-Host "Запуск ffmpeg (попытка $restartCount)..."

    $ffmpegCommand = "ffmpeg $($ffmpegArgs -join ' ') > $($config['LOG_FILE']) 2>&1"
    $process = Start-Process -FilePath "cmd" -ArgumentList "/c", $ffmpegCommand -NoNewWindow -Wait

    if ($process.ExitCode -eq 0) {
        Write-Host "ffmpeg завершился успешно."
        break
    } else {
        Write-Host "ffmpeg завершился с ошибкой $($process.ExitCode). Перезапуск через 5 секунд..."
        Start-Sleep -Seconds 5
    }
}
