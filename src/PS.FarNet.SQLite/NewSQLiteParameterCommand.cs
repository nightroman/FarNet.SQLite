using System.Data;
using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("New", "SQLiteParameter")]
[OutputType(typeof(SQLiteParameter))]
public sealed class NewSQLiteParameterCommand : PSCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public string Name { get; set; }

    [Parameter(Position = 1, Mandatory = true)]
    public DbType Type { get; set; }

    [Parameter(Position = 2)]
    public object Value { get; set; }

    protected override void BeginProcessing()
    {
        var prm = new SQLiteParameter(Name, Type);
        if (Value is not null)
            prm.Value = Abc.BaseObject(Value);

        WriteObject(prm);
    }
}
