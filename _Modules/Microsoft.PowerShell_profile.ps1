Using Module CommonConst
Set-Alias -Name JP -Value Join-Path
$env:MyWorkPCName = "MainPC"

# TRAINING ===========================================
$TrainingPath =	switch ($env:COMPUTERNAME){
			'MainPC' { $Disk = 'D:\'; 'D:\PAPA\PROJECT\EXCEL\TRAINING' }		# домашний компьютер
			'WorkPC' { $Disk = 'D:\'; 'E:\LEARNING\PROJECT\EXCEL\TRAINING' }	# мой рабочий компьютер
			'WorkNB' { $Disk = 'X:\'; 'Z:\PROJECT\EXCEL\TRAINING' }			# мой рабочий ноутбук
			'HomeNB' { $Disk = 'Z:\'; 'C:\PROJECT\EXCEL\TRAINING' }			# домашний ноутбук
			# ...
			default { $Disk = $null; $null }
		}

cd $TrainingPath

if ( ! (Test-Path TRPS:) ) {
	New-PSdrive -Name TRPS -PSprovider Filesystem -Root $TrainingPath  | Out-Null
}



if( !(Test-Path Variable:global:GV_GlobalHashBox) ) { $global:GV_GlobalHashBox = @{} }

$BoxName 		= 'ТекДатаВремя'
$ValueObject 	= Get-Date

$global:GV_GlobalHashBox.$BoxName = $ValueObject
$global:GV_GlobalHashBox.'Test2' = 'TEST STRING VALUE'





$FilesPath 			= Join-Path $TrainingPath 'ФАЙЛЫ'
$CryptFileName 		= 'FileToCrypt.txt'
$FullNameCryptFile 	= JP $FilesPath $CryptFileName

$CryptFileContent 	= Get-Content -Path $FullNameCryptFile


# 3 EXCEL =================================
$TraningExcelFilePath 	= JP $TrainingPath 'EXCEL'
$DestPartPath 			= JP $TrainingPath 'TMP_PART'


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
$NewCryptPath = JP $TrainingPath 'TMP_NEWCRYPT'
#New-Item -Path $NewCryptPath -ItemType Directory -Force | Out-Null

$FinalDatePat 		= '(?:\D|\s|^)(?:0[1-9]|[12]\d|3[01])\.(?:0[1-9]|1[0-2])\.(?:19\d\d|20(?:[01]\d|2[0-3]))(?:\D|\s|$)'
$DoubleWordPattern 	= '\b(\w+)\s+\1\b'
$SeparThous 		= '(\d)(?=(\d{3})+(?!\d))'


#--------------------------------------------------------
# 5. CREATE CSV -----------------------------------------
	
$DestCSVPath 	= JP $TrainingPath 'TMP_CSV'
#New-Item -Path $DestCSVPath -ItemType Directory -Force | Out-Null

	$PrefixABS   = '\\?\'	
	$PathScan	 = $PrefixABS + $TrainingPath

	if ($PrefixABS = '\\?\') {$OutCSVFileScan = JP $DestCSVPath 'ScanList_ABS.csv'}`
	else {$OutCSVFileScan = JP $DestCSVPath 'ScanList.csv'}	

	if( $PathScan.StartsWith('\\?\') ) { $SplatPath = @{LiteralPath = $PathScan} } `
	else 							   { $SplatPath = @{Path = $PathScan} }
	
	$PrefixLen = $PrefixABS.Length	# если префикс не задан - длина префикса 0





#--------------------------------------------------------
# 5.1 
$BigCSVPath 	= JP $TrainingPath 'ФАЙЛЫ'
$BigCSVFile 	= JP $BigCSVPath 'l4i26051_SCAN.csv'

#--------------------------------------------------------
# 5.2 100 LINES
$Test100Path 	= JP $TrainingPath 'TMP_100Lines'
#New-Item -Path $Test100Path -ItemType Directory -Force | Out-Null

$TestFile100 	= JP $Test100Path  'PSTestFile_100_Lines.txt'


#--------------------------------------------------------
# 6. ROBOCOPY

$SourcePath 	= JP $TrainingPath 'DOC'	

$DestCopyPath 	= JP $Disk  'TRAINING_TEMP\RoboCopy\Traning\Doc'

$LogPath		= JP $Disk  'Temp'
#New-Item -Path $LogPath -ItemType Directory -Force  | Out-Null	

$LogName		= 'LogTraningRoboCopy.log'

$LogFullName 	= JP $LogPath $LogName	



$TestFileWithBOM = JP $FilesPath 'Test BOM UTF-16 LE.txt'


$PREFIXUNC	 = '\\?\'

#cd k:\WORK_PC\PROJECT\PSScripts


Update-TypeData -PrependPath $PSHOME\FileType.Types.ps1xml

