using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("Close", "SQLite")]
public sealed class CloseSQLiteCommand : BaseDBCmdlet
{
    [Parameter(Position = 0)]
    public override DB Database { get; set; }

    protected override void BeginProcessing()
    {
        base.BeginProcessing();
        Database.Dispose();
    }
}
