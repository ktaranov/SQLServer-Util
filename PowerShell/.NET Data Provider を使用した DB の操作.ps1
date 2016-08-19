# .NET Data Provider

$constring = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$constring.psbase.DataSource = "."
$constring.psbase.InitialCatalog = "tempdb"
$constring.psbase.IntegratedSecurity = $true

$con = New-Object System.Data.SqlClient.SqlConnection

$con.ConnectionString = $constring
$con.Open()

# SELECT の実行 (平文)
$cmd = $con.CreateCommand()
$cmd.CommandText = "SELECT object_id, name FROM sys.objects"
$ret = $cmd.ExecuteReader()
while($ret.Read()){
    "{0} {1}" -f $ret[0], $ret[1]
}
$ret.Close()

# SELECT の実行 (パラメーター)
$cmd = $con.CreateCommand()
$cmd.CommandText = "SELECT object_id, name FROM sys.objects WHERE name like @param1"
$cmd.CommandType = [System.Data.CommandType]::Text
$cmd.Parameters.Add("@param1", [System.Data.SqlDbType]::VarChar, 255) > $null
$cmd.Parameters["@param1"].Value = "sys%"

$ret = $cmd.ExecuteReader()
while($ret.Read()){
    "{0} {1}" -f $ret[0], $ret[1]
}
$ret.Close()

# ストアドプロシージャの実行 
$cmd = $con.CreateCommand()
$cmd.CommandText = "sp_configure"
$cmd.CommandType = [System.Data.CommandType]::StoredProcedure

$cmd.Parameters.Add("@configname", [System.Data.SqlDbType]::VarChar, 255) > $null
$cmd.Parameters["@configname"].Value = "show advanced options"
$cmd.Parameters["@configname"].Direction = [System.Data.ParameterDirection]::Input

$ret = $cmd.ExecuteReader()

while($ret.Read()){
    "{0} {1}" -f $ret[0], $ret[1]
}
$ret.Close()

# ストアドプロシージャの実行 (OUTPUT)
<#
create procedure usp_test
    @param1 int output
AS
BEGIN

	SET @param1 = 99999
END
#>

$cmd = $con.CreateCommand()
$cmd.CommandText = "usp_test"
$cmd.CommandType = [System.Data.CommandType]::StoredProcedure

$cmd.Parameters.Add("@param1", [System.Data.SqlDbType]::int) > $null
$cmd.Parameters["@param1"].Direction = [System.Data.ParameterDirection]::Output

$cmd.ExecuteNonQuery() > $null

$cmd.Parameters["@param1"].Value
$ret.Close()

# トランザクション
$tran = $con.BeginTransaction([System.Data.IsolationLevel]::Serializable)
$cmd = $con.CreateCommand()

$cmd.Transaction = $tran

$cmd.CommandText = "CREATE TABLE test1(Col1 int);INSERT INTO test1 VALUES(1)"
$cmd.CommandType = [System.Data.CommandType]::Text
$cmd.ExecuteNonQuery() > $null

$tran.Rollback()

# トランザクションスコープ
$con1 = New-Object System.Data.SqlClient.SqlConnection
$con1.ConnectionString = $constring

$con2 = New-Object System.Data.SqlClient.SqlConnection
$con2.ConnectionString = $constring

# トランザクションスコープ 
# オブジェクト生成後に Open し、try / catch でエラー時には、Complete しないようにする
try{
    $transcope = New-Object System.Transactions.TransactionScope
   
    $con1.Open()

    $cmd1 = $con1.CreateCommand()
    $cmd1.CommandText = "CREATE TABLE test1(Col1 int);INSERT INTO test1 VALUES(1)"
    $cmd1.ExecuteNonQuery() > $null
   
    $con2.Open()

    $cmd2 = $con2.CreateCommand()
    $cmd2.CommandText = "CREATE TABLE test2(Col1 int);INSERT INTO test1 VALUES(1)"
    $cmd2.ExecuteNonQuery() > $null
    
    $transcope.Complete()
}catch{
    Write-Output $_
}finally{
    if($transcope){
        $transcope.Dispose()
    }
}

if($con1){
    $con1.Close()
    $con1.Dispose()
}

if($con2){
    $con2.Close()
    $con2.Dispose()
}
# MARS
$constring_mars = $constring
$constring_mars.MultipleActiveResultSets = $true

$con_mars = New-Object System.Data.SqlClient.SqlConnection

$con_mars.ConnectionString = $constring_mars
$con_mars.Open()

$cmd1 = $con_mars.CreateCommand()
$cmd2 = $con_mars.CreateCommand()

$cmd1.CommandText = "SELECT 1"
$cmd1.CommandType = [System.Data.CommandType]::Text

$cmd2.CommandText = "SELECT 2"
$cmd2.CommandType = [System.Data.CommandType]::Text

$ret1 = $cmd1.ExecuteReader()
$ret2 = $cmd2.ExecuteReader()

if($con_mars){
    $con_mars.Close()
    $con_mars.Dispose()
}


if($con){
    $con.Close()
    $con.Dispose()
}
