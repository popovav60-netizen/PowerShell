#==============================================================
# Изменения: 
#   18.01.2026
# 	    1. в функцию Set-AbsUncPath 
#		   1.1. добавлен параметр переключатель проверки наличия пути
#		   1.2. изменен алгоритм проверки подстановочных символов
#		   в имени папки
#		2. добавлены функции Get-TypeBOM и Get-BytesInFile
#		3. в функции Get-CountLinesInFile изменен алгоритм подсчета строк
#
# 	20.06.2023
# 		1. в функцию Get-CountLinesInFile добавлена обработка ошибки
#		   попытки открытия заблокированного файла
#
# 	06.04.2023
# 		1. в функцию Get-CountLinesInFile добавлен режим поддержки конвейера
#
# 	13.08.2021 
#		1. в модулях контроль минимальной длины делается с привязкой к 
#		   статическим свойствам класса MinValue модуля CommonConst
#
# Используются модули:
#			CommonConst.psm1
#==============================================================
# загружаем статические свойства
Using Module CommonConst

# для определения типа файла
Add-Type -AssemblyName "System.Web"


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
	if (!$TestValue -or 
		[string]::IsNullOrWhiteSpace($TestValue) -or 
		[string]::IsNullOrEmpty($TestValue)) 
		{ return $true }
	# если предыдущая проверка не отработала, уточним...
	else {
		# с учетом последующих идей...
		switch ($TestValue.GetType().Name){
			'Hashtable' { return ($TestValue.Count -eq 0) }
			# ...
			default { return $false }
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
		Шаблон Ip4 адреса и имени DNS сервера берутся из статического свойства [Ip4]::PatternIp4 модуля CommonConst
		Если путь соответствует шаблону - возвращается $true, иначе - $false
		Наличие физического пути не проверяется
	.PARAMETER Path
		Путь который проверяется
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
		Get-CleanPath '\\10.185.152.72\Personal\PopovAV\TestL\l2f21ck1' 		# вернет '\\10.185.152.72\Personal\PopovAV\TestL\l2f21ck1'
		Get-CleanPath '\\?\UNC\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1' 	# вернет '\\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1'
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

		# тело функции
		$FreeDrv = (ls function:[d-z]: -n | ?{ !(Test-Path $_ -ErrorAction SilentlyContinue) })
		
		if ($FreeDrv.length -eq 0) { return '' }
		
		return $FreeDrv[0]
	
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
		Если в пути есть подстановочные символы, позвращает его без префикса абсолютной ГТС адресации
		Проверяет наличие пути при установленном переключателе Check
	.PARAMETER Path
		Путь который дополняем префиксом абсолютного адреса
		Не нулевое строковое выражение длинной более 1 символа 
	.PARAMETER Check
		Переключатель - Не обязательный параметр
		Если установлен, то производится физическая проверка наличия пути
	.EXAMPLE
		Set-AbsUncPath 'C:\Work_PC\TestPath' 
		# вернет '\\?\C:\Work_PC\TestPath'
	.EXAMPLE
		Set-AbsUncPath '\\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1' 
		# вернет '\\?\UNC\10.385.152.72\Personal\PopovAV\TestL\l2f21ck1'
	.EXAMPLE
		Set-AbsUncPath 'C:\Work_PC\TestPath\*.txt' 
		# вернет \\?\C:\Work_PC\TestPath\*.txt'
	.EXAMPLE
		Set-AbsUncPath 'xz:\temp\bad?folder\test.txt'
		# вернет '\\?\xz:\temp\bad?folder\test.txt'
	.EXAMPLE
		Set-AbsUncPath 'xz:\temp\bad?folder\test.txt' -Check 
		# вернет $null - т.к. такого файла/пути нет
	.EXAMPLE
		Set-AbsUncPath 'xz:\temp\[bad?folder]\test.txt' 
		# вернет xz:\temp\[bad?folder]\test.txt' - т.к. имя папки содержит
		# не допустимые символы []
	.EXAMPLE
		Set-AbsUncPath 'xz:\temp\[bad?folder\te]st.txt'
		# вернет \\?\xz:\temp\[bad?folder\te]st.txt' - т.к. имя папки не содержит
		# не допустимые символы [] - в имени папки присутствует только 1 символ - [
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
		[Parameter (Mandatory = $false)]
#		[ValidateNotNullOrEmpty()]              
#		[ValidateScript( { $_.length -ge $([MinValue]::RootPathLen) } )]    # >=   'c:'        
		[Alias('PTH')]
		[string]$Path
		
		,
		
		# 18.01.2026
		[Parameter (Mandatory = $false, 
				HelpMessage="Проверить наличие")]
		# физическая проверка наличия файла/пути
		[Switch] $Check
		
	)
	
	# проверяем параметр - если путь не задан, возьмем текущий 
	if( !$Path ) {$Path = Get-Location}
	
	# если есть недопустимые символы в пути - выходим
	if ($Path.IndexOfAny([System.IO.Path]::GetInvalidPathChars()) -ne -1 ) {return $null}
	
	# очень короткий путь (<=)
	if ($Path.length -le $([MinValue]::FSOPathLen)) {
		if ($Path -notmatch $([ABSPath]::PatternDrvAndOptionalSlesh)) { return $null }
		if ($Path.EndsWith(':')) {return "$([ABSPath]::PrefixABS)$Path\" }
		return "$([ABSPath]::PrefixABS)$Path"
	}
	
	# 18.01.2026
	# ВЛОЖЕННАЯ .....................................................
	# вспомогательная функция
	# вернет путь или $null если его нет
	function Check-Path([string]$psPath) {
		if( !(Test-Path -LiteralPath $psPath -PathType Container) ) { return $null }
		return $psPath
	}
	
	
	# 18.01.2026
	# если путь не начинается с префикса абсолютной адресации и 
	# имя папки содержит подстановочные символы []
	# вернем его без абсолютного UNC префикса или в случае необходимости проверки его наличия
	# или путь - если он есть или при его отсутствия - $null
	if ( !$Path.StartsWith([ABSPath]::PrefixABS) -and $Path -match "$([ABSPath]::PatternSubstFolder)") {
		if($Check) { $Path = Check-Path $Path }
		return $Path
	}
	

	# если параметр не содержит абсолютный префикс  '\\?\'
	if ( $Path -and !$Path.StartsWith([ABSPath]::PrefixABS) ) {
		# если сетевой адрес - сделаем абсолютный сетевой UNC формат  '\\?\UNC\' & $Path без первого '\'
		If ($Path.StartsWith("\\")) { $Path = ($([ABSPath]::PrefixABSUNC) + $Path.Substring(1)) }
		# иначе (не сетевой адрес) сделаем абсолютный локальный формат '\\?\' & $Path
		else {$Path = "$([ABSPath]::PrefixABS)$Path"}
	}

	if($Check) { $Path = Check-Path $Path }
	return $Path
	
}	
	
	


#==============================================================
function Get-SplatParam {
<# 
	.SYNOPSIS
		Формирует хеш таблицу для сплаттинг параметров
	.DESCRIPTION
		Если путь не включает подстановочные сисмволы, то в сплаттинге используется LiteralPath и к пути добавляется
		префикс абсолютной UNC адресации, иначе в сплаттинге используется просто Path
		Фильтр и глубина сканирования - не обязательные параметры, если они не заданы, то фильтр не устанавливается, т.е.
		все файлы и сканируется на всю глубину вложенности папок
	.PARAMETER Path
		Обязательный параметр
		путь начала обработки объектов файловой системы
		может содержать подстановочные символы, но тогда префикс абсолютной UNC адресации не устанавливается
	.PARAMETER Filter
		фильтр - подстановочные знаки для объектов
		Не обязательный параметр
	.PARAMETER Depth
		глубина сканирования
		Не обязательный параметр
		если не установлен - сканируется по всей глубине вложенности папок, иначе только на заданную глубину
	.EXAMPLE
		Get-SplatParam '\\?\c:\temp'
	.EXAMPLE
		Get-SplatParam '\\10.181.52.54\gibr\1_GIBR_CA\PERSONAL\PopovAV'
	.EXAMPLE
		# путь + фильтр + глубина сканирования
		Get-SplatParam $TrainingPath '*.txt' 2
	.EXAMPLE
		# путь + глубина сканирования (указываем имя параметра, т.к. второй не обязательный параметр (фильтр) пропустили)
		Get-SplatParam 'c:\temp' -piDepth 2
	.EXAMPLE
		путь с подстановочными символами + глубина сканирования
		Get-SplatParam (JP $TrainingPath '*.txt') -piDepth 2
	.EXAMPLE
		# сетевой путь с подстановочными символами
		Get-SplatParam '\\10.181.52.54\gibr\1_GIBR_CA\PERSONAL\PopovAV\*.txt'
	.INPUTS
		System.String
		System.Int32
	.OUTPUTS
		System.Collections.Hashtable
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 04.04.2024
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
	
		[Parameter (Mandatory = $true)]
		[ValidateNotNullOrEmpty()]              
		[string]$Path
		, 
		[Parameter (Mandatory = $false)]
		[string]$Filter
		,
		[Parameter (Mandatory = $false)]
		[int]$Depth
	)


	# пробуем получить путь с префиксом абсолютной UNC адресацией
	$UNCPath = Set-AbsUncPath $Path
	
	# если путь задан не правильно - выходим
	if( !$UNCPath ) { return $null }

	# формируем хэш таблицу с базовыми параметры сплаттинга
	$SplatPath = 	@{Force			= $true
				      Recurse 		= $true
				      ErrorAction 	= 'SilentlyContinue'	 
					}
		
	# если путь не начинается с префикса абсолютной адресации
	if( !$UNCPath.StartsWith([ABSPath]::PrefixABS) ) {
		# добавляем в хэш таблицу ключ пути с подстановочными символами
		$SplatPath.Path 		= $UNCPath
	}
	else {
		# добавляем в хэш таблицу ключ пути  UNC адресации
		$SplatPath.LiteralPath 	= $UNCPath
	}
	
	# если задан фильтр, добавим его
	if( $Filter ) {
		$SplatPath.Filter	= $Filter
	}
				
	# если задана глубина сканирования, добавим ее
	if( $Depth -and $Depth -gt 0) {
		$SplatPath.Depth	= $Depth
	}
				
	# возвращаем сформированные параметры в виде хэш таблицы
	return $SplatPath
	
}


	
	

#==============================================================
function Get-CountItem {
<# 
	.SYNOPSIS
		Получить количество элементов в заданной папке включая вложенные папки.
	.DESCRIPTION
		Подсчитывается количество элементов в зависимости от установленного параметра (переключателя) NoFolder. 
	.PARAMETER Path
		Или -P
		Начальный путь для сканирования
		Не нулевое строковое выражение длиной более 1 символа
		Возможно указание абсолютного адреса пути
	.PARAMETER NoFolder
		Или -NF
		Переключатель
		Если задан, то подсчет элементов ведется без учета папок
	.PARAMETER Format
		Или -F
		Переключатель (не обязательный параметр)
		Если задан, то количество найденных элементов форматируется с разделением тысяч (строковое представление)
	.PARAMETER NoRecurse
		Или -NR
		Переключатель (не обязательный параметр)
		Если задан, то вложенные подпапки не обрабатываются
	.EXAMPLE
		Get-CountItem '\\10.85.152.72\Personal\PopovAV\TestL\l2f21ck1'	# вернет типа 599
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1'	-NoRecurse	# вернет типа 10
	.EXAMPLE
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1'				# вернет типа 8427
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -NoFolder	# вернет типа 6950
	.EXAMPLE
		Get-CountItem 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -NF -Format	# вернет типа 6 950
		Get-CountItem '\\?\k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -NF -F	# вернет типа 6 950
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
		[Alias('P')]
		[string]$Path
		
		,
		
		# Не обрабатывать подкаталоги
		[Parameter (Mandatory = $false)]
		[Alias('NR')]
		[Switch] $NoRecurse
				
		,
		
		# без учета папок
		[Parameter (Mandatory = $false)]
		[Alias('NF')]
		[Switch] $NoFolder

		,
		
		# отформатировать вывод
		[Parameter (Mandatory = $false)]
		[Alias('F')]
		[Switch] $Format
		
	)
		# SPLATTING на определение пути
		# если абсолютный адрес пути - используем LiteralPath
		if($Path.StartsWith($([ABSPath]::PrefixABS))){$SplatPath = @{LiteralPath = $Path} }
		# если простой путь - используем Path
		else {$SplatPath = @{Path = $Path}}
		
		# если путь отсутствует - выходим
		if (!(Test-Path @SplatPath)) { return 0 }
		
		
		# добавляем в SPLATTING определение вложенных папок
		$SplatPath += @{Recurse = !$NoRecurse; Force = $true}
		
		# возвращает кол-во всех элементов
		if (!$NoFolder) {
			$RetVal = (Get-ChildItem @SplatPath).Length
		}
		# только кол-во файлов если $false
		else {
			$RetVal =  (Get-ChildItem @SplatPath | ? PSIsContainer -ne $true ).Length
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
		Подсчитывается суммарный размер папки, включая все вложенные элементы подпапок включая скрытые и системные элементы структуры
		Возвращает значения в зависимости от установленных переключателей
		Если переключатели не установлены - возвращается значение в байтах
		Одновременное использование переключателей Mb, Gb и Tb не допускается
	.PARAMETER Path
		Или -P
		Начальный путь для сканирования
		Не нулевое строковое выражение длиной более 1 символа
		Возможно указание абсолютного адреса пути
	.PARAMETER NoRecurse
		Или -NR
		Переключатель (не обязательный параметр)
		Если задан, то вложенные подпапки не обрабатываются
	.PARAMETER Format
		Или -F
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
		Если задан, то общий размер найденных элементов указывается в терабайтах с точностью до 3 знаков после целого значения
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' 			# вернет типа 7077075672
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -Format	# вернет типа 7 077 075 672
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -Mb		# вернет типа 6749,225
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -F -Mb	# вернет типа 6 749,225
	.EXAMPLE
		 Get-FolderSize 'k:\WORK_PC\PROJECT\EXCEL\L\l2f252a1' -F -Gb	# вернет типа 6,591
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
		[Alias('P')]
		[string]$Path
		
		,
		
		# Не обрабатывать подкаталоги
		[Parameter (Mandatory = $false)]
		[Alias('NR')]
		[Switch] $NoRecurse
		
		,
		
		# отформатировать вывод
		[Parameter (Mandatory = $false)]
		[Alias('F')]
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
	
		# SPLATTING на определение пути
		# если абсолютный адрес пути - используем LiteralPath
		if($Path.StartsWith($([ABSPath]::PrefixABS))){$SplatPath = @{LiteralPath = $Path} }
		else {$SplatPath = @{Path = $Path}}
		
		if (!(Test-Path @SplatPath)) { return 0 }
		
		# SPLATTING на определение вложенных папок
		$SplatPath += @{Recurse = !$NoRecurse; Force = $true}
		
		# -Property Length - присутствует только у файлов! поэтому в объекте Measure свойство Count
		# будет указывать на кол-во файлов!
		[double]$RetVal = (Get-ChildItem @SplatPath | Measure-Object -Property Length -Sum).Sum

		if     ($Mb) { $RetVal = [math]::Round(($RetVal/1Mb),3) }
		elseif ($Gb) { $RetVal = [math]::Round(($RetVal/1Gb),3) }
		elseif ($Tb) { $RetVal = [math]::Round(($RetVal/1Tb),3) }
		else		 { $RetValue = $RetVal }
		
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
		Возвращает массив объектов имен разделенных файлов
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
        [String[]]$Path
		
		,

		# максимальное количество строк в выходных файлах
		# обязательный параметр во 2-й позиции больше 0
        [Alias('c')]
        [Parameter(Position=1, Mandatory=$true)]
		[ValidateScript( {$_ -gt 0} )] # значение больше 0
        [Int32]$Count
		
		,

		# путь назначения выходных файлов
        [Alias('d')]
        [Parameter(Position=2)]
        [String]$Destination='.'
		
		,

		# количество строк заголовка для повторения в выходных файлах
        [Alias('rc')]
        [Parameter()]
        [Int32]$RepeatCount

    )
	
	# выполняется всегда в начале обработки (инициализация)
	begin {
		# определяем имя функции
		$MyNameIs = $MyInvocation.MyCommand.Name
		
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
	
		if (Is-PlainText $Path) { 
			# SPLATTING на определение пути
			# если абсолютный адрес пути - используем LiteralPath
			if($Path.StartsWith($([ABSPath]::PrefixABS))){$ArgPath = @{LiteralPath = $Path} }
			else {$ArgPath = @{Path = $Path}}

			# Получаем полное имя текстового файла
			# СПЛАТ параметр @ArgPath
			$FullName = Resolve-Path @ArgPath

	Write-Verbose "$MyNameIs $(Resolve-Path @ArgPath)"
				
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

	Write-Verbose "$MyNameIs Writing $OutputFile"

				# записываем данные ($_ == $Count строк) в выходной файл
				# через Add-Content т.к. возможно туда уже записали заголовок
				Add-Content $OutputFile $_
				
				# формируем массив объектов №п\п и имя_файла
				$Arr += [PSCustomObject]@{Part = $Part; Name = $OutputFile}
				
				# увеличиваем номер файла для вывода
				$Part += 1

			}
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
		Создание расширенного списка файлов заданной директории (папке).
	.DESCRIPTION
		Создается расширенный список файлов заданной директории (папки). Результаты помещаются в CSV файл.
		Файл с результатами размещается по указанному в параметре Destination пути или, если параметр Destination не задан, рядом со сканируемой папкой.
		Имя результирующего CSV файла соответствует имени папки с добавлением в конец текста '_SCAN'
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
		Информацию по работе командлета можно посмотреть в разделе реестра $([RegValue]::RKFullPathXchCsv)
		или выполнить следующий командлет Get-Item -Path $([RegValue]::RKFullPathXchCsv)
		или запросить конкретный параметр, используя командлет Get-CsvFileInfo с нужным параметром (см. примеры)
	.PARAMETER PathScan
		(Или -p) Задает полное имя папки для сканирования. Возможна абсолютная UNC адресация.
		Обязательный параметр.
		Если путь начинается с абсолютной адресации (\\?\[UNC\])- в качестве параметра при сканировании
		используется LiteralPath, воспринимающий подстановочные символы в пути "как есть"
	.PARAMETER Destination
		(Или -d) Местоположение, в которое следует поместить результирующий файл. 
		Не обязательный параметр. По умолчанию (если параметр не указан) результат располагается рядом с папкой сканирования.
	.PARAMETER Delimiter
		(Или -dl) Определяет символ-разделитель полей CSV файла.
		Не обязательный параметр. По умолчанию (если параметр не указан) устанавливается символ точка с запятой (';').
	.EXAMPLE
		Create-CsvListFile C:\Test\ -d K:\ -dl ':'
			сканируем путь C:\Test, результирующий файл размещаем в K:\, разделитель полей - символ ':'
			полное имя результирующего файла будет 'c:\Test_SCAN.csv'
		Посмотреть информацию о процессе
		Get-CsvFileInfo $([RegValue]::RVCsvFileName)
		Get-CsvFileInfo $([RegValue]::RVCsvFileScanDate)
	.EXAMPLE
		Create-CsvListFile C:\Test\Subfolder
			сканируем путь C:\Test\Subfolder, результирующий файл размещаем рядом с папкой сканирования в C:\Test, 
			разделитель полей по умолчанию - символ ';'
			полное имя результирующего файла будет 'C:\Test\Subfolder_SCAN.csv'
		Посмотреть всю информацию о процессе из реестра
		Get-Item -Path $([RegValue]::RKFullPathXchCsv)
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 30.03.2022
		Для корректной работы требуется модуль CommonConst.psm1 версии 1.0.1 и выше
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
	
	#######################################################
	#
	# определяем имя функции
	$MyNameIs = $MyInvocation.MyCommand.Name
	
	[string]$Messages
	[string]$RegKey
	# раздел реестра для обмена с информацией по процессу сканирования
	# что-то типа HKCU:\Software\PowerShell\PAV\Xchange\CSVFile
	$RegKey = $([RegValue]::RKFullPathXchCsv)
	
	# если раздел существует
	if (Test-Path -Path $RegKey -PathType Container) {
		# очистим раздел
		Remove-Item -Path $RegKey  | Out-Null
	}
	
	
	#======================================================
	# проверим путь для сканирования
	# если не задано что надо сканировать - выходим
	if (Check-BlankValue $PathScan) {
		$Messages = $MyNameIs + " Er. Не задан параметр '-PathScan'"
		Set-RegValue $RegKey $([RegValue]::RVCsvFileMsg) $Messages
		Write-Verbose $Messages 	#-ForegroundColor Red
		RETURN
	}
	
	# если путь не существует - выходим
	if ((Test-Path -Path $PathScan -PathType Container) -ne $true ) {
		$Messages = $MyNameIs  + " Er. Указанный путь '$PathScan' отсутствует"
		Set-RegValue $RegKey $([RegValue]::RVCsvFileMsg) $Messages
		Write-Verbose $Messages 	#-ForegroundColor Red
		RETURN
	}
	
	
	# делаем SPLATTING на путь сканирования
	# если абсолютный адрес пути - используем LiteralPath если нет то Path
	if($PathScan.StartsWith($([ABSPath]::PrefixABS))){$SplatPath = @{LiteralPath = $PathScan} }
	else {$SplatPath = @{Path = $PathScan}}

	# определяем "чистый" путь без префикса
	$ClearPathScan = Get-CleanPath $PathScan
	
	#======================================================
	# путь до расположения результирующего файла делаем в простой нотации
	# если не задано - установим значение по умолчанию
	if (Check-BlankValue $Destination) {
		$Destination = Split-Path $ClearPathScan 
	}
	# проверим на существование путь для размещения файла
	else {
		# путь не существует
		if (!(Test-Path -PathType Container -Path $Destination)) {
			Write-Verbose "$MyNameIs Путь назначения $Destination не существует"
			$Destination = Split-Path $ClearPathScan 
			$Messages = $MyNameIs  + " Wr. Установлен путь назначения по умолчанию $Destination"
			Set-RegValue $RegKey $([RegValue]::RVCsvFileMsg) $Messages
			Write-Verbose $Messages
		}
		# путь есть
		else {
			# приводим путь к виду без префикса UNC
			$Destination = Get-CleanPath $Destination
		}
	}
	
	#======================================================
	# проверим разделитель полей
	# если не задано - вернем значение по умолчанию
	if (Check-BlankValue $Delimiter) {
		# если не задано - вернем значение по умолчанию
		$Delimiter = ';' 
	}
	# на всякий случай оставляем только первый символ
	else { $Delimiter = (($Delimiter.Trim(" "))[0]).ToString() }

	
	#======================================================
	# получаем только имя папки сканирования
	$FolderName = (Split-Path $ClearPathScan -Leaf).Trim([IO.Path]::DirectorySeparatorChar)
	
	# путь до папки сканирования приводим к виду с обязательным разделителем путей в конце
	# типа из '\\?\k:\WORK_PC\PROJECT\EXCEL\L\l2f159l1\' делаем '\\?\k:\WORK_PC\PROJECT\EXCEL\L\'
	# так как после Split-Path объект будет иметь вид '\\?\k:\WORK_PC\PROJECT\EXCEL\L' без конечного слеша
	# делаем это через удаление с последующим добавлением для случая корневой папки
	# например папка типа '\\?\k:\temp' после Split-Path будет иметь вид '\\?\k:\', поэтому приводим к одинаковому виду
	# метод TrimEnd объекта (результата Split-Path) удалит разделитель только если он есть, после чего добавим его
	# что обеспечит наличие разделителя в конце объекта в любом случае
	$PrefixPath = (Split-Path $PathScan).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
	# определяем длину пути до целевой папки
	# при сканировании начальная часть строки этой длины не будет учитываться в результирующем csv файле
	$PrefixLen = $PrefixPath.Length
	
	# формируем имя файла CSV 
	$CSVFileScan = (Join-Path $Destination ($FolderName + '_SCAN.csv'))
	
	# если файл с результатами сканирования уже есть
	if ( (Test-Path -Path $CSVFileScan -PathType Leaf) -eq $true ) {
		# удаляем файл 
		Remove-Item $CSVFileScan | Out-Null
	}

	Write-Verbose "$MyNameIs `$PathScan    = `t$PathScan"
	Write-Verbose "$MyNameIs `NoPrefixPath = `t$($PathScan.Substring($PrefixLen))"
	Write-Verbose "$MyNameIs `@SplatPath   = `t$($SplatPath.Keys) $($SplatPath.Values)"
	Write-Verbose "$MyNameIs `$Destination = `t$Destination"
	Write-Verbose "$MyNameIs `$Delimiter   = `t'$Delimiter'"
	Write-Verbose "$MyNameIs `$CSVFileScan = `t$CSVFileScan"


#$Host.EnterNestedPrompt() 

	#======================================================
	# пишем информацию в реестр
	Set-RegValue $RegKey $([RegValue]::RVCsvFileName) 		$CSVFileScan
	Set-RegValue $RegKey $([RegValue]::RVCsvFileScanDate) 	(Get-Date).ToString('dd.MM.yyyy HH:mm:ss')
	Set-RegValue $RegKey $([RegValue]::RVCsvFileDelimiter) 	$Delimiter


	# запускаем таймер
	$ScanWatch = [System.Diagnostics.Stopwatch]::StartNew()
	$ScanWatch.Start() #Запускаем таймер сканирования



	#======================================================
	# формируем CSV файл с результатами сканирования
	# Используем SPLATTING (@SplatPath) на путь сканирования
	Get-Childitem -Force -Recurse @SplatPath  -ErrorAction SilentlyContinue | `
	Select-Object @{Name='FullName'; Expression={$_.FullName.Substring($PrefixLen)}}, Mode, Length, Extension, @{Name='NameLen'; Expression={$_.FullName.Substring($PrefixLen).Length}} | `
	Export-CSV -Path $CSVFileScan -Force -NoTypeInformation -Encoding UTF8 -Delimiter $Delimiter

	# Пояснения:
	#
	# Get-Childitem -Force -Recurse @SplatPath -ErrorAction SilentlyContinue
	# получить список всех (-Force) файлов и папок включая вложенные (-Recurcse) 
	# начиная с заданной папки в стандартной или абсолютной адресации используя( @SplatPath )
	# с подавлением сообщений об ошибках с возобновлением выполнения  (-ErrorAction SilentlyContinue)
	#
	# | 
	# результаты передать по конвейеру
	# 
	# Select-Object @{Name='FullName'; Expression={$_.FullName.Substring($PrefixLen)}}, Mode, Length, Extension, @{Name='NameLen'; Expression={$_.FullName.Substring($PrefixLen).Length}}
	# из конвейера сформировать ОБЪЕКТ содержащий:
	# вычисляемое свойство - полное имя пути без префикса (из хэш таблицы (ключ, значение))
	# (@{Name='FullName'; Expression={$_.FullName.Substring($PrefixLen)}}) 
	# атрибуты, размер и расширение (Mode, Length, Extension)
	# вычисляемое свойство - длину полного пути из хэш-таблицы (ключ, значение)
	# @{Name='NameLen'; Expression={$_.FullName.Substring($PrefixLen).Length}}
	#
	# | 
	# результаты в виде объекта передать по конвейеру
	#
	# Export-CSV -Path $CSVFileScan -Force -NoTypeInformation -Encoding UTF8 -Delimiter $Delimiter
	# результат из конвейера поместить в формате CSV файла с перезаписью (-Force) без служебной информации (-NoTypeInformation)
	# в кодировке UTF8 (-Encoding UTF8) - для корректного отображения русских букв в MS Excel
	# разделитель столбцов (-Delimiter) задан в параметре $Delimiter -  ";" для русской версии MS Office - иначе параметр не указываем
	
	# остановим таймер
	$ScanWatch.Stop()
	
	Set-RegValue $RegKey $([RegValue]::RVCsvFileScanTime) 	$ScanWatch.Elapsed.ToString().Substring(0,11)
	
	Set-RegValue $RegKey $([RegValue]::RVCsvFileSize) 		((Get-Childitem -Path $CSVFileScan).Length).ToString()
	Set-RegValue $RegKey $([RegValue]::RVCsvFileRows) 		((Get-Content -Path $CSVFileScan).Length).ToString()
	Set-RegValue $RegKey $([RegValue]::RVCsvFileDelimiter) 	$Delimiter
	
	Set-RegValue $RegKey $([RegValue]::RVCsvFileMsg) "Ok. Сканирование и создание CSV файла завершено"
	
}	



#==============================================================
function Get-CsvFileInfo {
<#
	.SYNOPSIS
		Возвращает информацию по csv файлу сформированную командлетом Create-CsvListFile.
	.DESCRIPTION
		В зависимости от значения параметра возвращает сформированную информацию по csv файлу сформированную командлетом Create-CsvListFile.
		Если файл не сформировался по большинству параметров возвращается $null
		Статус результата работы можно посмотреть задав параметр $([RegValue]::RVCsvFileMsg)
	.PARAMETER Info
		Или -i
		Допустимы следующие значения параметра:
			$([RegValue]::RVCsvFileName)
			$([RegValue]::RVCsvFileScanDate)
			$([RegValue]::RVCsvFileScanTime)
			$([RegValue]::RVCsvFileSize)
			$([RegValue]::RVCsvFileRows)
			$([RegValue]::RVCsvFileDelimiter)
			$([RegValue]::RVCsvFileMsg)
		В зависимости от значения параметра возвращается запрашиваемая информация в формате текстовой строки
		Не обязательный параметр - по умолчанию запрашивается имя файла. Если файл не сформировался возвращается 
		информация по запросу сообщения $([RegValue]::RVCsvFileMsg)
	.EXAMPLE
		Get-CsvFileInfo $([RegValue]::RVCsvFileSize)
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 06.04.2022
		Для корректной работы требуется модуль CommonConst.psm1 версии 1.0.1 и выше
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
    [CmdletBinding()]

    param(
		
		# где ищем файлы (обязательный параметр)
		[Parameter (Mandatory = $false)]
		[Alias('p')]   
		# Имя параметра
		[string]$Info
	)		

	if (Check-BlankValue $Info) {
		$Info = $([RegValue]::RVCsvFileName)
	}
	
	$RegKey = $([RegValue]::RKFullPathXchCsv)
	$CSVFileRetValue = Get-RegValue $RegKey $Info 
	
	if (Check-BlankValue $CSVFileRetValue) {
		$CSVFileRetValue = Get-RegValue $RegKey $([RegValue]::RVCsvFileMsg)
	}

	return $CSVFileRetValue

}




#==============================================================
function Get-VersionModule {
<#
	.SYNOPSIS
		Получение версии модуля.
	.DESCRIPTION
		Проверяется наличие модуля и если модуль присутствует, возвращается его версия в виде числа.
		Если указанный модуль отсутствует возвращается -1
		Версия в виде числа: сотни - MAJOR десятки - MINOR еденицы - BUILD    REVISION не определяется
		Ноль означает отсутствие версии
	.PARAMETER ModuleName
		(Или -n) Задает имя модуля.
	.EXAMPLE
		Get-VersionModule CommonFn
			вернет что-то типа 101
	.EXAMPLE
		Get-VersionModule 'WriteLog'
			вернет 0
	.EXAMPLE
		Get-VersionModule 'NotModulePresent'
			вернет -1
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 05.04.2022
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>


	[CmdletBinding()]
	
	# описание параметров
	Param (
	
		# значение которое надо преобразовать
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[Alias('n')]
		[string]$ModuleName
		
	)


	if (Get-Module -ListAvailable -Name $ModuleName) {
		$ModVer =  (Get-Module $ModuleName).version
		
		[int]$Ret = ( $ModVer.major * 100 + $ModVer.minor * 10 )
		if ($ModVer.build -ne -1) { $Ret += $ModVer.build }
		
		return $Ret
	}
	else {
		return -1
	}

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
		# в случае Char при преобразовании к типу  Int получим код символа :(
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


#==============================================================
function Is-PlainText{
<#
	.SYNOPSIS
		Проверить файл на простой текстовый формат по его расширению
	.DESCRIPTION
		Использует модуль CommonConst - [TxtPlain]::Match
		Поддерживает конвейер
	.PARAMETER FileNameOrExt
		Полное имя файла или расширение или объект файловой системы если передается по конвейеру
	.EXAMPLE
		Is-PlainText 'c:\Test_SCAN.csv'
	.EXAMPLE
		выводит только файлы простого текстового формата
		Get-ChildItem d:\temp -Recurse | Is-PlainText | ft
	.INPUTS
		String 
		[IO.FileInfo]
	.OUTPUTS
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 04.04.2024
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр
		[Parameter (Mandatory = $true, ValueFromPipeline = $True)]
		[string]$FileNameOrExt
	)
	
	begin {  # один раз
		# режим pipeline? или как параметр функции
		$PipeMode = -not $PSBoundParameters.FileNameOrExt
	}
	process {	# для каждого файла или параметра

		# если конвейер
		if ($PipeMode) {
		
			# если расширение соответствует шаблону - вернем объект
			if( $_.Extension -match "$([TxtPlain]::Match)" ) { $_ }
		}
		else {
			# если параметр не задан - вернем $false
			if( !$FileNameOrExt ) { return $false }
			
			# получаем расширение файла
			$FileExt = ([System.IO.FileInfo]$FileNameOrExt).Extension

			# возвращаем статус простого текстового формата
			# match вернет $true если расширение из нашего списка или $false - если его там нет
			# мы и вернем то что вернет match
			return ( $FileExt -match "$([TxtPlain]::Match)" )
		}
	}
}	
	


#==============================================================
function Get-TypeFile{
<#
	.SYNOPSIS
		Получить тип файла по его расширению или из реестра или используя MIME
	.DESCRIPTION
		Командлет (функция) использует шаблоны расширения файлов из модуля 
		CommonConst версии не ниже 1.0.3
		Поддерживает конвейерную обработку и параметры
		Определяет по расширению 
			[TxtPlain] 	- простой текстовый формат
			[Word]		- документы MS Word 
			[Excel] 	- документы MS Excel 
			[Read]		- читаемый документ
			[Graphic]	- графические файлы
			[Archive]	- архивы 
			[Video] 	- видео
			[Audio] 	- аудио
			[Exec] 		- исполняемые файлы, скрипты
			[Database]	- базы данных
			[Crypt] 	- криптографические файлы
			[Sig]		- подписи и сертификаты
			[Virtual] 	- файлы виртуализации
		Если определить тип по заданным шаблонам из модуля CommonConst не удается,
		производится попытка определения типа через зарегистрированные типы файлов в реестре
		Если в реестре нет описания типа файла, то производится попытка получить описание,
		используя [System.Web.MimeMapping]::GetMimeMapping
		Если получить описание типа файла не удается, то все свойства типов файла возвращаемого 
		объекта будут $false, а свойство TypeIs будет содержать 'Unknown' и свойство Unknown будет $true
		Некоторые расширения могут попадать сразу в несколько типов, например файлы скриптов
		это простой текстовый формат и исполняемый файл и т.п.
	.PARAMETER FileNameOrExt
		или 'FN', 'FEXT', 'FNE'
		Полное имя файла или расширение с точкой или объект файловой системы 
	.PARAMETER FilferKeys
		или 'Filter'
		Не обязательный параметр
		Функционирует в 2-х режимах:
		1. Задаются конкретные базовые типы файлов
			При указании данного параметра функция работает как фильтр на заданные базовые типы
			Допускаются указывать следующие типы в любом сочетании:
				TxtPlain    - фильтр для простого текстового файла
				Word        - фильтр для документа MS Word
				Excel       - фильтр для документа MS Excel
				Read        - фильтр для читаемого документа
				Graphic     - фильтр для графического файла
				Archive     - фильтр для архивного файла
				Video       - фильтр для видео файла
				Audio       - фильтр для аудио файла
				Exec        - фильтр для исполняемого файла
				Database    - фильтр для файла базы данных
				Crypt       - фильтр для криптографического (возможно зашифрованного) файла
				Sign        - фильтр для файла подписи или сертификата
				Virtual     - фильтр для файла виртуализации
		2. Указывается тип IO.FileInfo 
			данный тип указывается автоматически при при встраивании (привязки) данной функции 
			в определении типа [System.IO.FileInfo]
			Привязка делается командой Update-TypeData -PrependPath $PSHOME\FileType.Types.ps1xml
			Файл FileType.Types.ps1xml должен располагаться в домашней директории PowerShell - $PSHOME
			вот так выглядит файл FileType.Types.ps1xml
			
			<?xml version="1.0" encoding="utf-8" ?>
			<Types>
			    <Type>
			        <Name>System.IO.FileInfo</Name>
			        <Members>
			            <ScriptProperty>
			                <Name>TypeFile</Name>
			                <GetScriptBlock>
			                    Get-TypeFile -FileNameOrExt $this IO.FileInfo
			                </GetScriptBlock>
			            </ScriptProperty>
			            <AliasProperty>
			                <Name>FileTypeExt</Name>
			                <ReferencedMemberName>TypeFileExt</ReferencedMemberName>
			            </AliasProperty>
			        </Members>
			    </Type>
			</Types>
			
			После привязки при получении объектов типа [System.IO.FileInfo] производится 
			автоматический вызов данной функции с параметром IO.FileInfo и в типе [System.IO.FileInfo]
			формируется пользовательский объект с признаками типа файла исключая свойства
				FullName    - полное имя файла
				Name        - имя файла
				Extension   - расширение файла
				Length      - длина (размер) файла
		    данные свойства будут присутствовать в самом объекте System.IO.FileInfo
			
			При задании данного типа все остальные фильтры типов, если они указаны, игнорируются 
		3. Если параметр не задан, то пробуем получить зарегистрированный тип из реестра или
		   с использованием MIME
	.EXAMPLE
		Get-TypeFile -FileNameOrExt 'c:\Test_SCAN.csv'
		Получить тип конкретного файла
	.EXAMPLE
		".xlsx", ".doc", ".pav", ".pim", ".rpf", ".mid", ".mng", ".u3p" | Get-TypeFile
		получить типы заданных расширений
	.EXAMPLE
		Get-ChildItem @TestSplatPath | Get-TypeFile | ? Graphic | Select FullName
		отбираем только графические файлы
	.EXAMPLE
		Get-ChildItem @TestSplatPath | Get-TypeFile | ? {$_.Exec -and !$_.TxtPlain} | Select FullName
		отбираем не скриптовые исполняемые файлы
	.EXAMPLE
		Get-ChildItem @TestSplatPath | Get-TypeFile | ? Sig | ft Name, Length
		отбираем файлы подписи
	.EXAMPLE
		Get-ChildItem @TestSplatPath | Get-TypeFile | ? TypeIs -contains 'Unknown' | ft Extension, Length, TypeIs, Name
		отбираем файлы которые не можем идентифицировать
		или так
		Get-ChildItem @TestSplatPath | Get-TypeFile | ? Unknown | ft Extension, Length, TypeIs, Name
	.EXAMPLE
		Get-ChildItem @TestSplatPath | Get-TypeFile read | ft Extension, Length, TypeIs, Name
		в режиме фильтра отбираем файлы для чтения
	.EXAMPLE
		Get-ChildItem @TestSplatPath | Get-TypeFile word excel database | ft Extension, Length, TypeIs, Name
		в режиме фильтра отбираем файлы Word, Excel и Database
	.EXAMPLE
		Get-ChildItem @TestSplatPath | ? {$_.TypeFile.Word} | fl Extension, Length, Name, TypeIs
		в режиме встраивания в объект System.IO.FileInfo отбираем файлы Word
	.INPUTS
		[String]
		[IO.FileInfo]
	.OUTPUTS
		возвращает пользовательский объект TypeFile.Object со следующими свойствами
		[PSCustomObject]@{
			FullName    - полное имя файла
			Name        - имя файла
			Extension   - расширение файла
			Length      - длина (размер) файла
			TypeIs      - строковый массив перечислений типов к которым принадлежит файл
			TxtPlain    - признак простого текстового файла
			Word        - признак документа MS Word
			Excel       - признак документа MS Excel
			Read        - признак читаемого документа
			Graphic     - признак графического файла
			Archive     - признак архивного файла
			Video       - признак видео файла
			Audio       - признак аудио файла
			Exec        - признак исполняемого файла
			Database    - признак файла базы данных
			Crypt       - признак криптографического (возможно зашифрованного) файла
			Sign        - признак файла подписи или сертификата
			Virtual     - признак файла виртуализации
			Unknown     - признак что тип определить не удалось
		}
		Если не заданы конкретные типы или заданный тип не определен функция отработает как фильтр
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 25.04.2024
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
	

	# включаем расширенную поддержку параметров Debug, Verbose и др.
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр, можно получать по конвейеру
		[Parameter (Mandatory = $true, ValueFromPipeline = $True)]
		[Alias('FN', 'FEXT', 'FNE')]	
		[string]$FileNameOrExt

		,

		# не обязательный параметр - конкретные базовые типы для фильтрации
		# ValueFromRemainingArguments - все что не попадает в основные параметры
		# будет размещаться в массиве $Keys
		# обязательно указываем позицию 2
		[Parameter (Position=2, Mandatory = $false, ValueFromRemainingArguments)]
		[Alias('Filter')]
		$FilferKeys
	)
	
	begin {  # блок выполняется 1-н раз при старте командлета (функции)
	
		# определяем имя функции для отображения в режиме Verbose
		$MyNameIs = $MyInvocation.MyCommand.Name
	
		# определяем режим: pipeline или параметр функции?
		$PipeMode = -not $PSBoundParameters.FileNameOrExt
		
		# текстовый статус - определить тип не удалось
		$sUnknown  = 'Unknown'
		
		# признак что заданы фильтры
		[bool]$bFilterKey = $FilferKeys.Count
		
		# признак что получаем сокращенный объект 
		# (определяем по всем типам)
		$bIOFileInfo = 'IO.FileInfo' -in $FilferKeys
				
	}
	process {	# основной блок обработки для каждого файла или параметра

		$bUnknown = $false	# признак что признак не определен
		$IsFile   = $false	# признак что обрабатываем реальный файл
		
		# принудительно сбрасываем статусы для pipeline
		$TxtPlain 	= $false
		$Word 		= $false
		$Excel 		= $false
		$Read		= $false
		$Graphic 	= $false
		$Archive 	= $false
		$Video 		= $false
		$Audio 		= $false
		$Exec 		= $false
		$Database 	= $false
		$Crypt 		= $false
		$Sig	 	= $false
		$Virtual	= $false
		
		# конвейерная обработка
		if ($PipeMode) {
			# если по конвейеру передаем только расширения файлов типа '.txt'
			if ($_.ToString().StartsWith('.') -and !$_.PSIsContainer) {
				$Extension 	= $_
				$FullName 	= $_
				$Length 	= 0
				$Name		= $_
			}
			# передали нормальный объект файловой системы
			elseif (!$_.PSIsContainer) {
				$Extension 	= $_.Extension
				$FullName 	= $_.FullName
				$Length 	= $_.Length
				$Name		= $_.Name
				$IsFile		= $true
			}
		}
		# не конвейерная обработка - простой параметр функции
		else {
			
			$Extension = ([System.IO.FileInfo]$FileNameOrExt).Extension
			$FullName = $FileNameOrExt
			if ([system.io.file]::exists($FileNameOrExt)) {
				$Length = ([System.IO.FileInfo]$FileNameOrExt).Length
				$Name   = ([System.IO.FileInfo]$FileNameOrExt).Name
				$IsFile = $true
			}
			else { 
				$Length 	= 0 
				$Name   	= $FileNameOrExt
			}
		}

		# если удалось получить расширение 
		if ($Extension) {
			# формируем признаки по шаблонам РВ из модуля CommonConst версии не ниже 1.0.3
			# с учетом если в параметрах (аргументах) задан(ы) конкретный(е) тип(ы)
			if (!$bFilterKey -or $bIOFileInfo -or "TextPlain" 	-in $FilferKeys) { $TxtPlain	= ($Extension -match [TxtPlain]::Match) }
			if (!$bFilterKey -or $bIOFileInfo -or "Word" 	 	-in $FilferKeys) { $Word		= ($Extension -match [Word]::Match)		}
			if (!$bFilterKey -or $bIOFileInfo -or "Excel" 	 	-in $FilferKeys) { $Excel		= ($Extension -match [Excel]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Read" 	 	-in $FilferKeys) { $Read		= ($Extension -match [Read]::Match)		}
			if (!$bFilterKey -or $bIOFileInfo -or "Graphic"   	-in $FilferKeys) { $Graphic		= ($Extension -match [Graphic]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Archive"   	-in $FilferKeys) { $Archive		= ($Extension -match [Archive]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Video"     	-in $FilferKeys) { $Video		= ($Extension -match [Video]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Audio"     	-in $FilferKeys) { $Audio		= ($Extension -match [Audio]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Exec"      	-in $FilferKeys) { $Exec		= ($Extension -match [Exec]::Match)		}
			if (!$bFilterKey -or $bIOFileInfo -or "Database"  	-in $FilferKeys) { $Database	= ($Extension -match [Database]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Crypt"     	-in $FilferKeys) { $Crypt		= ($Extension -match [Crypt]::Match)	}
			if (!$bFilterKey -or $bIOFileInfo -or "Sig"       	-in $FilferKeys) { $Sig			= ($Extension -match [Sig]::Match)		}
			if (!$bFilterKey -or $bIOFileInfo -or "Virtual"   	-in $FilferKeys) { $Virtual		= ($Extension -match [Virtual]::Match)	}
			
			# формируем свойство текстовый массив типов
			# динамическая типизация - массив
			$TypeIs = @()
			
			If ($TxtPlain) 	{ $TypeIs += 'TxtPlain' }
			If ($Word) 		{ $TypeIs += 'Word' 	}
			If ($Excel) 	{ $TypeIs += 'Excel' 	}
			If ($Read)		{ $TypeIs += 'Read' 	}
			If ($Graphic) 	{ $TypeIs += 'Graphic' 	}
			If ($Archive) 	{ $TypeIs += 'Archive' 	}
			If ($Video) 	{ $TypeIs += 'Video' 	}
			If ($Audio) 	{ $TypeIs += 'Audio' 	}
			If ($Exec) 		{ $TypeIs += 'Exec' 	}
			If ($Database) 	{ $TypeIs += 'Database' }
			If ($Crypt) 	{ $TypeIs += 'Crypt' 	}
			If ($Sig)	 	{ $TypeIs += 'Sig' 		}
			If ($Virtual)	{ $TypeIs += 'Virtual' 	}
			
			# если определить тип по расширению не удалось
			# и не установлены фильтры на конкретные типы
			if (!$TypeIs -and (!$bFilterKey -or $bIOFileInfo) )   { 
				# пробуем получить зарегистрированный тип из реестра
				
				# если расширение зарегистрировано
				if(test-path -path "Registry::HKEY_Classes_root\$Extension" ) {
					# получаем описание расширения (иногда возвращает $null - нет описания)
					$TypeIs = ,(Get-ItemProperty "Registry::HKEY_Classes_root\$((Get-ItemProperty "Registry::HKEY_Classes_root\$Extension")."(default)")")."(default)"
				}
				
				# расширение не зарегистрировано на компьютере или в реестре нет описания 
				if (!$TypeIs) {
					# если это реальный файл
					if($IsFile) {
						# пробуем получить описание через MIME
						$TmpTypeIs = [System.Web.MimeMapping]::GetMimeMapping($FullName)
						# если по MIME не определили
						if (!$TmpTypeIs) { $TypeIs = ,($Unknown); $bUnknown = $true }
						# MIME получили - упрощаем тип
						else { 
							Write-Verbose $MyNameIs + " " + $TmpTypeIs
							if     ($TmpTypeIs.StartsWith('text'))  		{ $TypeIs = ,'TxtPlain'	}
							elseif ($TmpTypeIs.StartsWith('image')) 		{ $TypeIs = ,'Graphic' 	}
							elseif ($TmpTypeIs.StartsWith('model')) 		{ $TypeIs = ,'Graphic' 	}
							elseif ($TmpTypeIs.StartsWith('audio')) 		{ $TypeIs = ,'Audio' 	}
							elseif ($TmpTypeIs.StartsWith('video')) 		{ $TypeIs = ,'Video' 	}
							elseif ($TmpTypeIs.StartsWith('application')) 	{ $TypeIs = ,'Exec'		}
							else											{ $TypeIs = ,$TmpTypeIs }
						} 
					}
					# не файл - просто расширение
					else {
						$TypeIs = ,($Unknown)
						$bUnknown = $true
					}
				}
			}
			
			# если тип установить не удалось
			if (!$TypeIs) { $TypeIs = ,($Unknown); $bUnknown = $true}
			
			# если не заданы конкретные типы или заданный тип не определен (отработает как фильтр)
			if (!$bFilterKey -or ($FilferKeys.Count -and $TypeIs -notcontains $sUnknown) ) {
				
				# если встраиваем в [System.IO.FileInfo]
				if ($bIOFileInfo) {
					$FullName	= $null
					$Name		= $null
					$Extension	= $null
					$Length		= $null
				}
				
				# сформируем и вернем объект с признаками 
				# принадлежности к типу
				[PSCustomObject]@{

					PSTypeName  = 'TypeFile.Object'

					FullName	= $FullName
					Name		= $Name
					Extension	= $Extension
					Length		= $Length
					TypeIs		= $TypeIs
					TxtPlain	= $TxtPlain
					Word		= $Word
					Excel		= $Excel
					Read		= $Read
					Graphic		= $Graphic
					Archive		= $Archive
					Video		= $Video
					Audio		= $Audio
					Exec		= $Exec
					Database	= $Database
					Crypt		= $Crypt
					Sig			= $Sig
					Virtual		= $Virtual
					Unknown		= $bUnknown
				}
			}
		}

	}
}	





#==============================================================
function Get-CountLinesInFile {
<#
	.SYNOPSIS
		Получить количество строк в файле
	.DESCRIPTION
		Корректно работает с текстовыми файлами
		Поддерживает конвейер и режим Verbose
	.PARAMETER FullFileName
		Полное имя файла
	.EXAMPLE
		Get-CountLinesInFile 'c:\Test_SCAN.csv'
	.EXAMPLE
		Get-ChildItem k:\tmp -Recurse | Get-CountLinesInFile
	.EXAMPLE
		Get-ChildItem k:\tmp -Recurse | ? extension -match '^\.(?:txt|csv|vbs)$' | Get-CountLinesInFile
	.INPUTS
		String 
		[IO.FileInfo]
	.OUTPUTS
		System.ValueType.Integer32
		PSCustomObject Lines, FullName
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.2 от 14.01.2026
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр с поддержкой PipeLine
		[Parameter (Mandatory = $true, ValueFromPipeline=$True)]
#		[ValidateNotNullOrEmpty()]        # не ноль и не пусто      
#		[ValidateScript({ Test-Path -PathType Leaf -Path $_ })] # файл должен существовать               
		[Alias('FN')]	# альтернативное имя параметра
		# параметры (агрументы) функции
		[string]$FullFileName
		
	) 

	begin {  # один раз
		# режим pipeline?
		$PipeMode = -not $PSBoundParameters.FullFileName
	}
	process {	# для каждого файла
	
		[int]$Lines = 0
		$readfile = $null
		
		# если конвейер
		if ($PipeMode) {
			# объект не папка и файл существует и он текстового формата
			if ( !$_.PSIsContainer -and [system.io.file]::exists($_.fullname) -and (Is-PlainText $_.fullname)) {
				# запоминаем полное имя файла
				$readfile = $_.fullname
			}
		}
		# не конвейер а просто параметр функции
		else {
			# параметр задан и файл существует и он текстового формата
			if ($FullFileName -and [system.io.file]::exists($FullFileName) -and (Is-PlainText $FullFileName)) {
				# запоминаем полное имя файла
				$readfile = $FullFileName
			}
			# если параметр битый вернем -1 (невозможное кол-во строк)
			else { -1 ; Write-Verbose "Ошибка параметра в имени файла" }
		}

		# если есть файл для подсчета строк
		if ($readfile) {
			# в блоке обработки ошибок, т.к. файл может быть заблокирован
			try {
				# ReadLines потоковое чтение строк с возвращением IEnumerable<string>
				# не требует явного закрытия файла - все сделает .NET
				$Lines = [System.Linq.Enumerable]::Count([System.IO.File]::ReadLines($readfile))
				
				if ($PipeMode) {
					[PSCustomObject]@{FullName=$_.fullname; Lines=$Lines}
				}
				# если по параметру - возвращаем кол-во строк
				else { $Lines }
			}
			catch {
				Write-Verbose "Ошибка чтения файла '$readfile'"
				if ($PipeMode) { $null }
				else { -1 }
			}
		}
	}
	end { } # в завершении ни чего не делаем
}



#==============================================================
function Get-LongFileName {
<#
	.SYNOPSIS
		Конвейерный подсчет полной длины имени файла
	.DESCRIPTION
		вернуть объекты, полное имя которых превышает заданную величину
	.PARAMETER More
		не обязательный входной параметр [int] - длина полного имени файла
		более которой полное имя файла попадет в выходные данные
		если параметр не задан, устанавливается в 0 - все файлы		
	.EXAMPLE
		Get-Childitem @SplatPath | Get-LongFileName -More 260
	.EXAMPLE
		Get-ChildItem k:\tmp -Recurse | ? extension -match '^\.(?:txt|csv|vbs)$' | Get-LongFileName
	.INPUTS
		[System.IO.FileInfo]
		[Int32]
	.OUTPUTS
		[PSCustomObject]@{
			FullName 	= $FullNameNotUNC			# полное имя без учета возможного префикса
			Mode 		= $_.Mode
			Length 		= $_.Length
			Extension 	= $_.Extension
			NameLen 	= $FullNameNotUNC.Length 	# длина полного имени без учета возможного префикса
		}
		или 
		[int] - в случае параметра функции 
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 17.04.2024
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр с поддержкой PipeLine
		[Parameter (Position=0, Mandatory = $true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true)]
		[string]$FullName
		
		,
		
		[Parameter (Position=1, Mandatory = $false)]
		[int]$More
		
	)
	
	begin {

		# режим pipeline?
		$PipeMode = -not $PSBoundParameters.FullName

		# если длина не задана, вернем все файлы у кого длина пути более 0
		if(!$More) {$More = 0}
		# длина задана - возьмем абсолютное значение
		else {$More = [bigint]::Abs($More)}
		
	}
	
	process {	# для каждого файла

		if ($PipeMode) {
			
			# если текущий объект конвейера не папка
			if( !$_.PSIsContainer ) {

				# получим полное имя файла без возможных префиксов абсолютной UNC адресации
				$FullNameNotUNC = (Get-CleanPath $_.FullName)
				
				# если длина имени текущего объекта из конвейера превышает заданный параметр
				if( $FullNameNotUNC.length -gt $More ) {
					
					# формируем возвращаемый объект с заданными свойствами
					[PSCustomObject]@{
						FullName 	= $FullNameNotUNC			# полное имя без учета возможного префикса
						Mode 		= $_.Mode
						Length 		= $_.Length
						Extension 	= $_.Extension
						NameLen 	= $FullNameNotUNC.Length 	# длина полного имени без учета возможного префикса
					}
				}
			}
		}
		else { return (Get-CleanPath $FullName).length }
	}
	end { } # в завершении ни чего не делаем
	
}



#==============================================================
function ConvertTo-CliXML {
<#
	.SYNOPSIS
		Преобразование любого объекта в формат CliXML PowerShell
	.DESCRIPTION
		Любой объект преобразуется в формат CliXML
		Для преобразования используется класс [System.Management.Automation.PSSerializer]
		и его статический метод Serialize
		Ограничение - глубина вложенности объектов не должна превышать 48 уровней 
	.PARAMETER Obj
		обязательный входной параметр отличный от null	
	.EXAMPLE
		$CliXML = ConvertTo-CliXML $GlobalHashTable
	.INPUTS
		[System.Object[]]
	.OUTPUTS
		[String]
		или 
		$null - в случае пустого параметра 
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 21.06.2025
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
	
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр 
		[Parameter (Position=0, Mandatory = $true)]
		$Obj
	)
	
	if ($Obj)  { $CliXML = [System.Management.Automation.PSSerializer]::Serialize($Obj, [int32]::MaxValue) }
		
	return $CliXML
		
}


#==============================================================
function ConvertFrom-CliXML {
<#
	.SYNOPSIS
		Восстановление объекта из формат CliXML PowerShell
	.DESCRIPTION
		Для преобразования используется класс [System.Management.Automation.PSSerializer]
		и его статический метод Deserialize
	.PARAMETER CliXML
		обязательный входной параметр отличный от null 
		массив строк, содержащий данные в структуре	формата CliXML
	.EXAMPLE
		$GlobalHashTable = ConvertFrom-CliXML $CliXML
	.INPUTS
		[System.CliXML[]]
	.OUTPUTS
		[System.Object[]]
		или 
		$null - в случае не соответствия формату CliXML 
	.LINK
		Out-
		
		
		Версия: 1.0 от 18.01.2026
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
	
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр 
		[Parameter (Position=0, Mandatory = $true)]
		# не null и не empty
		[ValidateNotNullOrEmpty()]
		[String]$CliXML
	)
	
	# простая проверка на соответствие формату
	# если не соответствует - вернем $null
	# должно быть:
	# 1 строка, длиной более 60 символов и начинается с <Objs Version=
	# если не так - выходим и возвращаем $null
	if ($CliXML.count -ne 1 -or $CliXML.Length -lt 60 -or !$CliXML.StartsWith('<Objs Version=')  ) { return $null }
	
	# в блоке обработки ошибок, т.к. $CliXML все-таки может не соответствовать формату
	try {
		# если соответствует формату - сформирует объект
		$Obj = [System.Management.Automation.PSSerializer]::Deserialize($CliXML) 
	}
	# ошибка формата
	catch {
		$Obj = $null
	}	
	
	return $Obj
}


	
#==============================================================
function Get-TypeBOM {
<#
	.SYNOPSIS
		Получить из файла информацию о возможном BOM
		BOM (Byte Order Mark) - не обязательная метка порядка байт
		(от 2 до 4 байт в начале текстового файла)
	.DESCRIPTION
		Поддерживает конвейерную обработку, параметры и режим Verbose
		Может работать в режиме фильтрации
		Из файла читаются первые 4 байта и далее они проверяются по 
		сигнатурам BOM
		Определяет наличие BOM и его характеристики 
			Type	BOM		Sig		Length	Decod
			0	-		- 		-	-
			1	UTF-8		EFBBBF		3	UTF8
			2	UTF-16 LE	FFFE		2	Unicode
			3	UTF-16 BE	FEFF		2	BigEndianUnicode
			4	UTF-32 BE	0000FEFF	4	UTF32
			5	UTF-32 LE	0000FFFE	4	UTF32
			6	UTF-7 /v#	2B2F76##	4	UTF7
		Type 	- условный тип сигнатуры BOM
		BOM  	- название BOM
		Sig		- сигнатура BOM
		Length	- длина сигнатуры
		Decod	- имя статического метода класса [System.Text.Encoding]
				  для декодирования
	.PARAMETER FileName
		строка содержащая полное имя файла или объект файловой системы
		обязательный входной параметр отличный от null 
		может быть принят по конвейеру
	.PARAMETER TypesFilter
		не обязательный параметр
		при его задании функция работает в режиме фильтра
		допускается задание любого набора типов BOM от 0 до 6 
		или BOM - отбор любых файлов с BOM
	.PARAMETER Plain
		переключатель (не обязательный)
		если установлен то проверяем только простые текстовые файлы
	.EXAMPLE
		$TypeBOM = Get-TypeBOM D:\TRAINING\ФАЙЛЫ\Test.txt
		помещаем в переменную $TypeBOM объект информации по BOM
	.EXAMPLE
		'D:\TRAINING\ФАЙЛЫ\Test.txt' | Get-TypeBOM 
		передаем по конвейеру имя файла и получаем объект информации по BOM
	.EXAMPLE
		передаем по конвейеру объект файловой системы
		Get-ChildItem $TestFile | Get-TypeBOM
	.EXAMPLE
		конвейерный поиск всех файлов с BOM UTF-16 LE
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM | ? Type -eq 2
	.EXAMPLE
		конвейерный поиск файлов с BOM типа 2 и 3
		в режиме фильта
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM 2 3
	.EXAMPLE
		конвейерная фильтрация простых текстовых файлов с BOM типа 1 и 4
		в режиме фильта только типы 2 и 3
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM -Plain 1 4
	.EXAMPLE
		# получение значений отдельных свойств
		(Get-TypeBOM $FileTest).type
		(Get-TypeBOM $FileTest).BOM
		(Get-TypeBOM $FileTest).length
		(Get-TypeBOM $FileTest).decod
		или получить в переменную и смотреть там
		$InfoBOM = Get-TypeBOM $FileTest
		if ($InfoBOM.type -eq 2) { "Файл в кодировке Unicode" }
	.EXAMPLE
		конвейерный поиск всех файлов с BOM
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM | ? Type -ne 0
		или так в режиме фильтра
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM -plain BOM
	.EXAMPLE
		конвейерный поиск всех файлов без BOM
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM | ? Type -eq 0
		или так
		Get-ChildItem (JP $TrainingPath *.*) -Recurse | Get-TypeBOM -plain 0
	.INPUTS
		[String]
		[IO.FileInfo]
	.OUTPUTS
		Возвращается $null если с файлом что-то не так или
		пользовательский объект со следующими свойствами:
		[PSCustomObject]@{
			Name 		- полное имя файла
			Type		- условный тип BOM (от 0 до 5)
			BOM 		- название BOM
			Sig			- сигнатура BOM 
			Length 		- длина сигнатуры BOM
			Decod		- имя статического метода класса [System.Text.Encoding]
						  для декодирования 
		}
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 18.01.2026
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр с поддержкой PipeLine
		# полное имя файла
		[Parameter (Mandatory = $true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true)]
		[string]$FileName
		
		,
		
		# не обязательный параметр - конкретные типы BOM для фильтрации
		# ValueFromRemainingArguments - все что не попадает в основные параметры
		# будет размещаться в массиве $Keys
		# целочисленный массив фильтров
		# обязательно указываем позицию 2
		[Parameter (Position=2, Mandatory = $false, ValueFromRemainingArguments)]
		$TypesFilter
		
		,
		
		# не обязательный переключатель - смотреть только текстовые файлы
		[Parameter (Mandatory = $false)]
		[switch]$Plain
	)

	# делаем один раз
	begin {

		# режим pipeline?
		$PipeMode = -not $PSBoundParameters.FullFileName
		
		if ($TypesFilter){
			write-verbose "TypesFilterCnt:$($TypesFilter.count) TypesFilter:$($TypesFilter)"
			write-verbose "TypesFilterCntType:$($TypesFilter.gettype())"
		}
	}

	process {	# для каждого файла

		# если конвейер
		if ($PipeMode) {
			
			# подготовим переменные чтобы потом ими воспользоваться
			# для открытия и чтения файла
			
			# если в конвейер передаются строки
			if ($_.GetType().Name -eq 'String') {
				$Name = $_
				Write-Verbose "PIPE mode string `$_:$Name"
				$IsContainer = (Test-Path -Path $Name -PathType Container)
				$FilePresent = (Test-Path -Path $Name -PathType Leaf)
				if ($FilePresent) {
					# получаем расширение файла
					$FileExt = ([System.IO.FileInfo]$Name).Extension
				}
			}
			else {
				$Name = $_.fullname
				Write-Verbose "PIPE mode object `$_:$Name"
				$IsContainer = $_.PSIsContainer
				# получаем расширение файла
				$FileExt = $_.Extension
				$FilePresent = $true
			}
			
			# объект папка или файл не существует
			if ( $IsContainer -or !$FilePresent ) {
				Write-Verbose "PIPE mode Conteiner:$IsContainer Present:$FilePresent"
				return $null
			}
			
		}
		# не конвейер а просто параметр функции
		else {
			Write-Verbose "Parameter mode"
			
			# параметр задан и файл существует
			if ($FileName -and [system.io.file]::exists($FileName)) {
				# для выходного объекта
				$Name = $FileName
				$FileExt = ([System.IO.FileInfo]$Name).Extension
			}
			# если параметр битый вернем $null
			else { 
				Write-Verbose "Указанный файл не существует"
				return $null 
			}

		}

		# если проверяем любой файл (переключатель plain не установлен или $false)
		# или если установлен переключатель plain то проверяем только текстовые файлы
		if (!$plain -or ($FileExt -match "$([TxtPlain]::Match)") ) { 
			
			# откроем файл для потокового чтения
			# если файл открыт другим приложение - будет ошибка мы ее учтем
			try {
				$stream = [System.IO.File]::OpenRead($Name)
				Write-Verbose "File OpenRead Ok"
			}
			catch {
				Write-Verbose "Not open File! File is locked"
				return
			}
			
			Write-Verbose "Ready stream"
			
			# создаем буфер для 4 байт
			$bom = New-Object byte[] 4  # Читаем 4 байта для охвата разных BOM
			try {
				$bytesRead = $stream.Read($bom, 0, 4)
				Write-Verbose "Buffer Read Ok"
			}
			catch {
				$stream.Close()	# закрываем файл чтобы не блокировать его
				Write-Verbose "Error Buffer Read"
				return
			}
			
			$stream.Close()	# закрываем файл чтобы не блокировать его
		
			# если прочитали не менее 2-х байт
			if ($bytesRead -ge 2) {
				
				Write-Verbose "Read -ge 2 bytes"
				
				# UTF-8: 0xEF 0xBB 0xBF
				if ($bytesRead -ge 3 -and $bom[0] -eq 0xEF -and $bom[1] -eq 0xBB -and $bom[2] -eq 0xBF) {
					Write-Verbose "BOM: UTF-8"
					$type		= 1
					$bom 		= 'UTF-8'
					$sig		= 'EFBBBF' 
					$length 	= 3
					$decod		= 'UTF8'
				}
				# UTF-16 LE (Windows-стиль): 0xFF 0xFE
				elseif ($bom[0] -eq 0xFF -and $bom[1] -eq 0xFE) {
					Write-Verbose "BOM: UTF-16 Little-Endian"
					$type		= 2
					$bom 		= 'UTF-16 LE'
					$sig		= 'FFFE' 
					$length 	= 2
					$Decod		= 'Unicode'
				}
				# UTF-16 BE: 0xFE 0xFF
				elseif ($bom[0] -eq 0xFE -and $bom[1] -eq 0xFF) {
					Write-Verbose "BOM: UTF-16 Big-Endian"
					$type		= 3
					$bom 		= 'UTF-16 BE'
					$sig		= 'FEFF' 
					$length 	= 2
					$decod		= 'BigEndianUnicode'
				}
				# UTF-32 BE: 0x00 0x00 0xFE 0xFF
				elseif ($bytesRead -eq 4 -and $bom[0] -eq 0x00 -and $bom[1] -eq 0x00 -and $bom[2] -eq 0xFE  -and $bom[3] -eq 0xFF) {
					Write-Verbose "BOM: UTF-32 Big-Endian"
					$type		= 4
					$bom 		= 'UTF-32 BE'
					$sig		= '0000FEFF' 
					$length 	= 4
					$decod		= 'UTF32'
				}
				# UTF-32 LE: 0xFF 0xFE 0x00 0x00
				elseif ($bytesRead -eq 4 -and $bom[0] -eq 0xFF -and $bom[1] -eq 0xFE -and $bom[2] -eq 0x00 -and $bom[3] -eq 0x00) {
					Write-Verbose "BOM: UTF-32 Little-Endian (UTF32)"
					$type		= 5
					$bom 		= 'UTF-32 LE'
					$sig		= 'FFFE0000' 
					$length 	= 4
					$decod		= 'UTF32'
				}
				# UTF-7
				elseif ($bytesRead -ge 3 -and $bom[0] -eq 0x2B -and $bom[1] -eq 0x2F -and $bom[2] -eq 0x76) {
					if ($bytesRead -ge 4) {
						$type = 6
						$bom  = 'UTF-7 '
						$length = 4
						$decod	= 'UTF7'
						switch ($bom[3]) {
							0x38 { Write-Verbose "UTF-7 BOM: +/v8 (следующий символ не Base64 или кодируется как 00)"
								$bom 	+= '/v8'
								$sig	= '2B2F7638'
							}
							0x39 { Write-Verbose "UTF-7 BOM: +/v9 (кодируется как 01)" 
								$bom 	+= '/v9'
								$sig	= '2B2F7639'
							}
							0x2B { Write-Verbose "UTF-7 BOM: +/v+ (кодируется как 10)" 
								$bom 	+= '/v+'
								$sig	= '2B2F762B'
							}
							0x2F { Write-Verbose "UTF-7 BOM: +/v/ (кодируется как 11)" 
								$bom 	+= '/v/'
								$sig	= '2B2F762F'
							}
							default { Write-Verbose "UTF-7 BOM: +/v? (неизвестный четвёртый байт)" 
								$bom 	+= '/v?'
								$sig	= '2B2F76'
							}
						}
					} else {
						Write-Verbose "UTF-7 BOM: +/v (недостаточно байтов для определения четвёртого)"
						$bom 	+= '/v?'
						$sig	= '2B2F76'
					}
				} 
				else {
					Write-Verbose "BOM не обнаружен или неизвестный тип"
					$type		= 0
					$bom 		= ''
					$sig		= '' 
					$length 	= 0
					$decod		= 'Default'
				}
				
				write-verbose "TypeIs:$type"
				
				# если фильтр не задан или заданный тип соответствует списку
				# или задано все файлы с BOM
				if ( !$TypesFilter -or $type -in $TypesFilter -or 
					 ('BOM' -in $TypesFilter -and $type -gt 0)) {
					write-verbose "Type in TypesFilter:$($type -in $TypesFilter)"
					# выходной объект
					[PSCustomObject]@{
						Name 		= $Name
						Type		= $type
						BOM 		= $bom
						Sig			= $sig 
						Length 		= $length
						Decod		= $decod
					}
				}
				else { return $null }
			}
			else {
				Write-Verbose "Файл слишком короткий для BOM"
			} # $bytesRead -ge 2
		} # !Plain or match
	}	# process
	end { } # в завершении ни чего не делаем
}



#==============================================================
function Get-BytesInFile {
<#
	.SYNOPSIS
		Прочитать из файла с заданного смещения заданное количество байт
	.DESCRIPTION
		Поддерживает режим Verbose
		Если файл существует, читает с заданной позиции заданное количество байт, 
		и возвращает массив байт, иначе возвращает $null
	.PARAMETER FileName
		обязательный параметр
		строка содержащая полное имя файла или объект файловой системы
		обязательный входной параметр отличный от null 
	.PARAMETER offset
		обязательный параметр
		смещение от начала файла для чтения байт
		если задано смещение большее чем размер файла - возвращает $null
	.PARAMETER count
		обязательный параметр
		задает количество байт которые надо прочитать
	.EXAMPLE
		$bytes = Get-BytesInFile $TestFileWithBOM 0 10
		помещаем в переменную $bytes первые 10 байт из файла $TestFileWithBOM
	.EXAMPLE
		$bytes = Get-BytesInFile'D:\TRAINING\ФАЙЛЫ\Test.txt' 137 432
		помещаем в переменную $bytes 432 байта начиная с 138 позиции
	.INPUTS
		[String]
		[IO.FileInfo]
	.OUTPUTS
		Возвращается $null если с файлом или параметрами что-то не так или
		массив байт
	.LINK
		Out-TempFile
	.NOTES
		Версия: 1.0 от 18.01.2026
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>
	

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()]
	
	# описание параметров
	Param (
		# обязательный параметр
		# полное имя файла
		[Parameter (Mandatory = $true)]
		[ValidateNotNullOrEmpty()]   
		[ValidateScript( { $_.length -ge $([MinValue]::NetPathLen) } )]
		[Alias('FN')]
		[string]$FileName
		
		,
		
		# смещение с которого начинаем чтение
		[Parameter (Mandatory = $true)]
		[ValidateScript( { $_ -ge 0 -and $_ -le [int]::MaxValue } )] 
		[int]$offset

		, 

		# количество читаемые байт
		[Parameter (Mandatory = $true)]
		[ValidateScript( { $_ -ge 0 -and $_ -le [int]::MaxValue } )] 
		[int]$count	
	)

	# если файла нет - выходим
	if( ![system.io.file]::exists($FileName) ) {
		write-verbose "Файл '$FileName' отсутствует"
		return $null
	}
	else {
		try {
			# если версия PS 5 и более
			if($host.Version.Major -ge 5){
				# ::New - это конструктор класса, но вызывается как статический метод
				# открываем существующий файл (::Open) на чтение (::Read)
				# с разрешением другим читать данный файл пока мы его используем
				$stream = [System.IO.FileStream]::New($FileName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
			}
			else {
			# надо использовать New-Object 
				$stream = New-Object IO.FileStream($FileName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
			}
		}
		# если открыть не смогли - выходим
		catch {
			write-verbose "Не смогли открыть файл '$FileName'"
			return $null
		}

		# берем абсолютное значение
		$count 	= [bigint]::Abs($count)
		$offset = [bigint]::Abs($offset)
		
		# если размер файла больше чем смещение
		if($stream.Length -gt $offset){
			# устанавливаем заданное смещение
			$stream.Seek($offset, [System.IO.SeekOrigin]::Begin) | Out-Null
			# выделяем буфер для чтения
			$buffer = New-Object byte[] $count
			# читаем заданное количество байт (или меньше)
			$bytesRead = $stream.Read($buffer, 0, $count)
			# формируем возвращаемое значение
			$RetVal = $buffer[0..($bytesRead-1)]
		}
		else { write-verbose "Смещение выходит за размеры файла" }
		
		# закрываем файл
		$stream.Dispose()
		
		# возвращаем значение
		return $RetVal
	}
}












	