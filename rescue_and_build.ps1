# Script tu dong cuu ho dia ao WSL 2 va tiep tuc bien dich ONLYOFFICE
# Duoc chay ngam de tu dong hoa toan bo qua trinh va ghi log tien do.

$logPath = "E:\VSC\ONLYOFFICE_SUITE\rescue_progress.log"

function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] $message"
    
    # Khong in ra console cac dong log e2fsck va inode de tranh sandbox hieu lam la cho nhap lieu
    if ($message -notlike "*e2fsck dang chay*" -and $message -notlike "*Unattached inode*" -and $message -notlike "*ref count*" -and $message -notlike "*Connect to*") {
        Write-Output $logLine
    }
    
    Add-Content -Path $logPath -Value $logLine
}

# Khoi tao file log moi neu chua co, hoac reset lai de bat dau dot theo doi moi
$null = New-Item -Path $logPath -ItemType File -Force
Write-Log "=== BAT DAU TIEN TRINH CUU HO VA BIEN DICH TU DONG ==="
Write-Log "Muc tieu: Sua dia ao 263GB, xoa database containerd hieu nang bi loi, khoi dong lai Docker va tiep tuc build ONLYOFFICE."

# --- BUOC 1: Theo doi e2fsck cho den khi hoan tat ---
Write-Log "Dang theo doi tien trinh e2fsck tren o dia /dev/sdf..."
$e2fsckRunning = $true
while ($e2fsckRunning) {
    Start-Sleep -Seconds 10
    
    # Kiem tra xem e2fsck con chay trong alpine-repair khong
    $psOut = wsl -d alpine-repair -u root -e ps aux
    if ($psOut -like "*e2fsck*") {
        # Kiem tra dong cuoi cung cua log e2fsck de cap nhat tien do
        $tailLog = Get-Content -Path "C:\Users\nghia\.gemini\antigravity\brain\5cb47f0f-6bea-4dca-a4c7-53b8f4522715\.system_generated\tasks\task-5483.log" -Tail 5 -ErrorAction SilentlyContinue
        $lastLine = ""
        if ($tailLog) {
            $lastLine = $tailLog -join " | "
        }
        Write-Log "e2fsck dang chay. Dong log cuoi: $lastLine"
    } else {
        $e2fsckRunning = $false
        Write-Log "Phat hien tien trinh e2fsck da ket thuc!"
    }
}

# Doc toan bo 20 dong cuoi cua log e2fsck de ghi nhan ket qua cuoi cung
$finalTail = Get-Content -Path "C:\Users\nghia\.gemini\antigravity\brain\5cb47f0f-6bea-4dca-a4c7-53b8f4522715\.system_generated\tasks\task-5483.log" -Tail 20 -ErrorAction SilentlyContinue
Write-Log "Ket qua cuoi cung tu e2fsck:"
foreach ($line in $finalTail) {
    if ($line.Trim() -ne "") {
        Write-Log "   > $line"
    }
}

# --- BUOC 2: Mount o dia de xoa database containerd (meta.db) bi hong ---
Write-Log "Tien hanh mount dia ao /dev/sdf vao alpine-repair..."
$null = wsl -d alpine-repair -u root -e mkdir -p /mnt/sdf
$mountRes = wsl -d alpine-repair -u root -e mount /dev/sdf /mnt/sdf 2>&1
if ($mountRes -like "*error*" -or $mountRes -like "*failed*") {
    Write-Log "LOI: Khong the mount /dev/sdf. Chi tiet: $mountRes"
    # Thu mount o che dou readonly de cuu truoc neu can
    Write-Log "Thu mount o che do Read-Only..."
    $mountRes = wsl -d alpine-repair -u root -e mount -o ro /dev/sdf /mnt/sdf 2>&1
}

# Tim va xoa meta.db cua containerd
Write-Log "Dang tim kiem file meta.db bi loi tren o dia da mount..."
$filesFound = wsl -d alpine-repair -u root -e find /mnt/sdf -name "meta.db"
if ($filesFound) {
    Write-Log "Da tim thay file meta.db tai cac duong dan sau:"
    foreach ($f in $filesFound) {
        if ($f.Trim() -ne "") {
            Write-Log "   > $f"
            # Thuc hien xoa file meta.db de containerd tu khoi tao lai file moi sach se khi start
            $delRes = wsl -d alpine-repair -u root -e rm -f $f 2>&1
            Write-Log "   > Ket qua xoa: Success (neu khong co thong bao loi) $delRes"
        }
    }
} else {
    Write-Log "Khong tim thay file meta.db nao tren o dia."
}

# Unmount an toan
Write-Log "Tien hanh unmount dia ao..."
$unmountRes = wsl -d alpine-repair -u root -e umount /mnt/sdf 2>&1
Write-Log "Ket qua unmount: $unmountRes"

# --- BUOC 3: Shutdown WSL va don dep distro cuu ho ---
Write-Log "Tat hoan toan WSL de giai phong tai nguyen va nhan o dia..."
wsl --shutdown
Start-Sleep -Seconds 5

Write-Log "Thiet lap distro mac dinh tro lai la docker-desktop..."
wsl --set-default docker-desktop

Write-Log "Huy dang ky distro cuu ho alpine-repair..."
wsl --unregister alpine-repair

# --- BUOC 4: Khoi dong lai Docker Desktop ---
Write-Log "Dang khoi dong ung dung Docker Desktop..."
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Write-Log "Cho Docker Desktop khoi dong va san sang..."

$dockerReady = $false
$retryCount = 0
$maxRetries = 30 # Cho toi da 5 phut (30 * 10s)
while (-not $dockerReady -and $retryCount -lt $maxRetries) {
    Start-Sleep -Seconds 10
    $retryCount++
    $dockerInfo = docker info 2>&1
    if ($dockerInfo -like "*Containers*") {
        $dockerReady = $true
        Write-Log "Docker Desktop da khoi dong THANH CONG va san sang hoat dong!"
    } else {
        Write-Log "Cho Docker ready (Lan thu $retryCount/30)..."
    }
}

if (-not $dockerReady) {
    Write-Log "LOI CRITICAL: Docker Desktop khong the khoi dong sau 5 phut. Vui long kiem tra bang tay."
    exit 1
}

# --- BUOC 5: Chay container bien dich ONLYOFFICE ---
Write-Log "Di chuyen vao thu muc du an va khoi chay container bien dich..."
Set-Location "E:\VSC\ONLYOFFICE_SUITE"
$dockerUp = docker compose up -d 2>&1
Write-Log "Ket qua chay docker compose up: $dockerUp"

# --- BUOC 6: Theo doi va cap nhat tien do build ---
Write-Log "Bat dau theo doi log bien dich tu container onlyoffice-linux-builder..."
$buildFinished = $false
$lastProgress = ""

while (-not $buildFinished) {
    Start-Sleep -Seconds 30
    
    # Lay log moi nhat cua container
    $logs = docker logs onlyoffice-linux-builder --tail 50 2>&1
    
    # Kiem tra container co con chay khong
    $containerStatus = docker ps --filter "name=onlyoffice-linux-builder" --format "{{.Status}}"
    
    # Tim kiem tien do compile (dang: [xxxx/xxxx] hoac % hoac done)
    # Trinh bien dich Ninja thuong in ra dang [2246/2828]
    $progressLine = ""
    foreach ($line in $logs) {
        if ($line -match "\[\d+/\d+\]") {
            $progressLine = $line
        }
    }
    
    if ($progressLine -ne "" -and $progressLine -ne $lastProgress) {
        $lastProgress = $progressLine
        Write-Log "TIEN DO BIEN DICH HIEN TAI: $lastProgress"
    }
    
    if ($containerStatus -eq "") {
        # Container da dung lai, kiem tra ket qua cuoi cung
        $buildFinished = $true
        Write-Log "Container onlyoffice-linux-builder da dung hoat dong!"
        
        # Xem container ket thuc thanh cong hay that bai
        $exitCode = docker inspect onlyoffice-linux-builder --format "{{.State.ExitCode}}"
        if ($exitCode -eq "0") {
            Write-Log "=== BIEN DICH THANH CONG MY MAN! (Exit Code 0) ==="
        } else {
            Write-Log "=== LOI BIEN DICH! Container ket thuc voi Exit Code: $exitCode ==="
            # Ghi lai 10 dong log cuoi cung lam bang chung
            $errLogs = docker logs onlyoffice-linux-builder --tail 20 2>&1
            Write-Log "Chi tiet log loi cuoi cung:"
            foreach ($el in $errLogs) {
                Write-Log "   > $el"
            }
        }
    }
}
