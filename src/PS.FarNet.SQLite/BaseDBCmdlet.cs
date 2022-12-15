using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

public abstract class BaseDBCmdlet : PSCmdlet
{
    public abstract DB Database { get; set; }

    protected override void BeginProcessing()
    {
        if (Database is null)
        {
            Database = GetVariableValue("db") as DB;
            if (Database is null)
                throw new PSArgumentException("Expected variable $db or parameter Database.", nameof(Database));
        }
    }
}
