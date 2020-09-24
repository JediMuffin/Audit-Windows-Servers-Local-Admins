function get-serveradmins($servername){
    Invoke-Command $servername{
    net localgroup administrators
    }
}
function get-serverdomain($servername){
    Invoke-Command $servername{
    echo %userdomain%
    }
}
function trim-list($serveradmins) {

       $trim = $serveradmins.Count - 2 #2 is the comments below
       #6 is the beginning of the admins list dropping comments
       For ($i=6; $i -le $serveradmins.Count; $i++) {
           if($i -lt $trim){
           $serveradmins[$i]
                        
        }       
    }
}

#finaloutput 
$result = @()
#list of servers
$servers = "TESTSERVER1001"

foreach($server in $servers){
$serveradmins = get-serveradmins($server)
$serveradmins = trim-list($serveradmins)

    foreach($admin in $serveradmins){

    $serverdomain = get-serverdomain($server)
    $admintype;
    $admin_SAN;
    $admin_DN;
    $admin_ObjectClass;
    $admin_members;

    #get admintype
    if($admin -like "*\*"){
        $admintype = "DomainAccount"

        #get admin_SAN
        $admin_SANinput = $admin.Split("\")
        $admin_SAN = $admin_SANinput[1]

        #get DN and ObjectType
        try{
            $admin_DN = Get-ADuser $admin_SAN -Properties DistinguishedName | select DistinguishedName
            $admin_ObjectClass = "user"
            $admin_members = "N/A"
        }
        catch{
            $admin_DN = Get-ADGroup $admin_SAN -Properties DistinguishedName | select DistinguishedName
            $admin_ObjectClass = "group"
            $admin_members = Get-ADGroupMember -Identity $admin_SAN | select name
        }    
    }

    else{
        $admintype = "LocalAccount"
    }

    #get results
        $result += [pscustomobject]@{
        DateOfQuery = Get-Date
        Domain = $serverdomain
        Computer_Hostname = $server
        Computer_FQDN = "$($server).$($serverdomain)"
        LocalAdmins = $admin
        AdminType = $admintype
        ObjectClass = $admin_ObjectClass
        Admin_SAN = $admin_SAN
        Admin_DN = $admin_DN
        Members = ($admin_members.Name -join ', ')
        }
    }
}

$result | export-csv -path "C:\Users\usbufv00adm\desktop\audit.csv" -NoTypeInformation
