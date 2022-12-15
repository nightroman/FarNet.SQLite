using System;
using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("Get", "SQLite", DefaultParameterSetName = PsnRows)]
public sealed class GetSQLiteCommand : BaseDBCmdlet
{
    const string
        PsnRows = "Rows",
        PsnColumn = "Column",
        PsnLookup = "Lookup",
        PsnScalar = "Scalar",
        PsnTable = "Table";

    [Parameter(Position = 0, Mandatory = true)]
    public object Command { get; set; }

    //! Empty as default ~ no parameters.
    //! Allow null ~ one null parameter.
    [Parameter(Position = 1)]
    public object[] Parameters { get; set; } = Array.Empty<object>();

    [Parameter(ParameterSetName = PsnColumn, Mandatory = true)]
    public SwitchParameter Column { get; set; }

    [Parameter(ParameterSetName = PsnLookup, Mandatory = true)]
    public SwitchParameter Lookup { get; set; }

    [Parameter(ParameterSetName = PsnScalar, Mandatory = true)]
    public SwitchParameter Scalar { get; set; }

    [Parameter(ParameterSetName = PsnTable, Mandatory = true)]
    public SwitchParameter Table { get; set; }

    [Parameter]
    public override DB Database { get; set; }

    protected override void BeginProcessing()
    {
        base.BeginProcessing();

        Command = Abc.BaseObject(Command);

        if (Command is SQLiteCommand cmd)
        {
            if (Parameters is null || Parameters.Length > 0)
                throw new PSArgumentException("Parameters are not used with SQLiteCommand command.", nameof(Parameters));

            if (Column)
            {
                WriteObject(Database.ExecuteColumn(cmd));
            }
            else if (Lookup)
            {
                WriteObject(Database.ExecuteLookup(cmd));
            }
            else if (Scalar)
            {
                WriteObject(Database.ExecuteScalar(cmd));
            }
            else
            {
                var dt = Database.ExecuteTable(cmd);
                if (Table)
                    WriteObject(dt);
                else
                    WriteObject(dt.Rows, true);
            }
        }
        else
        {
            if (Parameters is not null)
            {
                for (int i = 0; i < Parameters.Length; ++i)
                    Parameters[i] = Abc.BaseObject(Parameters[i]);
            }

            var text = Command.ToString();
            if (Column)
            {
                WriteObject(Database.ExecuteColumn(text, Parameters));
            }
            else if (Lookup)
            {
                WriteObject(Database.ExecuteLookup(text, Parameters));
            }
            else if (Scalar)
            {
                WriteObject(Database.ExecuteScalar(text, Parameters));
            }
            else
            {
                var dt = Database.ExecuteTable(text, Parameters);
                if (Table)
                    WriteObject(dt);
                else
                    WriteObject(dt.Rows, true);
            }
        }
    }
}
