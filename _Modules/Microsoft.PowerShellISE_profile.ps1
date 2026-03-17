# КОДИРОВКА Windows-1251

Using Module CommonConst
using Namespace System.Collections.Generic

#Update-TypeData -PrependPath $PSHOME\FileType.Types.ps1xml

$LogTxtFile = 'e:\temp\TestLog.txt'
$LogCsvFile = 'e:\temp\TestLog.csv'
$JSON = $LogTxtFile + '.json'




Set-Alias -Name JP -Value Join-Path

Set-Alias -Name Get-NotUNCPath -Value Get-CleanPath

Set-Alias -Name Get-AbsolutUNCPath -Value Set-AbsUncPath


$env:MyWorkPCName = "MainPC"
if (!$ConstMyWorkPC) {Set-Variable -Name ConstMyWorkPC -Value $env:MyWorkPCName -Option Constant}

# TRANING ============================================
$TrainingPath =	switch ($env:COMPUTERNAME){
			"MainPC" { $Disk = 'D:\'; 'D:\PAPA\PROJECT\EXCEL\TRAINING' }		# домашний компьютер
			"WorkPC" { $Disk = 'D:\'; 'E:\LEARNING\PROJECT\EXCEL\TRAINING' }	# мой рабочий компьютер
			"WorkNB" { $Disk = 'X:\'; 'Z:\PROJECT\EXCEL\TRAINING' }			# мой рабочий ноутбук
			"HomeNB" { $Disk = 'Z:\'; 'C:\PROJECT\EXCEL\TRAINING' }			# домашний ноутбук
			# ...
			default { $Disk = $null; $null }
		}

if ( ! (Test-Path TRPS:) ) {
	New-PSdrive -Name TRPS -PSprovider Filesystem -Root $TrainingPath  | Out-Null
}

# путь к файлам
$FilesPath = JP $TrainingPath 'ФАЙЛЫ'

# текстовый файл для экспериментов
$CryptFileName = 'FileToCrypt.txt'
$FullNameCryptFile = JP $FilesPath $CryptFileName
#$FullNameCryptFile = '\\?\' + $FullNameCryptFile

# разделение файлов
$DestPartPath = JP $TrainingPath 'TMP_SMALL_PART'
$DestPartFileName = ([System.IO.FileInfo]$CryptFileName).BaseName
$DestFileExt = ([System.IO.FileInfo]$CryptFileName).Extension
$FormatLine = $DestPartFileName + '_Small_Part-{0:0000}' + $DestFileExt


# вопрос 3
# загрузка в MS Excel
$TrainingExcelFilePath = JP $TrainingPath 'EXCEL'
$TrainingBookName = 'TRAINING_v17.xlsm'






# вопрос 4
# регулярные выражения
$DoubleWordPattern = '\b(\w+)\s+\1\b'
$SeparThous = '(\d)(?=(\d{3})+(?!\d))'


$ExcelExtPattern = '^\.(?:xl(?:s[bmx]|t[xm]?|am?|w))$'
$WordExtPattern = '^\.(?:do[ct][mx]?)$'


$PlainTextExt = '^\.(?:ba[st]|c|cer|cfg|cl[as]?|cls|co[bd]|config|cpp|crt|css|csv|d|dbt|dos|emf|err|esh|exc|fft|fqy|frm|hh?|hhc|html?|ini|js|json|jw|lgc|log|pfx|php|pls?|ppl|ps1xml|psd1|psm?1|pst|py|rtf|se|sno|txt|vb[as]|vls|wbt|wlg|xml|xsd|xslt?|xy)$'	
# файлы MS Word
$WordExtTP = '^\.(?:do[ct][mx]?)$'
# файлы MS Excel
$ExelExtTP = '^\.(?:xls[bmx]?|xlt[xm]?|xlam?|xlw)$'
# Архивные файлы
$ArcExtTP = '^\.(?:7z|a|ace|afa|alz|apk|ar[cjk]?|b1|b6z|ba|bh|bz2|cab|cdx|cfs|cpio|cpt|dar|dd|dgc|dmg|ear|ecc|ecsbx|f|gca|gz|ha|hki|ice|img|iso|jar|kgb|lbr|lha|lz[4hxo]?|lzma|mar|mht|pak|paq[678]|par2?|partimg|pea|pim|pit|Q|qda|rar|rev|rk|rz|s7z|sbx|sda|sen|sfark|sfx|shar|shk|sitx|sqx|sz|t|tar|tbz2|tlz|txz|uc[02an]?|ue2|uha|ur2|war|wim|xar|xf|xp3|xz|yz1|z|z|zipx?|zpaq|zst|zz)$'
# Графические файлы
$GrapExtTP = '^\.(?:3ds|3dxm|ai|blend|bmp|cdr|cgm|cmx|collada|djvu|ecw|emf|gif|hd photo|ico|ilbm|jfif|jpe?g|jpeg 2000|mrsid|pag|pcx|pdf|png|pnm|psd|rla|rpf|skp|stl|svgz?|tga|tiff?|u3d|vrml|vsd|webp|wmf|x3d|xbm|xps)$'
# Аудио файлы
$AudioExtTP = '^\.(?:3jp|8svx|aa[cx]?|act|aiff|alac|amr|ape|au|awb|cda|dss|flac|gsm|lklax|lvs|m4[abp]|mid|mmf|mogg|movpkg|mp[3c]|msv|og[ga]|opus|r[am]|raw|rf64|sln|tta|vo[cx]|wav|webm|wma|wv)$'
# Видео файлы
$VideoExtTP = '^\.(?:3g[p2]|amv|asf|avi|drc|f4[vpab]|flv|flv|gifv?|m[24]v|m2?ts|m4[pv]|mkv|mng|mov|mp[ev]|mp2|mp4|mpeg|mpg|mxf|nsf|og[vg]|pptx?|qt|rm|rmvb|roq|svi|ts|viv|vob|webm|wmv|yuv)$'
# Исполняемые файлы
$ExecExtTP = '^\.(?:action|apk|app|ba[st]|bin|chm|cls|cmd|com|command|cpl|csh|dll|exe|frx|gadget|hhp|in[sx]|inf1|ipa|isu|job|jse|ksh|lnk|ms[cpt]|msi|osx|out|paf|pif|ps1xml|psm?1|reg|rgs|run|sct|sh[bs]?|u3p|vb[es]?|vbscript|workflow|wsf?|xlm|xslt?)$'
# Файла баз данных
$DatabaseExtTP = '^\.(?:$er|4d[bcdlrz]|ab[sx]|abcddb|ac|accd[bcertw]|accft|ad[befnp]|alf|anb|approj|aq|ask|bacpac|bak|bc3|btr|caf|cat|cdb|chck|chml?|ckp|cma|cpd|crypt|crypt[56789]|crypt1?|crypt1[0245]|da[bd]|dacpac|dadiagrams|daschema|db[23cfstvx]?|db-journal|db-shm|db-wal|dc[btx]|ddl|dlis|dp1|dqy|dsk|dsn|dtsx|dxl|eco|ecx|edb|epim|erx|exb|fcd|fdb|fic|fm[5p]?|fmp12|fmpsl|fol|fp[3457t]|ftb|gdb|grdb|gwi|hdb|hhc|his|ibd?|icdb|idb|ihx|ipj|itdb|itedb|itw|jet|jtx|kdb|kexi[cs]|lgc|luminar|lwx|ma[fqrsvw]|marshal|mbtiles|md[bfnt]|mdbhtml|mfd|mpd|mrg|mud|musicdb|mwb|myd|nd[bf]|nnt|nrmlib|ns[234f]|nv2?|nwdb|nyf|odb|odl|oqy|or[ax]|owc|p9[67]|pan|pd[bm]|pnz|pqa|pvoc|qry|qvd|r2d|rbf|rctd|realm|rmgc|rodx?|rpd|rsd|sas7bdat|sbf|scx|sd[abcfxy]|sis|spq|sq|sql|sqlite3?|te|teacher|temx|tmd|tps|tr[cm]|tsd|tvdb|ud[bl]|usr|v12|vis|vpd|vvv|wdb|wmdb|wrk|xdb|xld|xmlff)$'
# файлы криптозащиты
$CryptExtTP = '^\.(?:aaa|acid|adame|adobe|ae[ps]|afp|apkm|asc|atsofts|aurora|axx|az[efs]|b2a|bc5b|bca|bf[ae]|bhx|bi[np]|bit|blower|blw?f|bp[kw]|bsk|btoa|bvd|c|cadq|ccf|cdoc|ce[fr]|cerber2?|cgp|chml|clx|cng|codercrypt|conti|coot|cpio|cpt|crt|crypt1?|crypted|crypto|cryptra|ctbl|cuid2?|dc[4df]|dco|ddoc|ded|dharma|dime?|djvus?|dlc|dm|e4a|ecd|edfw|edoc|eegf|eewt|ef[lru]|efdc|eiur|emc|enc|encrypted|enx|eoc|esf|eslock|exc|extr|fc|fgsf|filebolt|film|fonix|fpenc|fsm|fun|g|gdcb|gero|gfe|good|gxk|gzquar|hbx|hex|hid2?|hoop|hqx|htpasswd|idea|iwa|jac|jbc|jceks|jcrypt|jks|jmc[ekprx]?|k3y|kde|keystore|kkk|klq|kode|krab|ksd?|kxx|lastlogin|lcn|lilith|lilocked|litar|locked|locker|locky|lqqw|lucy|lvivt|maas|mba|mcq|mcrp|md5|meo|merry|mfs|mic|mime?|mjd|mme|mnc|mse|nbes|nc|nmo|null|nxl|o|odin|p7e|pack|paradise|pcv|pdc|pdex|pdy|pem|pfile|pfo|pfx|pgp|pkey|plp|poop|ppdf|psw6|purge|pwv|pxf|pxx|pyenc|qewe|qscx|r2u|r5a|radman|rap|rcrypted|rdi|repp|rote|rrbb|rsdf|rumba|ryk|rzk|rzx|s|sa|safe|sage|salma|scb|sdo|sdoc|sdtid|seb|sef|sfi|sgn|sgz|sha256|sha512|shy|sia|sig|signature|sj|sle|sme|snk|spdf?|sqz|srf|ssoi|sspq|stop|stxt|suf|switch|sxls|sxml|u2k|uea|ufr|uiwix|uu[de]?|vdata|viivo|vlt|voom|vp|vtym|w|wallet|wcry|werd|wiot|wlu|wncry|wncryt|wnry|wolf|wpe|wrui|wrypt|xmdx|xtbl|xxe|xxx|yenc|ykcol|ync|zepto|zps|zzzzz)$'
# файлы подписей
$SigExtTP = '^\.(?:sig|p7e|crt|cer|pem|der|pfx)$'
# файлы виртуальных машин
$VirtualExtTP = '^\.(?:jbc|hdd|nvram|ova|vdi|vmdk|vmem|vms[dns]|vmx|vhd)$'
# файлы для чтения
$Read = '^\.(?:0|1st|60[02]|a(bw|cl|fp|mi|ns|sc|ww|zw)|c(cf|hm|sv|wk)|d(bk|ita|jvu|oc[mx]?|otx?|wd)|e(gt|pub|zw)|f(b[23]|dx|t[mx])|g(doc|uide)|h(tm|tl|wp|wpml)|info|kf8|l(og|rf|wp)|m(bp|cw|d|e|obi)|n(bp?|eis|q|t)|o(dm|doc|dt|mm|sheet|tt)|p(ages|ap|dax|d[bfr]|er|rc)|quox|r(adix-64|pt |tf)|s(dw|e|tw|xw)|t(ex|mdx|roff|xt)|uo(f|ml)|via|w(p[dst]|r[dfi])|x(ht|html|ml|ps))$'


$TestSplatPath 	= Get-SplatParam $TrainingPath
$TestExtFile = @(".xlsx", ".doc", ".pav", ".pim", ".cls", ".djvu", ".rpf", ".mid", ".mng", ".pdf", ".cer", ".u3p", ".qvd", ".pdy", ".p7e", ".ova")


# вопрос 5 сканирование
$ScanCSVFolder = 'TMP_SCAN_CSV_RESULT'
$DestCSVPath = JP $TrainingPath $ScanCSVFolder

$PREFIXUNC	 = '\\?\'
$TrainingUnsPathSplat = @{
	Force		= $true
	Recurse 	= $true
	ErrorAction = 'SilentlyContinue'
	LiteralPath	= $PREFIXUNC + $TrainingPath
}

$Delimiter = ';'




# большие файлы
$BigFileCSV = JP $FilesPath 'l4i26051_SCAN.csv'
$BigCSVFile = $BigFileCSV


$Test100Path = JP $TrainingPath 'TMP_100Lines'


$TestFileWithBOM = JP $FilesPath 'Test BOM UTF-16 LE.txt'

Update-TypeData -PrependPath $PSHOME\FileType.Types.ps1xml