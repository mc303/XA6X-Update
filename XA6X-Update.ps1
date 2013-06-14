    #Add-PSSnapin Citrix.*
    $snapin = Get-PSSnapin | where {$_.name -eq 'Citrix.Common.Commands'}
    if($snapin -eq $null){ Add-PSSnapin Citrix.Common.Commands }
    $snapin = Get-PSSnapin | where {$_.name -eq 'Citrix.XenApp.Commands'}
    if($snapin -eq $null){Add-PSSnapin Citrix.XenApp.Commands}
        
    # XenApp Options    
    $_xa_version = "650"   
    $_xa_ro = "R01"
    
    $_xa_install_ro = $false
    
    $_download_msp = $false 
    $_xa_farm_check = $true 
    $_xa_farm_instal = $false
    $_xa_farm_dl_repository = $true
    $_xa_farm_dl_repository_location = "\\test\link"   
    
    # PROXY Options
    $_proxy_enable = $false
    $_proxy_server = ""
    $_proxy_port = ""
    $_proxy_useDefaultCredentials = $false
    $_proxy_user = ""
    $_proxy_passwd = ""
    
#=======================================================================================================    
	$VerbosePreference = "Continue" #"SilentlyContinue"
    $_xa = "XA" 
    $_xa_os = "W2K8R2X64"

    [hashtable]$_hotfixlist_inet = @{}
	[hashtable]$_hotfixlist_xa_hs = @{}
    $_hotfixlist_local = @()
    $_hotfixlist_xa = @()
    [hashtable]$_hotfixlist_to_install = @{}
    
    #$_downloaded_msp = $false
    
    $_regex = [regex]'(https://support.citrix.com/servlet/KbServlet/download)/([0-9\-]+)/(XA650R01W2K8R2X64[0-9]+)(.msp)'
    $_regex_ro = [regex]'(https://support.citrix.com/servlet/KbServlet/download)/([0-9\-]+)/(XA650W2K8R2X64R[0-9]+)(.msp)'
    
    $fullPathIncFileName = $MyInvocation.MyCommand.Definition
    $currentScriptName = $MyInvocation.MyCommand.Name
    $currentExecutingPath = $fullPathIncFileName.Replace($currentScriptName, "")
    
<#  
    Recommended Hotfixes for XenApp 6.0 and later on Windows Server 2008 R2 
    http://support.citrix.com/article/CTX129229
    Based on Citrix Technical Support experience and customer feedback, the following Citrix and Microsoft hotfixes 
    are found to resolve the most common issues with XenApp 6, and XenApp 6.5 running on a Windows Server 2008 R2 platform. 
    These hotfixes focus on basic functionality and stability. For a complete list of Citrix hotfixes for each product, 
    click XenApp 6.0 or XenApp 6.5.       
#>
    
    [hashtable]$_xa_recommanded = @{"XA650R01W2K8R2X64061" = "http://support.citrix.com/article/CTX136085";
        "XA650R01W2K8R2X64090" = "http://support.citrix.com/article/CTX137383";
        "XA650W2K8R2X64R01"= "http://support.citrix.com/article/CTX132122"}
        
    $_xa_hrp = @("Hotfix Rollup Pack 1 for Citrix XenApp 6.5 for Microsoft Windows Server 2008 R2", "Hotfix Rollup Pack 2 for Citrix XenApp 6.5 for Microsoft Windows Server 2008 R2")
        
    if ($_xa_version = "650"){
        $_xa_rss_version = "v6.5_2008r2"
		 $_xa__version = "v6.5"
    } elseif($_xa_version = "600"){
        $_xa_rss_version = "v6.0_2008r2"
		$_xa__version = "v6.0"
    }     

    $_hotfix_url = "http://support.citrix.com/product/xa/$_xa_rss_version/hotfix/general/public/?rss=on"
    $_hotfix_url_ro = "http://support.citrix.com/product/xa/$_xa_rss_version/hotfix/general/hrp/?rss=on"
    
#=======================================================================================================      
$_html_body = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
	<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
	<TITLE></TITLE>
</HEAD>
<BODY>

<style type="text/css">
table { 
 font-family: Verdana, Geneva, sans-serif;
	border: 1px solid #808080; padding: 0in
}

td {
	border: 1px solid #808080; padding: 0in;
	text-align: center;
	vertical-align: middle;
}

td.title {
	text-align: left; 
	vertical-align: middle;
	font-size: 40px; 
}

td.servername {
	text-align: right; 
	vertical-align: middle;
	font-size: 14px;
	font-weight: bold;
}

td.hotfixname {
	text-align: center; 
	vertical-align: middle;
	font-size: 14px;
	font-weight: bold;
}

td.hotfix {
	text-align: center; 
	vertical-align: middle;
	font-size: 13px;
	font-weight: bold;
}

td.IsInstalled {
	text-align: center; 
	vertical-align: middle;
	font-size: 13px;
	background-color: #53B753;
}

td.NotInstalled {
	text-align: center; 
	vertical-align: middle;
	font-size: 13px;
	background-color: #FFFF35;
}

td.IsMissing {
	text-align: center; 
	vertical-align: middle;
	font-size: 13px;
	background-color: #D20004;
}
</style>

<TABLE  CELLPADDING=0 CELLSPACING=0 style="min-width: 800px;">
	<TR>
		<TD class="title" COLSPAN="{title_colspan}">
			&nbsp;  XenApp {version} installed Hotfixes
		</TD>
	</TR>
	<TR>
		<TD class="servername">		
			Hotfixes	&nbsp;
		</TD>
		<TD COLSPAN="{hrp_colspan}" class="hotfixname">
			XA650W2K8R2X64
		</TD>
		<TD COLSPAN="{hotfixname_colspan}" class="hotfixname">
			XA650R01W2K8R2X64
		</TD>
	</TR>
	{servers_hrp_hf}
	{hotfixs}
</TABLE>
</BODY>
</HTML>
"@    


$_html_hotfixes = @"
    <TR>
		<TD class="servername">		
			{txt_servers} &nbsp;
		</TD>
        {hrp}
        {hotfixs}		
	</TR>
"@

$_html_hotfixes_items = @"
        <TD {class_items}>
			{item}
		</TD>
"@

        #<TD class="hotfix">
		#	R01
		#</TD>
		#<TD class="hotfix">
		#	R02
		#</TD>
		#<TD class="hotfix">
		#	002
		#</TD>
		#<TD class="hotfix">
		#	011
		#</TD>
		#<TD class="hotfix">
		#	068
		#</TD>

#=======================================================================================================    
    function GetHotfixlistFromCitrix(){
        $_hotfixlist_function = @{}
        if($_proxy_enable -eq $true){ 
            $proxy = new-object System.Net.WebProxy
            $proxy.Address = "$_proxy_server:$_proxy_port"
            if ($_proxy_useDefaultCredentials -eq $false){
                $account = new-object System.Net.NetworkCredential($_proxy_user,[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_proxy_passwd)), "")
                $proxy.credentials = $account
            } else {            
                $proxy.useDefaultCredentials = $proxy_useDefaultCredentials
            }
        }
        
        $wc = new-object system.net.webclient
        if($_proxy_enable -eq $true){ 
            $wc.proxy = $proxy
        }
        
        [xml]$_rss_xml_rdf = $wc.downloadString($_hotfix_url)
        [xml]$_rss_xml_rdf_ro = $wc.downloadString($_hotfix_url_ro)
        
        #$wc.DownloadFile($_hotfix_url_ro, "C:\#Beheer\XAUpdate\hrp.txt")
       
        foreach ($item in $_rss_xml_rdf.rdf.item) {               
           if ([int]$item.title.IndexOf("$_xa$_xa_version$_xa_ro$_xa_os") -ne -1) {          
               $_hotfixlist_function.add($item.title.Substring($item.title.IndexOf("$_xa$_xa_version$_xa_ro$_xa_os"),20), $item.link)
           }                              
        }         
        $item = $null
        
        foreach ($item in $_rss_xml_rdf_ro.rdf.item) { 
            if ($item.title -match $_xa_hrp[0]){
                $_hotfixlist_function.add("$_xa$_xa_version$_xa_os$_xa_ro", $item.link)
            }  
            if ($item.title -match $_xa_hrp[1]){
                $_hotfixlist_function.add("$_xa$_xa_version$_xa_os$_xa_ro", $item.link)
            }                                                       
        } 
        
        $item = $null
        $wc = $null
        $proxy = $null
        
        return ,$_hotfixlist_function         
    }
    
    function DownloadCitrixHotFix {
        param($_filename, $_link)
        
        $_hotfixlist_function = @{}
        if($_proxy_enable -eq $true){ 
            $proxy = new-object System.Net.WebProxy
            $proxy.Address = "$_proxy_server:$_proxy_port"
            if ($_proxy_useDefaultCredentials -eq $false){
                $account = new-object System.Net.NetworkCredential($_proxy_user,[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_proxy_passwd)), "")
                $proxy.credentials = $account
            } else {            
                $proxy.useDefaultCredentials = $proxy_useDefaultCredentials
            }
        }
        
        $wc = new-object system.net.webclient
        if($_proxy_enable -eq $true){ 
            $wc.proxy = $proxy
        }       
        if ($_filename.IndexOf("$_xa$_xa_version$_xa_os$") -ne -1) {
            $_htmlfile = $wc.DownloadString($_link)
            $_matches = $_regex_ro.Matches($_htmlfile)
            $_download_file = $_matches | %{$_.value}   
        } else {            
            $_htmlfile = $wc.DownloadString($_link)
            $_matches = $_regex.Matches($_htmlfile)
            $_download_file = $_matches | %{$_.value}        
        }
        $__filename = $_filename.replace(".html", ".msp")
        if ((test-path $__filename) -eq $false){
            Write-Verbose ("Downloading :$__filename")			
            $wc.DownloadFile($_download_file, $_filename.replace(".html", ".msp"))
            Write-Verbose ("Downloaded :$__filename")
        } else {
            Write-Verbose ("File found in repository :$__filename")
        }
        
        $wc = $null
        $proxy = $null  
        $_htmlfile = $null  
        $_matches = $null   
    }
    
    
    function _citrixHotfixToHtml{        
        param($_hotfixlist_inet, $_html_hotfixes, $_html_body, $_xa_hrp, $_xs_hf)
             
        [string]$_html_hotfixes_items_all = ""
		[string]$_html_hotfixes_items_hrp = ""
		[int]$_hrp_count = 0
		[int]$_hf_count = 0
		
        ForEach($item in $_hotfixlist_inet.GetEnumerator() | sort key){                                 
            if ($item.key.Contains($_xa_hrp) -eq $true) {
				# Display the Hotfix Rollup Pack

            	$_item_short = $item.key.replace($_xa_hrp,"")
            	$_html_hotfixes_items_hrp += $_html_hotfixes_items.replace("{item}",$_item_short)       
				$_hrp_count += 1
			} else {
				# Display the Hotfix
				$_item_short = $item.key.replace($_xs_hf,"")
            	$_html_hotfixes_items_all += $_html_hotfixes_items.replace("{item}",$_item_short)
				$_hf_count += 1
            }			
        }
			
		$_html_body = $_html_body.Replace("{title_colspan}", ($_hf_count + $_hrp_count + 3))
		$_html_body = $_html_body.Replace("{hrp_colspan}", $_hrp_count)
		$_html_body = $_html_body.Replace("{hotfixname_colspan}", $_hf_count)
		 
        $_html_hotfixes = $_html_hotfixes.replace("{hrp}", $_html_hotfixes_items_hrp)
        $_html_hotfixes = $_html_hotfixes.replace("{hotfixs}", $_html_hotfixes_items_all)
		$_html_hotfixes = $_html_hotfixes.replace("{txt_servers}", "Servers")
		$_html_hotfixes = $_html_hotfixes.replace("{class_items}", "class=""hotfix""")

        return $_html_hotfixes, $_html_body
        
        $item = $null
        $hotfix = $null
    }
	
	function _installedHotfixPerServerToHtml() {
	    param([hashtable]$_xa_recommanded, 
				$_hotfixlist_xa_hs,
				[hashtable]$_hotfixlist_inet,
				$_html_hotfixes,
				$_html_body,
				[string]$_servername,
				$_xa_hrp,
				$_xs_hf)
        
        [string]$_html_hotfixes_items_all = ""
        [string]$_html_hotfixes_items_hrp = ""
		[string]$_html_hotfixes_item = ""
        [string]$_switch_hotfix = "NotInstalled"
		
       	ForEach($item in $_hotfixlist_inet.GetEnumerator() | sort key){     
            if ($_hotfixlist_xa_hs.ContainsKey($item.key) -eq $true){
				 if ($item.key.Contains($_xa_hrp) -eq $true -and $_xa_recommanded.ContainsKey($item.key) -eq $true) {
					$_html_hotfixes_item += $_html_hotfixes_items.replace("{item}","&nbsp;Installed (R) &nbsp;")
					$_html_hotfixes_items_hrp += $_html_hotfixes_item.replace("{class_items}","class=""IsInstalled""")
					$_html_hotfixes_item = ""
				} elseif($_xa_recommanded.ContainsKey($item.key) -eq $true) {
					$_html_hotfixes_item += $_html_hotfixes_items.replace("{item}","&nbsp;Installed (R)&nbsp;")
					$_html_hotfixes_items_all += $_html_hotfixes_item.replace("{class_items}","class=""IsInstalled""")
					$_html_hotfixes_item = ""
	            } else {
					$_html_hotfixes_item += $_html_hotfixes_items.replace("{item}","&nbsp;Installed&nbsp;")
					$_html_hotfixes_items_all += $_html_hotfixes_item.replace("{class_items}","class=""IsInstalled""")
					$_html_hotfixes_item = ""
				}
            } else {
				if ($item.key.Contains($_xa_hrp) -eq $true -and $_xa_recommanded.ContainsKey($item.key) -eq $true) {
					$_html_hotfixes_item += $_html_hotfixes_items.replace("{item}","&nbsp;Missing (R)&nbsp;")
					$_html_hotfixes_items_hrp += $_html_hotfixes_item.replace("{class_items}","class=""IsMissing""")
					$_html_hotfixes_item = ""
				} elseif ($_xa_recommanded.ContainsKey($item.key) -eq $true){
					$_html_hotfixes_item += $_html_hotfixes_items.replace("{item}","&nbsp;Missing (R)&nbsp;")
					$_html_hotfixes_items_all += $_html_hotfixes_item.replace("{class_items}","class=""IsMissing""")
					$_html_hotfixes_item = ""
				} else {
					$_html_hotfixes_item += $_html_hotfixes_items.replace("{item}","&nbsp;Not Installed&nbsp;")
					$_html_hotfixes_items_all += $_html_hotfixes_item.replace("{class_items}","class=""NotInstalled""")
					$_html_hotfixes_item = ""
				}
			}                                    	 							              
		}
				
		$_html_hotfixes = $_html_hotfixes.replace("{hrp}", $_html_hotfixes_items_hrp)
        $_html_hotfixes = $_html_hotfixes.replace("{hotfixs}", $_html_hotfixes_items_all)
		$_html_hotfixes = $_html_hotfixes.replace("{txt_servers}", $_servername)
		$_html_hotfixes = $_html_hotfixes.replace("{class_items}", "class=""hotfix""")

        return $_html_hotfixes
	}
    
    function _citrixHotfixes{
        param($_hotfixlist_xa)
    
        Write-Verbose ("Citrix Hotfixes: $_server_name")
        ForEach($hotfix in $_hotfixlist_xa) {
        	$_hotfixlist_local += $hotfix.HotfixName                       
        }
        
        # Compare to Array's 
        #Compare-Object -referenceObject $_hotfixlist_inet -DifferenceObject $_hotfixlist_local  -IncludeEqual           

        $_found = $false
        ForEach($item in $_hotfixlist_inet.GetEnumerator() | sort key){
            ForEach($hotfix in $_hotfixlist_xa) {
                if ($item.key -match $hotfix.HotfixName){
                    $_found = $true  
                    $_hotfix = $hotfix.HotfixName 
                    break      
                    #$_hotfix_link += $hotfix.link  
                    #$hotfix.link            			                    		                 
                }
            }
            if($_found -eq $true) {
                Write-Verbose ("[X] Hotfix:$_hotfix")
            } else {
                Write-Verbose ("[ ] Hotfix:$($item.key)")
            }           
            
            
            $_found = $false
        }
        $item = $null
        $hotfix = $null
    }
    
    function _recommendedCitrixHotfixes {
        param($_xa_recommanded, $_hotfixlist_xa)
        
         Write-Verbose ("Recommended Citrix Hotfixes: $_server_name")
        #$_xa_recommanded
        #Write-Verbose  ""
        $_found = $false
        ForEach($_item in $_xa_recommanded.GetEnumerator() | sort key) {
            ForEach($hotfix in $_hotfixlist_xa) {
                if ($_item.key -match $hotfix.HotfixName){
                    $_found = $true  
                    $_hotfix = $hotfix.HotfixName                   			                    		                 
                }
            }
            if($_found -eq $true) {
                Write-Verbose ("[X] Hotfix:$_hotfix")
                
            } else {
                Write-Verbose ("[ ] Hotfix:$($_item.key)")
                $_hotfixlist_to_install.add($_item.key,	$_item.value)
                            
            }
            $_found = $false
        }
        
        return $_hotfixlist_to_install
    }
	
	function _convertXAtoHS() {
		param($_hotfixlist_xa)
		
		[hashtable]$_xa_temp = @{}
		
		ForEach($hotfix in $_hotfixlist_xa) {
			$_xa_temp.add($hotfix.HotfixName, $hotfix.ServerName)
		}
		
		return $_xa_temp	
	}
    
   # function _ScriptDirectory(){
   #     $fullPathIncFileName = $MyInvocation.MyCommand.Definition
   #     $currentScriptName = $MyInvocation.MyCommand.Name
   #     $currentExecutingPath = $fullPathIncFileName.Replace($currentScriptName, "")
   #     
   #     return ,$fullPathIncFileName
   # }
#=======================================================================================================

    [string]$_html_table_tr = ""
    [hashtable]$_hotfixlist_inet = GetHotfixlistFromCitrix
    # $_hotfixlist_inet = $_hotfixlist_inet | sort 
    # [hashtable]$_hotfixlist_inet = [hashtable]$_hotfixlist_inet.GetEnumerator() | Sort-Object Key
    # $_xa_recommanded.GetEnumerator() | Sort-Object Key
    
    
    if ($_xa_farm_check -eq $false) {
        $_server = Get-XAServer -ServerName $env:computername 
        #$_server = Get-XAServer -ServerName "CTX98" #$env:computername 
        $_server_name = $_server.ServerName
        $_checking_tekst = "CitrixProductName `t: " + $_server.CitrixProductName
        $_line = "-" * $_checking_tekst.Length        
        
        Write-Verbose ("")
        Write-Verbose ("Checking $($_server.Server) Namefor missing hotfixes")
        Write-Verbose ($_line)
        Write-Verbose ("$_checking_tekst")
        Write-Verbose ("CitrixVersion `t`t: $($_server.CitrixVersion)")
        Write-Verbose ("CitrixEdition `t`t: $($_server.CitrixEdition)")
        Write-Verbose ($_line)
        Write-Verbose ("")
            
        $_hotfixlist_xa = Get-XAServerHotfix -ServerName $_server.ServerName -EA 0 | sort-object HotfixName
        If( $? -and $_hotfixlist_xa -and $_hotfixlist_inet){ 
                  
        
			$_hotfixlist_xa_hs = _convertXAtoHS $_hotfixlist_xa
            
			# Citrix Hotfixes       
            _citrixHotfixes $_hotfixlist_xa
            
            Write-Verbose ($_line)
            Write-Verbose ("")
            
            # Recommended Citrix Hotfixes
            $_hotfixlist_to_install = _recommendedCitrixHotfixes $_xa_recommanded $_hotfixlist_xa
            Write-Verbose ($_line)
            
            #download missing hotfixes
            if ($_download_msp -eq $true) {
                Write-Verbose ("")
				
                ForEach($_item in $_hotfixlist_to_install.GetEnumerator() | sort key) {   
                    $_file_name = "{0}{1}" -f $_item.key, ".html"
                    $_fullpath = join-path -path $currentExecutingPath -childpath $_file_name
                    $_link_to = $_item.value
                    
                    DownloadCitrixHotFix $_fullpath $_link_to   
                    $_fullpath = $null
                    $_link_to = $null                
                }
				$_html_table_tr += _installedHotfixPerServerToHtml $_xa_recommanded $_hotfixlist_xa_hs $_hotfixlist_inet $_html_hotfixes $_html_body $_server.ServerName  "$_xa$_xa_version$_xa_os" "$_xa$_xa_version$_xa_ro$_xa_os"
            }          
    	} else {
            Write-Verbose ("Cannot retrieve hotfix list from server: $($_server.ServerName)")
        }
        

    } else {
        $_servers = Get-XAServer
                
        ForEach($_server in $_servers) {
        
            $_server_name = $_server.ServerName
            $_checking_tekst = "CitrixProductName `t: " + $_server.CitrixProductName
            $_line = "-" * $_checking_tekst.Length        
            
            Write-Verbose ("")
	        Write-Verbose ("Checking $($_server.Server) Namefor missing hotfixes")
	        Write-Verbose ($_line)
	        Write-Verbose ("$_checking_tekst")
	        Write-Verbose ("CitrixVersion `t`t: $($_server.CitrixVersion)")
	        Write-Verbose ("CitrixEdition `t`t: $($_server.CitrixEdition)")
	        Write-Verbose ($_line)
	        Write-Verbose ("")
            
            $_hotfixlist_xa = Get-XAServerHotfix -ServerName $_server.ServerName -EA 0 | sort-object HotfixName
            If( $? -and $_hotfixlist_xa -and $_hotfixlist_inet){            
                
				$_hotfixlist_xa_hs = _convertXAtoHS $_hotfixlist_xa
				
                # Citrix Hotfixes       
                _citrixHotfixes $_hotfixlist_xa
                                
                Write-Verbose ($_line)
                Write-Verbose  ""
                
                # Recommended Citrix Hotfixes
                $_hotfixlist_to_install = _recommendedCitrixHotfixes $_xa_recommanded $_hotfixlist_xa
               
                Write-Verbose  $_line
                
                #download missing hotfixes
                if ($_download_msp -eq $true) {
                    Write-Verbose  ""
                    ForEach($_item in $_hotfixlist_to_install.GetEnumerator() | sort key) {   
                        $_file_name = "{0}{1}" -f $_item.key, ".html"
                        $_fullpath = join-path -path $currentExecutingPath -childpath $_file_name
                        $_link_to = $_item.value
                        #$_link_to
                        DownloadCitrixHotFix $_fullpath $_link_to
                    }
                }
                $_html_table_tr += _installedHotfixPerServerToHtml $_xa_recommanded $_hotfixlist_xa_hs $_hotfixlist_inet $_html_hotfixes $_html_body $_server.ServerName  "$_xa$_xa_version$_xa_os" "$_xa$_xa_version$_xa_ro$_xa_os"
            } else {
                Write-Verbose ("Cannot retrieve hotfix list from server: $($_server.ServerName)")
            }
            $_hotfixlist_xa = @()
            $_hotfixlist_to_install = @{}
        }
    }

    $_html_return = _citrixHotfixToHtml $_hotfixlist_inet $_html_hotfixes $_html_body "$_xa$_xa_version$_xa_os" "$_xa$_xa_version$_xa_ro$_xa_os"
	$_html_table_tr
	$_html_hotfixes = $_html_return[0]
	$_html_body = $_html_return[1]
    $_html_output = $_html_body.replace("{hotfixs}",$_html_table_tr)
    $_html_output = $_html_output.replace("{servers_hrp_hf}",$_html_hotfixes)
	$_html_output = $_html_output.replace("{version}",$_xa__version)
    $_html_output | Out-File c:\testt.html
        
    $_hotfixlist_xa = $null
    $_hotfixlist_inet = $null
    $_hotfixlist_local = $null
   
