Function Write-Log {
<# 
	.SYNOPSIS
		Запись сообщения в журнал
	.DESCRIPTION
		Функция производит запись сообщений в журнал с автоматическим формированием порядкового номера, типа, даты и времени записи сообщения
		Поддерживается формат TXT и CSV
		Сохранение и восстановление настроек производится с помощью функций модуля GetSetObject.psm1
	.PARAMETER LogName
		(или fname)
		Имя файла куда записываются сообщения (txt или csv формат)
		Обязательный параметр
		Необходимо задавать полное имя файла журнала  например: 'C:\LOGS\FileMaskCopyLog.txt'
		Или, например, так: 'e:\temp\TestLog.csv'
		Если путь к файлу не существует, запись не производится.
	.PARAMETER Message
		(или msg)
		Текст сообщения
		Не обязательный параметр - строка
	.PARAMETER StartLineId
		(или sln)
		Задает начальный (стартовый) номер сообщений
		Распространяется на все последующие записи
		Не обязательный параметр, числовое значение, по умолчанию - 0
	.PARAMETER Type
		(или t)
		Тип сообщения - числовое значение
		Распространяется на текущую запись
		Не обязательный параметр, по умолчанию 0
	.PARAMETER NoDate
		(или nd)
		Переключатель.
		Если установлен, то при записи сообщения в файл дата не формируется
		Распространяется на текущую запись
		Не обязательный параметр, по умолчанию - не установлен
		При использовании совместно с переключателем -Remember
		будет распространяться на все последующие записи
	.PARAMETER NoTime
		(или nt)
		Переключатель.
		Если установлен, то при записи сообщения в файл время не формируется
		Распространяется на текущую запись
		Не обязательный параметр, по умолчанию - не установлен
		При использовании совместно с переключателем -Remember
		будет распространяться на все последующие записи
	.PARAMETER NoDateTime
		(или ndt)
		Переключатель.
		Если установлен, то при записи сообщения в файл дата и время не формируются
		Распространяется на текущую запись
		Не обязательный параметр, по умолчанию - не установлен
		При использовании совместно с переключателем -Remember
		будет распространяться на все последующие записи
		Эквивалентен применению двух параметров: -NoDate -NoTime
		Взаимоисключающий одновременное использование параметров -NoDate и -NoTime
	.PARAMETER NoLineNum
		(или nln)
		Переключатель.
		Если установлен, то при записи сообщения в файл номера сообщений не формируются
		Распространяется на текущую запись
		Не обязательный параметр, по умолчанию - не установлен
		При использовании совместно с переключателем -Remember
		будет распространяться на все последующие записи
	.PARAMETER Remember
		Переключатель.
		Если задан совместно с другими переключателями, то настройки сохраняются для всех последующих записей
		и повторно их указывать не надо
	.PARAMETER Reset
		Переключатель.
		Если задан, то все настройки кроме текущего номера сообщения сбрасываются в значения по умолчанию
	.PARAMETER Force
		Переключатель.
		Применяется только совместно с Reset
		Если задан, то сбрасывается и текущая нумерация строк
	.PARAMETER Clear
		Переключатель.
		Если задан, то журнал очищается
	.EXAMPLE
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1"
		В файле добавятся запись типа:
		1		0		20.05.2019	10:25:36	Текст сообщения 1
	.EXAMPLE
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1" -StartLineId 100
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 2"
		В файле добавятся записи типа:
		100		0		20.05.2019	10:25:36	Текст сообщения 1
		101		0		20.05.2019	10:25:37	Текст сообщения 2
	.EXAMPLE
		PS C:\>Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1" -NoDate -Type 10
		PS C:\>Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 2" -NoTime -Type 20
		В файле добавятся записи типа:
		1		10					10:25:36 	Текст сообщения 1
		2		20		20.05.2019 				Текст сообщения 2
	.EXAMPLE
		PS C:\>Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1" -NoDateTime
		PS C:\>Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 2" 
		В файле добавятся записи типа:
		1		0								Текст сообщения 1
		2		0		20.05.2019	10:25:37	Текст сообщения 2
	.EXAMPLE
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1" -NoDateTime -NoLineNum
		В файле добавятся записи типа:
				0							Текст сообщения 1
				0							Текст сообщения 2
	.EXAMPLE
		PS C:\>Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1" -NoDate -remember
		PS C:\>Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 2"
		В файле добавятся записи типа:
		1		0					10:25:36 	Текст сообщения 1
		2		0					10:25:38 	Текст сообщения 2
	.EXAMPLE
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" -reset -force -clear
		Настройки сбрасываются в значения по умолчанию, журнал очищается
	.EXAMPLE
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 1" -StartLineId 100 -NoDate -remember
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 2"
		В файле добавятся записи типа:
		100		0					10:25:36	Текст сообщения 1
		101		0					10:25:37	Текст сообщения 2

		Write-Log "C:\LOGS\FileMaskCopyLog.txt" -reset	# сбросится настройка не формировать дату
		
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 3" 
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 4"
		В файле добавятся записи типа:
		102		0		20.05.2019	10:28:36	Текст сообщения 3
		103		0		20.05.2019	10:28:37	Текст сообщения 4
		
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" -reset -force # сбросится и нумерация
		
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 5" 
		Write-Log "C:\LOGS\FileMaskCopyLog.txt" "Текст сообщения 6"
		В файле добавятся записи типа:
		0		0		20.05.2019	10:30:36	Текст сообщения 5
		1		0		20.05.2019	10:30:37	Текст сообщения 6
	.INPUTS
		System.String
		System.Int32
		System.Hashtable
	.OUTPUTS
		None
	.NOTES
		Версия: 1.0.2 от 11.04.2020
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding(DefaultParameterSetName="All")] 
	#[CmdletBinding()] 

	# описание параметров
	Param (     
		###################
		[Parameter (Mandatory = $true,Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript({ Test-Path -Path ([System.IO.Path]::GetDirectoryName($_ )) })]               
		[Alias('fname')]
		[string]$LogName,	# имя файла куда пишем сообщения - обязательный первый параметр
		
		###################
		[Parameter (Mandatory = $false,Position=1)]
		[Alias('msg')]
		[string]$Message,	# текст сообщения -  не обязательный второй параметр
		
		
		###################
		[Parameter (
					Mandatory = $false
#				   ,ParameterSetName='PStartLineId'
		)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript({ ($_ -gt 0) })]               
		[Alias('sln')]
		[int]$StartLineNum		# порядковый номер сообщения
		
		,
		
		[Parameter (
					Mandatory = $false
#				   ,ParameterSetName='PStartLineId'
		)]
		[ValidateNotNullOrEmpty()]              
#		[ValidateScript({ ($_ -gt 0) })]               
		[Alias('t')]
		[int]$Type		# порядковый номер сообщения
		
		,
		
		[Parameter (
					Mandatory = $false
				   ,ParameterSetName='One'
		)]
		[Alias('nt')]
		[Switch]$NoTime # переключатель отменяющий формирование времени
		
		,

		[Parameter (
					Mandatory = $false
				   ,ParameterSetName='One'
		)]
		[Alias('nd')]
		[Switch]$NoDate # переключатель отменяющий формирование даты
		
		,
				
		[Parameter (
					Mandatory = $false
				   ,ParameterSetName='Two'
		)]
		[Alias('ndt')]
		[Switch]$NoDateTime # переключатель отменяющий формирование даты и времени
		
		,
		
		[Parameter (
					Mandatory = $false
#				   ,ParameterSetName='One'
		)]
		[Alias('nln')]
		[Switch]$NoLineNum # переключатель отменяющий формирование номеров строк
		
		,
		
		[Parameter (
					Mandatory = $false
		)]
		[Alias('rem', 'save')]
		[Switch]$Remember # переключатель сохраняет настройки для последующего использования
		
		,
		
		[Parameter (
					Mandatory = $false
				   ,ParameterSetName='res'
		)]
		[Alias('res')]
		[Switch]$Reset # переключатель отменяющий все установки 
		
		,
		
		[Parameter (Mandatory = $false
				   ,ParameterSetName='res'
		)]
		[Switch]$Force # применяется вместе с Reset для сбрасывания текущего номера записи 
		
		,
		
		[Parameter (
					Mandatory = $false
		)]
		[Alias('clr')]
		[Switch]$Clear # переключатель удаляющий все записи 
		
	)

	# определяем имя функции
	$MyNameIs = $MyInvocation.MyCommand.Name

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

	
	write-verbose "$MyNameIs `$LogName = $LogName"
	write-verbose "$MyNameIs `$Message = $Message"
	
	$MsgNum = 0
	$MsgStr = $null
	
	$YesMsg = !(Check-BlankValue $Message)
	
	
	
	# формируем имена ключей ----------------------------------------
	$CurIdKey 		= $LogName + '_CurId'
	$NoLineNumKey  	= $LogName + '_NoLineNum'
	$NoDateTimeKey 	= $LogName + '_NoDateTime'
	$NoDateKey     	= $LogName + '_NoDate'
	$NoTimeKey     	= $LogName + '_NoTime'
	
	# файл CSV??? ---------------------------------------------------
	$Csv = ([System.IO.FileInfo]$LogName).Extension.StartsWith('.csv')

	# строка форматирования для TXT 
	$FrmStr = '{0,-10} {1,-3} {2,-10} {3,-8} {4}'
	
	# формируем заголовки
	if ($csv) {
		$Hdr = 'Id;Type;Date;Time;Message'
	}
	else {
		$Hdr 	= $FrmStr -f 'Id', 'Type', 'Date', 'Time', 'Message'
	}


	#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	# если отладка - остановимся
	if ($IsDebug) { 
		$Host.EnterNestedPrompt() 
	}


	
	# ---------------------------------------------------------------
	# сбрасываем все в исходные настройки
	if($Reset) {
		$NoLineNum  = $false
		$NoDateTime = $false
		$NoDate     = $false
		$NoTime     = $false
		
		# запомним текущий номер сообщения
		$SavedCurId = In-Box $CurIdKey 0

		# удаляем из хэш таблицы все по данному ключу
		Reset-Box $LogName -StartsWith 

		# если не надо сбрасывать текущий номер сообщения,
		# восстановим его, сохранив его значение в ХТ
		if (!$Force) { To-Box $CurIdKey $SavedCurId }

	}
	
	# ---------------------------------------------------------------
	# запоминаем настройки
	if($Remember) {
		
		if($PSBoundParameters.StartLineNum) {To-Box $CurIdKey 		$StartLineNum}
		
		if($PSBoundParameters.NoLineNum) 	{To-Box $NoLineNumKey 	$NoLineNum 	}
		if($PSBoundParameters.NoDateTime) 	{To-Box $NoDateTimeKey 	$NoDateTime }
		if($PSBoundParameters.NoDate) 		{To-Box $NoDateKey 		$NoDate		}
		if($PSBoundParameters.NoTime) 		{To-Box $NoTimeKey 		$NoTime 	}
	}
	
	# ---------------------------------------------------------------
	# очищаем журнал
	if($Clear) {
		#если файл был - удалим его
		if(([System.IO.FileInfo]$LogName).Exists) { Remove-item $LogName }
		# создадим пустой файл + подавляем вывод
		New-Item -path $LogName -ItemType File | Out-Null
		
		# записываем заголовок
		Set-Content -Path $LogName -Value $Hdr 
	}
	
	# ---------------------------------------------------------------
	# если конкретные переключатели не установлены, восстановим их ХТ
	if (!$PSBoundParameters.NoLineNum)	{ $NoLineNum 	= In-Box $NoLineNumKey 	$false	}
	if (!$PSBoundParameters.NoDateTime)	{ $NoDateTime	= In-Box $NoDateTimeKey $false	}
	if (!$PSBoundParameters.NoDate)		{ $NoDate 		= In-Box $NoDateKey		$false	}
	if (!$PSBoundParameters.NoTime)		{ $NoTime 		= In-Box $NoTimeKey		$false	}
	
	
	# пробуем сформировать номер/индекс сообщения для журнала
	# если задано значение стартового номера
	if($PSBoundParameters.StartLineNum)          
	{              
		write-verbose "$MyNameIs Set -StartLineNum"
		# формируем индекс сообщения							  -Force:$YesMsg
		#$MsgNum = (Get-NextNum $CurIdKey -StartNum $StartLineNum  -verbose:$IsVerbose)
		$MsgNum = $StartLineNum
		To-Box $CurIdKey $StartLineNum
		write-Verbose "$MyNameIs StartNum MsgNum = $MsgNum"
	}  
	# стартовый номер не задан
	else {
		# если номер все же нужен и есть само сообщение
		if(!$NoLineNum -and $YesMsg){
			# пробуем получить очередное значение
			$MsgNum = (Get-NextNum $CurIdKey  -verbose:$IsVerbose)
			write-Verbose "$MyNameIs ++MsgNum = $MsgNum"
		}
	}

	# если нет сообщения - выходим
	if( !$YesMsg ) { return }

		
	# обрабатываем переключатели дат
	if($NoDateTime) {
		$Date = $null
		$Time = $null
	}
	else {
		
		if(!$NoTime -or !$NoDate){ $DateTime = Get-Date }
		
		if(!$NoTime){ 
			# используем строку где дата и не берем время 
			$Time = '{0:HH:mm:ss}' -f $DateTime
		} 
		if(!$NoDate){ 
			# берем только время и пробел (если задан -NoTime) 
			$Date = '{0:dd.MM.yyyy}' -f $DateTime
		} 
	}
	
	
	# формируем текст сообщения -------------------------------------
	
	if ($csv) {
		$MsgStr = [String]::Join(';',$MsgNum, $Type, $Date, $Time, $Message)
	}
	else {
		$MsgStr = $FrmStr -f $MsgNum, $Type, $Date, $Time, $Message
	}
	
	# файл пустой - запишем заголовок
	if ((Get-Item $LogName).Length -eq 0) {
		Set-Content -Path $LogName -Value $Hdr 
	}
	
	# добавим запись в журнал
	Add-Content -Path $LogName -Value $MsgStr
	
	Write-Verbose "$MyNameIs Message save to Log file"
	
	# при необходимости восстановим установки общих параметров
	if ($PSBoundParameters.Verbose) {
		if($VerbosePreference -ne $OldVerbosePreference) {$VerbosePreference = $OldVerbosePreference}
	}
	
	if ($PSBoundParameters.Debug) {
		if($DebugPreference -ne $OldDebugPreference) {$DebugPreference = $OldDebugPreference}
	}
	
}



################################################################
################################################################
function ShowPartial-Log {
<# 
	.SYNOPSIS
		Частично выводит информацию из журнала
	.DESCRIPTION
		Функция выводит либо всю информацию или заголовок и окончаниефайла
		Примечание:
			1. реализована поддержка общих параметров командлетов -Verbose и -Debug
	.PARAMETER FileName
		Имя файла
	.PARAMETER MaxLineShow
		Если количество строк меньше данного значения выводятся все строки
	.PARAMETER StartLineShow
		Если количество строк больше MaxLineShow, то выводятся сначала первые StartLineShow строки
	.PARAMETER EndLineShow
		Если количество строк больше MaxLineShow, то выводятся последние EndLineShow строки
	.EXAMPLE
		PS C:\>ShowPartial-Log $LogFileName
	.EXAMPLE
		PS C:\>ShowPartial-Log $LogFileName 30 8 20
	.INPUTS
		System.String
		System.Int32
	.OUTPUTS
		None
	.NOTES
		Версия: 1.2 от 11.04.2020
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>	

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
	
#		[Parameter(Mandatory = $true)]
		[Parameter(Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript({ Test-Path -Path $_ })]               
		[Alias('FN')]
		[String]$FileName,
		
#		[Parameter(Mandatory = $false)]
		[Parameter(Position=1)]
		[Alias('ML', 'AllLine', 'AL')]
		[int]$MaxLineShow = 40,
		
#		[Parameter(Mandatory = $false)]
		[Parameter(Position=2)]
		[Alias('SL', 'FirstLine', 'FL')]
		[int]$StartLineShow = 10,
		
#		[Parameter(Mandatory = $false)]
		[Parameter(Position=3)]
		[Alias('EL', 'LastLine', 'LL')]
		[int]$EndLineShow = 30
	)

	# определяем имя функции
	$MyNameIs = $MyInvocation.MyCommand.Name
	
	# получаем содержимое файла в виде строк
	$LogLines = (Get-Content $FileName)
	
	# верификация параметров
	# <= 0
	if($MaxLineShow -le 0){$MaxLineShow = $LogLines.length}
	
	# $StartLineShow >= $MaxLineShow or $MaxLineShow <= 0
	if(($StartLineShow -ge $MaxLineShow) -or ($MaxLineShow -le 0)){$StartLineShow = $MaxLineShow}
	
	# $EndLineShow <= $MaxLineShow
	if(($EndLineShow -ge $MaxLineShow) -or ($EndLineShow -le 0)){$EndLineShow = $MaxLineShow - $StartLineShow}
	
	Write-Verbose "$MyNameIs `$LogLines.length = $($LogLines.length)"
	Write-Verbose "$MyNameIs `$MaxLineShow 	= $MaxLineShow"
	Write-Verbose "$MyNameIs `$StartLineShow 	= $StartLineShow"
	Write-Verbose "$MyNameIs `$EndLineShow 	= $EndLineShow"
	
	# выводим содержимое файла или целиком или порциями начала и окончания
	
	# если строк меньше 
	if ($LogLines.length -lt $MaxLineShow) {
		# все отображаем
		$LogLines
	}
	else {
		# первые (заголовок)
		$LogLines[0..$StartLineShow]
		write-host "..."
		# последние 
		$LogLines[-$EndLineShow..-1]
	}
}




################################################################
################################################################
function Remove-Log {
<# 
	.SYNOPSIS
		Удаляет журнал
	.DESCRIPTION
		Физически удаляет и все настройки по нему
	.PARAMETER FileName
		Имя файла
	.EXAMPLE
		PS C:\>Remove-Log $LogFileName
	.INPUTS
		System.String
	.OUTPUTS
		None
	.NOTES
		Версия: 1.0 от 17.07.2019
		Разработчик: Popov A.V. email: popov-av@mail.ru
#>	

	# расширенная функция
	# обеспечение проверки корректности параметров
	[CmdletBinding()] 

	# описание параметров
	Param (
	
		[Parameter(Mandatory = $true)]
		[Parameter(Position=0)]
		[ValidateNotNullOrEmpty()]              
		[ValidateScript({ Test-Path -Path $_ })]               
		[Alias('FN')]
		[String]$LogFileName
	)

	if(Test-Path $LogFileName) 	{ Remove-Item $LogFileName }
	
	Reset-Box  $LogFileName -StartsWith

}
