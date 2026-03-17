#==============================================================
# изменение 13.08.2021 
#	контроль минимальной длины с привязкой к статическим 
#	свойствам класса MinValue модуля CommonConst
#
# Используются модули:
#			CommonConst.psm1
#==============================================================
# загружаем статические свойства
Using Module CommonConst


#==============================================================
function Check-BlankValue {
<# 
	.SYNOPSIS
		Проверка на отсутствие значения
	.DESCRIPTION
		Функция проверяет параметр на отсутствие значеня или $null
		В случае отсутствия значения возвращает $true иначе $false
	.PARAMETER TestValue
		Любой тип переменной или значение
	.EXAMPLE
		$TestValue	= @{}
		PS C:\>Check-BlankValue  $TestValue
		True
	.EXAMPLE
		$TestValue	= @{"Item1"=123}
		PS C:\>Check-BlankValue  $TestValue
		False
	.EXAMPLE
		$TestValue
		PS C:\>Check-BlankValue  $TestValue
		True
	.EXAMPLE
		$TestValue = ''
		PS C:\>Check-BlankValue  $TestValue
		True
	.EXAMPLE
		$TestValue = '123'
		PS C:\>Check-BlankValue  $TestValue
		False
	.INPUTS
		AnyType
	.OUTPUTS
		System.ValueType.Boolean
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 24.01.2020
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# значение которое надо проверить
		# обязательный параметр
		[Parameter (Mandatory = $true)]
		# допускается в качестве аргумента $null 
		[AllowNull()]
		# допускается в качестве аргумента пустые строки 
		[AllowEmptyString()]
		# допускается в качестве аргумента пустые массивы 
		[AllowEmptyCollection()]		
		$TestValue
	)
	

	# проверяем параметр на $null, Space и Empty
	if (!$TestValue -or `
		[string]::IsNullOrWhiteSpace($TestValue) -or `
		[string]::IsNullOrEmpty($TestValue)) {return $true}
	# если предыдущая проверка не отработала, уточним...
	else {
		# с учетом последующих идей...
		switch ($TestValue.GetType().Name){
			'Hashtable' {return ($TestValue.Count -eq 0)}
			# ...
			default {return $false}
		}
	}
}	



#==============================================================
function Check-NetPath{
<# 
	.SYNOPSIS
		Проверка на сетевой путь
	.DESCRIPTION
		Проверка осуществляется с использованием регулярного выражения -match
		Шаблон префиксов абсолютного UNC адреса берется из статического свойства [ABSPath]::PrefixABSUNC модуля CommonConst
		Шабнол Ip4 адреса и имени DNS сервера берутся из статического свойства [Ip4]::PatternIp4 модуля CommonConst
		Если путь соответствует шаблону - возвращается $true, иначе - $false
		Наличие физического пути не проверяется
	.PARAMETER Path
		Путь который проверяектся
		Не нулевое строковое выражение 
	.EXAMPLE
		PS Check-NetPath 'C:\Work_PC\TestPath' 
		False
		PS Check-NetPath '\\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1' 
		False # т.к. 2-я тетрада 385 не допустима в адресе Ip4
	.EXAMPLE
		PS Check-NetPath '\\10.85.152.72\Personal\PopovAV\TestL\l2f21ck1' 
		True
		PS Check-NetPath '\\?\UNC\10.85.152.72\Personal\PopovAV\TestL\l2f21ck1' 
		True
	.EXAMPLE
		PS Check-NetPath '\\Gibr-sod\M$\TestL\l2f21ck1' 
		True
		PS Check-NetPath '\\?\UNC\Gibr-sod\M$\TestL\l2f21ck1' 
		True
		PS Check-NetPath '\\1Gibr-sod\M$\TestL\l2f21ck1' 
		False # т.к. DNS имя не может начинаться с цифры
		PS Check-NetPath '\\Gibr.sod\M$\TestL\l2f21ck1' 
		False # т.к. DNS имя не может содержать точки
	.INPUTS
		System.String
	.OUTPUTS
		System.Boolean
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# путь для проверки 
		[Parameter (Mandatory = $true)]	  # обязательный параметр
		[ValidateNotNullOrEmpty()]        # не ноль и не пусто      
		[ValidateScript( { $_.length -ge $([MinValue]::NetPathLen) } )]  # минимум '\\d\s\'
		[Alias('PTH')]
		[string]$Path
	)

		# шаблон для проверки сетевого пути с Ip адресом
		$PatternIp = '^' + [ABSPath]::PatternPrefixABSNET + [Ip4]::PatternIp4 + '\\.+'

		# шаблон для проверки сетевого пути с DNS именем сервера
		$PatternDNS = '^' + [ABSPath]::PatternPrefixABSNET + [Ip4]::PatternDNSName + '\\.+'
		
		return ( ($Path -match $PatternIp) -or ($Path -match $PatternDNS))
	
}





#==============================================================
function Get-CleanPath {
<# 
	.SYNOPSIS
		Возвращает "чистый" путь без возможного абсолютного UNC префикса 
	.DESCRIPTION
		Контроль наличия в пути абсолютных префиксов осуществляется с использованием
		статических свойств [ABSPath]::PrefixABS и [ABSPath]::PrefixABSUNC модуля CommonConst
		При их наличии, они из пути удаляются
	.PARAMETER Path
		Путь который очищается
		Не нулевое строковое выражение длинной более 2 символов 
	.EXAMPLE
		Get-CleanPath 'C:\Work_PC\TestPath' 	# вернет 'C:\Work_PC\TestPath'
		Get-CleanPath '\\?\C:\Work_PC\TestPath' # вернет 'C:\Work_PC\TestPath'
	.EXAMPLE
		Get-CleanPath '\\10.185.152.72\Personal\PopovAV\TestL\l2f21ck1' 	# вернет '\\10.185.152.72\Personal\PopovAV\TestL\l2f21ck1'
		Get-CleanPath '\\?\UNC\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1'' # вернет '\\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1'
	.INPUTS
		System.String
	.OUTPUTS
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# путь для "очистки"
		[Parameter (Mandatory = $true)]
		[ValidateNotNullOrEmpty()]              # не ноль и не пусто
		[ValidateScript( { $_.length -ge $([MinValue]::FSOPathLen) } )]	# 'c:\'
		[Alias('PTH')]
		[string]$Path
		
	)
	
		# если параметр абсолютный сетевой UNC формат
		if ($Path.ToUpper().StartsWith([ABSPath]::PrefixABSUNC)) { return ('\' + $Path.Substring(7)) }

		# абсолютный локальный формат
		if ($Path.StartsWith([ABSPath]::PrefixABS)) { return ($Path.Substring(4)) }
		
		# параметр имеет чистый формат
		return $Path
	
}
	
	

	
	
#==============================================================
function Check-RootPath {
<# 
	.SYNOPSIS
		Проверка на корневой путь
	.DESCRIPTION
		Для проверки используются регулярные выражения -match
		Шаблоны для регулярных выражений берутся из статических свойств классов [Ip4] и [ABSPath] модуля CommonConst
		Если путь является корневым - возвращается $true, иначе $false
	.PARAMETER Path
		Путь который проверяем
		Не нулевое строковое выражение длинной более 1 символа 
	.EXAMPLE
		Check-RootPath 'C:\Work_PC\TestPath' # вернет $false
		Check-RootPath '\\?\C:\Work_PC\TestPath' # вернет $false
		Check-RootPath '\\10.385.152.72\Personal\PopovAV' # вернет $false
		Check-RootPath '\\?\UNC\10.385.152.72\Personal\PopovAV' # вернет $false
	.EXAMPLE
		Check-RootPath 'C:\' # вернет $true
		Check-RootPath '\\?\C:\' # вернет $true
		Check-RootPath '\\10.385.152.72\Personal' # вернет $true
		Check-RootPath '\\?\UNC\10.385.152.72\Personal' # вернет $true
	.INPUTS
		System.String
	.OUTPUTS
		System.Boolean
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# путь для проверки
		[Parameter (Mandatory = $true)]
		[ValidateNotNullOrEmpty()]				# не ноль и не пусто              
		[ValidateScript( { $_.length -ge $([MinValue]::RootPathLen) } )]	# минимум 'c:'
		[Alias('MM')]
		[string]$Path
		
	)

		# получаем путь без префикса абсолютного адреса
		$Path = Get-CleanPath  $Path 
		
		# получаем родительский путь
		$ParentFolder = Split-Path -Parent -Path $Path
		
		# ..........................
		# указан диск (нет родителя)
		if (!$ParentFolder -or $ParentFolder -eq '') { 
			[bool]$RootPath = $true 
		}
		# проверим на корневую папку
		else {
			# если сетевой путь
			if ((Check-NetPath $Path)) {
				[bool]$RootPath = $($ParentFolder -match '^\\\\' + [Ip4]::PatternIp4 + [ABSPath]::PatternLastFolder)
			}
			else {
				# родитель - корень диска?
				[bool]$RootPath = $($ParentFolder -match $([ABSPath]::PatternRootPathDrv))
			}
		}

		return $RootPath

}	
	




#==============================================================
function Get-FirstNTFSDrive {
<# 
	.SYNOPSIS
		Получить букву диска с файловой системой NTFS
	.DESCRIPTION
		Для получения информации о подключенных дисковых устройствах используется командлет Get-Volume
		Если диски с файловой системой NTFS присутствуют - возвращается буква первого найденного диска, иначе пустая строка
	.PARAMETER 
		НЕТ
	.EXAMPLE
		PS Get-FirstNTFSDrive 	
		C:
	.INPUTS
		НЕТ
	.OUTPUTS
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (	)

		# получим отсортированный список всех локальных NTFS дисков
		$NTFSVols = Get-Volume | ? {$_.FileSystemType -eq 'NTFS' -and $_.DriveLetter -ne $null} | Sort-Object -Property DriveLetter
		
		# если NTFS дисков нет - выходим
		if ($NTFSVols.Length -eq 0) { return '' }
		
		# получаем букву первого диска с файловой системой NTFS 
		return ( $NTFSVols[0].DriveLetter + ':' )
	
}	
	

	
	
	
#==============================================================
function Set-AbsUncPath {
<# 
	.SYNOPSIS
		Преобразовать путь в абсолютный адрес
	.DESCRIPTION
		Локальный или сетевой путь при отсутствии добавляется префиксом абсолютного адреса
		Наличие префикса абсолютного адреса проверяется с использованием шаблонов регулярного выражения -match
		Шаблоны берутся из статических свойств класса [ABSPath] модуля CommonConst
		Возвращает путь с префиксом абсолютного адреса
	.PARAMETER Path
		Путь который дополняем префиксом абсолютного адреса
		Не нулевое строковое выражение длинной более 1 символа 
	.EXAMPLE
		Set-AbsUncPath 'C:\Work_PC\TestPath' # вернет '\\?\C:\Work_PC\TestPath'
	.EXAMPLE
		Set-AbsUncPath '\\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1' # вернет '\\?\UNC\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1'
	.INPUTS
		System.String
	.OUTPUTS
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# путь
		[Parameter (Mandatory = $true)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_.length -ge $([MinValue]::RootPathLen) } )]    # >=   'c:'        
		[Alias('PTH')]
		[string]$Path
		
	)
		# очень короткий путь (<=)
		if ($Path.length -le $([MinValue]::FSOPathLen)) {
			if ($Path -notmatch $([ABSPath]::PatternDrvAndOptionalSlesh)) { return '' }
			if ($Path.EndsWith(':')) {return "$([ABSPath]::PrefixABS)$Path\" }
			return "$([ABSPath]::PrefixABS)$Path"
		}
		
		# если параметр не абсолютный путь
		if ($Path.Substring(0,3) -ne $([ABSPath]::PrefixABSUNC).Substring(0,3) ) {
			# абсолютный сетевой UNC формат
			If ($Path.Substring(0,2) -eq "\\") { return ($([ABSPath]::PrefixABSUNC).Substring(0,7) + $Path.Substring(1)) }
			# абсолютный локальный формат
			else {return "$([ABSPath]::PrefixABS)$Path"}
		}
		
		# параметр имеет абсолютный формат
		else {return $Path}
	
}	
	
	
	
	

#==============================================================
function Get-FirstNotUseDriveLetter {
<# 
	.SYNOPSIS
		Получить первую свободную букву диска
	.DESCRIPTION
		Для поиска используется встроенная функция формирования списка свободных буква
		В случае нахождения свободной буквы - возвращается буква , иначе пустая строка.
	.PARAMETER 
		НЕТ
	.EXAMPLE
		Get-FirstNotUseDriveLetter		# вернет типа 'F:'
	.INPUTS
		НЕТ
	.OUTPUTS
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param ()

		$FreeDrv = (ls function:[d-z]: -n | ?{ !(Test-Path $_) })
		
		if ($FreeDrv.length -eq 0) { return '' }
		
		return $FreeDrv[0]
	
}	
	
	


	
	
#==============================================================
function Get-CountItem {
<# 
	.SYNOPSIS
		Получить количество элементов в заданной папке включая вложенные папки.
	.DESCRIPTION
		Подсчитывается количество элементов в зависимости от установленного параметра (переключателя) NoFolder. 
	.PARAMETER Path
		Начальный путь для сканирования
		Не нулевое строковое выражение длиной более 1 символа
		Возможно указание абсолютного адреса пути
	.PARAMETER NoFolder
		Переключатель
		Если задан, то подсчет элементов ведется без учета папок
	.PARAMETER Format
		Переключатель (не обязательный параметр)
		Если задан, то количество найденных элементов форматируется с разделением тысяч (строковое представление)
	.PARAMETER NoRecurse
		Переключатель (не обязательный параметр)
		Если задан, то вложенные подпапки не обрабатываются
	.EXAMPLE
		Get-CountItem '\\10.85.152.72\Personal\PopovAV\TestL\l2f21ck1'	# вернет типа 599
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1'	-NoRecurse	# вернет типа 10
	.EXAMPLE
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1'				# вернет типа 8427
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -NoFolder	# вернет типа 6950
	.EXAMPLE
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -NoFolder -Format		# вернет типа 6 950
		Get-CountItem '\\?\k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -NoFolder -Format	# вернет типа 6 950
	.INPUTS
		System.String
	.OUTPUTS
		System.Long
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 27.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# начальный путь
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript( { $_.length -ge $([MinValue]::RootPathLen) } )]               
		[Alias('PTH')]
		[string]$Path
		
		,
		
		# Не обрабатывать подкаталоги
		[Parameter (Mandatory = $false)]
		[Switch] $NoRecurse
				
		,
		
		# без учета папок
		[Parameter (Mandatory = $false)]
		[Switch] $NoFolder

		,
		
		# отформатировать вывод
		[Parameter (Mandatory = $false)]
		[Switch] $Format
		
	)
		# SPLATTING на опрелделение пути
		# если абсолютный адрес пути - используем LiteralPath
		if($Path.StartsWith($([ABSPath]::PrefixABS))){$SplatPath = @{LiteralPath = $Path} }
		# если простой путь - используем Path
		else {$SplatPath = @{Path = $Path}}
		
		if (!(Test-Path @SplatPath)) { return 0 }
		
		
		# SPLATTING на опрелделение вложенных папок
		$ArgRecFor = @{Recurse = !$NoRecurse; Force = $true}
		
		# возвращает кол-во всех элементов
		if (!$NoFolder) {
			$RetVal = (Get-ChildItem @ArgRecFor  @SplatPath).Length
		}
		# толко кол-во файлов если $false
		else {
			$RetVal =  (Get-ChildItem @ArgRecFor  @SplatPath | ? {$_.PSIsContainer -ne $true}).Length
		}

		if ($Format){ return ("{0:N0}" -f $RetVal) }
		else { return $RetVal }
}	
	
	
	
	
	
	
#==============================================================
function Get-FolderSize {
<# 
	.SYNOPSIS
		Получить размер папки, включая все подпапки
	.DESCRIPTION
		Подсчитывается суммарный размер папки, включая все вложенные энементы подпапок включая скрытые и системные элементы структыры
		Возвращает значения в зависимости отустановленных переключателей
		Если переключатели не установлены - возвращается значение в байтах
		Одновременное использование переключателей Mb, Gb и Tb не допускается
	.PARAMETER Path
		Начальный путь для сканирования
		Не нулевое строковое выражение длиной более 1 символа
		Возможно указание абсолютного адреса пути
	.PARAMETER NoRecurse
		Переключатель (не обязательный параметр)
		Если задан, то вложенные подпапки не обрабатываются
	.PARAMETER Format
		Переключатель (не обязательный параметр)
		Если задан, то общий размер найденных элементов форматируется с разделением тысяч (строковое представление)
	.PARAMETER Mb
		Переключатель (не обязательный параметр)
		Если задан, то общий размер найденных элементов указывается в мегабайтах с точностью до 3 знаков после целого значения
	.PARAMETER Gb
		Переключатель (не обязательный параметр)
		Если задан, то общий размер найденных элементов указывается в гигабайтах с точностью до 3 знаков после целого значения
	.PARAMETER Tb
		Переключатель (не обязательный параметр)
		Если задан, то общий размер найденных элементов указывается в терагабайтах с точностью до 3 знаков после целого значения
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' 	# вернет типа 7077075672
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -Format	# вернет типа 7 077 075 672
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -Mb	# вернет типа 6749,225
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -Format -Gb	# вернет типа 6,591
	.INPUTS
		System.String
	.OUTPUTS
		System.Double
		System.String
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 19.07.2021
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding(DefaultParameterSetName="Pav")] 

	# описание параметров
	Param (
    
		# начальный путь
		# обязательный параметр в позиции 0
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]  			# не $null и не пустая строка            
		[ValidateScript( { $_.length -ge $([MinValue]::RootPathLen) } )] # длина строки более 1 символа (2 и больше)              
		[Alias('PTH')]
		[string]$Path
		
		,
		
		# Не обрабатывать подкаталоги
		[Parameter (Mandatory = $false)]
		[Switch] $NoRecurse
		
		,
		
		# отформатировать вывод
		[Parameter (Mandatory = $false)]
		[Switch] $Format
		
		,
		
		# получение результата в МБ
		[Parameter (Mandatory = $false, ParameterSetName="ParamMb")]
		[Switch] $Mb
		
		,
		
		# получение результата в ГБ
		[Parameter (Mandatory = $false, ParameterSetName="ParamGb")]
		[Switch] $Gb
		
		,
		
		# получение результата в ТБ
		[Parameter (Mandatory = $false, ParameterSetName="ParamTb")]
		[Switch] $Tb
		
	)
	
		# SPLATTING на опрелделение пути
		# если абсолютный адрес пути - используем LiteralPath
		if($Path.StartsWith($([ABSPath]::PrefixABS))){$ArgPath = @{LiteralPath = $Path} }
		else {$ArgPath = @{Path = $Path}}
		
		if (!(Test-Path @ArgPath)) { return 0 }
		
		# SPLATTING на опрелделение вложенных папок
		$ArgRecFor = @{Recurse = !$NoRecurse; Force = $true}
		
		# -Property Length - присутствует только у файлов! поэтому в объекте Measure свойство Count
		# будет указывать на кол-во файлов!
		[double]$RetVal = (Get-ChildItem @ArgRecFor  @ArgPath | Measure-Object -Property Length -Sum).Sum

		if ($Mb) { $RetVal = [math]::Round(($RetVal/1Mb),3) }
		if ($Gb) { $RetVal = [math]::Round(($RetVal/1Gb),3) }
		if ($Tb) { $RetVal = [math]::Round(($RetVal/1Tb),3) }
		
		
		$RetValue = $RetVal
		
		if($Format) { $RetValue = "{0:N3}" -f $RetVal}
		
		return $RetValue
	
}	
	
	

#==============================================================
function Split-FileContent {
<#
	.SYNOPSIS
		Разбивает текстовый файл на несколько текстовых файлов в месте назначения, где каждый
		файл содержит заданное количество строк.
	.DESCRIPTION
		При работе с файлами, имеющими заголовок, часто желательно иметь
		информацию заголовка повторяющуюся во всех разделенных файлах. 
		Данный командлет поддерживает эту функцию с параметром -rc (RepeatCount).
	.PARAMETER Path
		Задает полное имя файла или массив полных имен файлов. Подстановочные знаки разрешены.
		Возможна обработка имен файлов по конвейеру (по значению и по именованному параметру)
		Если путь к файлу начинается с абсолютной адресации - в качестве параметра
		используется LiteralPath, воспринмающий подстановочные символы в пути "как есть"
	.PARAMETER Count
		(Или -c) Максимальное количество строк в каждом файле.
	.PARAMETER Destination
		(Или -d) Местоположение, в которое следует поместить файлы вывода с фрагментами.
	.PARAMETER RepeatCount
		(Или -rc) Определяет количество строк "заголовка" во входном файле, которые будут
		повторяться в каждом выходном файле. Обычно это 0 или 1, но это может быть любое
		количество строк.
	.EXAMPLE
		# разделить на файлы по 3000 строк с заголовком из 1-строки исходного файла
		Split-FileContent bigfile.csv 3000 -rc 1
	.EXAMPLE
		# конвейерная обработка файлов. имена передаются по значению
		Get-Childitem -Force -Recurse "C:\Test\*.csv" | Split-FileContent -c 3000 -rc 1 -d 'C:\Test'
	.EXAMPLE
		# конвейерная обработка файлов по именованному параметру
		Get-Childitem -Force -Recurse "C:\Test\*.csv" | % {[PSCustomObject]@{Path=$_.FullName}} | Split-FileContent -c 3000 -rc 1
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 29.07.2021
		Разработчик: Основа Internet, доработка Popov A.V. email: popov-av@mail.ru
#>
    [CmdletBinding()]
    param(
		
		# полное имя файла или массив имен. обязательный 1-й параметр
		# возможно получение по конвейеру
		# ValueFromPipeline - получение из конвейера только значения
		# ValueFromPipelineByPropertyName - получение из конвейера значения по имени
		# 	если имя параметра задано не верно - получим ошибку
		#	передача именованных параметров осуществляется только с использованием PSCostomObject
		#	типа: [PSCostomObject]@{Path='C:\Test\bigfile.csv'} | Split-FileContent -c 3000 -rc 1
        [Parameter(Position=0, 
				   Mandatory=$true, 
				   ValueFromPipeline=$true, 
				   ValueFromPipelineByPropertyName=$true)]
        [String[]]$Path,

		# максимальное количество строк в выходных файлах
		# обязательный параметр во 2-й позиции больше 0
        [Alias('c')]
        [Parameter(Position=1, Mandatory=$true)]
		[ValidateScript( {$_ -gt 0} )] # значение больше 0
        [Int32]$Count,

		# путь назначения выходных файлов
        [Alias('d')]
        [Parameter(Position=2)]
        [String]$Destination='.',

		# количество строк заголовка для повторения в выходных файлах
        [Alias('rc')]
        [Parameter()]
        [Int32]$RepeatCount

    )
	
	# выполняется всегда в начале обработки (инициализация)
	begin {
		# ПРИЗНАК КОНВЕЙЕРНОЙ ОБРАБОТКИ НЕ ИСПОЛЬЗУЕМ, НО ...
		# определим Pipeline режим (получение данных по конвейеру)
		# если данные получили как параметр функции (аргумент), то в системной переменной
		# $PSBoundParameters (хеш таблица) должен существовать ключ с именем переменной
		# если переменной в хеш таблице нет - значит входное значение получено по конвейеру
		# $PipeMode = -not $PSBoundParameters.ContainsKey("Path")
		$PipeMode = -not $PSBoundParameters.Path
		
		# возвращаемый массив разделенных файлов (будет из объектов)  
		$Arr = @()
			
	}
	# конвейерная обработка или обработка одного входного параметра
	# раздел process выполняется пока не будут обработаны все входные данные
	# или один параметр командлета
	process {
	
		# SPLATTING на опрелделение пути
		# если абсолютный адрес пути - используем LiteralPath
		if($Path.StartsWith($([ABSPath]::PrefixABS))){$ArgPath = @{LiteralPath = $Path} }
		else {$ArgPath = @{Path = $Path}}

		# Получаем полное имя текстового файла
		# СПЛАТ параметр @ArgPath
		$FullName = Resolve-Path @ArgPath

Write-Verbose "$(Resolve-Path @ArgPath)"
			
		# получаем только имя файла
		$InputName = [IO.Path]::GetFileNameWithoutExtension($FullName)
		# получаем расширение файла
		$InputExt  = [IO.Path]::GetExtension($FullName)

		# если надо повторять строки заголовка сохраним их в $Header
		if ($RepeatCount) { $Header = Get-Content $FullName -TotalCount:$RepeatCount }

		# начальный номер разделенного файла
		$Part = 1
		
		# Читаем из файла $Count строк
		# и передаем их далее в поток за 1 раз
		# и так пока не прочтем все данные из файла
		# далее цикл ForEach по всем $Count строкам файла
		Get-Content $FullName -ReadCount:$Count | % {

			# формируем имя выходного файла включая номер и расширение
			# делаем типа 'FileName-0001.csv'
			$OutputFile = Join-Path $Destination ('{0}-{1:0000}{2}' -f ($InputName,$Part,$InputExt))

			# если задано повторять заголовки
			# если первая итерация то копирование заголовка не делаем
			# в противном случае, записываем заголовок
			if ($RepeatCount -and $Part -gt 1) {
				Set-Content $OutputFile $Header
			}

Write-Verbose "Writing $OutputFile"

			# записываем данные ($_ == $Count строк) в выходной файл
			Add-Content $OutputFile $_
			
			# формируем массив объектов №п\п и имя_файла
			$Arr += [PSCustomObject]@{Part = $Part; Name = $OutputFile}
			
			# увеличиваем номер файла для вывода
			$Part += 1

		}
	}
	# завершающий блок (выполняется всегда)
	end {
		# в любом случае возвращаем массив ','
		return ,$Arr
	}
}





#==============================================================
function Create-CsvListFile {
<#
	.SYNOPSIS
		Создание расширенного списка файлов заданной директории.
	.DESCRIPTION
		Создается расширенный список файлов заданной директории (папки). Результаты помещаются в CSV файл.
		Файл с результатами размещается по указанному в параметре Destination пути или рядом с папкой, если параметр Destination не задан.
		Имя результирующего файла соответствует имени директории с добавлением в конец имени деректории текста '_SCAN'
		В результирующем CSV файле:
			Кодировка файла - UTF8
			Разделитель полей - по умолчанию символ точка с запятой (';') или заданный в параметре Delimiter
			Заголовки столбцов в первой строке
			Имена столбцов: "FullName";"Mode";"Length";"Extension";"NameLen", где:
				"FullName" 	- полное имя файла от корня папки сканирования
				"Mode"		- атрибуты файла / директории
				"Length"	- длина файла в байтах
				"Extension"	- расширение файла с префиксной точкой ('.')
				"NameLen"	- длина полного имени 
			Поля "Length" и "Extension" для директории (папки) не заполняются
	.PARAMETER PathScan
		(Или -p) Задает полное имя папки для сканирования. Подстановочные знаки разрешены.
		Обязательный параметр.
		Если путь начинается с абсолютной адресации - в качестве параметра
		используется LiteralPath, воспринмающий подстановочные символы в пути "как есть"
	.PARAMETER Destination
		(Или -d) Местоположение, в которое следует поместить результирующий файл. 
		Не обязательный параметр. По умолчанию результат распологается рядом с папкой сканирования.
	.PARAMETER Delimiter
		(Или -dl) Определяет символ-разделитель полей CSV файла.
		Не обязательный параметр. По умолчанию символ точка с запятой (';').
	.EXAMPLE
		# сканируем путь C:\Test, результирующий файл размещаем в K:\, разделитель полей - символ ':'
		# имя результирующего файла будет 'Test_SCAN.csv'
		Create-CsvListFile C:\Test\ -d K:\ -dl ':'
	.EXAMPLE
		# сканируем путь C:\Test, результирующий файл размещаем рядом с папкой сканирования в C:\, разделитель полей по умолчанию - символ ';'
		# имя результирующего файла будет 'Test_SCAN.csv'
		Create-CsvListFile C:\Test\
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 30.03.2022
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
    [CmdletBinding()]
    param(
		
		# где ищем файлы (обязательный параметр)
		[Parameter (
			Mandatory = $true, 
			Position=0)]
		#[ValidateNotNullOrEmpty()]    
		#[ValidateScript({ Test-Path -PathType Container -Path $_ })]               
		[Alias('p')]               
		# Имя стартовой папки
		[string]$PathScan #= (Get-Location)
		
		,

		# где размещаем результат (не обязательный параметр)
		[Parameter (
			Mandatory = $false, 
			Position=1)]
		[Alias('d')]               
		# Имя результирующей папки
		[string]$Destination
		
		,
		
		# где размещаем результат (не обязательный параметр)
		[Parameter (
			Mandatory = $false, 
			Position=2)]
		[Alias('dl')]               
		# Символ разделитель
		[string]$Delimiter

    )
	
	if (Check-BlankValue $PathScan) {
		# если не задано что надо сканировать - выходим
		Write-Verbose "Не задан параметр '-PathScan'" -ForegroundColor Red
		RETURN
	}
	
	if ((Test-Path -Path $PathScan -PathType Container) -ne $true ) {
		Write-Verbose "Указанный путь '$PathScan' отсутствует" -ForegroundColor Red
		RETURN
	}
	
	
	# SPLATTING на опрелделение пути
	# если абсолютный адрес пути - используем LiteralPath
	if($PathScan.StartsWith($([ABSPath]::PrefixABS))){$SplatPath = @{LiteralPath = $PathScan} }
	else {$SplatPath = @{Path = $PathScan}}

	# делаем "чистый" путь без префикса
	$ClearPathScan = Get-CleanPath $PathScan
	
	# путь до расположения результирующего файла делаем в простой нотации
	if (Check-BlankValue $Destination) {
		# если не задано - вернем значение по умолчанию
		$Destination = Split-Path $ClearPathScan 
	}
	else {
		if (!(Test-Path -PathType Container -Path $Destination)) {
			Write-Verbose "Путь назначения $Destination не существует"
			$Destination = Split-Path $ClearPathScan 
			Write-Verbose "Установлен путь назначения по умолчанию $Destination"
		}
		else {
			# приводим путь к виду без префикса UNC
			$Destination = Get-CleanPath $Destination
		}
	}

	if (Check-BlankValue $Delimiter) {
		# если не задано - вернем значение по умолчанию
		$Delimiter = ';' 
	}

	# получаем только имя папки
	$FolderName = Split-Path $ClearPathScan -Leaf
	
	# определяем длину пути до целевой папки
	$PrefixLen = (Split-Path $PathScan ).LastIndexOf('\') + 3
	
	# формируем имя файла CSV 
	$CSVFileScan = (Join-Path $Destination ($FolderName + '_SCAN.csv'))
	
	# если файл с результатами сканирования уже есть - удалим его
	if ( (Test-Path -Path $CSVFileScan -PathType Leaf) -eq $true ) {
		# удаляем файл 
		Remove-Item $CSVFileScan | Out-Null
	}

#$Host.EnterNestedPrompt() 

	Write-Verbose "`$PathScan = `t$PathScan"
	Write-Verbose "`$Destination = `t$Destination"
	Write-Verbose "`$Delimiter = `t'$Delimiter'"
	Write-Verbose "`$CSVFileScan = `t$CSVFileScan"

	# формируем CSV файл с результатами сканирования
	# Используем SPLATTING на путь сканирования (@SplatPath)
	Get-Childitem -Force -Recurse @SplatPath  -ErrorAction SilentlyContinue | `
	Select-Object @{Name='FullName'; Expression={$_.FullName.Substring($PrefixLen)}}, Mode, Length, Extension, @{Name='NameLen'; Expression={$_.FullName.Substring($PrefixLen).Length}} | `
	Export-CSV -Path $CSVFileScan -Force -NoTypeInformation -Encoding UTF8 -Delimiter $Delimiter

}	








#==============================================================
function Aling-String {
<#
	.SYNOPSIS
		Дополнить строку заданным символом слева или справа до заданной максимальной длины.
	.DESCRIPTION
		Производит "выравнивание" строки по заданным параметрам
	.PARAMETER StringValue
		(Или sv) Не нулевое не пустое строковое выражение, которое необходимо дополнить
		Обязательный первый параметр 
	.PARAMETER MaxLen
		(Или ml) Максимальное значение длинны строки
		Не обязательный параметр. По умолчанию 65 символов
	.PARAMETER Char
		(Или ch) Символ, которым дополняется строка
		Не обязательный параметр. По умолчанию - пробел
	.PARAMETER Left
		(Или l) Переключатель
		Дополнить до заданной длины слева
	.PARAMETER Right
		(Или r) Переключатель по умолчанию
		Дополнить до заданной длины справа
	.PARAMETER Center
		(Или c) Переключатель
		Дополнить до заданной длины справа и слева
	.EXAMPLE
		Write-host $(Aling-String $ComandletName -MaxLen $HeadingLen -Center) -ForegroundColor Yellow
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 12.05.2019
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding(DefaultParameterSetName='RightAling')]
	
	# описание параметров
	Param (
	
		# значение которое надо преобразовать
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[Alias('sv')]
		[string]$StringValue,
		
		# максимальное значение длинны строки преобразования
		[Parameter (Mandatory = $false, Position=1)]
		[Alias('ml')]
		[int]$MaxLen = 65,
		
		# символ чем дополняем до максимальной длины
		[Parameter (Mandatory = $false)]
		[Alias('ch')]
		[char]$Char = ' ',
		
		# переключатель - дополняем слева
		[Parameter(ParameterSetName='LeftAling', Mandatory=$false)]
		[Alias('l')]
		[Switch]$Left,
		
		# переключатель - дополняем справа (по умолчанию)
		[Parameter(ParameterSetName='RightAling', Mandatory=$false)]
		[Alias('r')]
		[Switch]$Right,
		
		# переключатель - дополняем слева
		[Parameter(ParameterSetName='CenterAling', Mandatory=$false)]
		[Alias('c')]
		[Switch]$Center
	)

	
	# удаляем лишние пробелы
	$RetVal = $StringValue.Trim(' ')

# если отладка - остановимся
if ($IsDebug -eq $true) { 
	$Host.EnterNestedPrompt() 
}

	# если максимальная длина не достигнута
	if ($MaxLen -ge $RetVal.Length) {
		# добиваем ее справа заданным символом
		if ($Left -eq $true) {
			$RetVal = "".PadLeft($MaxLen - $RetVal.Length, $Char[0]) + $RetVal
		}
		elseif ($Center -eq $true){
			$RetVal = "".PadLeft(($MaxLen/2) - ($RetVal.Length/2), $Char[0]) + $RetVal
		}
		# добиваем ее слева заданным символом
		else{ 
			$RetVal = $RetVal + "".PadLeft($MaxLen - $RetVal.Length, $Char[0])
		}
	}
	
	# возвращаем результат преобразования
	return $RetVal
	
}





#==============================================================
function Declension-File {
<#
	.SYNOPSIS
		Склонение окончания 'файл'
	.DESCRIPTION
		В зависимости от количества меняем окончание склонения
		1 - файл''
		2,3,4 - файл'А'
		5,6,7,8,9,0 - файл'ОВ'
	.PARAMETER CountFiles
		Количество файлов
	.EXAMPLE
		Declension-File 234
		'а'
	.EXAMPLE
		Declension-File 3170130
		'ов'
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 12.05.2019
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр
		[Parameter (Mandatory = $true)]
		[ValidateScript({$_ -ge 0})] # значение больше или равно 0
		# параметры (агрументы) функции
		[long]$CountFiles

	) 

	# если количество указано
	if(!(Check-BlankValue $CountFiles)) {

		# определяем последнюю цифру в числе
		# [-1] вернет тип Char, а нам нужен String чтобы получить цифру
		# в случае Char при приобразовании к типу  Int получим код символа :(
		$LastDigitInNumber = [int]([string](($CountFiles.ToString())[-1]))
		
		# формируем склонения 'файл'
		switch ($LastDigitInNumber) {
			{$_ -eq 1} 				 { $Declension = "";  Break } 
			{$_ -ge 2 -and $_ -le 4} { $Declension = "а"; Break }
			Default 				 { $Declension = "ов" }
		}
	}
	
	return $Declension
}















	
	