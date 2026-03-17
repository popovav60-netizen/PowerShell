# ######################################################
#
# Модуль классов статических переменных
#
# версия 1.0.3  от 26.04.2024
#
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
# [RegValue]| Get-Member -Static
# [TxtPlain]| Get-Member -Static
# [Word]	| Get-Member -Static
# [Excel]	| Get-Member -Static
# [Archive]	| Get-Member -Static
# [Video]	| Get-Member -Static
# [Audio]	| Get-Member -Static
# [Exec]	| Get-Member -Static
# [Database]| Get-Member -Static
# [Crypt]	| Get-Member -Static
# [Sig]		| Get-Member -Static
# [Virtual] | Get-Member -Static
# [Read] 	| Get-Member -Static
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


# ######################################################
# разделы реестра
class RegValue {

	static [string]$RKCommon					= 'HKCU:\Software\PowerShell\PAV'
	static [string]$RKSFXchange					= 'Xchange'
	static [string]$RKSKCSVFile					= 'CSVFile'
	
	static [string]$RKFullPathXchCsv			= [RegValue]::RKCommon + '\' + [RegValue]::RKSFXchange + '\' + [RegValue]::RKSKCSVFile

	static [string]$RVCsvFileName				= 'CSVFileName'
	static [string]$RVCsvFileScanDate			= 'CSVFileScanDate'
	static [string]$RVCsvFileScanTime			= 'CSVFileScanTime'
	static [string]$RVCsvFileMsg				= 'CSVFileMessage'
	static [string]$RVCsvFileSize				= 'CSVFileSize'
	static [string]$RVCsvFileRows				= 'CSVFileRows'
	static [string]$RVCsvFileDelimiter			= 'CSVFileDelimiter'

}




# ######################################################
# добавлено 06.04.2023
# ------------------------------------------------------
# расширения файлов в простом текстовом формате
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([TxtPlain]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [TxtPlain]::Match | ft
class TxtPlain {
		
	static [string]$Ext	='ba[st]|c(er|l[as]?|o([bd]|nfig)|pp|fg|rt|s[sv])?|d(bt|os)?|e(mf|rr|sh|xc)|f(ft|qy|rm)|h(h|hc|tml?)?|ini|j(s(on)?|w)|l(gc|og)|p(fx|hp|ls?|pl|s(1xml|m?1|d1|t))|py|rtf|s(e|no)|txt|v(b[as]|ls)|w(bt|lg)|x(ml|sd|slt?|y)'
	
	static [string]$Match = "^\.(?:$([TxtPlain]::Ext))$"
}



# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения MS Word файлов 
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Word]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Word]::Match | ft
class Word {
		
	static [string]$Ext	= 'do[ct][mx]?'
	
	static [string]$Match = "^\.(?:$([Word]::Ext))$"
}


# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения MS Excel файлов 
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Excel]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Excel]::Match | ft
class Excel {
		
	static [string]$Ext	= 'xl(am?|s[bmx]?|t[xm]?|w)'
	
	static [string]$Match = "^\.(?:$([Excel]::Ext))$"
}


# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения Archive файлов 
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Archive]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Archive]::Match | ft
class Archive {
		
	static [string]$Ext	= '7z|a(ce|fa|lz|pk|r[cjk]?)|b(1|6z|a|h|z2)|c(ab|dx|fs|p(io|t))|d(ar|d|gc|mg)|e(ar|c(c|sbx))|f|g(ca|z)|h(a|ki)|i(ce|mg|so)|jar|kgb|l(br|ha|z([4hxo]?|ma))|m(ar|ht)|p(a(k|q[678]|r(2?|timg))|ea|im|it)|q(da)?|r(ar|ev|k|z)|s(7z|bx|da|en|f(ark|x)|h(ar|k)|itx|qx|z)|t(ar|bz2|[lx]z)?|u(c[02an]?|e2|ha|r2)|w(ar|im)|x(ar|f|p3|z)|yz1|z(ipx?|paq|st|z)?'
	
	static [string]$Match = "^\.(?:$([Archive]::Ext))$"
}



# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения Graphic файлов 
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Graphic]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Graphic]::Match | ft
class Graphic {
		
	static [string]$Ext	= '3d(s|xm)|ai|b(lend|mp)|c(dr|gm|mx|ollada)|djvu|e(cw|mf)|fb[23]|gif|hd photo|i(co|lbm)|j(fif|pe?g|peg 2000)|mrsid|p(ag|cx|df|n(g|m)|sd)|r(la|pf)|s(kp|tl|vgz?)|tga|tiff?|u3d|v(rml|sd)|w(ebp|mf)|x(3d|bm|ps)'
	
	static [string]$Match = "^\.(?:$([Graphic]::Ext))$"
}




# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения Audio файлов 
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Audio]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Audio]::Match | ft
class Audio {
		
	static [string]$Ext	= '3jp|8svx|a(a[cx]?|ct|iff|lac|mr|pe|u|wb)|cda|dss|flac|gsm|l(klax|vs)|m(4[abp]|id|mf|o(gg|vpkg)|p[3c]|sv)|o(g[ga]|pus)|r([am]|aw|f64)|sln|tta|vo[cx]|w(av|ebm|ma|v)'
	
	static [string]$Match = "^\.(?:$([Audio]::Ext))$"
}




# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения Video файлов 
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Video]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Video]::Match | ft
class Video {
		
	static [string]$Ext	= '3g[p2]|a(mv|sf|vi)|drc|f(4[vpab]|lv|lv)|gifv?|m([24]v|2?ts|4[pv]|kv|ng|ov|p(e([v24g]|g)|4)|xf)|nsf|og[vg]|pptx?|qt|r(m(vb)?|oq)|svi|ts|v(iv|ob)|w(ebm|mv)|yuv'
	
	static [string]$Match = "^\.(?:$([Video]::Ext))$"
}



# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения Exec (исполняемых) файлов - не полный список
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Exec]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Exec]::Match | ft
class Exec {
		
	static [string]$Ext	= 'a(ction|pk|pp)|b(a[st]|in)|c(hm|ls|md|nv|om|ommand|pl|sh)|dll|exe|frx|gadget|hhp|i(n([sx]|f1)|pa|su)|j(ob|se)|ksh|lnk|ms[cpt]|ms[ib]|mui|nlb|o(sx|ut)|olb|paf|pbd|pif|ps1xml|psm?1|r(eg|gs|un)|sbsx|s(ct|h[bs]?)|tmp|u3p|vb([esp]?|script)|w(orkflow|sf?)|x(lm|slt?)'
	
	static [string]$Match = "^\.(?:$([Exec]::Ext))$"
}


# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения файлов баз данных
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Database]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Database]::Match | ft
class Database {
		
	static [string]$Ext	= '$er|4d[bcdlrz]|a(b([sx]|cddb)|a(c|c(d[bcertw]|ft))|ccdb|d[befnp]|lf|nb|pproj|q|sk)|bacpac|bak|bc3|btr|caf|cat|cdb|chck|chml?|ckp|cma|cpd|crypt|crypt[56789]|crypt1?|crypt1[0245]|da[bd]|dacpac|dadiagrams|daschema|db[23cfstvx]?|db-journal|db-shm|db-wal|dc[btx]|ddl|dic|dlis|dp1|dqy|dsk|dsn|dtsx|dxl|eco|ecx|edb|epim|erx|exb|fcd|fdb|fic|fm[5p]?|fmp12|fmpsl|fol|fp[3457t]|ftb|gdb|grdb|gwi|hdb|hhc|his|ibd?|icdb|idb|ihx|ipj|itdb|itedb|itw|jet|jtx|kdb|kexi[cs]|lgc|luminar|lwx|ma[fqrsvw]|marshal|mbtiles|md[bfnt]|mdbhtml|mfd|mpd|mrg|mud|musicdb|mwb|myd|nd[bf]|nnt|nrmlib|ns[234f]|nv2?|nwdb|nyf|odb|odl|oqy|or[ax]|owc|p9[67]|pan|pd[bm]|pnz|pqa|pvoc|qry|qvd|r2d|rbf|rctd|realm|rmgc|rodx?|rpd|rsd|sas7bdat|sbf|scx|sd[abcfxy]|sis|spq|sq|sql|sqlite3?|te|teacher|temx|tmd|tps|tr[cm]|tsd|tvdb|ud[bl]|usr|v12|vis|vpd|vvv|wdb|wmdb|wrk|xdb|xld|xmlff'
	
	static [string]$Match = "^\.(?:$([Database]::Ext))$"
}



# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения файлов криптозащиты
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Crypt]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Crypt]::Match | ft
class Crypt {
		   
	static [string]$Ext	= 'aaa|acid|adame|adobe|ae[ps]|afp|apkm|asc|atsofts|aurora|axx|az[efs]|b2a|bc5b|bca|bf[ae]|bhx|bi[np]|bit|blower|blw?f|bp[kw]|bsk|btoa|bvd|c|cadq|ccf|cdoc|ce[fr]|cerber2?|cgp|chml|clx|cng|codercrypt|conti|coot|cpio|cpt|crt|crypt1?|crypted|crypto|cryptra|ctbl|cuid2?|dc[4df]|dco|ddoc|ded|dharma|dime?|djvus?|dlc|dm|e4a|ecd|edfw|edoc|eegf|eewt|ef[lru]|efdc|eiur|emc|enc|encrypted|enx|eoc|esf|eslock|exc|extr|fc|fgsf|filebolt|film|fonix|fpenc|fsm|fun|g|gdcb|gero|gfe|good|gxk|gzquar|hbx|hex|hid2?|hoop|hqx|htpasswd|idea|iwa|jac|jbc|jceks|jcrypt|jks|jmc[ekprx]?|k3y|kde|keystore|kkk|klq|kode|krab|ksd?|kxx|lastlogin|lcn|lilith|lilocked|litar|locked|locker|locky|lqqw|lucy|lvivt|maas|mba|mcq|mcrp|md5|meo|merry|mfs|mic|mime?|mjd|mme|mnc|mse|nbes|nc|nmo|null|nxl|o|odin|p7e|pack|paradise|pcv|pdc|pdex|pdy|pem|pfile|pfo|pfx|pgp|pkey|plp|poop|ppdf|psw6|purge|pwv|pxf|pxx|pyenc|qewe|qscx|r2u|r5a|radman|rap|rcrypted|rdi|repp|rote|rrbb|rsdf|rumba|ryk|rzk|rzx|s|sa|safe|sage|salma|scb|sdo|sdoc|sdtid|seb|sef|sfi|sgn|sgz|sha256|sha512|shy|sia|sig|signature|sj|sle|sme|snk|spdf?|sqz|srf|ssoi|sspq|stop|stxt|suf|switch|sxls|sxml|u2k|uea|ufr|uiwix|uu[de]?|vdata|viivo|vlt|voom|vp|vtym|w|wallet|wcry|werd|wiot|wlu|wncry|wncryt|wnry|wolf|wpe|wrui|wrypt|xmdx|xtbl|xxe|xxx|yenc|ykcol|ync|zepto|zps|zzzzz'
	
	static [string]$Match = "^\.(?:$([Crypt]::Ext))$"
}




# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения файлов подписей
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Sig]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Sig]::Match | ft
class Sig {
		
	static [string]$Ext	= 'c(rt|er)|der|p(em|fx|7e)|sig(nature\.p7s)?'
	
	static [string]$Match = "^\.(?:$([Sig]::Ext))$"
}





# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения файлов виртуализации
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Virtual]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Virtual]::Match | ft
class Virtual {
		
	static [string]$Ext	= 'jbc|hdd|nvram|ova|v(di|m(dk|em|s[dns]|x)|hd)'
	
	static [string]$Match = "^\.(?:$([Virtual]::Ext))$"
}







# ######################################################
# добавлено 24.04.2024
# ------------------------------------------------------
# расширения файлов для чтения
# для использования в -match например:
# Get-ChildItem k:\tmp -recurse | ? extension -match "^\.($([Read]::Ext))$" | ft
# или так
# Get-ChildItem k:\tmp -recurse | ? extension -match [Read]::Match | ft
class Read {
		
	static [string]$Ext	= '0|1st|60[02]|a(bw|cl|fp|mi|ns|sc|ww|zw)|c(cf|hm|sv|wk)|d(bk|ita|jvu|oc[mx]?|otx?|wd)|e(gt|pub|zw)|f(b[23]|dx|t[mx])|g(doc|uide)|h(tm|tl|wp|wpml)|info|kf8|l(og|rf|wp)|m(bp|cw|d|e|obi)|n(bp?|eis|q|t)|o(dm|doc|dt|mm|sheet|tt)|p(ages|ap|dax|d[bfr]|er|rc)|quox|r(adix-64|pt |tf)|s(dw|e|tw|xw)|t(ex|mdx|roff|xt)|uo(f|ml)|via|w(p[dst]|r[dfi])|x(ht|html|ml|ps)'
	
	static [string]$Match = "^\.(?:$([Read]::Ext))$"
}






