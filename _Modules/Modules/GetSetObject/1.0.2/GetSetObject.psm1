# ---------------------------------------------------------
# не экспортируемая функция (доступна только в данном модуле) - script:
# формируем по имени вызывающей функции имя файла для сохранения 
# глобальной хэш таблицы чтобы не было пересечений по объектам
# т.е. для каждого вызывающего будет формироваться своя, ранее
# сформированная глобальная хеш таблица со своими элементами
# $pCaller - имя вызывающей функции/командлета
function script:m_fnCreate-CliXmlName( $pCaller ){
		
	# возвращаем сформированное имя файла
	return (Join-Path (Get-Location) ($pCaller + '.CliXML'))
}	


# ---------------------------------------------------------
# не экспортируемая функция (доступна только в данном модуле)
# если хэш таблица не существует, создаем пустую ХТ
# а при наличии ранее сохраненных данных в файле, 
# восстанавливаем хэш таблицу
# $pCaller - имя вызывающей функции/командлета
function script:m_sbGet-SavedHashTable( $pCaller ) {

	# проверяем и при отсутствии создаем глобальную хеш таблицу GV_GlobalHashBox
	if( !(Test-Path Variable:global:GV_GlobalHashBox) ) { 
		$global:GV_GlobalHashBox = @{} 
	}
	
	# формируем имя файла для хэш таблицы
	$CLI = m_fnCreate-CliXmlName($pCaller)

	# если файл есть - восстановим хэш таблицу
	if ([system.io.file]::exists($CLI)) {
		$global:GV_GlobalHashBox = Import-Clixml -Path $CLI
	}
}


# ---------------------------------------------------------
# не экспортируемая функция (доступна только в данном модуле)
# сохраняем хэш таблицу в файле в формате CliXML
# $pCaller - имя вызывающей функции/командлета
function script:m_sbSave-HashTable( $pCaller ) {

	$CLI = m_fnCreate-CliXmlName($pCaller)
	Export-Clixml -Path $CLI -InputObject $global:GV_GlobalHashBox 
}




# =========================================================
function To-Box{
<# 
	.SYNOPSIS
		Создает значение в глобальной хеш таблице
		и сохраняет ее в именованном файле сериализации формата Clixml
	.DESCRIPTION
		Если глобальная хеш таблица не существует, она создается и там сохраняется любой объек
		индексом (ключом) таблицы выступает имя под которым мы сохраняем объект
		Псевдокод: GlobalHashTable.SaveObjectName = SaveObjectValue
		Может применяться внутри командлетов для создания псевдо статических переменных
		или передачи внешних параметров, которые можно изменить, т.к. хеш таблицы в виде параметров (аргументов)
		всегда передаются по ссылке ([ref])
		Данные хеш таблицы сохраняются во внешнем файле с привязкой к вызываемому объекту (функции/командлету)
		поэтому, элементы (ключ-скалярное значение объекта) хеш таблицы сохраняются даже между сеансами работы
	.PARAMETER BoxName
		Имя, под которым сохраняем объекта
	.PARAMETER ValueObject
		Любой объект который сохраняем
	.EXAMPLE
		To-Box "TotalFileCount" $TotalFileCount 
		в глобальной таблице под индексом (ключем) "TotalFileCount" сохранится значение переменной $TotalFileCount
	.EXAMPLE
		$MyVar = "test"
		To-Box "MyVar" $MyVar 
		...
		$MyVar = ...
		...
	.INPUTS
		SystemObject
		System.String
	.OUTPUTS
		None
	.NOTES
		Версия: 1.0 от 28.06.2019
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
		[ValidateScript({ $_.length -ge 1 })]               
		[Alias('name')]
		[string]$BoxName		# имя под которым сохраняем
		
		,
		
		# обязательный параметр
		[Parameter (Mandatory = $true, Position=1)]
		[Alias('value')]
		$ValueObject	# значение объекта, которое сохраняем
	
	)
	
	# определяем имя вызывающей функции/командлета
	$CallerCnt = (Get-PSCallStack).count
	$Caller = (Get-PSCallStack)[$CallerCnt-2].FunctionName


	# создаем новую или восстанавливаем ранее сохраненную хэш таблицу
	m_sbGet-SavedHashTable($Caller)

	# формируем значение объекта в таблице по заданному ключу
	$global:GV_GlobalHashBox.$BoxName = $ValueObject
	
	# сохраняем хэш таблицу в файле
	m_sbSave-HashTable($Caller)

}



################################################################
################################################################
################################################################
function In-Box{
<# 
	.SYNOPSIS
		Возвращает объект из глобальной хеш таблицы
	.DESCRIPTION
		Если глобальная хеш таблица не существует, она создается
		Если ранее что-то сохранялось, то данные восстанавливаются из внешнего
		файла, который привязан к вызывающему объекту
		Индексом (ключом) таблицы выступает имя под которым мы получаем объект
		Псевдокод: SavedObjectValue = GlobalHashTable.SavedObjectName
		Может применяться внутри командлетов для создания псевдо статических переменных
		или передачи внешних параметров
		Элементы (ключ-скалярное значение объекта) хеш таблицы сохраняются даже между сеансами работы
		Если значение отсутствует будет возвращено значение по умолчанию, если оно задано
	.PARAMETER BoxName
		Имя, под которым сохраняли объект
	.PARAMETER DefaultValue
		Не обязательный параметр
		Значение которое будет возвращено в случае отсутствия данных 
	.EXAMPLE
		$TotalFileCount = In-Box "TotalFileCount"
		из глобальной таблицы возвращается значение по ключу "TotalFileCount"
	.EXAMPLE
		$FileID = In-Box "MyFileId" 12
		из глобальной таблицы возвращается значение по ключу "MyFileId"
		если значение ранее не сохранялось, вернет значение 12
	.EXAMPLE
		function MyFunc($param1) {
			$localVar = In-Box 'localVar' "DefValue"
			...
			$localVar = ...
			...
			To-Box 'localVar' $localVar 
		}
		"статическая" переменная $localVar - сохраняет свое значение между вызовами функции
	.INPUTS
		System.String
	.OUTPUTS
		System.Object
	.NOTES
		Версия: 1.0 от 28.06.2019
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
    
		# имя сохраненного объекта
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript({ $_.length -ge 1 })]               
		[Alias('name')]
		[string]$BoxName		# имя под которым сохраняли значение объекта
		
		,
		
		[Parameter (Mandatory = $false, Position=1)]
		[Alias('defval')]
		$DefaultValue		# значение по умолчанию
	)
	
	# определяем имя вызывающей функции/командлета
	$CallerCnt = (Get-PSCallStack).count
	$Caller = (Get-PSCallStack)[$CallerCnt-2].FunctionName

	# создаем новую или восстанавливаем ранее сохраненную хэш таблицу
	m_sbGet-SavedHashTable($Caller)

	# если нет заданного ключа
	if (!$global:GV_GlobalHashBox.ContainsKey($BoxName) ) {
		# формируем значение по умолчанию в таблице по заданному ключу
		$global:GV_GlobalHashBox.$BoxName = $DefaultValue
		# сохраняем хэш таблицу
		m_sbSave-HashTable($Caller) 
		# возвращаем значение по умолчанию
		return $DefaultValue
	}
	else {
		# возвращаем ранее сохраненное значение по заданному ключу
		return $global:GV_GlobalHashBox.$BoxName
	}

}


################################################################
# удалить ключ таблицы
function Reset-Box {
<# 
	.SYNOPSIS
		Удаляет ключ из глобальной хеш таблици
	.DESCRIPTION
		Если глобальная хеш таблица не существует - ни чего не делается
		иначе удаляется запись с индексом (ключем) таблицы имя под которым мы сохраняли объект
		Удаляется также и информация во внешнем файле, привязанном к вызывающему объекту
	.PARAMETER BoxName
		Имя, под которым сохраняли объект
	.PARAMETER StartsWith
		Переключатель
		Не обязательный параметр
		Работает только в паре с BoxName
		При установке удаляет ключи в глобальной таблице, чьи имена начинаются со значения,
		заданного в параметре BoxName (маска ключа)
	.PARAMETER All
		Переключатель
		Не обязательный параметр
		Работает только как отдельный параметр. Не совместим с другими
		При установке - очищает всю глобальную хеш таблицу
	.EXAMPLE
		Reset-Box "TotalFileCount"
		из глобальной таблицы удаляется значение по индексу (ключу) "TotalFileCount"
	.EXAMPLE
		Reset-Box "Total" -StartsWith
		из глобальной таблицы удаляется все записи, если имя ключа начинается с  "Total"
	.EXAMPLE
		Reset-Box -All
		из глобальной таблицы удаляется все записи
	.INPUTS
		System.String
	.OUTPUTS
		None
	.NOTES
		Версия: 1.0 от 16.07.2019
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	[CmdletBinding(DefaultParameterSetName="Only")] 

	# описание параметров
	Param (
    
		# имя сохраненного объекта
		[Parameter (Mandatory = $false, Position=0, ParameterSetName='Only')]
		[Alias('name')]
		[string]$BoxName		# имя под которым сохраняли значение
		
		,
		
		[Parameter (Mandatory = $false, ParameterSetName='Only')]
		[Alias('sw')]
		[Switch] $StartsWith
		
		,
		
		[Parameter (Mandatory = $false, ParameterSetName='All')]
		[Switch] $All
	)

	# определяем имя вызывающего
	$CallerCnt = (Get-PSCallStack).count
	$Caller = (Get-PSCallStack)[$CallerCnt-2].FunctionName

	# создаем или восстанавливаем хэш таблицу
	m_sbGet-SavedHashTable($Caller)
	
	# если чистим все
	if ($All) { $global:GV_GlobalHashBox.clear() }
	# если удаляем по маске
	elseif ($StartsWith) {
		$global:GV_GlobalHashBox.keys.clone() | % { if ($_.StartsWith($BoxName)) { $global:GV_GlobalHashBox.Remove($_) } }
	}
	# удаляем конкретный ключ
	elseif ($global:GV_GlobalHashBox.ContainsKey($BoxName)) {
		$global:GV_GlobalHashBox.Remove($BoxName)
	}
	
	# сохраняем хэш таблицу
	m_sbSave-HashTable($Caller) 
}



################################################################
################################################################
################################################################
function Get-NextNum {
<# 
	.SYNOPSIS
		Для именованных значений, возвращает номера по возрастанию
	.DESCRIPTION
		Функция возвращает номера по возрастанию, для каждого имени отдельно.
		Возможно задание для каждого имени начального стартового номера и шага приращения
		Использует командлеты To-Box и In-Box 
	.PARAMETER NameKey
		Имя, для кого получаем очередной порядковый номер
	.PARAMETER StartNum
		Не обязательный параметр
		Явно задается начальный стартовый номер для данного имени 
		При последующих вызовах без указания стартового номера, стартовый номер для данного имени будет автоматически увеличиваться
		на шаг по умолчанию - 1 или установленный шаг
		По умолчанию стартовый номер равен 0
	.PARAMETER StepNum
		Не обязательный параметр
		Явно указывается какой должен быть шаг приращения значения при следующем вызове для данного имени 
		По умолчанию шаг приращения устанавливается в 1
		При дальнейших вызовах без указания шага приращения, текущий номер для данного имени будет автоматически увеличиваться на установленное приращение 
	.PARAMETER Force
		Не обязательный параметр
		По умолчанию не установлен
		При включении, остальные параметры применяются немедленно, а не через вызов
	.EXAMPLE
		Get-NextNum "Test1"
		При первом вызове вернет 0
		
		при повторном вызове 
		PS С:\>Get-NextNum "Test1"
		вернет 1 и т.д. 
	.EXAMPLE
		Get-NextNum "Test2" -StartNum 100
		Вернет 100
		
		При повторном вызове 
		PS С:\>Get-NextNum "Test2"
		Вернет 101 и т.д. 
	.EXAMPLE
		Get-NextNum "Test3" -StartNum 100 -StepNum 5
		Вернет 100
		При повторном вызове 
		PS С:\>Get-NextNum "Test3"
		Вернет 105
		При последующем вызове 
		PS С:\>Get-NextNum "Test3"
		Вернет 110 и т.д. 
	.EXAMPLE
		Get-NextNum "Test4" -StartNum 100
		Вернет 100
		При повторном вызове 
		PS С:\>Get-NextNum "Test4"
		Вернет 101
		
		PS С:\>Get-NextNum "Test4" -StartNum 22
		Вернет 22
		При последующем вызове 
		PS С:\>Get-NextNum "Test4"
		Вернет 23
	.EXAMPLE
		Get-NextNum "Test5" -StepNum 5 -Force
		Вернет 5
		PS С:\>Get-NextNum "Test5" -StartNum 222 -StepNum 8 -Force
		Вернет 230
	.INPUTS
		System.String
		System.Int32
	.OUTPUTS
		System.Int32
	.NOTES
		Версия: 3.0 от 16.04.2020
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	# и поддержки общих параметров
	[CmdletBinding()] 

	# описание параметров
	Param (     
		# обязательный не пустой параметр
		[Parameter (Mandatory = $true, Position=0)]
		[ValidateNotNullOrEmpty()]              
		[Alias('name')]
		[String]$NameKey	# для кого определяем ID
	
		,
		
		# не обязательный начальный номер
		[Parameter (Mandatory = $false, Position=1)]
		[Alias('start')]
		[int]$StartNum		# порядковый номер сообщения
		
		,
		
		# не обязательный шаг приращения
		[Parameter (Mandatory = $false, Position=2)]
		[Alias('step')]
		[int]$StepNum		# шаг приращения
		
		,
		
		# не обязательный режим немедленного применения 
		[Parameter (Mandatory = $false, Position=3)]
		[switch] $Force
		
	)
	
	# определяем имя функции для отладочного режима Verbose
	$MyNameIs = $MyInvocation.MyCommand.Name

	# имя ключа для шага приращения
	$NameKeyStep = $NameKey + '_Step'
	
	# имя ключа для первой записи
	$NameKeyFirst = $NameKey + '_First'
	
	# возвращаемое значение
	$RetNum = 0
	
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
	
	
	
	#=================================
	#=================================

	# пробуем получить ранее сохраненное значение шага
	# если не сохраняли вернет значение по умолчанию - 0
	$StepNumOldValue = In-Box $NameKeyStep 0

	# признак что первое использование (ранее не сохраняли шаг)
	$FirstRec = $StepNumOldValue -eq 0
	
	# если ранее не сохраняли шаг установим шаг по умолчанию и сохраним его
	if ($FirstRec) {$StepNumOldValue = 1; To-Box $NameKeyStep $StepNumOldValue; To-Box $NameKeyFirst $true}

	write-verbose "$MyNameIs `$FirstRec = $FirstRec"
	write-debug   "$MyNameIs `$FirstRec = $FirstRec"
	
	# если параметром задаем шаг приращения
	if($PSBoundParameters.StepNum) {    
		
		write-verbose "$MyNameIs $PSBoundParameters.StepNum"
		
		# берем абсолютное значение
		$StepNum = [bigint]::Abs($StepNum)
		
		# если новый шаг 0 - оставим старый
		if ($StepNum -eq 0) { $StepNum = $StepNumOldValue }
		
		# если новый шаг отличается от ранее сохраненного
		if ($StepNumOldValue -ne $StepNum){
			
			# сохраняем новый шаг для последующего использования
			To-Box $NameKeyStep $StepNum
		}

		# если не надо сразу применять новый шаг, используем старый
		if (!$Force) {$StepNum = $StepNumOldValue}
	}
	# параметр шаг не задан
	else {
		# получаем ранее сохраненный шаг
		$StepNum = $StepNumOldValue
	}

	write-verbose "$MyNameIs `$StepNum = $StepNum"
	write-debug   "$MyNameIs `$StepNum = $StepNum"
	

	# если параметром задаем начальный номер 
	if($PSBoundParameters.StartNum)        
	{              
		write-verbose "$MyNameIs PSBoundParameters.StartNum"
		
		write-verbose "$MyNameIs `$StartNum = $StartNum"
		write-debug   "$MyNameIs `$StartNum = $StartNum"
		# формируем возвращаемое значение для объекта
		$RetNum = [bigint]::Abs($StartNum)
		
		# сразу установим что это начальное значение
		# и в любом случае мы его вернем сразу
		$FirstRec = $true
		#
		#To-Box $NameKey $StartNum
		#To-Box $NameKeyFirst $true

	}
	# параметр стартовый номер не указан
	else {
		# получаем ранее сохраненное значение и  если его 
		# не сохраняли - получим значение по умолчанию - 0
		$RetNum = In-Box $NameKey 0
		#$FirstRec = In-Box $NameKeyFirst $false
		#To-Box $NameKeyFirst $false
	}
			
	write-verbose "$MyNameIs `$RetNum Before Step = $RetNum"
	write-debug   "$MyNameIs `$RetNum Before Step = $RetNum"

	write-verbose "$MyNameIs `$Force = $Force"
	write-verbose "$MyNameIs !`$FirstRec = $(!$FirstRec)"
	# если режим применения или не первая запись - добавим шаг
	if ($Force -or !$FirstRec) { 
		$RetNum += $StepNum 
		write-verbose "$MyNameIs `$RetNum += `$StepNum = $RetNum"
		write-debug   "$MyNameIs `$RetNum += `$StepNum = $RetNum"
	}
	
	# сохраняем текущее значение для последующих вызовов
	To-Box $NameKey $RetNum
	
	# при необходимости восстановим установки общих параметров
	if ($PSBoundParameters.Verbose) {
		if($VerbosePreference -ne $OldVerbosePreference) {$VerbosePreference = $OldVerbosePreference}
	}
	
	if ($PSBoundParameters.Debug) {
		if($DebugPreference -ne $OldDebugPreference) {$DebugPreference = $OldDebugPreference}
	}
	
	write-verbose "$MyNameIs `$RetNum = $RetNum"
	write-debug   "$MyNameIs `$RetNum = $RetNum"
	# возвращаем значение
	return $RetNum
}





