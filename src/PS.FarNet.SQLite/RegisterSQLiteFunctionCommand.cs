using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("Register", "SQLiteFunction")]
public sealed class RegisterSQLiteFunctionCommand : BaseDBCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public string Name { get; set; }

    [Parameter(Position = 1, Mandatory = true)]
    public int Arguments { get; set; }

    [Parameter(Position = 2, Mandatory = true)]
    public ScriptBlock Script { get; set; }

    [Parameter]
    public override DB Database { get; set; }

    object Invoke(object[] args)
    {
        return Script.Invoke(args)[0].BaseObject;
    }

    protected override void BeginProcessing()
    {
        base.BeginProcessing();
        Database.BindScalarFunction(Name, Arguments, Invoke);
    }
}
