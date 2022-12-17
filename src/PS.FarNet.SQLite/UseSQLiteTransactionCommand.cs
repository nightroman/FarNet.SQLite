using System.Collections.ObjectModel;
using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("Use", "SQLiteTransaction")]
public sealed class UseSQLiteTransactionCommand : BaseDBCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public ScriptBlock Script { get; set; }

    [Parameter]
    public override DB Database { get; set; }

    protected override void BeginProcessing()
    {
        base.BeginProcessing();

        Collection<PSObject> res = null;
        Database.UseTransaction(() =>
        {
            res = Script.Invoke();
        });

        WriteObject(res, true);
    }
}
