# ######################################################
# для использования надо первым оператором 
# в модуле или командлете ставить
#
# Using Module CommonConst 
#
#
# Посмотреть что импортируется из классов
#
# [MapVar] 	| Get-Member -Static
# [Ip4] 	| Get-Member -Static
# [ABSPath] | Get-Member -Static
# [MinValue]| Get-Member -Static
#
# ######################################################





# ######################################################
# для мапирования локальных и сетевых путей
class MapVar {

	static [String]$MapSep			= '->'
	static [String]$ROOT			= 'ROOT'
	static [String]$SMB				= 'SMB'
	static [String]$Junction		= 'Junction'
	static [String]$Simbolic		= 'SymbolicLink'
	static [String]$ErrorMap		= 'ErrMap'
	static [String]$ErrMapSep		= [MapVar]::ErrorMap + [MapVar]::MapSep
	static [String]$DelLink			= 'Del'
	static [String]$LinkNotPresent	= 'LinkNotPresent'
	
}




# ######################################################
# для проверки Ip4 адреса и сетевых путей
class Ip4 {

	# Ip4 адрес	типа '10.85.152.72'
	#                                         \d\d? вместо \d?\d немного ускоряет выявление неудачи в НКА
	static [String]$PatternIp4	= '(?:(?:[01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d\d?|2[0-4]\d|25[0-5])'

	# DNS имя сервера (не адрес) НАЧИНАЕТСЯ С БУКВЫ И БЕЗ ПРОБЕЛОВ!!!
	static [string]$PatternDNSName				= '[A-zА-яЁё][\w\-]+'
	

}




# ######################################################
# для проверки и формирования префиксов абсолютных путей
class ABSPath {
	
	# ПРЕФИКСЫ В ПУТИ
	static [string]$PrefixABS					= '\\?\'
	static [string]$PrefixABSUNC				= [ABSPath]::PrefixABS + 'UNC\'	# '\\?\UNC\'
	
	# ШАБЛОНЫ ПРОВЕРКИ
	static [string]$PatternPrefixABS			= '(?:\\\\\?\\)'			# '\\?\'
	static [string]$PatternPrefixABSNET			= '(?:\\\\\?\\UNC\\|\\\\)'	# '\\?\UNC\' или '\\'
	
	static [string]$PatternLastFolder			= '\\(?:[\wА-яЁё]+\$?)?$'	# возможно '\FolderName' и '\' и '\Folder$'
	
	static [string]$PatternDrvLetter			= '^[a-z]:$'				# только типа  'C:'
	static [string]$PatternRootPathDrv			= '^[a-z]:\\$'				# только типа  'C:\'
	static [string]$PatternDrvAndOptionalSlesh 	= '^[a-z]:\\?$'				# возможно 'C:' и 'C:\'
	
	# подстановочние символы, поддерживаемые PowerShell:  '[]*?'
	static [string]$PatternSubstChar			= '[[\]\*\?]'
	
}



# ######################################################
# минимальные значения
class MinValue {

	static [int]$RegPathLen						= 7		# путь в реестре 'HKCU:\P'
	static [int]$RegVNameLen					= 1		# имя значения  'P'
	
	static [int]$NetPathLen						= 6		# сетевой путь '\\d\s\'
	static [int]$FSOPathLen						= 3		# путь 'c:\'
	static [int]$RootPathLen					= 2		# путь 'c:'
	
	static [int]$LinkPathLen					= 5		# путь 'c:\l'
	
	static [int]$MsgMapLen						= 3		# путь 'Del'
	
}



