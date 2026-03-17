#==============================================================
# изменение 13.08.2021 
#	контроль минимальной длины с привязкой к статическим 
#	свойствам класса MinValue модуля CommonConst
#
# Используются модули:
#		CommonConst.psm1
#		CommonFn.psm1
#==============================================================
# загружаем статические переменные
Using Module CommonConst




#==============================================================
function Del-Link{
<# 
	.SYNOPSIS
		Удаляет ранее созданное мапирование (линк)
	.DESCRIPTION
		Проверяет параметр Link на существование в виде папки.
		Если папка присутствует, определяется ее тип.
		Если это просто папка (не линк) - ни чего не делается
		Если папка это линк, то проверяется на что он указывает
		Если линк не на источник Target, то линк удаляется
		иначе линк не меняется
		Резуме: удаляется линк на другой ресурс
	.PARAMETER Link
		(Или l) Линк, который надо удалить 
	.PARAMETER Target
		(Или t) Путь куда должен указывать линк
	.EXAMPLE
		$DelLink = $(Del-Link $Link $Target)
	.EXAMPLE
		$DelLink = $(Del-Link 'C:\PersonalPAV' '\\10.85.152.72\personal\popov_av')
	.INPUTS
		System.String
	.OUTPUTS
		System.String
	.NOTES
		Версия: 1.0 от 19.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
	.LINK
		Out-TempFile
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# обязательный не пустой параметр имя линка
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::LinkPathLen) } )]               
		[Alias('L')]
		[string]$Link
	
		,
		
		# обязательный не пустой параметр путь назначения
		[Parameter (Mandatory = $true, Position=1)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_ -ge $([MinValue]::LinkPathLen) } )]               
		[Alias('T')]
		[string]$Target
	)

		############################################################
		# проверим папку с линком на существование
		# если такая папка уже есть
		if ((Test-Path -Path $Link -PathType Container) -eq $true) {
			
			# если это линк - удалим его???
			if ((Get-Item $Link).LinkType -ne $null) {
			
				# определим куда указывает существующий линк

#write-verbose "$((Get-Item $Link).Target)"

				$TLink = ((Get-Item $Link).Target).Replace("UNC\","\\")
				# если источники не равны
				if ($Target -ne $TLink){
					# удаляем линк
					(Get-Item $Link).Delete()
					return ($([MapVar]::DelLink) + $([MapVar]::MapSep) + $Link) 
				}
				# нужный линк уже существует
				else { return ((Get-Item $Link).LinkType + $([MapVar]::MapSep) + $Link) }
			}
			else { RETURN ($([MapVar]::ErrMapSep) + 'Link Is HardPath') }
			
		}

		return ($([MapVar]::LinkNotPresent) + $([MapVar]::MapSep) + $Link)
}





#==============================================================
function Map-Path {
<# 
	.SYNOPSIS
		Мапирует путь
	.DESCRIPTION
		В зависимости от типа папки назначения (локальный путь или сетевой)
		производится попытка мапирования.
		Для локальных путей используется точка соединения (Junction)
		Для сетевых путей используется сетевое дисковое устройство (SMB) или
		при отсутствии свободных букв для мапирования - символическая ссылка (SimbolicLink)
		Возвращается текстовая информационная строка с разделителем '->' сообщений
	.PARAMETER PathMap
		(Или pm) Путь для мапирования
	.PARAMETER SimbolicLink
		(Или sl) Переключатель
		При его задании для мапирования локальных и сетевых путей будет использоваться
		символическая ссылка (SimbolicLink)
	.EXAMPLE
		Map-Path '\\10.85.152.74\bufer\L\TestL\l2f21ck1'
		возвращаемое значение 
		'SMB->F:->\\10.85.152.74\bufer\L\TestL->l2f21ck1' 
		для перхода в папку надо сделать CD F:\l2f21ck1, т.к. по SNB мапируется путь родителя
		в примере будет смапирован путь \\10.85.152.74\bufer\L\TestL
	.EXAMPLE
		Map-Path 'K:\WORK_PC\PROJECT\EXCEL\L\l2f252a1'
		возвращаемое значение 
		'Junction->C:\l2f252a1' 
	.EXAMPLE
		Map-Path '\\10.85.152.74\bufer\L\TestL\l2f21ck1' -SimbolicLink
		возвращаемое значение 
		'SymbolicLink->C:\l2f21ck1' 
	.INPUTS
		System.String
	.OUTPUTS
		System.String
	.NOTES
		Версия: 1.0 от 19.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
	.LINK
		Out-TempFile
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
		[ValidateScript( { $_.length -ge $([MinValue]::FSOPathLen) } )]               
		[Alias('PM')]
		[string]$PathMap
		
		,
		
		# подключение с использованием символической ссылки
		[Parameter (Mandatory = $false)]
		[Alias('sl')]
		[Switch] $SimbolicLink
	
	)
	
	# определяем имя функции
	$MyNameIs = $MyInvocation.MyCommand.Name
	
	############################################################
	if (!(Test-Path $PathMap) ) {
		return ($([MapVar]::ErrMapSep) + "Path '$PathMap' not found")
	}

	# делаем "чистый" путь без префикса
	$PathMap = Get-CleanPath $PathMap

write-verbose "$MyNameIs `$PathMap 	$PathMap"
	############################################################
	# СЕТЕВОЙ ПУТЬ
	if ((Check-NetPath $PathMap) -eq $true) {
	
		# получаем родительский путь
		$ParentPath = Split-Path -Parent -Path $PathMap
		# если $ParentPath пустой - то корень шары
		
		# если это ROOT Net Path
		if (Check-BlankValue $ParentPath) { 
			# захватываем имя из чистой сетевой нотации
			if (($PathMap -match '([\wА-я\$]+)$') -eq $true) {
				$LastFolderName = $Matches[0]
				$LastFolderName = $LastFolderName.Replace('$', 'hid')
			}
			else { $LastFolderName = 'unknown' }
			$SMBSubFolfer = ""
			# ROOT путь для мапирования
			$RootPath = $PathMap
		}
		# не корень шары, есть подпапка(и)
		else {
			# получаем имя последней папки из пути для мапирования
			$SMBSubFolfer = Split-Path $PathMap -Leaf
			# путь для мапирования - до подпапки
			$RootPath = $ParentPath
			# последняя папка
			$LastFolderName = $SMBSubFolfer
		}
		
write-verbose "$MyNameIs `$LastFolderName 	$LastFolderName"
	
		############################################################
		############################################################
		if (!$SimbolicLink) {

			# м.б. уже смапировано по SMB ? (буква диска)
			$Link = Get-SmbMapping | Select LocalPath, RemotePath | ? { $_.RemotePath -eq $RootPath} | Select LocalPath

			if ($Link -ne $null){
write-verbose "$MyNameIs `$Link.LocalPath  $($Link.LocalPath)"
				return ($([MapVar]::SMB) + $([MapVar]::MapSep) + $Link.LocalPath + $([MapVar]::MapSep) + $RootPath + $([MapVar]::MapSep) + $SMBSubFolfer)
			}
			
			# ранее по SMB не мапировали
			# сделаем сетевое мапирование на новое устройство
			# сформируем массив свободных дисков
			$FreeDrv = Get-FirstNotUseDriveLetter

			# если есть свободные буквы для мапирования
			if ($FreeDrv -ne '') { 
			
				# берем первую свободную букву
				$Link = $FreeDrv

write-verbose "$MyNameIs `$Link	$Link"
			
				# пробуем создать новое устройство в блоке 
				# обработки ошибок
				try {
					# нормально создает, но плохо потом удаляет
					# New-SmbMapping -LocalPath $Link -RemotePath $PathMap -Persistent $false
					
					# делаем так, а не через SmbMapping т.к. потом нормально удаляет
					(New-Object -ComObject WScript.Network).MapNetworkDrive( $Link, $RootPath, $false )
					$RetVal = $([MapVar]::SMB) + $([MapVar]::MapSep) + $Link + $([MapVar]::MapSep) + $RootPath + $([MapVar]::MapSep) + $SMBSubFolfer
				}
				# в случае ошибки
				catch {
					$RetVal = $([MapVar]::ErrorMap)
				}
				if ($RetVal -ne $([MapVar]::ErrorMap)) { return $RetVal }
			}

		} # !$SimbolicLink ################
		
		# если не получилось сделать SMB мапирование
		# или нет свободных букв для мапирования
		# пробуем сделать символическую ссылку

		# формируем букву первого диска с файловой системой NTFS 
		$NTFSDisk = Get-FirstNTFSDrive
write-verbose "$MyNameIs `$NTFSDisk   $NTFSDisk"

		# пробует создать символьную ссылку
		# если нет NTFS диска - выходим
		if ($NTFSDisk -eq '') { return ($([MapVar]::ErrMapSep) + 'Not present NTFS drive') }

		# пробуем сделать символическую ссылку
		# формируем путь линка
		$Link = (Join-Path $NTFSDisk $LastFolderName)
		# формируем путь куда будет линк
		$Target = $PathMap
		
		$DelLink = $(Del-Link $Link $Target)
		
write-verbose "$MyNameIs `$DelLink   $DelLink"

		# линк удален или ранее не создавался - создадим новый
		if ($DelLink.StartsWith($([MapVar]::DelLink) + $([MapVar]::MapSep)) -or
			$DelLink.StartsWith($([MapVar]::LinkNotPresent) + $([MapVar]::MapSep))) {
			
			# пробуем создать символическую ссылку 
			# в блоке обработки ошибок - т.к. у пользователя
			# мож нет на это прав 
			try {
			
				New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-null
				# ссылку создали
				$RetVal = ((Get-Item $Link).LinkType + $([MapVar]::MapSep) + $Link)
			}
			# нет прав на создание символьной ссылки
			catch {
				$RetVal = $([MapVar]::ErrorMap)
			}
			if ($RetVal -ne $([MapVar]::ErrorMap)) { return $RetVal }
		}
		return $DelLink 
		
	} # сетевой путь
		
	############################################################
	# ЛОКАЛЬНЫЙ ПУТЬ ИЛИ СМАПИРОВАННЫЙ СЕТЕВОЙ
	else {
	
		# корневой путь не мапируем
		if (Check-RootPath $PathMap) { return ($([MapVar]::ROOT) + $([MapVar]::MapSep) + $PathMap) }
		
		# формируем букву первого диска с файловой системой NTFS 
		$NTFSDisk = Get-FirstNTFSDrive

		# если NTFS дисков нет - выходим
		if ($NTFSDisk -eq '') { RETURN ($([MapVar]::ErrMapSep) + 'Not Find NTFS Disk') }
		
		# получаем имя последней папки из пути для мапирования
		$LastFolderName = Split-Path $PathMap -Leaf
		
		# формируем путь линка
		$Link = (Join-Path $NTFSDisk $LastFolderName)
		# формируем путь куда будет линк
		$Target = $PathMap
		
		# пробуем удалить линк
		$DelLink = $(Del-Link $Link $Target)
		
write-verbose "$MyNameIs `$DelLink   $DelLink"

		# линк удален или ранее не создавался - создадим новый
		if ($DelLink.StartsWith($([MapVar]::DelLink) + $([MapVar]::MapSep)) -or
			$DelLink.StartsWith($([MapVar]::LinkNotPresent) + $([MapVar]::MapSep))) {
			
			# ---------------------------------------
			# если задано установить символическую ссылку
			if ($SimbolicLink) {
				try {
					New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-null
					# ссылку создали
					$RetVal = ((Get-Item $Link).LinkType + $([MapVar]::MapSep) + $Link)
				}
				catch {
					$RetVal = $([MapVar]::ErrMap)
				}
				return $RetVal
			}
			# ---------------------------------------
			else {
				# создаем точку соединения 
				New-Item -ItemType Junction -Path $Link -Target $Target | Out-null
				return ((Get-Item $Link).LinkType + $([MapVar]::MapSep) + $Link)
			}
		}
		
		return $DelLink
	}
	
}
	
	

	
	
#==============================================================
function UnMap-Path {
<# 
	.SYNOPSIS
		Размапирует путь
	.DESCRIPTION
		Удаляет ранее созданное мапирование на основании сообщения возвращенным	Map-Path
		Возвращает текстовое сообщение о результате выполненного действия
	.PARAMETER MapMsg
		(Или мм) Сообщение в формате возвращаемого значения от Map-Path
		Обязательный параметр
	.EXAMPLE
		$MsgMap = Map-Path '\\10.85.152.74\bufer\L\TestL\l2f21ck1'
		...
		UnMap-Path $MsgMap
		'UnMap-Path: Сетевой диск 'F:' отключен' 
	.EXAMPLE
		$MsgMap = Map-Path 'K:\WORK_PC\PROJECT\EXCEL\L\l2f252a1'
		...
		UnMap-Path $MsgMap
		'UnMap-Path: Точка соединения 'C:\l2f252a1' удалена' 
	.EXAMPLE
		$MsgMap = Map-Path '\\10.85.152.74\bufer\L\TestL\l2f21ck1' -SimbolicLink
		...
		UnMap-Path $MsgMap
		'UnMap-Path: Символическая ссылка 'C:\l2f21ck1' удалена' 
	.INPUTS
		System.String
	.OUTPUTS
		System.String
	.NOTES
		Версия: 1.0 от 19.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
	.LINK
		Out-TempFile
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
		[ValidateScript( { $_ -ge $([MinValue]::MsgMapLen) } )]               
		[Alias('MM')]
		[string]$MapMsg
		
	)

	# определяем имя функции
	$MyNameIs = $MyInvocation.MyCommand.Name
	
	$MUMPrefixMsg = "UnMap-Path:"
	
Write-verbose "$MyNameIs `$MapMsg: $MapMsg"	
	
	# если сообщение содержит ошибку - значит мапирование не делали и выходим
	if ($MapMsg.StartsWith($([MapVar]::ErrorMap))) { return "$MUMPrefixMsg Error. Мапирование не выполнено" }
	
	$Parse = $MapMsg.Split($([MapVar]::MapSep))

	if ($Parse.length -lt 3)  { return "$MUMPrefixMsg Error. Параметр задан не верно (не соответствует сообщению от мапирования)" }
	
	$Type = $Parse[0]
	$Link = $Parse[2]

write-verbose "$MyNameIs `$Type '$Type'"	
write-verbose "$MyNameIs `$Link '$Link'"	
	
	if ($Type -ne $([MapVar]::SMB)) {
		$ChekPath = Test-Path $Link
write-verbose "$MyNameIs `$ChekPath $ChekPath"	
	
		if ( $ChekPath -ne $true ) { return "$MUMPrefixMsg Error. Указанный путь '$Link' не существует" }
write-verbose "$MyNameIs `$Link present"	
	}
	
#$Host.EnterNestedPrompt()	
	
	$MsgUnMap = ""
	
	switch ($Type) {
	
		$([MapVar]::SMB) { 
			# не убирает мапирование из проводника (оставляет с красным крестиком)
			# Remove-SmbMapping -LocalPath $Link -Force -UpdateProfile
			
			# 										DriveLetter, Force, RemoveUserProfile
			(New-Object -ComObject WScript.Network ).RemoveNetworkDrive( $Link, $true, $true )
write-verbose "$MyNameIs `$Type '$Type'"	
			$MsgUnMap = "Сетевой диск '$Link' отключен"			
			break
		}
		
		$([MapVar]::Simbolic) {
write-verbose "$MyNameIs `$Type '$Type'"	
			(Get-Item $Link).Delete()
			$MsgUnMap = "Символическая ссылка '$Link' удалена"			
			break
		}
	
		$([MapVar]::Junction) {
write-verbose "$MyNameIs `$Type '$Type'   MapVar: $([MapVar]::Junction)"	
			(Get-Item $Link).Delete()
			$MsgUnMap = "Точка соединения '$Link' удалена"			
			break
		}
		
		$([MapVar]::ROOT) {
write-verbose "$MyNameIs `$Type '$Type'"	
			$MsgUnMap = "Корневой каталог '$Link' размапирования не тебует"			
			break
		}
		default { $MsgUnMap = "Тип линка '$Link' не определен"}
	}

#$Host.EnterNestedPrompt()
	
	return "$MUMPrefixMsg $MsgUnMap"
}	
	

	
	
	
	
	
