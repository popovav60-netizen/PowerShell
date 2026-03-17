<# 
	.SYNOPSIS
		Контроль длины имени файла
	.DESCRIPTION
		Командлет позволяет найти файлы, полный путь которых превышают заданную величину
		Информация о процессе сканировании выводятся в консоль
		В случае нахождения файлов, превышающих заданную величину, формируется список 
		в виде CSV файла во временной директории пользователя, который по завершению работы
		командлета загружается как лист в MS Excel для просмотра
		В процессе сканирования производится мапирование заданного длинного пути в короткое в виде 
		точки соединения, нового сетевого диска или символической ссылки.
	.PARAMETER PathCheck
		(Или pc) Задает начальную папку для сканирования файлов, включая подпапки
		Заданный путь позиционируется как начальный (базовый) от которого начинается расчет длины имени файла
		Обязательный первый параметр командлета
	.PARAMETER MaxLen
		(Или ml) Максимально допустимая длинна
		Не обязательный параметр. По умолчанию 200 символов
		Если параметр не задан, то используется ранее указанный или значение по умолчанию
		Без указания имени параметра - обязательное расположение вторым параметром
	.PARAMETER Help
		Переключатель
		Вывод информации по командлету
		Используется отдельно от основных параметров
	.EXAMPLE
		.\CheckPathLen21.ps1 -PathCheck '\\10.85.152.74\BUFER\L\l4i26bi1' -MaxLen 180
		Имена параметров -PathCheck и -MaxLen можно не указывать
		Описание:
		Проверяем имена всех файлов включая подпапки с сетевого ресурса \\10.85.152.74\BUFER\L\l4i26bi1, начиная с папки 'l4i26bi1', длинна пути которых превышает 180 символов
	.EXAMPLE
		.\CreateLScan21.ps1 '\\10.85.152.74\BUFER\L\l4i26bi2'
		Не первый запуск командлета - можно не указывать максимальную длину (будет использоваться значение указанное при первом запуске или значение по умолчанию)
		Описание:
		Имя параметра -PathCheck не указано
		Проверяем имена всех файлов включая подпапки с сетевого ресурса \\10.85.152.74\BUFER\L\l4i26bi2, длинна пути которых превышает 200 символов
	.EXAMPLE
		.\CreateLScan21.ps1 'D:\PROJECT\EXCEL\'
		Проверяем имена всех файлов включая подпапки, длинна пути которых превышает 200 символов
	.INPUTS
		System.String
	.OUTPUTS
		Список файлов
	.NOTES
		Разработчик: Popov A.V. email: pav3@cbr.ru	popov-av@mail.ru

		Используются модули:
			CommonConst.psm1
			CommonFn.psm1
			GetRegValue.psm1
			MapUnMap.psm1
			
		Версия: 2.1 от 09.08.2021
			Реализован алгоритм без конвейерной обработки подсчета количества найденных элементов 
		Версия: 2.0 от 20.07.2021
			Изменен алгоритм мапирования путей. При отсутствии у пользователя прав на создание символической ссылки,
			создается: для локального пути - точка соединения, для сетевого адреса - новое дисковое устройство
			Все функции мапирования и константы вынесены в отдельный модуль MapUnMapPath.psm1
			Реализована прямая загрузка статических свойств модуля CommonConst.psm1
		Версия: 1.4 от 12.07.2021
			Добавлена функция префиксного преобразования имени базового пути к абсолютному
			Изменен параметр сканирования базового пути для получения имен превышающих 260 символов
		Версия: 1.3 от 16.06.2021
			Изменен алгоритм определения создания символической ссылки
			В буфер обмена добавлена команда удаления информационного файла
		Версия: 1.2 от 11.06.2021
			При проверке от корня диска - символические ссылки не создаются
		Версия: 1.1 от 10.06.2021
			При проверке папок в корне диска - символические ссылки не создаются
	.LINK
		Out-TempFile
#>

###################################################
###################################################
Using Module CommonConst 

###################################################
# расширенная функциональность по параметрам
# для исключения не совместимых параметров
# и для поддержки -Verbose и -Debug
[CmdletBinding(DefaultParameterSetName="Run")]



###################################################
# параметры скрипта
Param (

	# где ищем файлы (не обязательный параметр)
    [Parameter (
		Mandatory = $false, 
		Position=0, 
		HelpMessage='Путь, начиная с которого начнется проверка, например: \\10.85.152.74\bufer\L\l2f252a1',
		ParameterSetName='Run')]
#	[ValidateNotNullOrEmpty()]    
#	[ValidateScript({ Test-Path -PathType Container -Path $_ })]               
	[Alias('PC')]               
	# Имя стартовой папки
	[string]$PathCheck #= (Get-Location)
	
	,
	
	# Максимально допустимая длинна
    [Parameter (
		Mandatory = $false, 
		Position=1, 
		HelpMessage='Максимально допустимая длина, например: 190',
		ParameterSetName='Run')]
	[Alias('ML')]               
    [int]$MaxLen	
	
	,
	
	# получение справки по командлету
    [Parameter (Mandatory = $false, ParameterSetName='Help')]
	[Switch] $Help
	
)


#################################################
#################################################
# ОСНОВНОЕ ТЕЛО КОМАНДЛЕТА
#################################################

#################################################
# ОПРЕДЕЛЯЕМ КОНСТАНТЫ КОМАНДЛЕТА
Set-Variable -Name ComandletName 	-Value "CheckPathLen v. 2.1" 					-Option Constant -Scope Script -Visibility Private
Set-Variable -Name DefLen 			-Value 200 										-Option Constant -Scope Script -Visibility Private
Set-Variable -Name RegKey 			-Value "HKCU:\Software\PowerShell\CheckPathLen" -Option Constant -Scope Script -Visibility Private

Set-Variable -Name ModuleConst 		-Value "CommonConst" 							-Option Constant -Scope Script -Visibility Private


	#------------------------------------------------
	# чистим консоль
	cls

	#------------------------------------------------
	# переход на новую строку в консоле
	$NewLine = "`r`n" 
	
	#------------------------------------------------
	#------------------------------------------------
	# информация по этому командлету ----------v----------v-------v
	$CmdProp = (Get-ItemProperty -Path ($MyInvocation.MyCommand.Name))
	$CmdletFullName 	= $CmdProp.FullName
	$CmdletLenght 		= $CmdProp.Length
	$CmdletLastWrite 	= '{0:dd.MM.yyyy hh:mm:ss}' -f $CmdProp.LastWriteTimeUtc
	$CmdletHash   		= '{0:X}' -f (Get-Content -Path $CmdletFullName -raw).GetHashCode()

	$HeadingLen = 67

	$NewLine
	
	Write-host "".PadLeft($HeadingLen,'=') -ForegroundColor Yellow
	Write-host $(Aling-String $ComandletName -MaxLen $HeadingLen -Center) -ForegroundColor Yellow
	Write-host $(Aling-String "ГИБР УАПИПИД Попов А.В. pav3@cbr.ru вн.7-83-18" -MaxLen $HeadingLen -Center)	
	Write-Host "Hash: $CmdletHash `tLenght: $CmdletLenght `tLastWrite(UTC): $CmdletLastWrite" -ForegroundColor Yellow

	Write-host "".PadLeft($HeadingLen,'=') -ForegroundColor Yellow
	
	$NewLine
	

	#------------------------------------------------
	# если запросили справку по командлету
	# (.\CreateLScan.ps1 -Help)
	# выводим информацию и выходим
	if ($Help) {
		# Вызов (просмотр) полной справки по командлету
		Get-Help $CmdletFullName -full
		
		# завершаем работу командлета
		RETURN
	}


	#------------------------------------------------
	# общие переключатели
	$IsVerbose = $false
	# если задан параметр вывода на экран расширенной информации общего хода выполнения скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Verbose) {
		# сохраняем значения общих настроек
		$OldVerbosePreference = $VerbosePreference
		$VerbosePreference = "Continue"
		$IsVerbose = $true
	}

	$IsDebug = $false
	# если задан параметр детальной отладочной информации и возможно переключение в пошаговое исполнение скрипта
	# установим режим продолжения выполнения
	if ($PSBoundParameters.Debug) {
		# сохраняем значения общих настроек
		$OldDebugPreference = $DebugPreference
		$DebugPreference = "Continue"
		$IsDebug = $true
	}
	
	
	#################################################
	# настройки командлета
	if (Get-Module -ListAvailable -Name $ModuleConst) {
		Write-Host "Статические свойства модуля '$ModuleConst' получены" -ForegroundColor Green
		$NewLine
	}
	
	
	#################################################
	# если явно не задали пути сканирования и длину
	# сформируем их для локального и другого варианта
	
	#------------------------------------------------
	# ДОПУСТИМАЯ ДЛИНА 
	# если не задана
	if (Check-BlankValue $MaxLen) {
		# если не сохраняли - вернем значение по умолчанию -----v
		[int]$MaxLen = Get-RegValue $RegKey 'MaxLen'        $DefLen.ToString()
	}
	else {
		# если меньше 6 или больше 1000 - используем по умолчанию
		if ($MaxLen -lt 6 -or $MaxLen -gt 1000) {
			$MaxLen = $DefLen
		}
		else {
			# все в порядке - сохраняем в реестре
			Set-RegValue $RegKey 'MaxLen' $MaxLen.ToString()
		}
	}
	
	#------------------------------------------------
	# ПОЛНЫЙ ПУТЬ ДЛЯ СКАНИРОВАНИЯ
	# путь не указан
	if (Check-BlankValue $PathCheck) {
		if ($env:COMPUTERNAME -eq "MAINPC") {
			$PathCheck = Get-RegValue $RegKey 'PathCheck' 'D:\PAPA\PROJECT\EXCEL\TRAINING'
		}
		else {
			Write-Host "Не указан путь для сканирования" -ForegroundColor Red
			Write-Host "Запустите командлет с параметрами или для получения подсказки -Help"
			$NewLine
			RETURN
		}
	}
	# путь указан
	else {
		
		# делаем "чистый" путь без префикса
		$PathCheck = Get-CleanPath $PathCheck
		
		if ((Test-Path -Path $PathCheck -PathType Container) -ne $true ) {
			Write-Host "Указанный путь '$PathCheck' отсутствует" -ForegroundColor Red
			Write-Host "Запустите командлет повторно, указав в параметрах правильный путь"
			$NewLine
			RETURN
		}
	}

	
	#################################################
	Write-Host "Путь для сканирования:         $PathCheck"
	Write-Host "Максимально разрешенная длина: $MaxLen"
	$NewLine
	
	
# если отладка - остановимся
if ($IsDebug -eq $true) { 
	$NewLine
	Write-Host "PathCheck and Maxlen defined... Type exit to continue..."
	$NewLine
	$Host.EnterNestedPrompt() 
}

	# готовим имя выходного файла
	$CleanPath = Get-CleanPath $PathCheck
	$IsNetPath = Check-NetPath $CleanPath
	
	if ($IsNetPath) {
		$CleanPath = $CleanPath.Replace('\\', '')
	}
	else { $CleanPath = $CleanPath.Replace(':', '') }
	
	$FileName = $CleanPath.Replace('\', '_')

	# ----------------------------------------------
	# получаем родительский путь
	$ParentPath = Split-Path -Parent -Path $PathCheck
	# если $ParentPath пустой - то это либо корень диска или корень шары
	
	# получаем имя последней папки
	$ScanFolderName = Split-Path $PathCheck -Leaf
	# последняя папка для корня шары - пустой
	# последняя папка для корня диска - корень диска
	
	# определим имя файла с результатами
	$CSVFileScan = [system.io.path]::GetTempPath() + $FileName + '.csv'
write-verbose "`$CSVFileScan $CSVFileScan"

	# ----------------------------------------------
	# корень диск или шара 
	if (Check-BlankValue $ParentPath) { 
		# СЕТЕВАЯ шара
		if ($ScanFolderName -eq '') {
			# захватываем имя из чистой сетевой нотации
			if (($PathCheck -match '([\wА-я\$]+)$') -eq $true ) {
				$RootName = $Matches[0]
				$RootName = $RootName.Replace('$', "_hid")
			}
			else { $RootName = 'unknown' }
		}
		# буква диска
		else { 
			$RootName = $ScanFolderName[0] 
		}
		
		# сформируем новое имя для результатов
		$CSVFileScan = [system.io.path]::GetTempPath() + 'RootDrv_' + $RootName + '.csv'
	}
	
write-verbose "`$CSVFileScan $CSVFileScan"


	# если файл с результатами сканирования уже есть - удалим его
	if ( (Test-Path -Path $CSVFileScan -PathType Leaf) -eq $true ) {
		# удаляем файл 
		Remove-Item $CSVFileScan | Out-Null
	}

	
	
# если отладка - остановимся
if ($IsDebug -eq $true) { 
	$NewLine
	Write-Host "RootPath defined... Type exit to continue..."
	$NewLine
	$Host.EnterNestedPrompt() 
}

	################################################
	################################################
	# делаем мапирование

	$MsgMap = Map-Path $PathCheck 	#-Verbose
write-verbose "`$MsgMap $MsgMap"	

	if ($MsgMap.StartsWith([MapVar]::ErrorMap)) {
		Write-Host "Не удалось произвести мапирование пути: $MsgMap" -ForegroundColor Red
		Write-Host "Дальнейшая работа командлета будет не корректна!" -ForegroundColor Red
		$NewLine
		return
	}
	
	# получаем параметры мапирования
	$Parse = $MsgMap.Split([MapVar]::MapSep)
	$Type = $Parse[0]	# тип мапирования SMB Junction SimbolicLink
	$Link = $Parse[2]	# ссылка на путь
	
	
	$AddPath  = ""
	$RootPath = $PathCheck
	$AddPathInfo = ""
	# если SMB мапирование, то получим папку для добавления к пути сканирования,
	# т.к. мапирование делалось на родительскую папку
	If ($Type.StartsWith([MapVar]::SMB)) { 
		$RootPath = $Parse[4] 
		$AddPath  = $Parse[6] 
		$AddPathInfo = "SMB AddPath:$AddPath"
	}
	
	Write-Host "Результаты мапирования"
	Write-Host "$Link $Type -> $RootPath  $AddPathInfo"
	$NewLine

	$AELPath = Set-AbsUncPath $Link
	$PrefixLen = $AELPath.LastIndexOf('\') + 1
	
	if (!(Check-BlankValue $AddPath)) {$AELPath = $AELPath + $AddPath}
	Write-Host "Абсолютный путь сканирования: $AELPath"
	$NewLine
	
	################################################
	Write-Host 'Сканирование...'
	$NewLine
	
	$watch = [System.Diagnostics.StopWatch]::StartNew()
	$watch.Start() #Запускаем общий таймер

	# ищем все и во всех подпапках по условию с результатами в файл...
	Get-Childitem -Force -Recurse -LiteralPath $AELPath  -ErrorAction SilentlyContinue | `
	? { ($_.FullName.Length - $PrefixLen) -gt $MaxLen } | `
	Select-Object @{Name='PathLen'; Expression={$_.FullName.Length - $PrefixLen}}, `
				  Mode, `
				  @{Name='FullName'; Expression={$_.FullName.Substring($PrefixLen)}} | `
	Export-CSV -Path $CSVFileScan -Force -NoTypeInformation -Encoding UTF8 -Delimiter ";"
	# Пояснения:
	#
	# Get-Childitem -Force -Recurse -LiteralPath $AELPath  -ErrorAction SilentlyContinue |
	# Получить список всех файлов и папок (Force), включая вложенные (Recurse), начиная с заданного абсолютного пути (LiteralPath $AELPath)
	# с пропуском ошибок (ErrorAction SilentlyContinue) и результат передать по конвейеру (|)
	#
	# ? { ($_.FullName.Length - $PrefixLen) -gt $MaxLen } |
	# (? === where)
	# из конвейера отобрать объекты ($_ === текущий элемент конвейера), длина полных имен которых без длины префикса 
	# больше заданного значения и результат передать по конвейеру
	#
	# Select-Object @{Name='PathLen'; Expression={$_.FullName.Length - PrefixLen}}, 
	#				Mode,
	#				@{Name='FullName'; Expression={$_.FullName.Substring($PrefixLen)}} |
	# для формирования файла в формате CSV с результатами в виде таблицы со столбцами: длина пути, атрибут, путь...
	# из объектов конвейера выделяем свойство атрибут (Mode) и формируем 2-а новых ВЫЧИСЛЯЕМЫХ (@{}) свойства и предаем это дальше по конвейеру
	# в формате объектов
	# 1-е новое свойство: имя - 'PathLen';   вычисляемое значение свойства - длина полного имени минус $PrefixLen  ($_.FullName.Length - $PrefixLen)
	# 2-е новое свойство: имя - 'FullName';  вычисляемое значение свойства - полное имя без первых $PrefixLen символов  ($_.FullName.Substring($PrefixLen))
	#
	# Export-CSV -Path $CSVFileScan -Force -NoTypeInformation -Encoding UTF8 -Delimiter ";"
	# объекты из конвейера поместить в файл в формате CSV с перезаписью (-Force) без служебной информации (-NoTypeInformation)
	# в кодировке UTF8 (-Encoding UTF8) - для корректного отображения русских букв в MS Excel
	# разделитель столбцов ';' (-Delimiter ";") для русской версии MS Office - иначе параметр Delimiter не указываем
	# имена свойств объектов будут именами столбцов в листе MS Excel
	
	# остановим таймер
	$watch.Stop()
	
	
	# сканирование завершено
	# удаляем мапирование
	$RetMsg = UnMap-Path $MsgMap
	Write-Host $RetMsg
	$NewLine
	
	Write-Host "Время сканирования: $($watch.Elapsed.ToString().Substring(0,11))"

	# определяем кол-во сформированных строк в файле
	# по размеру массива определяем кол-во строк
	# на больших объемах производительней конвейера примерно в 6 раз
	[long]$CountFindFiles = (Get-Content -Path $CSVFileScan).Length
	# все содержимое CSV файла по конвейеру передаем на подсчет строк
	#[long]$CountFindFiles = (Get-Content -Path $CSVFileScan | Measure-Object -Line).Lines
	
	if ($CountFindFiles -eq 0) {
		if ($ScanFolderName -eq '') {$ScanFolderName = $PathCheck}
		$NewLine
		Write-Host "Имен превышающих $MaxLen символов в папке '$ScanFolderName' не обнаружено..." -ForegroundColor Green
		$NewLine
		RETURN
	}
	
	# ==================================================
	# элементы найдены - отобразим их в таблице MS Excel
	
	# целое значение с разделением по тысячам (-1 -это заголовок столбцов)
	Write-Host "Найдено элементов : $('{0:N0}' -f $($CountFindFiles - 1))"

	$NewLine
	
	Write-Host "Информация по найденным длинным имена размещена в файле"  -ForegroundColor Yellow
	Write-Host $CSVFileScan
	$NewLine
	
	try {
		# создаем/загружаем объект EXCEL
		$excel = New-Object -ComObject Excel.Application
		# показываем EXCEL
		$excel.Visible = $true

		# открываем на чтение временный CSV файл как книгу Excel
		# лист в книге будет называться как имя последней папки
		$CSVBook = $excel.workbooks.Open($CSVFileScan, $null, $true)

		Write-Host "MS Excel с информацией по файлам загружен"  -ForegroundColor Green

	}
	catch {
		Write-Host "Ошибка загрузки Excel"  -ForegroundColor Red
	}

	$NewLine

	Write-Host "Первые строчки файла:" -ForegroundColor Yellow
	Get-Content $CSVFileScan -TotalCount 5

	$NewLine


	Write-Host "Не забудьте потом удалить файл"  -ForegroundColor Red
	$NewLine
	Write-Host "Командное окно PowerShell можно закрыть" 	
	Write-Host "Или выполнить новую проверку..." 	

	
	$NewLine
	$NewLine
	Set-Clipboard -Value "Remove-Item '$CSVFileScan'"
	Write-Host "Команда удаления временного CSV файла помещена в буфер обмена"  -ForegroundColor Yellow
	Write-Host "Для ее вызова нажмите на правую кнопку мышки"  -ForegroundColor Yellow
	
	



