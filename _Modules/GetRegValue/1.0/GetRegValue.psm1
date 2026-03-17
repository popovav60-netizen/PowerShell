#==============================================
# изменение 13.08.2021 
#	контроль минимальной длины с привязкой к статическим 
#	свойствам класса MinValue модуля CommonConst
#
# Используются модули:
#		CommonConst.psm1
#		CommonFn.psm1
#==============================================
# загружаем статические свойства
Using Module CommonConst

# =============================================
function Get-RegValue {
<# 
	.SYNOPSIS
		Получает строковое значение из реестра
	.DESCRIPTION
		Возвращает строковое значение параметра из ветки реестра. 
		При отсутствии значения (параметра) возвращается значение по умолчанию.
	.PARAMETER RegPath
		(Или rp) Полный путь к разделу реестра
	.PARAMETER ValueName
		(Или vn) Имя параметра в разделе реестра
	.PARAMETER DefValue
		(Или dv) Возвращаемое значение по умолчанию
	.EXAMPLE
		# определим переменные
		Set-Variable -Name RegKey 				-Value "HKCU:\Software\PowerShell\ScanLFile" -Option Constant -Scope Script -Visibility Private
		Set-Variable -Name DefLModuleName 		-Value "CheckLFile PAV 2.01.09.xlsm" 		 -Option Constant -Scope Script -Visibility Private
		...
		$ModulePath = Get-RegValue $RegKey 'ModulePath' (Join-Path 'k:\WORK_PC\PROJECT\EXCEL' $DefLModuleName)
	.INPUTS
		SystemObject
		System.String
	.OUTPUTS
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 15.05.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# обязательный не пустой параметр имя ящика
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::RegPathLen) } )]	# >=               
		[Alias('RP')]
		[string]$RegPath,		# имя под которым сохраняем
		
		# обязательный не пустой параметр значение
		[Parameter (Mandatory = $true, Position=1)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::RegVNameLen) } )]	# >=               
		[Alias('VN')]
		[string]$ValueName,	# значение объекта, которое сохраняем
	
		# не обязательный параметр
		[Parameter (Mandatory = $false, Position=2)]
		[Alias('DV')]
		[string]$DefValue	# значение по умолчанию
	

	)

	# определяем общие параметры
	$IsVerbose = $false
	# если задан параметр вывода на экран расширенной информации общего хода выполнения скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Verbose) {
		# сохраняем значения общих настроек
		$OldVerbosePreference = $VerbosePreference
		$VerbosePreference = "Continue"
		$IsVerbose = $true
	}

	# определяем общие параметры
	$IsDebug = $false
	# если задан параметр детальной отладочной информации и возможно переключение в пошаговое исполнение скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Debug) {
		# сохраняем значения общих настроек
		$OldDebugPreference = $DebugPreference
		$DebugPreference = "Continue"
		$IsDebug = $true
	}

	#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	# если отладка - остановимся
	if ($IsDebug -eq $true) { 
		$Host.EnterNestedPrompt() 
	}

	$RetVal = ""
	
	
	# проверяем ветку реестра - если ее нет - создаем
	Create-RegKey $RegPath
	

	$RetVal = Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction SilentlyContinue  #| Out-Null

	if ( (($RetVal -eq $null) -or ($RetVal.Length -eq 0)) -and $DefValue -ne '' ) {
		$RetVal = $DefValue
		New-ItemProperty -Path $RegPath -Name $ValueName -PropertyType String -Value $RetVal | Out-Null
	}
	else {$RetVal = $RetVal.$ValueName}
	
	
	# при необходимости восстановим установки общих параметров
	if ($PSBoundParameters.Verbose) {
		if($VerbosePreference -ne $OldVerbosePreference) {$VerbosePreference = $OldVerbosePreference}
	}
	
	if ($PSBoundParameters.Debug) {
		if($DebugPreference -ne $OldDebugPreference) {$DebugPreference = $OldDebugPreference}
	}
	
	
	return $RetVal
	
}





# =============================================
function Set-RegValue {
<# 
	.SYNOPSIS
		Устанавливает значение в реестре
	.DESCRIPTION
		При отсутствии ветки реестра - она создается
	.PARAMETER RegPath
		(Или rp) Полный путь к разделу реестра
	.PARAMETER ValueName
		(Или vn) Имя параметра в разделе реестра
	.PARAMETER SetValue
		(Или sv) Устанавливаемое значение
	.EXAMPLE
		# определим переменные
		Set-Variable -Name RegKey 				-Value "HKCU:\Software\PowerShell\ScanLFile" -Option Constant -Scope Script -Visibility Private
		Set-Variable -Name DefLModuleName 		-Value "CheckLFile PAV 2.01.09.xlsm" 		 -Option Constant -Scope Script -Visibility Private
		...
		Set-RegValue $RegKey 'ModulePath' $ModulePath
	.INPUTS
		SystemObject
		System.String
	.OUTPUTS
		None
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 15.05.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# обязательный не пустой параметр имя ящика
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::RegPathLen) } )]     # >=         
		[Alias('RP')]
		[string]$RegPath,		# имя под которым сохраняем
		
		# обязательный не пустой параметр значение
		[Parameter (Mandatory = $true, Position=1)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::RegVNameLen) } )]    # >=            
		[Alias('VN')]
		[string]$ValueName,	# значение объекта, которое сохраняем
	
		# не обязательный параметр
		[Parameter (Mandatory = $false, Position=2)]
		[Alias('SV')]
		[string]$SetValue = ''	# значение по умолчанию
	
	)

	# определяем общие параметры
	$IsVerbose = $false
	# если задан параметр вывода на экран расширенной информации общего хода выполнения скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Verbose) {
		# сохраняем значения общих настроек
		$OldVerbosePreference = $VerbosePreference
		$VerbosePreference = "Continue"
		$IsVerbose = $true
	}

	# определяем общие параметры
	$IsDebug = $false
	# если задан параметр детальной отладочной информации и возможно переключение в пошаговое исполнение скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Debug) {
		# сохраняем значения общих настроек
		$OldDebugPreference = $DebugPreference
		$DebugPreference = "Continue"
		$IsDebug = $true
	}

	#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	# если отладка - остановимся
	if ($IsDebug -eq $true) { 
		$Host.EnterNestedPrompt() 
	}

	
	
	# проверяем ветку реестра - если ее нет - создаем
	Create-RegKey $RegPath
	
	New-ItemProperty -Path $RegPath -Name $ValueName -PropertyType String -Value $SetValue -Force | Out-Null
	
	
	# при необходимости восстановим установки общих параметров
	if ($PSBoundParameters.Verbose) {
		if($VerbosePreference -ne $OldVerbosePreference) {$VerbosePreference = $OldVerbosePreference}
	}
	
	if ($PSBoundParameters.Debug) {
		if($DebugPreference -ne $OldDebugPreference) {$DebugPreference = $OldDebugPreference}
	}
	
}






# =============================================
function Create-RegKey {
<# 
	.SYNOPSIS
		Создает ветку реестра
	.DESCRIPTION
		При отсутствии создает ветку реестра.
		Вложенность не ограничена
	.PARAMETER RegPath
		(Или rp) Полный путь к разделу реестра который надо создать
	.EXAMPLE
		Create-RegKey "HKCU:\Software\PowerShell\ScanLFile"
	.INPUTS
		SystemObject
		System.String
	.OUTPUTS
		None
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 15.05.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# обязательный не пустой параметр имя ящика
		[Parameter (Mandatory = $true)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::RegPathLen) } )]    # >=           
		[Alias('RP')]
		[string]$RegPath
	
	)

	# определяем общие параметры
	$IsVerbose = $false
	# если задан параметр вывода на экран расширенной информации общего хода выполнения скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Verbose) {
		# сохраняем значения общих настроек
		$OldVerbosePreference = $VerbosePreference
		$VerbosePreference = "Continue"
		$IsVerbose = $true
	}

	# определяем общие параметры
	$IsDebug = $false
	# если задан параметр детальной отладочной информации и возможно переключение в пошаговое исполнение скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Debug) {
		# сохраняем значения общих настроек
		$OldDebugPreference = $DebugPreference
		$DebugPreference = "Continue"
		$IsDebug = $true
	}

	#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	# если отладка - остановимся
	if ($IsDebug -eq $true) { 
		$Host.EnterNestedPrompt() 
	}

	# проверяем ветку реестра - если ее нет - создаем
	if((Test-Path -Path $RegPath -PathType Container) -ne $true) { 
		# убираем разделитель
		$key = $RegPath -replace ':',''
		# разбиваем путь на составляющие
		$parts = $key -split '\\'
		$tempkey = ''
		# по всему массиву папок/подпапок
		# передаем элементы массива по конвейеру
		# далее цикл ForEach-Object по всем папкам
		$parts | ForEach-Object {
			# добавляем новуй путь (папку)
			if ($tempkey -eq ''){$tempkey = $_}
			else {$tempkey += "\" + $_}
			# в случае отсутствия - создаем ветку реестра
			if( (Test-Path -Path "Registry::$tempkey") -eq $false ) {
				New-Item -Type Folder -Path "Registry::$tempkey" | Out-Null
			}
		}
	}

	
	# при необходимости восстановим установки общих параметров
	if ($PSBoundParameters.Verbose) {
		if($VerbosePreference -ne $OldVerbosePreference) {$VerbosePreference = $OldVerbosePreference}
	}
	
	if ($PSBoundParameters.Debug) {
		if($DebugPreference -ne $OldDebugPreference) {$DebugPreference = $OldDebugPreference}
	}
	
}






