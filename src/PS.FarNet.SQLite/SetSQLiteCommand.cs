using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("Set", "SQLite")]
public sealed class SetSQLiteCommand : BaseDBCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public object Command { get; set; }

    //! Empty as default ~ no parameters.
    //! Allow null ~ one null parameter.
    [Parameter(Position = 1)]
    public object[] Parameters { get; set; } = [];

    [Parameter]
    public SwitchParameter Result { get; set; }

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

            if (Result)
            {
                WriteObject(Database.ExecuteNonQuery(cmd));
            }
            else
            {
                Database.Execute(cmd);
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
            if (Result)
            {
                WriteObject(Database.ExecuteNonQuery(text, Parameters));
            }
            else
            {
                Database.Execute(text, Parameters);
            }
        }
    }
}
