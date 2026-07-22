[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$destination = Join-Path $projectRoot 'wwwroot\uploads\colleges\administration-economics\documents'
$sqlDirectory = Join-Path $projectRoot 'SQL'

New-Item -ItemType Directory -Force -Path $destination | Out-Null
New-Item -ItemType Directory -Force -Path $sqlDirectory | Out-Null

$documents = @(
    [pscustomobject]@{
        Name = 'administration-economics-strategic-plan-2024-2029.pdf'
        Url = 'https://account.hilla-unc.edu.iq/wp-content/uploads/2025/11/%D8%A7%D9%84%D8%AE%D8%B7%D8%A9_%D8%A5%D8%B3%D8%AA%D8%B1%D8%A7%D8%AA%D9%8A%D8%AC%D9%8A%D9%91%D8%A91-%D8%A7%D9%84%D9%85%D8%AD%D8%A7%D8%B3%D8%A8%D8%A9.pdf'
        WebPath = '/uploads/colleges/administration-economics/documents/administration-economics-strategic-plan-2024-2029.pdf'
    },
    [pscustomobject]@{
        Name = 'administration-economics-self-evaluation-report.pdf'
        Url = 'https://account.hilla-unc.edu.iq/wp-content/uploads/2026/03/%D8%AA%D9%82%D8%B1%D9%8A%D8%B1-%D8%A7%D9%84%D8%AA%D9%82%D9%8A%D9%8A%D9%85-%D8%A7%D9%84%D8%B0%D8%A7%D8%AA%D9%8A-8-2.pdf'
        WebPath = '/uploads/colleges/administration-economics/documents/administration-economics-self-evaluation-report.pdf'
    }
)

function Test-PdfFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        if ($stream.Length -lt 5) {
            return $false
        }

        $buffer = New-Object byte[] 5
        [void]$stream.Read($buffer, 0, 5)
        return ([System.Text.Encoding]::ASCII.GetString($buffer) -eq '%PDF-')
    }
    finally {
        $stream.Dispose()
    }
}

$headers = @{
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) UniWebDocumentImporter/1.0'
    'Accept' = 'application/pdf,application/octet-stream;q=0.9,*/*;q=0.8'
}

foreach ($document in $documents) {
    $targetPath = Join-Path $destination $document.Name

    if (Test-PdfFile -Path $targetPath) {
        Write-Host "[OK] موجود وصحيح: $($document.Name)" -ForegroundColor Green
        continue
    }

    $tempPath = "$targetPath.download"
    Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue

    Write-Host "[DOWNLOAD] $($document.Name)" -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $document.Url -Headers $headers -UseBasicParsing -OutFile $tempPath -MaximumRedirection 10

        if (-not (Test-PdfFile -Path $tempPath)) {
            throw "الملف المستلم ليس PDF صحيحاً."
        }

        Move-Item -LiteralPath $tempPath -Destination $targetPath -Force
        Write-Host "[SAVED] $targetPath" -ForegroundColor Green
    }
    catch {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        Write-Host "[FAILED] تعذر تنزيل $($document.Name): $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "نزّل الملف يدوياً من الرابط الرسمي وضعه بالاسم نفسه داخل:" -ForegroundColor Yellow
        Write-Host $destination -ForegroundColor Yellow
    }
}

$sizeSqlPath = Join-Path $sqlDirectory 'AdministrationEconomics_Update_Document_Sizes.generated.sql'
$sqlLines = New-Object System.Collections.Generic.List[string]
$sqlLines.Add('SET NOCOUNT ON;')
$sqlLines.Add('')

foreach ($document in $documents) {
    $targetPath = Join-Path $destination $document.Name

    if (Test-PdfFile -Path $targetPath) {
        $size = (Get-Item -LiteralPath $targetPath).Length
        $safeWebPath = $document.WebPath.Replace("'", "''")
        $sqlLines.Add("UPDATE dbo.DocumentFiles SET FileSizeBytes = $size, ContentType = N'application/pdf', Extension = N'.pdf', IsPdf = 1, IsActive = 1, IsDeleted = 0 WHERE FilePath = N'$safeWebPath';")
    }
}

$sqlLines.Add('')
$sqlLines.Add("SELECT TitleAr, FilePath, FileSizeBytes, IsPdf, IsActive FROM dbo.DocumentFiles WHERE FilePath LIKE N'/uploads/colleges/administration-economics/documents/%' ORDER BY DisplayOrder, Id;")

[System.IO.File]::WriteAllLines($sizeSqlPath, $sqlLines, (New-Object System.Text.UTF8Encoding($true)))

Write-Host ''
Write-Host 'اكتملت العملية.' -ForegroundColor Green
Write-Host "مسار الملفات: $destination"
Write-Host "سكربت تحديث الأحجام: $sizeSqlPath"
Write-Host ''
Write-Host 'بعد ذلك نفّذ في SSMS:' -ForegroundColor Cyan
Write-Host '1) SQL\AdministrationEconomics_Internal_Pages_And_Documents.sql'
Write-Host '2) SQL\AdministrationEconomics_Update_Document_Sizes.generated.sql (اختياري بعد التنزيل)'
Write-Host '3) SQL\Verify_AdministrationEconomics_Internal_Pages.sql'
