Using Module CommonConst
Set-Alias -Name JP -Value Join-Path
$env:MyWorkPCName = "D-280195020014"




# TRANING ============================================
if (!$MyWorkPC) {Set-Variable -Name MyWorkPC -Value $env:MyWorkPCName -Option Constant}

if ($env:COMPUTERNAME -eq $MyWorkPC) {
	$TraningPath 	= 'F:\WORK\TRAINING'
	$Disk 			= 'E:\'
}
else {
	$TraningPath 	= 'D:\POPOVAV\TRAINING'
	$Disk 			= 'D:\'
}

cd $TraningPath

if( !(Test-Path Variable:global:GV_GlobalHashBox) ) { $global:GV_GlobalHashBox = @{} }

$BoxName 		= 'ТекДатаВремя'
$ValueObject 	= Get-Date

$global:GV_GlobalHashBox.$BoxName = $ValueObject
$global:GV_GlobalHashBox.'Test2' = 'TEST STRING VALUE'





$FilesPath 			= Join-Path $TraningPath 'ФАЙЛЫ'
$CryptFileName 		= 'FileToCrypt.txt'
$FullCryptFileName 	= JP $FilesPath $CryptFileName

$CryptFileContent 	= Get-Content -Path $FullCryptFileName


# 3 EXCEL =================================
$TraningExcelFilePath 	= JP $TraningPath 'EXCEL'
$DestPartPath 			= JP $TraningPath 'TMP_PART'


$DestPartFileName 		= [System.IO.Path]::GetFileNameWithoutExtension($CryptFileName)
$DestFileExt  			= [System.IO.Path]::GetExtension($CryptFileName)

$PartNo 	= 1
$ReadBlok 	= 5 

$FormatLine 			= '{0}_Part-{1:0000}{2}'

$TraningBookName 		= 'TRANING_v8.xlsm'
$TraningModuleFullPath 	= JP $TraningExcelFilePath $TraningBookName

$TraningShName 			= 'ПРОБНЫЙ_ЛИСТ'



#--------------------------------------------------------
# 3.2 ---------------------------------------------------
#$excel = New-Object -ComObject Excel.Application | Out-Null

#$ObjTraningBook = $excel.Workbooks.Open($TraningModuleFullPath)

#$ObjTestSh = $ObjTraningBook.Worksheets($TraningShName)


#--------------------------------------------------------
# 4. REGEXP ---------------------------------------------
$NewCryptPath = JP $TraningPath 'TMP_NEWCRYPT'
#New-Item -Path $NewCryptPath -ItemType Directory -Force | Out-Null

$FinalDatePat 		= '(?:\D|\s|^)(?:0[1-9]|[12]\d|3[01])\.(?:0[1-9]|1[0-2])\.(?:19\d\d|20(?:[01]\d|2[0-3]))(?:\D|\s|$)'
$DoubleWordPattern 	= '\b(\w+)\s+\1\b'
$SeparThous 		= '(\d)(?=(\d{3})+(?!\d))'


#--------------------------------------------------------
# 5. CREATE CSV -----------------------------------------
	
$DestCSVPath 	= JP $TraningPath 'TMP_CSV'
#New-Item -Path $DestCSVPath -ItemType Directory -Force | Out-Null

	$PrefixABS   = '\\?\'	
	$PathScan	 = $PrefixABS + $TraningPath

	if ($PrefixABS = '\\?\') {$OutCSVFileScan = JP $DestCSVPath 'ScanList_ABS.csv'}`
	else {$OutCSVFileScan = JP $DestCSVPath 'ScanList.csv'}	

	if( $PathScan.StartsWith('\\?\') ) { $SplatPath = @{LiteralPath = $PathScan} } `
	else 							   { $SplatPath = @{Path = $PathScan} }
	
	$PrefixLen = $PrefixABS.Length	# если префикс не задан - длина префикса 0





#--------------------------------------------------------
# 5.1 
$BigCSVPath 	= JP $TraningPath 'ПРИМЕРЫ\PowerShell'
$BigCSVFile 	= JP $BigCSVPath 'l4i26051_SCAN.csv'

#--------------------------------------------------------
# 5.2 100 LINES
$Test100Path 	= JP $TraningPath 'TMP_100Lines'
#New-Item -Path $Test100Path -ItemType Directory -Force | Out-Null

$TestFile100 	= JP $Test100Path  'PSTestFile_100_Lines.txt'


#--------------------------------------------------------
# 6. ROBOCOPY

$SourcePath 	= JP $TraningPath 'DOC'	

$DestCopyPath 	= JP $Disk  'TRAINING_TEMP\RoboCopy\Traning\Doc'

$LogPath		= JP $Disk  'Temp'
#New-Item -Path $LogPath -ItemType Directory -Force  | Out-Null	

$LogName		= 'LogTraningRoboCopy.log'

$LogFullName 	= JP $LogPath $LogName	








#cd k:\WORK_PC\PROJECT\PSScripts


